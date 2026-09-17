INSERT INTO db_test_sonia.sch_bronze.sales_transactions
REPLACE WHERE ingestion_date = :batch_date
SELECT *, :batch_date AS ingestion_date
FROM samples.bakehouse.sales_transactions;