CREATE or ALTER VIEW [dbo].[uvwAreaManager]
AS

select areamanager.AreaManagerId,
	   areamanager.Name
from areamanager

union all

select NULL,'<None>'

