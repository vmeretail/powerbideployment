IF OBJECT_ID('dbo.[pocSalesBasketHeaderView]', 'V') IS NOT NULL 
  DROP VIEW dbo.[pocSalesBasketHeaderView]; 
GO; 

CREATE VIEW [dbo].[pocSalesBasketHeaderView]
AS
SELECT 
	[Basket ID] = salestransactioncompleted.AggregateId,
	[Store Id] = salestransactioncompleted.StoreId,
	[Sale Date] = salestransactioncompleted.CompletedDate,
	[Sale Time] = CONVERT(TIME, salestransactioncompleted.CompletedDateTime), 
	[Sales Quantity] = salestransactioncompleted.ProductQuantity,
	[Sales Line Total Inc] = TotalRetailValueInc,
	[Sales Line Total Ex] = TotalRetailValueEx,
	[Total Unit Cost] = salestransactioncompleted.TotalCost,
	[Total Sales Margin Value] = salestransactioncompleted.MarginValue,
	[Margin%]  = salestransactioncompleted.MarginPercent,
	[Is EFT] = CASE WHEN ISNULL(salestransactioncompleted.PaymentType, 'Cash') IN ('Credit Card', 'Electron', 'Maestro', 'Delta') THEN 1 ELSE 0 END,
	salestransactioncompleted.PaymentType [Payment Type],
	[Amount Paid]				= ISNULL(salestransactioncompleted.AmountPaid, 0),
	[Change Amount]				= ISNULL(salestransactioncompleted.ChangeGiven, 0),
	[Payment Was Voided]		= salestransactioncompleted.AmountToPayWasVoided,
	[Cashback Amount]            =ISNULL(salestransactioncompleted.CashbackAmount, 0),
	[Promotion Amount Applied]	= ISNULL(salestransactioncompleted.PromotionAmountApplied, 0),
	[Is Refund]					= salestransactioncompleted.IsRefund,
	[Line Count] =				salestransactioncompleted.SalesTransactionLineCount,
	[TillId] = salestransactioncompleted.tillNumber,
	salestransactioncompleted.transactionNumber,
	salestransactioncompleted.transactionId,
	StoreProjectionState.StoreReportingId
FROM salestransactioncompleted
inner join StoreProjectionState on StoreProjectionState.StoreId = salestransactioncompleted.StoreId
