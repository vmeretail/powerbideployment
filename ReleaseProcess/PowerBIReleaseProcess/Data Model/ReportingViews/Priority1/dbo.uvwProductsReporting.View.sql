CREATE OR ALTER VIEW [dbo].[uvwProductsReporting]
AS

select 

	[Organisation Product Id]	  = storeproduct.OrganisationProductId,
	[Product ID]				  = storeproduct.StoreProductId,
	[Product Description]		  = organisationproduct.Description,
	[External Product Id]		  = organisationproduct.ExternalProductId,	
	[Store ID]					  = storeproduct.StoreID,
	[Department ID]				  = producthierarchy.DepartmentId,  
	[Department Number]			  = producthierarchy.DepartmentNumber,
	[Department Name]			  = producthierarchy.DepartmentName,
	[Section ID]				  = producthierarchy.SectionId,
	[Section Number]			  = producthierarchy.SectionNumber,
	[Section Name]				  = producthierarchy.SectionName,
	[Sub Section ID]			  = producthierarchy.SubSectionId,
	[Sub Section Number]		  = producthierarchy.SubSectionNumber,
	[Sub Section Name]			  = producthierarchy.SubSectionName,
	[Cost Price]				  = OrganisationProductProjectionState.HighestPrioritySupplierCostPrice,
	[Unit Cost Price]			  = OrganisationProductProjectionState.HighestPrioritySupplierUnitCostPrice,
	[Case Size]					  = OrganisationProductProjectionState.HighestPrioritySupplierCaseSize,
	[SIC]						  = OrganisationProductProjectionState.HighestPrioritySupplierSic,
	[Supplier Name]				  =	supplier.SupplierName,
	[Item Size]					  = organisationproduct.ItemSize,
	[Standard Retail Price Inc]	  = storeproduct.RetailPrice,
	[Standard Retail Price Ex]	  = (storeproduct.RetailPrice / (taxrate.Rate + 1)),
	[Vat Rate]					  = taxrate.Rate,
	[Calculation Vat Rate]		  = taxrate.Rate + 1,
	[Ean]									  =	OrganisationProductProjectionState.Barcode

from storeproduct
inner join organisationproduct on organisationproduct.OrganisationProductId = storeproduct.OrganisationProductId
inner join OrganisationProductProjectionState on organisationproduct.OrganisationProductId = storeproduct.OrganisationProductId
left outer join supplier on supplier.SupplierId = OrganisationProductProjectionState.HighestPrioritySupplierId
inner join taxrate on taxrate.TaxRateId = organisationproduct.TaxRateId
inner join producthierarchy on producthierarchy.ProductHierarchyId = organisationproduct.ProductHierarchyNodeId