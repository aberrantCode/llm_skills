# /new-action — Create a new OSM profile action JSON file

You are creating a new action JSON file for the OSM profile configurator. The file will be placed in `assets/actions/all/`.

## Workflow

Follow these steps in order. **Do not write the file until all required information has been gathered.**

### Step 1: Determine what the user wants

Read the user's request. Identify:
- What Windows behavior they want to change
- Which action type(s) are needed (see reference below)

If the request is vague or missing critical details, use `AskUserQuestion` to clarify. For example, if the user says "disable something" without specifying the mechanism, ask which action type is appropriate.

### Step 2: Gather required fields by action type

For each action in the group, gather the fields listed below. **Use `AskUserQuestion` for any field the user has not provided and you cannot confidently determine.**

#### RegistryAction
| Field | Required | Description |
|-------|----------|-------------|
| `Action` | yes | One of: `SetKeyNamedValue`, `UpdateKeyNamedValue`, `RemoveKeyNamedValue`, `RemoveKey` |
| `Type` | yes for Set/Update | `DWord` or `string` (use `""` for Remove actions) |
| `Path` | yes | Full registry path (e.g. `HKCU:\Software\...`, `HKLM:\SOFTWARE\...`) |
| `Name` | yes for named-value actions | Registry value name (use `""` for `RemoveKey`) |
| `Value` | yes for Set/Update | The value to write. DWord values are integers (`0`, `1`). String values are strings (`"text"`). Use `null` for Remove actions. |
| `Restart` | no | `""` (default), `"Computer"`, or `"Explorer"` |

- `SetKeyNamedValue` — creates the key and value if they don't exist; fails if value already exists
- `UpdateKeyNamedValue` — creates or overwrites the value (most common for "disable/enable" settings)
- `RemoveKeyNamedValue` — deletes a named value from a key
- `RemoveKey` — deletes an entire registry key

#### IOAction
| Field | Required | Description |
|-------|----------|-------------|
| `Action` | yes | Typically `"Remove"` |
| `Path` | yes | Filesystem path to remove |
| `Scope` | no | `null` in most cases |
| `Name` | no | `""` in most cases |

#### MethodAction
| Field | Required | Description |
|-------|----------|-------------|
| `Action` | yes | `"Invoke"` |
| `Name` | yes | PowerShell function name to call (e.g. `"Invoke-EnablePSRemoting"`) |
| `Arguments` | no | `null` or an object of arguments |
| `Context` | no | `""` in most cases |

#### ScheduledTaskAction
| Field | Required | Description |
|-------|----------|-------------|
| `Action` | yes | `"Disable"` |
| `TaskName` | yes | Exact scheduled task name |
| `TaskPath` | no | Task path (e.g. `"\\Microsoft\\Windows\\Application Experience\\"`) or `null` |
| `Name` | no | `""` in most cases |

### Step 3: Confirm restart behavior

If any action modifies a setting that typically requires a restart to take effect (e.g. Bluetooth, network stack, explorer shell), use `AskUserQuestion` to confirm:

- `""` — no restart needed (default)
- `"Computer"` — full computer restart
- `"Explorer"` — restart Windows Explorer (for shell/taskbar/UI changes)

Place the `Restart` value on the **last action** in the group that requires it (not on every action).

### Step 4: Confirm the file name

The naming convention is `Verb_Description.json` using underscores between words.

Valid verb prefixes:
- `Disable_` — turn off a Windows feature or behavior
- `Enable_` — turn on a Windows feature or behavior
- `Remove_` — delete files, registry keys, or UI elements
- `Update_` — modify existing settings or configuration
- `Configure_` — set up a tool or subsystem
- `Set_` — assign a specific value or state

Propose a file name and confirm with the user via `AskUserQuestion` if there is any ambiguity.

### Step 5: Write the JSON file

Write the file to `assets/actions/all/<Filename>.json` using this structure:

```json
{
  "Target": "All",
  "Actions": [
    { ... }
  ],
  "ObjectTypeName": "GroupActions",
  "Action": "",
  "Name": "<Human-readable group name matching the filename>",
  "Title": "",
  "Restart": ""
}
```

Every action object must include all fields for its type, including empty-string defaults for `Title` and `Restart`. Refer to the examples below for exact field ordering.

### Step 6: Validate

After writing, verify:
- [ ] File is valid JSON
- [ ] `ObjectTypeName` is `"GroupActions"` at the top level
- [ ] Each action has the correct `ObjectTypeName` for its type
- [ ] Each action has all required fields (no missing keys)
- [ ] `Target` is `"All"`
- [ ] `Restart` values are only `""`, `"Computer"`, or `"Explorer"`
- [ ] File is in `assets/actions/all/`
- [ ] Filename follows `Verb_Description.json` convention

---

## Examples

### RegistryAction (SetKeyNamedValue with DWord)
```json
{
  "Target": "All",
  "Actions": [
    {
      "Type": "DWord",
      "Action": "SetKeyNamedValue",
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Search",
      "Value": 0,
      "ObjectTypeName": "RegistryAction",
      "Name": "SearchboxTaskbarMode",
      "Title": "",
      "Restart": ""
    }
  ],
  "ObjectTypeName": "GroupActions",
  "Action": "",
  "Name": "Remove Search From Taskbar",
  "Title": "",
  "Restart": ""
}
```

### RegistryAction (string type)
```json
{
  "Type": "string",
  "Action": "SetKeyNamedValue",
  "Path": "HKCU:\\Control Panel\\Colors",
  "Value": "0 0 0",
  "ObjectTypeName": "RegistryAction",
  "Name": "Background",
  "Title": "",
  "Restart": ""
}
```

### RegistryAction (RemoveKey — no Name, no Value, no Type)
```json
{
  "Type": "",
  "Action": "RemoveKey",
  "Path": "HKEY_CLASSES_ROOT\\CLSID\\{018D5C66-4533-4307-9B53-224DE2ED1FE6}",
  "Value": null,
  "ObjectTypeName": "RegistryAction",
  "Name": "",
  "Title": "",
  "Restart": ""
}
```

### RegistryAction (with Computer restart)
```json
{
  "Type": "DWORD",
  "Action": "UpdateKeyNamedValue",
  "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Bluetooth\\DefaultSettings",
  "Value": 0,
  "ObjectTypeName": "RegistryAction",
  "Name": "Enable",
  "Title": "",
  "Restart": "Computer"
}
```

### IOAction
```json
{
  "Path": "C:\\Users\\erik.OPBTA\\OneDrive",
  "Scope": null,
  "ObjectTypeName": "IOAction",
  "Action": "Remove",
  "Name": "",
  "Title": "",
  "Restart": ""
}
```

### MethodAction
```json
{
  "Arguments": null,
  "Context": "",
  "ObjectTypeName": "MethodAction",
  "Action": "Invoke",
  "Name": "Invoke-EnablePSRemoting",
  "Title": "",
  "Restart": ""
}
```

### ScheduledTaskAction
```json
{
  "TaskName": "Microsoft Compatibility Appraiser",
  "TaskPath": "\\Microsoft\\Windows\\Application Experience\\",
  "ObjectTypeName": "ScheduledTaskAction",
  "Action": "Disable",
  "Name": "",
  "Title": "",
  "Restart": ""
}
```

### RegistryAction (with Explorer restart on last action)
```json
{
  "Type": "DWord",
  "Action": "SetKeyNamedValue",
  "Path": "HKCU:\\Software\\Microsoft\\TabletTip\\1.7",
  "Value": 1,
  "ObjectTypeName": "RegistryAction",
  "Name": "TipbandDesiredVisibility",
  "Title": "",
  "Restart": "Explorer"
}
```
