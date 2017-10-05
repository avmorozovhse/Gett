select
i.country_symbol,
city_name as city,
 count(*) as FTRs,
sum(rides_30days) as sum_rides30days,
sum(case when i.order_gk > 0 then  driver_reward end) as driver_rewards,
sum(driver_fares) as driver_fares, sum(coupon_spend) as coupon_spend
from Mrr_Invites i
join Dwh_Fact_Orders_V o on i.order_gk = o.order_gk
join Dwh_Dim_Locations_v l on o.Origin_Location_Key = l.Location_Key
left join (select ordering_user_gk, count(*) as rides_30days,sum(driver_base_price) as driver_fares,  sum(Paid_With_Prepaid) as coupon_spend
      from Dwh_Fact_orders_V o, Dwh_Dim_Users_V u where o.Ordering_User_GK = User_GK  and Order_Status_Key = 7
      and o.Date_Key <= dateadd(day,30,u.FTP_Date_Key) and o.date_key >= '2017-06-01' and u.FTP_Date_Key >= '2017-06-01' group by Ordering_User_GK) r on o.Ordering_User_GK = r.Ordering_User_GK
where o.date_key between dateadd(day,-60, cast(getdate() as date)) and dateadd(day,-30, cast(getdate() as date))
and invitation_type = 1
group by i.country_symbol, city_name
