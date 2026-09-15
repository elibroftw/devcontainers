
# Skills (skills)

Installs agent skills from the open skills ecosystem (skills.sh) via `npx skills add`; ships find-skills by default so an agent can discover the rest. Requires nodejs to be preinstalled (e.g. the frontend feature)

## Example Usage

```json
"features": {
    "ghcr.io/elibroftw/devcontainers/features/skills:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| skills | Space separated skill sources. owner/repo installs every skill in the repository; owner/repo@skill installs just that one. Browse https://skills.sh | string | vercel-labs/skills@find-skills |
| agents | Space separated agent ids accepted by `npx skills add --agent`. pi lands in ~/.pi/agent/skills, claude-code in ~/.claude/skills, openhands in ~/.openhands/skills | string | pi |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/elibroftw/devcontainers/blob/main/src/features/skills/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
