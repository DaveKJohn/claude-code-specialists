## fix/1493-fold-on-merge-queue

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. Same rule, same reason: no gate reads this region (Dave, August 26, 2026).
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THIS DIRECTORY -- `CHANGELOG.md` sits here too, so
> write each path exactly as it reads in this file.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Adds .github/workflows/fold-on-merge.yml: on push to main, runs check-unfolded-entry.ps1 and, if it finds a leftover, folds it via fold-changelog-entry.ps1 -Commit -Push (fold-all mode, no per-branch derivation needed -- it already resolves each unfolded doc's own PR). Code-complete but inert until Dave adds the GitHub Actions app as a bypass actor on main-ci-gate (issue #1493) -- that ruleset change is his to make, not this branch's.

### CREATE

- [x] Add `.github/workflows/fold-on-merge.yml`: on push to `main`, run
      `check-unfolded-entry.ps1 -Branch main`; if it reports a leftover, run
      `fold-changelog-entry.ps1 -Commit -Push` (fold-all mode -- it already resolves each unfolded
      document's own PR via its own `gh pr list` lookup, so no branch has to be derived from the push
      event or the merge-commit message). Job permissions: `contents: write` + `pull-requests: read`
      (the second is required -- the fold step's own `gh pr list` needs it, and declaring any
      `permissions:` block sets every unlisted scope to `none`).
- [x] Manually cleared the one live instance already on the trunk when this branch was cut
      (`dkj-policy/feat-1480-rename-teams-to-dkj-teams.md`, from the `feat/1480` queue merge) via
      `fold-changelog-entry.ps1 -Branch feat/1480-rename-teams-to-dkj-teams -Commit -Push` -- unrelated
      to this branch's diff, done directly on `main` under the existing fold exception, so the workflow
      being added here starts from a clean trunk.

### TEST

No PowerShell changed, so no suite needed updating. What was verified instead:

- Read `check-unfolded-entry.ps1` and `fold-changelog-entry.ps1` end to end to confirm fold-all mode's
  branch/PR resolution needs no input from the push event.
- Confirmed live, via `gh api`, that `main-ci-gate`'s `bypass_actors` does not yet include the GitHub
  Actions app (`integration_id 15368`) -- so this workflow's fold step will fail its own `git push`
  with a ruleset rejection until that bypass is added. That is Dave's action, tracked on #1493, not
  this branch's.
- **Test gap, said out loud rather than faked**: this workflow's actual behaviour (a real queue merge,
  the bypass in place, the fold landing) cannot be exercised outside a live merge queue on this repo's
  own `main`. The honest verification is a real queue merge once the bypass exists -- see the PR body.

### DEPLOY: fix/1493-fold-on-merge-queue

Adds `.github/workflows/fold-on-merge.yml`: after every push to `main`, it checks for a changelog
entry left unfolded by a merge the shipping session never saw -- the `main-ci-gate` merge queue (#1492)
merges a PR itself, so `ship-pr.ps1`'s own post-merge fold step never runs for a queue-merged PR, and
the branch's `dkj-policy/<branch>.md` dossier was otherwise left sitting on the trunk with nobody to
fold it but a human doing it by hand. The workflow adds no new detection logic and no new fold logic --
it runs the two scripts this repo already has (`check-unfolded-entry.ps1`, then
`fold-changelog-entry.ps1 -Commit -Push` in its existing fold-all mode) from the one place that always
sees a queue merge: a push to `main`.

**Code-complete, and inert until one more thing lands that is not part of this PR.** `main-ci-gate`'s
`required_status_checks` rule blocks any push to `main` -- including this job's -- unless the pushing
actor is a listed bypass actor. The default `GITHUB_TOKEN` a workflow run carries pushes as the GitHub
Actions app, which is not on that list today. Adding it is a repo-settings/ruleset change, so it is
Dave's action to take, not this branch's -- see #1493 for the exact API payload already prepared for
him. Until he applies it, this workflow's fold step will visibly fail its own `git push` with a
ruleset rejection whenever it finds something to fold, which is the correct failure mode for code that
is finished but waiting on a permission it cannot grant itself.

**Score:** 4

#### What makes this deploy extra special

N/A -- this workflow lives in `.github/workflows/`, not under `plugins/`, so it never ships to a
consumer via the plugin mechanism. It is specific to how this source repo's own `main` is guarded.

**Score:** N/A

#### Pull Request

Fold the changelog entry automatically after a queue merge

