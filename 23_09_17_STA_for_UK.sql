-- UK FROM UK analysts
select r.city, r.week, invites, inviting_drivers, downloads, ftrs, riding_drivers, total_FTRs from (
--Actives
select (case when city_name in ('London','Birmingham','Greater Manchester','Glasgow','Edinburgh','Coventry','Reading','Newcastle upon Tyne','Liverpool','Bournemouth','Leeds') then city_name else 'Other Cities' end) as city,
cast(DATEADD(DAY, 1-DATEPART(WEEKDAY, dateadd(day,-1,date_key)), date_key) as date) as week,
count(distinct(driver_gk)) as riding_drivers, sum(Is_FTP_Key) as total_FTRs
from Dwh_Fact_Orders_v o
join Dwh_Dim_Locations_V l on o.Origin_Location_Key = l.Location_Key
join Dwh_Dim_Class_Types_V c on o.Class_Type_Key = c.Class_Type_Key
where o.country_key = 3 and Order_Status_Key = 7
and o.date_key >= '2017-07-01' and Category_Desc = 'transport'
and Class_Type_Desc not in ('ot standard v1','ot standard v2')
group by (case when city_name in ('London','Birmingham','Greater Manchester','Glasgow','Edinburgh','Coventry','Reading','Newcastle upon Tyne','Liverpool','Bournemouth','Leeds') then city_name else 'Other Cities' end),
cast(DATEADD(DAY, 1-DATEPART(WEEKDAY, dateadd(day,-1,date_key)), date_key) as date))  r
--Invites
left join (
select   (case when city_name in ('London','Birmingham','Greater Manchester','Glasgow','Edinburgh','Coventry','Reading','Newcastle upon Tyne','Liverpool','Bournemouth','Leeds') then city_name else 'Other Cities' end) as city,
cast(DATEADD(DAY, 1-DATEPART(WEEKDAY, dateadd(day,-1,Invite_Date_Key)), Invite_Date_Key) as date) as week,
count(*) as invites, count(distinct(i.driver_gk)) as inviting_drivers
from Mrr_Invites i
LEFT JOIN ( SELECT driver_gk, city_name, COUNT (*) AS c, row_number() over ( PARTITION BY Driver_GK ORDER BY COUNT (*) DESC ) AS ROW
FROM dwh_fact_rides_v r, Dwh_Dim_Locations_v l WHERE r.origin_location_key = l.Location_Key AND r.country_symbol = 'GB' GROUP BY driver_gk, city_name) l
ON i.Driver_GK = l.driver_gk AND ROW = 1
where i.country_key = 3 and i.Invite_Date_Key >= '2017-07-01'
group by (case when city_name in ('London','Birmingham','Greater Manchester','Glasgow','Edinburgh','Coventry','Reading','Newcastle upon Tyne','Liverpool','Bournemouth','Leeds') then city_name else 'Other Cities' end),
DATEADD(DAY, 1-DATEPART(WEEKDAY, dateadd(day,-1,Invite_Date_Key)), Invite_Date_Key)) i on i.city = r.city and i.week = r.week
--Downloads
left join (
select (case when city_name in ('London','Birmingham','Greater Manchester','Glasgow','Edinburgh','Coventry','Reading','Newcastle upon Tyne','Liverpool','Bournemouth','Leeds') then city_name else 'Other Cities' end) as city,
cast(DATEADD(DAY, 1-DATEPART(WEEKDAY, dateadd(day,-1,activated_at)), activated_at) as date) as week,
count(*) as downloads
from Mrr_Invites i
LEFT JOIN ( SELECT driver_gk, city_name, COUNT (*) AS c, row_number() over ( PARTITION BY Driver_GK ORDER BY COUNT (*) DESC ) AS ROW
FROM dwh_fact_rides_v r, Dwh_Dim_Locations_v l WHERE r.origin_location_key = l.Location_Key AND r.country_symbol = 'GB' GROUP BY driver_gk, city_name) l
ON i.Driver_GK = l.driver_gk AND ROW = 1
where i.country_key = 3 and i.activated_at >= '2017-07-01'
group by (case when city_name in ('London','Birmingham','Greater Manchester','Glasgow','Edinburgh','Coventry','Reading','Newcastle upon Tyne','Liverpool','Bournemouth','Leeds') then city_name else 'Other Cities' end),
cast(DATEADD(DAY, 1-DATEPART(WEEKDAY, dateadd(day,-1,activated_at)), activated_at) as date)) d on r.city = d.city and r.week = d.week
--FTRS
left join (
select (case when city_name in ('London','Birmingham','Greater Manchester','Glasgow','Edinburgh','Coventry','Reading','Newcastle upon Tyne','Liverpool','Bournemouth','Leeds') then city_name else 'Other Cities' end) as city,
cast(DATEADD(DAY, 1-DATEPART(WEEKDAY, dateadd(day,-1,date_key)), date_key) as date) as week,
count(*) as ftrs
from Mrr_Invites i
join Dwh_Fact_Orders_V o on i.Order_GK = o.Order_GK
join Dwh_Dim_Locations_V l on l.Location_Key = o.Origin_Location_Key
where i.country_key = 3 and o.country_key = 3 and o.Is_FTP_Key = 1 and Order_Status_Key = 7  and o.date_key >= '2017-07-01'
group by (case when city_name in ('London','Birmingham','Greater Manchester','Glasgow','Edinburgh','Coventry','Reading','Newcastle upon Tyne','Liverpool','Bournemouth','Leeds') then city_name else 'Other Cities' end),
cast(DATEADD(DAY, 1-DATEPART(WEEKDAY, dateadd(day,-1,date_key)), date_key) as date)) f on r.city = f.city and r.week = f.week
