CREATE OR ALTER VIEW [dbo].uvwStoreProductReporting
AS

SELECT 
 [Store Product Id] = sp.storeProductId,
 [Store Id] = sp.StoreId,
 [Organisation Product Id] = sp.OrganisationProductId, 
 [External Product Id] = op.ExternalProductId,
 [External Store Id] = s.ExternalStoreId,
 [Description]                             = op.[Description],
 [Retail Price] = sp.RetailPrice, 
 [MPL] = CASE WHEN (sp.[MPLHeight] * sp.[MPLWidth] * sp.[MPLDepth]) > 0 THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END,
 [Item Size] = op.ItemSize,
 [Product Hierarchy Id] = ph.ProductHierarchyId,
 [Department Id] = ph.DepartmentId,
 [Department Name] = ph.DepartmentName,
 [Department Number] = ph.DepartmentNumber,
 [Section Id] = ph.SectionId,
 [Section Name] = ph.SectionName,
 [Section Number] = ph.SectionNumber,
 [Subsection Id] = ph.SubsectionId,
 [Subsection Name] = ph.SubsectionName,
 [Subsection Number] = ph.SubsectionNumber,
 [Supplier Id] = sup.SupplierId,
 [Supplier Name] = sup.SupplierName,
 [Supplier Case Size] = supprod.CaseSize,
 [Supplier Cost Price] = supprod.CostPrice,
 [Supplier Is Suspended] = supprod.IsSuspended,
 [Supplier Priority] = supprod.Priority,
 [Tax Rate Id] = tr.TaxRateId,
 [Tax Rate] = tr.Rate,
 [Tax Rate Code] = tr.Code,
 [Tax Rate Name] = tr.Name
FROM storeproduct sp
INNER JOIN organisationproduct op ON sp.OrganisationProductId = op.OrganisationProductId
INNER JOIN producthierarchy ph ON ph.ProductHierarchyId = op.ProductHierarchyNodeId
INNER JOIN store s ON s.StoreId = sp.StoreId
OUTER APPLY
(
    SELECT TOP 1 *
    FROM supplierproduct
    WHERE supplierproduct.OrganisationProductId = sp.OrganisationProductId AND IsSuspended = 0
	ORDER BY [Priority] 
) supprod
LEFT JOIN supplier sup on sup.SupplierId = supprod.SupplierId 
INNER JOIN taxrate tr ON tr.TaxRateId = op.TaxRateId