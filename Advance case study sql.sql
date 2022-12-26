
--Q.1 List all the states in which we have customers who have bought cellphones from 2005 till today?

select
State
from
DIM_LOCATION A
left join FACT_TRANSACTIONS B on A.IDLocation = B.IDLocation 
where
YEAR(date)>=2005
group by
State

--Q.2 what state in the US is buying more samsung cell phones?

select top 1
State, sum(Quantity) as QTY
from
DIM_LOCATION A
left join FACT_TRANSACTIONS B on A.IDLocation = B.IDLocation
inner join DIM_MODEL C on B.IDModel = C.IDModel
inner join DIM_MANUFACTURER D on C.IDManufacturer = D.IDManufacturer
where
Country = 'US' and Manufacturer_Name = 'Samsung'
group by
State
order by
sum(Quantity) desc;

--Q.3 show the number of transactions for each model per zipcode per state?

select
Model_Name, ZipCode, State, count(B.IDLocation) 
from
DIM_LOCATION A
left join FACT_TRANSACTIONS B on A.IDLocation = B.IDLocation
inner join DIM_MODEL C on B.IDModel = C.IDModel
group by
Model_Name, ZipCode, State

--Q.4 show the cheapest cellphone?

select top 1
Manufacturer_Name, Model_Name, sum(unit_price) as price
from
DIM_MODEL A
inner join DIM_MANUFACTURER B on A.IDManufacturer = B.IDManufacturer
group by
Manufacturer_Name, Model_Name

--Q.5 find out the avg price for each model in the top 5 manufacturers in terms of sales quantity and order by avg price?

select
Manufacturer_Name, Model_Name, AVG(Unit_price) as average_price
from
FACT_TRANSACTIONS A 
left join DIM_MODEL B on A.IDModel = B.IDModel
inner join DIM_MANUFACTURER C on B.IDManufacturer = C.IDManufacturer
where
Manufacturer_Name in 
(select top 5
Manufacturer_Name
from
FACT_TRANSACTIONS A 
left join DIM_MODEL B on A.IDModel = B.IDModel
INNER JOIN DIM_MANUFACTURER C on B.IDManufacturer = C.IDManufacturer
group by
Manufacturer_Name
order by 
sum(Quantity) desc)
group by
Manufacturer_Name, Model_Name
order by 
average_price

-- Q.6 List the name of the customers and the avg amount spend in 2009, where the avg is higher than 500?

select
Customer_Name, AVG(totalprice) as Avg_price
from
FACT_TRANSACTIONS A
left join DIM_CUSTOMER B on A.IDCustomer = B.IDCustomer
where
YEAR(date) = 2009
group by
Customer_Name
having
AVG(totalprice)>500;

--Q.7 List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008,2009, 2010.

SELECT * FROM
(Select Top 5 B.Model_Name from Fact_Transactions A
left join DIM_MODEL B on A.IDModel = B.IDModel
Where Year(date) =2008
Group by 
B.Model_Name
Order by 
SUM(Quantity) DESC
INTERSECT
Select Top 5 B.Model_Name from Fact_Transactions A
left join DIM_MODEL B on A.IDModel = B.IDModel
Where Year(date) = 2009
Group by 
B.Model_Name
Order by SUM(Quantity) DESC
INTERSECT
Select Top 5 B.Model_Name from Fact_Transactions A
left join DIM_MODEL B on A.IDModel = B.IDModel
Where Year(date) = 2010
Group by 
B.Model_Name
Order by 
SUM(Quantity) DESC) A

--Q.8 Show the manufacturer with 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year 2010?

select * from
(select
year, Manufacturer_Name, SUM(TotalPrice) as sales, DENSE_RANK() over (order by sum(totalprice) desc) as [rank]
from
FACT_TRANSACTIONS A
left join DIM_MODEL B on A.IDModel = B.IDModel
inner join DIM_MANUFACTURER C on B.IDManufacturer = C.IDManufacturer
inner join DIM_DATE D on A.Date = D.DATE
where YEAR = 2009
group by
year, Manufacturer_Name) as t1
where
[rank] = 2

union

select * from
(select
year, Manufacturer_Name, SUM(TotalPrice) as sales, DENSE_RANK() over (order by sum(totalprice) desc) as [rank]
from
FACT_TRANSACTIONS A
left join DIM_MODEL B on A.IDModel = B.IDModel
inner join DIM_MANUFACTURER C on B.IDManufacturer = C.IDManufacturer
inner join DIM_DATE D on A.Date = D.DATE
where YEAR = 2010
group by
year, Manufacturer_Name) as t2
where
[rank] = 2

--Q.9 show the manufacturers that sold cellphones in 2010 but didnt in 2009.

select
Manufacturer_Name
from
FACT_TRANSACTIONS A
left join DIM_MODEL B on A.IDModel = B.IDModel
inner join DIM_MANUFACTURER C on B.IDManufacturer = C.IDManufacturer
inner join DIM_DATE D on A.Date = D.DATE
where
YEAR = 2010
group by 
Manufacturer_Name

except

select
Manufacturer_Name
from
FACT_TRANSACTIONS A
left join DIM_MODEL B on A.IDModel = B.IDModel
inner join DIM_MANUFACTURER C on B.IDManufacturer = C.IDManufacturer
inner join DIM_DATE D on A.Date = D.DATE
where
YEAR = 2009
group by 
Manufacturer_Name

--Q.10 find top 10 customers and their avg spend, average qty by each year. also find pecentage of change in their spend.

with topcustomers as(
SELECT distinct top 10
idcustomer,
SUM(TOTALPRICE) over (partition by IDCUSTOMER) as TotalSPEND
FROM FACT_TRANSACTIONS
order by TotalSPEND desc
), cte as (
SELECT
distinct
t.IDCUSTOMER, YEAR(t.DATE) [YEAR], TotalSPEND,
AVG(t.QUANTITY * 1.0) over (partition by t.IDCUSTOMER, YEAR(t.DATE)) as AverageQUANTITY,
AVG(t.TOTALPRICE * 1.0) over (partition by t.IDCUSTOMER, YEAR(t.DATE)) as AverageSPEND
FROM FACT_TRANSACTIONS t
INNER JOIN topcustomers c on c.IDCUSTOMER = t.IDCUSTOMER
)
select 
*,
( AverageSPEND - lag(AverageSPEND,1) over (partition by IDCUSTOMER order by [YEAR]) ) * 100.0 / AverageSPEND as [%Change]
from cte