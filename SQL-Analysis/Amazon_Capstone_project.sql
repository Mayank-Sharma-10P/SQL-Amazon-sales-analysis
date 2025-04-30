
create table Amazon(
Invoice_ID VARCHAR(30),
Branch VARCHAR(5),
City VARCHAR(30),
Customer_type VARCHAR(30),
Gender VARCHAR(10),
Product_line VARCHAR(100),
Unit_price DECIMAL(10,2),
Quantity INT,
VAT FLOAT(6,4),
Total DECIMAL(10,2),
Date DATE,
Time TIMESTAMP,
Payment DECIMAL(10,2),
cogs DECIMAL(10,2),
gross_margin_percentage FLOAT(11,9),
gross_income DECIMAL(10,2),
Rating FLOAT(2,1) );

LOAD DATA INFILE '/Users/mayan/Downloads/Amazon.csv'
INTO TABLE amazon
FIELDS TERMINATED BY ','
ENCLOSED by '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- data engineering --

Alter table amazon
add column timeofday
varchar(10);

update amazon
set timeofday = case
	when extract(hour from Time) >= 6 and extract(hour from Time) < 12 then "morning"
    when extract(hour from Time) >= 12 and extract(hour from Time) < 18 then "afternoon"
    else "evening"
end;

-- adding dayname column --
alter table amazon
add column dayname varchar(10);

update amazon
set dayname = case
weekday(date)
	when 0 then 'mon'
    when 1 then 'tue'
    when 2 then 'wed'
    when 3 then 'thu'
    when 4 then 'fri'
    when 5 then 'sat'
    when 6 then 'sun'
end;

describe amazon;
    
-- adding monthname column --
alter table amazon
add column monthname varchar(10);

update amazon
set monthname = case
    when MONTHNAME(Date) = 'january' then 'jan'
    when MONTHNAME(Date) = 'february' then 'feb'
    when MONTHNAME(Date) = 'march' then 'mar'
    when MONTHNAME(Date) = 'april' then 'apr'
    when MONTHNAME(Date) = 'may' then 'may'
    when MONTHNAME(Date) = 'june' then 'jun'
    when MONTHNAME(Date) = 'july' then 'jul'
    when MONTHNAME(Date) = 'august' then 'aug'
    when MONTHNAME(Date) = 'september' then 'sep'
    when MONTHNAME(Date) = 'october' then 'oct'
    when MONTHNAME(Date) = 'november' then 'nov'
    when MONTHNAME(Date) = 'december' then 'dec'
    end;
    
    
-- EXPLORATORY DATA ANALYSIS (EDA)--

-- Q1- What is the count of distinct cities in the dataset? --

select count(distinct city) as distinct_city_Count from amazon;

-- ans = 3 --

-- Q2- For each branch, what is the corresponding city? --

select branch, city
from amazon
group by city, branch;

-- ans  A = Yangon --
--      C = Naypyitaw --
--      B = Mandalay --

-- Q3- What is the count of distinct product lines in the dataset? --

select count(distinct  Product_line) as distinct_product_lines_count
from amazon;

-- Q4- Which payment method occurs most frequently?

select payment ,
count(*) as occurrence
from amazon
group by payment
order by occurrence desc
limit 1;

-- ans- EWallet 345 times --

-- Q5- Which product line has the highest sales?

select product_line, sum(unit_price * quantity) as total_sales
from amazon
group by Product_line
order by total_sales desc
limit 1;

-- ans- Food and beverages with total_sales of 53471.28000000006 --

-- Q6- How much revenue is generated each month?

select date_format(date , '%y-%m') as month,
sum(unit_price * quantity) as total_revenue
from amazon
group by date_format(date,'%y-%m')
order by month asc; 

-- ans- for jan - 110754.16, for feb - 92589.88, for mar - 104243.339999999997 --

-- Q7- In which month did the cost of goods sold reach its peak?

select date_format(date,'%y-%m') as month,
sum(cogs * quantity) as total_cogs
from amazon
group by date_format(date,'%y-%m')
order by total_cogs desc
limit 1;

-- ans- cogs reached its peak in the month of jan as 795133.68000000005 --

-- Q8- Which product line generated the highest revenue? --

select product_line,
sum(unit_price * quantity) as total_revenue
from amazon
group by Product_line
order by total_revenue desc
limit 1;

-- ans- food and beverages as 53471.2800000006 --

-- Q9- In which city was the highest revenue recorded? --

select city, sum(unit_price * quantity) as total_revenue
from amazon
group by city
order by total_revenue desc
limit 1;

-- ans- 'Napyitaw' is the city that recorded highest revenue as 105303.53 --

-- Q10- Which product line incurred the highest Value Added Tax?

select product_line, sum(VAT) as total_VAT
from amazon
group by Product_line
order by total_VAT desc
limit 1;

-- ans- 'Food and beverages' incurred the highest VAT as 2673.563999999994

-- Q11- For each product line, add a column indicating "Good" if its sales are above average, otherwise "Bad."

-- Adding column sales_category to the table amazon --
alter table amazon
add column sales_category varchar(10);

with product_line_sales as(select product_line, sum(unit_price * quantity) as total_sales
from amazon
group by product_line),
average_sales as(select avg(total_sales) as avg_sales from product_line_sales)
update amazon
set sales_category = case
when product_line in (select product_line from product_line_sales, average_sales
where product_line_sales.total_sales > average_sales.avg_sales)
then 'good'
else 'bad'
end;

-- Q12- Identify the branch that exceeded the average number of products sold.

select branch, sum(quantity) as total_quantity
from amazon
group by branch
having sum(Quantity) > ( select avg(total_quantity) 
from (select sum(quantity) as total_quantity
from amazon
group by branch) as subquery);

-- ans- branch 'A' exceeded the avg number of quantity sold as '1859' --

-- Q13- Which product line is most frequently associated with each gender?

select gender, product_line, count(*) as frequency
from amazon
group by gender,product_line
order by gender, frequency desc;

-- ans- for frequency update check the result --

-- Q14- Calculate the average rating for each product line.

select product_line, avg(rating) as average_rating
from amazon
group by Product_line;

-- ans- check result for average ratings associated with each product line. --

-- Q15- Count the sales occurrences for each time of day on every weekday. --

select dayofweek(date) as day_of_week,
hour(time) as hour_of_day,
count(*) as sales_occurrences
from amazon
where dayofweek(date) in (1, 7)
group by day_of_week, hour_of_day
order by day_of_week, hour_of_day;

-- ans- for sales occurances for each weekend check result. --

-- Q16- Identify the customer type contributing the highest revenue.

select customer_type, sum(unit_price * quantity) as total_revenue
from amazon
group by Customer_type
order by total_revenue desc
limit 1;

-- ans- 'member' customer type is contributing the highest revenue as 156403.27999999985 --

-- Q17- Determine the city with the highest VAT percentage.

select city, max(VAT) as highest_VAT_percentage
from amazon
group by city
order by highest_VAT_percentage desc
limit 1;

-- ans- 'Naypyitaw' is the city with the highest vat percentage as 49.65%. --

-- Q18- Identify the customer type with the highest VAT payments.

select customer_type, sum(unit_price * quantity * VAT / 100) as total_VAT_paid
from amazon
group by Customer_type
order by total_VAT_paid desc
limit 1;

-- ans- 'Member' is the customer type with the highest VAT payments as 38358.945572200064. --

-- Q19- What is the count of distinct customer types in the dataset? --

select count(distinct customer_type) as distinct_customer_types
from amazon;

select distinct customer_type from amazon;

-- ans- there are '2' distinct customer types in the dataset that are 'Member' and 'Normal'. --

-- Q20- What is the count of distinct payment methods in the dataset?

select count(distinct payment) as distinct_payment_methods
from amazon;

select distinct payment from amazon;

-- ans- there are '3' distinct payment methods in the dataset that are 'Ewallet', 'Cash' and 'Credit card'. --

-- Q21- Which customer type occurs most frequently? --

select customer_type, count(*) as frequency
from amazon
group by Customer_type
order by frequency desc
limit 1;

-- ans- 'member' customer type occurred most frequently in the dataset as 501. --

-- Q22- Identify the customer type with the highest purchase frequency. --

select customer_type,
count(*) as purchase_frequency
from amazon
group by  Customer_type
order by purchase_frequency desc
limit 1;

-- ans- 'Member' is the customer type with the highest purchase frequency. --

-- Q23- Determine the predominant gender among customers.

select gender, count(*) as gender_count
from amazon
group by gender
order by gender_count desc
limit 1;

-- ans- 'Female' is the predominant gender among customer with '501' purchases. --

-- Q24- Examine the distribution of genders within each branch. --

select branch, gender, count(*) as gender_count
from amazon
group by branch, gender
order by branch, gender_count desc;

-- ans- for distribution of genders within each branch check result. --

-- Q25- Identify the time of day when customers provide the most ratings. --

select date(date) as order_date, hour(time) as hour_of_day, count(*) as ratings_count
from amazon
where rating is not null
group by order_date, hour_of_day
order by ratings_count desc
limit 1 ;

-- ans- in '20-03-2019' at '19th' hour that is '7 pm' is the hour customers provided the most ratings that is '5'.

-- Q26- Determine the time of day with the highest customer ratings for each branch.

with Rankedratings as (
select branch, date(Date) as order_date, hour(time) as hour_of_day,
count(*) as rating_count,
row_number() over(partition by branch, date(Date) order by count(*) desc) as Ranks
from amazon
where rating is not null
group by branch, order_date, hour_of_day )
select branch, order_date, hour_of_day, rating_count
from Rankedratings
where ranks = 1
order by branch, order_date, rating_count desc;

-- ans- for highest customer ratings check result --

-- Q27- Identify the day of the week with the highest average ratings.

select dayofweek(date) as day_of_week,
avg(rating) as average_rating
from amazon
where rating is not null
group by day_of_week
order by average_rating desc
limit 1;

-- ans- on 'mon' that is '2' is the day of the week with highest avg ratings that is '7'. --

-- Q28- Determine the day of the week with the highest average ratings for each branch. --

with AverageRatings as(
select branch, dayofweek(date) as day_of_week, avg(rating) as average_rating
from amazon
where rating is not null
group by branch, day_of_week )
select branch, day_of_week, average_rating
from AverageRatings
where (branch, average_rating) in (
select branch, max(average_rating) as highest_average
from AverageRatings
group by branch )
order by branch, average_rating desc;

-- ans- day of the week with the highest average ratings are the following for each branch :
-- ' A ' = '6' THAT IS FRIDAY --
-- ' B ' = '2' THAT IS MONDAY --
-- ' C ' = '6' THAT IS FRIDAY --
