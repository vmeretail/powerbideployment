CREATE OR ALTER VIEW [dbo].[pocProductsSoldAlongside]
AS
SELECT 
	ai.antecedents,
	a.StoreId,
    aop.[Description] as antecedent,
	cop.[Description] as consequent,
	ai.support * 1000 as Support
FROM 
(SELECT antecedents  
FROM [dbo].[AI_BasketAnalysis_Last7Days]
GROUP BY antecedents
HAVING count(*) > 3) x
inner join [dbo].[AI_BasketAnalysis_Last7Days] ai on ai.antecedents = x.antecedents
inner join StoreProductStateProjection a1 on a1.StoreProductReportingId = ai.[antecedents]
inner join storeproduct a on a.StoreProductId = a1.StoreProductId
inner join organisationproduct aop on aop.OrganisationProductId = a.OrganisationProductId
inner join StoreProductStateProjection c1 on c1.StoreProductReportingId = ai.[consequents]
inner join storeproduct c on c.StoreProductId = c1.StoreProductId
inner join organisationproduct cop on cop.OrganisationProductId = c.OrganisationProductId
inner join store s on s.StoreId = a.StoreId