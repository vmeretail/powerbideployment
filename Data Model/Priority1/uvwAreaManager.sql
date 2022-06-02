IF OBJECT_ID('dbo.[uvwAreaManager]', 'V') IS NOT NULL 
  DROP VIEW dbo.[uvwAreaManager]; 
GO; 

CREATE VIEW [dbo].[uvwAreaManager]
AS
SELECT 
	AreaManagerId,
	[Name]
FROM areamanager