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
    FROM SalesSummaryByProductTest
    INNER JOIN producthierarchy ON SalesSummaryByProductTest.subSectionId = producthierarchy.subSectionId
    INNER JOIN organisationproduct ON SalesSummaryByProductTest.OrganisationProductId = organisationproduct.OrganisationProductId
    INNER JOIN store ON SalesSummaryByProductTest.storeId = store.StoreId