CREATE OR ALTER VIEW [dbo].[uvwStoresReporting]
AS

Select 

	[store ID]			= StoreId,
	enabled,
	[Organisation ID]	= s.OrganisationId,
	[Organisation Name] = o.Name,
	[Store Name]		= s.Name,
	[Store Number]		= s.ExternalStoreID,
	[Address Line 1]	= s.AddressLine1,
    [Address Line 2]	= s.AddressLine2,
	[Country]			= s.Country,
    [County]			= s.County,
    [Latitude]			= s.Latitude,
    [Longitude]			= s.Longitude,
    [Map Uri]			= s.MapUri,
    [Post Code]			= s.PostCode,
    [Town City]			= s.TownCity,
	[Date Registered]   = s.DateRegistered,
	[Store Name And Number] = CONCAT(s.Name, ' (', s.ExternalStoreID, ')')
	
from 
store s
LEFT JOIN 
organisation o ON s.OrganisationId = o.organisationId