IF OBJECT_ID('dbo.[pocSuppliersView]', 'V') IS NOT NULL 
  DROP VIEW dbo.[pocSuppliersView]; 
GO; 

CREATE VIEW [dbo].[pocSuppliersView]
AS
SELECT 
	SupplierId,
	SupplierName
FROM supplier