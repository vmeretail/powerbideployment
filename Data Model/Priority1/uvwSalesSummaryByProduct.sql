IF OBJECT_ID('dbo.uvwSalesSummaryByProduct', 'V') IS NOT NULL 
  DROP VIEW dbo.uvwSalesSummaryByProduct; 
GO; 

CREATE VIEW uvwSalesSummaryByProduct
AS
    SELECT 
	    [AggregateId]
        ,store.[StoreId]
        ,[CompletedDate]
        ,[DepartmentName] [Department]
        ,[SectionName] [Section]
        ,[SubsectionName] [Subsection]
        ,[Description] [ProductDescription]
        ,[TaxRate]
        ,[PaymentType]
        ,[Reason Code Type]
        ,[TransactionStatus]
        ,[DiscountType]
        ,[Tax Rate Count]
        ,[SALE exc VAT]
        ,[SALE inc VAT]
        ,[Margin £]
        ,[YearWeekNumber]
        ,[Year]
        ,[Week]
        ,[DayOfWeekShort]
        ,[DayOfWeek]
	    ,store.[StoreName] [Store]
        ,store.StoreReportingId
    FROM SalesSummaryByProduct
    INNER JOIN producthierarchy ON SalesSummaryByProduct.HierarchyNodeId = producthierarchy.ProductHierarchyId
    INNER JOIN OrganisationProductProjectionState ON SalesSummaryByProduct.OrganisationProductId = OrganisationProductProjectionState.OrganisationProductId
    INNER JOIN storeprojectionstate store ON SalesSummaryByProduct.storeId = store.StoreId