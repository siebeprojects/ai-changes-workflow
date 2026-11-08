#!/usr/bin/env bash
# Install the changes workflow (agent rules, the changes-workflow skill and the
# change templates) into another repository.
#
# AGENTS.md: the workflow rules live in a block between
#   <!-- changes-workflow:start --> and <!-- changes-workflow:end -->.
# A new AGENTS.md gets the default rules plus that block. In an existing
# AGENTS.md only the block is added or replaced; everything else is kept.
#
# CLAUDE.md only imports AGENTS.md (@AGENTS.md). .claude/skills/ only holds a
# symlink to the canonical skill in .agents/skills/.
#
# By default the agent files are ignored privately via .git/info/exclude
# (never committed, never written to .gitignore). The templates in
# changes/_templates/ are meant to be committed.
#
# With --changes <path>, the change documents live elsewhere (for example a
# separate store repo): no templates are copied, the rules and the skill point
# to that path, and Claude Code gets access to it.
#
# Usage: ./install.sh [--force] [--dry-run] [--no-exclude] [--changes <path>] <target-repo>

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL="changes-workflow"
START_MARK="<!-- changes-workflow:start -->"
END_MARK="<!-- changes-workflow:end -->"
FORCE=0
DRY_RUN=0
EXCLUDE=1
TARGET=""
CHANGES="changes"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--force] [--dry-run] [--no-exclude] [--changes <path>] <target-repo>

Installs the changes workflow into <target-repo>:
  AGENTS.md                  workflow rules in a marked block (rest of the file is kept)
  CLAUDE.md                  imports AGENTS.md
  .agents/skills/$SKILL/     the skill, linked from .claude/skills/$SKILL
  changes/_templates/        the document templates (commit these)

When a file already exists and differs, you are asked whether to overwrite
it. Without a terminal (e.g. CI), conflicting files are skipped.

Options:
  --force           Overwrite files that differ without asking
                    (originals moved to .changes-workflow-backup/<timestamp>/)
  --dry-run         Show what would happen without changing anything
  --no-exclude      Do not add the agent files to .git/info/exclude
                    (use this when they should be committed too)
  --changes <path>  Where the change documents live, relative to <target-repo>
                    (default: changes). With another path, for example
                    ../my-changes-store/changes, no templates are copied, the
                    rules and the skill point to that path, and Claude Code gets
                    access to it through .claude/settings.local.json.
  -h, --help        Show this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --force) FORCE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --no-exclude) EXCLUDE=0 ;;
    --changes)
      shift
      if [ $# -eq 0 ]; then echo "--changes needs a path" >&2; exit 1; fi
      CHANGES="${1%/}" ;;
    --changes=*) CHANGES="${1#--changes=}"; CHANGES="${CHANGES%/}" ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    *)
      if [ -n "$TARGET" ]; then echo "Only one target allowed" >&2; exit 1; fi
      TARGET="$1" ;;
  esac
  shift
done

if [ -z "$TARGET" ]; then usage >&2; exit 1; fi
if [ ! -d "$TARGET" ]; then echo "Error: target '$TARGET' is not a directory" >&2; exit 1; fi
TARGET="$(cd "$TARGET" && pwd)"
if [ "$TARGET" = "$SRC" ]; then echo "Error: target is this repository itself" >&2; exit 1; fi

# Files to install are staged in a temporary folder, so paths can be adjusted
# for --changes before they are compared with and copied to the target.
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
(cd "$SRC" && find AGENTS.md CLAUDE.md ".agents/skills/$SKILL" changes/_templates -type f ! -name '.DS_Store') |
  while IFS= read -r f; do
    mkdir -p "$STAGE/$(dirname "$f")"
    cp -p "$SRC/$f" "$STAGE/$f"
  done

EXTERNAL_CHANGES=0
CHANGES_ABS=""
if [ "$CHANGES" != "changes" ]; then
  EXTERNAL_CHANGES=1
  case "$CHANGES" in /*) CHANGES_ABS="$CHANGES" ;; *) CHANGES_ABS="$TARGET/$CHANGES" ;; esac
  if [ -d "$CHANGES_ABS" ]; then
    CHANGES_ABS="$(cd "$CHANGES_ABS" && pwd)"
  else
    echo "Warning: changes folder '$CHANGES' does not exist (relative to $TARGET)."
  fi
  # Point the rules and the skill to the external changes folder.
  for f in "$STAGE/AGENTS.md" "$STAGE/.agents/skills/$SKILL"/*.md; do
    [ -f "$f" ] || continue
    sed "s#\`changes/#\`$CHANGES/#g" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  done
  # The templates live with the changes, not in this repository.
  rm -rf "$STAGE/changes"
fi

IS_GIT=0
if git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  IS_GIT=1
else
  echo "Warning: $TARGET is not a git repository; changes cannot be reviewed with git diff."
fi

COPIED=0; SKIPPED=0; UNCHANGED=0
SKIPPED_LIST=""

# Run a command, unless in dry-run mode (the action is already reported).
run() {
  if [ "$DRY_RUN" -eq 0 ]; then "$@"; fi
}

# Backups go into one timestamped folder per run, mirroring the original
# paths. Created on first use only.
BACKUP_ROOT="$TARGET/.changes-workflow-backup"
BACKUP_DIR=""
BACKED_UP=0

# Move an existing path into this run's backup folder.
backup() {
  local path="$1" rel="${1#$TARGET/}"
  # A symlink holds no content of its own, so just remove it.
  if [ -L "$path" ]; then
    echo "  remove   $rel (old symlink -> $(readlink "$path"); not backed up)"
    run rm "$path"
    return
  fi
  if [ -z "$BACKUP_DIR" ]; then
    BACKUP_DIR="$BACKUP_ROOT/$(date +%Y-%m-%d_%H%M%S)"
    local base="$BACKUP_DIR" n=1
    while [ -e "$BACKUP_DIR" ]; do BACKUP_DIR="$base-$n"; n=$((n + 1)); done
  fi
  echo "  backup   $rel -> ${BACKUP_DIR#$TARGET/}/$rel"
  run mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
  run mv "$path" "$BACKUP_DIR/$rel"
  BACKED_UP=$((BACKED_UP + 1))
}

# Ask questions only when a terminal is available and no answer is implied
# by --force or --dry-run. Prompts read from /dev/tty.
INTERACTIVE=0
if [ "$FORCE" -eq 0 ] && [ "$DRY_RUN" -eq 0 ] && { : </dev/tty; } 2>/dev/null; then
  INTERACTIVE=1
fi
OVERWRITE_ALL="$FORCE"

# Show how an existing target differs from what would be installed.
show_diff() {
  local src="$1" dst="$2"
  if [ -L "$dst" ]; then
    echo "    existing is a symlink -> $(readlink "$dst")"
  elif [ -d "$dst" ]; then
    diff -ru "$dst" "$src" || true
  else
    diff -u "$dst" "$src" || true
  fi
}

# Decide what to do with an existing target that differs.
# Returns 0 to overwrite, 1 to skip; exits on "quit".
resolve_conflict() {
  local label="$1" src="$2" dst="$3" answer
  [ "$OVERWRITE_ALL" -eq 1 ] && return 0
  [ "$INTERACTIVE" -eq 1 ] || return 1
  while true; do
    {
      echo "  conflict $label already exists and differs."
      printf '           Overwrite? [y]es / [n]o / [d]iff / [a]ll / [q]uit (default: n): '
    } >/dev/tty
    read -r answer </dev/tty || answer="n"
    case "$answer" in
      y|Y|yes) return 0 ;;
      ""|n|N|no) return 1 ;;
      d|D|diff) show_diff "$src" "$dst" >/dev/tty ;;
      a|A|all) OVERWRITE_ALL=1; return 0 ;;
      q|Q|quit)
        echo "  quit     installation stopped; files already installed are kept."
        update_exclude
        print_summary
        exit 1 ;;
      *) echo "           Please answer y, n, d, a or q." >/dev/tty ;;
    esac
  done
}

# Record a skipped target for the summary.
skip() {
  echo "  skip     $1 (exists and differs)"
  SKIPPED=$((SKIPPED + 1)); SKIPPED_LIST="$SKIPPED_LIST $1"
}

# Copy one file (path relative to the repo root) from STAGE to TARGET.
copy_file() {
  local rel="$1" src="$STAGE/$1" dst="$TARGET/$1"
  if [ -e "$dst" ]; then
    if cmp -s "$src" "$dst"; then
      UNCHANGED=$((UNCHANGED + 1)); return
    fi
    if ! resolve_conflict "$rel" "$src" "$dst"; then skip "$rel"; return; fi
    backup "$dst"
  fi
  echo "  copy     $rel"
  run mkdir -p "$(dirname "$dst")"
  run cp -p "$src" "$dst"
  COPIED=$((COPIED + 1))
}

# Print the workflow block (markers included) from a file.
extract_block() {
  awk -v s="$START_MARK" -v e="$END_MARK" '
    $0 == s { inside = 1 }
    inside { print }
    $0 == e { inside = 0 }
  ' "$1"
}

# AGENTS.md: create it with the default rules, or add/replace only the
# workflow block in an existing file.
install_agents_md() {
  local src="$STAGE/AGENTS.md" dst="$TARGET/AGENTS.md" block tmp
  if [ ! -e "$dst" ]; then copy_file "AGENTS.md"; return; fi

  block="$(mktemp)"; tmp="$(mktemp)"
  extract_block "$src" > "$block"

  if grep -qxF "$START_MARK" "$dst" && grep -qxF "$END_MARK" "$dst"; then
    # Replace the existing block, keep everything around it.
    awk -v s="$START_MARK" -v e="$END_MARK" -v bf="$block" '
      $0 == s { while ((getline line < bf) > 0) print line; skipping = 1; next }
      skipping && $0 == e { skipping = 0; next }
      !skipping { print }
    ' "$dst" > "$tmp"
    if cmp -s "$tmp" "$dst"; then
      UNCHANGED=$((UNCHANGED + 1))
    else
      echo "  update   AGENTS.md (workflow block replaced; rest kept)"
      if [ "$DRY_RUN" -eq 0 ]; then cat "$tmp" > "$dst"; fi
      COPIED=$((COPIED + 1))
    fi
  elif grep -qxF "## Change documentation" "$dst"; then
    # An AGENTS.md from an earlier version without markers: the whole file
    # came from the template, so replace it instead of adding a second copy.
    if resolve_conflict "AGENTS.md (earlier version, no workflow markers)" "$src" "$dst"; then
      backup "$dst"
      echo "  copy     AGENTS.md"
      run cp -p "$src" "$dst"
      COPIED=$((COPIED + 1))
    else
      skip "AGENTS.md"
    fi
  else
    # The repository's own AGENTS.md: append the block.
    echo "  update   AGENTS.md (workflow block added at the end; rest kept)"
    if [ "$DRY_RUN" -eq 0 ]; then
      {
        if [ -s "$dst" ] && [ -n "$(tail -c 1 "$dst")" ]; then echo; fi
        echo
        cat "$block"
      } >> "$dst"
    fi
    COPIED=$((COPIED + 1))
  fi
  rm -f "$block" "$tmp"
}

# CLAUDE.md: copy if missing; otherwise make sure it imports AGENTS.md
# without discarding the target's existing Claude-specific content.
install_claude_md() {
  local dst="$TARGET/CLAUDE.md"
  if [ ! -e "$dst" ]; then copy_file "CLAUDE.md"; return; fi
  if grep -qxF '@AGENTS.md' "$dst"; then UNCHANGED=$((UNCHANGED + 1)); return; fi
  echo "  update   CLAUDE.md (prepend @AGENTS.md import; existing content kept)"
  if [ "$DRY_RUN" -eq 0 ]; then
    local tmp; tmp="$(mktemp)"
    { printf '@AGENTS.md\n\n'; cat "$dst"; } > "$tmp"
    cat "$tmp" > "$dst"   # keep original file permissions
    rm -f "$tmp"
  fi
  COPIED=$((COPIED + 1))
}

# Link .claude/skills/<skill> -> ../../.agents/skills/<skill> (relative, portable).
link_skill() {
  local link="$TARGET/.claude/skills/$SKILL" want="../../.agents/skills/$SKILL"
  if [ -L "$link" ] && [ "$(readlink "$link")" = "$want" ]; then
    UNCHANGED=$((UNCHANGED + 1)); return
  fi
  if [ -e "$link" ] || [ -L "$link" ]; then
    if ! resolve_conflict ".claude/skills/$SKILL" "$STAGE/.agents/skills/$SKILL" "$link"; then
      skip ".claude/skills/$SKILL"; return
    fi
    backup "$link"
  fi
  echo "  link     .claude/skills/$SKILL -> $want"
  run mkdir -p "$TARGET/.claude/skills"
  run ln -s "$want" "$link"
  COPIED=$((COPIED + 1))
}

# Mention skills installed by earlier versions; they are not removed.
report_old_skills() {
  local name
  for name in plan-change implement-change; do
    if [ -e "$TARGET/.agents/skills/$name" ] || [ -L "$TARGET/.claude/skills/$name" ]; then
      echo "  note     old skill '$name' found; $SKILL replaces it. Remove .agents/skills/$name and .claude/skills/$name."
    fi
  done
}

# Give Claude Code access to an external changes folder. Only creates the
# local settings file; an existing one is not edited, only reported.
install_claude_settings() {
  [ "$EXTERNAL_CHANGES" -eq 1 ] || return 0
  local file="$TARGET/.claude/settings.local.json"
  if [ -e "$file" ]; then
    if grep -qsF "\"$CHANGES_ABS\"" "$file"; then UNCHANGED=$((UNCHANGED + 1)); return; fi
    echo "  note     .claude/settings.local.json exists; add this to permissions.additionalDirectories:"
    echo "           \"$CHANGES_ABS\""
    return
  fi
  echo "  create   .claude/settings.local.json (access to $CHANGES_ABS)"
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$TARGET/.claude"
    printf '{\n  "permissions": {\n    "additionalDirectories": ["%s"]\n  }\n}\n' "$CHANGES_ABS" > "$file"
  fi
  COPIED=$((COPIED + 1))
}

print_summary() {
  echo
  echo "Done: $COPIED installed/updated, $UNCHANGED already up to date, $SKIPPED skipped."
  if [ "$SKIPPED" -gt 0 ]; then
    echo "Skipped (review and merge manually, or rerun to overwrite):"
    for s in $SKIPPED_LIST; do echo "  - $s"; done
  fi
  if [ "$BACKED_UP" -gt 0 ] && [ "$DRY_RUN" -eq 0 ]; then
    echo "Backed up $BACKED_UP original(s) to: ${BACKUP_DIR#$TARGET/}/"
    echo "  Delete that folder once you have reviewed the changes."
  fi
}

# Privately ignore the agent files by adding root-anchored patterns to
# .git/info/exclude (never committed). Files git already tracks, such as a
# committed AGENTS.md, are not excluded: commit the added block with them.
# The templates are never excluded; an old /changes/_templates/ line from
# earlier versions is removed.
update_exclude() {
  [ "$EXCLUDE" -eq 1 ] || return 0
  if [ "$IS_GIT" -eq 0 ]; then
    echo "  note     not a git repository; skipping .git/info/exclude"
    return 0
  fi

  local patterns="/AGENTS.md /CLAUDE.md /.agents/skills/$SKILL/ /.claude/skills/$SKILL /.changes-workflow-backup/"
  [ "$EXTERNAL_CHANGES" -eq 1 ] && patterns="$patterns /.claude/settings.local.json"

  # --git-path also resolves correctly for worktrees and submodules.
  local file
  file="$(git -C "$TARGET" rev-parse --git-path info/exclude)"
  case "$file" in /*) ;; *) file="$TARGET/$file" ;; esac

  if grep -qsxF -- "/changes/_templates/" "$file"; then
    echo "  include  /changes/_templates/ (removed from .git/info/exclude)"
    if [ "$DRY_RUN" -eq 0 ]; then
      grep -vxF -- "/changes/_templates/" "$file" > "$file.tmp" || true
      mv "$file.tmp" "$file"
    fi
  fi

  local p missing="" path
  for p in $patterns; do
    path="${p#/}"; path="${path%/}"
    if [ -n "$(git -C "$TARGET" ls-files -- "$path" | head -n 1)" ]; then
      echo "  note     $path is tracked by git; not excluded (commit the installed changes)"
      continue
    fi
    grep -qsxF -- "$p" "$file" || missing="$missing $p"
  done

  if [ -z "$missing" ]; then
    echo "  exclude  .git/info/exclude already up to date"
    return 0
  fi
  for p in $missing; do echo "  exclude  $p"; done
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$(dirname "$file")"
    {
      if [ -s "$file" ] && [ -n "$(tail -c 1 "$file")" ]; then echo; fi
      grep -qsxF '# changes-workflow (added by install.sh)' "$file" \
        || echo '# changes-workflow (added by install.sh)'
      for p in $missing; do echo "$p"; done
    } >> "$file"
  fi
}

echo "Installing the changes workflow"
echo "  from: $SRC"
echo "  into: $TARGET"
[ "$EXTERNAL_CHANGES" -eq 1 ] && echo "  changes: $CHANGES"
[ "$DRY_RUN" -eq 1 ] && echo "  mode: dry-run (no changes will be made)"
echo

# 1. Rules: AGENTS.md (workflow block) and the Claude Code import.
install_agents_md
install_claude_md

# 2. The skill and, unless the changes live elsewhere, the templates.
for dir in ".agents/skills/$SKILL" changes/_templates; do
  [ -d "$STAGE/$dir" ] || continue
  while IFS= read -r f; do
    copy_file "${f#$STAGE/}"
  done < <(find "$STAGE/$dir" -type f | sort)
done
link_skill
report_old_skills
install_claude_settings

# 3. Keep the agent files out of git, privately.
update_exclude

print_summary
if [ "$DRY_RUN" -eq 0 ]; then
  echo
  echo "Next steps:"
  if [ "$EXTERNAL_CHANGES" -eq 1 ]; then
    echo "  1. Review AGENTS.md and .agents/skills/$SKILL/."
    echo "  2. Change documents live in $CHANGES; templates are in $CHANGES/_templates/."
  else
    echo "  1. Review AGENTS.md, .agents/skills/$SKILL/ and changes/_templates/, and commit the templates."
    echo "  2. Start a change: mkdir changes/feat-short-name and copy the proposal template into it."
  fi
fi
