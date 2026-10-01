# AGENTS.md — brief for a coding agent working with the data architect

You are running on Krishna's laptop (Codex, Claude Code, or similar) inside a clone of this repository.
Your job is to get a data mart deposited in Epic Cosmos with as little thinking on Krishna's part as
possible. You do the reading, the file edits, the git, the interpretation of what he pastes back, and the
pull requests. **He does the one thing you cannot: run SQL inside the Cosmos virtual machine (DSVM) and
tell you what he saw.** The DSVM has no internet, no GitHub, and no agent; code goes in by paste, and
only names, counts, sizes and error text come out.

Read in this order, then start: this file · `sql/bundle/README.md` · `START_HERE_KRISHNA.md` ·
`docs/MART_CONTRACT.md`. `CLAUDE.md` is the analyst-side brief; the guardrails in it apply to you too.

## The boundary, in one table

| You can | You cannot — Krishna does it |
|---|---|
| clone, read, edit files, run `python sql/gen_sql.py`, `python sql/gen_contract.py`, `python deploy/make_paste_script.py` | execute any SQL against Cosmos |
| tell him exactly which file to open in SSMS, on which server, and what to copy back | see his screen |
| turn what he pastes (column lists, counts, errors) into finished `handoff/` files, `schema_map.csv` edits, and PRs | decide to skip a round |
| regenerate the SQL after a confirmed column name and hand him the fresh paste script | transcribe a data row — refuse it if offered |

## The job, as rounds

Each round: you prepare → he runs in SSMS → he pastes results to you → you write the files → PR → **stop**
and tell Jonah. Branch per round: `krishna/round-N`. Never commit to `main`.

**Round 0 — set up (you, 10 min).** `git pull`, confirm `sql/bundle/1_COSMOS_build.sql` and
`2_PROJECTS_transfer_and_check.sql` exist, run `python deploy/make_paste_script.py` so
`deploy/paste_into_dsvm.ps1` is fresh, and tell him: copy that file, paste it into
`Z:\Project D237BA6\paste_into_dsvm.ps1` in the DSVM via Notepad++ (full Citrix client), run it in
PowerShell from that folder. Done when he reports `wrote N files` and no `HASH MISMATCH`.

**Round 1 — the catalogue.** He runs `sql/c00_preflight.sql` on server **COSMOS**, `USE Cosmos_SneakPeek`,
and reads the four grids. You need four facts, and he can get them from the DSVM grids *or* from the
Cosmos Portal Data Dictionary in his laptop browser (copyable; prefer that):
1. `CancerStagingFact`: which column carries the ICD-O **topography** (site) code, and whether `HistologyCode`
   values look like `9440/3` or `9440` (behaviour in `BehaviorCode`).
2. BMI: on `VitalsFact` (which column) or on `FlowsheetValueFact` + `FlowsheetRowDim`.
3. `MedicationOrderComponentFact`: the start-date column, the quantity column, and that it has `PatientDurableKey`.
4. `PatientDim`: the exact 2020 SVI socioeconomic percentile column.
Then you: fill `handoff/round_1_preflight.md`; set every `UNCONFIRMED` row of `sql/schema_map.csv` to
`confirmed` and correct names; if a name differed, change it in `sql/gen_sql.py` where it is used
(search the old name), run `python sql/gen_sql.py` and `python sql/gen_contract.py`, and confirm the
bundle regenerated. Commit, push, `gh pr create --title "Round 1 — preflight"`. Stop.

**Round 3 — the 1% build.** He runs `sql/bundle/1_COSMOS_build.sql` on COSMOS/SneakPeek in one SSMS
window and pastes you the final two grids (row counts with any `NOT BUILT`; `cosmos_server`). You give him
`sql/bundle/2_PROJECTS_transfer_and_check.sql` with `$(COSMOS_SERVER)` already replaced by that string
(do the replace yourself, hand him the file or the paste script) and tell him: same window, new query
tab, connection → PROJECTS, F5. He pastes back the STEP 4 verdict grid and the STEP 5 size grids. You fill
`handoff/round_3_sneakpeek_counts.md`, compute `projected_full_cosmos_gb`, and state plainly whether it
fits under 20 GB. PR. Stop — Jonah decides go / trim.

**Round 4 — the full build.** Only after "go" on the Round 3 PR. You regenerate with
`python sql/gen_sql.py --full` (targets `Cosmos`), refresh the paste script, and he runs bundle 1 then
bundle 2 in one sitting. You fill `handoff/round_4_full_build.md` with the snapshot date, server string,
final counts, and the Project GitLab commit hash of the SQL as run. PR. Done.

## What to do with what he pastes

| He pastes | You do |
|---|---|
| `Invalid column name 'X'` in c02x | if section 7/8 and Round 1 not merged: expected, note it, continue. Otherwise find `X` in `sql/gen_sql.py`, ask him the real name (Data Dictionary), fix, regenerate |
| `Database 'ProjectD237BA6' does not exist` | he is on COSMOS, not PROJECTS — plug-and-pencil icon |
| `Could not find … ##mart_…` in bundle 2 | the COSMOS window closed, or the server string was not replaced — rebuild, keep the window open |
| `TEMPDB … filegroup is full` | stop everything; open an issue labelled `blocked`; tell Jonah |
| a concept with zero keys from c01 | record in `handoff/round_2_concept_keys.md`; not a blocker |
| HASH MISMATCH from the paste script | regenerate with `make_paste_script.py`, have him re-paste the whole file |
| anything that looks like a row of data | do not record it; tell him why; ask for the count or the column name instead |

## Rules you enforce

1. Names, counts, sizes, error text may be committed. A patient row, patient key, record date,
   `SourceKey`, a cell count under 11, a screenshot of the DSVM — never, anywhere.
2. SneakPeek before `Cosmos`. Always.
3. Stop at the end of Rounds 1 and 3. Jonah merges.
4. You do not invent column names. If neither he nor the Dictionary knows, it is a question on the PR.
5. Explicit `git add <files>`; never `git add -A`; never force-push; never rewrite history.
6. Edit the generators (`sql/gen_sql.py`, `sql/mart_contract.csv`), never the generated `.sql`.

## Kickoff

Krishna types: *"Read AGENTS.md and drive me through the Cosmos mart deposit from Round 0. I will paste
you whatever SSMS shows."* You answer with Round 0's three instructions and nothing else.
