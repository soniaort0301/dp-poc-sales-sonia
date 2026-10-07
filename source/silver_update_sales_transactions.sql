-- silver_update : FERME la version ouverte d'une transaction qui a changé (remplit valid_to).
-- La nouvelle version sera créée ensuite par silver_insert.
-- Les noms de colonnes sont lus dans la table de paramètres (param_tables).

-- 1) Deux variables qui vont contenir les formules de hash, écrites en texte.
DECLARE OR REPLACE VARIABLE key_expr    STRING;
DECLARE OR REPLACE VARIABLE change_expr STRING;

-- 2) Formule du hash de CLÉ, fabriquée depuis la fiche.
--    Résultat : sha2(to_json(struct(b.transactionID)), 256)
SET VAR key_expr = (
  SELECT concat('sha2(to_json(struct(b.', replace(key_columns, ',', ',b.'), ')), 256)')
  FROM db_test_sonia.sch_silver.param_tables
  WHERE table_name = 'sales_transactions');

-- 3) Formule du hash de CHANGEMENT, fabriquée depuis la fiche.
SET VAR change_expr = (
  SELECT concat('sha2(to_json(struct(b.', replace(change_columns, ',', ',b.'), ')), 256)')
  FROM db_test_sonia.sch_silver.param_tables
  WHERE table_name = 'sales_transactions');

-- 4) On assemble la requête UPDATE en texte, puis on l'exécute.
--    "Ferme les versions OUVERTES de Silver pour lesquelles Bronze a, dans ce batch,
--     une ligne avec la MÊME clé mais un contenu DIFFÉRENT."
EXECUTE IMMEDIATE concat(
  'UPDATE db_test_sonia.sch_silver.sales_transactions AS t ',
  'SET valid_to = current_timestamp() ',
  'WHERE valid_to IS NULL AND EXISTS (',
  'SELECT 1 FROM db_test_sonia.sch_bronze.sales_transactions b ',
  'WHERE b.ingestion_ts = :bts ',
  'AND ', key_expr, ' = t._key_hash ',
  'AND ', change_expr, ' <> t._change_hash)')
USING (CAST(:batch_ts AS TIMESTAMP) AS bts);