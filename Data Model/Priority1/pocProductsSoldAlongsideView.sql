IF OBJECT_ID('dbo.[pocProductsSoldAlongside]', 'V') IS NOT NULL 
  DROP VIEW dbo.[pocProductsSoldAlongside]; 
GO; 

CREATE VIEW [dbo].[pocProductsSoldAlongside]
AS
SELECT 
	ai.antecedents,
	s.StoreId,
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
inner join OrganisationProductProjectionState aop on aop.OrganisationProductId = a1.OrganisationProductId
inner join StoreProductStateProjection c1 on c1.StoreProductReportingId = ai.[consequents]
inner join OrganisationProductProjectionState cop on cop.OrganisationProductId = c1.OrganisationProductId
inner join StoreProjectionState s on s.StoreReportingId = a1.StoreReportingId