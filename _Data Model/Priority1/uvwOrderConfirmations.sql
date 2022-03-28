CREATE OR ALTER VIEW uvwOrderConfirmations
AS
    SELECT 
		os.[Date] [Date],
		oc.OrderNumber [Order Number],
		COUNT(oc.OrderNumber) [Confirmations Received],
		oc.SocietyNumber [Society Number],
		CONVERT(INT, os.StoreNumber) [Store Number],
		s.[Name] [Store Name],
		CASE oc.[Status]
			WHEN 'R' THEN 'Received'
			WHEN 'E' THEN 'Error'
		END [Status],
		os.SupplierName [Supplier],
		MAX(oc.[Date]) [File Datetime]
	FROM OrderSchedule os
	INNER JOIN store s ON CONVERT(INT, os.StoreNumber) = CONVERT(INT, s.ExternalStoreNumber)
	INNER JOIN StoreProjectionState sps ON s.StoreId = Sps.StoreId AND sps.StoreStatus = 2
	LEFT JOIN ( 
		SELECT 
			oc.OrderNumber,
			oc.SocietyNumber,
			oc.StoreNumber,
			oc.[Status],
			oc.[Date],
			o.ExternalSupplierId
		FROM OrderConfirmation oc
		INNER JOIN [order] o ON oc.OrderNumber = o.ExternalOrderId
		INNER JOIN store s ON o.StoreId = s.StoreId AND CONVERT(INT, oc.StoreNumber) = CONVERT(INT, s.ExternalStoreNumber)
	) oc ON CONVERT(DATE, os.[Date]) = CONVERT(DATE, oc.[Date]) AND CONVERT(INT, os.StoreNumber) = CONVERT(INT, oc.StoreNumber) AND os.SupplierName = oc.ExternalSupplierId 
	WHERE os.Date < GETDATE()
	GROUP BY
		os.[Date],
		oc.OrderNumber,
		oc.SocietyNumber,
		os.StoreNumber,
		s.[Name],
		oc.[Status],
		os.SupplierName