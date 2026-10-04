INSERT INTO db_test_sonia.sch_silver.sales_transactions
SELECT
  b.*,
  sha2(to_json(struct(b.transactionID)), 256) AS _key_hash,
  sha2(to_json(struct(b.* EXCEPT (ingestion_ts))), 256) AS _change_hash,
  current_timestamp() AS valid_from,
  CAST(NULL AS TIMESTAMP) AS valid_to
FROM db_test_sonia.sch_bronze.sales_transactions b
LEFT JOIN db_test_sonia.sch_silver.sales_transactions t
  ON sha2(to_json(struct(b.transactionID)), 256) = t._key_hash
  AND t.valid_to IS NULL
WHERE b.ingestion_ts = CAST(:batch_ts AS TIMESTAMP)
  AND (t.transactionID IS NULL
       OR sha2(to_json(struct(b.* EXCEPT (ingestion_ts))), 256) <> t._change_hash);