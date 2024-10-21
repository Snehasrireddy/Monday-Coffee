create database monday_coffee;
use Monday_coffee;

select * from city;
select * from customers;
select * from products;
select * from sales;

select population from city where isnumeric(population) = 0;
select try_convert(numeric(10,2),population) from city;


-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?
select count(customer_name) as Total_people,city_name,population,(population * 0.25) as estimated_coffee_consumers
 from city,customers group by customer_name,city_name,population;

-- Q.2 Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT SUM(cast(Total as int)) AS total_revenue FROM sales
WHERE sale_date >= '2023-10-01' 
AND sale_date <= '2023-12-31';

-- Q.3 Sales Count for Each Product
-- How many units of each coffee product have been sold?
select distinct product_name,count(sale_id) as units_sold from sales s left join products p on p.product_id=s.product_id group by product_name,sale_id order by product_name desc; 

-- Q.4 Sales Count for Each Product
-- What is the average sales amount per customer in each city?
select count(distinct c.customer_id) as total_count,sum(cast(s.total as int)) as total_revenue,avg(cast(total as int)) as average_sales,ci.city_name from customers as c 
join sales s on c.customer_id=s.customer_id 
join city ci on c.city_id=ci.city_id
group by total,customer_name,c.customer_id,city_name;

-- Q.5 City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers return city_name, total current cx, estimated coffee consumers (25%)?
SELECT ci.city_name,
       ci.population,
       COUNT(c.customer_id) AS total_current_customers,
       ci.population * 0.25 AS estimated_coffee_consumers
FROM city ci
LEFT JOIN customers c ON ci.city_id = c.city_id
GROUP BY ci.city_name, ci.population;

-- Q.6 Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?
select Top 3 * from(select distinct p.product_name,count(s.sale_id),ci.city_name from sales s 
join products p on p.product_id=s.product_id 
join customers as c on c.customer_id=s.customer_id
join city as ci on ci.city_id=c.city_id 
group by ci.city_name,p.product_name,s.sale_id 
order by count(s.sale_id) desc) as t;

-- Q.7 Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?
SELECT 
    ci.city_name,
    COUNT(DISTINCT c.customer_id) as unique_customers
FROM 
    customers c
LEFT JOIN 
    city ci ON ci.city_id = c.city_id
JOIN 
    sales s ON s.customer_id = c.customer_id
JOIN 
    products p ON s.product_id = p.product_id
WHERE 
    p.product_name LIKE '%Coffee%'
GROUP BY 
    ci.city_name;


-- Q.8 Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer?
select distinct ci.city_name,sum(cast(s.total as int))/count(distinct c.customer_id) as avg_sale_per_customer,
ci.estimated_rent/count(distinct c.customer_id) as avg_rent_per_customer from city ci 
join customers c on c.city_id=ci.city_id
join sales s on c.customer_id=s.customer_id 
group by city_name,sale_id,estimated_rent;

-- Q.9 Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly) by each city?

WITH MonthlySales AS (
    SELECT 
        c.city_name,
        YEAR(s.sale_date) AS SaleYear,
        MONTH(s.sale_date) AS SaleMonth,
        SUM(s.total) AS TotalSales
    FROM sales s
    JOIN customers cu ON s.customer_id = cu.customer_id
    JOIN city c ON cu.city_id = c.city_id
    GROUP BY c.city_name, YEAR(s.sale_date), MONTH(s.sale_date)
),
SalesGrowth AS (
    SELECT
        city_name,
        SaleYear,
        SaleMonth,
        TotalSales,
        LAG(TotalSales) OVER (PARTITION BY city_name ORDER BY SaleYear, SaleMonth) AS PreviousMonthSales,
        ((TotalSales - LAG(TotalSales) OVER (PARTITION BY city_name ORDER BY SaleYear, SaleMonth)) / LAG(TotalSales) OVER (PARTITION BY city_name ORDER BY SaleYear, SaleMonth)) * 100 AS GrowthRate
    FROM MonthlySales
)
SELECT 
    city_name,
    SaleYear,
    SaleMonth,
    TotalSales,
    PreviousMonthSales,
    GrowthRate
FROM SalesGrowth
WHERE PreviousMonthSales IS NOT NULL
ORDER BY city_name, SaleYear, SaleMonth;

-- Q.10 Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer?

SELECT Top 3 ci.city_name,
       SUM(cast(s.total as int)) AS total_sales,
       SUM(cast(ci.estimated_rent as int)) AS total_rent,
       COUNT(DISTINCT c.customer_id) AS total_customers,
       ci.population * 0.25 AS estimated_coffee_consumers
FROM city ci
LEFT JOIN customers c ON ci.city_id = c.city_id
LEFT JOIN sales s ON c.customer_id = s.customer_id
GROUP BY ci.city_name, ci.population, ci.estimated_rent,s.total
ORDER BY total DESC;