CREATE OR ALTER VIEW [dbo].[uvwSuppliersReporting]
AS

select 
	[Supplier ID] = SupplierId,
	[Supplier Name] = SupplierName

from supplier