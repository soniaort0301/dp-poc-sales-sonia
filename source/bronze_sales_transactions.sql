INSERT INTO db_test_sonia.sch_bronze.sales_transactions
REPLACE WHERE ingestion_date = :batch_date AND ingestion_hour = :batch_hour
SELECT 
  *, 
  :batch_date AS ingestion_date,
  :batch_hour AS ingestion_hour
FROM samples.bakehouse.sales_transactions;