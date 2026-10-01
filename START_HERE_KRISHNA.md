# Start here — Krishna's checklist

**Two things that make this easier:** `helper/krishna_helper.html` — open it in any browser; it is this
checklist with copy buttons, it writes the handoff files from what you type, and it decodes errors.
And `helper/AI_PROMPT.md` — paste it into Claude or ChatGPT and it walks you through, step by step.

Follow this top to bottom. Every step says what to do, where, and what "done" looks like. You should
not need to read anything else to get through it; the other documents exist for when you want the why.

Rule for everything below: **column names, table names, row counts, byte sizes, error messages — fine
to paste anywhere. A row of patient data — never**, not in a file, not in GitHub, not in a text.

---

## Part A — get the code (15 minutes, once)

### A1 · On your laptop

```bash
git clone https://github.com/Jonah-Keller/cosmos-gbm-validation.git
cd cosmos-gbm-validation
git checkout -b krishna/round-1
```

Done when: you have a folder with `sql/`, `docs/`, `handoff/` in it and `git branch` shows `krishna/round-1`.

### A2 · Into the DSVM

The DSVM cannot reach GitHub, so the repository travels in as one PowerShell script.

1. On your laptop, open `deploy/paste_into_dsvm.ps1` in any text editor. Select all, copy.
2. Log in to the Cosmos Portal → select project **D237BA6** → Data Science → launch the DSVM. Use the
   **full** Citrix client (gear icon → Account Settings → "Use full version") or paste will not work.
3. In the DSVM, open Notepad++ (desktop). New file. Paste. Save as `Z:\Project D237BA6\paste_into_dsvm.ps1`
   (use whatever the Data Science Navigator shows as the **Project Folder** — the Z: path).
4. Open PowerShell in the DSVM and run:
   ```powershell
   Set-Location "Z:\Project D237BA6"
   .\paste_into_dsvm.ps1
   ```
   If PowerShell refuses to run scripts: `powershell -ExecutionPolicy Bypass -File .\paste_into_dsvm.ps1`

Done when: it prints `wrote 42 files into ...\cosmos-gbm-validation` and no `HASH MISMATCH` lines.

---

## Part B — Round 1: the catalogue (30 minutes)

This round reads **no patient data**. It only asks SQL Server what tables and columns exist, so that
the next scripts are written against real names instead of my guesses.

### B1 · Run c00

1. DSVM desktop → **SQL Server Management Studio**. Connect to server **`COSMOS`**.
2. File → Open → `Z:\Project D237BA6\cosmos-gbm-validation\sql\c00_preflight.sql`.
3. Make sure the first line is `USE Cosmos_SneakPeek;`. Execute (F5). It takes seconds.

### B2 · Read the output

Four result grids. Leave them on screen; you will fill the handoff file on your laptop in B3 and use
these as the cross-check. Keep in your head (or in a Notepad++ file saved **inside** the DSVM, under
the project folder):

- which of the tables in result set 1 are missing, if any;
- the exact column names of `CancerStagingFact`, and whether `HistologyCode` values look like `9440/3` or `9440`;
- whether `VitalsFact` has a BMI column, and its name;
- the date and quantity column names on `MedicationOrderComponentFact`;
- the distinct `Type` labels in result set 3 (e.g. `ICD-10-CM`) and the partition columns in result set 4.

### B3 · Get the answers out and open the pull request

Nothing is copied out of the DSVM — not even text, and **never a photo or screenshot of its screen**.
You do not need to: every table and column name c00 shows you is also published in the **Cosmos Data
Dictionary** in the Portal, which runs in your laptop's browser and copies freely.

1. On your laptop: Cosmos Portal → **Data Dictionary** tab. Look up, in turn, `CancerStagingFact`,
   `VitalsFact` (and `FlowsheetValueFact` if `VitalsFact` has no BMI column), `MedicationOrderComponentFact`,
   `MedicationDispenseFact`, and `PatientDim` (search its columns for "Svi"). Open each table's
   **Columns** section and tick **Available in Data Science** — only those columns exist in EDDI.
2. In your laptop clone, fill `handoff/round_1_preflight.md` from the Dictionary: the column lists for
   those five tables under §2, and the four answers under §5. Use what c00 showed you in the DSVM as the
   cross-check — if the DSVM and the Dictionary disagree, say so under §6 and trust the DSVM.
3. §3 (vocabulary labels) and §4 (partition keys): type the handful of distinct values you saw in c00's
   result sets 3 and 4 — typically fewer than ten lines each. The Dictionary marks partition keys too.
4. Open `sql/schema_map.csv`. For each row whose `status` is `UNCONFIRMED`, change it to `confirmed`
   and correct the `object`/column names if they differ.
5. ```bash
   git add handoff/round_1_preflight.md sql/schema_map.csv
   git commit -m "round 1: c00 preflight, confirmed against the Data Dictionary"
   git push -u origin krishna/round-1
   ```
6. GitHub shows a "Compare & pull request" button. Click it. Title: `Round 1 — preflight`. Create.

Done when: the pull request exists. **Stop here and ping Jonah.** We regenerate the SQL from what you
confirmed, usually the same day, and merge. Then pull:

```bash
git checkout main && git pull
```

and paste the updated `deploy/paste_into_dsvm.ps1` into the DSVM again exactly as in A2 (it overwrites in place).

---

## Part C — Round 2 and 3: build on the 1% sample (1–2 hours)

Still on **`COSMOS` server, `USE Cosmos_SneakPeek`**. Keep **one SSMS window** for all of C1–C3 — the
`##` tables live only as long as that window does.

### C1 · Concept keys

Open and execute `sql/c01_concept_keys.sql`. The last result set is the check: concepts that matched
**zero** keys. It should be empty. If it is not, copy it into `handoff/round_2_concept_keys.md` and
carry on — a missing concept is a note for us, not a blocker.

### C2 · The marts

Open and execute `sql/c02x_marts_expansive.sql`. Every section is its own batch, so if one errors the
rest still run. Two result sets at the end:

- a table of every mart with its row count, or `NOT BUILT` — copy it into `handoff/round_3_sneakpeek_counts.md`
- `cosmos_server` — one string like `et4003vndsql031`. **Copy it; C3 needs it.**

If any row says `NOT BUILT`, scroll up in the Messages tab, find the red error for that section, and
paste the error text (not data) under `## Surprises` in the same handoff file.

### C3 · Transfer to the project database

1. Open `sql/c03x_transfer_expansive.sql` **in the same SSMS window** (New Query is fine; same window).
2. Change connection to server **`PROJECTS`** (plug-and-pencil icon on the toolbar). Leave `USE ProjectD237BA6;` as is.
3. Ctrl+H: replace `$(COSMOS_SERVER)` with the `cosmos_server` string from C2. Replace All.
4. Execute. Roughly a minute per GB. The last result set is the row counts on PROJECTS — they must
   match C2. Copy into the handoff file too.
5. Still on PROJECTS, open and execute `sql/c04_check_marts.sql`. Result set 2 is the verdict per table:
   `OK`, `FIX BEFORE ANALYSIS`, or `TABLE ABSENT`. Paste that grid into the handoff file. (What it is
   checking — every column and type — is `docs/MART_CONTRACT.md`, the one page that defines "deposited
   correctly".)
6. Still on PROJECTS, run and copy the output of:
   ```sql
   EXEC sp_spaceused 'dbo.mart_dx';  EXEC sp_spaceused 'dbo.mart_enc';  EXEC sp_spaceused 'dbo.mart_med';
   EXEC sp_spaceused 'dbo.mart_proc'; EXEC sp_spaceused 'dbo.mart_cancer_staging';
   ```
   This is how we learn whether the full build fits in the 20 GB project database.

### C4 · Commit and PR, as in B3

Same steps: handoff files → laptop clone → `git checkout -b krishna/round-3` → commit → push → pull
request titled `Round 3 — SneakPeek marts`. **Stop and ping Jonah.** We check the sizes × 100 against
20 GB and either say "go" or trim the spec first.

---

## Part D — Round 4: the real thing (half a day of server time)

Only after we have said "go" on the Round 3 PR.

1. Pull `main`, paste the fresh `paste_into_dsvm.ps1` into the DSVM (A2).
2. In SSMS on **`COSMOS`**, open `c01` and `c02x`; change the first line of each to **`USE Cosmos;`**.
3. Run `c01`, then `c02x`, **then `c03x` on PROJECTS, all in one SSMS window, in one sitting.** Do not
   close SSMS between them. Do not disconnect Citrix for long — the window must stay alive.
4. Before closing anything, on COSMOS run `SELECT MAX(DateValue) FROM DateDim WHERE DateKey < 20991231`
   and note the Portal's static-copy date for this snapshot. Put both, plus the final row counts and the
   `cosmos_server` string, into `handoff/round_4_full_build.md`.
5. Clean up: run the `DROP TABLE ##…` lines at the bottom of `c03x` on COSMOS.
6. Save `c01`, `c02x`, `c03x` **exactly as you ran them** into the project folder and commit them to the
   **Project GitLab** (Data Science Navigator → GitLab → Launch Project GitLab Group → New project or the
   existing one → Upload file). That is the auditable copy.
7. Commit the handoff file on your laptop, PR titled `Round 4 — full build`.

Done when: `ProjectD237BA6` has ten `dbo.mart_*` tables and the PR is open. From here the analysis is
Jonah's — you are finished unless something in the data surprises us.

---

## If something goes wrong

| You see | Do |
|---|---|
| `Invalid column name 'X'` in c02x | expected in sections 7/8 before Round 1 is merged. Note it in the handoff file; the other sections still built |
| `Database 'ProjectD237BA6' does not exist` | you are connected to COSMOS, not PROJECTS. Plug-and-pencil icon → PROJECTS |
| `Could not find … ##mart_x_GBM5ARI` in c03x | the COSMOS window that built it was closed, or `$(COSMOS_SERVER)` was not replaced. Rebuild (c02x), keep the window open |
| `TEMPDB … filegroup is full` | stop; tell Jonah. We shrink the universe before retrying |
| A concept with zero keys in c01 | note it; carry on |
| `paste_into_dsvm.ps1` reports HASH MISMATCH | the paste was truncated. Re-copy the whole file from the laptop and paste again; if it keeps failing, tell Jonah and we split the script into parts |
| Anything else | paste the **error text only** into a GitHub issue with the `blocked` label |

## What I most want from you

The column names on `CancerStagingFact`, from Round 1. It holds histology and grade. The reviewers'
central objection to this study is that the outcome is defined by treatment rather than by tissue, and
that table is the only place in any of our data sources where tissue-confirmed glioma exists at scale.
Everything else we can approximate; that we cannot.
