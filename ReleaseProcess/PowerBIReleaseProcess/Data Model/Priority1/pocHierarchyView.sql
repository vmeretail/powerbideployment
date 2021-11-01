CREATE OR ALTER VIEW [dbo].[pocHierarchyView]
AS
SELECT 
	ProductHierarchyId,
	DepartmentId,
	DepartmentName,
	DepartmentNumber,
	SectionId,
	SectionName,
	SectionNumber,
	SubsectionId,
	SubsectionName,
	SubsectionNumber,
	Field,
	Value
 FROM producthierarchy


