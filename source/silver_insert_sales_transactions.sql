
-- silver_insert : INSÈRE une nouvelle version dans Silver pour
--   - les transactions nouvelles (inconnues de Silver),
--   - les transactions modifiées (dont l'ancienne version vient d'être fermée par silver_update).
-- Les noms de colonnes sont lus dans la table de paramètres (param_tables).

-- 1) Deux variables qui vont contenir les formules de hash, écrites en texte.
DECLARE OR REPLACE VARIABLE key_expr    STRING;
DECLARE OR REPLACE VARIABLE change_expr STRING;

-- 2) Formule du hash de CLÉ (identique à silver_update).
SET VAR key_expr = (
  SELECT concat('sha2(to_json(struct(b.', replace(key_columns, ',', ',b.'), ')), 256)')
  FROM db_test_sonia.sch_silver.param_tables
  WHERE table_name = 'sales_transactions');

-- 3) Formule du hash de CHANGEMENT (identique à silver_update).
SET VAR change_expr = (
  SELECT concat('sha2(to_json(struct(b.', replace(change_columns, ',', ',b.'), ')), 256)')
  FROM db_test_sonia.sch_silver.param_tables
  WHERE table_name = 'sales_transactions');

-- 4) On assemble la requête INSERT en texte, puis on l'exécute.
--    BY NAME    : chaque valeur va dans la colonne qui porte le même nom.
--    SELECT b.* : toutes les colonnes de Bronze, plus les 4 colonnes techniques
--                 (_key_hash, _change_hash, valid_from, valid_to).
--    LEFT JOIN  : on cherche la version OUVERTE de la même clé dans Silver.
--    WHERE      : on garde la ligne si
--                   - elle n'existe pas encore en Silver (t._key_hash IS NULL) : nouvelle

