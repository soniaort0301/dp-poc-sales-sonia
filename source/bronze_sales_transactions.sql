INSERT INTO db_test_sonia.sch_bronze.sales_transactions
REPLACE WHERE ingestion_ts = CAST(:batch_ts AS TIMESTAMP)
SELECT
  s.*,
  CAST(:batch_ts AS TIMESTAMP) AS ingestion_ts
FROM samples.bakehouse.sales_transactions s;