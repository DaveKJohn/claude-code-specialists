## feat/1491-shared-scripts-table-drift

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

#### The prerequisite, resolved before this branch was cut

`plugins/dkj-policy/scripts/README.md` was 21 rows short of its registry on the trunk (#1486), so a check
built against it would have been born red rather than green. PR #1490 carried that repair and was merged
and folded before this branch was created; the table was then measured at 45 canonical / 45 claimed /
0 missing / 0 extra, which is the state that makes gating it possible at all.

### CREATE

- [x] `Invoke-MarkedSpanWalk` in `check-plugin-integrity.ps1`: the opt-in span walk extracted once, and
      checks 10 and 29 converted onto it -- they were the same 45-line walk written twice and had already
      diverged (the nested-BEGIN case, repaired in both on August 26, 2026), so a third copy was refused.
- [x] Check 32 (`[shared-script-list]`): the `shared-scripts:mirror` span, held against the
      `Get-SharedScriptPairs` mirrors landing in the marked document's own folder. Reports both
      directions, with a `Write-Coverage` line.
- [x] The markers placed around the table in `plugins/dkj-policy/scripts/README.md`, and the paragraph
      above it that said nothing guarded against a fourth drift rewritten to say what now does.
- [x] The third marker documented in the root `README.md`, beside `skills:all` and `skills:plugin`.
- [x] The two decisions and the silent-green defect recorded in
      [Sylvester's lens](../.claude/specialists/lenses/05-15-extension.md).

### TEST

- [x] Eight scenarios (42-49) added to `check-plugin-integrity-links.tests.ps1`, beside checks 10's and
      29's: the complete table, a missing row, an outlived row, the first-cell claim rule, header and
      prose passed over, a fenced example row, the folder-versus-plugin scope, and a span under no
      plugin. Suite: 108 asserts before, 130 after, all passing.
- [x] Code review (Victor): no correctness findings; the `$script:` counter convention, the
      `return`-for-`continue` swap and the raw pre-test's superset argument were each verified
      empirically rather than read. Two things acted on -- a scenario range labelled 42-48 for eight
      scenarios, and the coverage gap in the next line.
- [x] Check 32's coverage line prints the REGISTRY side beside the claim side, so a real run cannot
      report a `0`-against-`0` pass in the same words as a `45`-against-`45` one. Raised in review as
      the one way the new check could still fail the way check 29 just had, where the suite's guard
      does not reach.
- [x] The gate run whole against this repo, and every coverage figure compared against the pre-change
      baseline rather than merely read. That comparison is what caught the one real defect on this
      branch: a splice had eaten the doubled backslashes in two of check 29's regex literals, so its
      canonical set and its claim set were both empty, the comparison of empty to empty produced no
      findings, and the gate reported 0 errors with check 29 asserting nothing. `[skill-list-plugin]`
      read `0 claim(s)` against a baseline of `17`; repaired, re-run, and back to 17.

### DEPLOY: feat/1491-shared-scripts-table-drift

`plugins/dkj-policy/scripts/README.md`'s table is now held against `Get-SharedScriptPairs` by check 32
(`[shared-script-list]`) in `check-plugin-integrity.ps1`, so the drift that hit it three times -- three
rows in August 2026, then the header and the destination split, then 21 rows in #1486 -- fails the gate on
the PR that causes it instead of being found months later. The check reads an opt-in
`shared-scripts:mirror` span, takes each row's first cell as its claim, scopes to the mirrors
landing in the marked document's own folder, and reports both a registered script with no row and a row
the registry no longer mirrors. It is not check 8: that one proves each mirror's *content* matches its
source, and nothing before this asked whether the page naming them was complete. Opt-in for the measured
reason its two siblings are -- the root `scripts/README.md` is a deliberate subset of the same registry,
so a blanket rule would be born needing an allow-list. The same movement extracted the span walk checks 10
and 29 had been carrying as two copies into one `Invoke-MarkedSpanWalk`, since a third copy of a walk that
had already drifted once was the wrong thing to paste.

**Score:** 3

#### What makes this deploy extra special

Nothing to run and nothing to change: the gate runs where this plugin is maintained, not where it is
installed. What a consumer gets is the page itself -- `dkj-policy/scripts/README.md`, the one place that
says which shared scripts the mirror carries -- with a guarantee behind it that it lists all of them,
where until now it was three times measurably short.

**Score:** 2

#### Pull Request

A lint check holds plugins/dkj-policy/scripts/README.md against Get-SharedScriptPairs

