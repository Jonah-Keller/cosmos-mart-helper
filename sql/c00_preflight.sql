/* ============================================================================
   c00_preflight.sql — run this FIRST, in SQL Server Management Studio, connected
   to the COSMOS server. It reads no patient rows: only the catalogue.

   Purpose: discover the exact table and column names this study needs, so the
   mart SQL is generated against confirmed names instead of guessed ones. Paste
   the four result sets back and the rest of the pipeline is generated from them.

   Runtime: seconds.
   ============================================================================ */
USE Cosmos;

/* 1 · Which of the databases we expect are visible? ------------------------- */
SELECT name AS database_name
FROM sys.databases
WHERE name IN ('Cosmos', 'Cosmos_SneakPeek')
   OR name LIKE 'Project%' OR name LIKE 'Resource%'
ORDER BY name;

/* 2 · Every fact and dimension table whose name touches our domains --------- */
SELECT TABLE_SCHEMA, TABLE_NAME, TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE '%Patient%'     OR TABLE_NAME LIKE '%Encounter%'
   OR TABLE_NAME LIKE '%Diagnosis%'   OR TABLE_NAME LIKE '%Medication%'
   OR TABLE_NAME LIKE '%Procedure%'   OR TABLE_NAME LIKE '%Order%'
   OR TABLE_NAME LIKE '%Terminology%' OR TABLE_NAME LIKE '%Source%'
   OR TABLE_NAME LIKE '%Date%'        OR TABLE_NAME LIKE '%Death%'
   OR TABLE_NAME LIKE '%Vital%'       OR TABLE_NAME LIKE '%Flowsheet%'
   OR TABLE_NAME LIKE '%Tumor%'       OR TABLE_NAME LIKE '%Cancer%'
   OR TABLE_NAME LIKE '%Oncology%'
ORDER BY TABLE_NAME;

/* 3 · Columns of the tables the design depends on --------------------------- */
SELECT TABLE_NAME, ORDINAL_POSITION, COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN (
        'PatientDim', 'DateDim', 'SourceDim',
        'EncounterFact', 'DiagnosisEventFact', 'ProcedureEventFact',
        'DiagnosisTerminologyDim', 'MedicationDim',
        /* names to confirm — any that come back empty tell us the real one is
           in result set 2 under a different label */
        'MedicationOrderFact', 'MedicationEventFact', 'MedicationAdministrationFact',
        'MedicationTerminologyDim', 'ProcedureTerminologyDim',
        'VitalSignFact', 'FlowsheetFact', 'DeathFact')
ORDER BY TABLE_NAME, ORDINAL_POSITION;

/* 4 · Partitioning — the WHERE clause must carry the partition key ---------- */
SELECT  t.name  AS table_name,
        c.name  AS partition_column,
        ps.name AS partition_scheme
FROM sys.tables t
JOIN sys.indexes i        ON i.object_id = t.object_id AND i.index_id <= 1
JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id
JOIN sys.index_columns ic ON ic.object_id = t.object_id AND ic.index_id = i.index_id AND ic.partition_ordinal = 1
JOIN sys.columns c        ON c.object_id = t.object_id AND c.column_id = ic.column_id
ORDER BY t.name;

/* 5 · Do the vocabularies we need exist, and how are they spelled? ---------- *
   Terminology dimensions are small; this is a catalogue-level question about
   vocabulary labels, not a patient query.                                     */
SELECT Type AS vocabulary, COUNT(*) AS codes
FROM DiagnosisTerminologyDim
GROUP BY Type
ORDER BY codes DESC;
