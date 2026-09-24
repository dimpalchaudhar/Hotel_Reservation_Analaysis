-- Creating database for project
CREATE DATABASE hotel_reservation_analytics;

USE hotel_reservation_analytics;

# creating guests table
create table guests(
	guest_id varchar(10) primary key,
    guest_name varchar(100) not null,
    city varchar(50) not null,
    guest_type varchar(20) not null,
    preferred_room_type varchar(30),
    loyalty_tier varchar(20),
    account_since varchar(20),
    
    check (guest_type IN ("Individual", "Corporate"))
);

# creating hotels table
create table hotels(
	hotel_id varchar(10) primary key,
    hotel_name varchar(100) not null,
    city varchar(50) not null,
    star_rating int not null,
    total_rooms int not null,
    opened_date varchar(50),
    
    check (star_rating between 1 and 5),
    check (total_rooms > 0)
    
);

# creating staff table
create table staff(
	staff_id varchar(10) primary key,
    staff_name varchar(100) not null,
    hire_date varchar(20),
    rating decimal (3,2),
    department varchar(50) not null,
    is_active varchar(3) not null
default "Yes",

	check (rating between 0 and 5),
    check (is_active In ("Yes", "No"))
);
	
# Creating room table
create table rooms (
	room_id varchar(10) primary key,
    hotel_id varchar(10) not null,
    room_type varchar(30) not null,
    floor_number int not null,
    max_occupancy int not null,
    price_per_night decimal (10, 2)  not null,
    is_active varchar(3) not null default "Yes",
    
    foreign key(hotel_id)
		references hotels(hotel_id),
        
	check (max_occupancy > 0),
    check (price_per_night >= 0),
    check (is_active IN ("Yes", "No"))
);

# Creating booking table
create table bookings (
	booking_id varchar(10) primary key,
    guest_id varchar(10) not null, 
    hotel_id varchar(10) not null,
    booking_date varchar(20),
    room_type_requested varchar(30) not null,
    booking_channel varchar(30) not null,
    nights_booked int not null,
    total_amount decimal (12,2) not null,
    
    foreign key (guest_id)
		references guests(guest_id),
        
	foreign key (hotel_id)
		references hotels(hotel_id),
        
	check (nights_booked > 0),
    check (total_amount >= 0)
);

# Creating stays table
create table stays(
	stay_id varchar(10) primary key, 
    booking_id varchar(10) not null,
    room_id varchar(10) not null,
    staff_id varchar(10) not null,
    check_in_date varchar(20),
    check_out_date varchar(20),
    status varchar(20) not null,
    nights_stayed int not null,
    service_requests int not null,
    stay_duration_hrs int not null,
    
    foreign key (booking_id)
		references bookings(booking_id),
        
	foreign key (room_id)
		references rooms(room_id),
        
	foreign key (staff_id)
		references staff(staff_id)
);


SELECT COUNT(*) FROM guests;

SELECT COUNT(*) FROM hotels;

SELECT COUNT(*) FROM rooms;

SELECT COUNT(*) FROM bookings;

SELECT COUNT(*) FROM stays;

SELECT COUNT(*) FROM staff;



SELECT * FROM guests LIMIT 10;

SELECT * FROM hotels LIMIT 10;

SELECT * FROM rooms LIMIT 10;

SELECT * FROM bookings LIMIT 10;

SELECT * FROM stays LIMIT 10;

SELECT * FROM staff LIMIT 10;


SELECT
    COUNT(*) AS total_guests,
    SUM(loyalty_tier IS NULL) AS missing_loyalty_tier
FROM guests;


##------------------------------------------------------------- Sprint 3: Basic Analysis / Data Exploration------------------------------------------------------------------
## Write SQL queries to answer the following basic questions. The purpose of this sprint is to become familiar with the database before moving into objective-based analysis.

-- 1. What is the total number of guests?

SELECT COUNT(*) AS total_guests
FROM guests;

-- 2. What is the total number of bookings?
select count(*) AS total_bookings
from bookings;

-- 3. What is the total number of stays?
select count(*) AS total_stays
from stays;

-- 4. What are the different room types available?
select distinct room_type
from rooms;

-- 5. How many staff members are currently active?
select count(*) AS active_staff
from staff
where is_active = "Yes";

-- 6. What are the different booking channels?
select distinct booking_channel
from bookings;

-- 7. What is the total booking amount across all bookings?
select 
	sum(total_amount) AS
total_booking_amount
from bookings;

-- 8. What is the average nights booked per booking?
select 
	ROUND(AVG(nights_booked),2) AS 
avg_nights_booked
from bookings;

# ----------------------------------------------------------------Sprint 4: Objective-Based Analysis--------------------------------------------------------------------------
# 4.1 Understand Booking Demand
# Business Objective: The Operations team wants to understand where and how bookings are being generated.
-- 1. Which hotels receive the most bookings?
select 
	h.hotel_id,
    h.hotel_name,
    count(b.booking_id) AS 
total_bookings
from hotels h
join bookings b
	on h.hotel_id = b.hotel_id
group by h.hotel_id, h.hotel_name
order by total_bookings desc;

-- Obseravtion: The highest booking hotel is StayPoint Kolkata Residency over 129 bookings.


-- 2. Which booking channels generate the most bookings?
select 
	booking_channel,
    count(*) AS total_bookings
from bookings
group by booking_channel
order by total_bookings desc;

-- Obseravtion: Website is the largest booking channel, followed by Mobile App.

-- 3. Which channel generates the highest booking revenue?
select
	booking_channel,
    count(*) AS bookings,
    sum(total_amount) AS
total_revenue
from bookings
group by booking_channel
order by total_revenue desc;

-- Obseravtion: Website and Mobile App contribute almost equal revenue, with Website slightly higher.

-- 4. Which room type is requested most?
select 
	room_type_requested,
    count(*) As total_bookings,
    sum(total_amount) AS revenue,
    round(AVG(nights_booked), 2) AS 
avg_nights
from bookings
group by room_type_requested
order by total_bookings desc;

-- Obseravtion: Standard rooms are the most requested.

-- 5. How does booking volume change over time?
select 
	YEAR(booking_date) AS
booking_year,
	MONTH(booking_date) AS
booking_month,
	count(*) AS total_bookings,
    sum(total_amount) AS revenue 
from bookings
group by 
	YEAR(booking_date),
    MONTH(booking_date)
order by booking_year,
booking_month;

-- This identify: peak months, low_demand months, revenue trends

# 4.2 Understand Guest Booking Behaviour
# Business Objective: The Guest Experience team wants to understand how guests are using the reservation service.

-- 1. Which guests made multiple bookings?
select
	g.guest_id,
    g.guest_name,
    count(b.booking_id) AS 
booking_count
from guests g
join bookings b
	on g.guest_id = b.guest_id
group by 
	g.guest_id,
    g.guest_name
having count(b.booking_id) > 1
order by booking_count desc;

-- Observation: There are 322 repeat guests, the most active guest made 64 bookings.

-- 2. Top 10 guests by total booking amount
select 
	g.guest_id,
    g.guest_name,
    count(b.booking_id) AS bookings,
    sum(b.total_amount) AS
total_spending
from guests g
join bookings b
	 on g.guest_id = b.guest_id
group by g.guest_id, g.guest_name
order by total_spending desc
limit 10;

-- This identifies high-value guests.

-- 3. Individual vs Corporate guests
select
	g.guest_type,
    count(distinct g.guest_id) AS
total_guests,
	count(b.booking_id) AS
total_bookings,
	sum(b.total_amount) AS
total_revenue,
	round(avg(b.total_amount), 2) AS
avg_booking_amount,
	round(avg(b.nights_booked), 2) AS
avg_nights
from guests g
join bookings b
	on g.guest_id = b.guest_id
group by g.guest_type;

-- Observation: Individual guests generate more total bookings and revenue because there are considerably more individual guests.

-- 4. Which guests spend the most?
select 
	g.guest_id,
    g.guest_name,
    sum(b.total_amount) AS
total_spending
from guests g
join bookings b
	on g.guest_id = b.guest_id
group by g.guest_id, g.guest_name
order by total_spending desc
limit 10;

-- 5. Which cities have the most active guests?
select 
	g.city,
    count(distinct g.guest_id) AS
guests,
	count(b.booking_id) AS bookings,
    sum(b.total_amount) AS revenue
from guests g
left join bookings b
	on g.guest_id = b.guest_id
group by g.city
order by bookings desc;


# ---------------------------------------------------------------- 4.3 Evaluate Stay Performance ----------------------------------------------------------------------------
# Business Objective: The Operations team wants to understand how well stays are being completed.

-- 1. What are the different stay outcomes?
select 
	status,
    count(*) AS total_stays,
    round(
		count(*) * 100.0 /
        (select count(*) from stays), 2) AS 
	percentage
from stays
group by status
order by total_stays desc;

-- Observation : Approximately two-thirds of stays are successfully checked out, while cancellations and np-shows together represent a significant portion.

-- 2. Average stay duaration by status
select 
	status,
	count(*) AS stays,
	round(avg(nights_stayed), 2) AS
avg_nights,
	round(avg(stay_duration_hrs), 2) AS 
avg_hours
from stays
group by status;

-- Observation : 

-- 3. Which hotels have the most stays?
select
	h.hotel_name,
    count(s.stay_id) AS total_stays
from hotels h
join bookings b
	on h.hotel_id = b.hotel_id
join stays s
	on b.booking_id = s.booking_id
group by h.hotel_id, h.hotel_name
order by total_stays desc;


-- 4. Which hotels have the highest cancellation / no-show rate?
select 
	h.hotel_name,
    count(s.stay_id) AS total_stays,
    sum(
		case
			when s.status IN 
            ("Cancelled", "No-show")
            then 1
            else 0
		end
	) AS problem_stays,
    round(
		sum(
			case
				when s.status IN 
                ("Cancelled", "No-show")
                then 1
                else 0
			end
            ) * 100.0 /
count(s.stay_id), 2 ) AS 
	problem_rate
from hotels h
join bookings b
	on h.hotel_id = b.hotel_id
join stays s 
	on b.booking_id = s.booking_id
group by h.hotel_id, h.hotel_name
order by problem_rate desc;

-- Observation : Among the highest problem-rate hotels are:
-- StayPoint Kochi Palace
-- StayPoint Indore Plaza
-- StayPoint Ahmedabad Plaza
-- StayPoint Delhi Retreat
-- StayPoint Coimbatore Residency
-- These should receive operational attention.

-- 5. Compare stay outcomes by booking channel?
SELECT
    b.booking_channel,
    s.status,
    COUNT(*) AS total_stays
FROM bookings b
JOIN stays s
    ON b.booking_id = s.booking_id
GROUP BY
    b.booking_channel,
    s.status
ORDER BY
    b.booking_channel,
    total_stays DESC;
    
-- 6. calculate probelm rate by booking channel?
SELECT
    b.booking_channel,
    s.status,
    COUNT(*) AS total_stays
FROM bookings b
JOIN stays s
    ON b.booking_id = s.booking_id
GROUP BY
    b.booking_channel,
    s.status
ORDER BY
    b.booking_channel,
    total_stays DESC;
    
-- Observation: Mobile App has the highest cancellation/no-show problem rate in this dataset.

# 4.4 Understand Staff and Room Performance
# Business Objective: The Operations team wants to understand how its hotel resources are being utilized and how they are performing.

-- 1. Which staff members handled the most stays?
SELECT
    st.staff_id,
    st.staff_name,
    COUNT(s.stay_id) AS stays_handled,
    st.rating
FROM staff st
JOIN stays s
    ON st.staff_id = s.staff_id
GROUP BY
    st.staff_id,
    st.staff_name,
    st.rating
ORDER BY stays_handled DESC;


-- 2. Compare staff performance by outcome
SELECT
    st.staff_name,
    s.status,
    COUNT(*) AS total_stays
FROM staff st
JOIN stays s
    ON st.staff_id = s.staff_id
GROUP BY
    st.staff_id,
    st.staff_name,
    s.status
ORDER BY
    st.staff_name,
    total_stays DESC;
    
-- 3. Average stay duration handled by staff
SELECT
    st.staff_id,
    st.staff_name,
    COUNT(s.stay_id) AS stays_handled,
    ROUND(AVG(s.nights_stayed), 2) AS avg_nights,
    ROUND(AVG(s.stay_duration_hrs), 2) AS avg_duration_hours,
    st.rating
FROM staff st
JOIN stays s
    ON st.staff_id = s.staff_id
GROUP BY
    st.staff_id,
    st.staff_name,
    st.rating
ORDER BY avg_duration_hours DESC;

-- 4. Which room types are used most?
SELECT
    r.room_type,
    COUNT(s.stay_id) AS total_stays,
    ROUND(AVG(s.nights_stayed), 2) AS avg_nights,
    ROUND(AVG(s.service_requests), 2) AS avg_service_requests
FROM rooms r
JOIN stays s
    ON r.room_id = s.room_id
GROUP BY r.room_type
ORDER BY total_stays DESC;

-- 5. Does room capacity affect service requests?
SELECT
    r.max_occupancy,
    COUNT(s.stay_id) AS total_stays,
    ROUND(AVG(s.service_requests), 2) AS avg_service_requests
FROM rooms r
JOIN stays s
    ON r.room_id = s.room_id
GROUP BY r.max_occupancy
ORDER BY r.max_occupancy;

-- 6. Which rooms are used most?
SELECT
    r.room_id,
    r.room_type,
    COUNT(s.stay_id) AS total_stays,
    ROUND(AVG(s.nights_stayed), 2) AS avg_nights
FROM rooms r
JOIN stays s
    ON r.room_id = s.room_id
GROUP BY
    r.room_id,
    r.room_type
ORDER BY total_stays DESC;


# 4.5 Identify Booking and Stay Problems
# Business Objective: The Operations team wants to understand why some bookings require additional effort or fail to result in a completed stay.

-- 1. How many cancellations?
SELECT
    COUNT(*) AS cancelled_stays
FROM stays
WHERE status = 'Cancelled';

-- 2. How many no-shows?
SELECT
    COUNT(*) AS no_show_stays
FROM stays
WHERE status = 'No-show';

-- 3. Which bookings resulted in cancellations or no-shows?
SELECT
    b.booking_id,
    b.guest_id,
    b.hotel_id,
    b.booking_channel,
    b.nights_booked,
    b.total_amount,
    s.status
FROM bookings b
JOIN stays s
    ON b.booking_id = s.booking_id
WHERE s.status IN ('Cancelled', 'No-show')
ORDER BY b.booking_date;

-- 4. Which hotels have the most booking problems?
SELECT
    h.hotel_name,

    SUM(
        CASE
            WHEN s.status = 'Cancelled'
            THEN 1
            ELSE 0
        END
    ) AS cancellations,

    SUM(
        CASE
            WHEN s.status = 'No-show'
            THEN 1
            ELSE 0
        END
    ) AS no_shows,

    COUNT(*) AS total_stays

FROM hotels h

JOIN bookings b
    ON h.hotel_id = b.hotel_id

JOIN stays s
    ON b.booking_id = s.booking_id

GROUP BY h.hotel_id, h.hotel_name

ORDER BY
    (cancellations + no_shows) DESC;
    
-- 5. Which stays have unusually high service requests?
SELECT
    s.stay_id,
    s.booking_id,
    s.room_id,
    s.service_requests,
    s.status
FROM stays s
WHERE s.service_requests >= 4
ORDER BY s.service_requests DESC;

-- 6. Average service requests by stay status?
SELECT
    status,
    COUNT(*) AS stays,
    ROUND(AVG(service_requests), 2) AS avg_service_requests
FROM stays
GROUP BY status;


# ------------------------------------------------ More Question for better understanding --------------------------------------------------------------

-- 1. Top 10 hotels by revenue
select 
	h.hotel_name,
    count(b.booking_id) AS bookings,
    sum(b.total_amount) AS revenue
from hotels h
join bookings b
	on h.hotel_id = b.hotel_id
group by h.hotel_id, h.hotel_name
order by revenue desc
limit 10;
    

-- 2. Average booking value by channel
select 
	booking_channel,
    round(AVG(total_amount), 2) AS avg_booking_value
from bookings
group by booking_channel
order by avg_booking_value desc;


-- 3. Revenue per booked night
select 
	booking_channel,
    round(
		sum(total_amount) / sum(nights_booked),
        2
	) AS revenue_per_night
from bookings
group by booking_channel
order by revenue_per_night desc;


-- 4. Repeat guests
select 
	guest_id,
    count(*) AS booking_count
from bookings
group by guest_id
having count(*) > 1
order by booking_count desc;

-- 5. Guests with more than 10 bookings
select
	g.guest_name,
    count(b.booking_id) AS bookings
from guests g
join bookings b
	on g.guest_id = b.guest_id
group by g.guest_id, g.guest_name
having count(b.booking_id) > 10
order by bookings desc;


-- 6. Hotel revenue per room
select
	h.hotel_name,
    h.total_rooms,
    sum(b.total_amount) AS revenue,
    round(
		sum(b.total_amount) / h.total_rooms,
        2
	) AS revenue_per_room
from hotels h
join bookings b
	on h.hotel_id = b.hotel_id
group by 
	h.hotel_id,
    h.hotel_name,
    h.total_rooms
order by revenue_per_room desc;

-- 7. Compare requested room vs actual room
select
	b.room_type_requested,
    r.room_type AS actual_room_type,
    count(*) AS total_stays
from bookings b
join stays s
	on b.booking_id = s.booking_id
join rooms r
	on s.room_id = r.room_id
group by
	b.room_type_requested,
    r.room_type
order by total_stays desc;

-- 8. Booking-to-stay conversion
select
	count(distinct booking_id) AS bookings_with_stay
from stays;

select
	round(
		count(distinct s.booking_id) * 100.0 /
        count(distinct b.booking_id),
        2
	) AS booking_coverage_percentage
from bookings b
left join stays s
	on b.booking_id = s.booking_id;
    
    
# -- Q The dataset contains 2800 bookings and 3200 stays
# but only 2600 unique bookings appear in stays. 
select 
	booking_id,
    count(*) AS stay_count
from stays
group by booking_id
having count(*) > 1
order by stay_count desc;

# This means some bookings have multiple stay records.

