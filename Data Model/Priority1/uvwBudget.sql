IF OBJECT_ID('dbo.[uvwBudget]', 'V') IS NOT NULL 
  DROP VIEW dbo.[uvwBudget]; 
GO; 

CREATE VIEW [dbo].[uvwBudget]
AS
SELECT 
    [YearWeekNumber],
    [StoreReportingId],
    [Budget]
FROM [Budget]

