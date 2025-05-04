-- 1. Remove Duplicates
Select TransactionID, count(*) 
from sales_transaction
group by TransactionID
having count(*)>1;

create table nw_sales_transaction as 
select  Distinct * from sales_transaction;

drop table sales_transaction;

alter table nw_sales_transaction
rename to sales_transaction;

select * from sales_transaction;

-- 2. Fixing Incorrect Prices
select a.TransactionID, a.Price as TransactionPrice, b.Price as InventoryPrice
from sales_transaction a 
inner join product_inventory b 
on a.ProductID = b.ProductID
where a.price<>b.price;

update sales_transaction a 
inner join product_inventory b 
on a.ProductID = b.ProductID
set a.price=b.price;

select * from sales_transaction;

-- 3. Fixing Null Values
select count(*)
from customer_profiles 
where Location is null;

update customer_profiles
set Location= 'Unknown'
where Location is null;

select * from customer_profiles;

-- 4. Cleaning Date
create table nw_sales_transaction as
select * from sales_transaction;

alter table nw_sales_transaction
add column TransactionDate_updated date;

update nw_sales_transaction
set TransactionDate_updated= str_to_date(TransactionDate, '%Y-%c-%d');

drop table sales_transaction;

alter table nw_sales_transaction
rename to sales_transaction;

select * from sales_transaction;

-- 5. Total Sales Summary
Select productID, sum(quantityPurchased) as TotalUnitsSold, sum(quantityPurchased*Price) as TotalSales
from sales_transaction  
group by ProductID
order by TotalSales desc;

-- 6. Customer Purchase Frequency
Select CustomerID, count(*) as NumberOfTransactions
from Sales_transaction 
group by CustomerID
order by NumberOfTransactions desc;

-- 7. Product Categories Performance
Select p.category, sum(s.quantityPurchased) as TotalUnitsSold, sum(s.quantityPurchased*s.Price) as TotalSales
from sales_transaction s 
join product_inventory p on s.ProductID = p.ProductID
group by p.category
order by TotalSales desc;

-- 8. High Sales Products
Select ProductID, sum(quantityPurchased* Price) as TotalRevenue
from sales_transaction 
group by ProductID
order by TotalRevenue desc
limit 10;

-- 9. Low Sales Products
select ProductID, sum(quantityPurchased) as TotalUnitsSold
from sales_transaction 
group by ProductID
having TotalUnitsSold>1
order by TotalUnitsSold 
limit 10;

-- 10. Sales Trend
select date_format(TransactionDate, '%Y-%m-%d') as Datetrans, count(*) as Transaction_count, 
		sum(quantityPurchased) as TotalUnitsSold, sum(quantityPurchased*Price) as TotalSales
from sales_transaction 
group by Datetrans
order by Datetrans desc;

-- 11. Growth rate of Sales
WITH monthly_sales AS (
    SELECT 
        EXTRACT(MONTH FROM TransactionDate) AS month,
        SUM(QuantityPurchased * Price) AS total_sales
    FROM 
        sales_transaction
    GROUP BY 
        EXTRACT(MONTH FROM TransactionDate)
)
Select month, total_sales,
    LAG(total_sales) OVER (ORDER BY month) AS previous_month_sales,
    ((total_sales - LAG(total_sales) OVER (ORDER BY month)) 
        / LAG(total_sales) OVER (ORDER BY month)) * 100 AS mom_growth_percentage
from
    monthly_sales
order by month;

-- 12. High Purchase Frequency
Select CustomerID, count(TransactionID) as NumberOfTransactions, sum(quantityPurchased*Price) as TotalSpent
from sales_transaction 
group by CustomerID
having NumberOfTransactions>10 and TotalSpent>1000
order by TotalSpent desc;

-- 13. Occasional Customers
Select CustomerID, count(TransactionID) as NumberOfTransactions, sum(quantityPurchased*Price) as TotalSpent
from Sales_transaction
group by CustomerID
having NumberOfTransactions<=2 
order by NumberOfTransactions asc, TotalSpent desc;

-- 14. Repeat Purchases
Select CustomerID, ProductID, count(TransactionID) as TimesPurchased
from Sales_transaction 
group by CustomerID, ProductID
having TimesPurchased>1
order by TimesPurchased desc;

-- 15. Loyalty Indicators
Select CustomerID, min(TransactionDate) as FirstPurchase, max(TransactionDate) as LastPurchase, datediff(max(TransactionDate), min(TransactionDate)) as DaysBetweenPurchases
from Sales_transaction 
group by CustomerID
having DaysBetweenPurchases >0
order by DaysBetweenPurchases desc;

-- 16. Customer Segmentation
Create table Customer_segment as 
Select case when TotalQuantityPurchased>30 then 'High' 
                   when TotalQuantityPurchased>=10 then 'Med'
                   when TotalQuantityPurchased>0 then 'Low' end as CustomerSegment,
            count(*)
from 
(Select s.CustomerID, sum(s.quantityPurchased) as TotalQuantityPurchased
From Sales_transaction s 
join Customer_profiles c on c.CustomerID = s.CustomerID
group by CustomerID) c
group by CustomerSegment;

select * from Customer_segment;
