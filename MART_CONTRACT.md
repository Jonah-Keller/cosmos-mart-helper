---
title: "The deposit contract — every table, every column, every type"
subtitle: "Generated from sql/mart_contract.csv · build to this and the analysis runs unchanged"
---

This is the complete list of what lands in `ProjectD237BA6`. **Required** columns must exist with
the stated type or the analysis stops and says which one is missing. **Optional** columns are used
when present and silently skipped when not. Names are lower-case; types are SQL Server types.
`int` date columns are `YYYYMMDD` integers, exactly as Cosmos `*DateKey` columns are stored.

Grain-key columns together identify a row. Every fact is `Count > 0`; `PatientDim` is `IsCurrent = 1`;
`MedicationKey > 0`. After `c03x`, run `sql/c04_check_marts.sql` on PROJECTS — it prints PASS/FAIL per column.

| Table | The table itself | Required columns | Optional | Grain |
|---|---|---|---|---|
| `mart_patient` | required | 4 | 7 | `patient_id` |
| `mart_dx` | required | 6 | 3 | `patient_id` × `code_type` × `code` |
| `mart_med` | required | 7 | 4 | `patient_id` × `rxnorm_code` × `mode` × `source_table` |
| `mart_med_qtr` | optional | 4 | 1 | `patient_id` × `rxnorm_code` × `quarter_start_datekey` |
| `mart_proc` | wanted | 6 | 1 | `patient_id` × `cpt_code` × `hcpcs_code` |
| `mart_enc` | required | 3 | 1 | `patient_id` × `datekey` × `enc_type` |
| `mart_vitals` | optional | 3 | 2 | `patient_id` × `datekey` |
| `mart_lab` | optional | 4 | 2 | `patient_id` × `loinc_code` × `datekey` |
| `mart_cancer_staging` | wanted — the histology outcome | 4 | 5 | `patient_id` |
| `mart_source` | wanted | 3 | 3 | `patient_id` |
| `mart_active` | wanted (cheap) | 3 | 0 | `patient_id` × `start_datekey` |

**Required** tables: without them nothing runs. **Wanted**: each carries an analysis a reviewer asked for and
`01_adapt.R` prints exactly what is lost if it is absent. **Optional**: nice to have, skipped silently.
Within a table, a *required column* is required only if the table is delivered at all.

## `mart_patient`

one row per patient in the universe

| Column | Type | Required | Grain | Source | Meaning |
|---|---|---|---|---|---|
| `patient_id` | `bigint` | **yes** | ● | `PatientDim.DurableKey` | IsCurrent = 1 |
| `sex` | `nvarchar` | **yes** |  | `PatientDim.Sex` | legal sex; universe is 'Male' |
| `race` | `nvarchar` | **yes** |  | `PatientDim.FirstRace` | CDC categories |
| `ethnicity` | `nvarchar` | no |  | `PatientDim.Ethnicity` |  |
| `birth_year` | `int` | **yes** |  | `YEAR(PatientDim.BirthDate)` | adult birth dates are truncated to 1 Jan so the year is exact |
| `death_date` | `date` | no |  | `PatientDim.DeathDate` | NULL when unknown or masked past the snapshot |
| `status` | `nvarchar` | no |  | `PatientDim.Status` | deceased flag as documented |
| `state` | `nvarchar` | no |  | `PatientDim.StateOrProvinceAbbreviation` | finest location in EDDI; mapped to census division downstream |
| `ruca` | `int` | no |  | `PatientDim.PrimaryRUCA_X` | rural-urban commuting area 1-10; 99 uncoded |
| `svi` | `float` | no |  | `PatientDim.<2020 SVI socioeconomic percentile>` | confirm the column name in c00 |
| `source_combo_key` | `bigint` | no |  | `PatientDim.SourceComboKey_X` | used only to build mart_source; may be dropped after |

## `mart_dx`

one row per patient x code_type x code

| Column | Type | Required | Grain | Source | Meaning |
|---|---|---|---|---|---|
| `patient_id` | `bigint` | **yes** | ● | `DiagnosisEventFact.PatientDurableKey` | NO code filter |
| `code_type` | `nvarchar` | **yes** | ● | `DiagnosisTerminologyDim.Type` | 'ICD-10-CM' or 'ICD-9-CM' (other types may be present; they are ignored) |
| `code` | `nvarchar` | **yes** | ● | `DiagnosisTerminologyDim.Value` | with or without the dot; the analysis strips it |
| `first_datekey` | `int` | **yes** |  | `MIN(DiagnosisEventFact.StartDateKey)` | YYYYMMDD; Count > 0 only |
| `last_datekey` | `int` | **yes** |  | `MAX(DiagnosisEventFact.StartDateKey)` | YYYYMMDD |
| `n` | `bigint` | **yes** |  | `COUNT(*)` | diagnosis events of any Type |
| `first_billing_datekey` | `int` | no |  | `MIN(StartDateKey) WHERE Type LIKE 'Billing%'` | lets us run a billing-only outcome definition |
| `n_billing` | `bigint` | no |  | `COUNT WHERE Type LIKE 'Billing%'` |  |
| `n_problem_list` | `bigint` | no |  | `COUNT WHERE Type = 'Problem List'` |  |

## `mart_med`

one row per patient x rxnorm_code x mode x source_table

| Column | Type | Required | Grain | Source | Meaning |
|---|---|---|---|---|---|
| `patient_id` | `bigint` | **yes** | ● | `MedicationOrderComponentFact.PatientDurableKey` |  |
| `rxnorm_code` | `nvarchar` | **yes** | ● | `MedicationCodeDim.Code WHERE Type = 'RxNorm'` | ingredient-level RxNorm; NULL if the medication has no RxNorm mapping |
| `generic_name` | `nvarchar` | no |  | `MedicationDim.GenericName` |  |
| `strength` | `nvarchar` | no |  | `MedicationDim.Strength (confirm)` | finasteride 5 mg vs 1 mg; whatever string the dimension carries |
| `mode` | `nvarchar` | **yes** | ● | `MedicationOrderFact.Mode` | 'Inpatient' / 'Outpatient' / 'Historical'; NULL for administration and dispense rows. KEEP Historical rows; the analysis excludes them |
| `source_table` | `nvarchar` | **yes** | ● | `literal` | 'order' / 'administration' / 'dispense' |
| `first_datekey` | `int` | **yes** |  | `MIN(StartDateKey)` | YYYYMMDD |
| `last_datekey` | `int` | **yes** |  | `MAX(StartDateKey)` | YYYYMMDD |
| `n` | `bigint` | **yes** |  | `COUNT(*)` | records |
| `n_days_supply` | `int` | no |  | `SUM(MedicationDispenseFact.DaysSupply) (confirm column)` | dispense rows only; the duration question (R4 #7) |
| `total_quantity` | `float` | no |  | `SUM(Quantity)` |  |

## `mart_med_qtr`

one row per patient x drug x calendar quarter

| Column | Type | Required | Grain | Source | Meaning |
|---|---|---|---|---|---|
| `patient_id` | `bigint` | **yes** | ● | `MedicationOrderComponentFact.PatientDurableKey` | 5-ARIs and alpha-blockers only |
| `rxnorm_code` | `nvarchar` | **yes** | ● | `MedicationCodeDim.Code` | one of 228790 25025 77492 17300 49276 37798 720825 8629 |
| `quarter_start_datekey` | `int` | **yes** | ● | `derived from StartDateKey` | YYYYMMDD of the first day of the quarter |
| `n` | `bigint` | **yes** |  | `COUNT(*)` | orders in the quarter; Mode <> 'Historical' |
| `total_quantity` | `float` | no |  | `SUM(Quantity)` |  |

## `mart_proc`

one row per patient x cpt_code x hcpcs_code

| Column | Type | Required | Grain | Source | Meaning |
|---|---|---|---|---|---|
| `patient_id` | `bigint` | **yes** | ● | `ProcedureEventFact.PatientDurableKey` | NO code filter |
| `cpt_code` | `nvarchar` | **yes** | ● | `ProcedureDim.CptCode` | NULL when the procedure has no CPT |
| `hcpcs_code` | `nvarchar` | **yes** | ● | `ProcedureDim.HcpcsCode` | NULL when no HCPCS |
| `code_set` | `nvarchar` | no |  | `derived` | 'CPT' or 'HCPCS' |
| `first_datekey` | `int` | **yes** |  | `MIN(StartDateKey)` | YYYYMMDD |
| `last_datekey` | `int` | **yes** |  | `MAX(StartDateKey)` | YYYYMMDD |
| `n` | `bigint` | **yes** |  | `COUNT(*)` |  |

## `mart_enc`

one row per patient x encounter day x type (DISTINCT)

| Column | Type | Required | Grain | Source | Meaning |
|---|---|---|---|---|---|
| `patient_id` | `bigint` | **yes** | ● | `EncounterFact.PatientDurableKey` | or per month if reduced (MART_SPEC 6) |
| `datekey` | `int` | **yes** | ● | `EncounterFact.DateKey` | YYYYMMDD; Count > 0 |
| `enc_type` | `nvarchar` | **yes** | ● | `EncounterFact.Type` | 'Office Visit' / 'Hospital Encounter' / ... |
| `payer` | `nvarchar` | no |  | `EncounterFact.PrimaryCoverageFinancialClass_X` | answers the insurance question (R2 #5) |

## `mart_vitals`

one row per measurement

| Column | Type | Required | Grain | Source | Meaning |
|---|---|---|---|---|---|
| `patient_id` | `bigint` | **yes** | ● | `VitalsFact.PatientDurableKey (confirm object)` | or most recent per quarter if reduced |
| `datekey` | `int` | **yes** | ● | `VitalsFact.DateKey` | YYYYMMDD |
| `bmi` | `float` | **yes** |  | `VitalsFact.BodyMassIndex (confirm column)` | kg/m2; the analysis keeps 10-80 |
| `height` | `float` | no |  | `VitalsFact.Height` |  |
| `weight` | `float` | no |  | `VitalsFact.Weight` |  |

## `mart_lab`

one row per numeric result

| Column | Type | Required | Grain | Source | Meaning |
|---|---|---|---|---|---|
| `patient_id` | `bigint` | **yes** | ● | `LabComponentResultFact.PatientDurableKey` | nine LOINC codes only |
| `loinc_code` | `nvarchar` | **yes** | ● | `LabComponentDim.LoincCode` | 2857-1 19195-7 10886-0 2986-8 2991-8 2990-0 13967-5 10501-5 15067-2 |
| `datekey` | `int` | **yes** | ● | `LabComponentResultFact.PrioritizedDateKey` | YYYYMMDD |
| `value_numeric` | `float` | **yes** |  | `LabComponentResultFact.NumericValue` | free-text results are masked in EDDI and excluded |
| `unit` | `nvarchar` | no |  | `LabComponentResultFact.Unit` |  |
| `abnormal_flag` | `bit` | no |  | `LabComponentResultFact.Abnormal` |  |

## `mart_cancer_staging`

EVERY column of CancerStagingFact for the universe

| Column | Type | Required | Grain | Source | Meaning |
|---|---|---|---|---|---|
| `patient_id` | `bigint` | **yes** | ● | `CancerStagingFact.PatientDurableKey` | the names below are the ones the analysis looks for |
| `datekey` | `int` | **yes** |  | `CancerStagingFact.<diagnosis/staging DateKey> (confirm)` | YYYYMMDD; any of datekey / diagnosis_datekey / first_datekey is recognised |
| `bodysiteorcancertype_code` | `nvarchar` | **yes** |  | `CancerStagingFact.<ICD-O topography column> (confirm)` | C71.x is the brain; any of bodysiteorcancertype_code / site_code / icdo_site_code / primarysite is recognised |
| `histologycode` | `nvarchar` | **yes** |  | `CancerStagingFact.HistologyCode` | '9440/3' or '9440' - either works if behaviorcode is present |
| `behaviorcode` | `nvarchar` | no |  | `CancerStagingFact.BehaviorCode` | '3' = malignant; needed only if histologycode lacks the '/3' |
| `histology` | `nvarchar` | no |  | `CancerStagingFact.Histology` | text |
| `histologicgradeg` | `nvarchar` | no |  | `CancerStagingFact.HistologicGradeG` | WHO grade |
| `diagnosticconfirmation` | `nvarchar` | no |  | `CancerStagingFact.DiagnosticConfirmation` | 'Histology' etc. |
| `ajccstagegroup` | `nvarchar` | no |  | `CancerStagingFact.AjccStageGroup` |  |

## `mart_source`

one row per patient

| Column | Type | Required | Grain | Source | Meaning |
|---|---|---|---|---|---|
| `patient_id` | `bigint` | **yes** | ● | `via PatientDim.SourceComboKey_X -> PatientSourceBridgeX` |  |
| `n_sources` | `int` | **yes** |  | `COUNT(DISTINCT SourceKey)` | contributing organisations; identity never included |
| `n_sources_greenlit` | `int` | no |  | `COUNT WHERE SourceDim.UseInCosmosAnalytics = 1` |  |
| `transfer_start_datekey` | `int` | **yes** |  | `MIN(SourceDim.CompletedTransferStartDate_X) as YYYYMMDD` | from when the record is complete |
| `transfer_end_datekey` | `int` | no |  | `MAX(SourceDim.CompletedTransferEndDate_X) as YYYYMMDD` |  |
| `any_non_us_source` | `bit` | no |  | `MAX(SourceCountry <> 'United States of America')` |  |

## `mart_active`

one row per activity interval

| Column | Type | Required | Grain | Source | Meaning |
|---|---|---|---|---|---|
| `patient_id` | `bigint` | **yes** | ● | `ActivePatientRegistryDataMartX.PatientDurableKey` |  |
| `start_datekey` | `int` | **yes** | ● | `ActivePatientRegistryDataMartX.StartDateKey` | YYYYMMDD |
| `end_datekey` | `int` | **yes** |  | `ActivePatientRegistryDataMartX.EndDateKey` | YYYYMMDD; two years after the last qualifying encounter |

## Type equivalences the check accepts

| Contract | Also accepted |
|---|---|
| `bigint` | `int` |
| `int` | `bigint`, `smallint` |
| `float` | `real`, `decimal`, `numeric` |
| `nvarchar` | `varchar`, `nchar`, `char` |
| `bit` | `tinyint`, `int` |
| `date` | `datetime`, `datetime2`, `smalldatetime` |
