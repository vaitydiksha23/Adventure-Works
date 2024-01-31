-- What are our best products and salespeople, and how can we use this information to improve our overall performance?

-- finding our most popular products
SELECT prod.ProductID, prod.Name, AVG(prodrev.Rating) AS avg_rating, COUNT(prodrev.Rating) AS no_of_ratings
FROM Production.Product AS prod
INNER JOIN Production.ProductReview AS prodrev
ON prod.ProductID = prodrev.ProductID
GROUP BY prod.ProductID, prod.Name

SELECT prod_mpdc.ProductModelID, descrp.Description
FROM Production.productModelProductDescriptionCulture AS prod_mpdc
INNER JOIN Production.productDescription AS descrp
ON prod_mpdc.ProductDescriptionID = descrp.ProductDescriptionID
WHERE prod_mpdc.cultureID = 'en'
ORDER BY prod_mpdc.ProductModelID;

-- total quantity by product ID, name and description 
WITH eng_descrp_CTE AS (
	SELECT prod_mpdc.ProductModelID, descrp.Description
	FROM Production.productModelProductDescriptionCulture AS prod_mpdc
	INNER JOIN Production.productDescription AS descrp
	ON prod_mpdc.ProductDescriptionID = descrp.ProductDescriptionID
WHERE prod_mpdc.cultureID = 'en')
SELECT ed.ProductModelID, ed.Description, prod.Name, SUM(sod.OrderQty) AS total_qty
FROM eng_descrp_CTE AS ed
INNER JOIN Production.Product AS prod
ON ed.ProductModelID = prod.ProductModelID
INNER JOIN Sales.SalesOrderDetail AS sod
ON prod.ProductID = sod.ProductID
GROUP BY ed.ProductModelID, ed.Description, prod.Name
ORDER BY total_qty DESC

-- the quantity of products sold per product ID
SELECT sod.ProductID, SUM(sod.OrderQty) AS quantity 
FROM Sales.SalesOrderDetail AS sod
GROUP BY sod.ProductID

-- the list price for each product alongside its category and subcategory
SELECT prod.ProductID, cat.Name AS category, subcat.Name AS subcategory, prod.ListPrice 
FROM Production.Product AS prod
INNER JOIN Production.productSubcategory AS subcat
ON prod.ProductSubcategoryID = subcat.ProductSubcategoryID
INNER JOIN Production.ProductCategory AS cat
ON subcat.ProductCategoryID = cat.ProductCategoryID;

-- the average list price and the total quantity of products sold for each subcategory
WITH sales_CTE AS (
SELECT sod.ProductID, SUM(sod.OrderQty) AS quantity 
FROM Sales.SalesOrderDetail AS sod
GROUP BY sod.ProductID ),
product_CTE AS (
SELECT prod.ProductID, cat.Name AS category, subcat.Name AS subcategory, prod.ListPrice 
FROM Production.Product AS prod
INNER JOIN Production.productSubcategory AS subcat
ON prod.ProductSubcategoryID = subcat.ProductSubcategoryID
INNER JOIN Production.ProductCategory AS cat
ON subcat.ProductCategoryID = cat.ProductCategoryID )
SELECT product_CTE.category, product_CTE.subcategory, AVG(product_CTE.ListPrice) as averageprice, SUM(sales_CTE.quantity) AS totalquantity
FROM product_CTE
INNER JOIN sales_CTE
ON product_CTE.ProductID = sales_CTE.ProductID
GROUP BY product_CTE.category, product_CTE.subcategory
ORDER BY product_CTE.category

-- finding the top salespeople
SELECT sp.BusinessEntityID, sp.SalesYTD
FROM Sales.SalesPerson AS sp
ORDER BY sp.SalesYTD DESC

-- top salespeople in 2014
SELECT soh.SalesPersonID, SUM(soh.SubTotal) AS subtotal
FROM Sales.SalesOrderHeader AS soh
WHERE soh.OrderDate >= '2014-01-01' AND soh.SalesPersonID IS NOT NUll AND soh.SalesPersonID <> ''
GROUP BY soh.SalesPersonID
ORDER BY subtotal DESC

-- total sales per order ID
SELECT sod.SalesOrderID, SUM(sod.UnitPrice * OrderQty * (1 - sod.UnitPriceDiscount)) AS ordertotal
FROM Sales.SalesOrderDetail AS sod
GROUP BY sod.SalesOrderID
ORDER BY sod.SalesOrderID;

-- total sales per salesperson ID
WITH sod_CTE AS (
SELECT sod.SalesOrderID, SUM(sod.UnitPrice * OrderQty * (1 - sod.UnitPriceDiscount)) AS ordertotal
FROM Sales.SalesOrderDetail AS sod
GROUP BY sod.SalesOrderID ),
soh_CTE AS (
SELECT soh.SalesPersonID, SUM(soh.SubTotal) AS subtotal, soh.SalesOrderID
FROM Sales.SalesOrderHeader AS soh
WHERE soh.OrderDate >= '2014-01-01' AND soh.SalesPersonID IS NOT NUll AND soh.SalesPersonID <> ''
GROUP BY soh.SalesPersonID,soh.SalesOrderID )
SELECT soh_CTE.SalesPersonID, SUM(sod_CTE.ordertotal) AS ordertotalsum
FROM sod_CTE 
INNER JOIN soh_CTE
ON sod_CTE.SalesOrderID = soh_CTE.SalesOrderID
GROUP BY soh_CTE.SalesPersonID
ORDER BY ordertotalsum;

-- total sales per salesperson along with commission percentages
WITH sod_CTE AS (
SELECT sod.SalesOrderID, SUM(sod.UnitPrice * OrderQty * (1 - sod.UnitPriceDiscount)) AS ordertotal
FROM Sales.SalesOrderDetail AS sod
GROUP BY sod.SalesOrderID ),
soh_CTE AS (
SELECT soh.SalesPersonID, SUM(soh.SubTotal) AS subtotal, soh.SalesOrderID
FROM Sales.SalesOrderHeader AS soh
WHERE soh.OrderDate >= '2014-01-01' AND soh.SalesPersonID IS NOT NUll AND soh.SalesPersonID <> ''
GROUP BY soh.SalesPersonID,soh.SalesOrderID ),
spts_CTE AS (
SELECT soh_CTE.SalesPersonID, SUM(sod_CTE.ordertotal) AS ordertotalsum
FROM sod_CTE 
INNER JOIN soh_CTE
ON sod_CTE.SalesOrderID = soh_CTE.SalesOrderID
GROUP BY soh_CTE.SalesPersonID )
SELECT spts_CTE.SalesPersonID, spts_CTE.ordertotalsum, sp.CommissionPct
FROM spts_CTE
INNER JOIN Sales.SalesPerson AS sp
ON spts_CTE.SalesPersonID = sp.BusinessEntityID
ORDER BY spts_CTE.SalesPersonID

-- currency rates and codes
SELECT soh.SalesPersonID, soh.SalesOrderID, cr.CurrencyRateID,
CASE 
	WHEN cr.ToCurrencyCode IS NULL THEN 'USD'
	ELSE cr.ToCurrencyCode
END AS ToCurrencyCode
FROM Sales.SalesOrderHeader AS soh
LEFT JOIN Sales.CurrencyRate AS cr
ON soh.CurrencyRateID = cr.CurrencyRateID
WHERE soh.SalesPersonID IS NOT NULL;

-- the best salespeople are for each currency
WITH sod_CTE AS (
SELECT sod.SalesOrderID, SUM(sod.UnitPrice * OrderQty * (1 - sod.UnitPriceDiscount)) AS ordertotal
FROM Sales.SalesOrderDetail AS sod
GROUP BY sod.SalesOrderID ),
soh_CTE AS (
SELECT soh.SalesPersonID, SUM(soh.SubTotal) AS subtotal, soh.SalesOrderID,
CASE 
	WHEN cr.ToCurrencyCode IS NULL THEN 'USD'
	ELSE cr.ToCurrencyCode
END AS ToCurrencyCode
FROM Sales.SalesOrderHeader AS soh
LEFT JOIN Sales.CurrencyRate AS cr
ON soh.CurrencyRateID = cr.CurrencyRateID
WHERE soh.OrderDate >= '2014-01-01' AND soh.SalesPersonID IS NOT NUll AND soh.SalesPersonID <> ''
GROUP BY soh.SalesPersonID,soh.SalesOrderID, cr.ToCurrencyCode ),
spts_CTE AS (
SELECT soh_CTE.SalesPersonID, SUM(sod_CTE.ordertotal) AS ordertotalsum, soh_CTE.ToCurrencyCode
FROM sod_CTE 
INNER JOIN soh_CTE
ON sod_CTE.SalesOrderID = soh_CTE.SalesOrderID
GROUP BY soh_CTE.SalesPersonID, soh_CTE.ToCurrencyCode )
SELECT spts_CTE.SalesPersonID, spts_CTE.ToCurrencyCode, spts_CTE.ordertotalsum, sp.CommissionPct
FROM spts_CTE
INNER JOIN Sales.SalesPerson AS sp
ON spts_CTE.SalesPersonID = sp.BusinessEntityID
ORDER BY spts_CTE.ToCurrencyCode ASC, spts_CTE.ordertotalsum DESC