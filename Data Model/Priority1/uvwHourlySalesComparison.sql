CREATE OR ALTER VIEW uvwHourlySalesComparison 
AS 

SELECT 
	CONVERT(DATE, st1.CompletedDateHour) [Date],
	st1.CompletedDateHour [DateHour],
	store.StoreId,
	store.Name [Store],
	st1.Gross [Gross Today],
	st1.Net [Net Today],
	st2.Gross [Gross Yesterday],
	st2.Net [Net Yesterday],
	st3.Gross [Gross Last Week],
	st3.Net [Net Last Week],
	st4.Gross [Gross Last Month],
	st4.Net [Net Last Month]
FROM
(
	SELECT 
		StoreId,
		DATEADD(HOUR, DATEPART(HOUR, CompletedDateTime), CONVERT(DATETIME, CONVERT(DATE, CompletedDateTime))) CompletedDateHour,
		SUM(TotalRetailValueInc) Gross,
		SUM(TotalRetailValueEx) Net  
	FROM salestransactioncompleted
	WHERE salestransactioncompleted.CompletedDate != '0001-01-01'
	GROUP BY 
		StoreId,
		DATEADD(HOUR, DATEPART(HOUR, CompletedDateTime), CONVERT(DATETIME, CONVERT(DATE, CompletedDateTime)))
) st1
LEFT JOIN
(
	SELECT 
		StoreId,
		DATEADD(HOUR, DATEPART(HOUR, CompletedDateTime), CONVERT(DATETIME, CONVERT(DATE, CompletedDateTime))) CompletedDateHour,
		SUM(TotalRetailValueInc) Gross,
		SUM(TotalRetailValueEx) Net    
	FROM salestransactioncompleted 
	WHERE salestransactioncompleted.CompletedDate != '0001-01-01'
	GROUP BY 
		StoreId,
		DATEADD(HOUR, DATEPART(HOUR, CompletedDateTime), CONVERT(DATETIME, CONVERT(DATE, CompletedDateTime)))
) st2 ON st1.CompletedDateHour = DATEADD(DAY, 1, st2.CompletedDateHour) AND st1.StoreId = st2.StoreId 
LEFT JOIN
(
	SELECT 
		StoreId,
		DATEADD(HOUR, DATEPART(HOUR, CompletedDateTime), CONVERT(DATETIME, CONVERT(DATE, CompletedDateTime))) CompletedDateHour,
		SUM(TotalRetailValueInc) Gross,
		SUM(TotalRetailValueEx) Net    
	FROM salestransactioncompleted 
	WHERE salestransactioncompleted.CompletedDate != '0001-01-01'
	GROUP BY 
		StoreId,
		DATEADD(HOUR, DATEPART(HOUR, CompletedDateTime), CONVERT(DATETIME, CONVERT(DATE, CompletedDateTime)))
) st3 ON st1.CompletedDateHour = DATEADD(WEEK, 1, st3.CompletedDateHour) AND st1.StoreId = st3.StoreId  
LEFT JOIN
(
	SELECT 
		StoreId,
		DATEADD(HOUR, DATEPART(HOUR, CompletedDateTime), CONVERT(DATETIME, CONVERT(DATE, CompletedDateTime))) CompletedDateHour,
		SUM(TotalRetailValueInc) Gross,
		SUM(TotalRetailValueEx) Net    
	FROM salestransactioncompleted 
	WHERE salestransactioncompleted.CompletedDate != '0001-01-01'
	GROUP BY 
		StoreId,
		DATEADD(HOUR, DATEPART(HOUR, CompletedDateTime), CONVERT(DATETIME, CONVERT(DATE, CompletedDateTime)))
) st4 ON st1.CompletedDateHour = DATEADD(MONTH, 1, st4.CompletedDateHour) AND st1.StoreId = st4.StoreId
INNER JOIN store ON st1.StoreId = store.StoreId