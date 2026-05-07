# Contributing to Physica

Read this before pushing any code. The team is 7 people working in parallel on different levels — without a shared workflow we'll step on each other's commits.

If you're new to git collaboration, the **TL;DR**:
1. Pull `main` before you start.
2. Make a branch named after your work.
3. Commit often, with the conventions below.
4. Open a PR. Let one teammate review.
5. Merge. Delete the branch.

---

## Branch Strategy

We use **short-lived feature branches off `main`**. No `develop`, no long-lived branches.

### Branch naming

`<type>/<short-name>` — kebab-case.

| Prefix | When | Examples |
|--------|------|----------|
| `feat/` | New feature, level, mechanic | `feat/shadow-l2`, `feat/voltcity-l1`, `feat/profile-screen` |
| `fix/` | Bug fix | `fix/spark-drag-conflict`, `fix/hub-skyline-overflow` |
| `refactor/` | Code restructure, no behavior change | `refactor/extract-light-cone` |
| `style/` | Visual / UI tweaks, no logic change | `style/realm-card-shadow` |
| `docs/` | Documentation only | `docs/update-readme-w3` |
| `chore/` | Build settings, dependencies, project file | `chore/bump-deployment-target` |
| `art/` | Asset additions / replacements | `art/spark-rive-idle`, `art/cave-background-v2` |

Keep names under ~30 characters. The branch's purpose should be obvious from the name.

### One branch = one concern

If you find yourself fixing 3 unrelated things on the same branch, **stop**. Commit what you have, push it, open a PR for that, and start a new branch for the next concern. Mixed PRs slow down review and create messy history.

---

## Daily Workflow

### Starting work

```bash
# 1. Make sure your local main is current
git checkout main
git pull origin main

# 2. Create your branch
git checkout -b feat/shadow-l2

# 3. Open Xcode, code, commit, repeat
```

### While working

```bash
# Stage just what you want
git add Physica/Features/ShadowRealm/Level2/ShadowRealmLevel2State.swift

# (avoid 'git add .' — it grabs xcuserdata, .DS_Store, etc.)

# Commit with our convention (see below)
git commit -m "feat: add shadow L2 blocker state"
```

### Pulling in others' changes mid-feature

If your branch is open for more than a few hours, others may have merged to `main`. Pull their work into your branch periodically:

```bash
git fetch origin
git rebase origin/main      # preferred — keeps history linear
# or
git merge origin/main        # also fine, slightly messier history
```

Resolve any conflicts (see below), test that the app still builds, continue working.

### Pushing

```bash
git push -u origin feat/shadow-l2     # first push
git push                               # subsequent pushes
```

---

## Pull Request Rules

1. **One PR per branch**, scoped to one feature/fix.
2. **PR title** uses the same convention as commits: `feat: add shadow l2 blocker mechanic`.
3. **PR description** must include:
   - **What** changed (1-3 bullets)
   - **Why** (link to the level spec, issue, or design discussion)
   - **How to test** (the simulator steps to verify the change works)
   - Screenshots or screen-recordings for any visual change
4. **Build before opening.** A red PR wastes everyone's time.
5. **At least 1 reviewer.** Don't self-merge unless it's a docs-only change and no one is online.
6. **Squash-merge by default** when merging into `main`. This keeps `main`'s history clean — one commit per feature.
7. **Delete the branch** after merge (GitHub button).

### When you receive a review

- Address comments by pushing new commits to the same branch (don't force-push if review is in flight).
- Re-request review when ready.
- "Resolve conversation" only after the reviewer has confirmed it.

---

## Commit Message Convention

`<type>: <short description>`

| Type | When | Example |
|------|------|---------|
| `init` | Project setup, scaffolding new realm | `init: scaffold magnetic peaks folder` |
| `feat` | New feature / level / mechanic | `feat: add light reveal mask in shadow l1` |
| `fix` | Bug fix | `fix: resolve gesture conflict on spark` |
| `refactor` | Restructure, no behavior change | `refactor: extract LightConeView` |
| `style` | UI / visual / formatting only | `style: align hub button shadow` |
| `docs` | Documentation only | `docs: add backlog entry for echo valley` |
| `chore` | Build / config / project file | `chore: bump iOS target to 26.4` |
| `test` | Tests | `test: add HintEngine tick coverage` |
| `art` | Asset add / replace | `art: add spark idle rive file` |

**Rules:**
- Lowercase, imperative: `feat: add ...` not `feat: added ...`.
- Under 72 characters on the first line.
- No trailing period.
- Optional body after a blank line for *why* (motivation, links, gotchas) — not *what* (the diff already shows that).

---

## Conflict Resolution

When `git rebase origin/main` or merge raises conflicts:

1. **Don't panic.** Conflicts mean two people edited overlapping lines. Both versions exist; you choose how they merge.
2. **Don't blindly accept "incoming" or "current".** Read what each version is trying to do, and produce the version that achieves both intents.
3. **Build the app after every conflict resolution.** A green build is your sanity check.
4. **If you're unsure, ping the other author** before resolving. It's faster than guessing.
5. **Avoid working on the same file as a teammate** when you can. If two devs need to edit `RootView.swift`, coordinate verbally first — agree who lands first, the other rebases.

### Common conflict zones in Physica

| File | Why it conflicts | How to avoid |
|------|------------------|--------------|
| `App/RootView.swift` | New levels add destinations | Land routes in small batches, communicate before adding |
| `App/AppRouter.swift` | New `NavRoute` cases | Same as above |
| `Models/SeedData.swift` | Adding levels to a realm | Touch only when adding levels to your assigned realm |
| `Core/Audio/AudioManager.swift` | New SFX enum cases | Add your enum case at the bottom of the enum to minimize conflicts |
| `.gitignore` | Rare, but possible | Talk first before adding broad ignores |

---

## What NOT to Commit

The `.gitignore` already covers most of this. Double-check before pushing:

| File / folder | Why excluded |
|---------------|--------------|
| `xcuserdata/` | Per-user Xcode UI state (window positions, breakpoints) |
| `*.xcuserstate` | Xcode session state |
| `build/`, `DerivedData/` | Build artifacts |
| `.swiftpm/` | SwiftPM local cache |
| `.DS_Store` | macOS Finder metadata |
| `*.swp`, `*~` | Editor swap files |
| `Pods/` | (we don't use CocoaPods, but excluded for safety) |

If you accidentally committed one of these, untrack it:

```bash
git rm --cached -r xcuserdata
git commit -m "chore: stop tracking xcuserdata"
```

**Never commit** anything containing API keys, signing certificates, or `.p12` / `.mobileprovision` files. We don't have any of these yet — keep it that way.

---

## Safety Rules

These exist because someone, somewhere, has lost a week of work to each one of them.

- **Never `git push --force` to `main`.** If you absolutely must rewrite a branch, force-push only your own feature branch (and warn the reviewer if there's an open PR).
- **Never `git reset --hard` without checking `git status` first.** It throws away uncommitted work permanently.
- **Never delete the remote `main`.** It would take down everyone.
- **Don't run `git rebase -i` if you don't already know what it does.** Ask first.
- **Don't commit massive files.** Anything > 5 MB should be a Rive/Lottie/audio asset and you should mention it in PR description so reviewers expect the size.
- **If you don't understand what git is asking, stop.** It's faster to ask a teammate or the project lead than to try `--force` your way out.

---

## Setting Up the Remote (Project Lead)

```bash
# from the repo root (folder containing README.md, ARCHITECTURE.md, Physica/)
git remote add origin git@github.com:<owner>/<repo>.git
git branch -M main
git push -u origin main
```

After the remote exists, **invite the 6 teammates as collaborators** (Settings → Collaborators on GitHub) and **protect `main`**:
- Settings → Branches → Add rule for `main`
  - Require pull request reviews before merging (1 approver)
  - Require status checks to pass (when CI is set up)
  - Disallow force-pushes
  - Disallow deletions

---

## Quick Reference

```bash
# fresh start
git checkout main && git pull origin main
git checkout -b feat/my-thing

# during work
git status                                  # what's changed?
git diff                                    # what does it look like?
git add <specific-file>                     # stage a file
git commit -m "feat: do the thing"          # commit it
git push -u origin feat/my-thing            # first push (later: just `git push`)

# pulling others' work into your branch
git fetch origin
git rebase origin/main                       # preferred
# resolve conflicts -> git add <file> -> git rebase --continue

# checking what others are doing
git fetch origin
git log --oneline --all --graph -20

# undo last commit (kept changes staged)
git reset --soft HEAD^

# undo uncommitted changes to a single file
git checkout -- <file>
```

---

*Last updated: May 8, 2026*
