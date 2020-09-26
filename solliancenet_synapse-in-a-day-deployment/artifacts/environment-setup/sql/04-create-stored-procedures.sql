IF OBJECT_ID(N'[dbo].[Reset_ML_Environment]', N'P') IS NOT NULL   
DROP PROCEDURE [dbo].[Reset_ML_Environment]
GO

CREATE PROC [dbo].[Reset_ML_Environment] AS
BEGIN

delete from FinanceSales;
delete from Customer_SalesLatest;

COPY INTO FinanceSales
FROM 'https://solliancepublicdata.blob.core.windows.net/cdp/csv/FinanceSales.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)

COPY INTO Customer_SalesLatest
FROM 'https://solliancepublicdata.blob.core.windows.net/cdp/csv/Customer_SalesLatest.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)

END
GO

IF OBJECT_ID(N'[dbo].[Delete_SelfReferencing_Product_Recommendations]', N'P') IS NOT NULL   
DROP PROCEDURE [dbo].[Delete_SelfReferencing_Product_Recommendations]
GO

CREATE PROC [dbo].[Delete_SelfReferencing_Product_Recommendations] AS
BEGIN
Delete from ProductRecommendations_Sparkv2 where ProductId = RecommendedProductId
END
GO