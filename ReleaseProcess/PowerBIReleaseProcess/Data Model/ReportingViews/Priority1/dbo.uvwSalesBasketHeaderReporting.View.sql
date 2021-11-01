CREATE OR ALTER VIEW [dbo].[uvwSalesBasketHeaderReporting]
AS

   SELECT 
	[Basket ID]				= STC.AggregateId,
	[Store ID]				= STC.StoreID,
	[Store Name]				= store.[Name],
	[Store Number]				= store.[ExternalStoreId],
	[Sale Date]				= CASE STC.CompletedDate 
									WHEN '0001-01-01' THEN CONVERT(DATE,STC.StartedDateTime)
									ELSE STC.CompletedDate
									END,
	[Sale Time]				= CONVERT(TIME, CASE STC.CompletedDateTime 
									WHEN '0001-01-01 00:00:00.0000000' THEN STC.StartedDateTime
									ELSE STC.CompletedDateTime
									END), 	
	[Sales Quantity]		= SUM(CASE WHEN sl.IsPriceEnquiry = 1 THEN 0 ELSE sl.Quantity END),
	[Sales Value Gross]		= SUM(CASE WHEN sl.IsPriceEnquiry = 1 THEN 0 ELSE sl.StandardRetailPriceInc END),		--Per Item including tax
	[Sales Value Net]		= SUM(CASE WHEN sl.IsPriceEnquiry = 1 THEN 0 ELSE sl.StandardRetailPriceEx END),			--Per Item excluding tax
	[Sales Line Total]		= SUM(CASE WHEN sl.IsPriceEnquiry = 1 THEN 0 ELSE sl.LIneTotalInc END),
	[Sales Margin]			= SUM(
									CASE WHEN sl.IsPriceEnquiry = 1 THEN 0 
										 WHEN PH.Field = 6 AND PH.Value = 'N' THEN 0	
										ELSE (((StandardRetailPriceEx) / 100) * ((StandardRetailPriceEx - UnitCost) / StandardRetailPriceEx) * 100)
										END),
	[Transaction ID]			= STC.transactionId,
	[Transaction Number]		= STC.transactionNumber,
	[Operator ID]				= STC.operatorId,
	[Till Number]				= STC.tillNumber,
	[Is EFT]					= CASE WHEN ISNULL(STC.PaymentType, 'Cash') IN ('Credit Card', 'Electron', 'Maestro', 'Delta') THEN 1 ELSE 0 END,
	[Amount Paid]				= ISNULL(STC.AmountPaid, 0),
	[Change Amount]				= ISNULL(STC.ChangeGiven, 0),
	[Payment Was Voided]		= STC.AmountToPayWasVoided,
	[Cashback Amount]            = ISNULL(STC.CashbackAmount, 0),
	[Promotion Amount Applied]	= ISNULL(STC.PromotionAmountApplied, 0),
	[Is Refund]					= CASE WHEN STC.AmountRefunded > 0 THEN 1 ELSE 0 END,
	[Has MPL]					= CASE WHEN (SP.[MPLHeight] * SP.[MPLWidth] * SP.[MPLDepth]) > 0 THEN 1 ELSE 0 END
FROM 
	salestransactioncompleted STC
    INNER JOIN salestransactionline SL on sl.aggregateid = stc.AggregateId
	INNER JOIN organisationproduct OP on OP.OrganisationProductId = SL.organisationProductId
	INNER JOIN storeproduct SP on SP.StoreProductId = SL.storeProductId
	INNER JOIN producthierarchy PH on OP.ProductHierarchyNodeId = PH.ProductHierarchyId
	INNER JOIN store ON STC.StoreID = store.StoreId
WHERE StandardRetailPriceEx > 0
GROUP BY STC.AggregateId, STC.StoreID,store.[Name],store.[ExternalStoreId],STC.CompletedDate,STC.CompletedDateTime,STC.StartedDateTime,
STC.transactionId,STC.transactionNumber,STC.operatorId,STC.tillNumber,STC.PaymentType,STC.AmountPaid,
STC.ChangeGiven,STC.AmountToPayWasVoided, STC.CashbackAmount,STC.PromotionAmountApplied, STC.AmountRefunded, SP.MPLDepth, SP.MPLHeight, SP.MPLWidth