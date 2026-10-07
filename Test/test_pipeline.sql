-- ============================================================
-- TEST 1 : Les colonnes techniques de silver existent avec le bon type
-- (c'est l'erreur qu'on a eue : un hash tombe dans une colonne date)
-- Attendu : 0 ligne = PASS
-- ============================================================

SELECT t.column_name, t.type_attendu, c.data_type AS type_reel
FROM (VALUES
        ('_key_hash',    'STRING'),
        ('_change_hash', 'STRING'),
        ('valid_from',   'TIMESTAMP'),
        ('valid_to',     'TIMESTAMP')
     ) AS t(column_name, type_attendu)
LEFT JOIN db_test_sonia.information_schema.columns c
  ON c.table_schema = 'sch_silver'
  AND c.table_name = 'sales_transactions'
  AND c.column_name = t.column_name
WHERE c.data_type IS NULL OR c.data_type <> t.type_attendu;


-- ============================================================
-- TEST 2 : Silver = colonnes de bronze + les 4 colonnes techniques
-- Attendu : 0 ligne = PASS
-- ============================================================

WITH brz AS (
  SELECT column_name, data_type
  FROM db_test_sonia.information_schema.columns
  WHERE table_schema = 'sch_bronze' AND table_name = 'sales_transactions'
),
slv AS (
  SELECT column_name, data_type
  FROM db_test_sonia.information_schema.columns
  WHERE table_schema = 'sch_silver' AND table_name = 'sales_transactions'
)
SELECT COALESCE(b.column_name, s.column_name) AS column_name,
       b.data_type AS type_bronze, s.data_type AS type_silver
FROM brz b
FULL OUTER JOIN slv s ON b.column_name = s.column_name
WHERE (b.column_name IS NULL
       AND s.column_name NOT IN ('_key_hash', '_change_hash', 'valid_from', 'valid_to'))
   OR s.column_name IS NULL
   OR b.data_type <> s.data_type;


-- ============================================================
-- TEST 3 : _key_hash est bien le hash du transactionID
-- Attendu : 0 ligne = PASS
-- (on ne recalcule pas _change_hash ici : l'ordre des colonnes de
--  silver differe de celui de bronze, le hash recalcule serait different)
-- ============================================================

SELECT transactionID, _key_hash
FROM db_test_sonia.sch_silver.sales_transactions
WHERE _key_hash <> sha2(to_json(struct(transactionID)), 256);


-- ============================================================
-- TEST 4 : Une transaction n'a jamais 2 versions ouvertes
-- Attendu : 0 ligne = PASS
-- ============================================================

SELECT transactionID, COUNT(*) AS nb_versions_ouvertes
FROM db_test_sonia.sch_silver.sales_transactions
WHERE valid_to IS NULL
GROUP BY transactionID
HAVING COUNT(*) > 1;


-- ============================================================
-- TEST 5 : Non-chevauchement des periodes de validite
-- Attendu : 0 ligne = PASS
-- (pour la demo : remplacer la table par sales_transactions_overlap_test,
--  le test doit alors afficher des lignes)
-- ============================================================

WITH versions AS (
  SELECT
    transactionID, valid_from, valid_to,
    LEAD(valid_from) OVER (PARTITION BY transactionID ORDER BY valid_from) AS next_valid_from
  FROM db_test_sonia.sch_silver.sales_transactions
)
SELECT *
FROM versions
WHERE next_valid_from IS NOT NULL
  AND (valid_to IS NULL OR valid_to > next_valid_from);


-- ============================================================
-- TEST 6 : Aucune version fermee sans version suivante
-- (detecte un silver_update reussi suivi d'un silver_insert en echec)
-- Attendu : 0 ligne = PASS
-- ============================================================

WITH versions AS (
  SELECT
    transactionID, valid_from, valid_to,
    LEAD(valid_from) OVER (PARTITION BY transactionID ORDER BY valid_from) AS next_valid_from
  FROM db_test_sonia.sch_silver.sales_transactions
)
SELECT *
FROM versions
WHERE valid_to IS NOT NULL
  AND next_valid_from IS NULL;