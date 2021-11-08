CREATE OR ALTER PROCEDURE [dbo].[spBuildWeeklySummaryReport] @dateTo DATETIME = NULL
AS
	SET @dateTo = ISNULL(@dateto, GETDATE())

	DECLARE @startdate DATE = (SELECT DATEADD(DAY, 1, MAX(CompletedDate)) FROM SalesSummaryByProduct)
	DECLARE @enddate DATE = (SELECT DATEADD(DAY, -1, CONVERT(DATE, @dateTo)))

	INSERT INTO SalesSummaryByProduct
	(
		[AggregateId],
		[StoreId],
		[CompletedDate],
		[subSectionId],
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
		subSectionId,
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
	FROM salestransactioncompleted
	INNER JOIN salestransactionline ON salestransactioncompleted.AggregateId = salestransactionline.AggregateId
	INNER JOIN calendar ON calendar.Date = salestransactioncompleted.CompletedDate
	LEFT OUTER JOIN ReasonCodes ON salestransactionline.ReasonDescription Is NOT NULL AND salestransactionline.ReasonDescription = ReasonCodes.Code
	LEFT OUTER JOIN (
		SELECT aggregateId, storeProductId, promotionId, SUM(givenaway) givenaway
		FROM salestransactionpromotioninformation
		GROUP BY aggregateId, storeProductId, promotionId
	) salestransactionpromotioninformation ON salestransactionpromotioninformation.aggregateId = salestransactionline.aggregateId AND salestransactionpromotioninformation.storeProductId =salestransactionline.storeProductId
	LEFT OUTER JOIN promotion ON salestransactionpromotioninformation.promotionId = promotion.PromotionId
	WHERE (completedDate >= @startdate OR @startdate IS NULL) AND completedDate <= @enddate AND subSectionId IS NOT NULL
	GROUP BY
		salestransactioncompleted.AggregateId,
		StoreId,
		completedDate,
		subSectionId,
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