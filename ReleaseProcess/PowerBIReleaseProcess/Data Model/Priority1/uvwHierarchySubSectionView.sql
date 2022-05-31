CREATE OR ALTER  VIEW [dbo].[uvwHierarchySubSectionView]
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