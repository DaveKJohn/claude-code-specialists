<#
.SYNOPSIS
    check-plugin-integrity.ps1, part 1 of 4: check 4 (the dead-link scan set), check 10 (the
    marked <!-- skills:all --> spans), check 28 (the '@'-import targets), check 29 (the
    plugin-scoped <!-- skills:plugin --> spans), check 30 (a plugin-shipped relative link must
    resolve inside its own plugin) and check 32 (the <!-- shared-scripts:mirror --> tables), plus
    scenario 16 -- a root entry file is scanned before the fold.

.DESCRIPTION
    The fixture, the assert helpers and Invoke-Integrity live in check-plugin-integrity-fixture.ps1,
    which also records why this suite is four files. The scenario documentation that used to open the
    single file is kept where each scenario is, rather than as one index four files would have to
    share.

    Check 4 guards file-set COVERAGE rather than the scan engine: if the $linkFiles list is refactored
    and drops CONTRIBUTING.md, the connectors README or one of the four payload layers, that must fail
    loudly here. Check 10's sixteen scenarios cover the span mechanics, the fence masking in both
    directions, and the two symmetric sweeps -- the orphan END, and (since August 26, 2026, scenario
    14b) the nested BEGIN that used to pair across an open span in silence.

    Check 29 is check 10's plugin-scoped sibling, and its eleven scenarios sit beside check 10's for the
    same reason check 28's sit beside check 4's: same scan set, same marker mechanics, one deliberate
    difference each. The two that matter are asserted head-on -- the SCOPE (27, which manufactures a
    third skill in a second plugin so the two canonical sets genuinely differ) and the LINK-versus-
    BACKTICK reading (28). Without the manufactured skill the fixture's two sets coincide and the scope
    assertion is vacuous, which is the failure mode this suite exists to prevent.

    Check 30 is check 4's OTHER sibling, and the one whose scenarios are easiest to write vacuously:
    it reads the same links and asks a different question of them -- not "does this resolve here" but
    "does it still resolve once the file has travelled to a consumer's plugin cache". Every link in its
    six scenarios resolves in the fixture on purpose, so check 4 stays silent and any finding is 30's
    own; scenario 36 asserts that silence head-on. Scenario 37 is the one that earns the suite -- a link
    into a SIBLING plugin, which satisfies the boundary inbound #1066 proposed ('stay under plugins/')
    while still being dead for a consumer, because the cache gives every plugin its own versioned
    directory and a sibling is not a neighbour.

    Check 32 is the THIRD opt-in span in this file, and since #1491 all three run one walk --
    Invoke-MarkedSpanWalk. Its eight scenarios therefore do not restage the marker mechanics checks 10
    and 29 already prove; they cover what is its own, and two of them exist because an implementation
    that got them wrong would pass everything else here: 45 (the claim is the row's FIRST CELL, not
    every backtick and not a link) and 48 (the scope is the marked document's OWN FOLDER, not its
    plugin). Its expected set is DERIVED from Get-SharedScriptPairs rather than typed, so a newly
    shared script does not turn this suite red for having found nothing -- and 42 asserts that derived
    set is non-empty, because comparing empty to empty is exactly how check 29 came out green for the
    wrong reason while #1491 was being built.

    Check 28 is check 4's sibling -- the same scan set, a different syntax -- and its scenarios pin the
    resolution rule (file-relative, NOT repo-root-relative) separately from both discriminators (a fenced
    '@(...)' and a prose line), because each can fail invisibly in the others' direction. One assert
    compares its coverage count against check 4's, so the two sets cannot silently drift apart.

    Test gap (honest, inherited from the single file): the anchor-slug logic and the full scan engine
    are not re-exercised here -- they are covered by the repo-wide lint smoke checks in
    agent-shared.tests.ps1 and bootstrap-drift.tests.ps1.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'check-plugin-integrity-fixture.ps1')

$Fixture = Join-Path ([System.IO.Path]::GetTempPath()) ("check-plugin-integrity-links-$PID")

try {
    New-IntegrityFixture -Fixture $Fixture

    # --- Scenario A: dead links in the two target files + a decoy outside the scan set --------------
    Write-Host "check 4 coverage -- CONTRIBUTING.md + connectors README are IN the scan set" -ForegroundColor Cyan
    $contributingBroken = "# Contributing`n`nSee [nope]($deadLink) for details.`n"
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), $contributingBroken, $Utf8NoBom)
    $connectorsBroken = "# Connectors`n`nSee [nope]($deadLink) for details.`n"
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'connectors\README.md'), $connectorsBroken, $Utf8NoBom)
    # Decoy: same dead link, but in a file that check 4 does NOT scan -- proves the two hits below
    # are due to CONTRIBUTING.md / the connectors README specifically being in the file list, not
    # some accidental blanket scan of every .md file in the fixture.
    #
    # IT MOVED OUT OF THE ROOT IN #405, AND THAT IS THE POINT IT NOW PROVES. This decoy used to sit at
    # 'NOTES.md' in the fixture root, back when the root docs were a NAMED list and the *.md glob covered
    # the separate family directory that held QUICKSTART.md, UNINSTALL.md and the family README. Flattening
    # moved those three documents INTO the root, so the root became the directory where consumer-facing
    # pages live and inherited the glob (see scenario 33, which requires exactly that). A root decoy would
    # now be testing that the glob does not work.
    #
    # So the decoy moved one directory down instead of being deleted: the property under test -- the scan
    # is scope-limited rather than a blanket walk of every .md in the tree -- is unchanged and still worth
    # asserting. Only the boundary moved, from "which root files are named" to "the root, and not below it".
    $decoyBroken = "# Decoy`n`nSee [nope]($deadLink) for details.`n"
    New-Item -ItemType Directory -Path (Join-Path $Fixture 'notes') -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'notes\NOTES.md'), $decoyBroken, $Utf8NoBom)

    $a = Invoke-Integrity -FixtureRoot $Fixture
    Assert-Equal 1 $a.Code 'scenario A: exit 1 (findings present)'
    Assert-True ($a.Out -match [regex]::Escape('.\CONTRIBUTING.md') -and $a.Out -match '\[link\]') 'CONTRIBUTING.md dead link is reported'
    Assert-True ($a.Out -match [regex]::Escape('.\connectors\README.md')) 'connectors README dead link is reported'
    Assert-True (-not ($a.Out -match [regex]::Escape('NOTES.md'))) 'decoy notes\NOTES.md (outside the scan set) is NOT reported -- proves the scan is scope-limited, not a blanket walk'

    # --- Scenario B: fix both dead links -- the two specific findings disappear ----------------------
    Write-Host "check 4 coverage -- fixing the dead links removes exactly those findings" -ForegroundColor Cyan
    $contributingFixed = "# Contributing`n`nNothing to link to here.`n"
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), $contributingFixed, $Utf8NoBom)
    $connectorsFixed = "# Connectors`n`nNothing to link to here.`n"
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'connectors\README.md'), $connectorsFixed, $Utf8NoBom)

    $b = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($b.Out -match [regex]::Escape('.\CONTRIBUTING.md') + '.*dead link')) 'CONTRIBUTING.md dead-link finding is gone once fixed'
    Assert-True (-not ($b.Out -match [regex]::Escape('.\connectors\README.md') + '.*dead link')) 'connectors README dead-link finding is gone once fixed'

    # --- Scenario B2: the four payload layers added in #481 are IN the scan set ---------------------
    # Agent defs, agent-shared, .github and .claude/rules matched no category until August 6, 2026 --
    # 40 files, the largest of them the agent defs, which are the biggest body of prose this repo ships.
    # A real dead link had been sitting in one of them, seen by nothing. Each layer gets its own broken
    # link here rather than one shared assertion, because they are four separate rules and a single
    # combined check would pass while three of them were absent.
    Write-Host "check 4 coverage -- the payload layers (#481) are IN the scan set" -ForegroundColor Cyan
    $payloadTargets = @(
        @{ Rel = 'plugins\dkj-teams\dkj-team-alpha\agents\09-99-agent.md';   Label = 'an agent def' },
        @{ Rel = 'plugins\dkj-teams\agent-shared\fixture-block.md';  Label = 'a shared agent-def block' },
        @{ Rel = '.github\pull_request_template.md';             Label = 'a .github template' },
        @{ Rel = '.claude\rules\fixture-rule.md';                Label = 'a path-scoped rule' }
    )
    foreach ($pt in $payloadTargets) {
        $ptFull = Join-Path $Fixture $pt.Rel
        New-Item -ItemType Directory -Path (Split-Path -Parent $ptFull) -Force | Out-Null
        [System.IO.File]::WriteAllText($ptFull, "# Fixture`n`nSee [nope]($deadLink) for details.`n", $Utf8NoBom)
    }
    $b2 = Invoke-Integrity -FixtureRoot $Fixture
    foreach ($pt in $payloadTargets) {
        Assert-True ($b2.Out -match [regex]::Escape('.\' + $pt.Rel)) `
            ("payload scan: a dead link in $($pt.Label) is reported -- " + $pt.Rel)
    }
    Assert-True (-not ($b2.Out -match [regex]::Escape('NOTES.md'))) `
        'payload scan: the out-of-scope decoy is STILL not reported -- the four new rules are scoped, not a blanket walk'

    # And removing them again clears exactly those findings, so the assertions above are bound to the
    # files rather than to some other error the fixture happens to produce.
    foreach ($pt in $payloadTargets) { Remove-Item -LiteralPath (Join-Path $Fixture $pt.Rel) -Force }
    $b3 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($b3.Out -match [regex]::Escape('09-99-agent.md'))) `
        'payload scan: removing the agent def clears its finding -- the report tracked the file, not the fixture'

    # --- Scenario B4: the entry's links resolve WHERE THE FOLD WRITES, not where the file sits --------
    # The branch document's DEPLOY section is pasted verbatim into the changelog, so its links have to work
    # THERE. Until the branch/ split the file sat beside the changelog in the root and that held by
    # construction; moving it one level down turned every link in an entry into a dead one, measured on the
    # first entry written after the move.
    #
    # THE BASE IS THE CHANGELOG'S DIRECTORY AND NOT THE REPO ROOT (issue #1041, August 28, 2026). Those were
    # the same value until CHANGELOG.md moved into contributing-davekjohn/ on August 27, and this scenario
    # asserted the root by name -- so it passed while the check demanded a form the fold then broke.
    #
    # BOTH NAMES ARE EXERCISED, because they land on opposite sides of the repair:
    #   * TODAY'S name sits IN the changelog's directory, so the correct link is the one that reads
    #     correctly in front of the author. This is the case the issue measured and the only one an author
    #     meets today.
    #   * A LEGACY name sits one level BELOW it, so the base still differs from where the file sits -- which
    #     is why the special case survives the repair rather than being dropped. A branch open since before
    #     the August 23 merge still carries one.
    # And the root form is asserted DEAD on the legacy file, which is the direction pin: a repair that
    # simply left $RepoRoot in place, or one that dropped the case altogether, fails one of the three.
    Write-Host "check 4 coverage -- an entry's links are judged where the text LANDS" -ForegroundColor Cyan
    $entryDirFx = Join-Path $Fixture 'dkj-policy\branch'
    New-Item -ItemType Directory -Path $entryDirFx -Force | Out-Null
    $entryFx    = Join-Path $entryDirFx 'branch-deployment.md'
    $progressFx = Join-Path $entryDirFx 'branch-cycle.md'
    $devFx      = Join-Path $Fixture 'dkj-policy\development.md'
    # 'connectors/README.md' exists in this fixture. From dkj-policy/ -- where this fixture's
    # CHANGELOG.md resolves to -- it is reached with one '../', and the bare root form is dead there.
    [System.IO.File]::WriteAllText($entryFx,
        "## Fixture entry`n`nSee [the connectors README](../connectors/README.md), [the root form](connectors/README.md) and [nope]($deadLink).`n", $Utf8NoBom)
    # Today's single document: the changelog sits in ITS directory, so the link reads exactly as written.
    [System.IO.File]::WriteAllText($devFx,
        "## Development: ``feat/fixture```n`n### DEPLOY: ``feat/fixture```n`nSee [the connectors README](../connectors/README.md).`n", $Utf8NoBom)
    # The step list never travels, so it keeps the ordinary nested convention: '../../' to reach the root.
    [System.IO.File]::WriteAllText($progressFx,
        "# Branch progress`n`n**Branch:** ``feat/fixture```n`n## Steps`n`n- [ ] see [the connectors README](../../connectors/README.md)`n", $Utf8NoBom)

    $b4 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($b4.Out -match 'dead link ''\.\./connectors/README\.md''')) `
        'entry links: the link that reads correctly beside the changelog is NOT dead -- that is where the fold puts the text'
    Assert-True (-not ($b4.Out -match [regex]::Escape('.\dkj-policy\development.md'))) `
        "entry links: today's document is judged from its own directory, because the changelog sits there too"
    Assert-True ($b4.Out -match 'dead link ''connectors/README\.md''') `
        'entry links: the ROOT form IS dead on the legacy name -- the base is the changelog, not the repo root'
    Assert-True ($b4.Out -match [regex]::Escape('.\dkj-policy\branch\branch-deployment.md') -and $b4.Out -match [regex]::Escape($deadLink)) `
        'entry links: a genuinely dead link in the entry IS still reported -- the rebase is not a way out of the check'
    Assert-True (-not ($b4.Out -match [regex]::Escape('.\dkj-policy\branch\branch-cycle.md'))) `
        'entry links: the step list keeps the ordinary nested convention -- it never travels, so ../../ is correct there'

    Remove-Item -LiteralPath $entryFx, $progressFx, $devFx -Force

    # --- Scenario B5: plugins/ is read WHOLE, and a file gathered twice is reported once -------------
    # Inbound #566. Every rule in the scan set names either a SHAPE of file (SKILL.md, *-manual.md,
    # */agents/*.md) or a PLACE it takes entirely (the root, branch/, releases/). A markdown file sitting at
    # plugin level matched neither, which is exactly where a plugin's own README.md lives -- the first page a
    # consumer reads. Five such files were in the tree, unread, when a sixth was added: a portable
    # contribution guide whose whole purpose is to be copied, and whose dead links would be copied with it.
    #
    # Both halves are asserted because each one alone is satisfiable by a wrong fix. Widening the glob
    # without deduping double-reports every file two rules now claim; deduping without widening leaves the
    # gap. And the decoy is asserted a third time: plugins/ being read whole must not become "every .md in
    # the tree", which is the property scenarios A and B2 already defend at their own boundaries.
    Write-Host "check 4 coverage -- a plugin-level document is IN the scan set, and counted once" -ForegroundColor Cyan
    $pluginDocTargets = @(
        @{ Rel = 'plugins\dkj-teams\dkj-team-alpha\README.md';         Label = "a plugin's own README (plugin level, no shape rule matches it)" },
        @{ Rel = 'plugins\dkj-teams\dkj-team-alpha\scripts\README.md'; Label = 'a README in a plugin subdirectory that no shape rule reaches' }
    )
    # The dedupe witness: an agent def is gathered by the */agents/*.md payload rule AND by the recursive
    # plugins/ glob. One dead link in it must produce exactly one [link] finding. Counted on LINES carrying
    # both the path and the [link] tag, because check 3 also names this file (no frontmatter) and a naive
    # match on the path alone would count that too.
    $dupWitnessRel = 'plugins\dkj-teams\dkj-team-alpha\agents\09-98-agent.md'
    foreach ($pd in @($pluginDocTargets.Rel + $dupWitnessRel)) {
        $pdFull = Join-Path $Fixture $pd
        New-Item -ItemType Directory -Path (Split-Path -Parent $pdFull) -Force | Out-Null
        [System.IO.File]::WriteAllText($pdFull, "# Fixture`n`nSee [nope]($deadLink) for details.`n", $Utf8NoBom)
    }
    $b5 = Invoke-Integrity -FixtureRoot $Fixture
    foreach ($pd in $pluginDocTargets) {
        Assert-True ($b5.Out -match [regex]::Escape('.\' + $pd.Rel)) `
            ("plugin-doc scan: a dead link in $($pd.Label) is reported -- " + $pd.Rel)
    }
    $dupHits = @(($b5.Out -split "`r?`n") | Where-Object { $_ -match [regex]::Escape($dupWitnessRel) -and $_ -match '\[link\]' })
    Assert-Equal 1 $dupHits.Count `
        'plugin-doc scan: a file gathered by two rules yields ONE dead-link finding -- the scan set is deduped, so widening a rule never double-reports'
    Assert-True (-not ($b5.Out -match [regex]::Escape('NOTES.md'))) `
        'plugin-doc scan: the out-of-scope decoy is STILL not reported -- plugins/ is read whole, the tree is not'

    # Removing them clears exactly those findings, so the assertions above are bound to these files rather
    # than to other noise this near-empty fixture produces.
    foreach ($pd in @($pluginDocTargets.Rel + $dupWitnessRel)) { Remove-Item -LiteralPath (Join-Path $Fixture $pd) -Force }
    Remove-Item -LiteralPath (Join-Path $Fixture 'plugins\dkj-teams\dkj-team-alpha\scripts') -Recurse -Force
    $b6 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($b6.Out -match [regex]::Escape('.\plugins\dkj-teams\dkj-team-alpha\README.md'))) `
        "plugin-doc scan: removing the plugin README clears its finding -- the report tracked the file, not the fixture"

    # === check 10: marked "all skills" enumerations vs. the canonical skillset ==========================
    # From here on, only CONTRIBUTING.md's content is varied per scenario. The connectors README is
    # left exactly as fixed by Scenario B above (marker-free), so it never contributes a
    # <!-- skills:all --> span of its own -- keeping every assertion below attributable to
    # CONTRIBUTING.md alone.
    #
    # NOTE: the "[skill-list]" tag prefixes BOTH the error lines and the informational
    # "checked N span(s) against M canonical skill(s)" pass-line -- so "no finding" assertions must
    # match on an actual error phrase, not on the bare "[skill-list]" tag (which is always present
    # once at least one span exists).
    $SkillListFindingPattern = '\[skill-list\].*(is missing:|not a known skill:|has no matching)'

    # --- Scenario 1: a complete marked span passes. The canonical-skill count printed in the info
    # line doubles as proof that the depth-decoy SKILL.md is NOT counted as a 3rd canonical skill --
    Write-Host "check 10 -- a complete <!-- skills:all --> span passes" -ForegroundColor Cyan
    $s1Lines = @(
        '# Contributing'
        ''
        '<!-- skills:all -->'
        '- `skill-alpha`'
        '- `skill-beta`'
        '<!-- /skills:all -->'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s1Lines -join "`n") + "`n"), $Utf8NoBom)

    $r1 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($r1.Out -match $SkillListFindingPattern)) 'scenario 1: a complete span reports no [skill-list] finding'
    Assert-True ($r1.Out -match [regex]::Escape('checked 1 <!-- skills:all --> span(s) against 2 canonical skill(s)')) 'scenario 1: canonical set is exactly 2 -- the depth-decoy SKILL.md was not counted as a 3rd'

    # --- Scenario 2: a span missing a canonical skill name fails, naming it --------------------------
    Write-Host "check 10 -- a span missing a canonical skill name fails" -ForegroundColor Cyan
    $s2Lines = @(
        '# Contributing'
        ''
        '<!-- skills:all -->'
        '- `skill-alpha`'
        '<!-- /skills:all -->'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s2Lines -join "`n") + "`n"), $Utf8NoBom)

    $r2 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r2.Out -match '\[skill-list\].*is missing: skill-beta') 'scenario 2: the missing skill-beta is named in the finding'

    # --- Scenario 3: a span naming something that is not a skill fails -------------------------------
    Write-Host "check 10 -- a span naming a non-skill fails" -ForegroundColor Cyan
    $s3Lines = @(
        '# Contributing'
        ''
        '<!-- skills:all -->'
        '- `skill-alpha`'
        '- `skill-beta`'
        '- `not-a-real-skill`'
        '<!-- /skills:all -->'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s3Lines -join "`n") + "`n"), $Utf8NoBom)

    $r3 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r3.Out -match '\[skill-list\].*not a known skill: not-a-real-skill') 'scenario 3: the unknown name not-a-real-skill is named in the finding'

    # --- Scenario 4: an unpaired BEGIN marker (no matching END) is a hard error ----------------------
    Write-Host "check 10 -- an unpaired BEGIN marker fails" -ForegroundColor Cyan
    $s4Lines = @(
        '# Contributing'
        ''
        '<!-- skills:all -->'
        '- `skill-alpha`'
        '- `skill-beta`'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s4Lines -join "`n") + "`n"), $Utf8NoBom)

    $r4 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r4.Out -match [regex]::Escape("has no matching '<!-- /skills:all -->'")) 'scenario 4: the unpaired BEGIN marker is reported'

    # --- Scenario 5: TWO unpaired BEGIN markers in the SAME file -- BOTH must be reported. Regression
    # guard: an earlier version used 'break' on the first unpaired marker and silently abandoned the
    # rest of the file, so a second, later problem in the same doc went unnoticed. The fix continues
    # scanning past a malformed marker instead of bailing out of the whole file.
    Write-Host "check 10 -- two unpaired BEGIN markers in one file are BOTH reported" -ForegroundColor Cyan
    $s5Lines = @(
        '# Contributing'
        ''
        '<!-- skills:all -->'
        '- `skill-alpha`'
        ''
        'Some unrelated paragraph in between.'
        ''
        '<!-- skills:all -->'
        '- `skill-beta`'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s5Lines -join "`n") + "`n"), $Utf8NoBom)

    $r5 = Invoke-Integrity -FixtureRoot $Fixture
    $unpairedHits = [regex]::Matches($r5.Out, [regex]::Escape("has no matching '<!-- /skills:all -->'"))
    Assert-Equal 2 $unpairedHits.Count 'scenario 5: both unpaired BEGIN markers are reported, not just the first (no break-and-abandon regression)'

    # --- Scenario 6: an UNMARKED, deliberately incomplete enumeration must NOT fail. This is the
    # whole reason check 10 is opt-in rather than a generic prose scan: a real doc (e.g.
    # QUICKSTART.md) legitimately lists only SOME skills as illustration, without ever claiming to be
    # exhaustive, and must not be flagged just because it happens to under-enumerate.
    Write-Host "check 10 -- an unmarked, deliberately incomplete list is NOT flagged" -ForegroundColor Cyan
    $s6Lines = @(
        '# Contributing'
        ''
        'Here is one skill, for illustration only (this list is not exhaustive):'
        '- `skill-alpha`'
        ''
        "That's not all of them."
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s6Lines -join "`n") + "`n"), $Utf8NoBom)

    $r6 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($r6.Out -match $SkillListFindingPattern)) 'scenario 6: an unmarked, incomplete list reports no [skill-list] finding'
    Assert-True ($r6.Out -match [regex]::Escape('0 <!-- skills:all --> span(s) found')) 'scenario 6: zero spans found across the fixture -- opt-in, so this is a pass'

    # --- Scenario 7: an INLINE span in running prose -- backtick terms OUTSIDE the span that are not
    # skill names must not be flagged. Mirrors the real family-README sentence (the three
    # *-sessioncheck hook names sit one line above the skill enumeration, outside its span).
    Write-Host "check 10 -- an inline span in prose ignores backtick terms outside it" -ForegroundColor Cyan
    $s7Lines = @(
        '# Contributing'
        ''
        'Session hooks `connector-sessioncheck`, `roster-sessioncheck`, and `script-contract-sessioncheck` run at session start.'
        'Only the skills (<!-- skills:all -->`skill-alpha`, `skill-beta`<!-- /skills:all -->) remain available there.'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s7Lines -join "`n") + "`n"), $Utf8NoBom)

    $r7 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($r7.Out -match $SkillListFindingPattern)) 'scenario 7: hook names outside the inline span are not treated as claimed skill names'

    # --- Scenario 8: the depth-decoy SKILL.md (skills/<name>/references/SKILL.md) is not part of the
    # canonical skillset -- naming it inside a span is reported as an unknown name, proving it was
    # never picked up as a real skill in the first place (the flip side of scenario 1's count check).
    Write-Host "check 10 -- a SKILL.md nested one level too deep is not a canonical skill" -ForegroundColor Cyan
    $s8Lines = @(
        '# Contributing'
        ''
        '<!-- skills:all -->'
        '- `skill-alpha`'
        '- `skill-beta`'
        '- `skill-deep-decoy`'
        '<!-- /skills:all -->'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s8Lines -join "`n") + "`n"), $Utf8NoBom)

    $r8 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r8.Out -match '\[skill-list\].*not a known skill: skill-deep-decoy') 'scenario 8: the depth decoy skill-deep-decoy is reported as unknown -- it was never in the canonical set'

    # --- Scenario 9: a complete marker EXAMPLE inside a fenced ```-code block -- reports nothing, AND
    # does not count in the span total. Asserting the count (not just "no error") is the point: it is
    # the proof the example is genuinely invisible to the scan, not "seen, checked, and happened to
    # pass" -- see Get-FenceMaskedText in the real script (added because a literal marker example in
    # a doc, e.g. Tessa's convention writeup, would otherwise itself be read as a live span).
    Write-Host "check 10 -- a fenced marker EXAMPLE is invisible to the scan (not counted)" -ForegroundColor Cyan
    $s9Lines = @(
        '# Contributing'
        ''
        'Here is how you show the marker literally:'
        ''
        '```'
        '<!-- skills:all -->'
        '- `skill-alpha`'
        '- `skill-beta`'
        '<!-- /skills:all -->'
        '```'
        ''
        'End of example.'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s9Lines -join "`n") + "`n"), $Utf8NoBom)

    $r9 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($r9.Out -match $SkillListFindingPattern)) 'scenario 9: a fenced marker example reports no [skill-list] finding'
    Assert-True ($r9.Out -match [regex]::Escape('0 <!-- skills:all --> span(s) found')) 'scenario 9: the fenced example is not counted as a span at all -- proves it is invisible, not merely passing'

    # --- Scenario 10: a fence containing ONLY the BEGIN marker, with no '<!-- /skills:all -->'
    # ANYWHERE ELSE in the file either -- must NOT raise "has no matching END". This is exactly the
    # case that gave a hard error before the fence-masking fix (the reason for the change): a fenced
    # BEGIN-only example used to be indistinguishable from a genuinely malformed live marker.
    Write-Host "check 10 -- a fenced BEGIN-only example (no END anywhere) is NOT an unpaired-marker error" -ForegroundColor Cyan
    $s10Lines = @(
        '# Contributing'
        ''
        'Example of just the opening marker:'
        ''
        '```'
        '<!-- skills:all -->'
        '```'
        ''
        '(no matching end anywhere in this file)'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s10Lines -join "`n") + "`n"), $Utf8NoBom)

    $r10 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($r10.Out -match $SkillListFindingPattern)) 'scenario 10: a fenced BEGIN-only example reports no "has no matching END" error'
    Assert-True ($r10.Out -match [regex]::Escape('0 <!-- skills:all --> span(s) found')) 'scenario 10: the masked BEGIN inside the fence never becomes a span (not even an unpaired one)'

    # --- Scenario 11: a REAL span OUTSIDE a fence, in the SAME file as a fenced example -- still
    # checked normally, and its reported LINE NUMBER matches the actual line. The line number is the
    # crux of the masking approach (same length + same newline positions as the original) -- if
    # someone ever swaps the mask for a cut/splice, this assert is designed to break.
    Write-Host "check 10 -- a real span outside a fence is still checked, with the correct line number" -ForegroundColor Cyan
    $s11Lines = @(
        '# Contributing'                             # line 1
        ''                                             # line 2
        'Example of the marker (not a live span):'    # line 3
        ''                                             # line 4
        '```'                                          # line 5
        '<!-- skills:all -->'                          # line 6
        '- `something`'                                # line 7
        '<!-- /skills:all -->'                          # line 8
        '```'                                          # line 9
        ''                                             # line 10
        'Real usage below:'                            # line 11
        ''                                             # line 12
        '<!-- skills:all -->'                          # line 13
        '- `skill-alpha`'                              # line 14
        '<!-- /skills:all -->'                          # line 15
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s11Lines -join "`n") + "`n"), $Utf8NoBom)

    $r11 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r11.Out -match [regex]::Escape('span at line 13 is missing: skill-beta')) 'scenario 11: the real span outside the fence is checked, and reports the correct line (13)'
    Assert-True (-not ($r11.Out -match 'not a known skill: something')) 'scenario 11: the fenced examples "something" never surfaces as an unknown-skill finding -- it is masked, not scanned'
    Assert-True ($r11.Out -match [regex]::Escape('checked 1 <!-- skills:all --> span(s) against 2 canonical skill(s)')) 'scenario 11: only the real span is counted -- the fenced example contributes 0'

    # --- Scenario 12 (deliberate-boundary lock, not a bug guard): a marker written as INLINE code
    # (single backticks, not a fence) is NOT masked and IS still scanned as a live span. Sylvester's
    # documented trade-off: a real span's own claimed skill names are themselves single-backtick
    # delimited, so there is no character-level way to tell "this pair of backticks is an inline-code
    # escape" from "this pair of backticks is a claimed skill name" -- masking inline code would erase
    # genuine findings along with any escaped example. Fixing this assert to expect silence later
    # would mean someone changed that boundary without discussing it first.
    Write-Host "check 10 -- a marker in INLINE code (not a fence) is still scanned as live (deliberate boundary)" -ForegroundColor Cyan
    $s12Lines = @(
        '# Contributing'                                                # line 1
        ''                                                                # line 2
        'Inline example (not fenced): `<!-- skills:all -->`'             # line 3
        '- `skill-alpha`'                                                  # line 4
        '`<!-- /skills:all -->`'                                           # line 5
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s12Lines -join "`n") + "`n"), $Utf8NoBom)

    $r12 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r12.Out -match [regex]::Escape('span at line 3 is missing: skill-beta')) 'scenario 12: a marker inside single-backtick inline code is still read as a live span (deliberately not masked)'

    # --- Scenario 13: a LONE orphan END, with no BEGIN anywhere in the file -- a hard error, with the
    # correct line number. Victor's finding: the original check-10 only guarded BEGIN-without-END; an
    # orphan or duplicate END vanished silently. This is the symmetric counterpart of scenario 4.
    Write-Host "check 10 -- a lone orphan END (no BEGIN anywhere) fails" -ForegroundColor Cyan
    $s13Lines = @(
        '# Contributing'                              # line 1
        ''                                              # line 2
        '<!-- /skills:all -->'                          # line 3
        ''                                              # line 4
        'No begin marker anywhere in this file.'        # line 5
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s13Lines -join "`n") + "`n"), $Utf8NoBom)

    $r13 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r13.Out -match [regex]::Escape("'<!-- /skills:all -->' at line 3 has no matching '<!-- skills:all -->'")) 'scenario 13: the lone orphan END is reported, with the correct line number'

    # --- Scenario 14 (the important one): a SECOND END pasted inside an already-open, otherwise real
    # span -- exactly the copy-paste mistake that used to go silently, dangerously GREEN: the span
    # closed early at the first END, the rest of the enumeration became unchecked prose, the surplus
    # END vanished, and the check reported "checked 1 span" after only checking half of it. Two
    # things must both be true now: the truncated span reports its now-missing name (proof it closed
    # early), AND the surplus END is reported separately, on its own line.
    Write-Host "check 10 -- a second END pasted inside a real span is caught, not silently swallowed" -ForegroundColor Cyan
    $s14Lines = @(
        '# Contributing'                              # line 1
        ''                                              # line 2
        '<!-- skills:all -->'                          # line 3
        '- `skill-alpha`'                                # line 4
        '<!-- /skills:all -->'                          # line 5
        '<!-- /skills:all -->'                          # line 6 -- copy-paste duplicate
        '- `skill-beta`'                                 # line 7 -- now just prose, outside the span
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s14Lines -join "`n") + "`n"), $Utf8NoBom)

    $r14 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r14.Out -match [regex]::Escape('span at line 3 is missing: skill-beta')) 'scenario 14: the span closed early at the first END -- skill-beta (now outside it) is reported missing'
    Assert-True ($r14.Out -match [regex]::Escape("'<!-- /skills:all -->' at line 6 has no matching '<!-- skills:all -->'")) 'scenario 14: the surplus second END is reported separately, on its own line'

    # --- Scenario 14b: the MIRROR of 14 -- a second BEGIN pasted INSIDE an already-open span. Silent
    # here from the day this check shipped, and for the same structural reason 14 describes facing the
    # other way: the walk jumps from a span's opener straight past its END, so a BEGIN in between is
    # never visited and the span simply pairs across it. Found on August 26, 2026 by walking into it on
    # check 29's branch, where the marker was written in prose above a real span and the run came out
    # GREEN -- the prose BEGIN had paired with the real END, swallowing the real BEGIN and checking the
    # whole table as one span. A pass for the wrong reason is worse than a finding, so both halves are
    # asserted: the nested BEGIN is reported, AND the enumeration it swallowed is still checked (one
    # span, not two, and no spurious missing name).
    Write-Host "check 10 -- a second BEGIN pasted inside a real span is caught, not silently swallowed" -ForegroundColor Cyan
    $s14bLines = @(
        '# Contributing'                                # line 1
        ''                                              # line 2
        '<!-- skills:all -->'                           # line 3
        '- `skill-alpha`'                               # line 4
        '<!-- skills:all -->'                           # line 5 -- nested, opens nothing
        '- `skill-beta`'                                # line 6
        '<!-- /skills:all -->'                          # line 7
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s14bLines -join "`n") + "`n"), $Utf8NoBom)

    $r14b = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r14b.Out -match [regex]::Escape("'<!-- skills:all -->' at line 5 sits INSIDE an already-open span")) 'scenario 14b: the nested second BEGIN is reported, with the correct line number'
    Assert-True (-not ($r14b.Out -match '\[skill-list\].*is missing:')) 'scenario 14b: and the swallowed enumeration was still checked as one span -- no spurious missing name. Anchored on the tag, not on the bare phrase: [shared-script] says "source is missing:" too, and an unanchored assert fails on it'
    Assert-True ($r14b.Out -match [regex]::Escape('checked 1 <!-- skills:all --> span(s)')) 'scenario 14b: exactly one span, not two -- the nested BEGIN opened nothing'

    # --- Scenario 15: an END inside a code fence -- no error. Proves the masking is symmetric: a
    # fenced END is exactly as invisible to the sweep as a fenced BEGIN was in scenario 9/10.
    Write-Host "check 10 -- an END inside a code fence is invisible too (symmetric masking)" -ForegroundColor Cyan
    $s15Lines = @(
        '# Contributing'
        ''
        '```'
        '<!-- /skills:all -->'
        '```'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s15Lines -join "`n") + "`n"), $Utf8NoBom)

    $r15 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($r15.Out -match $SkillListFindingPattern)) 'scenario 15: a fenced END reports no [skill-list] finding'
    Assert-True ($r15.Out -match [regex]::Escape('0 <!-- skills:all --> span(s) found')) 'scenario 15: the masked END never becomes an orphan finding -- it is invisible, same as a masked BEGIN'

    # --- Scenario 16: root changelog ENTRY files are IN the scan set (#234) --------------------------
    # The window this closes: an entry file's text sits outside every scanned path while the PR is
    # open, and only lands in a scanned file at FOLD time -- which happens directly on main, past every
    # PR gate. v2.13.0 was blocked by exactly that: a marker quoted in changelog prose became an
    # unpaired BEGIN in CHANGELOG.md, discovered only when cut-release ran the full gate on main.
    # Both halves are asserted here: the dead link (check 4) AND the quoted marker (check 10, the
    # original case), because they share this file set and the window covered both.
    Write-Host "check 4 + 10 -- a root changelog entry file is scanned BEFORE the fold" -ForegroundColor Cyan
    $midDot = [char]0x00B7
    $entryPath = Join-Path $Fixture 'fix-my-branch.md'
    $s16Lines = @(
        "### My change $midDot Fix $midDot 2026-07-29"
        ''
        "See [nope]($deadLink) for details."
        'The gate caught the skill missing from a `<!-- skills:all -->` span.'
    )
    [System.IO.File]::WriteAllText($entryPath, (($s16Lines -join "`n") + "`n"), $Utf8NoBom)

    $r16 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-Equal 1 $r16.Code 'scenario 16: exit 1 -- an entry file is scanned, so its findings surface while the PR is open'
    Assert-True ($r16.Out -match [regex]::Escape('.\fix-my-branch.md') -and $r16.Out -match '\[link\]') 'scenario 16: a dead link in an entry body is reported BEFORE the fold, not after'
    Assert-True ($r16.Out -match [regex]::Escape("'<!-- skills:all -->' at line 4 has no matching")) 'scenario 16: the original #234 case -- a marker quoted in entry prose is caught on the PR instead of on main'
    # The entry-format rule still has to hold, and since #405 it is CHECK 13 that carries it rather than
    # the dead-link scan. Every root *.md is link-scanned now, so "is this an entry file?" no longer
    # decides whether a root document is READ -- it decides whether it is judged as a changelog entry
    # (heading levels) and whether checks 11 and 12 skip it as history in the making. A permanent root
    # doc must never be counted as one: the fixture root holds CONTRIBUTING.md and CHANGELOG.md beside
    # the single entry file, so the count is the discriminator, and it would catch the entry rule
    # degrading into "any root .md" just as the old NOTES.md assertion did.
    Assert-True ($r16.Out -match '\[entry-heading\].*1 unfolded entry\(ies\)') 'scenario 16: exactly ONE root file is read as an entry -- a permanent root doc is scanned but never judged as one'

    # And once the fold has taken it away, it simply drops out of the set again -- no stale reference,
    # no error about a file that no longer exists.
    Remove-Item -LiteralPath $entryPath -Force
    $r17 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($r17.Out -match [regex]::Escape('fix-my-branch.md'))) 'scenario 16: after the fold removes it, the entry file is gone from the set without complaint'

    # --- check 28: every '@'-import target resolves ----------------------------------------------------
    # 18-24. THE SIBLING OF CHECK 4, AND IT BELONGS IN THIS FILE FOR THAT REASON: it reads the same
    #        $linkFiles set and answers the same question about a different syntax. Issue #874.
    #
    #        What separates them is the COST OF BEING WRONG. A dead markdown link costs a reader one
    #        click; a dead '@'-import costs the session the WHOLE document, and nothing errors -- Claude
    #        Code drops an import it cannot resolve in silence, so the only symptom is a session behaving
    #        as if it had never read the layer that vanished. In this repo that layer is the safety rules
    #        or the roster.
    #
    #        The scenarios below pin the resolution rule and BOTH discriminators, because each of the
    #        three can fail on its own and each failure is invisible in the other two's direction: a
    #        check that resolved root-relative would pass every positive test in a root document and be
    #        wrong everywhere else, and a check without the discriminators would be born accusing correct
    #        files -- which is the shape this repo refuses on principle (see check 27's exemption note).
    Write-Host "check 28: '@'-import targets resolve" -ForegroundColor Cyan
    $impDir     = Join-Path $Fixture 'plugins\dkj-teams\dkj-team-alpha'
    $impProbe   = Join-Path $impDir 'import-probe.md'
    $impSibling = Join-Path $impDir 'import-sibling.md'
    [System.IO.File]::WriteAllText($impSibling, "# The sibling`n`nA target that exists.`n", $Utf8NoBom)

    # 18. A RESOLVING IMPORT IS SILENT, and the coverage line still reports a non-empty scan. Without the
    #     second half a check that examined nothing at all would pass this scenario.
    [System.IO.File]::WriteAllText($impProbe, "# The probe`n`n@import-sibling.md`n", $Utf8NoBom)
    $im1 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($im1.Out -match '\[import\].*import-probe')) `
        'import: a resolving import is not a finding'
    Assert-True ($im1.Out -match '\[import\] checked [1-9]') `
        'import: and the pass is not an empty scan'

    # 19. THE RESOLUTION RULE ITSELF, which is the one thing a second implementation would get wrong:
    #     an import resolves relative to the IMPORTING FILE's own directory, not to the repo root. The
    #     fixture root holds a CONTRIBUTING.md; this probe sits three levels down and must NOT find it.
    #     A root-relative reader passes scenario 18 and fails only here.
    [System.IO.File]::WriteAllText($impProbe, "# The probe`n`n@CONTRIBUTING.md`n", $Utf8NoBom)
    $im2 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($im2.Out -match '\[import\].*import-probe\.md:3') `
        'import: a target that exists at the REPO ROOT but not beside the importing file is dead -- the rule is file-relative'
    Assert-True ($im2.Code -ne 0) `
        'import: and it fails the gate -- a dropped import costs the session the whole document'
    Assert-True ($im2.Out -match 'importing file') `
        'import: and the finding states the base it resolved from, so the repair needs no source reading'

    # 20. A HOME-RELATIVE IMPORT IS COUNTED, NEVER REFUSED. SPECIALISTS.md imports the orchestrator's
    #     persona from the plugin marketplace clone under '~/', and CI is a machine with no clone. An
    #     error there would fail every PR for a correct file, so this assert is what keeps CI usable.
    [System.IO.File]::WriteAllText($impProbe,
        "# The probe`n`n@~/.claude/plugins/marketplaces/nothing-here/absent.md`n", $Utf8NoBom)
    $im3 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($im3.Out -match '\[import\].*import-probe')) `
        'import: a target outside the repo is not a finding -- CI has no marketplace clone'
    Assert-True ($im3.Out -match '1 outside the repo') `
        'import: but it is counted and named, so "no findings" does not mean "nothing was seen"'

    # 21. A FENCED '@(...)' IS POWERSHELL, NOT AN IMPORT. Seven of the twelve column-0 '@' lines in the
    #     real tree are exactly this, and check 4 already argues the case for links: illustrating a thing
    #     is not doing it.
    # Built from single-quoted parts and joined, so the fence delimiters are literal backticks rather
    # than an escape sequence three levels deep -- the readable form, and the one a later editor cannot
    # miscount.
    [System.IO.File]::WriteAllText($impProbe,
        ((@('# The probe', '', '```powershell', '@(Get-ChildItem .).Count', '```', '')) -join "`n"), $Utf8NoBom)
    $im4 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($im4.Out -match '\[import\].*import-probe')) `
        'import: a fenced PowerShell array expression is not an import'

    # 22. PROSE THAT WRAPS ONTO AN '@' IS NOT AN IMPORT EITHER, and this is the discriminator that keeps
    #     the check from being born with an exemption list. One line in the real tree needs it --
    #     releases/development/1.x/1.16.0.md, a paragraph that wraps onto '@-imported here (...)' -- and
    #     it sits in an archived note the language rule already exempts from repair. A target containing
    #     WHITESPACE is prose; the lib's parser takes the rest of the line, which is right for the
    #     always-on walk (it never meets prose) and wrong for a set that includes release history.
    [System.IO.File]::WriteAllText($impProbe,
        "# The probe`n`nA sentence that wraps onto`n@-imported here (which is prose, not a path).`n", $Utf8NoBom)
    $im5 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($im5.Out -match '\[import\].*import-probe')) `
        'import: a line beginning with @ whose target contains whitespace is prose, not an import'
    Assert-True ($im5.Out -match 'read as prose') `
        'import: and the coverage line says how many were read that way, so the discriminator is visible rather than silent'

    # 23. THE SET IS CHECK 4'S SET, asserted on the count rather than on a name. If $linkFiles is ever
    #     refactored and this check is left reading something narrower, the two numbers diverge and this
    #     fails -- which is the same coverage guard the rest of this file exists for.
    Assert-True ($im5.Out -match '\[import\] checked (\d+)') 'import: the coverage line reports a count'
    $impCount  = [int]([regex]::Match($im5.Out, '\[import\] checked (\d+)').Groups[1].Value)
    $linkCount = [int]([regex]::Match($im5.Out, '\[link-scan\] checked (\d+)').Groups[1].Value)
    Assert-True ($impCount -eq $linkCount) `
        'import: the scan set IS check 4 set -- a narrower one here would go unnoticed without this'

    # 24. And the fixture is clean again once the probe is gone, so nothing above leaks into a later run.
    Remove-Item -LiteralPath $impProbe -Force
    Remove-Item -LiteralPath $impSibling -Force
    Assert-True (-not ((Invoke-Integrity -FixtureRoot $Fixture).Out -match '\[import\] \.')) `
        'import: the fixture is clean again once the probes are gone'

    # === check 29: a plugin's OWN skill enumeration, scoped and read from its links =====================
    # 25-35. WHY THESE SIT BESIDE CHECK 10'S RATHER THAN IN A SUITE OF THEIR OWN: the two checks share the
    #        scan set, the fence masking and the whole marker mechanic, and they differ in exactly two
    #        respects (#920). Both differences are asserted head-on -- the SCOPE in 27 and the
    #        LINK-versus-BACKTICK reading in 28 -- because each is satisfiable by an implementation that
    #        gets the other wrong. A plugin-scoped check that quietly used the marketplace-wide canonical
    #        set passes every other scenario here, which is precisely why 27 manufactures a third skill in
    #        a SECOND plugin: without it the fixture's two sets coincide and the scope assertion is
    #        vacuous.
    #
    #        The document under test is the plugin's own README rather than CONTRIBUTING.md, and that is
    #        not incidental: this marker resolves its plugin from the FILE'S OWN PATH, so a root document
    #        cannot carry a valid one at all -- which is scenario 31.
    $PluginSkillFindingPattern = '\[skill-list-plugin\].*(links to none for:|ship no SKILL\.md there:|has no matching|sits INSIDE|belongs to no published plugin)'
    $pluginReadme = Join-Path $Fixture 'plugins\dkj-teams\dkj-team-alpha\README.md'

    # --- Scenario 25: a complete plugin-scoped span passes, and the coverage line proves it read the
    # links rather than merely finding the markers ---------------------------------------------------
    Write-Host "check 29 -- a complete <!-- skills:plugin --> span passes" -ForegroundColor Cyan
    $p25Lines = @(
        '# dkj-team-alpha'
        ''
        '<!-- skills:plugin -->'
        ''
        '| skill | when |'
        '|---|---|'
        '| [`skill-alpha`](skills/skill-alpha/SKILL.md) | the first one |'
        '| [`skill-beta`](skills/skill-beta/SKILL.md) | the second one |'
        ''
        '<!-- /skills:plugin -->'
    )
    [System.IO.File]::WriteAllText($pluginReadme, (($p25Lines -join "`n") + "`n"), $Utf8NoBom)

    $q25 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($q25.Out -match $PluginSkillFindingPattern)) 'scenario 25: a complete plugin-scoped span reports no [skill-list-plugin] finding'
    Assert-True ($q25.Out -match [regex]::Escape('[skill-list-plugin] checked 1')) 'scenario 25: exactly one span was counted'
    Assert-True ($q25.Out -match [regex]::Escape('with 2 claim(s) read from LINK TARGETS')) 'scenario 25: both rows were read as claims -- the coverage line proves the links were parsed, not just the markers found'

    # --- Scenario 26: a span that omits one of the plugin's skills fails, naming it ------------------
    Write-Host "check 29 -- a span omitting one of the plugin's skills fails" -ForegroundColor Cyan
    $p26Lines = @(
        '# dkj-team-alpha'
        ''
        '<!-- skills:plugin -->'
        '| [`skill-alpha`](skills/skill-alpha/SKILL.md) | the only row |'
        '<!-- /skills:plugin -->'
    )
    [System.IO.File]::WriteAllText($pluginReadme, (($p26Lines -join "`n") + "`n"), $Utf8NoBom)

    $q26 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($q26.Out -match [regex]::Escape("links to none for: skill-beta")) 'scenario 26: the omitted skill is named -- this is the drift the check exists to stop'
    Assert-Equal 1 $q26.Code 'scenario 26: and it fails the gate'

    # --- Scenario 27 (the SCOPE difference, and the reason this check exists at all): the canonical set
    # is THIS plugin's, not the marketplace's. A third skill is manufactured in a SECOND plugin, so the
    # two sets differ -- 3 marketplace-wide against 2 for dkj-team-alpha -- and both are asserted in the same
    # run: check 10's span sees 3, check 29's span passes with 2. Under the marketplace-wide set this
    # span would report skill-gamma missing, which is exactly what #920 measured and why a second marker
    # was needed rather than a wider check 10 ----------------------------------------------------------
    Write-Host "check 29 -- the canonical set is the DOCUMENT'S OWN plugin, not the marketplace" -ForegroundColor Cyan
    $gammaDir = Join-Path $Fixture 'plugins\dkj-teams\dkj-team-shopify\skills\skill-gamma'
    New-Item -ItemType Directory -Path $gammaDir -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $gammaDir 'SKILL.md'), "---`nname: skill-gamma`n---`n`n# Gamma`n", $Utf8NoBom)
    [System.IO.File]::WriteAllText($pluginReadme, (($p25Lines -join "`n") + "`n"), $Utf8NoBom)
    $s27Lines = @(
        '# Contributing'
        ''
        '<!-- skills:all -->'
        '- `skill-alpha`'
        '- `skill-beta`'
        '- `skill-gamma`'
        '<!-- /skills:all -->'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s27Lines -join "`n") + "`n"), $Utf8NoBom)

    $q27 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($q27.Out -match [regex]::Escape('against 3 canonical skill(s)')) 'scenario 27: the marketplace-wide set really is 3 -- so the two sets genuinely differ in this run'
    Assert-True (-not ($q27.Out -match $PluginSkillFindingPattern)) 'scenario 27: and the plugin-scoped span still passes with 2 -- skill-gamma belongs to another plugin and is not its business'
    Assert-True ($q27.Out -match [regex]::Escape('with 2 claim(s) read from LINK TARGETS')) 'scenario 27: two claims, not three -- the scope is the document own plugin'

    Remove-Item -LiteralPath (Split-Path -Parent $gammaDir) -Recurse -Force
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), "# Contributing`n`nNo markers here.`n", $Utf8NoBom)

    # --- Scenario 28 (the OTHER difference): a claim is a LINK TARGET, never a backtick. This is the
    # constraint that made check 10 unusable for a two-column table -- three rows of the real one carry a
    # backticked path or flag in their second column, and under check 10's rule each of those is a claimed
    # skill name. Here they are prose. A backticked name that is NOT a link is asserted too, in the same
    # span, because "ignores backticks" and "reads links" can each be implemented without the other -----
    Write-Host "check 29 -- prose and backticked paths in a row are not claims; the link is" -ForegroundColor Cyan
    $p28Lines = @(
        '# dkj-team-alpha'
        ''
        '<!-- skills:plugin -->'
        '| skill | when |'
        '|---|---|'
        '| [`skill-alpha`](skills/skill-alpha/SKILL.md) | scaffolds `dkj-policy/`, and takes `--force` |'
        '| [`skill-beta`](skills/skill-beta/SKILL.md) | stays out of the built-in `/continue` way |'
        '| `not-a-skill` | a backticked token with no link at all -- prose, not a claim |'
        '<!-- /skills:plugin -->'
    )
    [System.IO.File]::WriteAllText($pluginReadme, (($p28Lines -join "`n") + "`n"), $Utf8NoBom)

    $q28 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($q28.Out -match $PluginSkillFindingPattern)) 'scenario 28: backticked paths, flags and a bare backticked token inside the span cost nothing -- no author condition is needed'
    Assert-True ($q28.Out -match [regex]::Escape('with 2 claim(s) read from LINK TARGETS')) 'scenario 28: still exactly 2 claims -- the three extra backtick runs were not read as names'

    # --- Scenario 29: a link into this plugin's skills/ for a name that ships no SKILL.md ------------
    # The mirror of 26, and the case a renamed skill folder produces. Check 4 reports the dead link too;
    # this asserts the [skill-list-plugin] half, which is the one that says WHY it matters.
    Write-Host "check 29 -- a link to a skill this plugin does not ship is reported" -ForegroundColor Cyan
    $p29Lines = @(
        '# dkj-team-alpha'
        ''
        '<!-- skills:plugin -->'
        '| [`skill-alpha`](skills/skill-alpha/SKILL.md) | real |'
        '| [`skill-beta`](skills/skill-beta/SKILL.md) | real |'
        '| [`skill-ghost`](skills/skill-ghost/SKILL.md) | renamed away, or never there |'
        '<!-- /skills:plugin -->'
    )
    [System.IO.File]::WriteAllText($pluginReadme, (($p29Lines -join "`n") + "`n"), $Utf8NoBom)

    $q29 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($q29.Out -match [regex]::Escape('ship no SKILL.md there: skill-ghost')) 'scenario 29: the phantom row is named'
    Assert-Equal 1 $q29.Code 'scenario 29: and it fails the gate'

    # --- Scenario 30: the DEPTH DECOY, on the claim side this time. Check 10 binds its canonical walk to
    # exactly one segment between skills/ and SKILL.md; the same binding has to hold for a LINK, or a
    # level-3 progressive-disclosure page would be read as a claimed skill and reported as an extra ----
    Write-Host "check 29 -- a link to a level-3 SKILL.md is not a claim" -ForegroundColor Cyan
    $p30Lines = @(
        '# dkj-team-alpha'
        ''
        '<!-- skills:plugin -->'
        '| [`skill-alpha`](skills/skill-alpha/SKILL.md) | real |'
        '| [`skill-beta`](skills/skill-beta/SKILL.md) | real |'
        '| deeper reading | [the reference page](skills/skill-alpha/references/SKILL.md) |'
        '<!-- /skills:plugin -->'
    )
    [System.IO.File]::WriteAllText($pluginReadme, (($p30Lines -join "`n") + "`n"), $Utf8NoBom)

    $q30 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($q30.Out -match $PluginSkillFindingPattern)) 'scenario 30: the level-3 page is not read as a claimed skill, so it is not an extra'
    Assert-True ($q30.Out -match [regex]::Escape('with 2 claim(s) read from LINK TARGETS')) 'scenario 30: and it did not inflate the claim count either'

    # --- Scenario 31: a span in a document that belongs to NO plugin is a hard error, not a silent skip.
    # The marker means "this plugin", and a root document has none -- so there is nothing to adjudicate
    # against, and the honest answer is to say so rather than to pass. The message points at check 10,
    # which is the marker the author almost certainly wanted ------------------------------------------
    Write-Host "check 29 -- a span outside any plugin is refused, and points at the right marker" -ForegroundColor Cyan
    [System.IO.File]::WriteAllText($pluginReadme, "# dkj-team-alpha`n`nNo markers here.`n", $Utf8NoBom)
    $s31Lines = @(
        '# Contributing'
        ''
        '<!-- skills:plugin -->'
        '- [`skill-alpha`](plugins/dkj-teams/dkj-team-alpha/skills/skill-alpha/SKILL.md)'
        '<!-- /skills:plugin -->'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s31Lines -join "`n") + "`n"), $Utf8NoBom)

    $q31 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($q31.Out -match [regex]::Escape('belongs to no published plugin')) 'scenario 31: a span in a root document is refused rather than silently skipped'
    Assert-True ($q31.Out -match [regex]::Escape('<!-- skills:all --> (check 10) instead')) 'scenario 31: and the finding names the marker that WOULD serve there'
    Assert-Equal 1 $q31.Code 'scenario 31: and it fails the gate'
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), "# Contributing`n`nNo markers here.`n", $Utf8NoBom)

    # --- Scenario 32: an unpaired BEGIN, reported with its line number -------------------------------
    Write-Host "check 29 -- an unpaired BEGIN is reported" -ForegroundColor Cyan
    $p32Lines = @(
        '# dkj-team-alpha'                                    # line 1
        ''                                                # line 2
        '<!-- skills:plugin -->'                          # line 3
        '| [`skill-alpha`](skills/skill-alpha/SKILL.md) | no closer follows |'
    )
    [System.IO.File]::WriteAllText($pluginReadme, (($p32Lines -join "`n") + "`n"), $Utf8NoBom)

    $q32 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($q32.Out -match [regex]::Escape("'<!-- skills:plugin -->' at line 3 has no matching '<!-- /skills:plugin -->'")) 'scenario 32: the unpaired BEGIN is reported, with the correct line number'
    Assert-Equal 1 $q32.Code 'scenario 32: a typo-ed sentinel must never read as "no span here"'

    # --- Scenario 33: a lone orphan END, the symmetric half ------------------------------------------
    Write-Host "check 29 -- a lone orphan END is reported" -ForegroundColor Cyan
    $p33Lines = @(
        '# dkj-team-alpha'                                    # line 1
        ''                                                # line 2
        '<!-- /skills:plugin -->'                         # line 3
    )
    [System.IO.File]::WriteAllText($pluginReadme, (($p33Lines -join "`n") + "`n"), $Utf8NoBom)

    $q33 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($q33.Out -match [regex]::Escape("'<!-- /skills:plugin -->' at line 3 has no matching '<!-- skills:plugin -->'")) 'scenario 33: the orphan END is reported, with the correct line number'

    # --- Scenario 34: a SECOND BEGIN inside an already-open span -- the mirror of check 10's scenario
    # 14b, shipped with it. This is the case that made the repair necessary: on this check's own branch
    # the marker was written in prose above the real span, the two paired across the whole table, and the
    # run came out GREEN with the real BEGIN swallowed. Both halves asserted, as in 14b -----------------
    Write-Host "check 29 -- a second BEGIN inside a real span is caught, not silently swallowed" -ForegroundColor Cyan
    $p34Lines = @(
        '# dkj-team-alpha'                                    # line 1
        ''                                                # line 2
        '<!-- skills:plugin -->'                          # line 3
        '| [`skill-alpha`](skills/skill-alpha/SKILL.md) | real |'
        '<!-- skills:plugin -->'                          # line 5 -- nested, opens nothing
        '| [`skill-beta`](skills/skill-beta/SKILL.md) | real |'
        '<!-- /skills:plugin -->'                         # line 7
    )
    [System.IO.File]::WriteAllText($pluginReadme, (($p34Lines -join "`n") + "`n"), $Utf8NoBom)

    $q34 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($q34.Out -match [regex]::Escape("'<!-- skills:plugin -->' at line 5 sits INSIDE an already-open span")) 'scenario 34: the nested second BEGIN is reported, with the correct line number'
    Assert-True (-not ($q34.Out -match [regex]::Escape('links to none for:'))) 'scenario 34: and the swallowed rows were still checked as one span -- no spurious missing name'
    Assert-True ($q34.Out -match [regex]::Escape('[skill-list-plugin] checked 1')) 'scenario 34: exactly one span, not two'

    # --- Scenario 35: a fenced example of the marker is invisible, and the fixture is clean again -----
    # The convention this check inherits from check 10: a fence is the supported way to SHOW the bare
    # marker text. Asserted on the span COUNT rather than on the absence of a finding, because zero
    # findings is also what a check that stopped reading the file would produce.
    Write-Host "check 29 -- a fenced example is not a live marker, and the fixture ends clean" -ForegroundColor Cyan
    $p35Lines = @(
        '# dkj-team-alpha'
        ''
        'Wrap the table like this:'
        ''
        '```'
        '<!-- skills:plugin -->'
        '<!-- /skills:plugin -->'
        '```'
    )
    [System.IO.File]::WriteAllText($pluginReadme, (($p35Lines -join "`n") + "`n"), $Utf8NoBom)

    $q35 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($q35.Out -match $PluginSkillFindingPattern)) 'scenario 35: a fenced example produces no finding'
    Assert-True ($q35.Out -match [regex]::Escape('[skill-list-plugin] checked 0')) 'scenario 35: the fenced markers never become a span at all -- invisible, not merely passing'

    Remove-Item -LiteralPath $pluginReadme -Force
    $q35b = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($q35b.Out -match '\[skill-list-plugin\] \.')) 'scenario 35: the fixture is clean again once the plugin README is gone'


    # --- Check 30: a plugin-shipped relative link must resolve inside its OWN plugin ---------------
    #
    # WHAT THESE SIX SCENARIOS ARE FOR. Check 4 answers "does this link resolve in THIS tree"; check 30
    # answers "does it still resolve once the file has travelled". The two are independent, and the
    # fixture makes that visible: every link written below resolves perfectly where it sits, so check 4
    # stays silent throughout and any finding here is check 30's alone.
    #
    # SCENARIO 37 IS THE ONE THAT EARNS THE SUITE. Inbound #1066 proposed the boundary as 'plugins/',
    # and a link into a SIBLING plugin satisfies that while still being dead for a consumer -- the
    # cache gives each plugin its own versioned directory, so a sibling is not a neighbour. Without 37
    # a wrong-but-plausible rule passes every other scenario here.
    $PluginLinkFindingPattern = '\[plugin-link\] \.'
    $plNotes = Join-Path $Fixture 'plugins\dkj-teams\dkj-team-alpha\NOTES.md'
    # Real targets, so each scenario tests CONTAINMENT and not existence. A dead target would make the
    # finding appear for the wrong reason and the scenario would keep passing after the rule was broken.
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'README.md'), "# Fixture root`n", $Utf8NoBom)
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'plugins\dkj-teams\dkj-team-shopify\GUIDE.md'), "# Shopify guide`n", $Utf8NoBom)

    Write-Host "check 30 -- a link out of the plugin root is a finding, at the right line" -ForegroundColor Cyan
    $p36Lines = @(
        '# dkj-team-alpha notes'
        ''
        'Line three is prose.'
        ''
        'See [the root readme](../../../README.md) for the rest.'
    )
    [System.IO.File]::WriteAllText($plNotes, (($p36Lines -join "`n") + "`n"), $Utf8NoBom)
    $q36 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($q36.Out -match $PluginLinkFindingPattern) 'scenario 36: a link leaving the plugin root is reported'
    Assert-True ($q36.Out -match 'NOTES\.md:5 ') 'scenario 36: the finding names the line the link is on, not the file'
    Assert-True ($q36.Out -match "leaves the 'dkj-team-alpha' plugin root") 'scenario 36: the finding names the plugin the file belongs to'
    # The link resolves in this tree, so check 4 has nothing to say about it. Asserted head-on: if this
    # ever fails, the two checks have started overlapping and 30's findings are no longer its own.
    Assert-True (-not ($q36.Out -match 'dead link .\.\./\.\./\.\./README\.md')) 'scenario 36: check 4 stays silent -- the link is live HERE, which is the whole premise'
    # No repo-config in the fixture, so Get-RepoBlobUrl is undefined and the suggestion is dropped. The
    # designed fallback: a repo without the seam gets a plainer finding, never a wrong one or a crash.
    Assert-True (-not ($q36.Out -match 'Write it absolute:')) 'scenario 36: without repo-config the suggestion is omitted and the finding still stands'

    Write-Host "check 30 -- a SIBLING plugin is not a neighbour, though it shares plugins/" -ForegroundColor Cyan
    $p37Lines = @(
        '# dkj-team-alpha notes'
        ''
        'See [the shopify guide](../dkj-team-shopify/GUIDE.md) for the rest.'
    )
    [System.IO.File]::WriteAllText($plNotes, (($p37Lines -join "`n") + "`n"), $Utf8NoBom)
    $q37 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($q37.Out -match $PluginLinkFindingPattern) 'scenario 37: a link into a sibling plugin is reported, though it never leaves plugins/'
    Assert-True ($q37.Out -match "leaves the 'dkj-team-alpha' plugin root") 'scenario 37: the finding is attributed to the plugin the FILE sits in, not the one it points at'

    Write-Host "check 30 -- a link inside the plugin root is not a finding" -ForegroundColor Cyan
    $p38Lines = @(
        '# dkj-team-alpha notes'
        ''
        'See [skill alpha](skills/skill-alpha/SKILL.md) and [beta](./skills/skill-beta/SKILL.md).'
    )
    [System.IO.File]::WriteAllText($plNotes, (($p38Lines -join "`n") + "`n"), $Utf8NoBom)
    $q38 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($q38.Out -match $PluginLinkFindingPattern)) 'scenario 38: links staying inside the plugin root pass, in both the bare and the ./ form'

    Write-Host "check 30 -- code and comments are masked, and the mask keeps line numbers honest" -ForegroundColor Cyan
    # All three exclusions in one file, ABOVE a live escape: masking that shortened the text instead of
    # preserving its length would still suppress these three and then misreport the fourth's line. That is
    # the failure this scenario is shaped to catch -- a passing absence assert would hide it.
    $p39Lines = @(
        '# dkj-team-alpha notes'
        ''
        '```'
        'See [fenced](../../../README.md) -- illustration, not a link.'
        '```'
        ''
        'Inline `[code](../../../README.md)` is illustration too.'
        ''
        '<!-- [commented](../../../README.md) -->'
        ''
        'But [this one](../../../README.md) is real.'
    )
    [System.IO.File]::WriteAllText($plNotes, (($p39Lines -join "`n") + "`n"), $Utf8NoBom)
    $q39 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-Equal 1 ([regex]::Matches($q39.Out, $PluginLinkFindingPattern).Count) 'scenario 39: exactly one of the four links is live -- fence, inline code and HTML comment are all masked'
    Assert-True ($q39.Out -match 'NOTES\.md:11 ') 'scenario 39: the surviving finding reports line 11, so the mask preserved length and newlines'

    Write-Host "check 30 -- three forms are passed over rather than reported" -ForegroundColor Cyan
    $p40Lines = @(
        '# dkj-team-alpha notes'
        ''
        'An [absolute URL](https://github.com/DaveKJohn/claude-code-specialists/blob/main/README.md) is the repair, not the defect.'
        ''
        'A [plugin-relative path](${CLAUDE_PLUGIN_ROOT}/skills/skill-alpha/SKILL.md) resolves at runtime.'
        ''
        'A [marketplace-clone path](~/.claude/plugins/marketplaces/x/README.md) points there deliberately.'
        ''
        'A [pure anchor](#dkj-team-alpha-notes) never leaves the file.'
    )
    [System.IO.File]::WriteAllText($plNotes, (($p40Lines -join "`n") + "`n"), $Utf8NoBom)
    $q40 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($q40.Out -match $PluginLinkFindingPattern)) 'scenario 40: absolute, ${...}-relative, ~/-relative and pure-anchor targets are all passed over'

    Write-Host "check 30 -- the coverage line counts what was read and what escaped" -ForegroundColor Cyan
    # Coverage is asserted separately from the findings for Write-Coverage's own reason (#221): "0
    # escaping" and "checked nothing at all" are the same verdict read two ways, and only the count
    # tells them apart. So BOTH states are pinned, because the note has a branch for each and the
    # uninformative one is the branch a reader would otherwise be handed by accident.
    #
    # The file left over from scenario 40 carries four links and not one relative path among them, so
    # this is the zero-checked state -- and the assert is that the gate SAYS so rather than reporting a
    # bare zero that reads like a clean sweep.
    $q41 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($q41.Out -match '\[plugin-link\] checked 0 --') 'scenario 41: with only passed-over forms, the coverage count is zero'
    Assert-True ($q41.Out -match 'so none can escape') 'scenario 41: and the note says WHY it is zero, instead of leaving a bare zero to read as a clean sweep'

    # Now the other branch: one link, contained, so something was genuinely resolved and passed.
    $p41Lines = @(
        '# dkj-team-alpha notes'
        ''
        'See [skill alpha](skills/skill-alpha/SKILL.md).'
    )
    [System.IO.File]::WriteAllText($plNotes, (($p41Lines -join "`n") + "`n"), $Utf8NoBom)
    $q41a = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($q41a.Out -match '\[plugin-link\] checked [1-9]') 'scenario 41: a contained relative link is COUNTED, not skipped -- a pass must be a measurement'
    Assert-True ($q41a.Out -match '0 escaping') 'scenario 41: and it reports zero escaping'

    Remove-Item -LiteralPath $plNotes -Force
    Remove-Item -LiteralPath (Join-Path $Fixture 'plugins\dkj-teams\dkj-team-shopify\GUIDE.md') -Force
    $q41b = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($q41b.Out -match $PluginLinkFindingPattern)) 'scenario 41: the fixture is clean again once the notes file is gone'

    # === check 32: a mirror table's rows against the shared-scripts registry ============================
    # 42-49. WHY THESE SIT BESIDE CHECKS 10 AND 29 (issue #1491): the third opt-in span in this file, and
    #        since this branch all three run the SAME walk -- Invoke-MarkedSpanWalk. The marker mechanics
    #        (fence masking, unpaired BEGIN, orphan END, nested BEGIN) are therefore proven once by
    #        check 10's and 29's scenarios and are not restaged here; 47 keeps one masking assert because
    #        it is the one mechanic this check reads DIFFERENTLY -- through table rows rather than through
    #        backticks or links.
    #
    #        THE EXPECTED SET IS DERIVED FROM THE REGISTRY, NOT TYPED. Get-SharedScriptPairs is the thing
    #        under test's own source of truth, so hardcoding two filenames here would turn every future
    #        `git`-shared script into a red suite that has found nothing. The tautology that invites is
    #        answered by 42's second assert: the derived set must be NON-EMPTY, so a registry that
    #        silently returned nothing cannot make every scenario below pass by comparing empty to empty
    #        -- which is exactly how check 29 came out green for the wrong reason while this branch was
    #        being written.
    #
    #        THE DOCUMENT IS plugins/teams/team-alpha/scripts/README.md, and the folder is the point: this
    #        check scopes to the marked document's OWN directory rather than to its plugin. Scenario 48
    #        asserts that head-on by moving the same marker up to the plugin root, where the canonical set
    #        keeps the deeper 'scripts/' prefix -- the assertion that a plugin-scoped implementation
    #        (which would pass every other scenario here) fails.
    $MirrorFindingPattern = '\[shared-script-list\].*(has no row for:|does not mirror here:|has no matching|sits INSIDE|belongs to no published plugin)'
    $mirrorReadme = Join-Path $Fixture 'plugins\teams\team-alpha\scripts\README.md'
    New-Item -ItemType Directory -Path (Split-Path -Parent $mirrorReadme) -Force | Out-Null

    # What the registry says lands in that folder, resolved against the FIXTURE, exactly as the check
    # resolves it. Sorted so the table below is stable run to run.
    . (Join-Path $PSScriptRoot '..\lib\shared-scripts-lib.ps1')
    $mirrorDocDir = (Split-Path -Parent $mirrorReadme).TrimEnd('\') + '\'
    $mirrorExpected = @(
        Get-SharedScriptPairs -RepoRoot $Fixture -PluginRoots @(Get-RepoPluginRoots -RepoRoot $Fixture) |
            Where-Object { $_.MirrorPath.StartsWith($mirrorDocDir, [System.StringComparison]::OrdinalIgnoreCase) } |
            ForEach-Object { $_.MirrorPath.Substring($mirrorDocDir.Length) -replace '\\', '/' } | Sort-Object)

    function New-MirrorTable {
        # Builds the table body the way the real page writes it: a backticked path in the first cell,
        # running prose in the second, a link or the word 'none' in the third.
        param([string[]]$Rows)
        $out = @('| Script | What it is | Skill |', '|---|---|---|')
        foreach ($r in $Rows) { $out += "| ``$r`` | what it does | none -- dot-sourced lib |" }
        return $out
    }

    # --- Scenario 42: a table carrying every registered mirror passes, and the set is not empty --------
    Write-Host "check 32 -- a complete <!-- shared-scripts:mirror --> table passes" -ForegroundColor Cyan
    $p42Lines = @('# scripts', '', '<!-- shared-scripts:mirror -->') + (New-MirrorTable -Rows $mirrorExpected) + @('<!-- /shared-scripts:mirror -->')
    [System.IO.File]::WriteAllText($mirrorReadme, (($p42Lines -join "`n") + "`n"), $Utf8NoBom)

    $q42 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($q42.Out -match $MirrorFindingPattern)) 'scenario 42: a complete mirror table reports no [shared-script-list] finding'
    Assert-True ($mirrorExpected.Count -gt 0) 'scenario 42: the derived canonical set is NON-EMPTY -- without this every scenario below could pass by comparing empty to empty'
    Assert-True ($q42.Out -match [regex]::Escape('[shared-script-list] checked 1')) 'scenario 42: exactly one span was counted'
    Assert-True ($q42.Out -match [regex]::Escape(": $($mirrorExpected.Count) row(s) read from the first cell")) 'scenario 42: every row was read as a claim -- the coverage line proves the cells were parsed, not just the markers found'
    # The CANONICAL side, printed beside the claim side for the reason the check's own comment gives: a
    # claim count alone cannot tell 0-against-0 from 45-against-45, and both report "no findings".
    Assert-True ($q42.Out -match [regex]::Escape("against $($mirrorExpected.Count) registered mirror(s)")) 'scenario 42: and the registry side is reported too, so an empty-against-empty pass cannot read like a real one'

    # --- Scenario 43: THE RECURRENCE THIS CHECK EXISTS FOR. A registered script with no row is named.
    # Three hand passes (August 15, August 26, September 6 2026) repaired exactly this and reset the
    # clock; the finding below is what ends it ----------------------------------------------------------
    Write-Host "check 32 -- a registered mirror with no row is named" -ForegroundColor Cyan
    $mirrorDropped = $mirrorExpected[0]
    $p43Lines = @('# scripts', '', '<!-- shared-scripts:mirror -->') +
        (New-MirrorTable -Rows @($mirrorExpected | Where-Object { $_ -ne $mirrorDropped })) +
        @('<!-- /shared-scripts:mirror -->')
    [System.IO.File]::WriteAllText($mirrorReadme, (($p43Lines -join "`n") + "`n"), $Utf8NoBom)

    $q43 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($q43.Out -match [regex]::Escape("has no row for: $mirrorDropped")) 'scenario 43: the unlisted mirror is named -- this is the drift the check exists to stop'
    Assert-True ($q43.Out -match [regex]::Escape('Get-SharedScriptPairs')) 'scenario 43: and the finding names the registry to consult, so the repair needs no source reading'
    Assert-Equal 1 $q43.Code 'scenario 43: and it fails the gate'

    # --- Scenario 44: the other direction -- a row the registry does not mirror here. This is the half a
    # "count the rows" check could never catch, and the half that fires when a pair is RETIRED ----------
    Write-Host "check 32 -- a row for a script the registry does not mirror is reported" -ForegroundColor Cyan
    $p44Lines = @('# scripts', '', '<!-- shared-scripts:mirror -->') +
        (New-MirrorTable -Rows ($mirrorExpected + 'task/retired-long-ago.ps1')) +
        @('<!-- /shared-scripts:mirror -->')
    [System.IO.File]::WriteAllText($mirrorReadme, (($p44Lines -join "`n") + "`n"), $Utf8NoBom)

    $q44 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($q44.Out -match [regex]::Escape('does not mirror here: task/retired-long-ago.ps1')) 'scenario 44: the outlived row is named'
    Assert-Equal 1 $q44.Code 'scenario 44: and it fails the gate'

    # --- Scenario 45 (THE CLAIM RULE, and the one that separates this check from both siblings): only the
    # FIRST CELL is a claim. The real page's second column carries backticked flags and function names and
    # its third links a SKILL.md -- under check 10's every-backtick rule each would be a phantom row, and
    # under check 29's link rule the skill pages would be. Neither reading can serve this table ----------
    Write-Host "check 32 -- backticks and links elsewhere in a row are not claims; the first cell is" -ForegroundColor Cyan
    $p45Lines = @('# scripts', '', '<!-- shared-scripts:mirror -->', '| Script | What it is | Skill |', '|---|---|---|')
    foreach ($r in $mirrorExpected) {
        $p45Lines += "| ``$r`` | pass ``-Worker`` to ``Invoke-GitPark``, see ``CHANGELOG.md`` | [``park``](../skills/park/SKILL.md) |"
    }
    $p45Lines += '<!-- /shared-scripts:mirror -->'
    [System.IO.File]::WriteAllText($mirrorReadme, (($p45Lines -join "`n") + "`n"), $Utf8NoBom)

    $q45 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($q45.Out -match $MirrorFindingPattern)) 'scenario 45: backticked flags, function names and a SKILL.md link in the other cells cost nothing -- no author condition is needed'
    Assert-True ($q45.Out -match [regex]::Escape(": $($mirrorExpected.Count) row(s) read from the first cell")) 'scenario 45: still exactly one claim per row -- the four extra backtick runs per row were not read as names'

    # --- Scenario 46: a header row, a separator and running prose inside the span are passed over without
    # a rule of their own -- they simply carry no backticked first cell ----------------------------------
    Write-Host "check 32 -- a header, a separator and prose inside the span are not rows" -ForegroundColor Cyan
    $p46Lines = @('# scripts', '', '<!-- shared-scripts:mirror -->', 'Not every script here is reached through a skill.', '') +
        (New-MirrorTable -Rows $mirrorExpected) +
        @('', 'The registry is the only place that knows the answer.', '<!-- /shared-scripts:mirror -->')
    [System.IO.File]::WriteAllText($mirrorReadme, (($p46Lines -join "`n") + "`n"), $Utf8NoBom)

    $q46 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($q46.Out -match $MirrorFindingPattern)) 'scenario 46: the header, the separator and the surrounding prose produce no phantom rows'
    Assert-True ($q46.Out -match [regex]::Escape(": $($mirrorExpected.Count) row(s) read from the first cell")) 'scenario 46: and the claim count is unchanged by them'

    # --- Scenario 47: a FENCED example row is invisible, as everywhere else in this file. Asserted on the
    # finding a masked row would produce rather than on the span count, because this check reads the mask
    # for its ROWS where check 10 reads it for its backticks -- the mechanic is shared, the reading is not
    Write-Host "check 32 -- a fenced example row is not a claim" -ForegroundColor Cyan
    $p47Lines = @('# scripts', '', '<!-- shared-scripts:mirror -->') + (New-MirrorTable -Rows $mirrorExpected) +
        @('', 'Add one like this:', '', '```', '| `task/not-a-real-mirror.ps1` | example | none |', '```', '', '<!-- /shared-scripts:mirror -->')
    [System.IO.File]::WriteAllText($mirrorReadme, (($p47Lines -join "`n") + "`n"), $Utf8NoBom)

    $q47 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($q47.Out -match [regex]::Escape('task/not-a-real-mirror.ps1'))) 'scenario 47: the fenced example row is masked, so it is not read as a phantom claim'
    Assert-True ($q47.Out -match [regex]::Escape(": $($mirrorExpected.Count) row(s) read from the first cell")) 'scenario 47: and the claim count is the real table alone'

    # --- Scenario 48 (THE SCOPE difference): the canonical set is the marked document's OWN FOLDER, not
    # its plugin. The same marker one level up, in the plugin root README, must expect the deeper
    # 'scripts/'-prefixed paths -- so the folder-relative table that passed in 42 now reports every one of
    # its rows twice over, missing and extra. A plugin-scoped implementation passes every scenario above
    # and fails only here, which is why this one is written ----------------------------------------------
    Write-Host "check 32 -- the scope is the marked document's OWN folder, not its plugin" -ForegroundColor Cyan
    Remove-Item -LiteralPath $mirrorReadme -Force
    $mirrorRootReadme = Join-Path $Fixture 'plugins\teams\team-alpha\README.md'
    $p48Lines = @('# team-alpha', '', '<!-- shared-scripts:mirror -->') + (New-MirrorTable -Rows $mirrorExpected) + @('<!-- /shared-scripts:mirror -->')
    [System.IO.File]::WriteAllText($mirrorRootReadme, (($p48Lines -join "`n") + "`n"), $Utf8NoBom)

    $q48 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($q48.Out -match [regex]::Escape("has no row for: scripts/$($mirrorExpected[0])")) 'scenario 48: from the plugin root the canonical path keeps its scripts/ prefix -- the scope followed the document, not the plugin'
    Assert-True ($q48.Out -match [regex]::Escape("does not mirror here: $($mirrorExpected[0])")) 'scenario 48: and the folder-relative rows that passed one level down are now extras, for the same reason'

    # --- Scenario 49: a span in a document under no published plugin is refused rather than silently
    # skipped, exactly as check 29 refuses one (scenario 31) ---------------------------------------------
    Write-Host "check 32 -- a span outside any plugin is refused" -ForegroundColor Cyan
    Remove-Item -LiteralPath $mirrorRootReadme -Force
    $mirrorRootDoc = Join-Path $Fixture 'CONTRIBUTING.md'
    $mirrorRootDocOriginal = [System.IO.File]::ReadAllText($mirrorRootDoc, [System.Text.Encoding]::UTF8)
    $p49Lines = @('# Contributing', '', '<!-- shared-scripts:mirror -->', '| `task/whatever.ps1` | a row | none |', '<!-- /shared-scripts:mirror -->')
    [System.IO.File]::WriteAllText($mirrorRootDoc, (($p49Lines -join "`n") + "`n"), $Utf8NoBom)

    $q49 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($q49.Out -match [regex]::Escape('belongs to no published plugin')) 'scenario 49: a span in a root document is refused rather than silently skipped'
    Assert-Equal 1 $q49.Code 'scenario 49: and it fails the gate'

    [System.IO.File]::WriteAllText($mirrorRootDoc, $mirrorRootDocOriginal, $Utf8NoBom)
    $q49b = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($q49b.Out -match $MirrorFindingPattern)) 'scenario 49: the fixture is clean again once the span is gone'
    Assert-True ($q49b.Out -match [regex]::Escape('[shared-script-list] checked 0')) 'scenario 49: and zero spans is the opt-in pass, not a silent skip'

} finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

Complete-IntegritySuite
