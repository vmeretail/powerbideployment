CREATE OR ALTER VIEW [dbo].[uvwSalesBasketDetailReporting]
AS


   SELECT 
	--top 100
	[Basket ID]				= sh.AggregateId,
	[Store ID]				= sh.StoreID,
	[Sale Date]				= sh.CompletedDate,
	[Sale Time]				= CONVERT(TIME, sh.CompletedDateTime), 
	[BasketLineNumber]		= SL.lineNumber,
	[Sales Quantity]		= CASE WHEN sl.IsPriceEnquiry = 1 THEN 0 ELSE sl.Quantity END,
	[Sales Value Gross]		= CASE WHEN sl.IsPriceEnquiry = 1 THEN 0 ELSE sl.StandardRetailPriceInc END,		--Per Item including tax
	[Sales Value Net]		= CASE WHEN sl.IsPriceEnquiry = 1 THEN 0 ELSE sl.StandardRetailPriceEx END,			--Per Item excluding tax
	[Sales Value Line Gross] = CASE WHEN sl.IsPriceEnquiry = 1 THEN 0 ELSE sl.StandardRetailPriceInc * sl.Quantity END,
	[Sales Value Line Net]	= CASE WHEN sl.IsPriceEnquiry = 1 THEN 0 ELSE sl.StandardRetailPriceEx * sl.Quantity END,
	[Unit Cost]				= CASE WHEN sl.IsPriceEnquiry = 1 THEN 0 ELSE sl.UnitCost END,						--Unit Cost
	[Sales Tax Rate ID]		= OP.taxRateId,
	[Product ID]			= SL.StoreProductId,
	[Product Description]	= productDescription,
	[Sales Line Total]		= CASE WHEN sl.IsPriceEnquiry = 1 THEN 0 ELSE sl.LIneTotalInc END,
	[Sales Margin]			= CASE WHEN sl.IsPriceEnquiry = 1 THEN 0 ELSE sl.LIneTotalInc - (sl.UnitCost * sl.Quantity) END, --This is what the customer actually paid
	[Sales MarginPct]		= 0.00, --TODO: Need to review this. a % of what?
	[Org Product ID]		= SL.organisationProductId,
	[Sales Line ID]			= SL.EventId,
	[Department ID]	        = SL.departmentId,
	[Section ID]			= SL.sectionId,
	[Subsection ID]			= SL.subsectionId,
	[Item Size]				= OP.ItemSize,
	[Reason Description]	= sl.ReasonDescription,
	[Transaction Status]	= sl.TransactionStatus,
	[Is Price Enquiry]		= sl.IsPriceEnquiry,
	[Is Price Override]		= sl.IsPriceOverride,
	[Is Refund]				= sl.IsRefund,
	[Original Price]		= sl.OriginalPrice,
	[Is Age Check]			= CASE WHEN sl.SubType = 'AC' THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END,
	[Is Unknown Product]	= sl.IsUnknownProduct,
	[External Product Code] = sl.ExternalProductId

FROM 
	salestransactioncompleted SH
	INNER JOIN salestransactionline SL on SL.aggregateid = SH.AggregateId
	INNER JOIN	organisationproduct OP on SL.organisationProductId = OP.OrganisationProductId

