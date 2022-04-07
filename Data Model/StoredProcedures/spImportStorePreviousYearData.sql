/****** Object:  StoredProcedure [dbo].[spImportStorePreviousYearData]    Script Date: 4/7/2022 10:12:51 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[spImportStorePreviousYearData]  @calendaryear int, @externalstoreid char(36),@tablename varchar(50)
AS
--declare @calendaryear int-- sp param - 2021
--declare @externalstoreid char(36) -- sp param - from v2
--declare @tablename varchar(50)

--set @calendaryear = 2021
--set @externalstoreid = '60949770-2D8D-1847-BB-ACB2D0430637FA'
--set @tablename = 'ryton'

-- Get the raw rtc lines
select store, vmecode, TranskeyArchive.date, 1 as items, cast(soldprice as decimal(18,2)) as soldfor, normalprice  as retailprice, cast(variance as decimal(18,2)) as variance
into #rtclines
from TranskeyArchive
inner join calendar on calendar.Date = TranskeyArchive.date
where store = @externalstoreid
and reason = 'PK01' -- RTC
--and date = '2021-01-17'
and calendar.Year = @calendaryear
and calendar.date >= '2021-01-17'

-- group up the RTCs by store, vmecode, date to make stock transfer join easier
select store, vmecode, date, count(*) as items, sum(soldfor) as soldfor
into #rtclinesgrouped
from #rtclines
group by store, vmecode, date

-- Get all the stores stock transfers
declare @sqlstring nvarchar(MAX) 

CREATE TABLE #importdata
(
ExternalStoreId nvarchar(50),
VmeCode nvarchar(50), 
CompletedDate smalldatetime,
price decimal(18,5), 
items decimal(18,5), 
SaleLineInc decimal(18,5), 
Reason nvarchar(50)
)

set @sqlstring = '
insert into #importdata(ExternalStoreId, VmeCode, CompletedDate, price, items, SaleLineInc,Reason)
select 
ExternalStoreId,
VmeCode,
CompletedDate,
cast(price as decimal(18,5))  as price,
cast(Items as decimal(18,5)) as items,
cast(SaleLineInc as decimal(18,5))  as SaleLineInc,
--Items as originalitems,
--SaleLineInc as originalSaleLineInc,
Reason
--into #importdata
from [' + @tablename + ']
inner join calendar on calendar.Date = ' + '[' + @tablename + '].completeddate
where calendar.Year = ' + CAST(@calendaryear as char(4)) + '
and calendar.date >= ''2021-01-17''
and reason IN (''SALES'', ''WASTAGE'')'

PRINT @sqlstring

EXECUTE sp_executesql @sqlstring

-- Remove RTC values from the matching sales stock transfers
update #importdata -- 18165
set 
	#importdata.Items = (#importdata.Items - #rtclinesgrouped.items), 
	#importdata.SaleLineInc = (#importdata.SaleLineInc - #rtclinesgrouped.soldfor)
from #importdata
inner join #rtclinesgrouped on #rtclinesgrouped.store = #importdata.ExternalStoreId and #rtclinesgrouped.date = #importdata.CompletedDate and #rtclinesgrouped.vmecode = #importdata.VmeCode
where #importdata.Reason = 'SALES'

-- now remove any stock transfer sales which were wholly RTC
delete from #importdata where #importdata.Items = 0 and #importdata.Reason = 'SALES'

-- Update the price values for the matched sales containt RTC's
update #importdata
set 
	#importdata.price = #importdata.SaleLineInc   / #importdata.Items
from #importdata
inner join #rtclinesgrouped on #rtclinesgrouped.store = #importdata.ExternalStoreId and #rtclinesgrouped.date = #importdata.CompletedDate and #rtclinesgrouped.vmecode = #importdata.VmeCode
where #importdata.Reason = 'SALES'

-- Create the Activity records for the sales
insert into WIP_StoreProductActivity_PreviousYear(EventId,ActivityDate, ActivityDateTime, CurrentStockLevel, IsDelivery, IsGap, IsIBTIn, IsIBTOut, IsOrder, IsRTC,IsSale, IsStockCheck,
IsStockTake, IsWastage, IsStockTransfer, IsStockTransferSale, NumberOfitemsSold, OrderCaseSize, OrderNumberOfCases, ReasonDescription, SalesTransactionLineId,
StockTransferQuantity, StoreId, StoreProductId, StoreProductReportingId, SalesTransactionId,OrganisationProductId,OrganisationProductReportingId, storereportingid, soldforprice, retailprice, variance,
FutureDate, ActivityType, DepartmentId, SectionId,SubSectionId)
SELECT 
NEWID() as EventId,
importdata.CompletedDate as ActivityDate,
importdata.CompletedDate as ActivityDateTime, 
0 as CurrentStockLevel,
0 as IsDelivery,
0 as IsGap,
0 as IsIBTIn,
0 as IsIBTOut,
0 as IsOrder,
0 as IsRTC,
1 as IsSale,
0 as IsStockCheck,
0 as IsStockTake,
0 as IsWastage,
0 as IsStockTransfer,
1 as IsStockTransferSale,
importdata.items as NumberOfItemsSold,
0 as OrderCaseSize,
0 as OrderNumberofCases,
importdata.Reason,
'00000000-0000-0000-0000-000000000000' as salesTransactionLineId,
importdata.items as items,
StoreProjectionState.StoreId,
'00000000-0000-0000-0000-000000000000' as StoreProductId,
0 as StoreProductReportingId,
'00000000-0000-0000-0000-000000000000' as SalesTransactionId,
OrganisationProductProjectionState.OrganisationProductId,
OrganisationProductProjectionState.OrganisationProductReportingId,
StoreProjectionState.StoreReportingId,
importdata.SaleLineInc as soldfor,
importdata.price as retailprice,
0 as variance,
futureyear.[Date],
7,
producthierarchy.DepartmentId,
producthierarchy.SectionId,
producthierarchy.SubsectionId
from #importdata importdata
inner join calendar on calendar.Date = importdata.CompletedDate
left outer join calendar futureyear on futureyear.Year = (calendar.year + 1) and futureyear.WeekNumber = calendar.WeekNumber and futureyear.DayOfWeekNumber = calendar.DayOfWeekNumber
inner join store on store.ExternalStoreCode = importdata.ExternalStoreId
inner join StoreProjectionState on StoreProjectionState.StoreId = store.StoreId
left outer join OrganisationProductProjectionState on OrganisationProductProjectionState.ExternalProductId = importdata.VMECode
left outer join producthierarchy on producthierarchy.ProductHierarchyId = OrganisationProductProjectionState.ProductHierarchyNodeId
WHERE importdata.Reason = 'SALES'

-- Create the Activity records for the wastage records
insert into WIP_StoreProductActivity_PreviousYear(EventId,ActivityDate, ActivityDateTime, CurrentStockLevel, IsDelivery, IsGap, IsIBTIn, IsIBTOut, IsOrder, IsRTC,IsSale, IsStockCheck,
IsStockTake, IsWastage, IsStockTransfer, IsStockTransferSale, NumberOfitemsSold, OrderCaseSize, OrderNumberOfCases, ReasonDescription, SalesTransactionLineId,
StockTransferQuantity, StoreId, StoreProductId, StoreProductReportingId, SalesTransactionId,OrganisationProductId,OrganisationProductReportingId, storereportingid, soldforprice, retailprice, variance,
FutureDate, ActivityType, DepartmentId, SectionId,SubSectionId)
SELECT 
NEWID() as EventId,
importdata.CompletedDate as ActivityDate,
importdata.CompletedDate as ActivityDateTime, 
0 as CurrentStockLevel,
0 as IsDelivery,
0 as IsGap,
0 as IsIBTIn,
0 as IsIBTOut,
0 as IsOrder,
0 as IsRTC,
0 as IsSale,
0 as IsStockCheck,
0 as IsStockTake,
1 as IsWastage,
0 as IsStockTransfer,
0 as IsStockTransferSale,
importdata.items as NumberOfItemsSold,
0 as OrderCaseSize,
0 as OrderNumberofCases,
importdata.Reason,
'00000000-0000-0000-0000-000000000000' as salesTransactionLineId,
importdata.items as items,
StoreProjectionState.StoreId,
'00000000-0000-0000-0000-000000000000' as StoreProductId,
0 as StoreProductReportingId,
'00000000-0000-0000-0000-000000000000' as SalesTransactionId,
OrganisationProductProjectionState.OrganisationProductId,
OrganisationProductProjectionState.OrganisationProductReportingId,
StoreProjectionState.StoreReportingId,
importdata.SaleLineInc as soldfor,
importdata.price as retailprice,
0 as variance,
futureyear.[Date],
10,
producthierarchy.DepartmentId,
producthierarchy.SectionId,
producthierarchy.SubsectionId
from #importdata importdata
inner join calendar on calendar.Date = importdata.CompletedDate
left outer join calendar futureyear on futureyear.Year = (calendar.year + 1) and futureyear.WeekNumber = calendar.WeekNumber and futureyear.DayOfWeekNumber = calendar.DayOfWeekNumber
inner join store on store.ExternalStoreCode = importdata.ExternalStoreId
inner join StoreProjectionState on StoreProjectionState.StoreId = store.StoreId
left outer join OrganisationProductProjectionState on OrganisationProductProjectionState.ExternalProductId = importdata.VMECode
left outer join producthierarchy on producthierarchy.ProductHierarchyId = OrganisationProductProjectionState.ProductHierarchyNodeId
WHERE importdata.Reason = 'WASTAGE'

select store, vmecode, date, count(*) as items, 1 as IsRTC, 1 as IsSale, sum(soldprice) as soldfor, sum(normalprice) / count(*) as retailprice, sum(variance) as variance
into #tempTranskeyArchive
from TranskeyArchive 
where reason = 'PK01'
and store = @externalstoreid
group by store, vmecode, date

--673,798
insert into WIP_StoreProductActivity_PreviousYear(EventId,ActivityDate, ActivityDateTime, CurrentStockLevel, IsDelivery, IsGap, IsIBTIn, IsIBTOut, IsOrder, IsRTC,IsSale, IsStockCheck,
IsStockTake, IsWastage, IsStockTransfer, IsStockTransferSale, NumberOfitemsSold, OrderCaseSize, OrderNumberOfCases, ReasonDescription, SalesTransactionLineId,
StockTransferQuantity, StoreId, StoreProductId, StoreProductReportingId, SalesTransactionId,OrganisationProductId,OrganisationProductReportingId, storereportingid, retailprice, soldforprice, variance,
FutureDate, ActivityType, DepartmentId, SectionId,SubSectionId)
SELECT 
NEWID() as EventId,
transkeyarchive.date as ActivityDate,
transkeyarchive.date as ActivityDateTime, 
0 as CurrentStockLevel,
0 IsDelivery,
0 IsGap,
0 IsIBTIn,
0 IsIBTOut,
0 as IsOrder,
1 as IsRTC,
1 as IsSale,
0 IsStockCheck,
0 IsStockTake,
0 IsWastage,
0 as IsStockTransfer,
0 as IsStockTransferSale,
items as NumberOfItemsSold,
0 as OrderCaseSize,
0 as OrderNumberofCases,
'PK01',
'00000000-0000-0000-0000-000000000000' as salesTransactionLineId,
items,
StoreProjectionState.StoreId,
'00000000-0000-0000-0000-000000000000',
0,
'00000000-0000-0000-0000-000000000000' as SalesTransactionId,
OrganisationProductProjectionState.OrganisationProductId,
OrganisationProductProjectionState.OrganisationProductReportingId,
StoreProjectionState.StoreReportingId,
transkeyarchive.retailprice,
transkeyarchive.soldfor,
transkeyarchive.variance,
futureyear.[Date],
6,
producthierarchy.DepartmentId,
producthierarchy.SectionId,
producthierarchy.SubsectionId
from #tempTranskeyArchive transkeyarchive
inner join calendar on calendar.Date = transkeyarchive.date
left outer join calendar futureyear on futureyear.Year = (calendar.year + 1) and futureyear.WeekNumber = calendar.WeekNumber and futureyear.DayOfWeekNumber = calendar.DayOfWeekNumber
inner join store on store.ExternalStoreCode = transkeyarchive.store
inner join StoreProjectionState on StoreProjectionState.StoreId = store.StoreId
left outer join OrganisationProductProjectionState on OrganisationProductProjectionState.ExternalProductId = transkeyarchive.VMECode
left outer join producthierarchy on producthierarchy.ProductHierarchyId = OrganisationProductProjectionState.ProductHierarchyNodeId



