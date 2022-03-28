CREATE OR ALTER VIEW pocCashRecReportSummary
AS
select saleType,FormattedSaleType, departmentid, storeId, [previous_basketCount], [previous_basketTotal], [previous_marginTotal], [current_basketCount], [current_basketTotal],[current_marginTotal]
from 
(
select saleType,FormattedSaleType, departmentid, storeId, [previous_basketCount], [previous_basketTotal], [previous_marginTotal], [current_basketCount], [current_basketTotal],[current_marginTotal]
from 
(
select saleType,FormattedSaleType, departmentid, storeId, [Date] + '_'+col col, value
from (
select saleType, CashRecReporting.departmentid,storeId, 
CASE SaleType
		WHEN 'excludingselecteddepartment' THEN 'Excluding ' + pocHierarchyView.DepartmentName
		WHEN 'includingselecteddepartment' THEN 'Including ' + pocHierarchyView.DepartmentName
		WHEN 'onlyselecteddepartment' THEN 'Only ' + pocHierarchyView.DepartmentName
	END AS FormattedSaleType,
CASE DATEPART(MONTH,ReportDate)
	WHEN DATEPART(MONTH,GETDATE()) Then 'current' 
	WHEN DATEPART(MONTH,DATEADD(MONTH, -1,GETDATE())) Then 'previous' 
	ELSE 'x'
	END as [Date], CAST(basketCount as DECIMAL) as basketCount, CAST(basketTotal as decimal) as basketTotal, CAST(marginTotal as decimal) as marginTotal
from CashRecReporting
inner join pocHierarchyView ON pocHierarchyView.ProductHierarchyId = CashRecReporting.DepartmentId) src
unpivot
(
value
for col in (basketCount, basketTotal,marginTotal)
) unpiv) s
pivot
(
sum(value)
for col in ( [previous_basketCount], [previous_basketTotal], [previous_marginTotal], [current_basketCount], [current_basketTotal],[current_marginTotal]
)) piv) result