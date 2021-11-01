CREATE OR ALTER VIEW [dbo].[uvwSalesProductsReporting]
AS

select 
	
	[SaleDate] = Date,
	OrganisationProductId ,
	[Store ID]				= StoreID,
	[GrossCostPrice]		= GrossCostPrice,
	[NetCostPrice]			= NetCostPrice,
	[SalesQuantity]			= QuantitySold,
	[SalesValueGross]		= GrossRetailValue,
	[SalesValue Net]		= NetRetailValue,
	[Product ID]			= StoreProductId,
	[Product Description]	= productDescription,
	[TaxCostValue]			= TaxCostValue,
	[TaxRetailValue]		= TaxRetailValue,
	[UnitNetCost]			= UnitNetCost

from productsalesbystorebydate