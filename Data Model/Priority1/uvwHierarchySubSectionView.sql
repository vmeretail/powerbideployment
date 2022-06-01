IF OBJECT_ID('dbo.[uvwHierarchySubSectionView]', 'V') IS NOT NULL 
  DROP VIEW dbo.[uvwHierarchySubSectionView]; 
GO; 

CREATE  VIEW [dbo].[uvwHierarchySubSectionView]
AS
SELECT 
	DISTINCT
	DepartmentId,
	SectionId,
	SubSectionId,
	SubSectionName,
	SubSectionNumber
 FROM producthierarchy
 WHERE SubSectionId IS NOT NULL
 and Field != 6