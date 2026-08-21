This feature installs [Agent Skills](https://agentskills.io) — folders with a `SKILL.md` that teach an agent a specific capability — using the [`skills` CLI](https://github.com/vercel-labs/skills) from the open [skills.sh](https://skills.sh) ecosystem.

## Source formats

The `skills` option takes space separated sources:

| Format | Installs |
| --- | --- |
| `owner/repo` | Every skill in the repository, e.g. `runpod/runpod-plugins-official` |
| `owner/repo@skill` | One skill from the repository, e.g. `vercel-labs/skills@find-skills` |
| `https://github.com/...` | Full GitHub / GitLab / git URL, or a `/tree/...` path to one skill |

The default is `vercel-labs/skills@find-skills` — the most installed skill on skills.sh, which teaches an agent to discover and install further skills itself with `npx skills find` / `npx skills add`. Overriding the option replaces the default, so keep `vercel-labs/skills@find-skills` in the list if you want it.

## Where skills land

Per the `agents` option (default `pi`), matching the CLI's `--agent` flag:

| Agent id | Path |
| --- | --- |
| `pi` | `~/.pi/agent/skills/` |
| `claude-code` | `~/.claude/skills/` |

pi also reads the shared `~/.agents/skills/` directory, so skills installed for other agents using that location are visible to it too.

## Why the feature re-installs on container create

Skills live in `$HOME`, and the ai-agent template mounts `~/.pi` and `~/.claude` as named volumes. Docker copies image content into a volume only on its first mount; on every rebuild the surviving volume shadows the image copy, which would freeze skills at whatever version the volume was created with. The feature therefore writes `/usr/local/bin/install-agent-skills`, runs it at build time, and re-runs it (best effort, `|| true`) from `postCreateCommand` once the volumes are attached. `--copy` is used so volumes hold real files instead of symlinks back to `~/.agents`, which would dangle after a rebuild.

## Security

Skills are instructions your agent will follow with its full permissions. Review anything you install — skills.sh runs automated audits (Gen Agent Trust Hub, Socket, Snyk) and surfaces them per skill, but that is a filter, not a guarantee. Pin to a repo you trust rather than installing by bare name.
