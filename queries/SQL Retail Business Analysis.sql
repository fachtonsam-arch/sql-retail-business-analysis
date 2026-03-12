-- QUERY 1: Furniture Quarterly Sales Trend
/*
How did Furniture category revenue trend across quarters from 2014 to 2016,
and which period delivered the strongest quarter-over-quarter growth?
*/

SELECT
    CONCAT('Q', DATEPART(QUARTER, o.ORDER_DATE), '-', DATEPART(YEAR, o.ORDER_DATE)) AS QuarterLabel,
   round(SUM(o.SALES), 2) AS TotalFurnitureSales
FROM ORDERS o
JOIN PRODUCT p
    ON o.PRODUCT_ID = p.ID
WHERE p.NAME = 'Furniture'
GROUP BY
    DATEPART(YEAR, o.ORDER_DATE),
    DATEPART(QUARTER, o.ORDER_DATE)
ORDER BY
    DATEPART(YEAR, o.ORDER_DATE),
    DATEPART(QUARTER, o.ORDER_DATE);


-- QUERY 2: Discount Impact on Profitability
/*
How does discount depth affect profitability across product categories,
and at what discount tier does the business shift from profit to loss?

Discount level condition:
No Discount = 0
0 < Low Discount <= 0.2
0.2 < Medium Discount <= 0.5
High Discount > 0.5
*/

WITH DiscountClass AS (
    SELECT
        p.CATEGORY AS ProductCategory,
        o.ORDER_ID,
        o.SALES,
        o.PROFIT,
        o.DISCOUNT,
        CASE
            WHEN o.DISCOUNT = 0 THEN 'No Discount'
            WHEN o.DISCOUNT > 0 AND o.DISCOUNT <= 0.2 THEN 'Low Discount'
            WHEN o.DISCOUNT > 0.2 AND o.DISCOUNT <= 0.5 THEN 'Medium Discount'
            WHEN o.DISCOUNT > 0.5 THEN 'High Discount'
        END AS DiscountLevel
    FROM ORDERS o
    JOIN PRODUCT p
        ON o.PRODUCT_ID = p.ID
)
SELECT
    ProductCategory,
    DiscountLevel,
    COUNT(DISTINCT ORDER_ID) AS NumberOfOrders,
    ROUND(SUM(SALES), 2) AS TotalSales,
    ROUND(SUM(PROFIT), 2) AS TotalProfit
FROM DiscountClass
GROUP BY
    ProductCategory,
    DiscountLevel
ORDER BY
    ProductCategory,
    DiscountLevel;


-- QUERY 3: Top Categories by Customer Segment
/*
Which product categories drive the most revenue and profit within each customer segment,
and does the highest-selling category always yield the highest profit margin?
*/

WITH CategoryPerformance AS (
    SELECT
        c.SEGMENT AS CustomerSegment,
        p.CATEGORY AS ProductCategory,
        SUM(o.SALES) AS TotalSales,
        SUM(o.PROFIT) AS TotalProfit
    FROM ORDERS o
    JOIN PRODUCT p
        ON o.PRODUCT_ID = p.ID
    JOIN CUSTOMER c
        ON o.CUSTOMER_ID = c.ID
    GROUP BY
        c.SEGMENT,
        p.CATEGORY
),
RankedCategories AS (
    SELECT
        CustomerSegment,
        ProductCategory,
        RANK() OVER (
            PARTITION BY CustomerSegment
            ORDER BY TotalSales DESC
        ) AS SalesRank,
        RANK() OVER (
            PARTITION BY CustomerSegment
            ORDER BY TotalProfit DESC
        ) AS ProfitRank
    FROM CategoryPerformance
)
SELECT
    CustomerSegment,
    ProductCategory,
    SalesRank,
    ProfitRank
FROM RankedCategories
WHERE ProfitRank <= 2
ORDER BY
    CustomerSegment,
    ProfitRank,
    SalesRank;


-- QUERY 4: Employee Profit Distribution by Category
/*
How is each sales employee's profit distributed across product categories,
and which employees are over-reliant on a single category?
*/

WITH EmployeeCategoryTotals AS (
    SELECT
        e.ID_EMPLOYEE AS EmployeeID,
        p.CATEGORY AS ProductCategory,
        SUM(o.PROFIT) AS CategoryProfit
    FROM ORDERS o
    JOIN EMPLOYEES e
        ON e.ID_EMPLOYEE = o.ID_EMPLOYEE
    JOIN PRODUCT p
        ON p.ID = o.PRODUCT_ID
    GROUP BY
        e.ID_EMPLOYEE,
        p.CATEGORY
),
EmployeeTotals AS (
    SELECT
        EmployeeID,
        SUM(CategoryProfit) AS EmployeeTotalProfit
    FROM EmployeeCategoryTotals
    GROUP BY EmployeeID
),
Final AS (
    SELECT
        c.EmployeeID,
        c.ProductCategory,
        FORMAT
            (ROUND(c.CategoryProfit, 2), 'N2')
            AS Rounded_Total_Profit,
        c.CategoryProfit * 1.0 / NULLIF(t.EmployeeTotalProfit, 0) AS ProfitPct
    FROM EmployeeCategoryTotals c
    JOIN EmployeeTotals t
        ON c.EmployeeID = t.EmployeeID
)
SELECT
    EmployeeID,
    ProductCategory,
    Rounded_Total_Profit,
    FORMAT(ProfitPct * 100, 'N2') AS Profit_Percentage
FROM Final
ORDER BY
    EmployeeID,
    ProfitPct DESC;


-- QUERY 5: Profitability Ratio Analysis
/*
Which product categories deliver the highest profit-per-dollar-of-sales for each employee,
and where should the business redirect its sales focus?
*/

-- Create user-defined, scalar-valued Function
ALTER FUNCTION dbo.fnProfitabilityRatio
(
    @Profit DECIMAL(18,4),
    @Sales  DECIMAL(18,4)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Ratio DECIMAL(18,2);

    IF @Sales IS NULL OR @Sales = 0
        SET @Ratio = 0;
    ELSE
        SET @Ratio = ROUND(@Profit / @Sales, 2);

    RETURN @Ratio;
END;
GO

-- Generate a report for employees' performance

WITH EmployeeCategoryTotals AS (
    SELECT
        e.ID_EMPLOYEE AS EmployeeID,
        p.CATEGORY     AS ProductCategory,
        SUM(o.SALES)   AS CategorySales,
        SUM(o.PROFIT)  AS CategoryProfit
    FROM ORDERS o
    JOIN EMPLOYEES e
        ON e.ID_EMPLOYEE = o.ID_EMPLOYEE
    JOIN PRODUCT p
        ON p.ID = o.PRODUCT_ID
    GROUP BY
        e.ID_EMPLOYEE,
        p.CATEGORY
)

SELECT
    EmployeeID,
    ProductCategory,
    FORMAT(ROUND(CategorySales, 2), '0.##') AS TotalSales,
    FORMAT(ROUND(CategoryProfit, 2), '0.##') AS TotalProfit,
    ROUND(
        dbo.fnProfitabilityRatio(CategoryProfit, CategorySales),
        2
    ) AS ProfitabilityRatio
FROM EmployeeCategoryTotals
ORDER BY
    EmployeeID,
    dbo.fnProfitabilityRatio(CategoryProfit, CategorySales) DESC;


-- QUERY 6: Employee Performance Query Tool
/*
How can management efficiently query any employee's sales and profit for any custom time window
— enabling on-demand performance reviews?
*/

-- Set up stored procedure
ALTER PROCEDURE dbo.GetEmployeeSalesProfit
    @EmployeeID INT,
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        e.[NAME] AS Employee_Name,
        FORMAT(ROUND(SUM(o.SALES), 2), '0.##')  AS Total_Sales,
        FORMAT(ROUND(SUM(o.PROFIT), 2), '0.##') AS Total_Profit
    FROM ORDERS o
    JOIN EMPLOYEES e
        ON e.ID_EMPLOYEE = o.ID_EMPLOYEE
    WHERE
        e.ID_EMPLOYEE = @EmployeeID
        AND o.ORDER_DATE >= @StartDate
        AND o.ORDER_DATE <= @EndDate
    GROUP BY
        e.[Name];
END;
GO

-- Example execution
EXEC dbo.GetEmployeeSalesProfit
    @EmployeeID = 3,
    @StartDate = '2016-12-01',
    @EndDate = '2016-12-31';


-- QUERY 7: Regional Profit Pivot — State × Quarter
/*
How did profit performance vary across US states over the last 6 quarters,
and which states show consistent growth vs. decline?
*/

-- Change datatype of column profit to 2 decimals
ALTER TABLE ORDERS
ALTER COLUMN PROFIT DECIMAL(18,2);

------
DECLARE @cols NVARCHAR(MAX);
DECLARE @sql  NVARCHAR(MAX);

-- Get the automatic 6 latest quarters from the data
WITH QuarterData AS (
    SELECT DISTINCT
        CONCAT('Q', DATEPART(QUARTER, ORDER_DATE), '-', DATEPART(YEAR, ORDER_DATE)) AS QuarterLabel,
        DATEPART(YEAR, ORDER_DATE) AS Yr,
        DATEPART(QUARTER, ORDER_DATE) AS Qtr
    FROM ORDERS
)
SELECT @cols = STRING_AGG(QUOTENAME(QuarterLabel), ',')
FROM (
    SELECT TOP 6 QuarterLabel, Yr, Qtr
    FROM QuarterData
    ORDER BY Yr DESC, Qtr DESC
) AS x;

-- Build the dynamic pivot SQL
SET @sql = '
    SELECT State, ' + @cols + '
    FROM (
        SELECT
            c.STATE AS State,
            CONCAT(''Q'', DATEPART(QUARTER, o.ORDER_DATE), ''-'', DATEPART(YEAR, o.ORDER_DATE)) AS QuarterLabel,
            ROUND(o.PROFIT, 2) AS Profit
        FROM ORDERS o
        JOIN CUSTOMER c
            ON o.CUSTOMER_ID = c.ID
    ) AS src
    PIVOT (
        SUM(Profit)
        FOR QuarterLabel IN (' + @cols + ')
    ) AS p
    ORDER BY State;
';

-- Execute
EXEC sp_executesql @sql;
