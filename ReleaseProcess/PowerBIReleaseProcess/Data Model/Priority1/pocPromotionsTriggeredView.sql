CREATE OR ALTER   VIEW [dbo].[pocPromotionsTriggeredView]
AS
WITH Promotions AS (
	SELECT 
		salestransactioncompleted.AggregateId,
		CompletedDate, 
		CompletedDateTime, 
		StoreProjectionState.StoreId,
		StoreProjectionState.StoreReportingId,
		StoreName,
		StoreProductStateProjection.storeProductId as ProductId,
		StoreProductStateProjection.StoreProductReportingId as ProductReportingId,
		totalretailvalue, 
		quantity,
		1 [Is Promotion Line],
		ExternalPromotionId,
		promotion.promotionId,
		offerSequenceNumber,
		promotion.[Description],
		[StartDateTime],
		[EndDateTime],
		[Reclaim], 
		givenaway 
	FROM promotion
	INNER JOIN salestransactionpromotioninformation ON salestransactionpromotioninformation.promotionId = promotion.PromotionId
	INNER JOIN salestransactioncompleted ON salestransactioncompleted.AggregateId = salestransactionpromotioninformation.aggregateId
	INNER JOIN StoreProductStateProjection ON StoreProductStateProjection.StoreProductId = salestransactionpromotioninformation.storeProductId
	INNER JOIN StoreProjectionState ON StoreProjectionState.StoreReportingId = StoreProductStateProjection.StoreReportingId
),
Sales AS (
	SELECT 
		salestransactioncompleted.AggregateId,
		CompletedDate,
		CompletedDateTime, 
		StoreProjectionState.StoreId,
		StoreProjectionState.StoreReportingId,		
		StoreName,
		StoreProductStateProjection.storeProductId,
		StoreProductStateProjection.StoreProductReportingId,
		LineTotalInc,
		Quantity,	
		0 [Is Promotion Line],
		NULL ExternalPromotionId,
		NULL promotionId,
		NULL offerSequenceNumber,
		'No Promotion' [Description],
		NULL [StartDateTime],
		NULL [EndDateTime],
		NULL [Reclaim],
		0 givenaway
	FROM salestransactioncompleted
	INNER JOIN salestransactionline on salestransactionline.aggregateid = salestransactioncompleted.AggregateId
	INNER JOIN StoreProductStateProjection ON StoreProductStateProjection.StoreProductId = salestransactionline.storeProductId
	INNER JOIN StoreProjectionState on StoreProjectionState.StoreReportingId = StoreProductStateProjection.StoreReportingId
	WHERE NOT EXISTS (
		SELECT * FROM Promotions
		WHERE Promotions.AggregateId = salestransactioncompleted.AggregateId AND Promotions.ProductId = StoreProductStateProjection.StoreProductId
	)
)
SELECT 
	AggregateId,
	CompletedDate, 
	CompletedDateTime, 
	StoreId,
	StoreReportingId,
	StoreName,
	ProductId,
	ProductReportingId,
	SUM(totalretailvalue) totalretailvalue, 
	SUM(quantity) quantity,
	[Is Promotion Line],
	ExternalPromotionId,
	promotionId,
	offerSequenceNumber,
	[Description],
	MIN([StartDateTime]) [StartDateTime],
    MAX([EndDateTime]) [EndDateTime],
    [Reclaim], 
	SUM(givenaway) givenaway
FROM (
	SELECT * 
	FROM Promotions
	
	UNION ALL
	
	SELECT * 
	FROM Sales
) allProducts
GROUP BY
	AggregateId,
	CompletedDate, 
	CompletedDateTime, 
	StoreId,
	StoreReportingId,
	StoreName,
	ProductId,
	ProductReportingId,
	[Is Promotion Line],
	ExternalPromotionId,
	promotionId,
	offerSequenceNumber,
	[Description],
    [Reclaim]
