MERGE INTO db_test_sonia.sch_silver.sales_transactions AS target
USING (
  SELECT 
    *,
    current_timestamp() AS _updated_at
  FROM db_test_sonia.sch_bronze.sales_transactions
  WHERE ingestion_date = :batch_date AND ingestion_hour = :batch_hour
) AS source
ON target.transactionID = source.transactionID

WHEN MATCHED AND (
    target.customerID <> source.customerID OR
    target.franchiseID <> source.franchiseID OR
    target.dateTime <> source.dateTime OR
    target.product <> source.product OR
    target.quantity <> source.quantity OR
    target.unitPrice <> source.unitPrice OR
    target.totalPrice <> source.totalPrice OR
    target.paymentMethod <> source.paymentMethod
) THEN 
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
    target.ingestion_hour = source.ingestion_hour,
    target._updated_at = source._updated_at

WHEN NOT MATCHED THEN 
  INSERT (
    transactionID, customerID, franchiseID, dateTime, product, 
    quantity, unitPrice, totalPrice, paymentMethod, ingestion_date, ingestion_hour,
    _inserted_at, _updated_at
  )
  VALUES (
    source.transactionID, source.customerID, source.franchiseID, source.dateTime, source.product,
    source.quantity, source.unitPrice, source.totalPrice, source.paymentMethod, source.ingestion_date, source.ingestion_hour,
    current_timestamp(), source._updated_at
  );