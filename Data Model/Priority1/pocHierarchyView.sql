IF OBJECT_ID('dbo.[pocHierarchyView]', 'V') IS NOT NULL 
  DROP VIEW dbo.[pocHierarchyView]; 
GO; 

CREATE VIEW [dbo].[pocHierarchyView]
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


