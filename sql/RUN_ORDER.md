# What to run, in what order — for Krishna

Six `.sql` files are generated, but **you run four of them**. The other two are a narrow fallback
(`c02`, `c03`) kept in case the expansive tables will not fit in 20 GB — do not run both sets, because
`c03` and `c03x` both create `dbo.mart_patient` and the second would overwrite the first.

Everything below goes on **Cosmos_SneakPeek first** (1% sample, seconds to minutes), then the same
three files on **Cosmos**. SneakPeek is not optional: a mistake on Cosmos costs hours of shared server.

| Step | File | Server · database | Notes |
|---|---|---|---|
| 0 | `c00_preflight.sql` | COSMOS · Cosmos_SneakPeek | catalogue only. **Paste the output into `handoff/round_1_preflight.md`** — two sections of `c02x` are written against guessed column names and will fail until these are confirmed |
| 1 | `c01_concept_keys.sql` | COSMOS · Cosmos_SneakPeek | 273 codes → `##cx_*` key tables. Ends with a check: concepts that resolved to zero keys. Should be empty |
| 2 | `c02x_marts_expansive.sql` | COSMOS · Cosmos_SneakPeek | builds `##mart_*_GBM5ARI`. Each section is its own batch, so a failing section (expect 7 and 8 until c00 is in) does not stop the rest. **The last result set lists every mart with a row count or NOT BUILT; the one before it is `@@ServerName` — copy it** |
| 3 | `c03x_transfer_expansive.sql` | PROJECTS · ProjectD237BA6 | first Ctrl+H `$(COSMOS_SERVER)` → the `@@ServerName` string. **Same SSMS session as step 2** — the `##` tables die when that window closes |
| 4 | `c04_check_marts.sql` | PROJECTS · ProjectD237BA6 | reads `INFORMATION_SCHEMA` only. Result set 2 must say `OK` for every table that was built. The exact columns and types it checks are in **`docs/MART_CONTRACT.md`** — that page is the definition of "deposited correctly" |

Then `handoff/round_3_sneakpeek_counts.md`: the row counts and `EXEC sp_spaceused 'dbo.mart_dx'` etc. on
PROJECTS. Multiply by ~100 for the full build; if the total passes ~15 GB, we apply the reductions in
`docs/MART_SPEC.md` §6 before step 2 is run on Cosmos.

For the full run change `USE Cosmos_SneakPeek` to `USE Cosmos` in c01 and c02x (or regenerate with
`python sql/gen_sql.py --full`), run 1 → 2 → 3 again in one session, and record the snapshot date.

**What goes where.** The tables land in the project *database* (`ProjectD237BA6`, via `c03x`) — that is
what the analysis reads. The `.sql` files as you actually ran them go in the project *folder* and the
project GitLab, so the extraction is auditable. Both, not either.

**Sections 7 and 8** (`VitalsFact`, `CancerStagingFact`) and the order-component date column are the
three guesses in `c02x`. If c00 shows different names, change them in `sql/schema_map.csv` and
regenerate — or just edit the two sections in place and tell us what you changed. Section 8 is the one
that matters most: it is the histology-confirmed outcome.
