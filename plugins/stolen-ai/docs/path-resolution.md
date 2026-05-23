# Path Resolution

How agents and skills locate plugin files and distinguish them from user workspace paths.

## Two path scopes

| Scope | Root | Examples |
|-------|------|----------|
| **Plugin** | `$PLUGIN_ROOT` (discovered below) | `scripts/`, `schemas/`, `docs/` |
| **Workspace** | The user's open workspace folder | `.stolenai.json`, `output/`, `metrics/`, `specs/` |

Never conflate the two. Plugin files ship with the plugin. Workspace files belong to the consumer project.

## Discovering `$PLUGIN_ROOT`

VS Code installs this plugin under `~/.copilot/installed-plugins/`. The exact nesting varies, so resolve dynamically.

### For PowerShell script execution

Include this preamble in every terminal invocation that calls a plugin script:

```powershell
$pluginRoot = Join-Path $env:USERPROFILE '.copilot\installed-plugins\stolen-ai\stolen-ai'
if (-not (Test-Path (Join-Path $pluginRoot 'plugin.json'))) {
    $found = Get-ChildItem (Join-Path $env:USERPROFILE '.copilot\installed-plugins') `
        -Recurse -Filter 'plugin.json' -ErrorAction SilentlyContinue |
        Where-Object {
            (Get-Content $_.FullName -Raw | ConvertFrom-Json).name -eq 'stolen-ai'
        } | Select-Object -First 1
    if ($found) { $pluginRoot = $found.DirectoryName }
}
```

Then reference scripts as `& "$pluginRoot\scripts\plan-feature\fetch-feature.ps1"`.

### For AI file reads (read_file, schemas, docs)

Derive the plugin root from any loaded skill's file path visible in your context. Every stolen-ai skill path contains the plugin root, e.g.:

```
{USERPROFILE}\.copilot\installed-plugins\stolen-ai\stolen-ai\skills\getting-started\SKILL.md
                                                               ↑ plugin root ends here
```

Strip `skills/{name}/SKILL.md` to get the plugin root, then append the target path (e.g., `docs/governance.md`, `schemas/stories-output.schema.json`).

## Reference cheat sheet

| Agent/skill says | Resolves to |
|------------------|-------------|
| `$PLUGIN_ROOT/scripts/plan-feature/fetch-feature.ps1` | `{installed-plugins}/stolen-ai/stolen-ai/scripts/plan-feature/fetch-feature.ps1` |
| `$PLUGIN_ROOT/schemas/stories-output.schema.json` | `{installed-plugins}/stolen-ai/stolen-ai/schemas/stories-output.schema.json` |
| `$PLUGIN_ROOT/docs/governance.md` | `{installed-plugins}/stolen-ai/stolen-ai/docs/governance.md` |
| `output/{id}/stories.json` | `{user workspace}/output/{id}/stories.json` |
| `.stolenai.json` | `{user workspace}/.stolenai.json` |
