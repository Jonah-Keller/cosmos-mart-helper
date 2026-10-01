# The bundle — two files, two servers, done

This is everything Krishna runs to deposit the data mart. Both files are generated
(`python sql/gen_sql.py`); do not edit them by hand except for the two things named below.

| | File | Server | Window |
|---|---|---|---|
| 1 | `1_COSMOS_build.sql` | **COSMOS** · `Cosmos_SneakPeek` first, `Cosmos` after | open one SSMS window, F5 |
| 2 | `2_PROJECTS_transfer_and_check.sql` | **PROJECTS** · `ProjectD237BA6` | same window, new query tab, change connection |

**Two manual edits, total:**
1. In file 2, Ctrl+H `$(COSMOS_SERVER)` → the `@@ServerName` string file 1 printed last.
2. For the full run, in file 1, Ctrl+H `USE Cosmos_SneakPeek;` → `USE Cosmos;` — *after* the SneakPeek
   sizes (file 2, STEP 5) × 100 fit under 20 GB.

**What comes back to us** (into `handoff/round_3_sneakpeek_counts.md`, then `round_4_full_build.md`):
the row-count grid from the end of file 1; the STEP 4 verdict grid and the STEP 5 size grids from
file 2; the `@@ServerName`; for the full run the snapshot date. Counts and names only.

**If a column does not exist** — expected only in sections 7 (`VitalsFact`) and 8 (`CancerStagingFact`)
of STEP 2, written without a catalogue check — fix the name in place, re-run that section (it is its own
batch), and tell us what you changed so the generator is corrected.

Keep the COSMOS window open until file 2 has finished. The `##` tables live only as long as it does.
