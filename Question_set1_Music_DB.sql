--                  ## QUESTION SET 1 - EASY LEVEL ##
-- Q1: Who is the senior most employee based on job title?

select * from employee
order by levels desc
limit 1

-- Q2: Which countries have the most Inovices?

select billing_country, count(billing_country) as num_invoices
from invoice
group by billing_country
order by num_invoices desc

-- Q3: What are top 3 values of total invoice by countries

select billing_country, ROUND(sum(total)::decimal, 2) as total_spending
from invoice
group by billing_country
order by total_spending desc
limit 3

-- Q4: Which city has the best customers we would like to throw a promotional
--     Musical Festival in the city we made the most money. Wrtie a query that 
-- 	   return one city that has the highest sum of invoice totals. 
-- 	   Return both the city name and sum of all invoice totals

select billing_city, round(sum(total)::decimal, 2) as sum_all_invoice from invoice
group by billing_city
order by sum_all_invoice desc
limit 3  -- let's show top 3 cities

-- Q5: Who is the best customer? The customer who has the spent most money will be
-- 	   declared the best customer. Write a queru that returns the person who has spent
--     the most money

select first_name, last_name, billing_city, billing_country, round(sum(total)::decimal, 2) as total_spent
from invoice i
inner join customer cr on i.customer_id = cr.customer_id
group by first_name, last_name, billing_city, billing_country
order by total_spent desc
limit 1

