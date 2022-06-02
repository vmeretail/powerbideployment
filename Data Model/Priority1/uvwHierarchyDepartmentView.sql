IF OBJECT_ID('dbo.[uvwHierarchyDepartmentView]', 'V') IS NOT NULL 
  DROP VIEW dbo.[uvwHierarchyDepartmentView]; 
GO; 

CREATE VIEW [dbo].[uvwHierarchyDepartmentView]
AS
SELECT 
	DISTINCT
	DepartmentId,
	DepartmentName,
	DepartmentNumber
 FROM producthierarchy
 WHERE DepartmentId IS NOT NULL
 and SectionId is null 
 and Field != 6