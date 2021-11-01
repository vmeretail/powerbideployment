CREATE OR ALTER VIEW [dbo].[uvwDeliveriesWithItemsReporting]
AS

SELECT d.[AddedToStock],
	   d.[AddedToStockByUser],
	   d.[AddedToStockDateTime],
	   d.[DeliveryDateTime],
	   d.[DeliveryId],
	   d.[DeliveryType],
	   d.[ExternalDeliveryCode],
	   d.[ExternalOrderId],
	   d.[ExternalSupplierId],
	   d.[StoreId],
	   d.[SupplierId],
	   di.[ExternalDeliveryItemId],
	   di.[NumberOfCasesDelivered],
	   di.[Sic],
	   di.[StoreProductId],
	   di.[SubstitutedOrderItemId],
	   di.[VmeCode]
  FROM [delivery] as d
  left join [deliveryItem] as di on d.DeliveryId = di.DeliveryId