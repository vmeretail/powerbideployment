IF OBJECT_ID('dbo.[spBuildDepartmentCashRecReport]', 'P') IS NOT NULL 
  DROP PROCEDURE dbo.[spBuildDepartmentCashRecReport]; 
GO; 

CREATE PROCEDURE [dbo].[spBuildDepartmentCashRecReport] @reportStartDate datetime
AS
		-- Calculate the number for days to catch up
	declare @startDate datetime
	declare @endDate datetime

	set @startDate = @reportStartDate
	set @endDate = DATEADD(d,6,@reportStartDate)

	WHILE (@StartDate <= @EndDate)
	BEGIN

		print @StartDate;
		-- Do Something like call a proc with the variable @StartDate
		EXEC [spBuildDepartmentCashRecReport] @startDate

		set @StartDate = DATEADD(day, 1, @StartDate);
	END