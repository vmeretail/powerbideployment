CREATE OR ALTER VIEW uvwSalesSummaryByProduct
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
	    ,store.[Name] [Store] 
    FROM SalesSummaryByProduct
    INNER JOIN producthierarchy ON SalesSummaryByProduct.HierarchyNodeId = producthierarchy.ProductHierarchyId
    INNER JOIN OrganisationProductProjectionState ON SalesSummaryByProduct.OrganisationProductId = OrganisationProductProjectionState.OrganisationProductId
    INNER JOIN store ON SalesSummaryByProduct.storeId = store.StoreId