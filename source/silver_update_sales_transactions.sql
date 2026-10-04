UPDATE db_test_sonia.sch_silver.sales_transactions AS t
SET valid_to = current_timestamp()
WHERE valid_to IS NULL
AND EXISTS (
  SELECT 1
  FROM db_test_sonia.sch_bronze.sales_transactions b
  WHERE b.ingestion_ts = CAST(:batch_ts AS TIMESTAMP)
    AND sha2(to_json(struct(b.transactionID)), 256) = t._key_hash
    AND sha2(to_json(struct(b.* EXCEPT (ingestion_ts))), 256) <> t._change_hash
);