---
id: 15
group: 05
---

# Sylvester ⚙️ · claude-code-specialists addendum

> Repo-lens (claude-code-specialists) accompanying the portable playbook in the `dkj-team-alpha` plugin (`plugins/dkj-teams/dkj-team-alpha/manuals/05-15-manual.md`). This file does not describe the craft, but what Sylvester does in this repo.

A system administrator does the same thing everywhere — manage the harness and the tooling the team
works in: scripts, config, the safety guards. **What is repo-specific in claude-code-specialists is not
that Sylvester maintains the harness, but which scripts, manifests, and config that involves here.**
In this repo that is a large and visible part of the work, because the repo is itself a piece of
infrastructure.

### What Sylvester owns here

- **`scripts/lint/check-plugin-integrity.ps1`** — the PR lint gate: validates `marketplace.json` +
  every `plugin.json` and the agent-def/manual frontmatter (`name`/`id`/`group` + filename match),
  scans for dead links (in `README.md`, `CHANGELOG.md`, the manuals, `SKILL.md`s, and `releases/**`),
  checks that every `scripts/**/*.ps1` parses without errors (catching syntax errors in the
  orchestration that would only break at runtime), and guards (check 7) that every shared-block
  region in an agent def still equals its source in `agent-shared/`. **Check 28 reads that same
  scan set a second time for `@`-imports** (August 26, 2026, issue #874), because an import is a
  different syntax and the link scan matched none of it. It is worth separating from its sibling by
  what being wrong costs: a dead link costs a reader one click, a dead import costs the session **the
  whole document** — Claude Code drops one it cannot resolve without erroring, and this repo's
  always-on path is assembled entirely out of three of them, so the layer that vanishes is the one
  carrying the safety rules or the roster. It reuses `measure-context-lib.ps1`'s parser rather than
  restating the three resolution rules, so the gate and `measure-always-on.ps1` cannot drift on what an
  import means; a target outside the repo is counted, never refused, because a `~/`-relative import
  points into the marketplace clone and CI is a machine without one. **Checks 9 and 17 were retired on
  August 8, 2026** with the documents they guarded — the per-plugin `RELEASE.md` card and
  `CHANGELOG.md`. Both were the right repair for a real defect (a version stated twice, and a
  write-once intro that drifted), and both dissolved rather than being weakened: with the second copy
  gone there is nothing left to hold against the first. **The general shape is worth keeping: a check
  that compares two statements of one fact is made unnecessary by deleting one of them, and that is a
  better outcome than a better check.** **Check 11 is the one that guards a
  doc against reality rather than against itself:** every printed `claude plugin
  install`/`update`/`uninstall` — recognised by its `@`-target, which is what separates an instruction
  from prose discussing the command — must carry `--scope project`, and `install`/`update` must name
  the marketplace refresh nearby. Both fail *silently* when missing, which is why three adoption
  rounds in a row found this same class and four doc fixes only ever closed the instances. History
  (`CHANGELOG.md`, `releases/**`, root entry files) is excluded permanently: it records
  what was true then. Since #315 the scope rule is **verb-specific** — `uninstall` also accepts
  `--scope local`, because that is the only command that removes a record a session start left at that
  scope, and a gate demanding `project` there would have rejected the correct instruction and enforced the
  assumption round v8 disproved. **Check 12 is check 11's sibling, the same idea one level up:** a fenced
  block that reads `installed_plugins.json` *in code* must select `projectPath`, `scope`, `version` **and**
  `gitCommitSha`. It came out of round v8, whose three findings (#313/#314/#315) read as unrelated and were
  one class — the family's own verification query printed a green that could not distinguish the release
  from `main` after it, one record from two, or `project` from `local`. Closing those three by hand would
  have been the fourth round in a row to close *instances* of a class that kept coming back. Both checks
  answer the same **mention vs. use** question with a positional discriminator (check 11 the `@`-target,
  check 12 "does the block actually parse the file"), which makes this the third instance of that reasoning
  in this file. **Check 18 guards the shared source against its own documentation:** every parameter of a
  mirrored entry point must be named in the skill that documents it, because a consumer has only the mirror
  and that page — so a parameter the page never names does not exist for them, escape valves included. It
  is a repair with a measured cause (August 4, 2026): the `fold-changelog` skill told consumers to commit
  the fold *by hand* for two days after the script gained `-Commit`/`-Push`, since that improvement was
  written into this repo's lens. Four more surfaced immediately, `-Bump` and `-NoPush` among them — the
  latter being the only step where a human sees the assembled release before it is public. Two design notes
  worth keeping: the mapping and the per-parameter exemptions are declared **in the registry beside the
  registration**, the same reasoning `LibOnly` already carries, so a newly shared script cannot fall out of
  the check silently; and parameters are read via the **PowerShell parser**, because the regex first used
  for it missed a `[Parameter(...)]`-attributed parameter and would have given the gate the exact blind
  spot it exists to close. An entry point declaring *no* skill is reported in the coverage line rather than
  as an error — `ship-pr`, `fix-mojibake`, `verify-resolved-issues` and `check-script-contract` are in that
  state today, and the first three are real gaps rather than deliberate ones. This is the safety guard that
  [Derek #05](05-05-extension.md)'s `open-pr.ps1` runs before every push — and that `cut-release.ps1`
  runs before a release. **Check 23, `[plugin-kind]`, added August 9, 2026, and its reason was replaced on
  August 26, 2026 rather than left standing:** every published plugin must be `team-*` under
  `plugins/dkj-teams/` or a way of working by name, and a name carrying neither shape is an
  error rather than a style note. Since
  [#1467](https://github.com/DaveKJohn/claude-code-specialists/issues/1467) only `*-policy` /
  `*-policy-*` still carry a directory rule on the workflow side — `plugins/dkj-policy/`, the government,
  with the prime ministry at its root and each ministry a level inside it; `workflow-*`,
  `contributing-*` and `*-codex` are accepted by name and held to no location. It used to have teeth because the core team's `workflow-sessioncheck`
  hook decided what counted as a workflow by that prefix alone — that hook was retired with
  `workflow-default` under [#886](https://github.com/DaveKJohn/claude-code-specialists/issues/886), so the
  borrowed justification is gone. **What replaced it is internal to the check and stronger for it:** the
  directory half is *derived* from the name, so a plugin matching neither prefix falls through both
  branches and has its location held against nothing at all. An unprefixed name does not read untidily —
  it switches the check off for itself, silently.
- **`.github/workflows/ci.yml`** — the CI gate on GitHub: runs the same lint gate + all test suites
  (`scripts/tests/*.tests.ps1`) on every PR and every push to `main`, so the guard also applies to
  work that comes about outside `open-pr.ps1`. **"The same" is literal since August 7, 2026** — the step
  dot-sources `native-capture-lib.ps1` and calls `Invoke-TestSuiteGate`, the one function `open-pr.ps1`
  and `cut-release.ps1` also call. It held its own inline `foreach` until then, which is how a gate
  improvement can land in both local callers and miss the only one that actually blocks a merge; the
  asserts that keep it from coming back are in `cut-release-guardrail.tests.ps1`. It passes
  `-MaxParallel ([Environment]::ProcessorCount)` deliberately: the lib's default holds two cores back so a
  developer's machine stays usable, and on a four-core runner nobody is sitting at, that reservation would
  cost half the box.

  **AND SINCE [#1443](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1443) CI is no longer
  the only caller that can choose** (September 5, 2026). `open-pr.ps1` and `ship-pr.ps1` take the same
  `-MaxParallel` and hand it down through `Invoke-WorkflowGates`, which had been the missing hop: the
  parameter existed at the bottom of the chain and at the top of CI's, and nowhere in between. Measured on
  this machine — 18 cores, so 16 lanes — the default passed once at 716s and was then **killed twice by
  the harness for running out of memory**, where `-MaxParallel 4` passed in 888s. The reservation formula
  reasons about cores; what ran out was memory. **The default is unchanged**, deliberately: one machine is
  not a measurement of the formula, and what #1443 was actually about is that the only way past a gate
  that would not finish was `-SkipTests` — a skip and a smaller run leaving the same trace afterwards.
  The consumer-facing half is in the `open-pr` skill page, which is where a session reads it.

  **EVERY PUSH TO `main` IS ITS OWN CONCURRENCY GROUP, and before
  [#1294](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1294) half of them were never
  gated at all.** The block used to key one group on `github.ref`, i.e. one group for the whole trunk,
  and leaned on `cancel-in-progress: ${{ github.event_name == 'pull_request' }}` to keep the fold commit
  from cancelling the merge commit's run. It did not, and could not — the portable half of why is a hard
  rule in [Sylvester's manual](../../../plugins/dkj-teams/dkj-team-alpha/manuals/05-15-manual.md#sylvesters-hard-rules):
  the field governs the *in-progress* run, while a group also drops a **pending** one when a third
  arrives. **What made it bite here is this repo's own trunk rhythm**, which is the repo-specific half:
  `ship-pr` pushes twice per branch 6s apart, a run takes ~15 minutes, and `windows-latest` queues for
  seconds — so the merge commit's run had not started when the fold displaced it. Measured
  September 3, 2026 over the last 28 `merge:` commits: **14 `success`, 14 `cancelled`**, the cancelled
  ones with zero jobs allocated. And it was never only folds displacing merges — `0ab47d2d`, `2c54de74`
  and `e0175372` went down in one chain, so on a busy day only the **last push of each ~15-minute
  window** ran. The tip was always gated; nothing between it and the previous tip was, which is why that
  day's two `failure` runs on `main` named no commit. The repair keys pushes on `github.sha` and leaves
  the PR half exactly as #932 measured it. **It costs runner minutes on purpose** — 27 runs where 13 ran
  — and whether the *fold* commit needs a full run of its own is deliberately left open
  ([#1300](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1300)).

  Since July 15, 2026, the repo ruleset
  **`main-ci-gate`** (renamed from `main-ci-poort` by Dave on July 26, 2026; found at GitHub →
  Settings → Rules) enforces that gate as a **required status check**: a PR to `main` only merges
  on a green `lint-en-tests` job. The bypass list is what keeps the direct fold/release commits on
  `main` possible, and it is not a convenience: a required status check **cannot** be satisfied by a
  direct push, because the check has to be green before the push is accepted and a push is what would
  trigger it. Until September 2, 2026 it held *Repository admin + the Write role, "Always allow"*. The
  Write entry was there because the work account `davekokbwj` **then** held write rights and not admin —
  that pairing is what identified the role at all (the August 14 reading further down this bullet) — and
  the caveat attached to it was that a Write bypass is safe only while there are no external
  collaborators.

  **BOTH HALVES OF THAT SENTENCE ARE NOW DATED, AND THE ROLE TABLE IS THE PART TO READ**
  ([#1284](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1284)). Measured
  September 3, 2026, after the move into the `DKJ-Solutions` org:

  ```
  $ gh api orgs/DKJ-Solutions/memberships/<user> --jq .role   -> DaveKJohn, davekokbwj, maikel-bwj: all admin
  $ gh api repos/DKJ-Solutions/claude-code-specialists/collaborators?affiliation=outside   -> empty
  $ gh api repos/DKJ-Solutions/claude-code-specialists/rulesets/19008062
      bypass_actors  [ {OrganizationAdmin, always}, {RepositoryRole 5, always} ]
  ```

  All three accounts are **org owners**, which is why each also reads `role_name: admin` on this repo, and
  the restored list carries **no Write role**. Two consequences, the first being the one a reader takes
  from the old sentence and gets wrong: **a direct push that succeeds from `davekokbwj` proves the admin
  bypass works and says nothing about the Write role.** That is precisely the mis-attribution the #1244
  thread had to retract, and this lens is the document that retraction cites as its pre-transfer baseline.
  The second: the external-collaborator caveat no longer guards what it was written to guard, because the
  bypass now rests on **org ownership** rather than a repo role — a wider grant, since an org owner
  bypasses on every repo in the org, and one that nothing on this repo's settings page shows.

  **Inferred, not measured: why the roles changed** — an elevation, or the transfer's own member mapping.
  `orgs/DKJ-Solutions/audit-log` needs `admin:org` and answers 404 from a session, so the cause is not
  readable here. The roles themselves are, and nothing above depends on the cause.

  **THAT LIST WAS EMPTY FOR ONE DAY, AND THE TRANSFER WAS WHY** (September 2–3, 2026,
  [#1244](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1244)). Moving the repo into
  the `DKJ-Solutions` org carried the ruleset across **intact** — active, `~DEFAULT_BRANCH`,
  `deletion` + `non_fast_forward` + `required_status_checks` on `lint-en-tests` — and dropped only its
  bypass list: `bypass_actors: null`, `current_user_can_bypass: never`, which meant nobody could push to
  `main` directly, `DaveKJohn` as repo admin included. All three direct-on-`main` exceptions were dead
  until Dave restored it on September 3 at Settings → Rules → `main-ci-gate` → Bypass list.

  **The paragraph is kept rather than deleted, because the failure is a property of the ruleset and not
  of that one move.** The bypass list is the only thing standing between a green `main-ci-gate` and three
  exceptions that cannot satisfy it, and nothing in GitHub's UI says so — a transfer, an org policy, or
  somebody tidying the list all produce the identical symptom. What identifies it is the push's own
  answer: `GH013 ... Required status check "lint-en-tests" is expected` when the list is empty,
  `Bypassed rule violations for refs/heads/main` when it is not. Read that line rather than the ruleset
  page; it is the one measurement that distinguishes the two states without admin rights.

  **It does not stop at the three exceptions — it blocks MERGES too, by a chain reaction**, and that is
  the part worth reading before anybody concludes the damage is bounded. A PR still merges; its fold
  cannot push; so the merged branch's development document **stays on `origin/main`**. The trunk then
  carries a live branch document that should have been deleted, and while the fold stays blocked they
  accumulate.

  **The second half of this chain reaction is fixed as of September 3, 2026, and the sentence that used
  to be here is dated rather than swept.** It read: *"That path is fixed by design — the design's safety
  argument being that the fold removes it at the merge — so ... every open branch has its own file at that
  same path, and every subsequent PR conflicts on it."* That was true, and it was the shared-path design's
  defect rather than this ruleset's: the conflict happened on **every** merge, blocked fold or not, and a
  conflicting PR gets no check suite at all, so it could never go green and never merge
  ([#1255](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1255)). The document is named
  per branch now, so two branches never write the same path and a leftover on the trunk collides with
  nobody. **What this ruleset still costs is the leftover itself** — an unfolded entry sitting on `main`
  with nothing saying so — which was the half #1244 owned and the per-branch rename did not repair.

  **That half is no longer silent as of September 3, 2026**
  ([#1270](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1270)). `check-unfolded-entry.ps1`
  reports a written per-branch document on the trunk whose declared branch is not the
  one under HEAD — the invariant being that the fold removes it at the merge, so on `main` there should be
  none. It runs from two places, because neither reaches the whole population on its own: a CI workflow
  (`.github/workflows/unfolded-entry.yml`, `push` to `main`, **not** in `main-ci-gate` — the same
  Dave's-call reasoning as `branch-entry.yml`, and a required check cannot gate a push anyway) catches it
  regardless of who merged or how, and a SessionStart hook (`unfolded-entry-sessioncheck.ps1`, workflow
  plugin) tells the next specialists session at start rather than leaving it to Chris's manual
  `verify-stand-against-repo` check. Neither calls `gh`: a written entry on the trunk is folded or it is a
  defect, whatever the branch's PR state, and the fold is local. The one false positive it can raise is the
  ship window — `ship-pr` pushes the merge commit and then, seconds later, the fold commit — which **this
  workflow's own** `cancel-in-progress: true` swallows and a session reads as a finding that resolves
  itself. Read *this* workflow's, not `ci.yml`'s: since
  [#1294](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1294) `ci.yml` keys every push to
  the trunk on its own commit, so it swallows nothing. The
  detector is `Get-UnfoldedTrunkEntry` in `entry-scaffold-lib.ps1`, one definition for both callers.

  **#1244 IS OPEN AGAIN, AND WHAT REOPENED IT IS THE MIS-READING DIRECTLY ABOVE** — so the cost is still
  being paid, and the response to it is the part to get right. It *was* closed on September 3, 2026 on the
  strength of a fold commit that pushed cleanly; that commit carried `davekokbwj` as author because that is
  the git identity on the machine it was made on, while the **pusher** was `DaveKJohn` (admin). A commit's
  author does not name its pusher and
  `gh api "repos/DKJ-Solutions/claude-code-specialists/activity?ref=refs/heads/main"` does — read that
  before concluding anything about which role got past the gate. The mechanism half therefore runs on as
  [#1278](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1278). Both leftovers #1244
  stranded (#1253 and #1261) *did* fold unchanged the moment the list came back, and that half is
  untouched by the reopening — it is the evidence for the rule: a blocked fold is **waited out, not
  committed locally**.

  **What settles #1278 is a reading no admin session can take** — `current_user_can_bypass` on the ruleset,
  from the account that will actually push. It reads `always` from this one because it is an org owner, and
  that says nothing about any other account. Measured September 3, 2026, all three accounts are now org
  owners and the list bypasses `OrganizationAdmin`, so on the face of it the gap #1278 reports is closed;
  **that is an inference from the role table, not the measurement**, and the account itself has to confirm
  it. Committing it makes a `main` commit that exists on one machine, and `main` is what every
  other machine syncs — measured September 3, 2026, where a held fold met the same fold landing from
  elsewhere and produced a duplicate entry and an unmerged `CHANGELOG.md` with no `MERGE_HEAD` to abort.
  The trunk leftover is visible and cheap; the duplicate commit is neither. Rendall's lens carries the
  fold-side statement of this. `check-unfolded-entry.ps1` above is what makes "visible" literal.

  **The hazard that made it urgent is worth keeping, because it is what a reader would otherwise
  rediscover.** Resolving that conflict in favour of the incoming branch **destroys an unfolded DEPLOY
  entry**, the only copy of that change's changelog text — and *keep mine* is exactly what a session hits
  this reaches for. Measured on PR #1249, where the trunk's conflicting file turned out to belong to
  PR #1250 and `deleted by us` meant *"our fold deleted a different document at the same path"*. It was
  untangled by keeping theirs, running #1250's pending fold, and letting both held folds ride out through
  the open PR. Per-branch names remove the situation rather than the hazard's teeth: there is no longer a
  resolution in which one branch's document can stand in for another's.

  **The generalisable half, beside the one below it: a setting that is present and active is not proof
  that the thing you depend on inside it survived.** [#1239](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1239)
  made *"does `main-ci-gate` still exist"* the post-transfer check, and it existed — enforcement, target,
  rules and required check all unchanged. What does not survive a transfer is the **sub-field**, and a
  ruleset reporting `active` reads as a clean bill of health while the one array the fold model runs on
  is gone. So check the field you actually rely on, not the object that contains it.

  **AND ON SEPTEMBER 3, 2026 A DIFFERENT SUB-FIELD OF THAT RULESET WAS MOVED AND MOVED BACK THE
  SAME DAY — `strict`, ON FOR ABOUT 45 MINUTES**
  ([#1325](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1325)). The stale-CI
  certificate gate in `ship-pr.ps1` step 3b
  ([PR #1316](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1316)) detects a real
  race it cannot win on this trunk — `lint-en-tests` runs ~13m47s–16m09s while `main` gains a merge
  every ~15–25 min, with ~44% of branches behind at the merge — so re-running CI to refresh the
  certificate is a chase the operator keeps losing. The first verdict (~14:45 UTC) rejected every
  script-side change and turned three knobs with `gh api`: ruleset `main-ci-gate` →
  `required_status_checks` rule `strict_required_status_checks_policy` `false` → `true`, and repo
  `DKJ-Solutions/claude-code-specialists` `allow_auto_merge` + `allow_update_branch` both `false` →
  `true` (~15:10). #1325 was closed as "option 1 applied". Research on the thread (~15:29) showed
  the option is measurably worse; #1325 was reopened on Dave's instruction (~15:34) and all three
  fields reverted to `false` (~15:55). Readback confirms all three `false`.

  **Why it does not converge — the load-bearing fact.** GitHub performs **no server-side base-sync
  of a PR branch** outside a merge queue. `allow_update_branch` ("Always suggest updating pull
  request branches") only shows a UI button to a human with write access — it acts on nothing.
  Auto-merge flips the merge switch only once *every* requirement, **including "up to date"**, is
  already satisfied; it never syncs the base itself. So `strict` converts the ~44% behind-at-merge
  rate into a hard, repeating, server-side block with **no automatic resolution and no valve** —
  `-SkipStaleCheck` lives in `ship-pr.ps1` and cannot touch a refusal that is now GitHub's.
  Confirmed live in the 45-minute window: PR #1316 itself had to be landed with
  `gh pr merge --admin` while `strict` was on. Sources are cited on #1325.

  **Strict-off with auto-merge on is not a fallback**, which is why `allow_auto_merge` was reverted
  too and not only `strict`: without the "up to date" requirement, auto-merge would merge on a
  stale-but-green certificate, unattended — reintroducing exactly
  [#1292](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1292)'s defect, which
  step 3b exists to catch. #1292 (the red-trunk mechanism issue) stays open and assigned in its own
  right; the keep-`strict`-or-adopt-a-merge-queue decision is where #1325 now sits.

  **The real fix is a GitHub merge queue**, which tests each PR against the projected merge
  (target-branch tip + the PRs already queued), so staleness is gone by construction. It **is**
  available to this repo (public + org-owned; the earlier "Enterprise only" reading was wrong).
  `ship-pr.ps1` step 3b is unchanged: its detection is correct and it stays the mechanism and the
  portable net for consumers, whom a repo-settings change never reaches, with `-SkipStaleCheck` the
  valve for a known-harmless window. **The generalisable half: a repo-settings "fix" for the
  staleness race that is not a merge queue does not converge** — `strict` + `allow_auto_merge` +
  `allow_update_branch` look like the unattended loop, but the base never moves under the PR on its
  own, so all they add is the block.

  **BOTH PREREQUISITES ARE NOW IN THE TREE, AND THE SWITCH IS STILL DAVE'S** (September 3, 2026,
  #1325). Enabling the queue is a repo-settings change; making the repo survive one is not, and the
  two things that had to be true first are both the same shape — **inert today, catastrophic on the
  day the queue is switched on, and silent in between**. Both are pinned by
  [`scripts/tests/merge-queue-prereq.tests.ps1`](../../../scripts/tests/merge-queue-prereq.tests.ps1),
  because nothing in this repo's behaviour today would notice either being removed:
  1. **`.github/workflows/ci.yml` now triggers on `merge_group`.** A required workflow without it
     never runs for a queue entry, so `lint-en-tests` never reports and GitHub's own warning is that
     the merge fails — a **total merge outage on `main`**, not a degradation. The suites run in full
     for a queue entry: the #1300 fold-commit shortcut is gated on the `push` event, so it does not
     reach one, and it must not — a queue entry *is* the projected merge being certified. The
     concurrency key needed no change: its `|| github.sha` arm already gives each entry its own group.
  2. **`ship-pr.ps1` reads the PR's state after `gh pr merge` instead of trusting the exit code.**
     `gh pr merge --help` states it outright — under a queue the PR is *"added to the merge queue"*,
     and gh exits **0** having enqueued. Step 5 folds onto the trunk on the strength of that exit
     code, so an ordinary ship would have written a fold commit for a PR that had not landed: the
     changelog entry on `main` ahead of its own merge, with nothing in the run saying so. **This one
     is also right with no queue anywhere** — "merged" had been an inference from an exit code, on
     the one script that writes to the trunk. A state that cannot be *read* is deliberately **not** a
     refusal (same shape as the DEPLOY lock): only a state positively read as non-`MERGED` refuses,
     because turning a network blip into a refusal between the merge and the fold would manufacture
     the trapped-entry state (#1270) the fold exists to prevent. The refusal hands the wait back
     rather than guessing a timeout — waiting a queue out is a separate decision, not taken here.

  **The generalisable half of the prerequisites, beside the one above: a settings switch that is
  somebody else's to flip does not make the code it will break somebody else's problem.** The queue
  decision sat on #1325 for a day as "Dave's", and both defects that would have fired on the first
  merge after it were in the tree the whole time, reachable and fixable without touching a setting.

  **AND THE ANSWER IS NO — THE QUEUE'S CASE WAS DISCHARGED, NOT REJECTED** (Dave, September 3, 2026,
  [#1355](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1355), the decision split out
  of #1325 so it would not be buried in a closed thread). No merge queue is switched on for `main`, and
  the three settings above stay `false`. **What settled it was the same day's CI sharding**
  ([#1351](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1351)): the stale-certificate
  event went from **31.9% at ~13 min** to **12.3% at ~5 min**, which is an expected **~37 seconds per
  merge**. The queue's throughput objection had *also* been discharged by the same change — ~4 merges/hour
  serial at 15-minute CI, against an observed trunk cadence of 2.4–4/hour, became ~12/hour — so this is a
  no on price rather than on feasibility. Against ~37 seconds a yes buys a repo-settings change, a step-3b
  rebuild that is dead code until the day of the flip, and a GitHub-side mechanism in the middle of a chain
  `ship-pr.ps1` currently owns end to end.

  **The generalisable half: an option whose case rests on a measured cost has to be re-argued the day that
  cost is measured away, and the argument does not survive on its own momentum.** The queue was the
  standing answer for a week because the number behind it was 31.9% at ~13 min. Nothing about the queue
  changed on September 3; the problem it was sized against shrank by a factor of nearly seven in expected
  cost — 31.9% × ~13 min is ~4.1 minutes per merge, against 12.3% × ~5 min for ~0.6 — and an option
  carried forward without re-reading its own premise would have been built anyway.

  **The third prerequisite is therefore recorded and deliberately NOT built** — the one #1355 exists to
  keep out of a closed thread. `ship-pr.ps1` step 3b (`:885`) refuses before `gh pr merge` (`:1268`) is
  ever reached, and nothing in `scripts/**` detects a queue: under one the staleness predicate still fires
  at its normal rate, and the refusal is then **wrong**, because enqueueing *is* the converging remedy. The
  queue subsumes the predicate while the predicate blocks the path to the queue, and the operator's only
  way through would be `-SkipStaleCheck` on every ship. It stays unbuilt on this repo's
  no-pre-emptive-fixes rule, and it is written here so a future yes inherits it rather than rediscovering
  it at the first refusal. Its shape is still open: skip 3b when a queue is detected on the base branch,
  drop the predicate here entirely (the queue is strictly stronger), or gate it on the flipped setting.

  **And two things a future flip should not learn the hard way**, both read from `gh pr merge --help` on
  the day of the decision. *"When targeting a branch that requires a merge queue, no merge strategy is
  required"* — **not required is not rejected**, so whether `$mergeMethod`'s `--merge` (`ship-pr.ps1:304`)
  is accepted against a queue-backed branch is still unestablished, and is the first thing to check on the
  first ship after a flip. And the sentence beside it — *"If required checks have not yet passed,
  auto-merge will be enabled"* — means a yes is plausibly **two** settings, because `allow_auto_merge` is
  `false` here. `ship-pr` waits for green and should land on the straight-enqueue branch instead, so this
  is the path the happy case never exercises, which is exactly why it is written down.

  **What would reopen it:** the fire rate climbing back above ~25%, or CI cost past ~10 minutes. Until
  then the queue is a priced-and-declined option, not an open question.

- **`.github/workflows/claude.yml` + `.github/workflows/claude-code-review.yml`** — the two Claude Code
  workflows, added August 14, 2026 via
  [PR #658](https://github.com/DaveKJohn/claude-code-specialists/pull/658). The first answers an
  `@claude` mention in a comment; the second reviews every PR under the job id `claude-review`, which is
  **advisory** — the ruleset names `lint-en-tests` and nothing else. Four hardening decisions sit in
  those files and each one reads as arbitrary without its reason, so they are recorded here:
  - **Both `uses:` are pinned by commit SHA**, not by the moving `v4`/`v1` tags. This repo is a public
    plugin source: whoever can move a tag reaches every consumer through its CI.
  - **`claude.yml` runs on a read-only tool allowlist**, because upstream's configuration doc states the
    default set covers *"reading, committing, editing files"*. Without it, an `@claude` mention could
    produce a branch and a commit that passed no gate here. The three `mcp__github_ci__*` tools are named
    explicitly: the `actions: read` permission exists to enable exactly them, and an allowlist omitting
    them would switch that capability off in silence. **Do not "restore" Edit/Write/Bash to make
    `@claude fix this` work** — that it only answers is the decision, not a defect.
  - **The `issues: [opened, assigned]` trigger is deliberately absent** from the upstream template's set.
    The action's write-access gate governs who *triggers*, never who *wrote* the text a run then reads,
    and this repo publishes an `inbound` issue template — external prose is a designed-for input here.
  - **The `permissions:` block is NOT the boundary, and both files say so.** `id-token: write` lets the
    action mint a GitHub App token documented as Contents/Pull Requests/Issues at read **and** write; the
    read-only scopes bound `GITHUB_TOKEN` alone. Audit either file by its scopes and you conclude the
    opposite of what is true.

  **The plugin marketplace is unpinned, and that was checked rather than skipped.** `plugin_marketplaces`
  takes *"Git URLs to install from"* and neither the action's own `action.yml` nor `docs/usage.md`
  documents a ref, tag or commit syntax — so no syntax was invented, per the
  [#566](https://github.com/DaveKJohn/claude-code-specialists/issues/566) rule about a proposal naming a
  mechanism that does not exist. The remedy if it ever matters is to drop the plugin and write the review
  prompt inline, not to guess at a `#<sha>`.

  **The App is NOT in `main-ci-gate`'s bypass list, and the method is the part worth keeping** (August
  14, 2026). The question decides whether that App token can reach the trunk past the required check, and
  the REST endpoints all refuse: `bypass_actors` is returned to admins only, and the work account
  `davekokbwj` **then held** `admin: false, maintain: false, push: true` (it holds admin today — the role
  table on the `ci.yml` bullet above). It was answered anyway, from three measurements that survive a
  redacted field.

  **All three readings below are from before the transfer and none of them reproduces today** — the list
  was emptied by the transfer and refilled on September 3 with a *different* pair, so `bypass_actors` no
  longer resolves to Repository admin + Write, `current_user_can_bypass` no longer discriminates from this
  account (it is an org owner now, so it reads `always` whatever the roles say), and `updated_at` is the
  restore's stamp rather than July 26's. The conclusion still holds — the current pair is
  `OrganizationAdmin` + a repository role, and neither is an App — and **the method is what this entry is
  for**: it is how a question about a field you cannot read gets answered instead of guessed at.
  - **GraphQL redacts the entries but not the array.** `repository.rulesets.bypassActors` came back as
    `nodes: [null, null]` — the contents are hidden from a non-admin, the **count** is not. Exactly two
    actors.
  - **`current_user_can_bypass: "always"`** on the REST ruleset, for an account that at the time held
    nothing but `push`, means the **Write role** is one of the two — it was the only thing that account
    had which could grant bypass. **The inference is only as good as the role it rests on**, which is why
    the same reading proves nothing once that account holds admin.
  - **`updated_at` dates the list.** The ruleset was last modified `2026-07-26T20:58`, and the Claude App
    arrived `2026-08-14T08:46`. A list untouched for nineteen days cannot name an actor that did not
    exist when it was written. The July 26 field-by-field re-check recorded in
    [`language-layers.md`](../../rules/language-layers.md) names both actors as *Repository admin + the
    Write role*, which matches the count of two and leaves no room for a third.

  GitHub's own documentation closes the implicit route: roles and GitHub Apps are **separate** bypass
  categories, so an App gets nothing from the Write role being listed. **The generalisable half: when an
  API hides a field, check whether a sibling representation leaks its shape (a count, a length, a
  timestamp) — three partial reads answered a question no single endpoint would.**

  **What this bounds.** The App cannot push to `main`, delete it, or force-push. It *can* create a branch
  and open a PR — which then merges only on a green `lint-en-tests`, like everyone else's. So the residual
  is the ordinary route, and the read-only allowlist above closes the other end. The knob this turned on
  was the **Write-role bypass** and its external-collaborator condition; since September 3, 2026 there is
  no Write role in the list and the bypass rests on org ownership instead, so the knob to watch is **who
  is an owner of `DKJ-Solutions`** — see the role table on the `ci.yml` bullet above.

  **A RED `claude-review` HAS ALWAYS NAMED ITS OWN REASON, AND NOBODY WAS READING IT** — issue
  [#1103](https://github.com/DaveKJohn/claude-code-specialists/issues/1103), August 29, 2026. The
  **Why the review failed** step in that workflow prints `api_error_status`, writes it as a titled
  annotation and repeats it in the job summary, and has done so since
  [#966](https://github.com/DaveKJohn/claude-code-specialists/issues/966). The same class of report kept
  arriving anyway — eight threads about this check red on every PR, every one of them since #966 the same
  quota state, and #966 itself filed against a log already reading `429` and concluding that a secret
  needed rotating. #1103 was filed with *"the actual cause: not measured"*, pointing at the marketplace
  step, which is where the run happened to be when the error surfaced and not where it came from.

  **The diagnosis was reachable and the reader was not, so the repair moved the sentence rather than
  writing another one.** `ship-pr.ps1` now reads the failing check's annotations on the path where the
  merge PROCEEDS and prints what that workflow said about itself, beside the warning naming the check
  (`Get-FailedCheckRunRefs` + `Get-AuthoredFailureNote`, `scripts/lib/pr-issues-lib.ps1`). The selection
  rule is **a failure annotation carrying a title**: the Actions runner writes its own with an empty one
  (*"Process completed with exit code 1"*), while `::error title=X::Y` is a sentence an author left for
  exactly this reader — so it needs no maintenance and works in a consumer repo whose workflows this repo
  has never seen, where a rule keyed on the name `claude-review` would report nothing at all. Only the
  **not-required** failures are asked about: a required one is a refusal, and its gate runs locally where
  the reader meets the reason first-hand.

  **And the check STAYS RED on a 429** — that decision is unchanged and recorded in the workflow itself. A
  green tick would hide that this PR got no review, which is exactly what #966 asked not to be silent.
  What was wrong was the legibility, not the colour.

  **AND THE RELAYED SENTENCE IS ONLY AS GOOD AS ITS AUTHOR** — issue
  [#1112](https://github.com/DaveKJohn/claude-code-specialists/issues/1112), the day after. The relay works
  and is the right shape; what was wrong was the sentence going through it. That headline told the reader the
  reason line names *"when it comes back"*, and on August 29, 2026 run `33267175141` failed at 18:02 UTC
  reading *"resets Aug 31, 7am (UTC)"* while runs `33268549172` and `33269512129` reviewed successfully at
  18:43 and 18:55 the same evening — roughly **2.5 days early**, both of them real 1–3 minute reviews rather
  than the nine-second workflow-validation skip.

  **The repair went into the workflow, not into `Get-AuthoredFailureNote`, and that is the reusable part.**
  The relay is generic on purpose: it repeats what an author wrote and cannot know which authors are reliable,
  so a caveat added there would caveat every workflow in every consuming repo — including the ones whose
  timings are exact. An over-claiming sentence is repaired where it is written. The lib now says so in the
  comment beside its 500-character bound, which had itself asserted the reset time was *"the only actionable
  word in the whole note"*.

  **The standing rule that comment block now carries**, after three corrections from measurement —
  [#974](https://github.com/DaveKJohn/claude-code-specialists/issues/974) (a tally of red runs, wrong by ~3x
  when typed), [#1055](https://github.com/DaveKJohn/claude-code-specialists/issues/1055) (session versus
  weekly window) and #1112 (the reset time): **the headline states only what the STATUS proves, and everything
  the `result` STRING says is attributed to upstream rather than asserted.** The status proves the account is
  out of quota and that a re-run adds none; it proves nothing about when the quota returns. *Why* it returned
  early was deliberately not investigated — a rolling window, a session window clearing, an account change are
  all plausible and none was measured — and the headline reports the discrepancy rather than a mechanism.

  **AND THE SENTENCE HAS TO FIT THE PIPE THAT CARRIES IT** —
  [#1116](https://github.com/DaveKJohn/claude-code-specialists/issues/1116), and it sits beside the three
  above rather than among them: they corrected what the headline CLAIMS, this one asked how much of it
  SURVIVES. Two caps bound the same string and neither owner can see the other: this workflow caps the
  reason it appends at 300, `Get-AuthoredFailureNote` caps the whole message it relays at 500, and the
  296-character headline puts the sum at 597. Because the relay cannot see where the headline stops, the
  half it drops is the **tail of the reason** — where *"resets Aug 31, 7am (UTC)"* lives.

  **Both numbers were left exactly where they were, and that is the finding.** The obvious repair —
  lower the workflow's 300 so the sum fits — was built and then withdrawn on its own arithmetic:
  `500 - 296 - 1 = 203` is what the operator's console shows **whichever end owns the cut**, so capping
  here hands that reader the same 203 characters, drops the `...` that marks the loss, and costs the
  GitHub annotation — read in the checks UI, where no 500-character bound applies — up to 97 characters
  it currently keeps. Cutting from the *front* in the relay is the only change that would give the
  console more, and it is not free either: the relay carries workflows it has never seen, and for one
  whose message is all content and no preamble the front is the part worth keeping.

  **What the coupling lacked was an owner, not a tighter number**, so `scripts/tests/pr-issues.tests.ps1`
  now pins all three figures the arithmetic rests on — the relay's 500, the workflow's 300, and every
  literal headline's length — and mutation-testing confirms each movement goes red naming the right one.
  The headline is the one most likely to move: it is prose, and #974, #1055 and #1112 each rewrote it.

  **The sampling that decided it, since #1116 explicitly asked for one before a repair.** All 54 red runs
  available on August 29, 2026, carrying 45 titled failure annotations: every one a 429, upstream's
  `result` first line **51 to 55** characters against 203 of room, longest message actually emitted
  **341**. A reason must reach 204 characters — nearly four times the longest ever seen — before a reader
  loses a word. **The same pass caught the comment defending the 500 citing run `33267175141` as a 460-character
  note when it is 400** (title 55 + separator 4 + message 341). A comment that names a run id is inviting
  that check, which is the argument for naming one.

  **The transferable half: an overlap between two bounds is not automatically a defect, and the change
  that removes the overlap is not automatically the fix.** Here it would have moved the loss from a marked
  truncation in one reader's view to an unmarked one in another's, and delivered the same text to the
  reader it was meant to help.
  **AND THE RELAY IS ONLY AS GOOD AS THE WORKFLOW HAVING SPOKEN AT ALL** — issue
  [#1245](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1245), September 2, 2026, and it is
  the first entry in this narrative about a failure the diagnostic step never *saw*. Every measurement
  above describes a run the SDK lived long enough to report on. The **Why the review failed** step is
  gated on `execution_file != ''`, so when the action dies before the SDK is reached that step is
  **skipped**, the workflow writes no titled annotation, and `Get-AuthoredFailureNote` — correctly —
  selects nothing. The operator meets a red tick with a blank reason line: the #966 silence again, in the
  one class all of the 429 work could not reach.

  **Measured rather than reasoned about.** Run `33663986438` (PR #1249): step *Run Claude Code Review*
  `failure` after 16s, step *Why the review failed* `skipped`, and the job's annotations were a Node-20
  warning plus two **untitled** failures — *"Process completed with exit code 1"* and *"Action failed with
  error: Claude Code is not installed on this repository"*. The reason was in the API the whole time, in
  the one field the relay does not read. The cause was #1245's own subject: the Claude Code GitHub App did
  not follow the transfer into `DKJ-Solutions`, so the app-token exchange returned 401.

  **The repair is the second diagnostic step, and its placement is the #1112 rule applied again.** The
  tempting change is to let the relay fall back to an untitled annotation — and it is the wrong one, for
  the reason its own asserts already state: it would relay *"Process completed with exit code 1"* in every
  consuming repo, which is the reassuring-looking note that says nothing. A workflow that wants to be heard
  writes a title. So the workflow now has the **complementary** gate, `execution_file == ''`, and
  `pr-issues.tests.ps1` pins that both halves of `failure()` exist — a class cannot fall between them
  again.

  **What that second sentence may CLAIM is the interesting constraint**, and it is the standing rule of
  that file rather than a new one. It states only what an **empty output** proves: the SDK produced no
  result, so the failure is in the setup around it and not in the diff, and no `api_error_status` exists —
  a 429 or 529 arrives *with* a result message and is therefore the other step's business. It does **not**
  name the cause, because it cannot: the cause is in the runner's untitled annotation and in the step log,
  and the step can read neither. Naming today's cause in the sentence would be #966's mistake with the sign
  flipped — an assertion the run never proved — so the app installation is cited in the job summary as *the
  measured instance*, not as the diagnosis. The asserts pin that too: the headline may not mention 429,
  529, quota or a reset.

  **And the escape went in even though every character of that headline is a literal**, which is the
  #1118 lesson taken at face value rather than re-learned. On literals `${headline//%/%25}` is a no-op —
  but #1118 was precisely the branch nobody escaped because nobody had interpolated into it *yet*, and it
  was then the only branch without the guard. So the test pins the emission-site **count** rather than a
  `-ge`: a new site raises the number deliberately, and cannot slip in unescaped.

  **The transferable half, and it is #1245's own sentence: after a transfer, verify the CAPABILITY, not
  the artefact that represents it.** The post-transfer checklist checked that the Actions secret survived,
  and it had — so the check came back clean while both workflows depending on it were dead anyway, because
  the dependency that broke was one layer further out than the check reached. Its sibling
  [#1244](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1244) is the same shape on the same
  day: `main-ci-gate` present and active while the bypass list it depended on was gone. **Both failure
  modes are silent by design** — one check is advisory, the other's absence only shows when somebody tries
  to use it — which is why *"the artefact is still there"* is the one form of verification a transfer
  defeats.

  **What is NOT in this repo's gift**, stated because the temptation is to close the loop: the app install
  is an **account-level** action on the `DKJ-Solutions` organisation, like the spend limit #1164 turned out
  to need. A session can make the failure legible and cannot make it stop. The consumer-facing half — that
  no shipped *page* states the titled-annotation contract, only the code enforcing it — is
  [#1251](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1251), deliberately not folded in
  here.

- **`.github/workflows/unfolded-entry.yml` + `scripts/lint/check-unfolded-entry.ps1`** — the
  skipped-fold gate (issue #1270). The workflow runs the check on every `push` to `main`; the check is
  mirrored into the workflow plugin and also driven by `unfolded-entry-sessioncheck.ps1`. Advisory, not
  in `main-ci-gate`. The full reasoning is in the `#1244` chain-reaction passage on the `ci.yml` bullet
  above; the detector is `Get-UnfoldedTrunkEntry` in `entry-scaffold-lib.ps1`.
- **`scripts/lint/check-git-identity.ps1`** — the split-identity check (issue
  [#1315](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1315), September 3, 2026): does
  this checkout commit as the same account it acts as on the tracker? The claim rule's `@me` resolves
  through the GitHub API, so it writes whichever account `gh` holds, and nothing compared that against
  `git config user.name`. Measured on DAVE-KOK-BWJ, where `gh` is `DaveKJohn` and `git` is `davekokbwj`:
  the documented idiom put the wrong account on #1314, and the cross-device tell in
  [Derek's lens](05-05-extension.md#branch--repo-hygiene) — a branch whose commits name a different
  account than the checkout — fires there **by construction**, so it reads "built elsewhere" off a branch
  that never moved.

  **It has ONE caller and deliberately no CI half**, which is where it differs from every other check on
  this page: the finding is a fact about the *machine*, not about the tree, and a runner authenticates as
  a bot and commits as one — a mismatch by design that would fire on every push. The moment that matters
  is a session's start, just before it claims an issue and begins committing, so
  `git-identity-sessioncheck.ps1` (workflow plugin) is the whole delivery. It is in no gate and never
  will be.

  **Two design points that look arbitrary and are not.** It compares *names*, not emails, although GitHub
  attributes a commit by email — because `gh api user` returns a null email for an account with no public
  one and `gh api user/emails` needs the `user` scope, which this family's tokens do not carry; widening a
  token scope to print an advisory line is the wrong trade, and `gh auth status` reads the active account
  from the keyring with no network at all. And it fires **only when `user.name` is a valid GitHub username
  by GitHub's own rule** — 39 characters, single hyphens, none at either end. That guard is the whole
  reason the check is shippable: `user.name` is free text and usually holds a person's name, so an
  unconditional comparison would fire forever in every consumer that spells its name normally, which is
  precisely the shape of the stale-path check
  [declined further down this page](#how-the-gate-checks-got-their-shape-and-the-measurements-behind-them-august-15-2026)
  at 124 findings all false. The three accounts in this family are all login-shaped, so the measured case
  is still caught. `git-identity-gate.tests.ps1` walks both edges of that rule, and passes both identities
  in explicitly — a suite that read the machine's own would assert something different on every checkout.
- **`scripts/lint/check-consumer-prose.ps1`** — the consumer-prose check: **two detectors over one
  corpus, read once**, merged from two scripts and two hooks by issue
  [#1421](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1421) (September 5, 2026). Both
  halves are the narrow literal greps the declined prose-contract framework recorded as the proportionate
  alternative; each keeps its own detector function, its own measurement and its own report block, and
  what merged is the plumbing around them — the process, the root resolution, the skip, the lib loads and
  the always-on walk.

  **What the merge cost a consumer: nothing, and that is why it happened now rather than later.** #1421
  deferred it on the ground that it renames a consumer-facing hook one release after introducing it.
  Checked before building, and the reason had expired: **neither hook had ever been released** — both
  landed after the `v4.29.0` tag and both sat in `CHANGELOG.md`'s `[Unreleased]` section, so
  `consumer-prose-sessioncheck` is the first name any consumer ever sees. **That check is the general
  lesson here**: a deferral's reasoning is a fact about a moment, and the moment it names is the one thing
  a standing issue cannot re-measure for itself.

  **Measured, on a consumer fixture carrying both defects, three passes each** (this machine,
  September 5, 2026): `retired-doc-name-sessioncheck` 492 / 492 / 493 ms plus
  `supremacy-declaration-sessioncheck` 498 / 494 / 503 ms = **990 ms for the pair**, against
  **541 / 527 / 530 ms** for the merged hook reporting the same two blocks — **~457 ms saved per session
  start**, in every consumer, indefinitely. That is slightly *above* the ~350-450 ms #1421 inferred from
  the component costs, which is worth recording because that issue was honest that no merged version had
  been built to measure. A bare `powershell -NoProfile` hook launch that finds no check script is
  **~155 ms** here, which fixes the shape of it: one of the two outer launches goes, one of the two nested
  spawns goes, one of the two dot-source-plus-walk passes goes. **It is not the largest item on that
  bill** — measured in the same batch as #1421, all 7 SessionStart hooks came to ~6.8 s here, of which
  `connector-sessioncheck` alone was ~4.9 s (~72%).

  **The first half — the retired-name detector** (issue
  [#1389](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1389), September 4, 2026):
  does a consumer's own always-on prose still name a *retired* name of the branch's development
  document? The first of the two narrow literal greps the declined prose-contract framework recorded
  ([below on this page](#how-the-gate-checks-got-their-shape-and-the-measurements-behind-them-august-15-2026)),
  and its whole licence is that sentence — the detector is `Get-RetiredDocNameMention` in
  `entry-scaffold-lib.ps1`, the names come from `Get-BranchFileLegacyNames`, and nothing here reads what
  a sentence *means*.

  **Three things separate it from the framework that was declined**, and all three are asserted rather
  than described. The names are **derived**, so the next rename adds this token by the same row it always
  adds and there is no second list to leave at seven names. The corpus is stated as an **inclusion**
  list — the always-on closure plus the workflow folder's own permanent pages, minus its changelog,
  because a folded entry correctly names the file of its day and a check that read it would be born red
  on its own past. And it **skips the publishing repo**, on the source-repo guard's own condition 2, for
  the reason #1380's first pass measured the hard way: this repo's pages narrate the rename history on
  purpose, so without the skip the source reads as consumer drift.

  **Its stated gap, so nobody rediscovers it as a bug.** `development-<slug>.md` (pre-#1335) is *not* a
  token: a prose page names the shape, and matching a shape needs a wildcard, which is the step toward
  fuzzy the decline rules out. `development-cycle.md` is a real literal and is covered, so the
  `development-` era is not wholly absent — but a consumer restating only the shape is missed, and that
  is what the precision costs.

  **The second half — the supremacy-declaration detector** (issue
  [#1415](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1415), September 4, 2026):
  does a consumer's own always-on prose declare *its* `CLAUDE.md` the winner over
  `dkj-policy/CONTRIBUTING.md`, inverting `LAW-THIRD-RANK-ORDER`? The **second** of the two
  narrow literal greps the declined framework recorded, and the one that entry measures every candidate
  as **structurally blind** to: a pointer test flags only sections that cite nothing, so
  cites-then-contradicts can live nowhere but among the findings it suppresses.

  **The two share their corpus, and that was true before the merge** — it is the point of
  `Get-ConsumerProseDocuments` in `entry-scaffold-lib.ps1`: which documents a consumer-prose check may
  read is one question with one answer, and each of its exclusions (the changelog, `releases/`,
  plugin-shipped payload, a per-branch document) is load-bearing for a measured reason. Two copies would
  drift on the day a third exclusion is found, and the copy that missed it would report what the other
  correctly ignores. **Sharing the corpus is what left the runtime duplication visible**: the pair had one
  definition of *which* documents and two of everything else, which is exactly the residue #1421 removed.

  **The detector is ADJACENCY, not co-occurrence, and that departs from the sentence this page
  recorded** — measured, with the numbers, [further down](#how-the-gate-checks-got-their-shape-and-the-measurements-behind-them-august-15-2026).
  Short version: the recorded three-term test scores 0 findings and 0 recall on its own target, because
  the real sentence names the contributing page by a Dutch prose noun rather than by its filename;
  requiring `CLAUDE.md` and `wins`/`wint` to sit *beside* each other scores 3 raw / 2 reported / 2 true /
  100%, and reads **direction**, which is the whole defect — *"this page wins"* is the rank order stated
  correctly and a term list cannot tell the two apart.

  **Its one suppression rests on one instance, and is written down as such** rather than presented as a
  principle: a hit wholly inside a `"…"` span is skipped, the instance being a consumer quoting the
  closing line of a page it retired. Kept because precision is 67% without it and 100% with it; the
  suite pins it from both sides, including that an unrelated quotation elsewhere on the line does *not*
  suppress a real finding.

  **ONE CALLER, no CI half, and the publishing-repo skip** — three answers that now hold for the merged
  script as a whole. Where `check-git-identity` has no CI half because a runner is a bot by design, this
  one has none because there is nothing for a CI leg to check: in the only repo whose CI this repo
  controls, the check skips. So `consumer-prose-sessioncheck.ps1` (workflow plugin) is not a convenience
  on top of another route — it *is* the route, which is the whole point of #1389 and #1415 alike.

  **The skip means something different per detector, and one script must say so rather than inherit it.**
  For the retired-name half it is a **repair** — this repo narrates the rename history on purpose and
  would read as consumer drift without it. For the supremacy half it is only a **guard**: measured at zero
  hits here on the day it was written, because every supremacy sentence this repo carries names the
  plugin's page as the winner and adjacency reads that correctly. It is kept for sibling consistency and
  because this is the repo where such sentences get written about consumers.

  **BOTH DETECTORS ALWAYS RUN — the first finding does not short-circuit the second.** A check that
  stopped at the first block would hand a session start the worse half of the two-hook arrangement (one
  defect reported, the other hidden) without the saving that motivated merging them, so
  `consumer-prose-gate.tests.ps1` pins it from three sides: a tree with only the rename produces one
  block, a tree with only the inversion produces the other, and a tree with both produces exactly two
  `[ERROR]` markers from one invocation.

  **The pre-merge per-hook figures, kept because they are what the saving is measured against** (5 runs
  each, median, this machine, September 4, 2026): `retired-doc-name-sessioncheck` **365 ms** through the
  hook in this repo where it skips, against **544 ms** for `unfolded-entry-sessioncheck` beside it;
  `supremacy-declaration-sessioncheck` **728 ms** through the hook here, its check alone **387 ms** where
  it skips and **1,484 ms** against a consumer with findings — against **1,312 ms** for the sibling on
  that same consumer in that same run, so the paragraph joining cost roughly **13%** over a detector that
  still read physical lines. That was the price of the wrapping false negative being closed, and it was
  worth it.

  **The re-measurement is itself the lesson.** The supremacy figures were first taken before review found
  the wrapping defect, and the repair makes the check do strictly more work per document — so the
  paragraph would have shipped as a current, dated fact about code that no longer existed. Caught by the
  copy edit, not by any gate: **a measurement taken before the last repair is stale, and nothing goes red
  when it is.**

  **Compare the pair, never the figure.** Every absolute on this page runs roughly double or half its
  neighbour depending on nothing but how busy the box was — which is why the #1421 before/after above was
  taken as six runs in one sitting on one fixture rather than by subtracting two dated numbers. Same load
  sensitivity [#1401](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1401)
  closed by making a duration assert compare against its queue instead of a fixed ceiling.
- **`scripts/lint/check-consumer-drift.ps1`** — the read-only drift check against a consuming repo
  (`MISSING`/`IDENTICAL`/`DRIFTED`).
- **`scripts/lib/plugin-tree-lib.ps1`** — the one answer to *which plugins does this repo publish, and
  where does each one's folder sit*, read from `.claude-plugin/marketplace.json`. Five scripts used to
  answer that themselves, each by encoding the layout: a hand-written list of four directories in the
  drift check, a `^plugins/<name>/` regex with an exception for the one sibling that is not a plugin, a
  path-segment index in the shared-scripts registry, three `Split-Path`s upward from a `plugin.json`,
  and a `Join-Path <plugins root> <name>`. None of those is a fact about plugins; they are facts about
  one layout, and this tree has moved twice. Dependency-free on purpose: one caller runs at
  SessionStart (`check-connectors.ps1`, via `connector-sessioncheck`) and another is the fold, which
  runs straight after a merge on the trunk. Mirrored, because `release-lib.ps1` dot-sources it.
- **`scripts/lib/branch-info.ps1`** — the prefix→label→changelog-type table (shared with the
  release scripts). Deliberately no `release` prefix: a release does not go via a branch/PR but
  directly on `main`.
- **`scripts/lib/pr-issues-lib.ps1`** — the pure decision table of the **resolves gate**: which issues
  a text mentions, which a body actually *closes*, and whether a PR may open without declaring either.
  Deliberately pure (no `git`, no `gh`, no filesystem) so [Tycho #18](04-18-extension.md) can assert
  every branch of it offline; the one impure part — asking GitHub which issues are open — stays in
  `open-pr.ps1`. Shared/mirrored, since `open-pr.ps1` dot-sources it. The rule it enforces and the
  incident behind it are [Derek #05](05-05-extension.md#opening-a-pull-request)'s.
  **Two traps that cost real debugging while building this lib**, both measured and both now pinned by
  asserts:
  - **`powershell -File` cannot bind an `[int[]]`.** `-Resolves 332,340` arrives as the string
    `'332,340'` and is cast to the single number **332340** — the comma read as a *thousands
    separator*. No error, just a wrong issue. Hence a `[string]` parameter parsed by
    `ConvertTo-IssueNumberList`, and hence the fixture passes it over that same `-File` hop.
  - **`@(… | ConvertFrom-Json)` does not flatten a JSON array in PowerShell 5.1.** 5.1 emits the
    parsed array as *one* pipeline object, so `@()` collects a single element that IS the array, and
    `$_.number` then does member enumeration and hands `[int]` an `Object[]` that throws. Assign
    first, then wrap: `$parsed = … | ConvertFrom-Json; @(@($parsed) | …)`. That throw was swallowed by
    a `catch` that degrades the gate to "cannot check" — so the gate silently never blocked **while
    every pure unit test stayed green**. Only the wiring fixture caught it, which is the general
    lesson: a pure decision table proves the decision, never that it is reached.

    **IT HAS NOW FIRED TWICE, IN TWO UNRELATED SCRIPTS, SO TREAT IT AS A CLASS RATHER THAN AS THIS LIB'S
    INCIDENT** (August 14, 2026). The open-issues block of `session-status.ps1` — the reporter behind
    `/lock` and `/handover`, removed with them by #957 — carried the same one-liner and
    printed `#System.Object[]  System.Object[]` for three open issues — in this repo *and* in every
    consumer's mirror, since both those skills told a consumer to run it. Grep for
    `@(` immediately followed by a command piping into `ConvertFrom-Json` before adding another.
    **Two things that measurement added, neither of which the original write-up had:**
    - **At exactly ONE record the broken form is correct**, because member enumeration over a
      one-element array yields that element's own value. So the defect is invisible at 0 or 1 and only
      shows at 2+ — which is how it survived in a repo that usually had one open issue or none. A test
      that covers the populated case with a single record proves nothing; use three.
    - **`.Count` is `1` whether the array holds zero items or thirty**, so an `if ($x.Count -eq 0)`
      guard behind this pattern is **unreachable**, and the empty case falls into the populated branch.
      Here that printed a bare `#` with two empty fields. Fix and test *both* branches: the visible
      symptom is the populated case, the silent one is the empty case.
- **Two lessons that outlived the file they were measured in.** `scripts/task/session-status.ps1` — the
  reporter behind `/lock` and `/handover` — was removed with both skills on August 27, 2026
  ([#957](https://github.com/DaveKJohn/claude-code-specialists/issues/957), Dave). Its open-issues block
  had been repaired on **August 14, 2026**, and that repair cost two lessons beyond the
  `ConvertFrom-Json` trap above. Neither is about the deleted script, so both are kept:
  - **A `2>$null` on a native command makes its `catch` unreachable, so check `$LASTEXITCODE` instead.**
    The older of the two defects: an unauthenticated or offline `gh` throws nothing and prints nothing,
    so `ConvertFrom-Json` never ran, the pipeline yielded nothing, and the block reported **`none`** —
    *"we could not ask"* printed as *"there are none"*. The wrong answer that looks like a right one, and
    it had quietly disabled the degrade line that script's own docstring promised for **every** optional
    source. The redirect is still correct (a stderr dump is not a status report); what it costs is the
    throw, so the exit code is read explicitly and the `catch` kept only for a payload that arrives and
    does not parse.
  - **No `return` inside a reporter's section blocks.** They sit at **script scope**, where `return` exits
    the whole script — so an early return in the middle of one silently drops every block below
    it while still exiting `0`. Caught during the fix above, before it shipped: the degrade path is an
    `else`, and an assert pinned that a block *after* the failing one still printed.
- **`scripts/lib/release-lib.ps1`** — the pure release helpers (version bump, emptying `CHANGELOG.md` down
  to its intro, and the assembly of the changelog notes under `dkj-policy/releases/changelog/`)
  that [`cut-release.ps1`](../../../scripts/release/cut-release.ps1) dot-sources; deliberately
  pure so [Tycho #18](04-18-extension.md) can test them in isolation. The release *process* is
  [Rendall #06](05-06-extension.md)'s domain; Sylvester guards the script mechanics underneath.
- **`scripts/agents/build-agent-defs.ps1` + `scripts/lib/agent-shared-lib.ps1`** — the generator
  that fills the verbatim-shared bullets from
  `plugins/dkj-teams/agent-shared/<name>.md` into all agent defs (between
  `<!-- BEGIN/END shared:… -->` sentinels). Change a shared block →
  run `build-agent-defs.ps1` → all agent defs updated; `-Check` (and the lint gate, check 7) fails
  on drift. The pure expansion logic lives in the lib, so [Tycho #18](04-18-extension.md) can test
  it in isolation — mirroring the `release-lib` setup. **Never edit between the sentinels by hand.**
- **`.claude/settings.json`** — this repo's harness config: the `extraKnownMarketplaces` (the
  `github` source `DKJ-Solutions/claude-code-specialists`) and `enabledPlugins` with which the repo enables
  its own `dkj-team-alpha` plugin (the core team).
- **The manifests** `.claude-plugin/marketplace.json` and every `<plugin>/.claude-plugin/plugin.json`
  (structure + `version`) — their *structure/config*; the descriptive *texts* he coordinates with
  [Tessa #16](06-16-extension.md).

#### And therefore: here Sylvester is the author who runs `simplify`

The **`simplify`** skill applies quality fixes — reuse, simplification, efficiency — and applying is the
**author's** act, never the reviewer's: [Victor #19](06-19-extension.md) may report those same findings
and is forbidden from applying them, which is why the portable layer gives the skill to
[Cody #13](../../../plugins/dkj-teams/dkj-team-alpha/manuals/04-13-manual.md) rather than to a reviewer. Here
the code is `scripts/**` and **those are Sylvester's**, so here he is that author: he runs the tidy pass
over what he changed before the diff goes to review, and never over somebody else's change.

**Why this line exists in his lens and not only in Chris's** — Sylvester does not read Chris's lens, so a
routing line alone would name an owner who is never told. And why it is not in his *portable* playbook:
his shipped scope is the **harness** (`.claude/`, settings, hooks, MCP, skills, marketplaces), while
`scripts/**` is an extension this lens gives him. Writing the skill into his agent def would claim script
authorship for him in consumers that never granted it.

### Repo-specific rules

- **NEVER ROUND-TRIP A MARKDOWN FILE THROUGH POWERSHELL TO EDIT IT — USE THE EDITOR'S OWN EDIT.**
  Measured twice in one session, August 15, 2026, both times on a lens. `Get-Content -Raw` reads with the
  **ANSI codepage** in Windows PowerShell 5.1, so every em dash, `·` and emoji in a repo whose documents
  are full of them comes back as mojibake; writing that back produced **127 corrupted sequences** in
  `06-25-extension.md` in a single command. The second failure is quieter and has no lint behind it: a
  **double-quoted** PowerShell string eats backticks as escapes, so a line containing `` `v1.0.0` ``
  silently became a **vertical tab** plus `1.0.0` — valid UTF-8, invisible in a diff, and past every
  check here.
  - **The repair for the first is already built**:
    [`fix-mojibake.ps1`](../../../scripts/maintenance/fix-mojibake.ps1) peels the inverse round trip and
    repaired all 127 in one run. Verify by diff afterwards — `111 insertions(+), 0 deletions(-)` is what
    proves nothing else moved.
  - **The second has no gate, deliberately not proposed as one.** A vertical tab is legal in markdown and
    a rule against control characters would be a check written for one careless afternoon. The answer is
    not to write the file that way: use the harness `Edit` tool, or single-quoted strings and
    `[System.IO.File]::ReadAllText/WriteAllText` with an explicit
    `New-Object System.Text.UTF8Encoding($false)` when a script genuinely must do it.
  - **Why it belongs here rather than in the language rule.** This is not a language-layer question — it
    is the mechanism by which any specialist edits any document in this repo, and it fires hardest on the
    files that carry the most prose. It cost nothing both times only because the lint's mojibake check
    caught the loud half within minutes.
- **The shared-scripts registry spans TWO plugins since August 8, 2026, and the plugin is read off the
  mirror path rather than declared.** `Get-SharedScriptPairs` maps each source to a mirror in either
  `plugins/dkj-teams/dkj-team-alpha/` (the core: `check-roster-sync`, `check-report-lib`) or
  `plugins/dkj-policy/` (everything branch- and release-shaped). Three things to
  know before touching it:
  - **`SkillRel` is derived from `MirrorRel`, not stored.** Check 18 and `shared-scripts.tests.ps1`
    both used to look for a script's documenting page at a hardcoded `plugins\teams\team-alpha\skills\…`,
    and the moment nine entry points moved, the gate reported every one of their existing skills as a
    typo. A second field naming the plugin would have been free to disagree with the path beside it;
    deriving it means a script that moves takes its page lookup with it.
  - **`check-report-lib` is registered TWICE on purpose** — one source, two mirrors — because
    `check-roster-sync` stayed in the core while `check-script-contract` went to the workflow. The
    alternative, a mirror reaching into the other plugin's cache, was rejected on sight: separately
    versioned, separately installed, so a version mismatch breaks it silently. **A duplicate entry
    needs a distinct `Name`**: the suite looks pairs up with `Where-Object { $_.Name -eq … }` in
    eleven places and would get an array back.
  - **The thing that parked this work for days was a MENTION read as a USE — the fifth instance in
    this file.** The note that stopped it said `check-report-lib` and `native-capture-lib` each had
    readers in both halves. Neither did: `open-pr`/`fold-changelog-entry` name the first only in a
    comment, and `check-report-lib` names the second to say it *needs none of* its EAP dance. Both
    rows dissolved on being read. The assert that now refuses any mirror dot-sourcing a lib from the
    other plugin is in `shared-scripts.tests.ps1` — write the check that would have caught the
    misreading, not just the fix.
- **A scaffold with nothing to fill in is invisible to a placeholder test.** The same split gave a
  core-only consumer a `repo-config.ps1` holding just the roster pair — complete as generated, so no
  `VUL-IN` value anywhere. `specialists-teardown` classifies by placeholder VALUE (the #333 lesson),
  so it read that file as authored and would have kept it forever, making adoption exactly as
  irreversible as that skill promises it is not. The second recognised shape keys on "still exactly
  what the bootstrap wrote", which is conservative in the right direction: every way an owner can
  touch that file ADDS something. **General rule: when a generator gains a mode that emits no
  placeholder, check every consumer that classifies its output by one.**
- **The agent-def frontmatter and the `plugin.json` `version` land here first**, never in a consuming
  repo — those pull them in. An agent-def config change is Sylvester's side; the agent-def *text* is
  Tessa's side.
- **The lint gate may never become quieter than the risks.** As the repo grows (more plugins, more
  complex manifests), Sylvester extends the checks — with [Tycho #18](04-18-extension.md) building
  tests alongside.
- **The test gate is bound by its SLOWEST SINGLE SUITE, not by their sum — so the next second saved is
  bought inside one file.** Measured August 7, 2026 on the same machine within one session, all 27 suites
  green every time: **510s one at a time, against 128–263s parallel over six runs (median 159s)**
  ([#512](https://github.com/DaveKJohn/claude-code-specialists/issues/512)). **That spread is the mechanism,
  not noise** — a sum averages its own variance out, a maximum does the opposite, so a gate bound by its
  slowest suite is inherently less predictable than one bound by the total. Quote the range rather than the
  best run: the first parallel measurement taken was the 128s one, and on its own it would have promised a
  4× improvement the gate delivers only sometimes. **CI gains less, and for a stated reason:** its runner
  has four cores against this machine's eighteen, so the throttle is four wide and the `lint-en-tests` job
  went from about eleven minutes to **7m2s**. What made that safe rather than
  lucky was checked before it was built, not after: no suite writes into the repo tree (every `$RepoRoot`
  reference is a read, or a `Copy-Item` *out of* it into a fixture), and no two suites share a fixture path
  — the fixed-name ones each own their name, the rest key on `$PID`. **Re-check both before adding a suite
  that touches either.** The remaining half of #512 is now the whole critical path:
  `check-plugin-integrity.tests.ps1` spends its ~154s on **86** `Invoke-Integrity` calls, each a fresh
  `powershell` start (~0.18s) plus a full lint over its fixture (~1.6s) — real work, not waste, and it
  cannot be parallelised the way the gate was, because all 86 scenarios mutate **one** fixture directory in
  sequence. `-MaxParallel 1` is the valve, and it is worth reaching for before believing a suite that only
  fails with 30 siblings competing for the disk.

  **THE LAST CLAIM IN THAT PARAGRAPH WAS WRONG, AND IT IS KEPT ABOVE SO THE CORRECTION HAS SOMETHING TO
  CORRECT** (August 16, 2026, [#714](https://github.com/DaveKJohn/claude-code-specialists/issues/714)).
  "It cannot be parallelised the way the gate was" reasoned from the wrong unit: the scenarios do all
  mutate one directory in sequence, but the gate schedules **files**, not scenarios — so the suite could
  be given the idle lanes by becoming four files, each with its own fixture, without touching the
  sequence inside any of them. It now is: `check-plugin-integrity-{links,commands,entries,docs}.tests.ps1`
  over a shared `check-plugin-integrity-fixture.ps1`, same 110 invocations, **~51s across four lanes
  instead of ~160s in one**, asserts unchanged at 234. By then the paragraph above had been measured
  again and was worse than it read: the gate's total EQUALLED this suite to a tenth of a second, four runs
  out of four, with 15 of 16 lanes idle for its last 70-86 seconds. **The generalisation worth keeping:
  when a gate's cost is one file, ask whether the work has to be one file before asking whether it has to
  be done.** The convention for the four is in [Tycho #18](04-18-extension.md#the-lint-gate-suite-is-four-files-august-16-2026).
- **Do not hand-roll a second parallel runner — and re-run a red suite alone before believing its assert.**
  Measured August 12, 2026: a `Start-Job` fan-out over all **31** suites reported **6** failures —
  `agent-shared`, `bootstrap-drift`, `config-blueprint`, `fix-mojibake`, `roster-sync`,
  `verify-resolved-issues` — two of them asserting *"lint gate green on the repo"* in as many words, which
  reads like a finding about the repo rather than about the runner. **Every one of the six passes when run
  alone**, and `open-pr` then ran all 31 green in **218s**. What the six share is that they scan the **live
  repo**: three (`agent-shared`, `bootstrap-drift`, `fix-mojibake`) by invoking the lint gate over it, the
  other three by running their own repo-wide scanner — `build-config-blueprint.ps1`,
  `check-roster-sync.ps1`, `verify-resolved-issues.ps1`. So 31 at once collide over one tree, which is the
  same collision the paragraph above describes, in its strongest form to date. **Read that list before
  adding a suite that touches the tree**, and note that the shared condition is the tree rather than the
  gate — keying the lesson on the lint gate alone would exempt half the affected suites. The lesson is
  **not** "never run the suites in parallel": `open-pr` parallelises
  them, is the tested runner, and was checked against exactly the two conditions above before it did — no
  suite writes into the tree, no two share a fixture path. A hand-rolled runner is checked against neither,
  so its red is evidence about the runner, not about the suite.

  **And the tested runner has now done it too, three times — so the second half of that lesson stands on
  its own.** *Re-run a red suite alone before believing its assert* was written for a hand-rolled runner;
  the reds of August 16 (`bootstrap-drift`, `fix-mojibake`, post-split pool) and the **11 of 54** reported
  out of the `v4.22.0` cut in
  [#1033](https://github.com/DaveKJohn/claude-code-specialists/issues/1033) both came out of
  `Invoke-TestSuiteGate` itself. Neither reproduces: five full runs on that tree were all green, and the
  release's 443s "green" figure turns out to be a **2x-load** reading rather than the gate's cost — the
  numbers are in [Nolan #25](06-25-extension.md#a-gate-verdict-that-moves-is-a-load-reading--n5-and-the-caller-is-not-a-variable-august-28-2026).
  Six of those eleven scan the live tree and five do not, so the collision above explains part of it and
  nothing explains the rest. Do not read a lone red from the pool as a finding about the tree until it has
  been run alone.
- **A count in these documents is either DATED or LIVE, and the two are maintained in opposite directions.**
  The 27 above is a dated measurement and stays 27 — the 510s-vs-159s figure beside it means nothing when
  paired with any other count. The 30 in the paragraph above is live advice about what to try next, so it
  tracks the tree. Where a sentence is dated **and** the count carries none of its argument, the count is *removed*
  rather than refreshed: that is why [`CLAUDE.md`](../../../CLAUDE.md)'s *"`open-pr` runs the lint and every
  test suite"* now states no number under its August 7 stamp. It read `26` there for five days — wrong on the
  day it was written, since there were 27, and wronger every suite since. **And a bare `26` is still correct
  in two other senses**: the lint's own checks (`CHANGELOG.md`) and the agent-def count
  ([`README.md`](../../../README.md), [`agent-shared`](../../../plugins/dkj-teams/agent-shared/README.md)). Establish
  which noun a `26` governs before touching it; a find-and-replace here breaks correct statements to repair
  one.
- **Renaming or moving this checkout unlinks its own plugin install — plan the re-install into the same
  move.** Because this repo consumes itself, it is a consumer like any other, and the install record is
  keyed on `projectPath`. Measured August 3, 2026: after the directory was renamed from
  `davekjohns-workshop` to `claude-code-specialists`, `.claude/settings.json` still enabled
  `specialists@claude-code-specialists` correctly while the machine's only record named the old folder,
  so the session loaded no subagent, skill or hook at all. Recognize it by a **deliberate** run of
  [`check-roster-sync.ps1`](../../../scripts/sync/check-roster-sync.ps1) reporting
  `[NOT-INSTALLED-HERE]` — the session-start hook cannot report it, because that hook ships in the
  plugin that did not load. The repair is `claude plugin marketplace update claude-code-specialists`
  followed by `claude plugin install dkj-team-alpha@claude-code-specialists --scope project` from the new
  root, after which a leftover record naming the old folder is expected and inert. The mechanism, the
  other two ways a record goes missing, and why that leftover is not a stray duplicate are in the
  family's [INSTALL.md](../../../INSTALL.md#staying-up-to-date);
  don't restate them here.
- **The marketplace clone follows a REFRESH, not a push — and no version check can tell you it is
  behind.** A session here reads the plugins from the local marketplace clone, which advances only on
  `claude plugin marketplace update claude-code-specialists`. Measured August 23, 2026
  ([#845](https://github.com/DaveKJohn/claude-code-specialists/issues/845)): after four PRs merged and
  pushed, the clone still stood on the previous day's `3e46b3de` while `main` was at `86f1a6c8` — the
  cached manual missing a section added that morning, the cached shared block missing a rule added that
  afternoon — and **every check reported OK**. `/plugin` had nothing to do, and
  [`check-connectors.ps1`](../../../scripts/sync/check-connectors.ps1) reported `[OK] machine record is
  on the source version (v4.18.0)`. Both compare **version strings**, and between two releases the
  version is unchanged by definition, so a clone any number of commits behind `main` is
  indistinguishable from a current one. This is the failure check 11 in
  [`check-plugin-integrity.ps1`](../../../scripts/lint/check-plugin-integrity.ps1) already names in its
  own comment — *"a stale cache reports success with a plausible version number"* — reaching the source
  repo rather than a consumer. The repair is that one refresh, which moved the clone immediately.

  **Detection is deliberately left as it is, and that is the answer rather than a postponement**
  (Dave, August 24, 2026). Having `check-connectors.ps1` compare **commits** instead of versions was on
  the table and was declined on mechanism: its version verdicts are per **consumer checkout**, and a
  consumer's clone is *supposed* to follow the releases rather than `main`, so between two cuts a commit
  comparison would report a gap on every consumer where nothing is wrong — the same shape as the
  stale-path check this repo declined at 124 findings all false. Nothing was damaged here either: a
  session read payload a few hours older than `main` carried, which for content merged the same day is
  the ordinary state. What was wrong was the **expectation** — [`CLAUDE.md`](../../../CLAUDE.md) promised
  the "last pushed" version — and that sentence is what the repair changed.

  **The measurement check 11's comment relies on has never reached this boundary, so don't lean on it
  again without re-measuring.** It records, correctly and with a date, that a bare project-scoped
  `update` advanced the clone during the run (July 31, 2026, CLI 2.1.220, 3.0.3 → 3.0.4) — taken while
  the **version number was changing**. Identical version, new content, nothing moved is the untested
  case, and it is the one that bit.
- **Always read `$LASTEXITCODE` before you pipe a native command through a cmdlet.** A construct like
  `& git … | Select-Object -First 1` cuts the upstream (git) short as soon as the first item is in;
  if the process has not yet exited cleanly at that point, it ends with a non-zero exit code —
  purely timing-dependent. Whoever reads `$LASTEXITCODE` afterwards therefore gets a flaky value and
  builds a non-deterministically red CI. The rule: capture the full output first, record
  `$code = $LASTEXITCODE` immediately, and only then filter (`Select-Object`, `Where-Object`, …) on
  the fixed array. It took three PRs on the git derivation in `bootstrap.ps1` (`Get-DerivedRepoName`) — #94
  (regex coverage), #95 (`insteadOf` rewriting), and #96 — before this pitfall was recognized as the
  root cause; the rule applies to every `scripts/**/*.ps1` that calls a native command.
- **A native command's stderr under `$ErrorActionPreference = 'Stop'` becomes a *terminating*
  error — even when the command exits 0.** `git push` writes its `remote:` progress to stderr, so
  under `Stop` PowerShell 5.1 aborts the script on the push before the `$LASTEXITCODE` check can run
  (this bit `open-pr.ps1`'s push step). Sibling of the rule above: don't lean
  on stderr-as-failure. Run the call with `$ErrorActionPreference = 'Continue'` around it, capture
  `2>&1` (or `2>$null` when you only want stdout, e.g. `gh ... --json`), record `$LASTEXITCODE`,
  restore the preference, and only then judge. Applies to every native call whose stderr is normal
  chatter — `git push`/`git fetch` (`remote:`), **`git add` (the autocrlf LF↔CRLF warning — this
  broke `cut-release.ps1` while cutting v1.12.0)**, `gh` (auth/update notices), … Query commands
  (`git rev-parse`, `git status`) write results to stdout and only real errors to stderr, so `Stop`
  is correct there — don't wrap those. Swept across all release scripts after the v1.12.0 break.
- **Never name a local variable after a `$script:` variable a dot-sourced repo lib owns.** PowerShell
  variable names are case-insensitive, and at script top-level the local scope *is* the script scope
  — so `$changelogHeading = '<default>'` in a script that has dot-sourced `repo-config.ps1`
  overwrites that file's `$script:ChangelogHeading` **before** the `Get-…` accessor is ever called.
  The accessor then dutifully returns the default, and the configured value silently disappears: no
  error, no warning, just the fallback everywhere. This bit the `Get-ChangelogHeading` work for
  inbound #178; the fix is a distinct local name (`$foldHeading`). Sibling of the `$RepoRoot`/
  `$repoRoot` collision already documented at the top of `fold-changelog-entry.ps1`. Rule: when you
  read an optional repo-config value into a local, give the local a name that is not the backing
  variable's — and prove it with a test that sets a *non-default* value, since a test using the
  default passes either way.
- **Never dot-source a consumer's repo-owned lib under `Set-StrictMode`.** A check or hook that
  dot-sources `scripts/lib/branch-info.ps1` or `scripts/repo-config.ps1` to probe it (e.g.
  `check-script-contract.ps1`, `check-roster-sync.ps1`) must load it in a child scope with
  `Set-StrictMode -Off` (`& { Set-StrictMode -Off; . $lib; ... }`), because the real workflow scripts
  that consume those libs (`open-pr.ps1`, `new-branch.ps1`, `fold-changelog-entry.ps1`, …) never
  enable StrictMode, and both libs are explicitly written on that no-strict-mode assumption. Probe the
  functions (`Get-Command`) inside that same block so the dot-sourced definitions stay visible while
  nothing leaks into the check's own strict scope. Load under strict mode instead, and a consumer copy
  carrying harmless pre-strict-mode loose top-level code (an `if` on an unset variable, say) throws on
  the dot-source — a false `[ERROR]`, or under `$ErrorActionPreference = 'Stop'` a full crash — at
  every session start, for exactly the older consumer repos these checks exist to serve. A genuine
  load failure (a real syntax error) should degrade to a sane default or a reported `[ERROR]`, not
  abort the check. Recognized while building the script-contract check for inbound #147 (#148) and
  immediately found in its sibling `check-roster-sync.ps1` (#149).
- **Mask fenced code blocks before you pair inline backticks — a fence silently shifts every span
  after it.** A `` `[^`]+` `` pattern cannot open a span on the first two backticks of a ``` `` ``` run,
  opens one on the third, and closes it on the *first* backtick of the closing fence; from there every
  real inline span in the file pairs one position out. Nothing errors, so a scan built on those spans
  reads the wrong text and reports a plausible answer. Measured on July 31, 2026 while building check
  11: a command whose flag sat on the next line of its own span came back looking **flagless**, i.e.
  the gate under-reported rather than raising. `Get-FenceMaskedText` in
  [`check-plugin-integrity.ps1`](../../../scripts/lint/check-plugin-integrity.ps1) already solves this
  and keeps offsets and newline positions identical, so a span found in the mask indexes straight back
  into the real text — reuse it rather than writing a second fence walker. Sibling rule for the same
  scan: judge one command's own arguments, not the whole span, or two commands in one span let the
  second borrow the first one's flags (Victor, same build).
- **`return @($x)` does not return an array when `$x` is one item — and indexing the result then yields
  a character.** PowerShell unrolls a single-element array on return, so a helper written as
  `return @(...)` hands back a bare `[string]`; `$result[0]` is then its first *letter*, and
  `$result.Count` is `1` either way, so the length guard that was supposed to protect the index passes.
  Measured the same day in `teardown-protocol.tests.ps1`, where a check-ignore line's first field read
  as `.` instead of `.gitignore:2:`. Rule: wrap at the **call site** too — `$r = @(Get-Thing ...)` —
  whenever you are going to index or slice, and do not rely on `@()` inside the function. Same family
  as the two rules above: the wrong answer arrives as a plausible value instead of an error, which is
  the failure mode this repo's gates exist to catch and therefore the one its own tooling must not
  have.
- **A check's `[ERROR]` text is a consumed interface, not just prose.** `skills/sync-roster/sync-roster.ps1`
  does not re-implement detection — it *parses* `check-roster-sync.ps1`'s finding lines with a regex
  (`\[ERROR\]\s+(?:agent|persona) '(?<id>\d{2}-\d{2})' \(...\) has no (roster row|repo-lens)`). So
  rewording or widening a finding silently changes what the recovery skill can act on. Inbound #204
  hit exactly that: extending the check to persona-only specialists made it emit
  `persona '01-01' ... has no roster row`, which the then-`agent`-only pattern did not match — while
  both the check's own report *and* the session hook point the reader at that skill to stage the
  catch-up. Left alone it would have shipped advice that looks helpful and does nothing, for precisely
  the findings the change introduced. The rule: when you touch a finding's wording or scope, grep for
  who parses it before you touch the message. The integration tests in
  `scripts/tests/sync-roster.tests.ps1` drive the REAL check (not a stub) for exactly this reason, so
  they do fail on a wording change — treat that failure as the coupling reporting itself, not as a
  test to patch.
- **Verify a diagnosability fix against real data, not against the diff.** A report that "names the
  thing" reads correct in review and can still be useless in practice. The #203 fix made
  `check-connectors` label each finding with its connector — provably right, fully tested, and still
  producing two word-for-word identical lines when run against this repo's own register, because that
  consumer registers *two* plugins and both were behind on one outdated install. The distinguishing
  `-- plugin:` header was the very thing the hook filters away. Only running it surfaced that; the
  label now carries `<repo> / <plugin-id>`. For any change whose whole purpose is "make the output
  actionable", run it against the real register/repo before calling it done — a fixture proves the
  mechanism, not the usefulness.
- **A documented rule is not a mechanism, and a silent signal is not a signal.** The connectors README
  had carried "after a refresh, also update the manifest" for days when a deliberate run of
  `check-connectors.ps1` found eleven inventory-drift findings at once — six in this repo's own
  register, where the lenses had landed with PR #212 and the inventory was never updated alongside. The
  rule was on the books and had been followed exactly zero times, because the finding is an `[INFO]` and
  the session hook surfaces only `[ERROR]`: nothing ever reported the omission, so nothing ever
  prompted anyone. Writing the rule down more firmly would have changed nothing. What changed it was the
  non-counting `[INVENTORY]` marker (July 29, 2026) — the third instance of the
  `[UNREGISTERED]`/`[ORPHANS]` shape. **When a rule depends on someone remembering a follow-up step, ask
  what would report the omission; if the answer is "a deliberate run nobody has a reason to make",
  the rule needs a mechanism, not a sharper sentence.**
- **`Write-Host` output is invisible to a same-process pipeline, so an in-process assertion about it
  silently passes.** While verifying the `[INVENTORY]` marker by hand, `$out = .\check-connectors.ps1;
  @($out | Where-Object { $_ -cmatch '\[INVENTORY\]' }).Count` returned 0 for the case that *should*
  emit it — the line was plainly visible on the console, but `Write-Host` writes to the host and never
  enters the pipeline. Both the positive and the negative case therefore "passed", which is the
  dangerous half: a scoping test that can only ever read 0 proves nothing. The checks use `Write-Host`
  throughout (deliberately — it carries `-ForegroundColor`), and the hook only captures it because it
  runs the check as a **child process**, whose stdout *is* captured. So: verify these scripts the way
  the hook consumes them, via `& powershell -File …`, and treat a negative assertion that cannot
  distinguish "absent" from "uncapturable" as no assertion at all. The suite in
  `scripts/tests/connectors.tests.ps1` already does this correctly through `Invoke-Ps`.
- **Run a suite from the tree it is meant to judge — `$PSScriptRoot` follows the file, the working
  directory does not.** `roster-sync.tests.ps1` asserts that the git-root fallback lands on the repo the
  test runs inside. Invoked by absolute path out of a linked worktree while the shell's CWD was still
  the main checkout, it failed on exactly that assertion: `git rev-parse --show-toplevel` answers for
  the *process's* directory, not for the script's. 125 pass, 1 fail — a red suite caused entirely by
  where it was launched from, and the temptation is to read it as a real regression in the branch under
  test. `Push-Location <worktree>` around the run (or `git -C`) is the whole fix. **Sibling of the
  `Write-Host` trap above, and the same underlying mistake: verifying from the wrong vantage point.**
  One produced a false pass, this one a false failure — so the rule is not "distrust green" or
  "distrust red" but: before believing either verdict, confirm the check was observed from the same
  place its real consumer observes it. Both instances happened on July 29, 2026, within one session.
- **The non-counting marker is a standing pattern now, not a series of exceptions.** Five instances:
  `[ORPHANS]` (inbound #204), `[UNREGISTERED]` (#208), `[INVENTORY]` (#220), `[BOOTSTRAP]` (#225) and
  `[RECORD-SHAPE]` (#314/#315 — reached for rather than invented, which is this bullet working as intended).
  Each solves the same problem — a finding that is **real, actionable, and about the repo the session is
  in**, but that would be wrong as an `[ERROR]` because nothing is broken and a red line plus exit 1
  would be a lie. Each is also the answer to a specific failure: an `[INFO]` the session hook suppresses
  is, from the reader's seat, indistinguishable from no finding at all. **The recipe:** emit a dedicated
  bracketed token with `Write-Host` (never through `Write-Failure`/`Write-Info`, so the summary count
  and the exit code stay untouched), have the hook match it with its own `-cmatch` outside the
  `$signals` list, and give it **its own verdict line** rather than folding it under an existing one —
  `[BOOTSTRAP]` arrives on an exit-0 run, so without that branch it would have fallen through to
  "roster in sync", which for a repo with no roster is a flat untruth. When a fifth case appears, reach
  for this shape before inventing a new one, and ask the classification question first: if the finding
  could indicate tampering or a genuine breach it must be an `[ERROR]`, per the connectors README rule.
- **A repo-wide verdict must be computed where the evidence is complete, not where it is convenient.**
  The first `[BOOTSTRAP]` implementation short-circuited *before* the plugin-resolution loop, since that
  is where the predicate (no lenses, no roster rows) is cheapest to evaluate. It shipped a regression
  immediately: a repo whose plugin is enabled but **not present in the cache** was told to run
  `specialists-init`, when the real cause was that the plugin is not installed on that machine at all —
  two states that look identical from outside the loop and need opposite advice. The fix was to let the
  loop run, suppress only the two findings the marker replaces, count them, and emit the marker
  afterwards; everything else the check knows (not-in-cache, orphans, off-path lenses) still reports.
  `roster-sync.tests.ps1` caught this within one run, which is the argument for adding the guard case in
  the same commit as the feature rather than after it.
- **`Select-Object -First N` kills a child process mid-run; `-Last N` cannot.** The `$LASTEXITCODE`
  rule above says not to pipe a native command through a cmdlet — this is the sharpest instance and
  the discriminator that makes it predictable. `-First N` tears the pipeline down the moment N items
  are in, and the still-running upstream process dies with it; `-Last N` has to drain the entire
  stream to know what the last N are, so it is harmless. Measured on July 29, 2026 while measuring the
  fresh-consumer install: piping `bootstrap.ps1` into `-First 1` created **zero** lenses and reported
  nothing wrong, and into `-First 20` it wrote 19 lenses and exited **255** — while `-Last 25` on the
  identical command completed normally with exit 0. Both truncations look like display choices in the
  diff. The consequence was worse than a crash: the harness went on to measure an *unbootstrapped*
  repo and label the numbers "after bootstrap", and the first explanation reached for was a bug in
  `Get-DerivedRepoName` — a real hypothesis, tested across three git states (no repo / repo without
  remote / repo with remote), all exit 0. **So: capture a child process's output into a variable in
  full, then slice the variable — and when setup runs before a measurement, check its exit code and
  abort rather than measuring past it.**
- **MENTION vs USE — the day's recurring defect, and the rule that covers all three.** Three separate
  checks were satisfied by text that merely *named* the thing they look for, rather than *using* it:
  `check-roster-sync` counted an `@`-import path as a roster row because the path contains the id
  (#227); the lint gate's check 10 read a marker quoted in changelog prose as a real enumeration, on
  `main`, where no PR gate could see it (#235); and `specialists-teardown` classified a fully configured
  `repo-config.ps1` as an unfilled scaffold because the scaffold's own **docstring** still says "fill in
  the remaining VUL-IN values" — which is the *normal* state of a filled-in scaffold, not an edge case.
  That third one would have **deleted** the file `open-pr`, `fold-changelog`, `new-branch` and
  `check-roster-sync` all depend on, and only a dry run against a real consumer
  (`davekokbwj/smartwatchbanden`, July 29, 2026) surfaced it — every fixture had scaffolds that were
  either untouched or rewritten, never the real-world middle state.
  **The rule: when a check's evidence is "this string appears in the file", ask what else in that file
  legitimately contains it — docstrings, prose, links, paths — and key on the string in a POSITION that
  only real use produces.** A placeholder in an assignment's *value*, an unfilled slot *heading*, an
  empty table. And for a script that deletes, resolve every remaining doubt toward keeping: a false
  keep leaves clutter, a false remove destroys someone's work.
- **A gate can only fail on the files it scans — and a *transient* file is where that goes wrong.** The
  lint gate's scan set (`$linkFiles`, feeding both check 4's link scan and check 10's skill spans) listed
  every permanent doc but not the root changelog **entry** files. So an entry's text was invisible while
  the PR was open and became visible only at **fold** time — directly on `main`, in one of the two
  sanctioned direct-on-`main` actions, past every PR gate. The error then surfaced at the next full gate
  run, `cut-release.ps1`, which is why v2.13.0 was blocked by a changelog sentence. Note the shape: no
  check was wrong, the *timing* was — the gate's verdict was "green so far", not "green" (#234, closed
  July 29, 2026 by adding root entry files to the set, keyed on the entry format's `###` heading, so a
  permanent root doc with its `#` heading never joins). **The rule: when a gate checks file A and some
  other step copies text into A, the gate must also check where that text was authored.** Ask which file
  the content was *written* in, not which file it ends up in.
- **A check that scans a file for a token can be satisfied by a *path* containing that token.**
  `check-roster-sync` looks for each `<group>-<id>` in the roster file, and the bootstrap wrote
  `@.claude/plugins/claude-specialists/dkj-team-alpha/01-01-extension.md` into `CLAUDE.md` (the pre-seam
  lens path of the time; since #253 it writes the one seam line instead). That import
  line contains `01-01`, so Chris counts as rostered without a roster row ever existing — measured
  July 29, 2026: 18 ids reported missing after a bootstrap, not 19, with `01-01` the one silently
  passing. It is the worst possible id to lose, because a persona appears in no always-on listing at
  all and the roster row is the *only* thing that makes him exist for a session. Same class as the
  roster token-boundary fix in v2.6.0, so treat that fix as incomplete rather than done: **when a
  check's evidence is "the token appears in the file", ask what else in that file legitimately
  contains the token — a path, a link, a changelog line — before trusting a pass.**
- **Restoring a file with `Set-Content -Encoding utf8` is not a restore.** PowerShell 5.1's `utf8`
  means *with BOM*, so writing a captured `$orig` back leaves a byte-level diff (`M-oM-;M-?{`) on a
  file that was BOM-less — a "clean" restore that shows up as a modified file. When a probe needs to
  mutate a tracked file temporarily, undo it with `git checkout -- <path>` rather than rewriting the
  captured content.
- **`claude plugin marketplace remove` rewrites the *project* `settings.json` of the working directory you
  run it from — not only the scope the marketplace was declared in.** Measured on July 29, 2026 while
  cleaning up the two throwaway plugins of the [#215](https://github.com/DaveKJohn/claude-code-specialists/issues/215)
  experiment: it emptied the test consumer's `enabledPlugins` **and** `extraKnownMarketplaces`. So run it
  from a throwaway directory, never from a repo whose `.claude/settings.json` you want to keep. The full
  account, including how the damage was spotted, is in
  [PR #256](https://github.com/DaveKJohn/claude-code-specialists/pull/256)'s changelog entry.
  **And the lookup lesson that came with it:** the first version of this bullet declared the mechanism
  unrecorded and left it at an operating rule, because it went looking in the lenses and the manuals. It
  was on record all along — in that PR's entry, folded into `CHANGELOG.md` one commit earlier. Before
  writing "this was never captured", grep `CHANGELOG.md` and `releases/**` too: an entry body is where
  this repo's findings land *first*, and a lens is usually the second home, not the first.
- **When a tool refuses with "auto mode cannot determine the safety", retry it — do not route around it
  via the Bash tool.** A recurring platform fault on July 29, 2026 made PowerShell and Edit calls refuse
  intermittently; it comes and goes, and a plain retry clears it. That the Bash tool can usually do the
  same work is exactly the trap, because it makes the workaround feel like resourcefulness: reaching for
  it converts a transient refusal into a deliberate bypass of the safety decision that produced the
  refusal. The refusal is not the obstacle to route around — it is the mechanism working. Wait it out.
- This repo is **public**: config never contains secrets.

### How the gate checks got their shape, and the measurements behind them (August 15, 2026)

*Moved here verbatim from [`CLAUDE.md`](../../../CLAUDE.md)'s lint-gate bullet, where it was 9,440 B
over 102 lines — 26% of the always-on document, paid by every session before a word of work. The
operative rule stayed there; this is the evidence for it, and the second half of the same split that
moved the release craft to [Rendall #06](05-06-extension.md) the day before. Nothing was reworded:
the passages below still speak in the constitution's voice, and the dates and issue numbers are the
point of keeping them.*

**The entry format is described in about ten hand-maintained places, and the answer is a check rather
than a clear-out** (Dave, August 7, 2026;
[#508](https://github.com/DaveKJohn/claude-code-specialists/issues/508)). Two of those descriptions were
measured stale during a sweep that was looking for exactly that, one of them consumer-facing. The
alternative — deleting the shape from every document and pointing at
the generated reference under `dkj-policy/branch/templates/`, a directory the merged development
cycle has since retired — was weighed and declined: the prose costs every reader on
every read, while a check costs nothing per read. **What is checked is the section COUNT, not the
section names**, and that was settled by measuring four candidate rules against the tree rather than by
argument. A name-matching rule produced **six** findings on the tree, **all six false**: `What does this
change do?` and `Type of change` are retired entry sections *and*, at the time of that measurement, were
live headings of the PR template, so it accused **two** correct documents of being stale for describing
that template accurately — and would have been born red behind an exemption list, the shape this repo was
already bitten by. The count is a fact the scaffolder owns, both recorded drifts stated it, and holding it
needs no exemptions at all.

**That collision is gone since August 9, 2026, and the conclusion does not move with it**
([#538](https://github.com/DaveKJohn/claude-code-specialists/issues/538)). Both headings were removed from
the PR template, so the six false findings can no longer be reproduced from the tree. The measurement is
kept in the past tense rather than deleted, because a superseded measurement is worth something only while
it says *when* it was taken. Two reasons the count still wins: name-matching also lost on its narrowed
variant (3 findings, 2 false, against 4 claims with 3 correct), and a rule keyed on names is one rename
away from going silent — which is exactly what just happened to this collision, and would as easily happen
to a match the check depended on.

**A check on stale PATH references in prose was measured and declined** (August 9, 2026), and the reason
generalises past this one rule, which is why it is recorded rather than forgotten. The proposal came out of
a README sweep that found a title naming `specialists/scripts/`, a directory the plugin reorganisation had
removed — a defect no gate sees, since check 4 reads markdown **links** and this was a path in inline code.
The obvious rule is "a path in backticks must resolve against the tree". Five candidates were measured over
120 documents (history excluded as in checks 11 and 12), each with the most generous resolver a checker
could honestly use — repo root, the document's own directory, and every ancestor between:
requiring a separator **and** an extension gave **124** findings, a separator alone **349**, an extension
alone **621**, either **736**. **Not one of the 124 was a true finding**, and the narrowest rule does not
even reach the measured defect — `specialists/scripts/` carries no extension — so catching the one real
instance means adopting a rule born with 349.

**The reason is structural, and it is about what this repo is.** Being a plugin source, most paths it
names correctly describe *somebody else's* repo: `.claude/extensions/…` is the legacy lens location this
family deliberately still documents for unmigrated consumers, `config/settings_data.json` is a Shopify
store's file named in `dkj-team-shopify`'s manual, `PRETTY/[Emotie]/README.md` is a life-hub folder. All three
answer "no such file here", exactly as the stale title does — and **the difference is whose repo the line
is about, which the line never says**. An existence check reads "describes a consumer" as "stale", and no
regex recovers that distinction. Do not revive it behind an exemption list: that is the shape this repo has
already been bitten by, and the list would need to hold the entire consumer-facing vocabulary.

**What survived, unbuilt and deliberately so:** a title claiming a path must name its own location. It
sidesteps the anchor question entirely, because a document knows where it sits — 4 subjects tree-wide,
0 findings today, and verified against `33a41a2` to fire on the real defect. Not built, because four
subjects is close to nothing to guard; worth revisiting when per-directory READMEs multiply.

**The PR template that caused the collision is itself the change** (Dave, August 9, 2026). It now carries
one section — the changelog entry — because `open-pr.ps1` composes the body from
the DEPLOY section of `dkj-policy/<branch>.md`, so everything else it asked was already answered four lines lower. Measured
over 60 PRs before removing anything: `Type of change` had exactly **one of four** boxes ticked every
single time, a fact the entry states under `### Branch type` and which the GitHub label takes from
`Get-BranchInfo` rather than from the tick; of the checklist, `Requested by Dave` and
`Changelog entry written` were ticked **60/60** — both by the script itself — while the two items the
docstring called "human judgement checks" were ticked **0/60**, by anyone, ever, though both were already
enforced by gates that block the PR. A box that is always ticked and a box that is never ticked carry the
same information. The template also still offered a `chore/` row, four days after
`Test-BranchName` began refusing that prefix outright — the one line in the form that could actively
mislead. **`open-pr.ps1` keeps filling all of it in**: a consumer's PR template is their file, every one of
them still has those sections, and they receive the script through a plugin update rather than by choosing
to. Recognise both, write one.

**What travels from that decision is the MEASUREMENT, not the two-line answer** (August 10, 2026;
[#573](https://github.com/DaveKJohn/claude-code-specialists/issues/573)). The rule is *"keep what is
neither restated by the entry nor proven by a gate"*, and in this repo nothing survived it — which is a
fact about this repo, not about the form. The consumer who reported that issue re-ran the same
measurement over their own 60 PRs and found **one box of eight that genuinely varied**: a preview-URL
approval, on a repo whose result has to be judged by eye and which no gate can prove. They kept it and
dropped the other seven, and that is #538 applied rather than #538 ignored. So the portable half — the
`open-pr` skill and the reference template the plugin now ships — states *why* the default is two lines
and asks the next repo to run the measurement, instead of shipping "the portable template has no
checkboxes" as a conclusion. Their same pass confirmed the failure this repo predicted when it removed
the prefix checklist: **5 of their 60 PRs ticked two rows and 2 ticked none**, while the label came from
`Get-BranchInfo` in all 60.

**The template's shape is shipped, and the placeholder list moved so a gate could reach it** (same
issue). `.github/pull_request_template.md` cannot live in the plugin — GitHub reads it only from that
path in the consumer's own repo — so what ships is a reference to copy and diff against, at
`plugins/dkj-policy/templates/pull_request_template.md`, held byte for byte to
`Get-PrTemplateReference`. The three recognised placeholder strings were three literals inside
`open-pr.ps1`, which meant **nothing outside that script could read them**: the reference could not be
held against the list that has to recognise it, and that gap is the defect the issue reported. They now
live in `pr-body-lib.ps1`, and lint check 24 holds both files — the shipped reference byte for byte,
this repo's own template only to the contract, which since #865 is a recognised placeholder line and
nothing else: `open-pr` reads where the placeholder sits rather than the first heading, so a heading-less
template — the shape this repo actually ships — is supported and the gate must not refuse one. The second
file is held weakly because it is genuinely repo-owned, and a byte rule would refuse a correct change the
day it grows a section.

**The gate reaches `CHANGELOG.md`'s intro, and getting it there took two independent repairs** (August 8,
2026; [#525](https://github.com/DaveKJohn/claude-code-specialists/pull/525)). The check was born
excluding that file whole, on the history grounds it shares with checks 11 and 12 — but only the entries
below the intro are history. The intro is a live statement about the present mechanism that every cut
copies through **verbatim**, so it is the one piece of prose here that no release rewrites and no reviewer
opens; measured on the day it was repaired, it had promised *three* named sections for two days, with one
release and a consumer-facing release page in between. **Repairing either half alone changes nothing**:
the file was unread, *and* the pattern would have walked past the sentence anyway, because it carried no
`###` marker and ran across a line break. So the intro gets its **own pass with the level marker
optional**, and matching runs over the whole text instead of per line. Both relaxations were chosen by
measuring: whole-text matching finds the same **4** claims in the scanned tree as per-line, while dropping
the marker tree-wide would find **50** — which is why it is dropped only across the dozen lines of the
intro, where it was the whole difference between catching the drift and not.

**A link check that WAS built, and the neighbour it had to be told apart from** (August 29, 2026;
inbound [#1066](https://github.com/DaveKJohn/claude-code-specialists/issues/1066), lint check 30). The
declined stale-path rule above is the one this had to be measured against, because it looks like the
same proposal: another rule about paths in plugin-shipped prose, in a repo whose paths mostly describe
somebody else's tree. It is not the same, and the difference is the whole reason it was built — a path in
backticks is a *heuristic* about what a string means, while this is a **path comparison** with a
mechanical answer.

**The gap check 4 cannot close, and is right not to.** The dead-link scan resolves every link against the
tree it runs in, and for plugin payload that is the source repo — the one tree where the link is
guaranteed to work. It is correct about where the file *is* and has no notion of where the file will be
*read*. So the single class of link defect that reaches consumers is the one class it is structurally
blind to.

**The mechanism, read off disk rather than reasoned about.** Every `installPath` in
`~/.claude/plugins/installed_plugins.json` has the shape
`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`. The plugin's own directory is the root, and
the `plugins/` level, the family level (`teams/`, `workflows/`) and every sibling plugin are all gone —
a sibling is a separate versioned directory, not a neighbour. Worth knowing because the **marketplace
clone** is a full checkout of this repo, `.claude/` included, so a link verified there resolves and
teaches you the wrong lesson; the clone is where the catalog lives, the cache is where an installed
plugin is read.

**The report's own boundary was wrong, and its size was wrong in the direction that mattered.** #1066
proposed the rule as *"must resolve to a target also under `plugins/`, because that is the subtree the
plugin cache contains."* The cache contains no such subtree, and the weaker rule passes the one link that
had **already shipped dead** — `cut-release/SKILL.md:123` pointing at
`../../../../teams/dkj-team-alpha/manuals/06-25-manual.md`, verified against the installed v4.22.0 copy. So
the boundary is the **plugin root**, not `plugins/`, and scenario 37 of
`check-plugin-integrity-links.tests.ps1` exists to pin exactly that difference. The report also argued
from an expected count of **zero** (*"which is itself the reason not to build it yet"*) and stated that
nothing had shipped; the real count was **17 escapes in 5 files**, every one passing check 4, and
resolved inside the installed copies (`dkj-team-alpha` 4.21.0, `dkj-policy` 4.22.0) **all 17 are
dead**. That inverted its conclusion rather than qualifying it: the repo's name-a-risk-and-leave-it rule
holds until something bites, and this had bitten seventeen times in released payload.

**The two counts are different measurements and both are worth keeping**, because conflating them is how
the report went wrong in the first place. *17 escapes* is a property of the source tree, found by asking
where each link would land. *17 dead* is a property of the plugin cache, found by resolving those same
links inside `~/.claude/plugins/cache/` — the tree a consumer actually reads. They happen to be equal
here; nothing guarantees they are, and the second is the one that describes what a consumer meets.

**What it cost to hold to the same bar the declined rule was held to:** 98 relative links read across 83
markdown files in 5 plugin roots, 17 findings, **17 of them real** — against the stale-path rule's 124
findings, none real. Personas are excluded for check 4's reason and not a new one (their links are meant
to resolve at the consumer's `.claude/extensions/`, where check 4 already validates them), and three
forms are passed over: a `${...}` target is the plugin-relative form, a `~/` one points at the
marketplace clone deliberately, and an absolute URL is the repair being asked for.

**A prose contract check — the pointer-test analogue of `check-script-contract.ps1`, applied to law
instead of code — was measured and declined** (Dave, September 4, 2026;
[#1380](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1380)). Inbound
[#1379](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1379) asked for the two-sided
mechanism it names: a manifest of the laws `dkj-policy` legislates, and a consumer-side
check reporting any always-on consumer document that answers a listed law without declaring itself a
seam answer.

**The two facts that carry the decline, stated first because they are stronger than the structural
argument below on their own.** First, **the law the check was written to catch has zero standing true
positives.** `LAW-RELEASE-ORDER` was the acceptance test because
[#1378](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1378) had just made it the one
known-real defect in the corpus. #1378 was then repaired (commit `1db93328`) — Block 2's cut-then-push
became a default a live stage may answer differently, so the consumer's push-then-cut is now a
sanctioned answer the plugin actively invites, not a divergence. All 3 of that law's true positives were
in the English co-occurrence candidate and all 3 reclassify as sanctioned: the check's own reason for
existing was repaired out from under it while it was being measured. Second, **the detector found 1 of
the 3 defects that actually stand in the corpus.** The three: the stale `development.md` restatement in
each BWJ consumer (2, filed as #1389) and `smartwatchbanden`'s supremacy inversion (1, see below). Only
the `xoxowildhearts` `development.md` instance was ever flagged. The other two are false negatives —
`smartwatchbanden`'s stale instance was missed because the term list wanted a word that section does not
use, and the supremacy inversion was suppressed by the strict pointer match, the failure mode described
next. Recall on the real defects is 1 in 3, alongside the precision below.

**The corpus, corrected.** The original count of 13 documents counted this repo's own 4 always-on
documents (root `CLAUDE.md`, `SPECIALISTS.md`, Chris's persona, Chris's lens) as if they were a
consumer's, when this repo is the plugin's source and not a consumer at risk of drift — and it counted
Chris's persona three times, once per repo, when it is a single external file `@`-imported from the same
marketplace-clone path by all three repos, so 3 repos × 4 documents each collapses to 10 unique
documents, not 12, before any exclusion is applied. Applying the source-repo guard and excluding
plugin-shipped payload (`Source -eq 'external'`) removes this repo's 3 repo-specific always-on documents
(`CLAUDE.md`, `SPECIALISTS.md`, the lens) and the shared persona entirely, leaving **8 consumer-only
documents**: 6 always-on (`CLAUDE.md`, `SPECIALISTS.md`, the lens — 3 per repo × 2 BWJ consumers) plus 2
non-always-on `dkj-policy/CONTRIBUTING.md` (one per BWJ consumer).

**Four candidates measured (raw findings / true positives / precision), over the 8 consumer-only
documents:** a verbatim distinctive cue found **1 / 1 / 100%**; subject-term co-occurrence found
**21 / 1 / 4.8%** in English and **3 / 2 / 67%** in Dutch, **24 / 3 / 12.5%** combined; the same test
with a normative marker added found **13 / 1 / 8%** in English and **2 / 1 / 50%** in Dutch, **15 / 2 /
13%** combined; a declaration-based check — does the section say it is a seam answer — found **88**
(11 laws × 8 documents), zero declarations in any repo. The English and Dutch precisions move in
opposite directions between C2 and C3, but the combined figures, 12.5% against 13%, are indistinguishable
— the earlier apparent gap was an artifact of where three particular hits happened to sit, not a real
effect of adding the marker.

**The load-bearing structural reason: a strict pointer match suppressing a real contradiction is a
demonstrated failure mode, measured at 1 in 4 — not a coin flip and not "almost always."** By
construction a *flagged* finding is a section carrying no citation, so cites-then-contradicts can never
appear among flagged findings; it can only appear among **suppressed** ones, and the full census there
is 4 sections: 1 cites-then-contradicts, 3 cites-and-correctly-defers. The one is
`smartwatchbanden`'s own preamble: it names `CONTRIBUTING-portable.md` as a pointer into the plugin and,
four lines later, overrides it — the clause reads `wint` directly beside `` `CLAUDE.md` `` and names the
contributing page by a Dutch prose noun, `de contributor-pagina` (`smartwatchbanden/CLAUDE.md:22`).
Every candidate suppresses that finding, because the portable page's
filename sits right there. It is the cleanest real instance in the corpus and the detector is
structurally blind to it — a pointer test built on "is the source mentioned nearby" cannot distinguish
correct deference from restatement-with-citation-and-override, and 1 suppressed contradiction against 3
suppressed correct deferrals is the demonstrated rate, not an assumption. The parallel to the stale-path
decline above is exact, down to the shape of the failure: there the difference was *whose repo the line
is about*, which the line never says; here the difference is *whether the sentence agrees with or
contradicts the source it cites*, which no regex or term list reads.

**The verdict, at any of the three modes the inbound item proposed.** No candidate is shippable as a
gate, a SessionStart hook, or a deliberately-run `[INFO]`-only audit — the middle ground was measured
too, because #1380 explicitly asked about "a session-start check rather than a manually-run audit," and
the in-tree precedent exists (`check-script-contract.ps1`'s reachability half is always `[INFO]`, and
the hook passes `-SkipReachability`). It fails on its own terms: a human triaging 24 sections by hand to
find 3 real ones, at 1-in-8, with the flagship law gone, is not worth the run.

**The declaration-based check (C4) keeps its own, separate reason.** It is the structurally sound
design — a declaration is checkable the way a function signature is — and it reports 88/88 undeclared
because no consumer has adopted the convention: born red, in exactly the shape this repo already names
as a smell in itself. If it is ever revived it needs the convention bootstrapped first, the same way
`Get-LiveStage` and its siblings existed as real, populated seams before the script contract's
reachability half meant anything. Opt-in, per repo, `[INFO]` only, never `[ERROR]` against a convention
that does not exist yet.

**A third legitimate case surfaced that the third-rank corollary above does not name, and it is exactly
why "consumer prose answers a listed law" cannot be the trigger on its own.** Sometimes the plugin
*asks* for the answer to be written out: `cut-release`'s Block 2 declines the seam deliberately —
*"No seam, deliberately"*, `Get-LiveStageCutOrder` exists nowhere — and tells a consumer running the
non-default order to state it in its own `CLAUDE.md`. That case is filed as
[#1388](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1388) rather than resolved here.

**Record the alternative that IS proportionate, because a decline that names no better route invites the
same proposal again.** Two narrow, literal, high-precision one-off greps, each aimed at one law instead
of one framework carrying eleven at 12%: one for the literal string `development.md` outside the
changelog and history paths, one for a supremacy declaration — `wins`/`wint` plus `CLAUDE.md` plus the
contributing page's own filename, all three in the same sentence.

**The first of the two was built the same day** ([#1389](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1389),
September 4, 2026): `check-retired-doc-name.ps1`, driven by a SessionStart hook in every consumer and
[described above on this page](#what-sylvester-owns-here) — both greps live in
`check-consumer-prose.ps1` since #1421 merged them, one day later and before either had shipped. It kept the three constraints this entry
imposes — literal names, derived rather than listed; the corpus as an inclusion list with the changelog
out; and the publishing-repo skip — and it carries one stated gap, the shape `development-<branch>.md`,
which has no literal form.

**The second was built later that same day** ([#1415](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1415),
September 4, 2026): `check-supremacy-declaration.ps1`, its own SessionStart hook, and
`Get-ConsumerProseDocuments` — the corpus enumeration lifted out of the first check so both read one
definition of which documents a consumer-prose check may look in. **And the sentence above it, the one
this entry recorded as the alternative, did not survive its own measurement.** That is worth stating in
the entry that wrote it rather than quietly correcting: it had never been run as a check, #1415 asked for
it to be measured before it shipped, and over the same 8-document corpus the three-term same-sentence
test scores **0 raw findings and 0 recall** — on the single defect it was named to catch. Loosened to a
paragraph it finds **1**, and that one is a false positive.

**The reason is exact and is the useful part.** The instance is
`smartwatchbanden/CLAUDE.md:22`, whose clause carries `wint` beside `` `CLAUDE.md` `` and names the
contributing page by a Dutch **prose noun**, `de contributor-pagina`, not by its filename — so the third
term is precisely the one absent. The filename sits two lines up, in a different sentence. Nothing about
the sentence is unusual; what was wrong was inferring a term list from a defect that had been read
rather than grepped.

**What ships instead is ADJACENCY, and it is the same literalness arriving at a different rule.**
`CLAUDE.md` and `wins`/`wint` must sit next to each other, either order, nothing between them but
markdown — which answers the question co-occurrence cannot: *which page is being declared the winner*.
Direction is the entire defect. *"this page wins"* over `CLAUDE.md` is `LAW-THIRD-RANK-ORDER` stated
**correctly** and a term list scores it identically to the inversion. Measured on the same corpus:
**3 raw / 2 reported / 2 true / 100%**, one hit suppressed for sitting inside a `"…"` quotation (a page
narrating a rule it retired). Against this page's own bar — the accepted dead-link check at 17/17, the
declined stale-path check at 124/0 — it lands on the accepted side, where the recorded shape landed
below the declined one.

**And it found one more standing defect than this entry's census knew about.** The census above counts
the suppressed sections as 4: 1 contradiction, 3 correct deferrals. The contradiction is
`smartwatchbanden`'s `CLAUDE.md` preamble — but the same inversion is stated a second time, from the
other side, in that repo's own `dkj-policy/CONTRIBUTING.md`, and no candidate measured here
ever counted it. Two standing instances, one repo.

**One inheritance was asked for and turns out to be a guard rather than a repair, which is worth saying
plainly.** #1415 required the publishing-repo skip on the ground that this repo's pages *"discuss
supremacy declarations at length, so without it the source reads as consumer drift"*. Measured: this
repo's own always-on pages produce **zero** hits without the skip, because every supremacy sentence here
names the plugin's page as the winner and adjacency reads that correctly. The skip is kept — this is
where sentences about a consumer's rank order get written, and one future line would fire — but it is
sibling consistency and cheap insurance, not the repair it is for the retired-name grep. Since #1421 the
two share **one** skip, so that difference is stated once, in `check-consumer-prose.ps1`, instead of
being inherited by a copy that would not know it had changed meaning.

**The manifest survives the decline** — a later revisit should not have to re-derive 11 laws from
scratch:

| Id | Canonical statement | Source | Seam |
|---|---|---|---|
| `LAW-RELEASE-ORDER` | Block 1 (cutting) always runs first; Block 2 (going live) only follows it, where a live stage exists. | `cut-release/SKILL.md` — "Order matters" | `Get-LiveStage` |
| `LAW-NO-TRUNK-DEVDOC` | The branch's development document exists only for the branch's lifetime; the trunk carries no copy. | `DEVELOPMENT-portable.md` | none |
| `LAW-BRANCH-DOC-PER-BRANCH` | One development document per branch, named after it — not a single shared `development.md`. | `CONTRIBUTING-portable.md` — "2. Branch" | none |
| `LAW-SIGNIFICANCE-NOT-FROM-PREFIX` | Never infer significance/tier from the branch prefix — the prefix predicts nothing about impact. | `CONTRIBUTING-portable.md` — "Significance" | none |
| `LAW-TIER0-NOT-NA` | Tier 0 can never be N/A; its floor is a score of 1. | `CONTRIBUTING-portable.md` — "Significance" | none |
| `LAW-NOTREQUIRED-CHECK-DOES-NOT-BLOCK` | A failing not-required check never blocks the merge; `ship-pr` merges past it and relays its reason. | `CONTRIBUTING-portable.md` — "5. Merge" | none |
| `LAW-SHIP-IN-BACKGROUND` | Run the merge step in the background — the required check waits regardless. | `CONTRIBUTING-portable.md` — "5. Merge" | none |
| `LAW-PR-TITLE-COMPOSED` | No PR title is passed by hand — it is composed as `<branch type>: <Branch title>`. | `CONTRIBUTING-portable.md` — "4. Open the PR" | none |
| `LAW-CLAIM-ISSUE-BEFORE-WORK` | Claim an issue before working it, and read the claim as well as write it. | `CONTRIBUTING-portable.md` — "1. New issue or task" | none |
| `LAW-DOCCOMMIT-BEFORE-PUSH` | `open-pr` commits the development document alone, never `git add -A`, before anything is pushed. | `CONTRIBUTING-portable.md` — "4. Open the PR" | none |
| `LAW-THIRD-RANK-ORDER` | The plugin's portable pages/skills outrank `dkj-policy/CONTRIBUTING.md`, which outranks the floor. | `CONTRIBUTING-portable.md` — "A third rank sits above both" | none |

**Any future attempt still needs the source-repo guard plus the exclusion of plugin-shipped payload
(`Source -eq 'external'`)**, or this repo's own pages and the shared persona read as consumer drift,
exactly as they did before the correction above. Do not revive this behind a rule that reads nearby text
for the source and calls that deference — that is the exact test this entry measures as structurally
blind to the one real contradiction it has to catch.

#### Check 32, and the extraction that came with it (September 6, 2026, [#1491](https://github.com/DaveKJohn/claude-code-specialists/issues/1491))

**The check is the ordinary shape** — a hand-maintained list beside a registry that can be asked, gated
by an opt-in sentinel. What is worth recording here is the two decisions that were *not* obvious, and one
defect the branch produced and caught.

**The scope is the marked document's own FOLDER, not its plugin**, which is where it parts company with
check 29. `skills:plugin` resolves a plugin and holds the span to that plugin's whole `skills/` tree;
`shared-scripts:mirror` narrows `Get-SharedScriptPairs` to the mirrors landing at or below the directory
the marked document sits in, and relativizes against it. That is not a refinement of the same idea but a
different question, and it is what makes the rows comparable **as written**: the page's own table says
`task/new-branch.ps1`, because that is where the reader stands. A plugin-scoped implementation passes
every scenario in the suite except 48, which is why 48 exists.

**The claim is the row's first cell**, and this is the third distinct claim rule in three span checks —
check 10 reads every backtick, check 29 reads link targets, this one reads the first backticked token of
each table row. That is not drift: the subject picks the rule. This table's second column is running prose
carrying `-Worker`, `Get-LintScript` and `Invoke-GitPark`, and its third links a `SKILL.md` rather than the
script, so under either sibling's rule the correct page reports phantom rows. Check 10's answer to that is
an author condition — *wrap tightly* — which this table cannot meet without being rewritten to satisfy a
checker, and check 29's own comment already refuses that trade for the same reason.

**AND THE EXTRACTION, which is the part to read before touching any of the three.** Checks 10 and 29 were
the same forty-five-line walk written twice — fence masking, the forward scan, the unpaired-BEGIN error,
the orphan-END sweep, the nested-BEGIN sweep — and they had **diverged**. The nested-BEGIN case was silent
in check 10 from the day it was written, was found only while walking into it on check 29's branch, and had
to be repaired in both places on August 26, 2026. A third hand-written copy would have been the third place
to repair and the one most likely to be missed, so the walk became `Invoke-MarkedSpanWalk` and all three
checks now call it. The suites are what made that safe to do: 108 asserts across checks 4/10/28/29/30
passed unchanged before a line of check 32 was written.

**The defect the branch produced, because it is the exact failure this gate exists to prevent.** Splicing
the rewritten check 29 into the file through a shell heredoc silently ate the doubled backslashes in two
regex literals: `'\\skills\\[^\\]+\\SKILL\.md$'` landed as `'\skills\[^\]+\SKILL\.md$'`, which matches
nothing. Both the canonical set and the claim set then came back **empty**, the comparison of empty to
empty produced no findings, and the whole gate reported **0 errors** — green, with check 29 asserting
nothing at all. Nothing in the findings could have shown this. What showed it was the **coverage line**
(`Write-Coverage`, issue #221): `with 0 claim(s)` against a baseline of `17`, which is precisely the
argument for why a verdict never travels without the count behind it. Three consequences, all acted on:
the suite's scenario 42 asserts the derived canonical set is **non-empty** before any comparison is
trusted; check 32's coverage line prints **both** sides — rows read *and* mirrors registered — because a
claim count alone cannot tell `0` against `0` from `45` against `45`, and both of those report *no
findings*; and a code splice into a `.ps1` is written with the editor tools rather than through a shell
heredoc — the mangling class is the one already documented in the manual's PowerShell traps, arriving by
a different route.

**The middle one came out of the code review rather than out of the failure**, which is worth noting: the
defect was in check 29, and the reviewer's question was whether the *new* check could fail the same way on
a real run, where the suite's guard does not reach. It could — silence needs only both sets empty — and
the answer was not a runtime assertion but the missing figure, which is the same answer #221 gave.

In short: the **how** (managing the harness, scripts, config, safety guards) is portable; the **what**
(the plugin lint + drift lint, `branch-info.ps1`, `.claude/settings.json` with the github source, and
the marketplace/plugin manifests) belongs to this repo.
