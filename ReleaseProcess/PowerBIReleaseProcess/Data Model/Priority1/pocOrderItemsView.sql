CREATE OR ALTER   VIEW [dbo].[pocOrderItemsView]
AS
SELECT  
	[order].OrderId, 
	[order].ExternalOrderId [Order Number], 
	[order].CreatedDateTime,
	CONVERT(VARCHAR(10), [order].ExternalOrderId) [Order Number String],
	store.[Name] Store,
	orderItem.ExternalOrderItemId, 
	sub.SubstitutedOrderItemId, 
	replacementId,
	ISNULL(NumberOfCasesOrdered, 0)  [Cases Ordered],
	organisationproduct.OrganisationProductId [Original product Id],
	rep.OrganisationProductId [Swapped Product Id],
	CASE
		WHEN organisationproduct.OrganisationProductId = rep.OrganisationProductId THEN 'Same Product'
		ELSE 'Different Product'
	END [Swapout Type],
	organisationproduct.[Description] [Original Description],
	rep.[Description] [Swapped Description],
	organisationproduct.ItemSize [Original Item Size],
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
    CONCAT(orderItem.SIC, ' (', supplierproduct.[Priority], ')') [Original Sic],
	CONCAT([Swapped Sic], ' (', rep.[Priority], ')') [Swapped Sic],
	CASE
		WHEN organisationproduct.OrganisationProductId = rep.OrganisationProductId THEN CONCAT(supplier.SupplierName, ' (S)')
		ELSE CONCAT(supplier.SupplierName, ' (D)')
	END [Supplier Swapout Type]
FROM [order]
INNER JOIN orderitem ON [order].orderId = orderItem.OrderId
INNER JOIN store ON [order].StoreId = store.StoreId
INNER JOIN organisationproduct ON orderItem.OrganisationProductId = organisationproduct.OrganisationProductId
INNER JOIN supplier ON [order].SupplierId = supplier.SupplierId
INNER JOIN supplierproduct ON supplierproduct.OrganisationProductId = orderItem.OrganisationProductId AND supplierproduct.SupplierId = [order].SupplierId AND supplierproduct.Sic = orderItem.SIC
INNER JOIN (
	SELECT 
		delivery.OrderId, 
		SubstitutedOrderItemId,
		SUM(NumberOfCasesDelivered) NumberOfCasesDelivered
	FROM delivery
	INNER JOIN deliveryItem ON delivery.DeliveryId = deliveryItem.DeliveryId and SubstitutedOrderItemId IS NOT NULL
	GROUP BY
		delivery.OrderId, 
		SubstitutedOrderItemId
) sub ON sub.SubstitutedOrderItemId = orderItem.ExternalOrderItemId 
INNER JOIN (
	SELECT 
		orderitem.OrderId, 
		orderitem.ExternalOrderItemId, 
		rep.ExternalOrderItemId replacementId,
		rep.SIC [Swapped SIC],
		supplierproduct.CaseSize,
		supplierproduct.CostPrice,
		supplierproduct.[Priority],
		organisationproduct.[Description],
		organisationproduct.ItemSize,
		organisationproduct.OrganisationProductId,
		supplier.SupplierName,
		SUM(NumberOfCasesDelivered) [Swapped Cases Delivered]
	from orderitem
	INNER JOIN [order] ON [order].OrderId = orderItem.OrderId
	INNER JOIN delivery ON delivery.OrderId = orderItem.OrderId
	INNER JOIN deliveryItem ON delivery.deliveryId = deliveryItem.deliveryid AND deliveryItem.SubstitutedOrderItemId = orderItem.ExternalOrderItemId
	INNER JOIN orderitem rep ON orderitem.OrderId = rep.OrderId AND rep.SIC = deliveryItem.Sic AND rep.StoreProductId = deliveryItem.StoreProductId
	INNER JOIN supplierproduct ON supplierproduct.OrganisationProductId = rep.OrganisationProductId AND supplierproduct.SupplierId = [order].SupplierId AND supplierproduct.Sic = rep.SIC
	INNER JOIN organisationproduct ON rep.OrganisationProductId = organisationproduct.OrganisationProductId
	INNER JOIN supplier ON [order].SupplierId = supplier.SupplierId
	GROUP BY
		orderitem.OrderId, 
		orderitem.ExternalOrderItemId, 
		rep.ExternalOrderItemId,
		rep.SIC,
		supplierproduct.CaseSize,
		supplierproduct.CostPrice, 
		supplierproduct.[Priority],
		organisationproduct.[Description],
		organisationproduct.ItemSize,
		organisationproduct.OrganisationProductId,
		supplier.SupplierName
) rep on rep.OrderId = [order].OrderId AND rep.ExternalOrderItemId = orderItem.ExternalOrderItemId
WHERE orderItem.SIC <> [Swapped SIC]