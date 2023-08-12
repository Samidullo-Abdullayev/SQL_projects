--                  ## QUESTION SET 3 ##

-- Q1: Find how much amount spent by each customer on artists? Write a query to return
--     customer name, artist name and total spent
-- NOTE: total spent for each artist : unit_price * quantity. Not 'total' column in invoice
--       table, because 'total' means a payment for all songs customer bought.

select distinct cr.customer_id, cr.first_name,
artist.name as artist_name, round(sum(inv_line.unit_price * inv_line.quantity)::decimal, 2) as total_spent
from customer cr
join invoice inv on cr.customer_id = inv.customer_id
join invoice_line inv_line on inv.invoice_id = inv_line.invoice_id
join track on track.track_id = inv_line.track_id
join album on track.album_id = album.album_id
join artist on album.artist_id = artist.artist_id
group by 1, 3
order by first_name, total_spent desc

-- Q2: We want to find out the most popular music Genre for each country. We determine
--     the most popular genre as the genre with the highest amount of purchases. Write 
--     a query that returns each country along with the top Genre. For countries where 
--     the maximum number of purchases is shared return all Genres.

with popular_song as (
	select count(inv_line.quantity) as purchases, billing_country as country,
	genre.name as genre_name, 
	row_number() over(partition by billing_country order by count(quantity) desc) as rowN
	from invoice inv
	join invoice_line inv_line on inv.invoice_id = inv_line.invoice_id
	join track on track.track_id = inv_line.track_id
	join genre on track.genre_id = genre.genre_id
	group by 2, 3
	order by 1 desc
), 
max_amount as ( 
	select purchases, country, genre_name, 
	max(purchases) over(partition by country order by purchases desc) as max_purchases
	from popular_song
)

--  1 - method
select purchases, country, genre_name from popular_song
where rowN = 1

-- 2- method
select * from max_amount
where purchases = max_purchases


-- Q3: Write a query that determines the cutomer that has spent the most on music for
--     each country. Write a query that returns the country along with the top customer
--     and how much they spent. For countries where the top amount spent is shared,
--     provide all customers who spent this amount.

with customer_spent as	(
	select distinct cr.customer_id, concat(trim(first_name), ' ', trim(last_name)) as full_name,
	country, round((sum(total) over(partition by cr.customer_id))::decimal, 2) as total_spent
	from invoice inv
	join customer cr on inv.customer_id = cr.customer_id
	order by 4 desc
),
max_spender as (
	select *,
	max(total_spent) over(partition by country order by total_spent desc) as max_spent
	from customer_spent
	order by 4 desc
)

select customer_id, full_name, country, max_spent from max_spender
where total_spent = max_spent

-- second method. let's try with row_number yourself