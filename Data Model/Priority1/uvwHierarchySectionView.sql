IF OBJECT_ID('dbo.[uvwHierarchySectionView]', 'V') IS NOT NULL 
  DROP VIEW dbo.[uvwHierarchySectionView]; 
GO; 

CREATE VIEW [dbo].[uvwHierarchySectionView]
AS
SELECT 
	DISTINCT
	DepartmentId,
	SectionId,
	SectionName,
	SectionNumber
 FROM producthierarchy
 WHERE SectionId IS NOT NULL
 And SubSectionId IS NULL
 and Field != 6