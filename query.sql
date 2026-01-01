create database cust_order;
use cust_order;
select * from customers;
select * from order_items;
select * from orders; 



--  What is the total revenue, total number of orders, and total items sold?
select sum(oi.quantity*oi.price_per_unit) as "Total_revenue", 
	   count(distinct o.order_id) as "Total_No_Orders" , 
       sum(oi.quantity) as  "Total_items"  
from orders o inner join order_items oi 
on o.order_id=oi.order_id;


--  How many orders are completed / cancelled / returned?
select order_status, count(order_status) as "Total_orders" 
from orders 
where order_status in ("Cancelled","Delivered","Returned") 
group by order_status;

--  Find top five customer by total spending money
select  c.customer_name,sum(oi.price_per_unit * oi.quantity) as "Total_spent" 
from customers c 
inner join orders o 
on  c.customer_id=o.customer_id 
inner join order_items oi 
on o.order_id=oi.order_id 
group by c.customer_id,c.customer_name 
order by Total_spent desc 
limit 5;


--  Find top ten customer by total spending money with rank wse
select * from 
(select c.customer_name,sum(oi.price_per_unit * oi.quantity) as "Total_spent",
rank() over(order by sum(oi.price_per_unit * oi.quantity) desc) as "Rank" 
from  customers c 
inner join orders o 
on  c.customer_id=o.customer_id 
inner join order_items oi 
on o.order_id=oi.order_id 
group by c.customer_id,c.customer_name) X
where X.Rank<=10 ;

-- Identify top 5 customers with highest cancelled orders
select c.customer_name,count(c.customer_id) as "cancelled order"
from customers c 
inner join orders o 
on c.customer_id=o.customer_id 
where o.order_status in('Cancelled') 
group by c.customer_name 
order by count(c.customer_id) desc
limit 5 ;

--  Customers whose total spending is above average customer spending
with cp as(
select c.customer_name,sum(oi.quantity*oi.price_per_unit) as Total_spending
from customers c 
inner join orders o 
on c.customer_id=o.customer_id 
inner join order_items oi 
on o.order_id=oi.order_id
group by c.customer_name),

ca as(select avg(Total_spending) as Avg_spending 
from cp)

select cp.* 
from cp 
inner join ca 
where cp.Total_spending>ca.Avg_spending;


--  Customers whose cancelled-order-rate > 50% and total orders > 5
with total as (
select c.customer_id,c.customer_name,COUNT(o.order_status) AS Total_order
from customers c
inner join orders o 
on c.customer_id = o.customer_id
group by c.customer_id, c.customer_name
),

ca as (
select c.customer_id,count(o.order_status) AS cancel_order
from orders o
inner join customers c on o.customer_id = c.customer_id
where o.order_status = 'cancelled'
group by c.customer_id
)

select t.customer_id,t.customer_name,t.Total_order,c.cancel_order
from total t
inner join ca c 
on t.customer_id = c.customer_id
where  t.Total_order > 5 and (c.cancel_order * 1.0 / t.Total_order) > 0.5;

--  Top 3 customers by revenue per city — returns only top 3 per city
with cust as(select  c.customer_name ,c.city,sum(oi.quantity*oi.price_per_unit) as Total_spending
from customers c 
inner join orders o 
on c.customer_id=o.customer_id 
inner join order_items oi 
on o.order_id=oi.order_id
where o.order_status="Delivered"
group by c.customer_name,c.city)

select cust.*
from cust 
order by Total_spending desc
limit 3;

--  Identify customer whose  no orders in last 6 months
with last_order as(
select c.customer_name,max(o.order_date) as last_order_date 
from customers c 
inner join orders o 
on c.customer_id=o.customer_id
group by c.customer_name)

select lo.customer_name,lo.last_order_date
from last_order lo
where lo.last_order_date <date_sub(curdate(),interval 6 month);

--  Revenue contribution percentage per customer
with cp as(select c.customer_name, sum(oi.quantity*oi.price_per_unit) as revenue
from customers c 
inner join orders o 
on c.customer_id=o.customer_id
inner join order_items oi 
on o.order_id=oi.order_id
group by c.customer_name)

select cp.customer_name,cp.revenue,revenue/sum(revenue) over()*100 as revenue_per_c
from cp ;

--  Second highest order per customer
with rnk as (
select c.customer_name, sum(oi.quantity*oi.price_per_unit) as revenue, dense_rank() 
over(order by  sum(oi.quantity*oi.price_per_unit) desc) as ranked
from customers c 
inner join orders o 
on c.customer_id=o.customer_id
inner join order_items oi 
on o.order_id=oi.order_id
group by c.customer_name)

select * from rnk 
where ranked=2;

--  Customers who never placed an order
select * from customers c
where not exists (select *
from orders o 
where c.customer_id=o.customer_id);

--  Orders with exactly one item
select order_id 
from order_items
group by order_id
having count(order_id)=1;

--  Customers who bought the most expensive product
select distinct o.customer_id,c.customer_name,oi.price_per_unit  
from customers c 
inner join orders o 
on  c.customer_id=o.customer_id 
inner join order_items oi 
on o.order_id=oi.order_id 
where oi.price_per_unit=(
select max(oi.price_per_unit) 
from order_items oi);

-- Find customers whose name starts with 'A'
select customer_name
from customers 
where customer_name like "A%";

--  Orders whose total value equals maximum order value
select c.customer_name,max(oi.quantity*oi.price_per_unit) as "max_revenue"
from customers c 
inner join orders o 
on c.customer_id=o.customer_id 
inner join order_items oi 
on o.order_id=oi.order_id
group by c.customer_name
having sum(oi.quantity*oi.price_per_unit)=(
	select max(total_revenue) 
    from (
	select sum(oi.quantity*oi.price_per_unit) as total_revenue 
	from order_items oi
	inner join orders o on o.order_id=oi.order_id
	group by o.customer_id)  t ); 
    
-- Customers whose name has exactly 10 characters
select customer_name
from customers 
where customer_name like '__________';

--  Customers who placed orders but never completed
select c.customer_id,c.customer_name 
from customers c 
inner join orders o
on o.customer_id=c.customer_id
group by c.customer_id,c.customer_name
having sum(case when o.order_status = 'completed' then 1 else 0 end) = 0;

-- Customers whose name does NOT start with a vowel
select customer_name
from customers 
where customer_name not like ('a%' and 'e%' and 'i%' and 'o%' and 'u%');

--  Orders with maximum quantity sold
select order_id 
from order_items
group by order_id
having sum(quantity)=(
	select max(max_quantity)
	from (
    select sum(quantity) as max_quantity
    from order_items
    group by order_id) t);
    
--  Customers whose every order has more than 2 items
select c.customer_id,c.customer_name
from customers c 
inner join orders o 
on c.customer_id=o.customer_id 
inner join order_items oi 
on o.order_id=oi.order_id
group by c.customer_id,c.customer_name
having sum(oi.quantity)>2;


--  Customers who placed more than one order on the same day
select distinct
    o1.customer_id,
    o1.order_date
FROM orders o1
JOIN orders o2
  ON o1.customer_id = o2.customer_id
 AND o1.order_date = o2.order_date
 AND o1.order_id <> o2.order_id;
 
--   Orders placed after another order by the same customer
select o2.order_id,o2.customer_id,o2.order_date
from orders o1
join orders o2
on o1.customer_id = o2.customer_id
and o2.order_date > o1.order_date;

