#Requires -Version 5.1
<#
.SYNOPSIS
    Interactive skill selector for ~/.claude/skills/

.DESCRIPTION
    Fetches all available skills from the llm_skills GitHub archive,
    displays a collapsible category menu, and installs/removes skill
    bundles (SKILL.md + commands/ + sub-skills/) based on your selections.

    Key bindings:
      Up/Down    Navigate
      Space      On category: toggle all skills in group on/off
                 On skill: toggle that skill
      Enter      On category: expand/collapse
                 On skill: apply changes
      A / N / I  Select all / None / Invert (global)
      Q          Quit without changes

.NOTES
    Remote one-liner:
        irm 'https://raw.githubusercontent.com/aberrantCode/llm_skills/main/install-skills.ps1' | iex
#>

$ErrorActionPreference = 'Stop'

# ── Constants ─────────────────────────────────────────────────────────────────

$Owner      = 'aberrantCode'
$Repo       = 'llm_skills'
$Branch     = 'main'
$ApiBase    = "https://api.github.com/repos/$Owner/$Repo"
$RawBase    = "https://raw.githubusercontent.com/$Owner/$Repo/$Branch"
$InstallDir = Join-Path $env:USERPROFILE '.claude\skills'

# ── Standard Skills ───────────────────────────────────────────────────────────
# Edit this list to change which skills appear in the "Standard Skills" group.
# Pressing Space on that category header selects/deselects all of them at once.

$StandardSkills = @(
    'code-review',
    'git-cleanup',
    'project-manager',
    'release-to-main',
    'ship-to-dev',
    'skills-manager'
)

# ── Category Map ──────────────────────────────────────────────────────────────
# Skills not listed here fall into an "Other" group at the bottom.

$CategoryMap = [ordered]@{
    'Foundations'         = @('base', 'code-deduplication', 'commit-hygiene', 'existing-repo',
                              'iterative-development', 'session-management', 'team-coordination',
                              'tdd-workflow', 'workspace')
    'Code Quality'        = @('codex-review', 'gemini-review', 'requesting-code-review',
                              'security', 'security-review', 'subagent-driven-development')
    'Languages'           = @('android-java', 'android-kotlin', 'flutter', 'nodejs-backend',
                              'python', 'react-best-practices', 'react-native', 'react-web',
                              'typescript')
    'Frontend & UI'       = @('design-taste-frontend', 'frontend-design', 'playwright-testing',
                              'pwa-development', 'ui-mobile', 'ui-testing', 'ui-web',
                              'web-design-guidelines')
    'Databases'           = @('aws-aurora', 'aws-dynamodb', 'azure-cosmosdb', 'cloudflare-d1',
                              'database-schema', 'firebase', 'supabase', 'supabase-nextjs',
                              'supabase-node', 'supabase-python')
    'AI & LLM'            = @('agentic-development', 'ai-models', 'llm-patterns')
    'DevOps & Tooling'    = @('add-remote-installer', 'chrome-extension-builder',
                              'project-tooling', 'publish-github', 'remote-installer',
                              'start-app', 'using-git-worktrees', 'visual-explainer')
    'Workflow'            = @('add-feature', 'composition-patterns', 'create-feature-spec',
                              'doc-coauthoring', 'explain-code', 'feature-start',
                              'finishing-a-development-branch', 'fix-start', 'guide-assistant',
                              'pre-pr', 'retro-fit-spec', 'spec-align')
    'Commerce'            = @('klaviyo', 'medusa', 'reddit-ads', 'shopify-apps',
                              'web-payments', 'woocommerce')
    'Content & Marketing' = @('aeo-optimization', 'credentials', 'ms-teams-apps',
                              'posthog-analytics', 'reddit-api', 'site-architecture',
                              'user-journeys', 'web-content')
    'Specialized'         = @('logo-restylizer', 'vercel-deploy-claimable',
                              'worldview-layer-scaffold', 'worldview-shader-preset',
                              'youtube-prd-forensics')
}

# ── Helpers ───────────────────────────────────────────────────────────────────

function Invoke-GitHubApi {
    param([string]$Path)
    try {
        Invoke-RestMethod -Uri "$ApiBase/$Path" -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
    } catch {
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode.value__ -eq 404) {
            return $null
        }
        throw
    }
}

function Get-RawContent {
    param([string]$RepoPath)
    try {
        Invoke-RestMethod -Uri "$RawBase/$RepoPath" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    } catch {
        $null
    }
}

function Read-FrontmatterField {
    param([string]$Content, [string]$Field)
    if ($Content -and $Content -match "(?m)^${Field}:\s*(.+)$") { return $Matches[1].Trim() }
    return $null
}

$script:DescCache = @{}

function Get-CachedDescription {
    param([string]$SkillName)
    if ($script:DescCache.ContainsKey($SkillName)) { return $script:DescCache[$SkillName] }
    $content = Get-RawContent "claude/skills/$SkillName/SKILL.md"
    $raw     = Read-FrontmatterField $content 'description'
    $desc    = if ($raw) { $raw } else { '(no description)' }
    $script:DescCache[$SkillName] = $desc
    return $desc
}

# ── Visible Item Builder ──────────────────────────────────────────────────────
# Returns a flat array of hashtables: .type = 'category'|'skill',
# .name, and for categories: .skills = string[]

function Get-VisibleItems {
    param(
        [System.Collections.Specialized.OrderedDictionary]$AllCategories,
        [hashtable]$Expanded,
        [string[]]$Available
    )

    $items       = [System.Collections.Generic.List[hashtable]]::new()
    $categorized = @{}

    foreach ($catName in $AllCategories.Keys) {
        $catSkills = @($AllCategories[$catName] | Where-Object { $Available -contains $_ })
        if ($catSkills.Count -eq 0) { continue }

        $items.Add(@{ type = 'category'; name = $catName; skills = $catSkills })
        foreach ($s in $catSkills) { $categorized[$s] = $true }

        if ($Expanded[$catName]) {
            foreach ($skill in $catSkills) {
                $items.Add(@{ type = 'skill'; name = $skill; category = $catName })
            }
        }
    }

    # Anything not in any category
    $uncategorized = @($Available | Where-Object { -not $categorized.ContainsKey($_) })
    if ($uncategorized.Count -gt 0) {
        $items.Add(@{ type = 'category'; name = 'Other'; skills = $uncategorized })
        if ($Expanded['Other']) {
            foreach ($skill in $uncategorized) {
                $items.Add(@{ type = 'skill'; name = $skill; category = 'Other' })
            }
        }
    }

    return , $items.ToArray()
}

# ── UI Renderer ───────────────────────────────────────────────────────────────

function Show-Selector {
    param(
        [object[]]  $Items,
        [hashtable] $Selected,
        [hashtable] $Expanded,
        [int]       $Cursor,
        [int]       $ViewportTop,
        [string]    $Description,
        [int]       $ViewportSize,
        [int]       $Width
    )

    [Console]::SetCursorPosition(0, 0)
    [Console]::CursorVisible = $false

    Write-Host '  Claude Skills Selector'.PadRight($Width) -ForegroundColor Cyan -BackgroundColor DarkBlue
    Write-Host ('  ' + ('-' * ($Width - 4)) + '  ') -ForegroundColor DarkGray
    Write-Host '  [Sp] Toggle  [Enter] Expand/Apply  [A] All  [N] None  [I] Invert  [Q] Quit  '.PadRight($Width) -ForegroundColor DarkGray
    Write-Host ''

    $viewportEnd = [Math]::Min($ViewportTop + $ViewportSize - 1, $Items.Count - 1)

    for ($i = $ViewportTop; $i -le $viewportEnd; $i++) {
        $item     = $Items[$i]
        $isActive = ($i -eq $Cursor)

        if ($item.type -eq 'category') {
            $catSkills  = $item.skills
            $selCount   = @($catSkills | Where-Object { $Selected[$_] }).Count
            $total      = $catSkills.Count
            $expandChar = if ($Expanded[$item.name]) { '-' } else { '+' }
            $checkChar  = if ($selCount -eq $total -and $total -gt 0) { 'x' } `
                          elseif ($selCount -gt 0) { '~' } else { ' ' }
            $label      = "  [$checkChar] [$expandChar] $($item.name)  ($selCount/$total)"
            $line       = $label.PadRight($Width)

            if ($isActive) {
                Write-Host $line -ForegroundColor Black -BackgroundColor Cyan
            } elseif ($selCount -gt 0) {
                Write-Host $line -ForegroundColor Cyan
            } else {
                Write-Host $line -ForegroundColor DarkCyan
            }
        } else {
            $isSel = $Selected[$item.name]
            $check = if ($isSel) { 'x' } else { ' ' }
            $arrow = if ($isActive) { '>' } else { ' ' }
            $line  = "        $arrow [$check] $($item.name)".PadRight($Width)

            if ($isActive -and $isSel) {
                Write-Host $line -ForegroundColor Yellow -BackgroundColor DarkGreen
            } elseif ($isActive) {
                Write-Host $line -ForegroundColor Yellow -BackgroundColor DarkBlue
            } elseif ($isSel) {
                Write-Host $line -ForegroundColor Green
            } else {
                Write-Host $line -ForegroundColor Gray
            }
        }
    }

    # Fixed-height padding so description bar never shifts
    $rendered = $viewportEnd - $ViewportTop + 1
    for ($p = $rendered; $p -lt $ViewportSize; $p++) {
        Write-Host ''.PadRight($Width)
    }

    Write-Host ''
    Write-Host ("  > $Description").PadRight($Width) -ForegroundColor DarkCyan

    $checkedCount = @($Selected.Values | Where-Object { $_ }).Count
    $scrollInfo   = if ($Items.Count -gt $ViewportSize) {
        "  rows $($ViewportTop+1)-$($viewportEnd+1) of $($Items.Count)"
    } else { '' }
    Write-Host "  Selected: $checkedCount / $($Selected.Count) skills  $scrollInfo".PadRight($Width) -ForegroundColor White
}

# ── Step 1: Fetch skill list ──────────────────────────────────────────────────

[Console]::Clear()
Write-Host 'Fetching skill list from GitHub...' -ForegroundColor Cyan

$skillDirs = $null
try {
    $skillDirs = Invoke-GitHubApi 'contents/claude/skills'
} catch {
    Write-Error "Could not reach GitHub: $_"
    exit 1
}

$available = @(
    $skillDirs |
    Where-Object { $_.type -eq 'dir' } |
    Select-Object -ExpandProperty name |
    Sort-Object
)

Write-Host "Found $($available.Count) skills." -ForegroundColor DarkGray

# ── Step 2: Detect installed skills ──────────────────────────────────────────

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

$installed = @(
    Get-ChildItem -Path $InstallDir -Directory -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Name
)

# ── Step 3: Build full category map (Standard Skills first) ───────────────────

$allCategories = [ordered]@{}
$allCategories['Standard Skills'] = @($StandardSkills | Where-Object { $available -contains $_ })
foreach ($k in $CategoryMap.Keys) { $allCategories[$k] = $CategoryMap[$k] }

# ── Step 4: Initial state ─────────────────────────────────────────────────────

$selected = @{}
foreach ($s in $available) { $selected[$s] = ($installed -contains $s) }

$expanded = @{ 'Standard Skills' = $true; 'Other' = $false }
foreach ($k in $CategoryMap.Keys) { $expanded[$k] = $false }

# ── Step 5: Interactive loop ──────────────────────────────────────────────────

[Console]::Clear()

$width      = [Math]::Max([Console]::WindowWidth, 72)
$viewSize   = [Math]::Max([Console]::WindowHeight - 10, 10)
$cursor     = 0
$viewTop    = 0
$lastCursor = -1
$desc       = ''
$running    = $true

while ($running) {
    $items  = Get-VisibleItems -AllCategories $allCategories -Expanded $expanded -Available $available
    $maxIdx = $items.Count - 1
    if ($cursor -gt $maxIdx) { $cursor = $maxIdx }

    $cur = $items[$cursor]

    if ($cursor -ne $lastCursor) {
        $lastCursor = $cursor
        if ($cur.type -eq 'skill') {
            $desc = '(loading...)'
            Show-Selector -Items $items -Selected $selected -Expanded $expanded `
                -Cursor $cursor -ViewportTop $viewTop -Description $desc `
                -ViewportSize $viewSize -Width $width
            $desc = Get-CachedDescription $cur.name
        } else {
            $desc = "$($cur.skills.Count) skills in this group  [Space] toggle all  [Enter] expand"
        }
    }

    Show-Selector -Items $items -Selected $selected -Expanded $expanded `
        -Cursor $cursor -ViewportTop $viewTop -Description $desc `
        -ViewportSize $viewSize -Width $width

    $key = [Console]::ReadKey($true)

    if ($key.Key -eq [ConsoleKey]::UpArrow) {
        if ($cursor -gt 0) {
            $cursor--
            if ($cursor -lt $viewTop) { $viewTop = $cursor }
        }

    } elseif ($key.Key -eq [ConsoleKey]::DownArrow) {
        if ($cursor -lt $maxIdx) {
            $cursor++
            if ($cursor -ge $viewTop + $viewSize) { $viewTop = $cursor - $viewSize + 1 }
        }

    } elseif ($key.Key -eq [ConsoleKey]::PageUp) {
        $cursor  = [Math]::Max(0, $cursor - $viewSize)
        $viewTop = [Math]::Max(0, $viewTop - $viewSize)

    } elseif ($key.Key -eq [ConsoleKey]::PageDown) {
        $cursor  = [Math]::Min($maxIdx, $cursor + $viewSize)
        $viewTop = [Math]::Min([Math]::Max(0, $maxIdx - $viewSize + 1), $viewTop + $viewSize)
        if ($viewTop -lt 0) { $viewTop = 0 }

    } elseif ($key.Key -eq [ConsoleKey]::Spacebar) {
        if ($cur.type -eq 'category') {
            $catSkills   = @($cur.skills | Where-Object { $available -contains $_ })
            $allSelected = (@($catSkills | Where-Object { $selected[$_] }).Count -eq $catSkills.Count)
            foreach ($s in $catSkills) { $selected[$s] = -not $allSelected }
        } else {
            $selected[$cur.name] = -not $selected[$cur.name]
        }

    } elseif ($key.Key -eq [ConsoleKey]::Enter) {
        if ($cur.type -eq 'category') {
            $expanded[$cur.name] = -not $expanded[$cur.name]
        } else {
            $running = $false
        }

    } else {
        switch ($key.KeyChar.ToString().ToLower()) {
            'a' { foreach ($s in $available) { $selected[$s] = $true  } }
            'n' { foreach ($s in $available) { $selected[$s] = $false } }
            'i' { foreach ($s in $available) { $selected[$s] = -not $selected[$s] } }
            'q' {
                [Console]::CursorVisible = $true
                [Console]::Clear()
                Write-Host 'Aborted - no changes made.' -ForegroundColor Yellow
                exit 0
            }
        }
    }
}

[Console]::CursorVisible = $true

# ── Step 6: Compute diff ──────────────────────────────────────────────────────

$toInstall = @($available | Where-Object { $selected[$_]  -and ($installed -notcontains $_) })
$toRemove  = @($available | Where-Object { -not $selected[$_] -and ($installed -contains $_) })

[Console]::Clear()

if ($toInstall.Count -eq 0 -and $toRemove.Count -eq 0) {
    Write-Host 'No changes to apply.' -ForegroundColor Green
    exit 0
}

# ── Step 7: Confirm ───────────────────────────────────────────────────────────

Write-Host 'Pending changes:' -ForegroundColor White
Write-Host ''

if ($toInstall.Count -gt 0) {
    Write-Host "  Install ($($toInstall.Count)):" -ForegroundColor Green
    $toInstall | ForEach-Object { Write-Host "    + $_" -ForegroundColor Green }
}
if ($toRemove.Count -gt 0) {
    Write-Host "  Remove ($($toRemove.Count)):" -ForegroundColor Red
    $toRemove  | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
}

Write-Host ''
$confirm = Read-Host 'Apply these changes? [Y/N]'
if ($confirm -notmatch '^[Yy]') {
    Write-Host 'Aborted - no changes made.' -ForegroundColor Yellow
    exit 0
}

Write-Host ''

# ── Step 8: Remove deselected bundles ─────────────────────────────────────────

foreach ($skill in $toRemove) {
    $path = Join-Path $InstallDir $skill
    if (Test-Path $path) {
        Remove-Item -Path $path -Recurse -Force
        Write-Host "  - Removed $skill" -ForegroundColor Red
    }
}

# ── Step 9: Install selected bundles ──────────────────────────────────────────

function Install-SkillBundle {
    param([string]$SkillName)

    $skillDir = Join-Path $InstallDir $SkillName
    if (-not (Test-Path $skillDir)) {
        New-Item -ItemType Directory -Path $skillDir -Force | Out-Null
    }

    # SKILL.md - required
    try {
        Invoke-WebRequest -Uri "$RawBase/claude/skills/$SkillName/SKILL.md" `
            -OutFile (Join-Path $skillDir 'SKILL.md') -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Warning "    Could not download $SkillName/SKILL.md - skipping"
        return $false
    }

    # commands/ - optional
    try {
        $commandsApi = Invoke-GitHubApi "contents/claude/skills/$SkillName/commands"
        if ($commandsApi) {
            $commandsDir = Join-Path $skillDir 'commands'
            if (-not (Test-Path $commandsDir)) { New-Item -ItemType Directory -Path $commandsDir -Force | Out-Null }
            foreach ($item in ($commandsApi | Where-Object { $_.type -eq 'file' -and $_.download_url })) {
                Invoke-WebRequest -Uri $item.download_url -OutFile (Join-Path $commandsDir $item.name) `
                    -UseBasicParsing -ErrorAction Stop
            }
        }
    } catch {
        Write-Warning "    commands/ incomplete for $SkillName"
    }

    # sub-skills/ - optional, one level deep
    try {
        $subApi = Invoke-GitHubApi "contents/claude/skills/$SkillName/sub-skills"
        if ($subApi) {
            $subRoot = Join-Path $skillDir 'sub-skills'
            if (-not (Test-Path $subRoot)) { New-Item -ItemType Directory -Path $subRoot -Force | Out-Null }
            foreach ($subDir in ($subApi | Where-Object { $_.type -eq 'dir' })) {
                $subDest = Join-Path $subRoot $subDir.name
                if (-not (Test-Path $subDest)) { New-Item -ItemType Directory -Path $subDest -Force | Out-Null }
                $subFiles = Invoke-GitHubApi "contents/claude/skills/$SkillName/sub-skills/$($subDir.name)"
                foreach ($file in ($subFiles | Where-Object { $_.type -eq 'file' -and $_.name -like '*.md' -and $_.download_url })) {
                    Invoke-WebRequest -Uri $file.download_url -OutFile (Join-Path $subDest $file.name) `
                        -UseBasicParsing -ErrorAction Stop
                }
            }
        }
    } catch {
        Write-Warning "    sub-skills/ incomplete for $SkillName"
    }

    return $true
}

foreach ($skill in $toInstall) {
    Write-Host "  + Installing $skill..." -ForegroundColor Green -NoNewline
    $ok = Install-SkillBundle -SkillName $skill
    if ($ok) { Write-Host ' done' -ForegroundColor DarkGreen }
}

# ── Summary ───────────────────────────────────────────────────────────────────

Write-Host ''
$activeCount = @($selected.GetEnumerator() | Where-Object { $_.Value }).Count
Write-Host "Done.  $activeCount skills active in $InstallDir" -ForegroundColor Cyan
