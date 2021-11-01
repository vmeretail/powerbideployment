CREATE OR ALTER VIEW [dbo].[uvwStoreProductsHistoryReporting]
AS

SELECT      
	[Current Stock Level]                     = st.[CurrentStockLevel],
	[Last Stock Transfer Date]                = CONVERT(DATE,st.ActivityDate),       
	[Last Stock Transfer Time]                = CONVERT(TIME,st.ActivityDate),          
	[Reason For Stock Transfer]               = st.ReasonDescription,
	[Store ID]                                = st.[StoreId],       
	[Store Product ID]                        = st.[StoreProductId],       
	[Description]                             = op.[Description],
	[Last Sold Date]                          = sp.[LastSold],       
	[Organisation Product ID]                 = sp.[OrganisationProductId],       
	[Quantity Sold]                           = sp.[QuantitySold],      
	[Retail Price]                            = sp.[RetailPrice],       
	[Tax Rate]                                = sp.[TaxRate],
	[MPL]                                     = CASE WHEN (sp.[MPLHeight] * sp.[MPLWidth] * sp.[MPLDepth]) > 0 THEN 1 ELSE 0 END,
	[External Store ID]                       = store.[ExternalStoreId],       
	[Name]                                    = store.[Name],       
	[Status]                                  = store.[Status],       
	[Date Registered]                         = store.[DateRegistered],       
	[Address Line 1]                          = store.[AddressLine1],       
	[Address Line 2]                          = store.[AddressLine2],       
	[Country]                                 = store.[Country],       
	[County]                                  = store.[County],       
	[Latitude]                                = store.[Latitude],       
	[Longitude]                               = store.[Longitude],       
	[MapUri]                                  = store.[MapUri],       
	[PostCode]                                = store.[PostCode],       
	[TownCity]                                = store.[TownCity],       
	[Enabled]                                 = store.[Enabled],       
	[Number]                                  = store.[ExternalStoreNumber],       
	[Vme Code]                                = op.ExternalProductId,      
	[Item Size]                               = op.ItemSize,       
	[NSL]                                     = OrganisationProductProjectionState.HighestPrioritySupplierSic,       
	[Out Of Stock]                            = CASE WHEN st.[CurrentStockLevel]<=0 THEN 1 ELSE 0 END,       
	[Supplier Name]							  = supplier.SupplierName,
	[Ean]									  = OrganisationProductProjectionState.Barcode,
	[IsStockTransfer]					  = CASE WHEN st.IsGap = 1 OR st.IsIBTIn = 1 OR st.IsIBTOut = 1 OR st.IsStockCheck = 1 OR
													  st.IsWastage = 1 OR st.isStocktransferSale = 1 OR
													  st.ReasonDescription = 'DELIVERY' THEN 1 ELSE 0 END
	FROM storeproductactivity st
	inner join storeproduct as sp on st.StoreProductId = sp.StoreProductId 
	inner join store on st.StoreId = store.StoreId 
	inner join organisationproduct as op on sp.OrganisationProductId = op.OrganisationProductId 
	inner join OrganisationProductProjectionState on op.OrganisationProductId = OrganisationProductProjectionState.OrganisationProductId
	left join supplier on supplier.SupplierId = OrganisationProductProjectionState.HighestPriorityProductSupplierId
	where (sp.MPLDepth * sp.MPLHeight * sp.MPLWidth) >  0