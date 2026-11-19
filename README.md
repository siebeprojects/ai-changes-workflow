# ai-changes-workflow

A small, plain workflow for building software with AI agents: think first, build small. Each change gets a few short documents, written in order, and agents plan and build from them.

A change is planned first:

```
changes/feat-short-name/
├── proposal.md   the user story, why, the value, and what we would like to have
├── spec.md       acceptance criteria and requirements, in plain language
└── plan.md       what must exist to meet each requirement, and the decisions
```

Then each repository where it is built gets its own folder with the same name, on the change's branch, committed with the code:

```
changes/feat-short-name/
├── qa.md         how the acceptance criteria built here are verified
└── tasks.md      the tasks built here, one at a time
```

A new change starts with only `proposal.md`. Each next document is added when you start on it, so the files show how far it is. In a single repository, all five documents end up in the same folder.

There is always one store: the place that holds the templates in `changes/_templates/` and the planning documents of each change. With one repository, the repository is its own store. With several, the store is a repository of its own, and the code repositories hold only their `qa.md` and `tasks.md`, so the templates are never copied around.

## Contents

- `AGENTS.md`: engineering rules for agents (Codex, Claude Code and other compatible agents). The workflow rules sit in a marked block.
- `CLAUDE.md`: only imports `AGENTS.md` for Claude Code.
- `.agents/skills/changes-workflow/`: one skill, with `planning.md` and `implementing.md`.
- `changes/_templates/`: the document templates: `proposal.md`, `spec.md` and `plan.md` for planning, `qa.md` and `tasks.md` for building.
- `install.sh`: installs the files above into another repository; nothing else is copied.

## Installing

Clone this repository anywhere, then run the script for one of two situations.

**The store is in the same repository.** The repository gets the rules, the skill and all five templates, and every document of a change goes in its `changes/` folder:

```bash
./install.sh --repo /path/to/repo
```

**The store is a separate repository.** Keep the templates and the planning documents in their own repository (for example `my-changes-store`), and `qa.md` and `tasks.md` with the code. Set up the store once, then install each code repository against it:

```bash
./install.sh --store /path/to/my-changes-store                         # the store, with all templates
./install.sh --repo /path/to/code-repo --store /path/to/my-changes-store  # a code repository, no templates
```

A code repository gets no templates: its rules and skill point to the store's `changes/` folder, as a path relative to the repository such as `../my-changes-store/changes`, also for the `qa.md` and `tasks.md` templates. Claude Code gets access to that folder through `.claude/settings.local.json`. The script stops when the store hasn't been set up yet. A `changes/_templates/` left in a code repository by an earlier version is reported, not removed.

Agents plan and build from the code repository, where they can read the code: they write the planning documents into the store, and `qa.md` and `tasks.md` into `changes/<name>/` on the change's branch. A change built in several repositories gets a `qa.md` and `tasks.md` in each, for the part built there. The change name connects everything: the store folder, the branches and the folders in each repository all have the same name, so `qa.md` and `tasks.md` name the planning folder as plain text, such as `my-changes-store/changes/feat-short-name`, instead of linking to it.

The rules and the skill write `changes/` for the store and `./changes/` for the repository's own folder; installing a code repository only rewrites the first.

Every command takes these options:

```bash
--dry-run     # preview, change nothing
--force       # overwrite conflicts without asking
--no-exclude  # also commit AGENTS.md, CLAUDE.md, the skill and the local settings
```

Run a command again at any time to update a repository.

## What the script does

- **`AGENTS.md`:** creates it with the default rules if missing. In an existing `AGENTS.md`, it only adds or replaces the block between `<!-- changes-workflow:start -->` and `<!-- changes-workflow:end -->`, and keeps the rest. An `AGENTS.md` from an earlier version without markers is replaced as a whole, after asking.
- **`CLAUDE.md`:** creates it if missing; if one exists, it prepends `@AGENTS.md` and keeps the existing content.
- **The skill:** copies `.agents/skills/changes-workflow/` and links it from `.claude/skills/changes-workflow`. Old `plan-change` and `implement-change` skills are reported, not removed.
- **Templates:** copies all five to `changes/_templates/` in the store only: with `--repo` alone and with `--store` alone, not for a code repository. Commit them with the store.
- **Conflicts:** asks for each existing file that differs: `[y]es / [n]o / [d]iff / [a]ll / [q]uit` (default: no). Without a terminal (e.g. CI), conflicts are skipped. Replaced originals go to `.changes-workflow-backup/<timestamp>/`.
- **Git:** privately ignores the agent files in `.git/info/exclude`, which is never committed; `.gitignore` is not touched. In a code repository this includes `.claude/settings.local.json`. Files git already tracks, such as a committed `AGENTS.md`, are not excluded. With `--no-exclude`, nothing is excluded. The templates are never excluded.

## Starting a change

A change can be a new feature, a bug fix, a refactoring or other work. Create `changes/feat-short-name/` (or `fix-`, `refactor-`, and so on) and copy the proposal template into it, or ask your agent to use the `changes-workflow` skill. Once the plan is approved, the agent asks to create the branch `feat-short-name` in each repository where it is built, with `qa.md` and `tasks.md`. Keep `changes/_templates/` unchanged.

## Notes

- `.claude/skills/` contains a symbolic link; preserve symlinks if you copy files manually.
- Skills follow the Agent Skills format (`SKILL.md` with `name` and `description`). Check skill discovery in your versions of Claude Code and Codex.
