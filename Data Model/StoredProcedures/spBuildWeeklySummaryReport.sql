CREATE OR ALTER PROCEDURE [dbo].[spBuildWeeklySummaryReport] @dateFrom DATETIME
AS
	DELETE FROM SalesSummaryByProduct where completeddate >= @dateFrom

	INSERT INTO SalesSummaryByProduct
	(
		[AggregateId],
		[StoreId],
		[CompletedDate],
		[HierarchyNodeId],
		[OrganisationProductId],
		[TaxRate],
		[PaymentType],
		[Reason Code Type],
		[TransactionStatus],
		[DiscountType],
		[Tax Rate Count],
		[SALE exc VAT],
		[SALE inc VAT],
		[Margin £],
		[YearWeekNumber],
		[Year],
		[Week],
		[DayOfWeekShort],
		[DayOfWeek]
	)
	SELECT
		salestransactioncompleted.AggregateId,
		StoreId,
		completedDate,
		ISNULL(subSectionId, sectionId),
		OrganisationProductId,
		TaxRate,
		PaymentType,
		ReasonCodes.[Type] [Reason Code Type],
		TransactionStatus,
		DiscountType,
		COUNT(TaxRate) [Tax Rate Count],
		SUM(LineTotalExc) [SALE exc VAT],
		SUM(LineTotalInc) [SALE inc VAT],
		SUM(LineTotalMarginValue) [Margin £],
		YearWeekNumber,
		[Year],
		WeekNumber,
		DayOfWeekShort,
		DayOfWeekNumber
	FROM salestransactioncompleted WITH(nolock)
	INNER JOIN salestransactionline WITH(nolock) ON salestransactioncompleted.AggregateId = salestransactionline.AggregateId
	INNER JOIN calendar ON calendar.Date = salestransactioncompleted.CompletedDate
	LEFT OUTER JOIN ReasonCodes ON salestransactionline.ReasonDescription Is NOT NULL AND salestransactionline.ReasonDescription = ReasonCodes.Code
	LEFT OUTER JOIN (
		SELECT aggregateId, storeProductId, promotionId, SUM(givenaway) givenaway
		FROM salestransactionpromotioninformation WITH(nolock)
		GROUP BY aggregateId, storeProductId, promotionId
	) salestransactionpromotioninformation ON salestransactionpromotioninformation.aggregateId = salestransactionline.aggregateId AND salestransactionpromotioninformation.storeProductId =salestransactionline.storeProductId
	LEFT OUTER JOIN promotion WITH(nolock) ON salestransactionpromotioninformation.promotionId = promotion.PromotionId
	WHERE completedDate >= @dateFrom AND ISNULL(subSectionId, sectionId) IS NOT NULL
	GROUP BY
		salestransactioncompleted.AggregateId,
		StoreId,
		completedDate,
		subSectionId,
		sectionId,
		OrganisationProductId,
		TaxRate,
		PaymentType,
		ReasonCodes.[Type],
		TransactionStatus,
		DiscountType,
		promotion.PromotionId,
		YearWeekNumber,
		[Year],
		WeekNumber,
		DayOfWeekShort,
		DayOfWeekNumber