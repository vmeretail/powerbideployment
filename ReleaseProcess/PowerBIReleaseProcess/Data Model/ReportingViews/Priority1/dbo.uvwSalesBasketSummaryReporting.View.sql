CREATE OR ALTER VIEW [dbo].[uvwSalesBasketSummaryReporting]
AS

select 
	STC.aggregateId,
	[Store ID]		= STC.StoreId,
	[Sale Date]		= STC.CompletedDateTime,
	BasketTotalBeforeDeductions,
	-- This is to handle sites where tender lines are not being uploaded yet so there is no amount paid
	AmountPaid = CASE AmountPaid WHEN 0 THEN BasketTotalBeforeDeductions ELSE AmountPaid END, 
	SalesTransactionLineCount,
	ProductQuantity
from 
salestransactioncompleted 	STC