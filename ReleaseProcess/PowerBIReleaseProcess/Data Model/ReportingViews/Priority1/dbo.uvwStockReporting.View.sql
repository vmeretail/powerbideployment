CREATE OR ALTER VIEW [dbo].[uvwStockReporting]
AS

SELECT	 [Store product ID]				  = sps.[StoreProductId]
		,[Unit Stock]					  = sps.CurrentStockLevel
		,[Net Retail Value Of Stock]      = (sp.RetailPrice * sps.CurrentStockLevel) / (1 + sp.TaxRate / 100)
		,[Tax Retail Value Of Stock]      = (sp.RetailPrice * sps.CurrentStockLevel) - (sp.RetailPrice * sps.CurrentStockLevel) / (1 + sp.TaxRate / 100)
		,[Gross Retail Value Of Stock]    = sp.RetailPrice * sps.CurrentStockLevel
		,[Net Cost Price Of Stock]        = (sup.CostPrice * sps.CurrentStockLevel) / (1 + sp.TaxRate / 100)
		,[Tax Cost Price Of Stock]	      = (sup.CostPrice * sps.CurrentStockLevel) - (sp.RetailPrice * sps.CurrentStockLevel) / (1 + sp.TaxRate / 100)
		,[Gross Cost Price Of Stock]	  = sup.CostPrice * sps.CurrentStockLevel
		,[Store ID]					      = sps.StoreId
		,[Department ID]				  = ph.DepartmentId
		,[Department Number]			  = ph.DepartmentNumber
		,[Department Name]			      = ph.DepartmentName
		,[Section ID]				      = ph.SectionId
		,[Section Number]			      = ph.SectionNumber
		,[Section Name]				      = ph.SectionName
		,[Sub Section ID]			      = ph.SubSectionId
		,[Sub Section Number]		      = ph.SubSectionNumber
		,[Sub Section Name]			      = ph.SubSectionName
		,[Product Description]			  = op.[Description]
		,[Product Size]					  = op.ItemSize
		,[Store Name]					  = st.[Name]
		,[Store Number]					  = st.ExternalStoreId

  
FROM storeproductactivity as sps
inner join storeproduct as sp on sps.StoreProductId = sp.StoreProductId
inner join organisationproduct op ON sp.OrganisationProductId = op.OrganisationProductId
inner join producthierarchy ph ON ph.ProductHierarchyId = op.ProductHierarchyNodeId
inner join store st on sp.StoreId = st.StoreId
inner join supplierproduct sup on op.OrganisationProductId = sup.OrganisationProductId