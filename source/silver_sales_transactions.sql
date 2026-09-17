MERGE INTO db_test_sonia.sch_silver.sales_transactions AS target
USING (
  SELECT 
    *,
    current_timestamp() AS _updated_at
  FROM db_test_sonia.sch_bronze.sales_transactions
  WHERE ingestion_date = :batch_date
) AS source
ON target.transactionID = source.transactionID

WHEN MATCHED THEN 
  UPDATE SET
    target.customerID = source.customerID,
    target.franchiseID = source.franchiseID,
    target.dateTime = source.dateTime,
    target.product = source.product,
    target.quantity = source.quantity,
    target.unitPrice = source.unitPrice,
    target.totalPrice = source.totalPrice,
    target.paymentMethod = source.paymentMethod,
    target.ingestion_date = source.ingestion_date,
    target._updated_at = source._updated_at

WHEN NOT MATCHED THEN 
  INSERT (
    transactionID, customerID, franchiseID, dateTime, product, 
    quantity, unitPrice, totalPrice, paymentMethod, ingestion_date,
    _inserted_at, _updated_at
  )
  VALUES (
    source.transactionID, source.customerID, source.franchiseID, source.dateTime, source.product,
    source.quantity, source.unitPrice, source.totalPrice, source.paymentMethod, source.ingestion_date,
    current_timestamp(), source._updated_at
  );