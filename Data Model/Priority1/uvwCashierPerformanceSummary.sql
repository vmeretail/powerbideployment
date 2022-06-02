IF OBJECT_ID('dbo.[uvwCashierPerformanceSummary]', 'V') IS NOT NULL 
  DROP VIEW dbo.[uvwCashierPerformanceSummary]; 
GO; 

CREATE VIEW [dbo].[uvwCashierPerformanceSummary]
AS
SELECT
	[trading] [Trading Date],
	futuredate,
	StoreId,
	[tr_item] [Item Number],
	[tr_desc] [Cashier Name],
	[tr_ccnt] [Cancels Count],
	[tr_voidc] [Voids Count],
	[tr_custc] [Customers Count],
	[tr_itemc] [Items Count],
	[tr_refc] [Refunds Count],
	[tr_ccval] [Cancels Value],
	[tr_voidv] [Voids Value],
	[tr_salev] [Sales Value],
	[tr_refv] [Refunds Value],
	StoreReportingId
FROM [CashierPerformanceSummary]

