CREATE OR ALTER   VIEW [dbo].[uvwHierarchySectionView]
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