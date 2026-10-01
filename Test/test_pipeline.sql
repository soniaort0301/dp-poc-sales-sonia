

-- ============================================================
-- TEST 1 : Verification du schema (colonnes source vs cible)
-- Objectif : detecter une evolution des endpoints (colonne
-- ajoutee / retiree / renommee) avant qu'elle ne casse le MERGE.
-- Point de vigilance (bug corrige) : en Unity Catalog,
-- information_schema est scopee par catalogue, il faut la
-- prefixer par le nom du catalogue (samples.information_schema...,
-- db_test_sonia.information_schema...) plutot que de filtrer sur
-- table_catalog.
-- ============================================================
SELECT
  'source (samples.bakehouse)' AS endpoint,
  column_name,
  data_type
FROM samples.information_schema.columns
WHERE table_schema = 'bakehouse'
  AND table_name   = 'sales_transactions'

UNION ALL

SELECT
  'bronze (db_test_sonia.sch_bronze)' AS endpoint,
  column_name,
  data_type
FROM db_test_sonia.information_schema.columns
WHERE table_schema = 'sch_bronze'
  AND table_name   = 'sales_transactions'

UNION ALL

SELECT
  'silver (db_test_sonia.sch_silver)' AS endpoint,
  column_name,
  data_type
FROM db_test_sonia.information_schema.columns
WHERE table_schema = 'sch_silver'
  AND table_name   = 'sales_transactions'

ORDER BY endpoint, column_name;

-- Attendu : les colonnes metier (transactionID, customerID,
-- franchiseID, dateTime, product, quantity, unitPrice,
-- totalPrice, paymentMethod, cardNumber) presentes dans les 3 blocs.
-- Bronze a en plus : _row_hash, ingestion_ts.
-- Silver a en plus : _row_hash, ingestion_ts, valid_from, valid_to.


-- ============================================================
-- TEST 2 : Comptage de lignes AVANT / APRES (par batch)
-- A executer une fois AVANT de lancer le Job (capture "avant"),
-- puis une fois APRES (capture "apres"), avec le meme batch_ts.
-- ============================================================
SELECT
  'bronze' AS table_name,
  COUNT(*) AS nb_lignes
FROM db_test_sonia.sch_bronze.sales_transactions
WHERE ingestion_ts = CAST(:batch_ts AS TIMESTAMP)

UNION ALL

SELECT
  'silver (versions ouvertes touchees par ce batch)' AS table_name,
  COUNT(*) AS nb_lignes
FROM db_test_sonia.sch_silver.sales_transactions
WHERE ingestion_ts = CAST(:batch_ts AS TIMESTAMP);


-- ============================================================
-- TEST 3 : Aucune transaction n'a 2 versions OUVERTES en meme temps
-- (remplace l'ancien test "0 doublon de transactionID", qui n'a
-- plus de sens maintenant que Silver garde volontairement
-- plusieurs versions d'une meme transaction).
-- ============================================================
SELECT
  transactionID,
  COUNT(*) AS nb_versions_ouvertes
FROM db_test_sonia.sch_silver.sales_transactions
WHERE valid_to IS NULL
GROUP BY transactionID
HAVING COUNT(*) > 1;

-- Attendu : 0 ligne retournee = PASS.
-- Toute ligne retournee ici = FAIL : deux versions ouvertes en
-- meme temps pour la meme transaction, a investiguer immediatement.


-- ============================================================
-- TEST 4 : Non-chevauchement des periodes de validite
-- Objectif : pour une transaction historisee, verifier que les
-- periodes [valid_from, valid_to) ne se chevauchent jamais entre
-- deux versions successives.
-- ============================================================
WITH versions AS (
  SELECT
    transactionID,
    valid_from,
    valid_to,
    LEAD(valid_from) OVER (PARTITION BY transactionID ORDER BY valid_from) AS next_valid_from
  FROM db_test_sonia.sch_silver.sales_transactions
)
SELECT *
FROM versions
WHERE valid_to IS NOT NULL
  AND next_valid_from IS NOT NULL
  AND valid_to > next_valid_from;

-- Attendu : 0 ligne retournee = PASS (la periode de fin d'une
-- version n'est jamais apres le debut de la version suivante).


-- ============================================================
-- TEST 5 : Coherence Bronze -> Silver (pour le batch traite)
-- Objectif : verifier qu'aucune transaction nouvelle ou modifiee
-- du batch Bronze n'est absente de Silver.
-- ============================================================
SELECT b.transactionID
FROM db_test_sonia.sch_bronze.sales_transactions b
WHERE b.ingestion_ts = CAST(:batch_ts AS TIMESTAMP)
  AND NOT EXISTS (
    SELECT 1
    FROM db_test_sonia.sch_silver.sales_transactions s
    WHERE s.transactionID = b.transactionID
  );

-- Attendu : 0 ligne retournee = PASS (toute transaction presente
-- dans Bronze pour ce batch a bien au moins une version dans Silver).





