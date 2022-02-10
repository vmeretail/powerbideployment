CREATE OR ALTER   VIEW [dbo].[uvwAreaManager]
AS
select NULL as 'AreaManagerId',
	   'None' as 'Name'

union all

select areamanager.AreaManagerId,
	   areamanager.Name
from areamanager