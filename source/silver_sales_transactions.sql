CREATE OR REPLACE TABLE db_test_sonia.sch_silver.sales_transactions
AS
SELECT 
  * EXCEPT (_ingestion_timestamp, _source_table, _layer),
  current_timestamp() AS _ingestion_timestamp,
  'db_test_sonia.sch_bronze.sales_transactions' AS _source_table,
  'silver' AS _layer
FROM db_test_sonia.sch_bronze.sales_transactions;