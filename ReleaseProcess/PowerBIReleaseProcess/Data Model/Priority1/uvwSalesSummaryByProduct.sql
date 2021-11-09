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
	    ,store.[Name] [store] 
    FROM SalesSummaryByProduct
    INNER JOIN producthierarchy ON SalesSummaryByProduct.HierarchyNodeId = producthierarchy.ProductHierarchyId
    INNER JOIN organisationproduct ON SalesSummaryByProduct.OrganisationProductId = organisationproduct.OrganisationProductId
    INNER JOIN store ON SalesSummaryByProduct.storeId = store.StoreId