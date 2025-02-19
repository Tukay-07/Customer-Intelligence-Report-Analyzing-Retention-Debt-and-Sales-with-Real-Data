								---ENUGU SALES OUTLET ANALYSIS

										---KEY METRICS
---RETENTION RATE

WITH Retained_customers AS(
	SELECT 
		COUNT(DISTINCT customer_id) AS Retained_count
	FROM 
		Customer_records
	WHERE
		Last_visit>= DATEADD(month, -18, GETDATE()) -- Retained within the last 18 months
),
	Total_customers AS(
	SELECT
		COUNT(DISTINCT customer_id) AS Total_count
	FROM
		Customer_records
)
SELECT ROUND((Retained_count *100.0)/ NULLIF(Total_count, 0),3) AS Retention_rate
FROM Retained_customers, Total_customers

-- ACTIVE/INACTIVE 

SELECT 
	Customer_id, Customer_name, Last_visit
FROM 
	Customer_records
WHERE 
	Last_visit>= DATEADD(MONTH,-18,GETDATE())  ---active customers


SELECT 
	Customer_id, Customer_name, Last_visit
FROM 
	Customer_records
WHERE 
	Last_visit< DATEADD(MONTH,-18,GETDATE()) --inactive customers

-- Average Visits

SELECT
 AVG(Total_visits) AS Average_visits
 FROM
	Customer_records

-- Total debt

SELECT
	SUM(balance) AS Total_outstanding_debt
FROM
	Customer_records

-- Total Sales

SELECT
	SUM(Total_sales) AS Total_sales
FROM
	Customer_records

-- DEBT TO SALES RATIO

SELECT
	SUM(balance) *1.0 / SUM(Total_sales)
FROM
	Customer_records

												-- ANALYSIS --

										-- Customer Loyalty and Activity

-- Who are the most loyal customers based on visits and sales? (Top 10)

SELECT TOP 10
	Customer_id,
	Customer_name,
	SUM(Total_visits) AS Total_visits
FROM
	Customer_records
GROUP BY
	Customer_name,Customer_id
ORDER BY
	 Total_visits DESC 

SELECT TOP 10
	Customer_id,
	Customer_name,
	SUM(Total_sales) AS Total_sales
FROM
	Customer_records
GROUP BY
	Customer_name,Customer_id
ORDER BY
	 Total_sales DESC

-- How many customers are inactive? (Total number and percentage)
	 
SELECT 
	COUNT(*) AS Total_inactive,
	(COUNT(*)* 100.0) / (SELECT COUNT(*) FROM Customer_records) AS Inactive_percent
FROM 
	Customer_records
WHERE 
	DATEDIFF(MONTH,Last_visit,GETDATE()) >18

-- Financial and Debt Analysis

-- Who has the highest outstanding balance, and when was their last visit?

SELECT
	customer_name,
	customer_id,
	balance,
	last_visit
FROM
	Customer_records
WHERE 
	Balance > 0
ORDER BY
	Balance DESC

SELECT 
	customer_id,
	customer_name,
	Balance,
	Last_visit
FROM
	Customer_records
WHERE
	Balance > (SELECT AVG(balance) FROM Customer_records)
ORDER BY
	Balance DESC

-- Total debt

SELECT
	SUM(balance) AS Total_outstanding_debt
FROM
	Customer_records

-- Do discounts result in higher purchases? (Correlation)

WITH Stats AS (
    SELECT 
        COUNT(*) AS N,
        SUM(Discount) AS SumX,
        SUM(Total_sales) AS SumY,
        SUM(Discount * Total_sales) AS SumXY,
        SUM(Discount * Discount) AS SumX2,
        SUM(Total_sales * Total_sales) AS SumY2
    FROM Customer_Records
)
SELECT 
    (N * SumXY - SumX * SumY) / 
    SQRT((N * SumX2 - SumX * SumX) * (N * SumY2 - SumY * SumY)) AS Correlation
FROM Stats;

-- Which customer has enjoyed the most savings/discount?

SELECT TOP 10
	customer_name,
	customer_id,
	savings
FROM
	Customer_records
ORDER BY
	Savings DESC

-- What is the savings-to-sales ratio overall and for each customer?

SELECT
	SUM(savings) *1.0 / SUM(Total_sales) as Overall_savings_sales_ratio
FROM 
	Customer_records

SELECT
	customer_id,
	customer_name,
	SUM(savings) *1.0 / SUM(Total_sales) as savings_sales_ratio
FROM 
	Customer_records
GROUP BY
	Customer_id,Customer_name
ORDER BY
	savings_sales_ratio DESC

-- Credit and Purchasing Behavior

-- Does credit limit impact purchasing behavior?

SELECT 
    -- Correlation between Credit Limit and Total Sales
    (COUNT(*) * SUM(CAST(Credit_Limit AS FLOAT) * CAST(Total_Sales AS FLOAT)) - 
     SUM(CAST(Credit_Limit AS FLOAT)) * SUM(CAST(Total_Sales AS FLOAT))) /
    NULLIF(
        SQRT(
            (COUNT(*) * SUM(CAST(Credit_Limit AS FLOAT) * CAST(Credit_Limit AS FLOAT)) - 
             POWER(SUM(CAST(Credit_Limit AS FLOAT)), 2)) * 
            (COUNT(*) * SUM(CAST(Total_Sales AS FLOAT) * CAST(Total_Sales AS FLOAT)) - 
             POWER(SUM(CAST(Total_Sales AS FLOAT)), 2))
        ), 0
    ) AS CreditSalesCorrelation,

    -- Correlation between Credit Limit and Balance
    (COUNT(*) * SUM(CAST(Credit_Limit AS FLOAT) * CAST(Balance AS FLOAT)) - 
     SUM(CAST(Credit_Limit AS FLOAT)) * SUM(CAST(Balance AS FLOAT))) /
    NULLIF(
        SQRT(
            (COUNT(*) * SUM(CAST(Credit_Limit AS FLOAT) * CAST(Credit_Limit AS FLOAT)) - 
             POWER(SUM(CAST(Credit_Limit AS FLOAT)), 2)) * 
            (COUNT(*) * SUM(CAST(Balance AS FLOAT) * CAST(Balance AS FLOAT)) - 
             POWER(SUM(CAST(Balance AS FLOAT)), 2))
        ), 0
    ) AS CreditBalanceCorrelation

FROM Customer_Records;

-- Revenue and Sales Insights
-- What is the revenue trend based on visit frequency?

SELECT
    Customer_name,
    Customer_id,
    Total_visits,
    Total_sales,
    ROUND((Total_sales * 1.0) / NULLIF(Total_visits, 0),3) AS Rev_per_visit
FROM
    Customer_records
GROUP BY
    Customer_id, Customer_name, Total_visits, Total_sales
ORDER BY
    Total_visits DESC;

-- List the top 20 customers with the most sales.

SELECT TOP 20 
	Customer_ID, 
	Customer_name, 
	SUM(Total_Sales) AS TotalSales
FROM 
	Customer_Records
GROUP BY 
	Customer_ID, Customer_name
ORDER BY 
	TotalSales DESC;


-- How many of the top customers are still active?

WITH Top_customers AS (
    SELECT TOP 20 Customer_id, Customer_name
    FROM Customer_records
    ORDER BY Total_sales DESC
),
Active_customers AS (
    SELECT DISTINCT Customer_id
    FROM Customer_records
    WHERE Last_visit >= DATEADD(MONTH, -18, GETDATE())
)
SELECT 
    Customer_name,
    COUNT(Customer_id) OVER () AS Active_top_customers
FROM Top_customers
WHERE Customer_id IN (SELECT Customer_id FROM Active_customers);
