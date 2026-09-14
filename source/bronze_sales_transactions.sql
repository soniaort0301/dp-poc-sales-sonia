CREATE OR REPLACE TABLE db_test_sonia.sch_bronze.sales_transactions
AS
SELECT 
  *,
  current_timestamp() AS _ingestion_timestamp,
  'samples.bakehouse.sales_transactions' AS _source_table,
  'sch_bronze'AS _layer
FROM samples.bakehouse.sales_transactions;