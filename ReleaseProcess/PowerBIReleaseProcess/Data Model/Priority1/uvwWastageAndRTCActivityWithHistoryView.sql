CREATE OR ALTER VIEW uvwWastageAndRTCActivityWithHistoryView
AS
select 
1 as CYorPY,
ActivityDate,
ActivityDate as FutureYearDate,
ActivityDateTime,
uvwStoreProductActivityView.StoreReportingId,
OrganisationProductReportingId,
YearWeekNumber,
RTCCount as RTCCountCurrentYear,
0 as RTCCountPreviousYear,
RTCSales as RTCSalesCurrentYear,
0 as RTCSalesPreviousYear,
Variance as VarianceCurrentYear,
0 as VariancePreviousYear,
SaleCount as SaleCountCurrentYear,
0 as SaleCountPreviousYear,
Sales as SalesCurrentYear,
0 as SalesPreviousYear,
IsWastage,
WastageCount as WastageCountCurrentYear,
0 as WastageCountPreviousYear,
WastageSales as WastageSalesCurrentYear,
0 as WastageSalesPreviousYear,
ActivityType
from uvwStoreProductActivityView 
where ActivityDate >= '2022-01-23' -- filter historic data
and (uvwStoreProductActivityView.ActivityTypeInt = 6 OR
	uvwStoreProductActivityView.ActivityTypeInt = 7 OR
	uvwStoreProductActivityView.ActivityTypeInt =  10)

union all

select 
2 as CYorPY,
ActivityDate,
FutureYearDate,
ActivityDateTime,
uvwStoreProductActivityView_PreviousYear.StoreReportingId,
OrganisationProductReportingId,
YearWeekNumber,
0 as RTCCYCount,
CASE WHEN IsRTC = 1 THEN SaleCount ELSE 0 END as RTCPYCount,
0 as RTCSalesCurrentYear,
RTCSales as RTCSalesPreviousYear,
0 as VarianceCurrentYear,
Variance as VariancePreviousYear,
0 as SaleCountCurrentYear,
SaleCount as SaleCountPreviousYear,
0 as SalesCurrentYear,
Sales as SalesPreviousYear,
IsWastage,
0 as WastageCountCurrentYear,
WastageCount as WastageCountPreviousYear,
0 as WastageSalesCurrentYear,
WastageSales as WastageSalesPreviousYear,
ActivityType
from uvwStoreProductActivityView_PreviousYear 
where (uvwStoreProductActivityView_PreviousYear.ActivityTypeInt = 6 OR
	uvwStoreProductActivityView_PreviousYear.ActivityTypeInt = 7 OR
	uvwStoreProductActivityView_PreviousYear.ActivityTypeInt =  10)
