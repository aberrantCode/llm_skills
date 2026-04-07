#Requires -Version 5.1
<#
.SYNOPSIS
    Interactive skill selector for ~/.claude/skills/

.DESCRIPTION
    Fetches all available skills from the llm_skills GitHub archive,
    displays an interactive checkbox menu showing which are currently
    installed, and applies your selections — installing new bundles
    (SKILL.md + commands/ + sub-skills/) and removing deselected ones.

.NOTES
    Remote one-liner (run in any PowerShell terminal):
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

# ── Helpers ───────────────────────────────────────────────────────────────────

function Invoke-GitHubApi {
    param([string]$Path)
    try {
        Invoke-RestMethod -Uri "$ApiBase/$Path" -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
    } catch {
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode.value__ -eq 404) { return $null }
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

# Per-session description cache — fetched once per skill, reused on revisit
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

# ── UI Renderer ───────────────────────────────────────────────────────────────

function Show-Selector {
    param(
        [string[]]  $Skills,
        [hashtable] $Selected,
        [int]       $Cursor,
        [int]       $ViewportTop,
        [string]    $Description,
        [int]       $ViewportSize = 22
    )

    [Console]::SetCursorPosition(0, 0)
    [Console]::CursorVisible = $false

    $width = [Console]::WindowWidth
    if ($width -lt 60) { $width = 60 }

    $header = '  Claude Skills Selector  '
    Write-Host $header.PadRight($width) -ForegroundColor Cyan -BackgroundColor DarkBlue
    Write-Host ('  ' + ([string][char]0x2500 * ($width - 4)) + '  ') -ForegroundColor DarkGray
    Write-Host '  [↑↓] Navigate   [Space] Toggle   [A] All   [N] None   [I] Invert   [Enter] Apply   [Q] Quit  '.PadRight($width) -ForegroundColor DarkGray
    Write-Host ''

    $viewportEnd = [Math]::Min($ViewportTop + $ViewportSize - 1, $Skills.Count - 1)

    for ($i = $ViewportTop; $i -le $viewportEnd; $i++) {
        $skill    = $Skills[$i]
        $isActive = ($i -eq $Cursor)
        $isSel    = $Selected[$skill]
        $check    = if ($isSel) { 'x' } else { ' ' }
        $arrow    = if ($isActive) { '>' } else { ' ' }

        if ($isActive -and $isSel) {
            $fg = 'Yellow'; $bg = 'DarkGreen'
        } elseif ($isActive) {
            $fg = 'Yellow'; $bg = 'DarkBlue'
        } elseif ($isSel) {
            $fg = 'Green'; $bg = $null
        } else {
            $fg = 'Gray'; $bg = $null
        }

        $line = "  $arrow [$check] $skill"
        $line = $line.PadRight($width)

        if ($bg) {
            Write-Host $line -ForegroundColor $fg -BackgroundColor $bg
        } else {
            Write-Host $line -ForegroundColor $fg
        }
    }

    # Pad remaining rows so the description line stays fixed
    $renderedRows = $viewportEnd - $ViewportTop + 1
    for ($p = $renderedRows; $p -lt $ViewportSize; $p++) {
        Write-Host ''.PadRight($width)
    }

    Write-Host ''

    # Description bar
    $descLine = if ($Description) { "  > $Description" } else { '' }
    Write-Host $descLine.PadRight($width) -ForegroundColor DarkCyan

    # Summary bar
    $checkedCount  = ($Selected.Values | Where-Object { $_ }).Count
    $scrollInfo    = if ($Skills.Count -gt $ViewportSize) {
        "  Scroll: $($ViewportTop + 1)-$($viewportEnd + 1) of $($Skills.Count)"
    } else { '' }
    $summaryLine = "  Selected: $checkedCount / $($Skills.Count)    $scrollInfo"
    Write-Host $summaryLine.PadRight($width) -ForegroundColor White
}

# ── Step 1: Fetch skill list from GitHub ─────────────────────────────────────

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

Write-Host "Found $($available.Count) skills.`n" -ForegroundColor DarkGray

# ── Step 2: Detect currently installed skills ─────────────────────────────────

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

$installed = @(Get-ChildItem -Path $InstallDir -Directory -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Name)

# ── Step 3: Build initial selection state ─────────────────────────────────────

$selected = @{}
foreach ($s in $available) {
    $selected[$s] = ($installed -contains $s)
}

# ── Step 4: Interactive selection loop ────────────────────────────────────────

[Console]::Clear()

$cursor      = 0
$viewTop     = 0
$viewSize    = 22
$lastCursor  = -1
$description = ''
$running     = $true

while ($running) {
    # Fetch description when cursor moves (lazy, cached)
    if ($cursor -ne $lastCursor) {
        $lastCursor  = $cursor
        $description = '(loading...)'
        Show-Selector -Skills $available -Selected $selected -Cursor $cursor `
            -ViewportTop $viewTop -Description $description -ViewportSize $viewSize

        $description = Get-CachedDescription $available[$cursor]
    }

    Show-Selector -Skills $available -Selected $selected -Cursor $cursor `
        -ViewportTop $viewTop -Description $description -ViewportSize $viewSize

    $key = [Console]::ReadKey($true)

    if ($key.Key -eq [ConsoleKey]::UpArrow) {
        if ($cursor -gt 0) {
            $cursor--
            if ($cursor -lt $viewTop) { $viewTop = $cursor }
        }
    } elseif ($key.Key -eq [ConsoleKey]::DownArrow) {
        if ($cursor -lt $available.Count - 1) {
            $cursor++
            if ($cursor -ge $viewTop + $viewSize) { $viewTop = $cursor - $viewSize + 1 }
        }
    } elseif ($key.Key -eq [ConsoleKey]::PageUp) {
        $cursor  = [Math]::Max(0, $cursor - $viewSize)
        $viewTop = [Math]::Max(0, $viewTop - $viewSize)
    } elseif ($key.Key -eq [ConsoleKey]::PageDown) {
        $cursor  = [Math]::Min($available.Count - 1, $cursor + $viewSize)
        $viewTop = [Math]::Min([Math]::Max(0, $available.Count - $viewSize), $viewTop + $viewSize)
    } elseif ($key.Key -eq [ConsoleKey]::Spacebar) {
        $skill           = $available[$cursor]
        $selected[$skill] = -not $selected[$skill]
    } elseif ($key.Key -eq [ConsoleKey]::Enter) {
        $running = $false
    } else {
        switch ($key.KeyChar.ToString().ToLower()) {
            'a' { foreach ($s in $available) { $selected[$s] = $true } }
            'n' { foreach ($s in $available) { $selected[$s] = $false } }
            'i' { foreach ($s in $available) { $selected[$s] = -not $selected[$s] } }
            'q' {
                [Console]::CursorVisible = $true
                [Console]::Clear()
                Write-Host 'Aborted — no changes made.' -ForegroundColor Yellow
                exit 0
            }
        }
    }
}

[Console]::CursorVisible = $true

# ── Step 5: Compute diff ──────────────────────────────────────────────────────

$toInstall = @($available | Where-Object { $selected[$_] -and ($installed -notcontains $_) })
$toRemove  = @($available | Where-Object { -not $selected[$_] -and ($installed -contains $_) })

[Console]::Clear()

if ($toInstall.Count -eq 0 -and $toRemove.Count -eq 0) {
    Write-Host 'No changes to apply.' -ForegroundColor Green
    exit 0
}

# ── Step 6: Confirm ───────────────────────────────────────────────────────────

Write-Host 'Pending changes:' -ForegroundColor White
Write-Host ''

if ($toInstall.Count -gt 0) {
    Write-Host "  Install ($($toInstall.Count)):" -ForegroundColor Green
    $toInstall | ForEach-Object { Write-Host "    + $_" -ForegroundColor Green }
}

if ($toRemove.Count -gt 0) {
    Write-Host "  Remove ($($toRemove.Count)):" -ForegroundColor Red
    $toRemove | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
}

Write-Host ''
$confirm = Read-Host 'Apply these changes? [Y/N]'
if ($confirm -notmatch '^[Yy]') {
    Write-Host 'Aborted — no changes made.' -ForegroundColor Yellow
    exit 0
}

Write-Host ''

# ── Step 7: Remove deselected skill bundles ───────────────────────────────────

foreach ($skill in $toRemove) {
    $skillPath = Join-Path $InstallDir $skill
    if (Test-Path $skillPath) {
        Remove-Item -Path $skillPath -Recurse -Force
        Write-Host "  - Removed $skill" -ForegroundColor Red
    }
}

# ── Step 8: Install selected skill bundles ────────────────────────────────────

function Install-SkillBundle {
    param([string]$SkillName)

    $skillDir = Join-Path $InstallDir $SkillName
    if (-not (Test-Path $skillDir)) {
        New-Item -ItemType Directory -Path $skillDir -Force | Out-Null
    }

    # SKILL.md — required
    $skillMdDest = Join-Path $skillDir 'SKILL.md'
    try {
        Invoke-WebRequest -Uri "$RawBase/claude/skills/$SkillName/SKILL.md" `
            -OutFile $skillMdDest -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Warning "    Could not download $SkillName/SKILL.md — skipping"
        return $false
    }

    # commands/ — optional, copy all .md files
    try {
        $commandsApi = Invoke-GitHubApi "contents/claude/skills/$SkillName/commands"
        if ($commandsApi) {
            $commandsDir = Join-Path $skillDir 'commands'
            if (-not (Test-Path $commandsDir)) {
                New-Item -ItemType Directory -Path $commandsDir -Force | Out-Null
            }
            foreach ($item in ($commandsApi | Where-Object { $_.type -eq 'file' -and $_.download_url })) {
                $dest = Join-Path $commandsDir $item.name
                Invoke-WebRequest -Uri $item.download_url -OutFile $dest -UseBasicParsing -ErrorAction Stop
            }
        }
    } catch {
        Write-Warning "    commands/ partially downloaded for $SkillName — $_"
    }

    # sub-skills/ — optional, recurse one level
    try {
        $subSkillsApi = Invoke-GitHubApi "contents/claude/skills/$SkillName/sub-skills"
        if ($subSkillsApi) {
            $subSkillsDir = Join-Path $skillDir 'sub-skills'
            if (-not (Test-Path $subSkillsDir)) {
                New-Item -ItemType Directory -Path $subSkillsDir -Force | Out-Null
            }
            foreach ($subDir in ($subSkillsApi | Where-Object { $_.type -eq 'dir' })) {
                $subName  = $subDir.name
                $subDest  = Join-Path $subSkillsDir $subName
                if (-not (Test-Path $subDest)) {
                    New-Item -ItemType Directory -Path $subDest -Force | Out-Null
                }
                $subFiles = Invoke-GitHubApi "contents/claude/skills/$SkillName/sub-skills/$subName"
                foreach ($file in ($subFiles | Where-Object { $_.type -eq 'file' -and $_.name -like '*.md' -and $_.download_url })) {
                    $dest = Join-Path $subDest $file.name
                    Invoke-WebRequest -Uri $file.download_url -OutFile $dest -UseBasicParsing -ErrorAction Stop
                }
            }
        }
    } catch {
        Write-Warning "    sub-skills/ partially downloaded for $SkillName — $_"
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
$activeCount = ($selected.GetEnumerator() | Where-Object { $_.Value }).Count
Write-Host "Done.  $activeCount skills active in $InstallDir" -ForegroundColor Cyan
