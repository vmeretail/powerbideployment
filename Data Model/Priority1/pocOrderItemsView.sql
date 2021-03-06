IF OBJECT_ID('dbo.[pocOrderItemsView]', 'V') IS NOT NULL 
  DROP VIEW dbo.[pocOrderItemsView]; 
GO; 

CREATE VIEW [dbo].[pocOrderItemsView]
AS
SELECT 
	[order].OrderId, 
	[order].ExternalOrderId [Order Number], 
	[order].CreatedDateTime,
	CONVERT(VARCHAR(10), [order].ExternalOrderId) [Order Number String],
	StoreProjectionState.StoreName Store,
	orderItemProjectionState.ExternalOrderItemId, 
	sub.OriginalOrderItemId as SubstitutedOrderItemId, 
	replacementId,
	ISNULL(NumberOfCasesOrdered, 0)  [Cases Ordered],
	OrganisationProductProjectionState.OrganisationProductId [Original product Id],
	rep.OrganisationProductId [Swapped Product Id],
	CASE
		WHEN OrganisationProductProjectionState.OrganisationProductId = rep.OrganisationProductId THEN 'Same Product'
		ELSE 'Different Product'
	END [Swapout Type],
	OrganisationProductProjectionState.[Description] [Original Description],
	rep.[Description] [Swapped Description],
	OrganisationProductProjectionState.ItemSize [Original Item Size],
	rep.ItemSize [Swapped Item Size],
	supplier.SupplierName [Original Supplier],
	rep.SupplierName [Swapped Supplier],
	supplierproduct.CaseSize [Original Case Size Ordered],
	rep.CaseSize [Swapped Case Size Ordered],
	CONVERT(DECIMAL(18,2), ISNULL(supplierproduct.CostPrice, 0)) [Original Cost Price],
	CONVERT(DECIMAL(18,2), ISNULL(rep.CostPrice, 0)) [Swapped Cost Price],
	CONVERT(DECIMAL(18,2), ISNULL(supplierproduct.CostPrice, 0) * ISNULL(NumberOfCasesOrdered, 0)) [Original Total Cost Price],
	CONVERT(DECIMAL(18,2), ISNULL(rep.CostPrice, 0) * ISNULL([Swapped Cases Delivered], 0)) [Swapped Total Cost Price],
	ISNULL(NumberOfCasesDelivered, 0) [Cases Delivered],
	ISNULL([Swapped Cases Delivered], 0) [Swapped Cases Delivered],
	orderItemProjectionState.SIC + ' (' + cast(supplierproduct.[Priority] as varchar(5)) + ')' as [Original Sic],
	[Swapped Sic] + ' (' + cast(rep.[Priority] as varchar(5)) + ')' as [Swapped Sic],
	CASE
		WHEN OrganisationProductProjectionState.OrganisationProductId = rep.OrganisationProductId THEN supplier.SupplierName + ' (S)'
		ELSE supplier.SupplierName + ' (D)'
	END [Supplier Swapout Type]
FROM [order]
INNER JOIN orderItemProjectionState ON [order].orderId = orderItemProjectionState.OrderId
INNER JOIN StoreProjectionState ON [order].StoreId = StoreProjectionState.StoreId
INNER JOIN OrganisationProductProjectionState ON orderItemProjectionState.OrganisationProductId = OrganisationProductProjectionState.OrganisationProductId
INNER JOIN supplier ON [order].SupplierId = supplier.SupplierId
INNER JOIN supplierproduct ON supplierproduct.OrganisationProductId = orderItemProjectionState.OrganisationProductId AND supplierproduct.SupplierId = [order].SupplierId AND supplierproduct.Sic = orderItemProjectionState.SIC
INNER JOIN (
	SELECT 
		delivery.OrderId, 
		OriginalOrderItemId,
		SUM(NumberOfCasesDelivered) NumberOfCasesDelivered
	FROM DeliveryProjectionState delivery
	INNER JOIN deliveryItemProjectionState deliveryItem ON delivery.DeliveryId = deliveryItem.DeliveryId and OriginalOrderItemId IS NOT NULL
	GROUP BY
		delivery.OrderId, 
		OriginalOrderItemId
) sub ON sub.OriginalOrderItemId = orderItemProjectionState.ExternalOrderItemId 
INNER JOIN (
	SELECT 
		orderItemProjectionState.OrderId, 
		orderItemProjectionState.ExternalOrderItemId, 
		rep.ExternalOrderItemId replacementId,
		rep.SIC [Swapped SIC],
		supplierproduct.CaseSize,
		supplierproduct.CostPrice,
		supplierproduct.[Priority],
		OrganisationProductProjectionState.[Description],
		OrganisationProductProjectionState.ItemSize,
		OrganisationProductProjectionState.OrganisationProductId,
		supplier.SupplierName,
		SUM(NumberOfCasesDelivered) [Swapped Cases Delivered]
	from orderItemProjectionState
	INNER JOIN [order] ON [order].OrderId = orderItemProjectionState.OrderId
	INNER JOIN DeliveryProjectionState delivery ON delivery.OrderId = orderItemProjectionState.OrderId
	INNER JOIN deliveryItemProjectionState deliveryItem ON delivery.deliveryId = deliveryItem.deliveryid AND deliveryItem.OriginalOrderItemId = orderItemProjectionState.ExternalOrderItemId
	INNER JOIN orderItemProjectionState rep ON orderItemProjectionState.OrderId = rep.OrderId AND rep.SIC = deliveryItem.Sic AND rep.StoreProductId = deliveryItem.StoreProductId
	INNER JOIN supplierproduct ON supplierproduct.OrganisationProductId = rep.OrganisationProductId AND supplierproduct.SupplierId = [order].SupplierId AND supplierproduct.Sic = rep.SIC
	INNER JOIN OrganisationProductProjectionState ON rep.OrganisationProductId = OrganisationProductProjectionState.OrganisationProductId
	INNER JOIN supplier ON [order].SupplierId = supplier.SupplierId
	GROUP BY
		orderItemProjectionState.OrderId, 
		orderItemProjectionState.ExternalOrderItemId, 
		rep.ExternalOrderItemId,
		rep.SIC,
		supplierproduct.CaseSize,
		supplierproduct.CostPrice, 
		supplierproduct.[Priority],
		OrganisationProductProjectionState.[Description],
		OrganisationProductProjectionState.ItemSize,
		OrganisationProductProjectionState.OrganisationProductId,
		supplier.SupplierName
) rep on rep.OrderId = [order].OrderId AND rep.ExternalOrderItemId = orderItemProjectionState.ExternalOrderItemId
WHERE orderItemProjectionState.SIC <> [Swapped SIC]