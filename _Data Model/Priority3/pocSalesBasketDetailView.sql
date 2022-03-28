CREATE OR ALTER VIEW [dbo].[pocSalesBasketDetailView]
AS
SELECT 
	[Basket ID]				= salestransactioncompleted.AggregateId,
	[Store ID]				= salestransactioncompleted.StoreID,
	[Sale Date Time]		= salestransactioncompleted.CompletedDateTime,
	[Sale Date]				= salestransactioncompleted.CompletedDate,
	[Sale Time]				= CONVERT(TIME, salestransactioncompleted.CompletedDateTime), 
	[Sale Hour]				= DATEPART(HOUR, salestransactioncompleted.CompletedDateTime), 
	[BasketLineNumber]		= salestransactionline.LineNumber,
	[Sales Quantity]		= CASE WHEN salestransactionline.IsPriceEnquiry = 1 THEN 0 ELSE salestransactionline.Quantity END,
	[ProductId]			= salestransactionline.StoreProductId,
	[ProductReportingId] = pocProductsView.ProductReportingId,
	[Organisation Product Id] = salestransactionline.OrganisationProductId,
	[Sales Line Total Inc]	= CASE WHEN salestransactionline.IsPriceEnquiry = 1 THEN 0 
								   WHEN salestransactionline.TransactionStatus = 'V' THEN salestransactionline.LineTotalInc
								   ELSE salestransactionline.LineTotalInc END,	
	[Sales Line Total Ex]	= CASE 
								WHEN salestransactionline.IsPriceEnquiry = 1 THEN 0 
								WHEN salestransactionline.TransactionStatus = 'V' THEN salestransactionline.LineTotalInc / (salestransactionline.TaxRate + 1)
								ELSE salestransactionline.LineTotalInc / (salestransactionline.TaxRate + 1) END,	
	salestransactionline.TaxRate,
	[Sales Line ID]			= salestransactionline.EventId,
	[Reason Description]	= salestransactionline.ReasonDescription,
	[Transaction Status]	= salestransactionline.TransactionStatus,
	[Is Price Enquiry]		= salestransactionline.IsPriceEnquiry,
	[Is Price Override]		= salestransactionline.IsPriceOverride,
	[Is Refund]				= salestransactionline.IsRefund,
	[Original Price]		= salestransactionline.OriginalPrice,
	[Is Age Check]			= CASE WHEN salestransactionline.SubType = 'AC' THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END,
	[Is Unknown Product]	= salestransactionline.IsUnknownProduct,
	[External Product Id]		= salestransactionline.ExternalProductId,
	salestransactionline.LineTotalMarginValue as [SalesMarginValue],
	salestransactionline.UnitMarginValue as [UnitMarginValue],
	salestransactionline.UnitMarginValue - pocProductsView.MarginValue as [MarginCheck],
	salestransactionline.subSectionId,
	case 
		WHEN salestransactionpromotioninformation.aggregateId IS NULL THEN 0
		ELSE 1
	END as IsOnPromotion,
	case 
		WHEN salestransactionpromotioninformation.aggregateId IS NULL THEN pocProductsView.ProductDescription
		ELSE pocProductsView.ProductDescription + ' (On Promotion)'
	END as ProductDescriptionOnPromotion
	FROM salestransactioncompleted
    INNER JOIN salestransactionline on salestransactionline.aggregateid = salestransactioncompleted.AggregateId
	left outer join salestransactionpromotioninformation on salestransactionpromotioninformation.aggregateId = salestransactionline.aggregateId 
															AND salestransactionpromotioninformation.storeProductId = salestransactionline.storeProductId
	left outer join pocProductsView on pocProductsView.ProductId = salestransactionline.storeProductId
	WHERE salestransactionline.IsPriceEnquiry != 1 
		  AND CASE WHEN salestransactionline.IsUnknownProduct = 1 THEN 1 ELSE salestransactionline.LineTotalExc END != 0
		  and salestransactionline.IsRefund != 1
		  and ISNULL(pocProductsView.CostPrice, 0.01) > 0.001 -- This is to filter out lottery type products which have a cost price of 0.001