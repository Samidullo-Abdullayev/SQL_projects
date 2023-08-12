--                  ## QUESTION SET 2 ##

-- Q1: Write a query to return the email, first nama, last name, and Genre of all Rock 
-- 	   music listeners. Return your list ordered alphabetically by email starting with A

select distinct customer.email, customer.first_name, customer.last_name, genre.name
from customer 
inner join invoice on customer.customer_id = invoice.customer_id
inner join invoice_line on invoice.invoice_id = invoice_line.invoice_id
inner join track on invoice_line.track_id = track.track_id
inner join genre on track.genre_id = genre.genre_id
where genre.name = 'Rock'
order by email 

-- Q2: Let's invite the artists who have written the most rock music in our dataset.
--     Write a query that return the Artist name and total track count of the top 10 rock bands

select artist.artist_id, artist.name, count(artist.artist_id) as num_songs from artist
inner join album on artist.artist_id = album.artist_id
inner join track on album.album_id = track.album_id
where track.genre_id = (select distinct genre.genre_id from track
					   join genre on genre.genre_id = track.genre_id and genre.name = 'Rock')
group by artist.artist_id
order by num_songs desc
limit 10


-- Q3: Return all the track names that have a song length longer than the average song length.
--     Return the Name and Milliseconds for each track. Order by the song length with the longest
--     songs listed first.

select name, milliseconds from track
where milliseconds > (
		select avg(milliseconds) as avg_len from track)
order by milliseconds desc