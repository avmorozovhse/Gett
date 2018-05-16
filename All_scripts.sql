-- 2GIS FTRs by month - размещение заказа
SELECT
  TRUNC(DATE_TRUNC('mon', u.registration_date_key)) as date
  ,l.city_name
  ,count(DISTINCT u.user_gk) as FTRs
FROM Dwh_Dim_Users_V u
  INNER JOIN Dwh_Fact_Orders_V fo ON fo.Riding_User_GK = u.User_GK
  LEFT JOIN (SELECT DISTINCT l.city_id, l.city_name
            FROM dwh_dim_locations_v l) l on u.primary_city_id = l.city_id
where u.Acquisition_Channel_Desc = 'GIS'
       and u.Registration_Date_Key between '2018-02-01' and '2018-02-28'
GROUP BY TRUNC(DATE_TRUNC('mon', u.registration_date_key)), l.city_name
ORDER BY TRUNC(DATE_TRUNC('mon', u.registration_date_key)), count(DISTINCT u.user_gk) DESC

-- 2GIS FTRs by region
SELECT
  l.city_name
  ,count(DISTINCT u.user_gk) as FTRs
FROM Dwh_Dim_Users_V u
  INNER JOIN Dwh_Fact_Orders_V fo ON fo.Riding_User_GK = u.User_GK
  LEFT JOIN (SELECT DISTINCT l.city_id, l.city_name
            FROM dwh_dim_locations_v l) l on u.primary_city_id = l.city_id
where u.Acquisition_Channel_Desc = 'GIS'
       and u.Registration_Date_Key >= '2017-03-01'
       and u.Registration_Date_Key <= '2017-11-30'
GROUP BY l.city_name
ORDER BY count(DISTINCT u.user_gk) DESC


-- Wargaming
SELECT
  fo.date_key
  ,CASE WHEN 6374.612 * 2 * asin(sqrt(power(sin(radians(55.750042 - fo.dest_latitude) / 2), 2) +
                                     cos(radians(55.750042)) * cos(radians(fo.dest_latitude)) *
                                     power(sin(radians((37.544066 - fo.dest_longitude) / 2)), 2))) * 1000 < 300
       THEN 'To_WG'
       WHEN 6374.612 * 2 * asin(sqrt(power(sin(radians(55.750042 - fo.origin_latitude) / 2), 2) +
                                     cos(radians(55.750042)) * cos(radians(fo.origin_latitude)) *
                                     power(sin(radians((37.544066 - fo.origin_longitude) / 2)), 2))) * 1000 < 300
       THEN 'FROM_WG' END AS type
    ,sum(CASE WHEN om.component_key = 15718 THEN om.cost_inc_vat ELSE 0 END) as revenue
    ,sum(CASE WHEN om.component_key = 15718 THEN fo.driver_total_cost_inc_vat ELSE 0 END) as driver_check
    ,sum(CASE WHEN not (om.component_key = 15718) THEN om.cost_inc_vat ELSE 0 END) as revenue_from_services
    ,avg(CASE WHEN om.component_key = 15718 THEN fo.m_ride_duration ELSE 0 END) as dur
    ,avg(CASE WHEN om.component_key = 15718 THEN fo.ride_distance_key ELSE 0 END) as dist
    ,count(DISTINCT fo.order_gk) as rides
FROM dwh_fact_orders_v fo
  inner join dwh_fact_users_orders_monetization_v om ON om.order_gk = fo.order_gk
WHERE fo.order_status_key = 7
      AND fo.ride_type_key = 1
      AND fo.date_key >= '2016-12-01'
      AND fo.origin_location_key = 245
      and not(fo.dest_longitude is null)
      and not(fo.dest_latitude is null)
      and fo.date_key = '2017-12-23'
      and om.mode_name_key = 83
      and ( 6374.612 * 2 * asin(sqrt(power(sin(radians(55.750042 - fo.dest_latitude) / 2), 2) +
                                     cos(radians(55.750042)) * cos(radians(fo.dest_latitude)) *
                                     power(sin(radians((37.544066 - fo.dest_longitude) / 2)), 2))) * 1000 < 300
      OR
       6374.612 * 2 * asin(sqrt(power(sin(radians(55.750042 - fo.origin_latitude) / 2), 2) +
                                     cos(radians(55.750042)) * cos(radians(fo.origin_latitude)) *
                                     power(sin(radians((37.544066 - fo.origin_longitude) / 2)), 2))) * 1000 < 300)


group by 2,1
order by 2 DESC,3 DESC

select
  DISTINCT dc.coupon_container_name
from dwh_dim_coupons_v dc
where lower(dc.coupon_container_name) like lower('%RU_B2B%')



-- Non Ftrs
 with users as (SELECT
  dc.user_gk
  ,dc.coupon_container_name
  ,dc.coupon_gk
  ,dc.total_redeemed_amount
  ,dc.coupon_type
  ,dc.country_key
  ,dc.created_date_key
  ,CASE WHEN dc.num_of_usages >= dc.max_usages or dc.remaining_amount = 0 THEN dc.last_consumed_datetime
     WHEN dc.expiration_date < CURRENT_DATE THEN dc.expiration_date
     ELSE dc.expiration_date END as end_datetime
  ,CASE WHEN dc.num_of_usages >= dc.max_usages or dc.remaining_amount = 0 THEN dc.last_consumed_date_key
       WHEN dc.expiration_date < CURRENT_DATE THEN dc.expiration_date
       ELSE dc.expiration_date END as end_date
  ,dc.first_consumed_datetime as start_datetime
 FROM dwh_dim_coupons_v dc
   WHERE  dc.total_redeemed_amount > 0.0 and dc.coupon_container_name in ('RU_BVIP_NonFTR_SPBLoyalty_01082017',
'RU_BVIP_NonFTR_H8MscUpgade_03082017',
'RU_BVIP_NonFTR_MscChurnGettChurnBV4x500_21092017',
'RU_BVIP_NonFTR_H40UpgradetoVIPSPb_17112017',
'RU_BVIP_H9H20MscUpgradeOrdLoyalty5x300_15092017',
'RU_BVIP_H9H20MscUpgradeOrdLoyalty5x400_15092017',
'RU_BVIP_H9H20SPbUpgradeOrdLoyalty5x300_15092017',
'RU_BVIP_H9H20SPbUpgradeOrdLoyalty5x400_15092017') and dc.country_key = 2 and dc.is_ftr_key=0 and dc.created_date_key BETWEEN '2017-01-01' AND '2017-12-31' and dc.country_key = 2),

  coupon_usages as (
  SELECT
      cu.order_gk
      ,cu.amount_redeemed_from_coupon
      ,cu.coupon_gk
      ,fo.is_ftp_key
      ,CASE WHEN dc.max_usages = 0 THEN dc.coupon_initial_amount
            ELSE dc.coupon_initial_amount/dc.max_usages END as max_amount_per_usage
  FROM dwh_dim_coupons_v dc
    inner join dwh_fact_coupon_usages_v cu on cu.coupon_gk = dc.coupon_gk
    inner join dwh_fact_orders_v fo on fo.order_gk = cu.order_gk
  WHERE dc.total_redeemed_amount > 0.0 and dc.country_key = 2),

  rides as (SELECT
    CASE WHEN dateadd(m, +3, fr.ride_end_datetime) < u.start_datetime THEN 'before'
         WHEN DATEDIFF('day', u.end_datetime, fr.ride_end_datetime) <= 30 THEN 'after_30'
         WHEN DATEDIFF('day', u.end_datetime, fr.ride_end_datetime) BETWEEN 31 AND 60 THEN 'after_60'
         ELSE 'after_60>' END as period
    ,u.user_gk
    ,fo.order_gk
    ,u.coupon_container_name
    ,cu.amount_redeemed_from_coupon
    ,fo.origin_location_key
    ,cu.coupon_gk
    ,fo.date_key
    ,fo.hour_key
    ,u.coupon_type
    ,cu.is_ftp_key
    ,fo.customer_total_cost_inc_vat
    ,fo.paid_with_prepaid
    ,u.created_date_key
    ,cu.max_amount_per_usage - cu.amount_redeemed_from_coupon as remain_from_coupon
    ,CASE WHEN fo.paid_with_prepaid is null THEN 0
      ELSE fo.paid_with_prepaid/fo.customer_total_cost_inc_vat END as share_paid_with_prepaid
    ,fo.driver_total_commission_inc_vat* -1.0 / 1.18 +
                      CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
                          THEN
                            (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
                       ELSE
                          (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END  as gp
  from users u
    inner join dwh_fact_orders_v fo ON fo.riding_user_gk = u.user_gk
                                       and DATEDIFF('day', u.start_datetime, fo.date_key) BETWEEN -30 AND 60 + DATEDIFF('day', u.start_datetime, u.end_datetime)
    inner join dwh_fact_rides_v fr ON fr.ride_gk = fo.order_gk
    left join coupon_usages cu ON cu.order_gk = fo.order_gk and cu.coupon_gk = u.coupon_gk
    INNER JOIN dbo.dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key




  where fo.Country_Symbol = 'RU'
              AND not(fo.Ride_Type_Key = 2)
              AND fo.order_status_key = 7
              AND fo.customer_total_cost_inc_vat > 0
              AND dct.class_type_group_desc in ('VIP', 'Premium', 'VIP+')
              AND fo.date_key > '2017-01-01' and fo.date_key < CURRENT_DATE-1)

  select
    r.coupon_container_name
    ,CASE WHEN r.origin_location_key = 245 THEN 'Moscow'
        WHEN r.origin_location_key = 246 THEN 'SPB'
        ELSE 'Regions' END AS location
    ,trunc(date_trunc('mon', min(r.created_date_key))) as date_key
    ,sum(CASE WHEN r.period = 'before' THEN 1 ELSE 0 END) as before_rides_30
    ,sum(CASE WHEN r.period = 'after_30' THEN 1 ELSE 0 END) as after_ride_30
    ,sum(CASE WHEN r.period = 'after_30' AND r.share_paid_with_prepaid < 0.30 THEN 1 ELSE 0 END) as after_ride_30_without_prepaid
    ,sum(CASE WHEN r.period = 'after_60' THEN 1 ELSE 0 END) as after_ride_31_60
    ,ceiling(sum(r.remain_from_coupon)) as remain_from_coupon
    ,count(DISTINCT CASE WHEN not(r.amount_redeemed_from_coupon is null) THEN r.coupon_gk ELSE 0 END) as coupon_activation
    ,sum(r.amount_redeemed_from_coupon) as coupon_spent_promo
    ,sum(CASE WHEN not(r.amount_redeemed_from_coupon is null) THEN 1 ELSE 0 END) as coupon_rides_promo
    ,sum(r.amount_redeemed_from_coupon) as coupon_spent_promo
    ,sum(CASE WHEN r.period = 'before' THEN r.customer_total_cost_inc_vat ELSE 0 END) as before_revenue_30
    ,sum(CASE WHEN r.period = 'after_30' THEN r.customer_total_cost_inc_vat ELSE 0 END) as after_revenue_30
    ,sum(CASE WHEN r.period = 'before' THEN r.gp ELSE 0 END) as before_gp_30
    ,sum(CASE WHEN r.period = 'after_30' THEN r.gp ELSE 0 END) as after_gp_30
    ,sum(CASE WHEN r.is_ftp_key = 1 THEN 1 ELSE 0 END) as ftrs
  from rides as r
    where r.coupon_type in ('general', 'other', 'marketing', 'unknown')

  GROUP BY r.coupon_container_name, 2
  HAVING count(DISTINCT CASE WHEN not(r.amount_redeemed_from_coupon is null) THEN r.coupon_gk ELSE 0 END)  > 30



-- FTRs
with users as (SELECT
  dc.user_gk
  ,dc.coupon_container_name
  ,dc.coupon_gk
  ,dc.total_redeemed_amount
  ,dc.coupon_type
  ,dc.country_key
  ,dc.created_date_key
  ,CASE WHEN dc.num_of_usages >= dc.max_usages or dc.remaining_amount = 0 THEN dc.last_consumed_datetime
     WHEN dc.expiration_date < CURRENT_DATE THEN dc.expiration_date
     ELSE dc.expiration_date END as end_datetime
  ,CASE WHEN dc.num_of_usages >= dc.max_usages or dc.remaining_amount = 0 THEN dc.last_consumed_date_key
       WHEN dc.expiration_date < CURRENT_DATE THEN dc.expiration_date
       ELSE dc.expiration_date END as end_date
  ,dc.first_consumed_datetime as start_datetime
 FROM dwh_dim_coupons_v dc
   WHERE  dc.total_redeemed_amount > 0.0 and dc.created_date_key BETWEEN '2016-01-01' AND '2017-12-31' and dc.country_key = 2),

  coupon_usages as (
  SELECT
      cu.order_gk
      ,cu.amount_redeemed_from_coupon
      ,cu.coupon_gk
      ,fo.is_ftp_key
      ,CASE WHEN dc.max_usages = 0 THEN dc.coupon_initial_amount
            ELSE dc.coupon_initial_amount/dc.max_usages END as max_amount_per_usage
  FROM dwh_dim_coupons_v dc
    inner join dwh_fact_coupon_usages_v cu on cu.coupon_gk = dc.coupon_gk
    inner join dwh_fact_orders_v fo on fo.order_gk = cu.order_gk
  WHERE dc.total_redeemed_amount > 0.0 and dc.country_key = 2),

  rides as (SELECT
    u.user_gk
    ,fo.order_gk
    ,u.coupon_container_name
    ,cu.amount_redeemed_from_coupon
    ,fo.origin_location_key
    ,cu.coupon_gk
    ,fo.date_key
    ,fo.hour_key
    ,u.coupon_type
    ,cu.is_ftp_key
    ,fo.customer_total_cost_inc_vat
    ,fo.paid_with_prepaid
    ,u.created_date_key
    ,cu.max_amount_per_usage - cu.amount_redeemed_from_coupon as remain_from_coupon
    ,CASE WHEN fo.paid_with_prepaid is null THEN 0
      ELSE fo.paid_with_prepaid/fo.customer_total_cost_inc_vat END as share_paid_with_prepaid
    ,fo.driver_total_commission_inc_vat * -1.0 / 1.18 +
                      CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
                          THEN
                            (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
                       ELSE
                          (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END  as gp

  from coupon_usages
    inner join dwh_fact_orders_v fo ON fo.riding_user_gk = u.user_gk
                                       and DATEDIFF('day', u.start_datetime, fo.date_key) BETWEEN -1 AND 120
    inner join dwh_fact_rides_v fr ON fr.ride_gk = fo.order_gk
    left join coupon_usages cu ON cu.order_gk = fo.order_gk and cu.coupon_gk = u.coupon_gk
    INNER JOIN dbo.dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key

  where fo.Country_Symbol = 'RU'
              AND not(fo.Ride_Type_Key = 2)
              AND fo.order_status_key = 7
              AND dct.class_type_group_desc in ('VIP', 'Premium', 'VIP+')
              AND fo.customer_total_cost_inc_vat > 0
              AND fo.date_key > '2017-01-01' and fo.date_key < CURRENT_DATE-1)

  select
    r.coupon_container_name
--    ,CASE WHEN r.origin_location_key = 245 THEN 'Moscow'
--        WHEN r.origin_location_key = 246 THEN 'SPB'
--        ELSE 'Regions' END AS location
    ,trunc(date_trunc('mon', min(r.created_date_key))) as date_key
    ,count(DISTINCT CASE WHEN not(r.amount_redeemed_from_coupon is null) THEN r.coupon_gk ELSE 0 END) as coupon_activation
    ,ceiling(sum(r.remain_from_coupon)) as remain_from_coupon
    ,sum(CASE WHEN r.is_ftp_key = 1 THEN 1 ELSE 0 END) as ftrs
    ,sum(r.amount_redeemed_from_coupon) as coupon_spent_promo

    ,sum(CASE WHEN not(r.amount_redeemed_from_coupon is null) THEN 1 ELSE 0 END) as coupon_rides
    ,sum(CASE WHEN r.period = 'after_30' THEN 1 ELSE 0 END) as rides_30
    ,sum(CASE WHEN r.period = 'after_31_60' THEN 1 ELSE 0 END) as rides_31_60
    ,sum(CASE WHEN r.period = 'after_61_120' THEN 1 ELSE 0 END) as rides_61_120
    ,sum(CASE WHEN r.period = 'after_30' AND r.share_paid_with_prepaid < 0.30 THEN 1 ELSE 0 END) as rides_30_without_prepaid

    ,sum(CASE WHEN r.period = 'after_30' THEN r.customer_total_cost_inc_vat ELSE 0 END) as revenue_30
    ,sum(CASE WHEN r.period = 'after_31_60' THEN r.customer_total_cost_inc_vat ELSE 0 END) as revenue_31_60
    ,sum(CASE WHEN r.period = 'after_61_120' THEN r.customer_total_cost_inc_vat ELSE 0 END) as revenue_61_120

    ,sum(CASE WHEN r.period = 'after_30' THEN r.gp ELSE 0 END) as gp_30
    ,sum(CASE WHEN r.period = 'after_31_60' THEN r.gp ELSE 0 END) as gp_31_60
    ,sum(CASE WHEN r.period = 'after_61_120' THEN r.gp ELSE 0 END) as gp_61_120

  from rides as r

    where r.coupon_type in ('general', 'other', 'marketing', 'unknown')

GROUP BY r.coupon_container_name
HAVING count(DISTINCT CASE WHEN not(r.amount_redeemed_from_coupon is null) THEN r.coupon_gk ELSE 0 END) > 30



-- FTRs
with users as (SELECT
  dc.user_gk
  ,dc.coupon_container_name
  ,dc.coupon_gk
  ,dc.total_redeemed_amount
  ,dc.coupon_type
  ,dc.country_key
  ,dc.created_date_key
  ,CASE WHEN dc.num_of_usages >= dc.max_usages or dc.remaining_amount = 0 THEN dc.last_consumed_datetime
     WHEN dc.expiration_date < CURRENT_DATE THEN dc.expiration_date
     ELSE dc.expiration_date END as end_datetime
  ,CASE WHEN dc.num_of_usages >= dc.max_usages or dc.remaining_amount = 0 THEN dc.last_consumed_date_key
       WHEN dc.expiration_date < CURRENT_DATE THEN dc.expiration_date
       ELSE dc.expiration_date END as end_date
  ,dc.first_consumed_datetime as start_datetime
 FROM dwh_dim_coupons_v dc
   WHERE  dc.total_redeemed_amount > 0.0 and dc.created_date_key BETWEEN '2016-01-01' AND '2017-12-31' and dc.country_key = 2),

  coupon_usages as (
  SELECT
      cu.order_gk
      ,cu.amount_redeemed_from_coupon
      ,cu.coupon_gk
      ,fo.is_ftp_key
      ,CASE WHEN dc.max_usages = 0 THEN dc.coupon_initial_amount
            ELSE dc.coupon_initial_amount/dc.max_usages END as max_amount_per_usage
  FROM dwh_dim_coupons_v dc
    inner join dwh_fact_coupon_usages_v cu on cu.coupon_gk = dc.coupon_gk
    inner join dwh_fact_orders_v fo on fo.order_gk = cu.order_gk
  WHERE dc.total_redeemed_amount > 0.0 and dc.country_key = 2),

  rides as (SELECT
    u.user_gk
    ,fo.order_gk
    ,u.coupon_container_name
    ,cu.amount_redeemed_from_coupon
    ,fo.origin_location_key
    ,cu.coupon_gk
    ,fo.date_key
    ,fo.hour_key
    ,u.coupon_type
    ,cu.is_ftp_key
    ,fo.customer_total_cost_inc_vat
    ,fo.paid_with_prepaid
    ,u.created_date_key
    ,cu.max_amount_per_usage - cu.amount_redeemed_from_coupon as remain_from_coupon
    ,CASE WHEN fo.paid_with_prepaid is null THEN 0
      ELSE fo.paid_with_prepaid/fo.customer_total_cost_inc_vat END as share_paid_with_prepaid
    ,fo.driver_total_commission_inc_vat * -1.0 / 1.18 +
                      CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
                          THEN
                            (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
                       ELSE
                          (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END  as gp

  from coupon_usages
    inner join dwh_fact_orders_v fo ON fo.riding_user_gk = u.user_gk
                                       and DATEDIFF('day', u.start_datetime, fo.date_key) BETWEEN -1 AND 120
    inner join dwh_fact_rides_v fr ON fr.ride_gk = fo.order_gk
    left join coupon_usages cu ON cu.order_gk = fo.order_gk and cu.coupon_gk = u.coupon_gk
    INNER JOIN dbo.dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key

  where fo.Country_Symbol = 'RU'
              AND not(fo.Ride_Type_Key = 2)
              AND fo.order_status_key = 7
              AND dct.class_type_group_desc in ('VIP', 'Premium', 'VIP+')
              AND fo.customer_total_cost_inc_vat > 0
              AND fo.date_key > '2017-01-01' and fo.date_key < CURRENT_DATE-1)

  select
    r.coupon_container_name
    ,CASE WHEN r.origin_location_key = 245 THEN 'Moscow'
        WHEN r.origin_location_key = 246 THEN 'SPB'
        ELSE 'Regions' END AS location
    ,trunc(date_trunc('mon', min(r.created_date_key))) as date_key
    ,count(DISTINCT CASE WHEN not(r.amount_redeemed_from_coupon is null) THEN r.coupon_gk ELSE 0 END) as coupon_activation
    ,ceiling(sum(r.remain_from_coupon)) as remain_from_coupon
    ,sum(CASE WHEN r.is_ftp_key = 1 THEN 1 ELSE 0 END) as ftrs
    ,sum(r.amount_redeemed_from_coupon) as coupon_spent_promo

    ,sum(CASE WHEN not(r.amount_redeemed_from_coupon is null) THEN 1 ELSE 0 END) as coupon_rides
    ,sum(CASE WHEN r.period = 'after_30' THEN 1 ELSE 0 END) as rides_30
    ,sum(CASE WHEN r.period = 'after_31_60' THEN 1 ELSE 0 END) as rides_31_60
    ,sum(CASE WHEN r.period = 'after_61_120' THEN 1 ELSE 0 END) as rides_61_120
    ,sum(CASE WHEN r.period = 'after_30' AND r.share_paid_with_prepaid < 0.30 THEN 1 ELSE 0 END) as rides_30_without_prepaid

    ,sum(CASE WHEN r.period = 'after_30' THEN r.customer_total_cost_inc_vat ELSE 0 END) as revenue_30
    ,sum(CASE WHEN r.period = 'after_31_60' THEN r.customer_total_cost_inc_vat ELSE 0 END) as revenue_31_60
    ,sum(CASE WHEN r.period = 'after_61_120' THEN r.customer_total_cost_inc_vat ELSE 0 END) as revenue_61_120

    ,sum(CASE WHEN r.period = 'after_30' THEN r.gp ELSE 0 END) as gp_30
    ,sum(CASE WHEN r.period = 'after_31_60' THEN r.gp ELSE 0 END) as gp_31_60
    ,sum(CASE WHEN r.period = 'after_61_120' THEN r.gp ELSE 0 END) as gp_61_120

  from rides as r

    where r.coupon_type in ('general', 'other', 'marketing', 'unknown')

GROUP BY r.coupon_container_name
HAVING count(DISTINCT CASE WHEN not(r.amount_redeemed_from_coupon is null) THEN r.coupon_gk ELSE 0 END) > 30















with users as (SELECT
  dc.user_gk
  ,dc.coupon_container_name
  ,dc.coupon_gk
  ,dc.total_redeemed_amount
  ,dc.coupon_type
  ,dc.country_key
  ,dc.created_date_key
  ,CASE WHEN dc.num_of_usages >= dc.max_usages or dc.remaining_amount = 0 THEN dc.last_consumed_datetime
     WHEN dc.expiration_date < CURRENT_DATE THEN dc.expiration_date
     ELSE dc.expiration_date END as end_datetime
  ,CASE WHEN dc.num_of_usages >= dc.max_usages or dc.remaining_amount = 0 THEN dc.last_consumed_date_key
       WHEN dc.expiration_date < CURRENT_DATE THEN dc.expiration_date
       ELSE dc.expiration_date END as end_date
  ,dc.first_consumed_datetime as start_datetime
 FROM dwh_dim_coupons_v dc
   WHERE  dc.total_redeemed_amount > 0.0 and dc.is_ftr_key=1 and dc.created_date_key >=  '2017-01-01' and dc.country_key = 2),

  campaigns as (SELECT
  dc.coupon_container_name
  ,count(DISTINCT dc.coupon_gk) as activations
  ,trunc(date_trunc('mon', min(dc.created_date_key))) as created_date_key
 FROM dwh_dim_coupons_v dc
   WHERE  dc.total_redeemed_amount > 0.0 and dc.is_ftr_key=1 and dc.created_date_key >=  '2017-01-01' and dc.country_key = 2
  GROUP BY 1),

  coupon_usages as (
  SELECT
      cu.order_gk
      ,cu.amount_redeemed_from_coupon
      ,cu.coupon_gk
      ,fo.is_ftp_key
      ,CASE WHEN dc.max_usages = 0 THEN dc.coupon_initial_amount
            ELSE dc.coupon_initial_amount/dc.max_usages END as max_amount_per_usage
  FROM dwh_dim_coupons_v dc
    inner join dwh_fact_coupon_usages_v cu on cu.coupon_gk = dc.coupon_gk
    inner join dwh_fact_orders_v fo on fo.order_gk = cu.order_gk
  WHERE dc.total_redeemed_amount > 0.0 and dc.country_key = 2),

  rides as (SELECT
    ca.coupon_container_name
    ,ca.activations as total_activations
    ,ca.created_date_key as created_date_key
    ,CASE WHEN DATEDIFF('day', u.end_datetime, fr.ride_end_datetime) <= 30 THEN 'after_30'
         WHEN DATEDIFF('day', u.end_datetime, fr.ride_end_datetime) BETWEEN 31 AND 60 THEN 'after_31_60'
         WHEN DATEDIFF('day', u.end_datetime, fr.ride_end_datetime) BETWEEN 61 AND 120 THEN 'after_61_120'
         ELSE 'after_120>' END as period
    ,u.user_gk
    ,fo.order_gk
    ,cu.amount_redeemed_from_coupon
    ,fo.origin_location_key
    ,cu.coupon_gk
    ,fo.date_key
    ,fo.hour_key
    ,u.coupon_type
    ,cu.is_ftp_key
    ,fo.customer_total_cost_inc_vat
    ,fo.paid_with_prepaid
    ,cu.max_amount_per_usage - cu.amount_redeemed_from_coupon as remain_from_coupon
    ,CASE WHEN fo.paid_with_prepaid is null THEN 0
      ELSE fo.paid_with_prepaid/fo.customer_total_cost_inc_vat END as share_paid_with_prepaid
    ,fo.driver_total_commission_inc_vat* -1.0 / 1.18 +
                      CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
                          THEN
                            (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
                       ELSE
                          (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END  as gp

    from campaigns ca
    inner join users u on u.coupon_container_name = ca.coupon_container_name
    inner join dwh_fact_orders_v fo ON fo.riding_user_gk = u.user_gk
                                       and DATEDIFF('day', u.start_datetime, fo.date_key) BETWEEN -1 AND 120
    inner join dwh_fact_rides_v fr ON fr.ride_gk = fo.order_gk
    left join coupon_usages cu ON cu.order_gk = fo.order_gk and cu.coupon_gk = u.coupon_gk

  where fo.Country_Symbol = 'RU'
              AND not(fo.Ride_Type_Key = 2)
              AND fo.order_status_key = 7
              AND fo.customer_total_cost_inc_vat > 0
              AND fo.date_key >= '2017-01-01' and fo.date_key < CURRENT_DATE-1)

  select
    r.coupon_container_name
    ,r.created_date_key as Month
    ,r.total_activations
    ,CASE WHEN r.origin_location_key = 245 THEN 'Moscow'
        WHEN r.origin_location_key = 246 THEN 'SPB'
        ELSE 'Regions' END AS location
    ,count(DISTINCT CASE WHEN not(r.amount_redeemed_from_coupon is null) THEN r.coupon_gk ELSE 0 END) as coupon_activation
    ,ceiling(sum(r.remain_from_coupon)) as remain_from_coupon
    ,sum(CASE WHEN r.is_ftp_key = 1 THEN 1 ELSE 0 END) as ftrs
    ,sum(r.amount_redeemed_from_coupon) as coupon_spent_promo

    ,sum(CASE WHEN not(r.amount_redeemed_from_coupon is null) THEN 1 ELSE 0 END) as coupon_rides
    ,sum(CASE WHEN r.period = 'after_30' THEN 1 ELSE 0 END) as rides_30
    ,sum(CASE WHEN r.period = 'after_31_60' THEN 1 ELSE 0 END) as rides_31_60
    ,sum(CASE WHEN r.period = 'after_61_120' THEN 1 ELSE 0 END) as rides_61_120
    ,sum(CASE WHEN r.period = 'after_30' AND r.share_paid_with_prepaid < 0.30 THEN 1 ELSE 0 END) as rides_30_without_prepaid

    ,sum(CASE WHEN r.period = 'after_30' THEN r.customer_total_cost_inc_vat ELSE 0 END) as revenue_30
    ,sum(CASE WHEN r.period = 'after_31_60' THEN r.customer_total_cost_inc_vat ELSE 0 END) as revenue_31_60
    ,sum(CASE WHEN r.period = 'after_61_120' THEN r.customer_total_cost_inc_vat ELSE 0 END) as revenue_61_120

    ,sum(CASE WHEN r.period = 'after_30' THEN r.gp ELSE 0 END) as gp_30
    ,sum(CASE WHEN r.period = 'after_31_60' THEN r.gp ELSE 0 END) as gp_31_60
    ,sum(CASE WHEN r.period = 'after_61_120' THEN r.gp ELSE 0 END) as gp_61_120
  from rides as r
    where r.coupon_type in ('general', 'other', 'marketing', 'unknown')
  GROUP BY 1,2,3, 4
  HAVING r.total_activations > 30



with users as (SELECT
  dc.user_gk
  ,dc.coupon_container_name
  ,dc.coupon_gk
  ,dc.total_redeemed_amount
  ,dc.coupon_type
  ,dc.country_key
  ,dc.created_date_key
  ,CASE WHEN dc.num_of_usages >= dc.max_usages or dc.remaining_amount = 0 THEN dc.last_consumed_datetime
     WHEN dc.expiration_date < CURRENT_DATE THEN dc.expiration_date
     ELSE dc.expiration_date END as end_datetime
  ,CASE WHEN dc.num_of_usages >= dc.max_usages or dc.remaining_amount = 0 THEN dc.last_consumed_date_key
       WHEN dc.expiration_date < CURRENT_DATE THEN dc.expiration_date
       ELSE dc.expiration_date END as end_date
  ,dc.first_consumed_datetime as start_datetime
 FROM dwh_dim_coupons_v dc
     WHERE  dc.total_redeemed_amount > 0.0 and dc.created_date_key >= '2017-01-01'  and dc.country_key = 2 and dc.is_ftr_key=1),

   campaigns as (SELECT
      dc.coupon_container_name
      ,count(DISTINCT dc.user_gk) as activations
     FROM dwh_dim_coupons_v dc
       WHERE  dc.total_redeemed_amount > 0.0 and dc.created_date_key >= '2017-01-01'  and dc.country_key = 2 and dc.is_ftr_key=1
      GROUP BY 1)

    SELECT
      ca.coupon_container_name
      ,ca.activations
      ,CASE WHEN fo.origin_location_key = 245 THEN 'Moscow'
        WHEN fo.origin_location_key = 246 THEN 'SPB'
        ELSE 'Regions' END AS location
      ,trunc(date_trunc('mon', fo.date_key)) as Month
      ,sum(cu.amount_redeemed_from_coupon) as d_coupon_spent
      ,count(*) as d_coupon_rides
      ,count(DISTINCT dc.user_gk) as d_activations
      ,sum(fo.is_ftp_key) as d_ftrs
      ,avg(fo.customer_total_cost_inc_vat) as d_check

  FROM campaigns ca
    inner join users dc ON dc.coupon_container_name = ca.coupon_container_name
    inner join dwh_fact_coupon_usages_v cu on cu.coupon_gk = dc.coupon_gk
    inner join dwh_fact_orders_v fo on fo.order_gk = cu.order_gk
  WHERE dc.total_redeemed_amount > 0.0
        and dc.country_key = 2
        and dc.coupon_type in ('general', 'other', 'marketing', 'unknown')
        and not(fo.Ride_Type_Key = 2)
        AND fo.order_status_key = 7
  GROUP BY 1,2,3,4
  HAVING ca.activations > 30

with users as (SELECT
  dc.user_gk
  ,dc.coupon_container_name
  ,dc.coupon_gk
  ,dc.total_redeemed_amount
  ,dc.coupon_type
  ,dc.country_key
  ,dc.created_date_key
  ,CASE WHEN dc.num_of_usages >= dc.max_usages or dc.remaining_amount = 0 THEN dc.last_consumed_datetime
     WHEN dc.expiration_date < CURRENT_DATE THEN dc.expiration_date
     ELSE dc.expiration_date END as end_datetime
  ,CASE WHEN dc.num_of_usages >= dc.max_usages or dc.remaining_amount = 0 THEN dc.last_consumed_date_key
       WHEN dc.expiration_date < CURRENT_DATE THEN dc.expiration_date
       ELSE dc.expiration_date END as end_date
  ,dc.first_consumed_datetime as start_datetime
FROM dwh_dim_coupons_v dc
 WHERE  dc.total_redeemed_amount > 0.0 and dc.country_key = 2 and dc.is_ftr_key=0 and dc.created_date_key >= '2017-01-01'),

  campaigns as (SELECT
    dc.coupon_container_name
    ,count(DISTINCT dc.coupon_gk) as activations
    ,trunc(date_trunc('mon', min(dc.created_date_key))) as created_date_key
   FROM dwh_dim_coupons_v dc
     WHERE  dc.total_redeemed_amount > 0.0 and dc.country_key = 2 and dc.is_ftr_key=0 and dc.created_date_key >= '2017-01-01'
    GROUP BY 1),

  coupon_usages as (
  SELECT
      cu.order_gk
      ,cu.amount_redeemed_from_coupon
      ,cu.coupon_gk
      ,fo.is_ftp_key
      ,CASE WHEN dc.max_usages = 0 THEN dc.coupon_initial_amount
            ELSE dc.coupon_initial_amount/dc.max_usages END as max_amount_per_usage
  FROM dwh_dim_coupons_v dc
    inner join dwh_fact_coupon_usages_v cu on cu.coupon_gk = dc.coupon_gk
    inner join dwh_fact_orders_v fo on fo.order_gk = cu.order_gk
  WHERE dc.total_redeemed_amount > 0.0 and dc.country_key = 2 and dc.is_ftr_key=0 and dc.created_date_key >= '2017-01-01'),

  rides as (SELECT

    ca.coupon_container_name
    ,ca.activations as total_activations
    ,ca.created_date_key as created_date_key
    ,CASE WHEN dateadd(m, +3, fr.ride_end_datetime) < u.start_datetime THEN 'before'
         WHEN DATEDIFF('day', u.end_datetime, fr.ride_end_datetime) <= 30 THEN 'after_30'
         WHEN DATEDIFF('day', u.end_datetime, fr.ride_end_datetime) BETWEEN 31 AND 60 THEN 'after_60'
         ELSE 'after_60>' END as period
    ,u.user_gk
    ,fo.order_gk
    ,cu.amount_redeemed_from_coupon
    ,fo.origin_location_key
    ,cu.coupon_gk
    ,fo.date_key
    ,fo.hour_key
    ,u.coupon_type
    ,cu.is_ftp_key
    ,fo.customer_total_cost_inc_vat
    ,fo.paid_with_prepaid
    ,cu.max_amount_per_usage - cu.amount_redeemed_from_coupon as remain_from_coupon
    ,CASE WHEN fo.paid_with_prepaid is null THEN 0
      ELSE fo.paid_with_prepaid/fo.customer_total_cost_inc_vat END as share_paid_with_prepaid
    ,fo.driver_total_commission_inc_vat* -1.0 / 1.18 +
                      CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
                          THEN
                            (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
                       ELSE
                          (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END  as gp
  from campaigns ca
    inner join users u on u.coupon_container_name = ca.coupon_container_name
    inner join dwh_fact_orders_v fo ON fo.riding_user_gk = u.user_gk
                                       and DATEDIFF('day', u.start_datetime, fo.date_key) BETWEEN -30 AND 60 + DATEDIFF('day', u.start_datetime, u.end_datetime)
    inner join dwh_fact_rides_v fr ON fr.ride_gk = fo.order_gk
    left join coupon_usages cu ON cu.order_gk = fo.order_gk and cu.coupon_gk = u.coupon_gk

  where fo.Country_Symbol = 'RU'
              AND not(fo.Ride_Type_Key = 2)
              AND fo.order_status_key = 7
              AND fo.customer_total_cost_inc_vat > 0
              AND fo.date_key > '2017-01-01' and fo.date_key < CURRENT_DATE-1)

select
    r.coupon_container_name
    ,r.created_date_key as Month
    ,r.total_activations
    ,CASE WHEN r.origin_location_key = 245 THEN 'Moscow'
        WHEN r.origin_location_key = 246 THEN 'SPB'
        ELSE 'Regions' END AS location
    ,count(DISTINCT CASE WHEN not(r.amount_redeemed_from_coupon is null) THEN r.coupon_gk ELSE 0 END) as coupon_activation
    ,sum(CASE WHEN r.period = 'before' THEN 1 ELSE 0 END) as before_rides_30
    ,sum(CASE WHEN r.period = 'after_30' THEN 1 ELSE 0 END) as after_ride_30
    ,sum(CASE WHEN r.period = 'after_30' AND r.share_paid_with_prepaid < 0.30 THEN 1 ELSE 0 END) as after_ride_30_without_prepaid
    ,sum(CASE WHEN r.period = 'after_60' THEN 1 ELSE 0 END) as after_ride_31_60
    ,ceiling(sum(r.remain_from_coupon)) as remain_from_coupon
    ,sum(r.amount_redeemed_from_coupon) as coupon_spent_promo
    ,sum(CASE WHEN not(r.amount_redeemed_from_coupon is null) THEN 1 ELSE 0 END) as coupon_rides_promo
    ,sum(r.amount_redeemed_from_coupon) as coupon_spent_promo
    ,sum(CASE WHEN r.period = 'before' THEN r.customer_total_cost_inc_vat ELSE 0 END) as before_revenue_30
    ,sum(CASE WHEN r.period = 'after_30' THEN r.customer_total_cost_inc_vat ELSE 0 END) as after_revenue_30
    ,sum(CASE WHEN r.period = 'before' THEN r.gp ELSE 0 END) as before_gp_30
    ,sum(CASE WHEN r.period = 'after_30' THEN r.gp ELSE 0 END) as after_gp_30
    ,sum(CASE WHEN r.is_ftp_key = 1 THEN 1 ELSE 0 END) as ftrs
from rides as r
  where r.coupon_type in ('general', 'other', 'marketing', 'unknown')

  GROUP BY 1,2,3, 4
  HAVING r.total_activations > 30
  order by 1











































-- RFM prediction model status
select
	u.user_gk
from dbo.dwh_dim_users_v as u
  inner join dwh_dim_rankings_v r on r.ranking_key = u.ranking_key
where u.country_key = 2 and u.primary_city_id in (245,246)
      and u.ranking_key in (3) and u.rfm_drop_prob_decile_country in (1,2,3)

-- 2GIS FTRs by month - размещение заказа
SELECT
  TRUNC(DATE_TRUNC('mon', u.registration_date_key)) as date
  ,l.city_name
  ,count(DISTINCT u.user_gk) as FTRs
FROM Dwh_Dim_Users_V u
  INNER JOIN Dwh_Fact_Orders_V fo ON fo.Riding_User_GK = u.User_GK
  LEFT JOIN (SELECT DISTINCT l.city_id, l.city_name
            FROM dwh_dim_locations_v l) l on u.primary_city_id = l.city_id
where u.Acquisition_Channel_Desc = 'GIS' and u.Registration_Date_Key between '2018-04-01' and '2018-04-31'
GROUP BY 1,2
ORDER BY 1,2

-- 2GIS FTRs by region
SELECT
  l.city_name
  ,count(DISTINCT u.user_gk) as FTRs
FROM Dwh_Dim_Users_V u
  INNER JOIN Dwh_Fact_Orders_V fo ON fo.Riding_User_GK = u.User_GK
  LEFT JOIN (SELECT DISTINCT l.city_id, l.city_name
            FROM dwh_dim_locations_v l) l on u.primary_city_id = l.city_id
where u.Acquisition_Channel_Desc = 'GIS'
       and u.Registration_Date_Key between '2018-04-01' AND '2018-04-30'
GROUP BY l.city_name
ORDER BY count(DISTINCT u.user_gk) DESC






-- Rides dashboard
with users as (
  select
    trunc(date_trunc('mon', fr.date_key)) as month
    ,du.user_gk
    ,min(fr.ride_gk) as first_month_ride_gk
    ,count(*) as rides
  from dwh_fact_rides_v fr
    inner join dwh_dim_users_v du ON du.user_gk = fr.riding_user_gk
  where fr.country_key = 2 and fr.date_key BETWEEN '2017-01-01' AND current_date
  group by 1,2),

stats as (select
  u.month
  ,u.user_gk
  ,u.first_month_ride_gk
  ,u.rides
  ,count(fr_last_30.date_key) as num_rides_previous_30
from users as u
left join dwh_fact_rides_v fr_last_30 ON u.user_gk = fr_last_30.riding_user_gk
                  AND DATEDIFF('month', trunc(date_trunc('mon', fr_last_30.date_key)), u.month) = 1
group by 1,2,3,4)


select
  p.timecategory
  ,p.subperiod2 as Period
  ,CASE WHEN fo.ride_type_key = 2 THEN 'B2B'
        WHEN dct.class_type_group_desc in ('VIP','VIP+','Premium') THEN 'B&V'
        WHEN fo_current_month.origin_location_key = 245 THEN 'Msk'
        WHEN fo_current_month.origin_location_key = 246 THEN 'Spb'
        ELSE 'Regions' END as Domain
  ,CASE WHEN s.num_rides_previous_30 > 0 THEN 'active_base'
        WHEN fo.is_ftp_key = 1 THEN 'FTR'
        WHEN s.num_rides_previous_30 = 0 AND fo.paid_with_prepaid > 0 THEN 'CRM_reactivation'
        ELSE 'organic_reactivation' END as type
  ,count(fo_current_month.order_gk) as rides
  ,count(DISTINCT s.user_gk) as users
  ,1.0 * count(fo_current_month.order_gk)/count(DISTINCT s.user_gk) rides_user
from stats s
  inner join dwh_fact_orders_v fo ON fo.order_gk = s.first_month_ride_gk
  inner join dwh_fact_orders_v fo_current_month ON fo_current_month.riding_user_gk = s.user_gk
        AND trunc(date_trunc('mon', fo_current_month.date_key)) = s.month
  inner join dbo.dwh_dim_class_types_v dct ON dct.class_type_key = fo_current_month.class_type_key
  join dbo.periods_v p on p.date_key = fo_current_month.date_key
where fo.ride_type_key != 2
      and fo.order_status_key = 7
      and fo_current_month.ride_type_key != 2
      and fo_current_month.order_status_key = 7
      and p.timecategory in ('3.Weeks', '4.Months', '5.Quarters')
      and p.hour_key = 0
group by 1,2,3,4

UNION

select
  p.timecategory
  ,p.subperiod2 as Period
  ,'all' as Domain
  ,CASE WHEN s.num_rides_previous_30 > 0 THEN 'active_base'
        WHEN fo.is_ftp_key = 1 THEN 'FTR'
        WHEN s.num_rides_previous_30 = 0 AND fo.paid_with_prepaid > 0 THEN 'CRM_reactivation'
        ELSE 'organic_reactivation' END as type
  ,count(fo_current_month.order_gk) as rides
  ,count(DISTINCT s.user_gk) as users
  ,1.0 * count(fo_current_month.order_gk)/count(DISTINCT s.user_gk) rides_user
from stats s
  inner join dwh_fact_orders_v fo ON fo.order_gk = s.first_month_ride_gk
  inner join dwh_fact_orders_v fo_current_month ON fo_current_month.riding_user_gk = s.user_gk
        AND trunc(date_trunc('mon', fo_current_month.date_key)) = s.month
  inner join dbo.dwh_dim_class_types_v dct ON dct.class_type_key = fo_current_month.class_type_key
  join dbo.periods_v p on p.date_key = fo_current_month.date_key
where fo.ride_type_key != 2
      and fo.order_status_key = 7
      and fo_current_month.ride_type_key != 2
      and fo_current_month.order_status_key = 7
      and p.timecategory in ('3.Weeks', '4.Months', '5.Quarters')
      and p.hour_key = 0
group by 1,2,3,4
order by 1,2,3




with random_users as (select
  DISTINCT fo.riding_user_gk as user_gk
  ,'random_users' as group
from dwh_fact_orders_v fo
where fo.origin_location_key = 245
      and fo.ride_type_key != 2
      and fo.order_status_key = 7
      and fo.date_key between current_date - 60 and current_date
order by RANDOM()
limit 10000),

all_users as (select
  DISTINCT fo.riding_user_gk as user_gk
  ,'all_users' as group
from dwh_fact_orders_v fo
where fo.origin_location_key = 245
      and fo.ride_type_key != 2
      and fo.order_status_key = 7
      and fo.date_key between current_date - 60 and current_date),

all_data as (select
  *
from all_users
union
select
  *
from random_users)

select
  ad.group
  ,avg(fo.customer_total_cost_inc_vat) as bill
  ,1.0 * count(*)/count(DISTINCT fo.riding_user_gk) as rides_per_user
  ,avg(fo.ride_distance_key) as distance
  ,1.0* count(DISTINCT CASE WHEN du.ranking_key = 1 THEN du.user_gk ELSE 0 END)/count(DISTINCT fo.riding_user_gk) as platinum_share
  ,1.0* count(DISTINCT CASE WHEN du.ranking_key = 2 THEN du.user_gk ELSE 0 END)/count(DISTINCT fo.riding_user_gk) as gold_share
from all_data ad
  inner join dwh_fact_orders_v fo on fo.riding_user_gk = ad.user_gk
  inner join dwh_dim_users_v du on du.user_gk = fo.riding_user_gk
where fo.origin_location_key = 245
      and fo.ride_type_key != 2
      and fo.order_status_key = 7
      and fo.date_key between current_date - 60 and current_date
group by 1


with users as (select
  fo.riding_user_gk
  ,ceil(avg(fo.origin_location_key)) as origin_location_key
  ,sum(CASE WHEN dct.class_type_group_key = 3 and fo.date_key > current_date - 31 THEN 1 ELSE 0 END) as economy_rides_30
  ,sum(CASE WHEN dct.class_type_group_key = 1 and fo.date_key > current_date - 31 THEN 1 ELSE 0 END) as comfort_rides_30
  ,sum(CASE WHEN dct.class_type_group_key = 1 and fo.date_key > current_date - 62 THEN 1 ELSE 0 END) as comfort_rides_last_90
  ,sum(CASE WHEN dct.class_type_group_key = 1 THEN 1 ELSE 0 END) as comfort_rides_last_year
  ,sum(CASE WHEN fo.date_key > current_date - 31 THEN 1 ELSE 0 END) as total_rides_30
from dwh_fact_orders_v fo
  inner join dbo.dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
WHERE fo.order_status_key = 7
    and fo.origin_location_key in (246, 245)
    and fo.ride_type_key = 1
    and fo.date_key > current_date - 121
    AND dct.class_type_group_key in (1,3)
    and fo.country_key = 2
group by 1
HAVING sum(CASE WHEN fo.date_key > current_date - 32 THEN 1 ELSE 0 END) > 0)
SELECT
  u.origin_location_key
  ,CASE WHEN u.economy_rides_30 = 0 THEN 'core_comfort'
       WHEN u.economy_rides_30 > 0 AND u.comfort_rides_30 > 0 THEN 'economy_with_comfort_30'
       WHEN u.economy_rides_30 > 0 AND u.comfort_rides_last_90 > 0 THEN 'economy_with_comfort_last_90'
       WHEN u.economy_rides_30 > 0 AND u.comfort_rides_last_year > 0 THEN 'economy_with_comfort_last year'
       ELSE 'economy_without_comfort_ever' END as group_name
  ,count(DISTINCT CASE WHEN u.total_rides_30 > 0 THEN u.riding_user_gk END) as users
  ,sum(u.economy_rides_30) as economy_rides_30
  ,sum(u.comfort_rides_30) as comfort_rides_30
from users u
group by 1,2
order by 1,2
select
/*  dc.activated_date_key
  ,fo.customer_total_cost_inc_vat as gett_actual_client
  ,fo.driver_total_cost_inc_vat as gett_actual_driver
  ,fo.driver_total_commission_inc_vat as commission*/
  count(*)
from dwh_dim_coupons_v dc
  inner join dbo.dwh_fact_coupon_usages_v cu ON cu.coupon_gk = dc.coupon_gk
  inner join dbo.dwh_fact_orders_v fo on fo.order_gk = cu.order_gk
where (lower(dc.external_id) like 'dmd%' or lower(dc.coupon_container_name) like 'dmd%')
      and dc.activated_date_key > '2017-01-01'
      and fo.order_status_key = 7
      and fo.ride_type_key = 1




select

from dwh_dim_coupons_v dc
  inner join dwh_fact_coupon_usages_v du ON du.coupon_gk = dc.coupon_gk
  inner join dwh_fact_orders_v fo ON fo.order_gk = du.order_gk
where dc.external_id like '%reactivation%' and dc.created_date_key > '2017-01-01'
      and fo.order_status_key = 7
      and fo.ride_type_key = 1
      and fo.country_key = 2




with users as (select
  fo.riding_user_gk
  ,ceil(avg(fo.origin_location_key)) as origin_location_key
  ,SUM(CASE WHEN dct.class_type_group_key = 1 THEN 1 ELSE 0 END) as comfort_rides
  ,SUM(CASE WHEN dct.class_type_group_key = 3 THEN 1 ELSE 0 END) as economy_rides
  ,count(*) as rides
  ,1.0*SUM(CASE WHEN dct.class_type_group_key = 1 THEN 1 ELSE 0 END)/count(*) as comfort_share
from dwh_fact_orders_v fo
      INNER JOIN dbo.dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
  where fo.date_key > '2018-01-15'
        and fo.ride_type_key = 1
        and fo.order_status_key = 7
        and dct.class_type_group_key in (1,3)
        and fo.origin_location_key in (245, 246)
group by 1)

select
  u.origin_location_key
  ,CASE WHEN u.rides < 4 THEN 'question marks'
        WHEN u.comfort_share > 0.7 THEN 'core_comfort'
        WHEN u.comfort_share between 0.3 and 0.7 THEN 'mixed'
        ELSE 'economy' END as user_group
  ,count(*) users
  ,sum(u.comfort_rides) as comfort_rides
  ,sum(u.economy_rides) as economy_rides
from users u
group by 1,2
order by 1,2




select
  fo.order_gk
  ,fo.driver_total_commission_inc_vat * -1.0 / 1.18 +
                  CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
                      THEN
                        (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
                   ELSE
                      (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END as Margin
from dbo.dwh_fact_orders_v fo
  inner join dbo.dwh_dim_users_v du on du.user_gk = fo.riding_user_gk
  inner join dwh_dim_rankings_v dr ON dr.ranking_key = du.ranking_key
where fo.ride_type_key = 1
      and fo.order_status_key = 7
      and fo.date_key between '2018-01-16'
      and '2018-02-16'
      and fo.origin_location_key = 245
group by 1,2




with users as (select
  fo.riding_user_gk
  ,fo.dest_full_address
  ,fo.origin_full_address
  ,row_number() OVER(PARTITION BY fo.riding_user_gk ORDER BY count(*) DESC) as rnk
  ,count(*) as num_rides
  ,max(fo.date_key) as last_date_key
from dwh_fact_orders_v fo
  inner join dwh_dim_users_v du ON du.user_gk = fo.riding_user_gk
where fo.ride_type_key = 1
      and fo.order_status_key = 7
      and fo.country_key = 2
      and du.number_of_private_purchases > 0
      and fo.loyalty_level_key

group by 1,2,3
  HAVING max(fo.date_key) > current_date - 60
order by 1,5 DESC, 6 DESC)

select
  u.riding_user_gk
  ,u.dest_full_address
  ,u.origin_full_address
from users u
  inner join dwh_dim_users_v du on du.user_gk = u.riding_user_gk
where u.rnk = 1 and 1.0 * u.num_rides / du.number_of_private_purchases > 0.20 and du.number_of_private_purchases > 10
      and not(u.dest_full_address is null) and not(u.origin_full_address is null)





select
  fr.riding_user_gk
  ,count(*) as rides
from dwh_fact_rides_v fr
inner join dwh_dim_users_v du on du.user_gk = fr.riding_user_gk
where du.number_of_private_purchases = 0 and fr.ride_type_key = 1 and fr.country_key = 2
group by 1

select
  count(*)
from dwh_fact_rides_v fr
where fr.riding_user_gk = 20002059183


with users as (select
  fo.riding_user_gk
  ,dc.first_consumed_date_key as start_date
  ,CASE WHEN dc.num_of_usages >= dc.max_usages or dc.remaining_amount = 0 THEN dc.last_consumed_date_key
       WHEN dc.expiration_date < CURRENT_DATE THEN TRUNC(DATE_TRUNC('day', dc.expiration_date))
       ELSE TRUNC(DATE_TRUNC('day', dc.expiration_date))  END as end_date
from dwh_dim_coupons_v dc
  inner join dwh_fact_coupon_usages_v cu on dc.coupon_gk = cu.coupon_gk
  inner join dwh_fact_orders_v fo on fo.order_gk = cu.order_gk
where dc.country_key = 2
      and dc.coupon_type = 'appboy'
      and fo.order_status_key = 7
      and fo.ride_type_key = 1
      and dc.total_redeemed_amount > 0
      and dc.activated_date_key > '2017-10-01'),
stats as (select
  u.riding_user_gk
  ,sum(CASE WHEN fr.date_key < u.start_date THEN 1 ELSE 0 END) as rides_before
  ,sum(CASE WHEN fr.date_key > u.end_date THEN 1 ELSE 0 END) as rides_after
from users u
inner join dwh_fact_rides_v fr on fr.riding_user_gk = u.riding_user_gk
                                  and (DATEDIFF('day', fr.date_key, u.start_date) BETWEEN 0 AND 30
                                  or DATEDIFF('day', u.end_date, fr.date_key) BETWEEN 0 AND 30)
  where fr.ride_type_key = 1
group by 1)
select
  s.riding_user_gk
from stats s
  inner join dwh_dim_users_v du on du.user_gk = s.riding_user_gk
where s.rides_after > s.rides_before and du.number_of_private_purchases_last_30_days < 10
















with users as (select
  fo.riding_user_gk
  ,lower(du.first_name) as first_name
  ,gn.gender as ru_gender
  ,gnm.gender as en_gender
from dwh_fact_orders_v fo
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
  inner join dwh_dim_users_v du ON du.user_gk = fo.riding_user_gk
  left join analysis.as_gender_names as gn    ON lower(du.first_name) ILIKE '% ' + lower(gn.ru_name) + ' %'
                                              OR lower(du.first_name) ILIKE '% ' + lower(gn.ru_name)
                                              OR lower(du.first_name) ILIKE lower(gn.ru_name) + ' %'
                                              OR lower(du.first_name) = lower(gn.ru_name)
  left join analysis.as_gender_names as gnm   ON lower(du.first_name) ILIKE '% ' + lower(gnm.ru_name) + ' %'
                                              OR lower(du.first_name) ILIKE '% ' + lower(gnm.ru_name)
                                              OR lower(du.first_name) ILIKE lower(gnm.ru_name) + ' %'
                                              OR lower(du.first_name) = lower(gnm.ru_name)
where fo.date_key > current_date - 61
      and fo.ride_type_key = 1
      and dct.class_type_group_desc in ('Premium', 'VIP', 'VIP+')
      and fo.order_status_key = 7
      and fo.country_key = 2
      and fo.origin_location_key = 245
      and gn.ru_name != 'Алекса'
group by 1,2,3,4
HAVING count(*) > 2)

select
  u.first_name
  ,u.ru_gender
  ,u.riding_user_gk
from users u
where u.en_gender = 'F' or u.ru_gender = 'F'



















SELECT
  *
FROM periods_v
LIMIT 15




SELECT
  *
FROM analysis.mav_rides_predictions

select
  *
from periods_v p
where p.date_key > current_date - 1
and p.timecategory in ('3.Weeks', '4.Months', '5.Quarters') and p.hour_key = 0




with users as (
  select
    trunc(date_trunc('mon', fr.date_key)) as month
    ,du.user_gk
    ,min(fr.ride_gk) as first_month_ride_gk
    ,count(*) as rides
  from dwh_fact_rides_v fr
    inner join dwh_dim_users_v du ON du.user_gk =fr.riding_user_gk
  where fr.country_key = 2 and fr.date_key BETWEEN '2017-01-01' AND current_date
  group by 1,2),

stats as (select
  u.month
  ,u.user_gk
  ,u.first_month_ride_gk
  ,u.rides
  ,sum(CASE WHEN DATEDIFF('month', trunc(date_trunc('mon', fr_last_30.date_key)), u.month) = 1 THEN 1 ELSE 0 END) as num_rides_previous_30
  ,sum(CASE WHEN DATEDIFF('month', trunc(date_trunc('mon', fr_last_30.date_key)), u.month) = 2 THEN 1 ELSE 0 END) as num_rides_30_60
  ,sum(CASE WHEN DATEDIFF('month', trunc(date_trunc('mon', fr_last_30.date_key)), u.month) = 3 THEN 1 ELSE 0 END) as num_rides_60_90
from users as u
left join dwh_fact_rides_v fr_last_30 ON u.user_gk = fr_last_30.riding_user_gk
                  AND DATEDIFF('month', trunc(date_trunc('mon', fr_last_30.date_key)), u.month) in (1,2,3)
group by 1,2,3,4)


select
  p.timecategory
  ,p.subperiod2 as Period
  ,CASE WHEN dct.class_type_group_desc in ('VIP','VIP+','Premium') THEN 'B&V'
        WHEN fo_current_month.origin_location_key = 245 THEN 'Msk'
        WHEN fo_current_month.origin_location_key = 246 THEN 'Spb'
        ELSE 'Regions' END as Domain
  ,CASE WHEN s.num_rides_previous_30 > 0 and s.num_rides_30_60>0 and s.num_rides_60_90>0 THEN '1.Core_active'
        WHEN s.num_rides_previous_30 > 0 THEN '2.Non_core_active'
        WHEN fo.is_ftp_key = 1 THEN '3.FTR'
        WHEN s.num_rides_previous_30 = 0 AND fo.paid_with_prepaid > 0 THEN '5.CRM_reactivation'
        ELSE '4.organic_reactivation' END as type
  ,count(fo_current_month.order_gk) as rides
  ,count(DISTINCT s.user_gk) as users
  ,1.0 * count(fo_current_month.order_gk)/count(DISTINCT s.user_gk) rides_user
from stats s
  inner join dwh_fact_orders_v fo ON fo.order_gk = s.first_month_ride_gk
  inner join dwh_fact_orders_v fo_current_month ON fo_current_month.riding_user_gk = s.user_gk
        AND trunc(date_trunc('mon', fo_current_month.date_key)) = s.month
  inner join dbo.dwh_dim_class_types_v dct ON dct.class_type_key = fo_current_month.class_type_key
  join dbo.periods_v p on p.date_key = fo_current_month.date_key
where fo.ride_type_key != 2
      and fo.order_status_key = 7
      and fo_current_month.ride_type_key != 2
      and fo_current_month.order_status_key = 7
      and p.timecategory in ('3.Weeks', '4.Months', '5.Quarters')
      and p.hour_key = 0
group by 1,2,3,4

UNION

select
  p.timecategory
  ,p.subperiod2 as Period
  ,'all' as Domain
  ,CASE WHEN s.num_rides_previous_30 > 0 and s.num_rides_30_60>0 and s.num_rides_60_90>0 THEN '1.Core_active'
        WHEN s.num_rides_previous_30 > 0 THEN '2.Non_core_active'
        WHEN fo.is_ftp_key = 1 THEN '3.FTR'
        WHEN s.num_rides_previous_30 = 0 AND fo.paid_with_prepaid > 0 THEN '5.CRM_reactivation'
        ELSE '4.organic_reactivation' END as type
  ,count(fo_current_month.order_gk) as rides
  ,count(DISTINCT s.user_gk) as users
  ,1.0 * count(fo_current_month.order_gk)/count(DISTINCT s.user_gk) rides_user
from stats s
  inner join dwh_fact_orders_v fo ON fo.order_gk = s.first_month_ride_gk
  inner join dwh_fact_orders_v fo_current_month ON fo_current_month.riding_user_gk = s.user_gk
        AND trunc(date_trunc('mon', fo_current_month.date_key)) = s.month
  inner join dbo.dwh_dim_class_types_v dct ON dct.class_type_key = fo_current_month.class_type_key
  join dbo.periods_v p on p.date_key = fo_current_month.date_key
where fo.ride_type_key != 2
      and fo.order_status_key = 7
      and fo_current_month.ride_type_key != 2
      and fo_current_month.order_status_key = 7
      and p.timecategory in ('3.Weeks', '4.Months', '5.Quarters')
      and p.hour_key = 0
group by 1,2,3,4
order by 1,2,3






SELECT
  TRUNC(DATE_TRUNC('mon', u.registration_date_key)) as date
  ,l.city_name
  ,count(*)
FROM Dwh_Dim_Users_V u
  INNER JOIN Dwh_Fact_Orders_V fo ON fo.Riding_User_GK = u.User_GK
  LEFT JOIN  dwh_dim_locations_v l on fo.origin_location_key = l.location_key
where u.Acquisition_Channel_Desc = 'GIS'
       and u.Registration_Date_Key between '2018-02-01' and '2018-02-28'
        and fo.is_ftp_key = 0
GROUP BY TRUNC(DATE_TRUNC('mon', u.registration_date_key)), l.city_name
ORDER BY TRUNC(DATE_TRUNC('mon', u.registration_date_key)), count(DISTINCT u.user_gk) DESC



with currency as (
select (case when c.currency_base_code = 'ILS' then 1
        when c.currency_base_code = 'RUB' then 2
        when c.currency_base_code = 'GBP' then 3
        when  c.currency_base_code = 'USD' then 4 end) as country_key
      ,c.date_key
      ,(case when c.currency_base_code ='USD' then 1 else c.exchange_rate end) exchange_rate_to_USD
from dbo.dwh_dim_currency_rates_v as c
where (c.currency_to_code = 'USD' and c.currency_base_code in ('ILS','RUB','GBP'))
and c.date_key between '2018-03-01' and '2018-03-12'
 )

-- Event Data
SELECT count(*) FTR_VIP
FROM Dwh_Dim_Users_V u
JOIN Mrr_Phone_User_Ids p on u.resource_id = p.phone_user_id and u.country_key = p.Country_Key
JOIN dwh_fact_orders_v o on u.user_gk = o.riding_user_gk and o.date_key between '2018-03-01' and '2018-03-12'
JOIN dwh_dim_class_types_v ct on ct.Class_Type_Key = o.Class_Type_Key
JOIN dwh_dim_ride_types_v rt on o.ride_type_key = rt.ride_type_key
JOIN currency cr on cr.country_key = o.country_key and cr.date_key = o.date_key
JOIN dwh_dim_countries c on c.country_key = o.country_key
WHERE 1 = 1
    AND o.date_key between '2018-03-01' and '2018-03-12'
    AND o.order_status_key = 7
    AND rt.LOB_segment_key = 1 -- private
    AND ct.lob_category = 'Private Transportation' -- transportation
    AND o.is_lob_ftp_key = 1 -- ftr only
    AND o.country_key not in (-1, 4)
    AND main_device_desc in ('Android', 'iPhone', 'iOS')
    AND p.appsflyer_id is not null
    AND class_type_desc_eng IN
('krasnodar business fo only'
,'novosibirsk business'
,'moscow business fix'
,'kazan business fo only'
,'kazan business'
,'sochi visa business'
,'krasnodar business'
,'sochi business'
,'ekaterinburg business'
,'moscow sberbank business'
,'moscow visa business fix'
,'sp visa business'
,'moscow business'
,'sp business'
,'moscow business fix dynamic surge'
,'novosibirsk visa business'
,'sp business fix'
,'kazan visa business fo only'
,'kazan visa business'
,'krasnodar visa business'
,'ekaterinburg visa business'
,'moscow visa business'
,'sp business promo'
,'moscow business promo 2017')



select
  dc.external_id
  ,dc.activated_date_key
  ,count(*)
from dwh_dim_coupons_v dc
where lower(dc.external_id) in ('dmdandr1', 'dmdandr2')
      and dc.activated_date_key >= '2018-04-01'
group by 1,2


select
  dct.class_type_group_desc
  ,count(*)
from dwh_fact_orders_v fo
  inner join dwh_dim_class_types_v dct on dct.class_type_key = fo.class_type_key
where fo.ride_type_key = 1
      and fo.order_status_key = 7
      and dct.class_type_group_desc in ('Premium', 'VIP', 'VIP+')
      and fo.date_key between '2018-03-01' and '2018-03-12'
      and fo.country_key in (1,2,3)
      and fo.is_ftp_key = 1
GROUP BY 1







WITH
   dme_all_ftrs as (
    SELECT
      fr.ride_gk
      ,1 as dme_geo_ftr
    FROM dbo.dwh_fact_rides_v fr
    WHERE fr.Date_Key >= '2017-01-01'
      and fr.Is_FTP_Key = 1
      and fr.origin_latitude >= 55.383401
      and fr.origin_latitude <= 55.435248
      and fr.origin_longitude >= 37.855796
      and fr.origin_longitude <= 37.952613)

    ,dme_coupon_ftrs as (select
        d.first_ride_gk as ride_gk
        ,CASE WHEN d.last_purchase_date IS NULL THEN 'dme_coupon_ftr'
              WHEN datediff('day', d.last_purchase_date, d.activated_date_key) > 90 then 'dme_coupon_reactivation'
              ELSE 'dme_coupon_less_90' END as dme_coupon_ftr
      from (SELECT
        c.user_gk as riding_user_gk
        ,c.activated_date_key
        ,max(fr1.date_key) as last_purchase_date
        ,min(fr2.date_key) as first_purchase_date
        ,min(fr2.ride_gk) as first_ride_gk
      FROM dbo.dwh_dim_coupons_v c
        LEFT JOIN dwh_fact_rides_v fr1 ON fr1.riding_user_gk = c.user_gk and datediff('day', fr1.date_key, c.activated_date_key) > 0
        LEFT JOIN dwh_fact_rides_v fr2 ON fr2.riding_user_gk = c.user_gk and datediff('day', fr2.date_key, c.activated_date_key) <= 0
      WHERE c.coupon_text = 'B_A_BB_M_16042017' OR c.external_id LIKE 'dmd%'
      GROUP BY 1,2
      HAVING not(min(fr2.date_key) is null)) d)

  ,dme_class_ftrs as (
  SELECT
    fr.ride_gk
    ,1 as dme_class_ftr
    ,du.number_of_private_purchases
  FROM dbo.dwh_fact_rides_v fr
    inner join dwh_dim_users_v du ON du.user_gk = fr.riding_user_gk
  WHERE fr.is_ftp_key = 1
    AND fr.class_type_key = 2000282
    AND fr.date_key >= '2017-01-01'),

  data as (SELECT
    p.timecategory,
    p.subperiod2 as Period
    ,CASE WHEN dme_class_ftrs.dme_class_ftr = 1 and dme_class_ftrs.number_of_private_purchases > 1 and fr.is_ftp_key = 1  THEN 'dme_class_strs'
          WHEN dme_class_ftrs.dme_class_ftr = 1 and fr.is_ftp_key = 1  THEN 'dme_class_ftrs'
          WHEN dme_coupon_ftrs.dme_coupon_ftr = 'dme_coupon_ftr' AND dme_all_ftrs.dme_geo_ftr = 1 AND fr.is_ftp_key = 1 THEN 'dme_coupon_ftrs'
          WHEN dme_coupon_ftrs.dme_coupon_ftr = 'dme_coupon_reactivation'  THEN 'dme_coupon_reactivation'
          WHEN dme_coupon_ftrs.dme_coupon_ftr = 'dme_coupon_less_90'  THEN 'dme_coupon_less_90'
          WHEN not(dme_coupon_ftrs.dme_coupon_ftr is null) AND dme_all_ftrs.dme_geo_ftr is null AND fr.is_ftp_key = 1 THEN 'no_dme_coupon_ftrs'
          WHEN dme_all_ftrs.dme_geo_ftr = 1 and fr.is_ftp_key = 1 THEN 'organic_dme'
          ELSE 'moscow_ftr' END as type
    ,count(DISTINCT fr.riding_user_gk) as ftrs
  from dbo.dwh_fact_rides_v fr
    left join dme_all_ftrs on dme_all_ftrs.ride_gk = fr.ride_gk
    left join dme_coupon_ftrs on dme_coupon_ftrs.ride_gk = fr.ride_gk
    left join dme_class_ftrs on dme_class_ftrs.ride_gk = fr.ride_gk
    join dbo.periods_v p on p.date_key = fr.date_key
  where fr.date_key >= '2018-01-01' AND (fr.Ride_type_Key = 1 OR fr.Class_Type_Key = 2000282)
         and fr.country_key = 2 and p.timecategory not in ('1.Hours', '7.Std Hours')and p.hour_key = 0
group by 1,2,3
order by 1,2,3)


SELECT
  *
FROM data d
where d.type != 'moscow_ftr'








WITH

   dme_all_ftrs as (
    SELECT
      fr.ride_gk
      ,1 as dme_geo_ftr
    FROM dbo.dwh_fact_rides_v fr
    WHERE fr.Date_Key >= '2017-01-01'
      and fr.Is_FTP_Key = 1
      and fr.origin_latitude >= 55.383401
      and fr.origin_latitude <= 55.435248
      and fr.origin_longitude >= 37.855796
      and fr.origin_longitude <= 37.952613)

    ,dme_coupon_ftrs as (select
        d.first_ride_gk as ride_gk
        ,CASE WHEN d.last_purchase_date IS NULL THEN 'dme_coupon_ftr'
              WHEN datediff('day', d.last_purchase_date, d.activated_date_key) > 90 then 'dme_coupon_reactivation'
              ELSE 'dme_coupon_less_90' END as dme_coupon_ftr
      from (SELECT
        c.user_gk as riding_user_gk
        ,c.activated_date_key
        ,max(fr1.date_key) as last_purchase_date
        ,min(fr2.date_key) as first_purchase_date
        ,min(fr2.ride_gk) as first_ride_gk
      FROM dbo.dwh_dim_coupons_v c
        LEFT JOIN dwh_fact_rides_v fr1 ON fr1.riding_user_gk = c.user_gk and datediff('day', fr1.date_key, c.activated_date_key) > 0
        LEFT JOIN dwh_fact_rides_v fr2 ON fr2.riding_user_gk = c.user_gk and datediff('day', fr2.date_key, c.activated_date_key) <= 0
      WHERE c.coupon_text = 'B_A_BB_M_16042017' OR c.external_id LIKE 'dmd%'
      GROUP BY 1,2
      HAVING not(min(fr2.date_key) is null)) d)

  ,dme_class_ftrs as (
  SELECT
    fr.ride_gk
    ,1 as dme_class_ftr
    ,du.number_of_private_purchases
  FROM dbo.dwh_fact_rides_v fr
    inner join dwh_dim_users_v du ON du.user_gk = fr.riding_user_gk
  WHERE fr.is_ftp_key = 1
    AND fr.class_type_key = 2000282
    AND fr.date_key >= '2017-01-01'),

  data as (SELECT
     CASE WHEN dme_class_ftrs.dme_class_ftr = 1 and dme_class_ftrs.number_of_private_purchases > 1 and fr.is_ftp_key = 1  THEN 'dme_class_strs'
          WHEN dme_class_ftrs.dme_class_ftr = 1 and fr.is_ftp_key = 1  THEN 'dme_class_ftrs'
          WHEN dme_coupon_ftrs.dme_coupon_ftr = 'dme_coupon_ftr' AND dme_all_ftrs.dme_geo_ftr = 1 AND fr.is_ftp_key = 1 THEN 'dme_coupon_ftrs'
          WHEN dme_coupon_ftrs.dme_coupon_ftr = 'dme_coupon_reactivation'  THEN 'dme_coupon_reactivation'
          WHEN dme_coupon_ftrs.dme_coupon_ftr = 'dme_coupon_less_90'  THEN 'dme_coupon_less_90'
          WHEN not(dme_coupon_ftrs.dme_coupon_ftr is null) AND dme_all_ftrs.dme_geo_ftr is null AND fr.is_ftp_key = 1 THEN 'no_dme_coupon_ftrs'
          WHEN dme_all_ftrs.dme_geo_ftr = 1 and fr.is_ftp_key = 1 THEN 'organic_dme'
          ELSE 'moscow_ftr' END as type
     ,fr.ride_gk
  from dbo.dwh_fact_rides_v fr
    left join dme_all_ftrs on dme_all_ftrs.ride_gk = fr.ride_gk
    left join dme_coupon_ftrs on dme_coupon_ftrs.ride_gk = fr.ride_gk
    left join dme_class_ftrs on dme_class_ftrs.ride_gk = fr.ride_gk

  where fr.date_key >= '2017-04-01' AND (fr.Ride_type_Key = 1 OR fr.Class_Type_Key = 2000282)
         and fr.country_key = 2),


 users as (SELECT
  TRUNC(DATE_TRUNC('mon', fo.date_key)) as date
  ,d.type
  ,count(DISTINCT fo.riding_user_gk) as users
  ,count(*) as rides_90
  ,sum(fo2.driver_total_commission_inc_vat * -1.0 / 1.18 +
                      CASE WHEN fo2.customer_total_cost_inc_vat > fo2.driver_total_cost_inc_vat
                          THEN
                            (fo2.customer_total_cost_inc_vat - fo2.driver_total_cost_inc_vat) / 1.18
                       ELSE
                          (fo2.customer_total_cost_inc_vat - fo2.driver_total_cost_inc_vat) / 1.00 END) as total_gp_90
FROM data d
  inner join dwh_fact_orders_v fo on fo.order_gk = d.ride_gk
  inner join dwh_fact_orders_v fo2 ON fo2.riding_user_gk = fo.riding_user_gk and DATEDIFF('day', fo.date_key, fo2.date_key) between 0 and 90
where d.type != 'moscow_ftr'
        and fo2.ride_type_key = 1
        and fo2.order_status_key = 7
group by 1,2)


select
  *
from users u
order by 1



















select

from dwh_fact_orders_v fo
  inner join dwh_dim_class_types_v ct on ct.class_type_key = fo.class_type_key
where fo.m_ride_duration = 1
      and ct.category_key = 0
      and fo.order_status_key = 7
      and ct.class_type_group_desc in ('Economy', 'Standard', 'VIP', 'Premium', 'Premium+')
      and fo.date_key between '2018-02-01' and '2018-02-28'
      and fo.country_key = 2


select
  TRUNC(DATE_TRUNC('mon', fo.date_key))
  ,du.username
  ,count(*) as rides
from dwh_fact_orders_v fo
  inner join dwh_dim_users_v du on du.user_gk = fo.riding_user_gk
where fo.order_status_key = 7 and fo.class_type_key = 2000192 and fo.date_key between '2018-01-01' and '2018-02-28'
group by 1,2





with users as (SELECT
  dc.user_gk
  ,min(dc.activated_date_key) as activated_date_key
FROM dwh_dim_coupons_v dc
where dc.is_ftr_key = 0
      and dc.activated_date_key > '2017-08-01'
      and dc.total_redeemed_amount > dc.coupon_initial_amount*0.9
      and dc.num_of_usages > 1
      and dc.country_key = 2
group by 1)

select
  u.user_gk
from users u
inner join dwh_fact_orders_v fo on fo.riding_user_gk = u.user_gk and fo.date_key >= u.activated_date_key
  where fo.ride_type_key = 1 and fo.order_status_key = 7
group by 1
having sum(fo.driver_total_commission_inc_vat * -1.0 / 1.18 +
                  CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
                      THEN
                        (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
                   ELSE
                      (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END) > 0

select
  fo.riding_user_gk
from dwh_fact_orders_v fo
inner join dwh_dim_class_types_v dct On dct.class_type_key = fo.class_type_key
where fo.date_key > current_date-31 and dct.class_type_group_desc like 'Kids' and fo.origin_location_key = 245
group by 1
HAVING sum(CASE WHEN fo.date_key > current_date-8 THEN 1 ELSE 0 END) = 0


grant SELECT on analysis.mav_rides_predictions to microanalyst

select
  *
from analysis.mav_rides_predictions as rp
where rp.period in ('2018-04', '2018-05')

select
  fo.riding_user_gk
from dwh_fact_orders_v fo
where fo.riding_user_gk = 20002059183








-- Task 1
SELECT
  du.user_gk,
  du.loyalty_status_desc,
  du.username,
  du.first_name
FROM dwh_dim_users_v as du
WHERE du.username = '7925333865'
               OR du.email = 'avmorozov.hse@yandex.ru'



SELECT
  du.user_gk
  ,du.loyalty_status_desc
  ,du.country_key
FROM dbo.dwh_dim_users_v as du
WHERE du.username = '79253338465'
      OR du.email = 'avmorozov.hse@yandex.ru'
      AND du.country_key = 2


select
  du.user_gk
from dwh_dim_users_v du


SELECT
  DATE_TRUNC('mon', fo.date_key) as Date
  ,count(*) as num_rides
  ,avg(fo.customer_total_cost_inc_vat) as avg_bill
  ,min(fo.customer_total_cost_inc_vat) as min_bill
  ,max(fo.customer_total_cost_inc_vat) as max_bill
FROM dbo.dwh_fact_orders_v fo
WHERE fo.riding_user_gk = 20002059183
      AND fo.date_key BETWEEN '2018-01-01' AND '2018-02-28'
      AND fo.ride_type_key = 1
      AND fo.order_status_key = 7
GROUP BY DATE_TRUNC('mon', fo.date_key)
ORDER BY count(*)


-- Task 2
SELECT
  DATE_TRUNC('mon', fo.date_key) as date,
  count(*) as num_rides,
  min(fo.customer_total_cost_inc_vat) as min_bill,
  max(fo.customer_total_cost_inc_vat) as max_bill,
  avg(fo.customer_total_cost_inc_vat) as avg_bill
FROM dwh_fact_orders_v as fo
WHERE fo.riding_user_gk = 20002059183
               AND fo.date_key > '2018-01-01'
               AND fo.ride_type_key = 1
               AND fo.order_status_key = 7
GROUP BY DATE_TRUNC('mon', fo.date_key)
ORDER BY count(*)

select
  fo.ride_type_key
  ,fo.hour_key
  ,count(*) as num_rides
from dbo.dwh_fact_orders_v fo
where fo.riding_user_gk = 20002059183
      and fo.date_key BETWEEN '2018-01-01' AND '2018-02-28'
      AND fo.ride_type_key = 1
      AND fo.order_status_key = 7
      AND fo.hour_key BETWEEN 7 AND 12
GROUP BY fo.ride_type_key, fo.hour_key
ORDER BY num_rides


-- Task 3
SELECT
  fo.hour_key,
  count(*) as num_rides
FROM dwh_fact_orders_v as fo
WHERE fo.riding_user_gk = 20002059183
    AND fo.date_key BETWEEN '2018-01-01' AND '2018-02-28'
    AND fo.ride_type_key = 1
    AND fo.order_status_key = 7
    AND fo.hour_key BETWEEN 7 AND 12
GROUP BY fo.hour_key
ORDER BY num_rides


-- Task 4
SELECT
  COUNT(DISTINCT fo.dest_full_address) as num_addresses
FROM dwh_fact_orders_v as fo
WHERE fo.riding_user_gk = 20002059183
    AND fo.date_key BETWEEN '2018-01-01' AND '2018-02-28'
    AND fo.ride_type_key = 1
    AND fo.order_status_key = 7



select
  date_part('dow', fo.date_key) as date
  ,count(*)
from dwh_fact_orders_v fo
where fo.date_key > '2018-03-11' and date_part('dow', fo.date_key) in (6,0) and fo.country_key = 2
group by 1



select
  fo.riding_user_gk
from dwh_fact_orders_v fo
  where fo.ride_type_key = 1
        and fo.order_status_key = 7
        and fo.country_key = 2
        and fo.date_key between current_date - 29 and current_date
        and fo.origin_location_key = 245
group by 1
HAVING sum(fo.driver_total_commission_inc_vat * -1.0 / 1.18 +
                  CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
                      THEN
                        (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
                   ELSE
                      (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END) > 0
       AND sum(CASE WHEN date_part('dow', fo.date_key) in (6,0) THEN 1 ELSE 0 END) = 0
       AND count(*) > 3





SELECT
  date_trunc('month', cu.consumption_date_key)::DATE Month_Year
 ,CASE WHEN lower(c.coupon_container_name) like lower('RU_B2C_NonFTR_31082017') OR
        lower(c.coupon_container_name) like lower('RU_B2C_NonFTR_12102017') OR
        lower(c.coupon_container_name) like lower('RU_B2C_NonFTR_31102017') OR
        lower(c.coupon_container_name) like lower('RU_B2C_NonFTR_07022018') OR
        lower(c.coupon_container_name) like lower('RU_B2C_NonFTR_28022018_SbSp')
THEN 'Sberbank'

 WHEN lower(c.coupon_container_name) LIKE lower('ru_b2c_nonftr_reg%') OR
 lower(c.coupon_container_name) LIKE lower('ru_b2c_ftr_reg%') OR
 lower(c.Coupon_Text) LIKE lower('c_a_reg%') OR
 lower(c.coupon_text) LIKE lower('c_r_reg%') OR
 lower(c.coupon_container_name) LIKE lower('c_a_reg%') OR
 lower(c.coupon_container_name) LIKE lower('c_r_reg%') OR
 lower(c.external_id) LIKE lower('ru:regions%') OR
 lower(c.coupon_container_name) LIKE lower('ru_ftr_sta%') OR
 lower(c.coupon_container_name) LIKE lower('ru_regions%') OR
 lower(c.coupon_container_name) LIKE lower('kashira%') OR
 lower(c.coupon_container_name) LIKE lower('magnitogorsk_ftr%')
 THEN 'REGIONS'

 WHEN c.coupon_container_name = 'CocaCola Code Coupon Campaign 2016' OR
 c.Coupon_Text = '?????? ???????????????? ?????????? ?????????????????? 1000 ?????????????? ???? ???????? ?????????????????? 10 ?????????????? ?? Gett ?????? ?????????????????? ?????????????? ???????? 200 ??????.' OR
 c.Coupon_Text = '?????? ???????????????? ?????????? ?????????????????? 1000 ?????????????? ???? ???????? ?????????????????? 10 ?????????????? ?? Gett ?????? ?????????????????? ?????????????? ???????? 250 ??????.' OR
 c.Coupon_Text = '?????? ???????????????? ?????????? ?????????????????? 500 ?????????????? ???? ???????? ?????????????????? 10 ?????????????? ?? Gett ?????? ?????????????????? ?????????????? ???????? 100 ??????.' OR
 lower(c.coupon_container_name) LIKE lower('????????????????_????????????%') OR
 lower(c.coupon_container_name) like lower('%северное_сияние%') OR
 lower(c.coupon_container_name) like lower('%siyanie%')
 THEN 'Siyanie'

 WHEN lower(c.Coupon_Text) LIKE lower('c_r_cc%') OR
 lower(c.coupon_container_name) LIKE lower('c_r_cc%') OR
 lower(c.coupon_container_name) LIKE lower('ru_cc%') OR
 lower(c.coupon_container_name) LIKE lower('couponcc%') OR
 lower(c.coupon_container_name) LIKE lower('coupon%cc%') OR
 lower(c.coupon_container_name) LIKE lower('cc%backup%') OR
 lower(c.coupon_container_name) LIKE lower('customercare%') OR
 lower(c.coupon_container_name) LIKE lower('cc%coupons%') OR
 lower(c.Coupon_Text) LIKE lower('cc%coupons%') OR
 lower(c.Coupon_Text) LIKE lower('couponcc%') OR
 lower(c.Coupon_Text) LIKE lower('coupon%cc%') OR
 lower(c.Coupon_Text) LIKE lower('cc%backup%') OR
 lower(c.Coupon_Text) LIKE lower('customercare%')
 THEN 'CC'

 WHEN lower(c.Coupon_Text) LIKE lower('%b_a_bb%') OR
 lower(c.Coupon_Text) LIKE lower('%b_r_bb%') OR
 lower(c.coupon_container_name) LIKE lower('%b_a_bb%') OR
 lower(c.coupon_container_name) LIKE lower('%b_а_bb_%') OR
 lower(c.coupon_container_name) LIKE lower('%b_r_bb%') OR
 lower(c.coupon_container_name) LIKE lower('%ru_b2b%') OR
 lower(c.Coupon_Text) LIKE lower('%??????????????%') OR
 lower(c.Coupon_Text) LIKE lower('%??????????????%') OR
 lower(c.Coupon_Text) LIKE lower('%??????????????%') OR
 lower(c.Coupon_Text) LIKE lower('%b_r_b%') OR
 lower(c.coupon_container_name) LIKE lower('%b_r_b%') OR
 lower(c.coupon_container_name) LIKE lower('%dmdvip%') OR
 lower(c.coupon_container_name) LIKE lower('%dontforgett750%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4bulgari%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4dior%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4evraz%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4goody%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4hend%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4mhen%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4pm%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4tupper%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4vw%') OR
 lower(c.coupon_container_name) LIKE lower('%gettf24%') OR
 lower(c.coupon_container_name) LIKE lower('%gettit%') OR
 lower(c.coupon_container_name) LIKE lower('%gettkiosk%')
 THEN 'B2B'

 WHEN lower(c.Coupon_Text) LIKE lower('c_a_bv%') OR
 lower(c.Coupon_Text) LIKE lower('c_r_bv%') OR
 lower(c.coupon_container_name) LIKE lower('c_a_bv%') OR
 lower(c.coupon_container_name) LIKE lower('c_r_bv%') OR
 lower(c.external_id) LIKE lower('ru:bv%') OR
 lower(c.coupon_container_name) LIKE lower('ru_bvip%') OR
 lower(c.coupon_container_name) LIKE lower('%bv%')
 THEN 'Business&VIP'

 WHEN lower(c.Coupon_Text) LIKE lower('d_a_sup%') OR
 lower(c.Coupon_Text) LIKE lower('d_r_sup%') OR
 lower(c.coupon_container_name) LIKE lower('ru_b2d%') OR
 lower(c.coupon_text) LIKE lower('q_s%') OR
 lower(c.Coupon_Text) LIKE lower('d_r_bv%') OR
 lower(c.coupon_container_name) LIKE lower('d_a_sup%') OR
 lower(c.coupon_container_name) LIKE lower('d_r_sup%') OR
 lower(c.coupon_container_name) LIKE lower('q_s%') OR
 lower(c.coupon_container_name) LIKE lower('d_r_bv%') OR
 lower(c.coupon_container_name) LIKE lower('%total%quality%')
 THEN 'Supply'

 WHEN lower(c.Coupon_Text) LIKE lower('c_a_v%') OR
 lower(c.Coupon_Text) LIKE lower('c_r_v%') OR
 lower(c.coupon_container_name) LIKE lower('c_a_v%') OR
 lower(c.coupon_container_name) LIKE lower('c_r_v%') OR
 lower(c.external_id) LIKE lower('ru:verticals%') OR
 lower(c.external_id) LIKE lower('ru_delivery_ftr%') OR
 lower(c.external_id) LIKE lower('ru_delivery_nonftr%') OR
 lower(c.coupon_container_name) LIKE lower('ru_courier%') OR
 lower(c.coupon_container_name) LIKE lower('ru_delivery%') OR
 lower(c.coupon_container_name) LIKE lower('ru_gett_courier%') OR
 lower(c.coupon_container_name) LIKE lower('%delivery%')
 THEN 'VERTICALS'

 WHEN lower(c.Coupon_Text) LIKE lower('ru_crm%') OR
 lower(c.coupon_container_name) LIKE lower('ru_crm%') OR
 lower(c.external_id) like lower('ru:%:%:%')
 THEN 'MAR_CRM'

 WHEN lower(c.Coupon_Text) LIKE lower('c_a_mar%') OR
 lower(c.Coupon_Text) LIKE lower('ru_b2c_ftr%') OR
 lower(c.coupon_container_name) LIKE lower('c_a_mar%') OR
 lower(c.coupon_container_name) LIKE lower('ru_b2c_ftr%') OR
 lower(c.coupon_container_name) LIKE lower('%getttele2%') OR
 lower(c.coupon_container_name) LIKE lower('%spb300%') OR
 lower(c.coupon_container_name) LIKE lower('%takearide%') OR
 lower(c.coupon_container_name) LIKE lower('%gettvarlamov%') OR
 lower(c.coupon_container_name) LIKE lower('%gift-ru%') OR
 lower(c.coupon_container_name) LIKE lower('%gift-us%') OR
 lower(c.coupon_container_name) LIKE lower('%gt300%') OR
 lower(c.coupon_container_name) LIKE lower('%love%') OR
 lower(c.coupon_container_name) LIKE lower('%first300%') OR
 lower(c.coupon_container_name) LIKE lower('%first500%') OR
 lower(c.coupon_container_name) LIKE lower('%dave_ru_10000_unique_codes_campaign%') OR
 lower(c.coupon_container_name) LIKE lower('%rnd%') OR
 lower(c.coupon_container_name) LIKE lower('ride') OR
 lower(c.coupon_container_name) LIKE lower('%rno_weekly%') OR
 lower(c.Coupon_Text) LIKE lower('spb300%') OR
 lower(c.Coupon_Text) LIKE lower('takearide%') OR
 lower(c.Coupon_Text) LIKE lower('gettvarlamov%') OR
 lower(c.Coupon_Text) LIKE lower('gift-ru%') OR
 lower(c.Coupon_Text) LIKE lower('gift-us%') OR
 lower(c.Coupon_Text) LIKE lower('gt300%') OR
 lower(c.Coupon_Text) LIKE lower('love%') OR
 lower(c.Coupon_Text) LIKE lower('first300%') OR
 lower(c.Coupon_Text) LIKE lower('first500%') OR
 lower(c.Coupon_Text) LIKE lower('dave_ru_10000_unique_codes_campaign%') OR
 lower(c.Coupon_Text) LIKE lower('rnd%') OR
 lower(c.Coupon_Text) LIKE lower('ride%') OR
 lower(c.Coupon_Text) LIKE lower('rno_weekly%')
 THEN 'MAR_AC'

 WHEN lower(c.Coupon_Text) LIKE lower('c_r_mar%') OR
 lower(c.coupon_container_name) LIKE lower('c_r_mar%') OR
 lower(c.external_id) LIKE lower('ru:marketing%') OR
 lower(c.Coupon_Text) LIKE lower('ru_b2c_nonftr%') OR
 lower(c.coupon_container_name) LIKE lower('ru_b2c_nonftr%') OR
 lower(c.coupon_container_name) LIKE lower('ru_b2c_nftr%')
 THEN 'MAR_R'

 WHEN lower(c.Coupon_Text) LIKE lower('ru_digital%') OR
 lower(c.coupon_container_name) LIKE lower('ru_digital')
 THEN 'MAR_DIGITAL'

 WHEN lower(c.coupon_type) LIKE lower('if_invitee') OR
 lower(c.coupon_type) LIKE lower('if_inviter') OR
 lower(c.coupon_text) LIKE lower('%moved prepaid balance%') OR
 lower(c.coupon_text) LIKE lower('%???????????? ?????????? ?????????????? ?????????????? ??????????????%')
 THEN 'IF'

 WHEN
   lower(c.Coupon_container_name) LIKE '%employee%' OR
   lower(c.Coupon_container_name) LIKE '%empoloyee_coupon%' OR
   lower(c.Coupon_text) LIKE '%employee%'
 THEN 'EMPLOYEE'

 WHEN
 lower(c.coupon_container_name) LIKE lower('%ru_dmd_nonftr%') OR
 lower(c.coupon_container_name) LIKE lower('%ru_dmd_ftr%') OR
 lower(c.coupon_container_name) LIKE lower('%dmd%') OR
 lower(c.coupon_container_name) LIKE lower('%ru_dme%')
 THEN 'DMD'


 WHEN
   lower(c.coupon_container_name) like lower('%sta%') OR
   lower(c.coupon_type) like lower('ShareTheApp') OR
   lower(c.coupon_type) like lower('ShareTheApp/PayWithGett')
 THEN 'STA'

 WHEN
   lower(c.coupon_container_name) like 'unknown'
 THEN 'unknown'

 ELSE
  'others_strange_names'
  END as Target

 ,SUM(cu.Amount_Redeemed_From_Coupon)  Coupon_Spent
 FROM dbo.Dwh_Dim_Coupons_V c
 JOIN dbo.Dwh_Fact_Coupon_Usages_V cu ON c.Coupon_GK = cu.Coupon_GK
 WHERE c.country_key = 2
 AND cu.consumption_date >= '2017-01-01'
 GROUP BY 1,2




select
  DISTINCT dc.coupon_type
from dwh_dim_coupons_v dc

select
  du.user_gk
  ,du.username
  ,du.first_name
  ,du.acquisition_advertising_id
from dwh_dim_users_v du
where du.user_gk = 2000886280


  upper(du.acquisition_advertising_id) in ('E6BB04B4-36A4-444A-8EE7-4C3719EE7C03'
,'DD316966-49EA-4945-BE3E-66FFE7D06ABF'
,'F476196D-F572-47A1-B544-2D6FAA754B72'
,'6F5BE306-44AA-44F9-9BD6-71F22BBDFFFA'
,'DE002585-83C9-4962-913A-4F082BC2AEE0'
,'1A7A1BE0-6963-4865-B7FE-644EAE74A07A'
,'35D684A7-96F8-47D3-A923-B4ED50122F34')



select
  DISTINCT crm.promotion_step_id
  ,l.city_name
  ,du.acquisition_advertising_id
  ,du.user_gk
  ,du.main_device_desc
  ,dc.promotion_name
from dwh_fact_crm_promotions_v crm
  inner join dwh_dim_users_v du ON du.user_gk = crm.user_gk
  inner join dwh_dim_locations_v l ON l.city_id = du.primary_city_id
  inner join dwh_dim_crm_promotions_v dc ON dc.variant_first_step_id = crm.promotion_step_id
where crm.promotion_step_id in ('359eb324-aa16-4b55-ae57-a96c0980bb77')


select
  crm.promotion_step_id
  ,l.city_name
  ,du.acquisition_advertising_id
  ,du.user_gk
  ,du.main_device_desc
from dwh_fact_crm_promotions_v crm
  inner join dwh_dim_users_v du ON du.user_gk = crm.user_gk
  inner join dwh_dim_locations_v l ON l.city_id = du.primary_city_id
where crm.promotion_step_id in ('359eb324-aa16-4b55-ae57-a96c0980bb77')



select
  count(*) as activations
  ,sum(CASE WHEN dc.num_of_usages > 0 THEN 1 ELSE 0 END) as rides
from dwh_dim_coupons_v dc
where dc.external_id like '%link467%' and dc.activated_date_key between '2018-03-21' and '2018-03-21'



select

from dwh_dim_users_v du
  inner join dwh_dim_rankings_v dr ON du.value_loyalty_ranking_key = dr.ranking_key
  inner join dwh_fact_orders_v fo ON fo.riding_user_gk = du.user_gk
                                     and DATEDIFF('day', fo.date_key, current_date) <= 30



select
  l.city_name
  ,dr.ranking_desc
  ,CASE WHEN fo.ride_distance_key < 3 THEN 'ultra_short'
        WHEN fo.ride_distance_key < 5 THEN 'short'
        WHEN fo.ride_distance_key < 10 THEN 'middle'
        ELSE 'long' END as ride_group
  ,count(DISTINCT fo.riding_user_gk) as users
  ,count(*) as rides
  ,sum(fo.driver_total_commission_inc_vat * -1.0 / 1.18 +
                  CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
                      THEN
                        (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
                   ELSE
                      (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END) as margin
from dwh_fact_orders_v fo
  inner join dwh_dim_users_v du ON du.user_gk = fo.riding_user_gk
  inner join dwh_dim_rankings_v dr ON du.value_loyalty_ranking_key = dr.ranking_key
  inner join dwh_dim_locations_v l ON l.city_id = du.primary_city_id
where fo.date_key between current_date - 31 and current_date
        and fo.ride_type_key = 1
        and fo.order_status_key = 7
        and du.country_key = 2
group by 1,2,3





select
  l.city_name
  ,dr.ranking_desc
  ,CASE WHEN fo.ride_distance_key < 3 THEN 'ultra_short'
        WHEN fo.ride_distance_key < 5 THEN 'short'
        WHEN fo.ride_distance_key < 10 THEN 'middle'
        ELSE 'long' END as ride_group
  ,count(DISTINCT fo.riding_user_gk) as users
  ,count(*) as rides
  ,sum(fo.driver_total_commission_inc_vat * -1.0 / 1.18 +
                  CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
                      THEN
                        (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
                   ELSE
                      (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END) as margin
from dwh_fact_orders_v fo
  inner join dwh_dim_users_v du ON du.user_gk = fo.riding_user_gk
  inner join dwh_dim_rankings_v dr ON du.value_loyalty_ranking_key = dr.ranking_key
  inner join dwh_dim_locations_v l ON l.city_id = du.primary_city_id
where fo.date_key between current_date - 31 and current_date
        and fo.ride_type_key = 1
        and fo.order_status_key = 7
        and du.country_key = 2
        and l.city_name = 'Moscow Region - General'
group by 1,2,3




with users as (SELECT
  dc.user_gk
  ,dc.coupon_container_name
  ,dc.coupon_gk
  ,dc.total_redeemed_amount
  ,dc.coupon_type
  ,dc.country_key
  ,dc.created_date_key
  ,CASE WHEN dc.num_of_usages >= dc.max_usages or dc.remaining_amount = 0 THEN dc.last_consumed_datetime
     WHEN dc.expiration_date < CURRENT_DATE THEN dc.expiration_date
     ELSE dc.expiration_date END as end_datetime
  ,CASE WHEN dc.num_of_usages >= dc.max_usages or dc.remaining_amount = 0 THEN dc.last_consumed_date_key
       WHEN dc.expiration_date < CURRENT_DATE THEN dc.expiration_date
       ELSE dc.expiration_date END as end_date
  ,dc.first_consumed_datetime as start_datetime
FROM dwh_dim_coupons_v dc
 WHERE  dc.total_redeemed_amount > 0.0 and dc.country_key = 2 and dc.is_ftr_key=0 and dc.created_date_key >= '2017-01-01'),


  campaigns as (SELECT
    dc.coupon_container_name
    ,count(DISTINCT dc.coupon_gk) as activations
    ,trunc(date_trunc('mon', min(dc.created_date_key))) as created_date_key
   FROM dwh_dim_coupons_v dc
     WHERE  dc.total_redeemed_amount > 0.0 and dc.country_key = 2 and dc.is_ftr_key=0 and dc.created_date_key >= '2017-01-01'
    GROUP BY 1),

  coupon_usages as (
  SELECT
      cu.order_gk
      ,cu.amount_redeemed_from_coupon
      ,cu.coupon_gk
      ,fo.is_ftp_key
      ,CASE WHEN dc.max_usages = 0 THEN dc.coupon_initial_amount
            ELSE dc.coupon_initial_amount/dc.max_usages END as max_amount_per_usage
  FROM dwh_dim_coupons_v dc
    inner join dwh_fact_coupon_usages_v cu on cu.coupon_gk = dc.coupon_gk
    inner join dwh_fact_orders_v fo on fo.order_gk = cu.order_gk
  WHERE dc.total_redeemed_amount > 0.0 and dc.country_key = 2 and dc.is_ftr_key=0 and dc.created_date_key >= '2017-01-01'),


  rides as (SELECT

    ca.coupon_container_name
    ,ca.activations as total_activations
    ,ca.created_date_key as created_date_key
    ,CASE WHEN dateadd(m, +30, fo.ride_start_datetime) < u.start_datetime THEN 'before'
         WHEN DATEDIFF('day', u.end_datetime, fo.ride_start_datetime) <= 30 THEN 'after_30'
         WHEN DATEDIFF('day', u.end_datetime, fo.ride_start_datetime) BETWEEN 31 AND 60 THEN 'after_60'
         ELSE 'after_60>' END as period
    ,u.user_gk
    ,fo.order_gk
    ,cu.amount_redeemed_from_coupon
    ,fo.origin_location_key
    ,cu.coupon_gk
    ,fo.date_key
    ,fo.hour_key
    ,u.coupon_type
    ,cu.is_ftp_key
    ,fo.customer_total_cost_inc_vat
    ,fo.paid_with_prepaid
    ,cu.max_amount_per_usage - cu.amount_redeemed_from_coupon as remain_from_coupon
    ,CASE WHEN fo.paid_with_prepaid is null THEN 0
      ELSE fo.paid_with_prepaid/fo.customer_total_cost_inc_vat END as share_paid_with_prepaid
    ,fo.driver_total_commission_inc_vat* -1.0 / 1.18 +
                      CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
                          THEN
                            (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
                       ELSE
                          (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END  as gp
  from campaigns ca
    inner join users u on u.coupon_container_name = ca.coupon_container_name
    inner join dwh_fact_orders_v fo ON fo.riding_user_gk = u.user_gk
                                       and DATEDIFF('day', u.start_datetime, fo.date_key) BETWEEN -30 AND 60 + DATEDIFF('day', u.start_datetime, u.end_datetime)
    inner join dwh_fact_rides_v fr ON fr.order_gk = fo.order_gk
    left join coupon_usages cu ON cu.order_gk = fo.order_gk and cu.coupon_gk = u.coupon_gk

  where fo.Country_Symbol = 'RU'
              AND not(fo.Ride_Type_Key = 2)
              AND fo.order_status_key = 7
              AND fo.customer_total_cost_inc_vat > 0
              AND fo.date_key > '2017-01-01' and fo.date_key < CURRENT_DATE-1)



select
    r.coupon_container_name
    ,r.created_date_key as Month
    ,r.total_activations
    ,CASE WHEN r.origin_location_key = 245 THEN 'Moscow'
        WHEN r.origin_location_key = 246 THEN 'SPB'
        ELSE 'Regions' END AS location
    ,count(DISTINCT CASE WHEN not(r.amount_redeemed_from_coupon is null) THEN r.coupon_gk ELSE 0 END) as coupon_activation
    ,sum(CASE WHEN r.period = 'before' THEN 1 ELSE 0 END) as before_rides_30
    ,sum(CASE WHEN r.period = 'after_30' THEN 1 ELSE 0 END) as after_ride_30
    ,sum(CASE WHEN r.period = 'after_30' AND r.share_paid_with_prepaid < 0.30 THEN 1 ELSE 0 END) as after_ride_30_without_prepaid
    ,sum(CASE WHEN r.period = 'after_60' THEN 1 ELSE 0 END) as after_ride_31_60
    ,ceiling(sum(r.remain_from_coupon)) as remain_from_coupon
    ,sum(r.amount_redeemed_from_coupon) as coupon_spent_promo
    ,sum(CASE WHEN not(r.amount_redeemed_from_coupon is null) THEN 1 ELSE 0 END) as coupon_rides_promo
    ,sum(r.amount_redeemed_from_coupon) as coupon_spent_promo
    ,sum(CASE WHEN r.period = 'before' THEN r.customer_total_cost_inc_vat ELSE 0 END) as before_revenue_30
    ,sum(CASE WHEN r.period = 'after_30' THEN r.customer_total_cost_inc_vat ELSE 0 END) as after_revenue_30
    ,sum(CASE WHEN r.period = 'before' THEN r.gp ELSE 0 END) as before_gp_30
    ,sum(CASE WHEN r.period = 'after_30' THEN r.gp ELSE 0 END) as after_gp_30
    ,sum(CASE WHEN r.is_ftp_key = 1 THEN 1 ELSE 0 END) as ftrs
from rides as r
  where r.coupon_type in ('general', 'other', 'marketing', 'unknown')

  GROUP BY 1,2,3, 4
  HAVING r.total_activations > 30
  order by 1






with users as (select
  l.city_name
  ,fo.riding_user_gk
from dwh_fact_orders_v fo
  inner join dwh_dim_class_types_v dct on dct.class_type_key = fo.class_type_key
  inner join dwh_dim_users_v du On du.user_gk = fo.riding_user_gk
  inner join dwh_dim_locations_v l ON l.city_id = du.primary_city_id
where fo.date_key > current_date - 31
      and fo.order_status_key = 7
      and fo.ride_type_key = 1
      and fo.country_key = 2
      and l.location_key in (245, 246, 374, 354, 300, 294, 343)
group by 1, 2
HAVING sum(CASE WHEN dct.class_type_group_desc in ('Economy', 'Standard') THEN 1 ELSE 0 END) > 5
       and sum(CASE WHEN dct.class_type_group_desc in ('Standard') THEN 1 ELSE 0 END) > 1)

select
  u.city_name
  ,u.riding_user_gk
from users u
  LEFT join dwh_fact_orders_v fo on fo.riding_user_gk = u.riding_user_gk
  LEFT join dwh_dim_class_types_v dct on dct.class_type_key = fo.class_type_key
group by 1,2
HAVING sum(CASE WHEN dct.class_type_group_key in (4, 5, 17) THEN 1 ELSE 0 END) = 0


select
  l.city_name
  ,fo.riding_user_gk
from dwh_fact_orders_v fo
  inner join dwh_dim_class_types_v dct on dct.class_type_key = fo.class_type_key
  inner join dwh_dim_users_v du On du.user_gk = fo.riding_user_gk
  inner join dwh_dim_locations_v l ON l.city_id = du.primary_city_id
where fo.date_key > '2016-01-01'
      and fo.order_status_key = 7
      and fo.ride_type_key = 1
      and fo.country_key = 2
      and dct.class_type_group_key in (4,5,17)
      and l.location_key in (245, 246, 374, 354, 300, 294, 343)
group by 1, 2
having max(fo.date_key) < current_date - 91


select
  DISTINCT fo.riding_user_gk
from dwh_fact_orders_v fo
  inner join dwh_dim_class_types_v dct on dct.class_type_key = fo.class_type_key
  inner join dwh_dim_users_v du On du.user_gk = fo.riding_user_gk
  inner join dwh_dim_locations_v l ON l.city_id = du.primary_city_id
where fo.date_key > current_date - 91
      and fo.order_status_key = 7
      and fo.ride_type_key = 1
      and fo.country_key = 2
      and fo.origin_location_key in (245, 246)
group by 1
having sum(CASE WHEN dct.class_type_group_key = 3 THEN 1 ELSE 0 END) > 3
          and sum(CASE WHEN dct.class_type_group_key = 1 and datediff('day', fo.date_key, current_date) < 31 THEN 1 ELSE 0 END) = 0





-- class_upgrade_analysis

with users as (select
  fo.riding_user_gk
  ,fo.order_gk
  ,fo.date_key as class_upgrade_date
  ,dct.class_type_group_desc
from dwh_fact_orders_v fo
  inner join dwh_dim_users_v du ON du.user_gk = fo.riding_user_gk
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
where fo.order_gk in (2000133265092) and fo.order_status_key = 7 and fo.ride_type_key = 1)



select
  CASE WHEN datediff('days', fo.date_key, u.class_upgrade_date) < 0 THEN 'before' ELSE 'after' END as period
  ,count(*) as rides
  ,sum(CASE WHEN dct.class_type_group_desc in (4,5,17) THEN 1 ELSE 0 END) as bv_rides
  ,avg(fo.customer_total_cost_inc_vat) as bill
from users u
  inner join dwh_fact_orders_v fo ON fo.riding_user_gk = u.riding_user_gk
                                     and datediff('days', fo.date_key, u.class_upgrade_date) between -91 and 91
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
  inner join dwh_dim_users_v du ON du.user_gk = fo.riding_user_gk
where fo.ride_type_key = 1 and fo.order_status_key = 7 and datediff('days', du.ftpp_date_key, u.class_upgrade_date) > 91
group by 1



with users as (select
  fo.riding_user_gk
  ,fo.order_gk
  ,fo.date_key as class_upgrade_date
  ,dct.class_type_group_desc
from dwh_fact_orders_v fo
  inner join dwh_dim_users_v du ON du.user_gk = fo.riding_user_gk
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
where fo.order_gk in {order_unique} and fo.order_status_key = 7 and fo.ride_type_key = 1)


select
  CASE WHEN datediff('days', fo.date_key, u.class_upgrade_date) >= 0 THEN 'before' ELSE 'after' END as period
  ,TRUNC(DATE_TRUNC('mon', u.class_upgrade_date)) as month
  ,count(*) as rides
  ,avg(fo.ride_distance_key) as ride_distance_key
  ,count(DISTINCT fo.riding_user_gk) as users
  ,sum(CASE WHEN dct.class_type_group_key in (4,5,17) THEN 1 ELSE 0 END) as bv_rides
  ,avg(fo.customer_total_cost_inc_vat) as bill
from users u
  inner join dwh_fact_orders_v fo ON fo.riding_user_gk = u.riding_user_gk
                                     and datediff('days', fo.date_key, u.class_upgrade_date) between -91 and 91
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
  inner join dwh_dim_users_v du ON du.user_gk = fo.riding_user_gk
where fo.ride_type_key = 1 and fo.order_status_key = 7 and datediff('days', du.ftpp_date_key, u.class_upgrade_date) > 91
group by 1,2



select
  l.city_name
  ,dr.ranking_desc
  ,CASE WHEN fo.ride_distance_key < 3 THEN 'ultra_short'
        WHEN fo.ride_distance_key < 5 THEN 'short'
        WHEN fo.ride_distance_key < 10 THEN 'middle'
        ELSE 'long' END as ride_group
  ,count(DISTINCT fo.riding_user_gk) as users
  ,count(*) as rides
  ,sum(fo.driver_total_commission_inc_vat * -1.0 / 1.18 +
                  CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
                      THEN
                        (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
                   ELSE
                      (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END) as margin
  ,1.0 * sum(fo.driver_total_commission_inc_vat * -1.0 / 1.18 +
                  CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
                      THEN
                        (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
                   ELSE
                      (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END)/count(DISTINCT fo.riding_user_gk) as AMPU
  ,count(*) / count(DISTINCT fo.riding_user_gk) as ridership
from dwh_fact_orders_v fo
  inner join dwh_dim_users_v du ON du.user_gk = fo.riding_user_gk
  inner join dwh_dim_rankings_v dr ON du.value_loyalty_ranking_key = dr.ranking_key
  inner join dwh_dim_locations_v l ON l.city_id = du.primary_city_id
where fo.date_key between current_date - 31 and current_date
        and fo.ride_type_key = 1
        and fo.order_status_key = 7
        and du.country_key = 2
group by 1,2,3




select
  rp.timecategory as timecategory
  ,rp.period as period
  ,rp.domain as domain
  ,rp.type as type
  ,rp.rides as rides_1
  ,rp.users as users_1
  ,rp.rides_user as rides_user_1
from analysis.mav_rides_predictions as rp
where rp.period in ('2018-04', '2018-05')


grant SELECT on analysis.mav_rides_predictions to microanalyst

select
  du.value_loyalty_ranking_key
from dwh_dim_users_v du




with users as (select
  fo.riding_user_gk
  ,fo.order_gk
  ,fo.date_key as class_upgrade_date
  ,dct.class_type_group_desc
from dwh_fact_orders_v fo
  inner join dwh_dim_users_v du ON du.user_gk = fo.riding_user_gk
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
where fo.order_gk in {order_unique} and fo.order_status_key = 7 and fo.ride_type_key = 1)


select
  fo.country_key
  ,rk.ranking_key
  ,CASE WHEN datediff('days', fo.date_key, u.class_upgrade_date) >= 0 THEN 'before' ELSE 'after' END as period
  ,TRUNC(DATE_TRUNC('mon', u.class_upgrade_date)) as month
  ,count(*) as rides
  ,avg(fo.ride_distance_key) as ride_distance_key
  ,count(DISTINCT fo.riding_user_gk) as users
  ,sum(CASE WHEN dct.class_type_group_key in (4,5,17) THEN 1 ELSE 0 END) as bv_rides
  ,avg(fo.customer_total_cost_inc_vat) as bill
from users u
  inner join dwh_fact_orders_v fo ON fo.riding_user_gk = u.riding_user_gk
                                     and datediff('days', fo.date_key, u.class_upgrade_date) between -91 and 90
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
  inner join dwh_dim_users_v du ON du.user_gk = fo.riding_user_gk
  inner join dwh_fact_users_monthly_v fum on fum.user_gk = u.riding_user_gk and fum.month_id = TRUNC(DATE_TRUNC('mon', u.class_upgrade_date))
  inner join dwh_dim_rankings_v rk ON rk.ranking_key = fum.ranking_key
where fo.ride_type_key = 1 and fo.order_status_key = 7 and datediff('days', du.ftpp_date_key, u.class_upgrade_date) > 91
group by 1,2,3,4

union

select
  'control' as test_group
  ,fo.country_key
  ,rk.ranking_desc
  ,CASE WHEN datediff('days', fo.date_key, u.class_upgrade_date) >= 0 THEN 'before' ELSE 'after' END as period
  ,TRUNC(DATE_TRUNC('mon', fo.class_upgrade_date)) as month
  ,count(*) as rides
  ,avg(fo.ride_distance_key) as ride_distance_key
  ,count(DISTINCT fo.riding_user_gk) as users
  ,sum(CASE WHEN dct.class_type_group_key in (4,5,17) THEN 1 ELSE 0 END) as bv_rides
  ,avg(fo.customer_total_cost_inc_vat) as bill
from dwh_fact_orders_v fo
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
  inner join dwh_dim_users_v du ON du.user_gk = fo.riding_user_gk
  inner join dwh_fact_users_monthly_v fum on fum.user_gk = fo.riding_user_gk and fum.month_id = TRUNC(DATE_TRUNC('mon', fo.date_key))
  inner join dwh_dim_rankings_v rk ON rk.ranking_key = fum.ranking_key
where fo.ride_type_key = 1
    and fo.order_status_key = 7
    and not(fo.riding_user_gk in (select riding_user_gk from users))
    and fo.date_key between '2017-07-01' and '2017-12-31'
group by 1,2,3,4







-- Сколько поездок вы сделали за новогодние праздники?
SELECT
  count(*) as num_rides
FROM dwh_fact_orders_v fo
WHERE fo.order_status_key = 7
      and fo.ride_type_key = 1
      and fo.date_key between '2018-01-01' and '2018-01-09'
      and fo.riding_user_gk = 20002059183


-- Кол-во пользователей с каждым статусом лояльности
SELECT
  du.loyalty_status_desc
  ,count(*) as users
FROM dwh_dim_users_v du
WHERE du.country_key = 2 and du.number_of_private_purchases_last_30_days > 1
group by du.loyalty_status_desc


-- Посчитайте среднюю длительность поездки в Москве
select
   trunc(date_trunc('mon', fo.date_key))
   ,avg(fo.ride_distance_key) as distance
from dwh_fact_orders_v fo
where fo.order_status_key = 7
      and fo.ride_type_key = 1
      and fo.origin_location_key = 245
      and fo.date_key >= '2018-01-01'
group by trunc(date_trunc('mon', fo.date_key))




-- Выведите список самых популярных своих адресов назначения
SELECT
  fo.dest_full_address
  ,count(*) as num_rides
FROM dwh_fact_orders_v fo
WHERE fo.order_status_key = 7
      and fo.ride_type_key = 1
      and fo.date_key between '2018-01-01' and '2018-03-09'
      and fo.riding_user_gk = 20002059183
group by 1
order by count(*) DESC





with users as (select
  fo.riding_user_gk as user_gk
  ,ss.s2o
from dwh_fact_orders_v fo
  inner join dwh_dim_users_v du ON du.user_gk = fo.riding_user_gk
  inner join dwh_dim_class_types_v dct On dct.class_type_key = fo.class_type_key
  left join (select
              ss.user_gk
              ,1.0 * sum(CASE WHEN ss.final_order_gk != -1 THEN 1 ELSE 0 END)/count(*) as s2o
            from dwh_fact_unique_sessions_v ss
            where ss.user_gk
                  and ss.first_event_date_key > current_date - 91
            group by 1
            having count(*)) as ss ON ss.user_gk = fo.riding_user_gk
where fo.origin_location_key = 245
      and fo.ride_type_key = 1
      and fo.order_status_key = 7
      and fo.date_key > current_date - 91
      and du.value_loyalty_ranking_key in (1,2)
      and ss.s2o < 0.7
group by 1,2
having sum(fo.driver_total_commission_inc_vat * -1.0 / 1.18 +
          CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
              THEN
                (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
           ELSE
              (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END) > -100
      and count(CASE WHEN fo.hour_key in (6,7,8,9,17,18,19) THEN 1 ELSE null END) > 2
      and count(CASE WHEN not(fo.hour_key in (6,7,8,9,17,18,19)) THEN 1 ELSE null END) > 2
      and sum(CASE WHEN dct.class_type_group_desc = 'Economy' THEN 1 ELSE 0 END) between 10 and 50)


select
  *
from users u

select
  count(*) * 50.0
from users u
  inner join dwh_fact_orders_v fo ON fo.riding_user_gk = u.user_gk
  inner join dwh_dim_class_types_v dct On dct.class_type_key = fo.class_type_key
where fo.date_key > current_date - 31
      and fo.ride_type_key = 1
      and fo.order_status_key = 7
      and fo.origin_location_key = 245
      and ((fo.customer_total_cost_inc_vat >= 250
           and fo.hour_key in (6,7,8,9)
           and date_part('dow', fo.date_key) between 1 and 5
           and dct.class_type_group_desc = 'Economy') OR (fo.customer_total_cost_inc_vat > 150
                                       and fo.hour_key in (22,23,24,1,2,3)
                                       and date_part('dow', fo.date_key) between 1 and 5
                                       and dct.class_type_group_desc = 'Economy'))





with users as (SELECT
  dc.user_gk
  ,dc.coupon_container_name
  ,dc.coupon_gk
  ,dc.total_redeemed_amount
  ,dc.coupon_type
  ,dc.country_key
  ,dc.created_date_key
  ,CASE WHEN dc.num_of_usages >= dc.max_usages or dc.remaining_amount = 0 THEN dc.last_consumed_datetime
     WHEN dc.expiration_date < CURRENT_DATE THEN dc.expiration_date
     ELSE dc.expiration_date END as end_datetime
  ,CASE WHEN dc.num_of_usages >= dc.max_usages or dc.remaining_amount = 0 THEN dc.last_consumed_date_key
       WHEN dc.expiration_date < CURRENT_DATE THEN dc.expiration_date
       ELSE dc.expiration_date END as end_date
  ,dc.first_consumed_datetime as start_datetime
FROM dwh_dim_coupons_v dc
 WHERE  dc.total_redeemed_amount > 0.0 and dc.country_key = 2 and dc.is_ftr_key=0 and dc.created_date_key >= '2017-01-01'),


  campaigns as (SELECT
    dc.coupon_container_name
    ,count(DISTINCT dc.coupon_gk) as activations
    ,trunc(date_trunc('mon', min(dc.created_date_key))) as created_date_key
   FROM dwh_dim_coupons_v dc
     WHERE  dc.total_redeemed_amount > 0.0 and dc.country_key = 2 and dc.is_ftr_key=0 and dc.created_date_key >= '2017-01-01'
    GROUP BY 1),

  coupon_usages as (
  SELECT
      cu.order_gk
      ,cu.amount_redeemed_from_coupon
      ,cu.coupon_gk
      ,fo.is_ftp_key
      ,CASE WHEN dc.max_usages = 0 THEN dc.coupon_initial_amount
            ELSE dc.coupon_initial_amount/dc.max_usages END as max_amount_per_usage
  FROM dwh_dim_coupons_v dc
    inner join dwh_fact_coupon_usages_v cu on cu.coupon_gk = dc.coupon_gk
    inner join dwh_fact_orders_v fo on fo.order_gk = cu.order_gk
  WHERE dc.total_redeemed_amount > 0.0 and dc.country_key = 2 and dc.is_ftr_key=0 and dc.created_date_key >= '2017-01-01'),


  rides as (SELECT

    ca.coupon_container_name
    ,ca.activations as total_activations
    ,ca.created_date_key as created_date_key
    ,CASE WHEN dateadd(m, +30, fo.ride_start_datetime) < u.start_datetime THEN 'before'
         WHEN DATEDIFF('day', u.end_datetime, fo.ride_start_datetime) <= 30 THEN 'after_30'
         WHEN DATEDIFF('day', u.end_datetime, fo.ride_start_datetime) BETWEEN 31 AND 60 THEN 'after_60'
         ELSE 'after_60>' END as period
    ,u.user_gk
    ,fo.order_gk
    ,cu.amount_redeemed_from_coupon
    ,fo.origin_location_key
    ,cu.coupon_gk
    ,fo.date_key
    ,fo.hour_key
    ,u.coupon_type
    ,cu.is_ftp_key
    ,fo.customer_total_cost_inc_vat
    ,fo.paid_with_prepaid
    ,cu.max_amount_per_usage - cu.amount_redeemed_from_coupon as remain_from_coupon
    ,CASE WHEN fo.paid_with_prepaid is null THEN 0
      ELSE fo.paid_with_prepaid/fo.customer_total_cost_inc_vat END as share_paid_with_prepaid
    ,fo.driver_total_commission_inc_vat* -1.0 / 1.18 +
                      CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
                          THEN
                            (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
                       ELSE
                          (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END  as gp
  from campaigns ca
    inner join users u on u.coupon_container_name = ca.coupon_container_name
    inner join dwh_fact_orders_v fo ON fo.riding_user_gk = u.user_gk
                                       and DATEDIFF('day', u.start_datetime, fo.date_key) BETWEEN -30 AND 60 + DATEDIFF('day', u.start_datetime, u.end_datetime)
    inner join dwh_fact_rides_v fr ON fr.ride_gk = fo.order_gk
    left join coupon_usages cu ON cu.order_gk = fo.order_gk and cu.coupon_gk = u.coupon_gk

  where fo.Country_Symbol = 'RU'
              AND not(fo.Ride_Type_Key = 2)
              AND fo.order_status_key = 7
              AND fo.customer_total_cost_inc_vat > 0
              AND fo.date_key > '2017-01-01' and fo.date_key < CURRENT_DATE-1)



select
    r.coupon_container_name
    ,r.created_date_key as Month
    ,r.total_activations
    ,CASE WHEN r.origin_location_key = 245 THEN 'Moscow'
        WHEN r.origin_location_key = 246 THEN 'SPB'
        ELSE 'Regions' END AS location
    ,count(DISTINCT CASE WHEN not(r.amount_redeemed_from_coupon is null) THEN r.coupon_gk ELSE 0 END) as coupon_activation
    ,sum(CASE WHEN r.period = 'before' THEN 1 ELSE 0 END) as before_rides_30
    ,sum(CASE WHEN r.period = 'after_30' THEN 1 ELSE 0 END) as after_ride_30
    ,sum(CASE WHEN r.period = 'after_30' AND r.share_paid_with_prepaid < 0.30 THEN 1 ELSE 0 END) as after_ride_30_without_prepaid
    ,sum(CASE WHEN r.period = 'after_60' THEN 1 ELSE 0 END) as after_ride_31_60
    ,ceiling(sum(r.remain_from_coupon)) as remain_from_coupon
    ,sum(r.amount_redeemed_from_coupon) as coupon_spent_promo
    ,sum(CASE WHEN not(r.amount_redeemed_from_coupon is null) THEN 1 ELSE 0 END) as coupon_rides_promo
    ,sum(r.amount_redeemed_from_coupon) as coupon_spent_promo
    ,sum(CASE WHEN r.period = 'before' THEN r.customer_total_cost_inc_vat ELSE 0 END) as before_revenue_30
    ,sum(CASE WHEN r.period = 'after_30' THEN r.customer_total_cost_inc_vat ELSE 0 END) as after_revenue_30
    ,sum(CASE WHEN r.period = 'before' THEN r.gp ELSE 0 END) as before_gp_30
    ,sum(CASE WHEN r.period = 'after_30' THEN r.gp ELSE 0 END) as after_gp_30
    ,sum(CASE WHEN r.is_ftp_key = 1 THEN 1 ELSE 0 END) as ftrs
from rides as r
  where r.coupon_type in ('general', 'other', 'marketing', 'unknown')

  GROUP BY 1,2,3, 4
  HAVING r.total_activations > 30
  order by 1









SELECT
  date_trunc('month', cu.consumption_date_key)::DATE Month_Year
 ,CASE WHEN lower(c.coupon_container_name) like 'unknown' THEN 'unknown'
      ELSE 'others_strange_names' END as Target
 ,c.coupon_container_name
 ,c.coupon_text
 ,SUM(cu.Amount_Redeemed_From_Coupon) Coupon_Spent

 FROM dbo.Dwh_Dim_Coupons_V c
 JOIN dbo.Dwh_Fact_Coupon_Usages_V cu ON c.Coupon_GK = cu.Coupon_GK
 WHERE c.country_key = 2
       AND cu.consumption_date >= '2018-01-01'
       and not (lower(c.coupon_container_name) LIKE lower('ru_b2c_nonftr_reg%') OR
 lower(c.coupon_container_name) LIKE lower('ru_b2c_ftr_reg%') OR
 lower(c.Coupon_Text) LIKE lower('c_a_reg%') OR
 lower(c.coupon_text) LIKE lower('c_r_reg%') OR
 lower(c.coupon_container_name) LIKE lower('c_a_reg%') OR
 lower(c.coupon_container_name) LIKE lower('c_r_reg%') OR
 lower(c.external_id) LIKE lower('ru:regions%') OR
 lower(c.coupon_container_name) LIKE lower('ru_ftr_sta%') OR
 lower(c.coupon_container_name) LIKE lower('ru_regions%') OR
 lower(c.coupon_container_name) LIKE lower('kashira%') OR
 lower(c.coupon_container_name) LIKE lower('magnitogorsk_ftr%') OR
 c.coupon_container_name = 'CocaCola Code Coupon Campaign 2016' OR
 c.Coupon_Text = '?????? ???????????????? ?????????? ?????????????????? 1000 ?????????????? ???? ???????? ?????????????????? 10 ?????????????? ?? Gett ?????? ?????????????????? ?????????????? ???????? 200 ??????.' OR
 c.Coupon_Text = '?????? ???????????????? ?????????? ?????????????????? 1000 ?????????????? ???? ???????? ?????????????????? 10 ?????????????? ?? Gett ?????? ?????????????????? ?????????????? ???????? 250 ??????.' OR
 c.Coupon_Text = '?????? ???????????????? ?????????? ?????????????????? 500 ?????????????? ???? ???????? ?????????????????? 10 ?????????????? ?? Gett ?????? ?????????????????? ?????????????? ???????? 100 ??????.' OR
 lower(c.coupon_container_name) LIKE lower('????????????????_????????????%') OR
 lower(c.coupon_container_name) like lower('%северное_сияние%') OR
 lower(c.coupon_container_name) like lower('%siyanie%') OR
 lower(c.Coupon_Text) LIKE lower('c_r_cc%') OR
 lower(c.coupon_container_name) LIKE lower('c_r_cc%') OR
 lower(c.coupon_container_name) LIKE lower('ru_cc%') OR
 lower(c.coupon_container_name) LIKE lower('couponcc%') OR
 lower(c.coupon_container_name) LIKE lower('coupon%cc%') OR
 lower(c.coupon_container_name) LIKE lower('cc%backup%') OR
 lower(c.coupon_container_name) LIKE lower('customercare%') OR
 lower(c.coupon_container_name) LIKE lower('cc%coupons%') OR
 lower(c.Coupon_Text) LIKE lower('cc%coupons%') OR
 lower(c.Coupon_Text) LIKE lower('couponcc%') OR
 lower(c.Coupon_Text) LIKE lower('coupon%cc%') OR
 lower(c.Coupon_Text) LIKE lower('cc%backup%') OR
 lower(c.Coupon_Text) LIKE lower('customercare%') OR
 lower(c.Coupon_Text) LIKE lower('%b_a_bb%') OR
 lower(c.Coupon_Text) LIKE lower('%b_r_bb%') OR
 lower(c.coupon_container_name) LIKE lower('%b_a_bb%') OR
 lower(c.coupon_container_name) LIKE lower('%b_а_bb_%') OR
 lower(c.coupon_container_name) LIKE lower('%b_r_bb%') OR
 lower(c.coupon_container_name) LIKE lower('%ru_b2b%') OR
 lower(c.Coupon_Text) LIKE lower('%??????????????%') OR
 lower(c.Coupon_Text) LIKE lower('%??????????????%') OR
 lower(c.Coupon_Text) LIKE lower('%??????????????%') OR
 lower(c.Coupon_Text) LIKE lower('%b_r_b%') OR
 lower(c.coupon_container_name) LIKE lower('%b_r_b%') OR
 lower(c.coupon_container_name) LIKE lower('%dmdvip%') OR
 lower(c.coupon_container_name) LIKE lower('%dontforgett750%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4bulgari%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4dior%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4evraz%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4goody%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4hend%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4mhen%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4pm%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4tupper%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4vw%') OR
 lower(c.coupon_container_name) LIKE lower('%gettf24%') OR
 lower(c.coupon_container_name) LIKE lower('%gettit%') OR
 lower(c.coupon_container_name) LIKE lower('%gettkiosk%') OR
 lower(c.Coupon_Text) LIKE lower('c_a_bv%') OR
 lower(c.Coupon_Text) LIKE lower('c_r_bv%') OR
 lower(c.coupon_container_name) LIKE lower('c_a_bv%') OR
 lower(c.coupon_container_name) LIKE lower('c_r_bv%') OR
 lower(c.external_id) LIKE lower('ru:bv%') OR
 lower(c.coupon_container_name) LIKE lower('ru_bvip%') OR
 lower(c.coupon_container_name) LIKE lower('%bv%') OR
 lower(c.Coupon_Text) LIKE lower('ru_crm%') OR
 lower(c.coupon_container_name) LIKE lower('ru_crm%') OR
 lower(c.coupon_text) = lower('?????? ?? ?????????????? 1000 ?????????????? ?? ?????????? ?????????????????? ?????????? ???????????? ?????????????? ?? Gett!') OR
 lower(c.coupon_text) = lower('?????? ?? ?????????????? 1000 ?????????????? ???? ?????????????? ?? ?????????????? ????????????????????!') OR
 lower(c.coupon_text) = lower('?????? ?? ?????????????? 1500 ?????????????? ???? ?????????????? ?? ?????????????? ????????????????????!') OR
 lower(c.external_id) like lower('ru:%:%:%') OR
 lower(c.Coupon_Text) LIKE lower('c_a_mar%') OR
 lower(c.Coupon_Text) LIKE lower('ru_b2c_ftr%') OR
 lower(c.coupon_container_name) LIKE lower('c_a_mar%') OR
 lower(c.coupon_container_name) LIKE lower('ru_b2c_ftr%') OR
 lower(c.coupon_container_name) LIKE lower('%getttele2%') OR
 lower(c.coupon_container_name) LIKE lower('%spb300%') OR
 lower(c.coupon_container_name) LIKE lower('%takearide%') OR
 lower(c.coupon_container_name) LIKE lower('%gettvarlamov%') OR
 lower(c.coupon_container_name) LIKE lower('%gift-ru%') OR
 lower(c.coupon_container_name) LIKE lower('%gift-us%') OR
 lower(c.coupon_container_name) LIKE lower('%gt300%') OR
 lower(c.coupon_container_name) LIKE lower('%love%') OR
 lower(c.coupon_container_name) LIKE lower('%first300%') OR
 lower(c.coupon_container_name) LIKE lower('%first500%') OR
 lower(c.coupon_container_name) LIKE lower('%dave_ru_10000_unique_codes_campaign%') OR
 lower(c.coupon_container_name) LIKE lower('%rnd%') OR
 lower(c.coupon_container_name) LIKE lower('ride') OR
 lower(c.coupon_container_name) LIKE lower('%rno_weekly%') OR
 lower(c.Coupon_Text) LIKE lower('spb300%') OR
 lower(c.Coupon_Text) LIKE lower('takearide%') OR
 lower(c.Coupon_Text) LIKE lower('gettvarlamov%') OR
 lower(c.Coupon_Text) LIKE lower('gift-ru%') OR
 lower(c.Coupon_Text) LIKE lower('gift-us%') OR
 lower(c.Coupon_Text) LIKE lower('gt300%') OR
 lower(c.Coupon_Text) LIKE lower('love%') OR
 lower(c.Coupon_Text) LIKE lower('first300%') OR
 lower(c.Coupon_Text) LIKE lower('first500%') OR
 lower(c.Coupon_Text) LIKE lower('dave_ru_10000_unique_codes_campaign%') OR
 lower(c.Coupon_Text) LIKE lower('rnd%') OR
 lower(c.Coupon_Text) LIKE lower('ride%') OR
 lower(c.Coupon_Text) LIKE lower('rno_weekly%') OR
 lower(c.Coupon_Text) LIKE lower('c_r_mar%') OR
 lower(c.coupon_container_name) LIKE lower('c_r_mar%') OR
 lower(c.external_id) LIKE lower('ru:marketing%') OR
 lower(c.Coupon_Text) LIKE lower('ru_b2c_nonftr%') OR
 lower(c.coupon_container_name) LIKE lower('ru_b2c_nonftr%') OR
 lower(c.coupon_container_name) LIKE lower('ru_b2c_nftr%') OR
 lower(c.Coupon_Text) LIKE lower('ru_digital%') OR
 lower(c.coupon_container_name) LIKE lower('ru_digital') OR
 lower(c.Coupon_Text) LIKE lower('d_a_sup%') OR
 lower(c.Coupon_Text) LIKE lower('d_r_sup%') OR
 lower(c.coupon_container_name) LIKE lower('ru_b2d%') OR
 lower(c.coupon_text) LIKE lower('q_s%') OR
 lower(c.Coupon_Text) LIKE lower('d_r_bv%') OR
 lower(c.coupon_container_name) LIKE lower('d_a_sup%') OR
 lower(c.coupon_container_name) LIKE lower('d_r_sup%') OR
 lower(c.coupon_container_name) LIKE lower('q_s%') OR
 lower(c.coupon_container_name) LIKE lower('d_r_bv%') OR
 lower(c.coupon_container_name) LIKE lower('%total%quality%') OR
 lower(c.Coupon_Text) LIKE lower('c_a_v%') OR
 lower(c.Coupon_Text) LIKE lower('c_r_v%') OR
 lower(c.coupon_container_name) LIKE lower('c_a_v%') OR
 lower(c.coupon_container_name) LIKE lower('c_r_v%') OR
 lower(c.external_id) LIKE lower('ru:verticals%') OR
 lower(c.external_id) LIKE lower('ru_delivery_ftr%') OR
 lower(c.external_id) LIKE lower('ru_delivery_nonftr%') OR
 lower(c.coupon_container_name) LIKE lower('ru_courier%') OR
 lower(c.coupon_container_name) LIKE lower('ru_delivery%') OR
 lower(c.coupon_container_name) LIKE lower('ru_gett_courier%') OR
 lower(c.coupon_container_name) LIKE lower('%delivery%') OR
 lower(c.coupon_type) LIKE lower('if_invitee') OR
 lower(c.coupon_type) LIKE lower('if_inviter') OR
 lower(c.coupon_text) LIKE lower('%moved prepaid balance%') OR
 lower(c.coupon_text) LIKE lower('%???????????? ?????????? ?????????????? ?????????????? ??????????????%') OR
 lower(c.Coupon_container_name) LIKE '%employee%' OR
 lower(c.Coupon_container_name) LIKE '%empoloyee_coupon%' OR
 lower(c.Coupon_text) LIKE '%employee%' OR
 lower(c.coupon_container_name) LIKE lower('%ru_dmd_nonftr%') OR
 lower(c.coupon_container_name) LIKE lower('%ru_dmd_ftr%') OR
 lower(c.coupon_container_name) LIKE lower('%dmd%') OR
 lower(c.coupon_container_name) LIKE lower('%ru_dme%') OR
 lower(c.coupon_container_name) like lower('%sta%'))

 GROUP BY 1,2,3,4
 order by 1,2, 5



select
  l.city_name
  ,dr.ranking_desc
  ,CASE WHEN fo.ride_distance_key < 3 THEN 'ultra_short'
        WHEN fo.ride_distance_key < 5 THEN 'short'
        WHEN fo.ride_distance_key < 10 THEN 'middle'
        ELSE 'long' END as ride_group
  ,count(DISTINCT fo.riding_user_gk) as users
  ,count(*) as rides
  ,sum(fo.driver_total_commission_inc_vat * -1.0 / 1.18 +
                  CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
                      THEN
                        (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
                   ELSE
                      (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END) as margin
  ,1.0 * sum(fo.driver_total_commission_inc_vat * -1.0 / 1.18 +
                  CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
                      THEN
                        (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
                   ELSE
                      (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END)/count(DISTINCT fo.riding_user_gk) as AMPU
  ,1.0 * sum(fo.driver_total_commission_inc_vat * -1.0 / 1.18 +
                  CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
                      THEN
                        (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
                   ELSE
                      (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END)/count(fo.riding_user_gk) as AMPR
  ,1.0 * count(*) / count(DISTINCT fo.riding_user_gk) as ridership
from dwh_fact_orders_v fo
  inner join dwh_dim_users_v du ON du.user_gk = fo.riding_user_gk
  inner join dwh_dim_rankings_v dr ON du.value_loyalty_ranking_key = dr.ranking_key
  inner join dwh_dim_locations_v l ON l.city_id = du.primary_city_id
where fo.date_key between current_date - 31 and current_date
        and fo.ride_type_key = 1
        and fo.order_status_key = 7
        and du.country_key = 2
group by 1,2,3



select
  sum(CASE WHEN fo.customer_total_cost_inc_vat < fo.driver_total_cost_inc_vat
    THEN fo.driver_total_cost_inc_vat - fo.customer_total_cost_inc_vat END)*(1/1.18-1) / count(*) as add_margin_per_ride
from dwh_fact_orders_v fo
where fo.origin_location_key = 245
      and fo.order_status_key = 7
      and fo.country_key = 2
      and fo.date_key > '2018-01-01'
      and fo.customer_total_cost_inc_vat is not null
      and fo.driver_total_cost_inc_vat is not null




select
  sum(CASE WHEN fo.customer_total_cost_inc_vat < fo.driver_total_cost_inc_vat
    THEN fo.driver_total_cost_inc_vat - fo.customer_total_cost_inc_vat END)*(1/1.18-1) / count(*) as add_margin_per_ride
   ,sum(fo.driver_total_commission_inc_vat* -1.0 / 1.18 +
                  CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
                      THEN
                        (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
                   ELSE
                      (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END)/count(*) as old_gp
   ,sum(CASE WHEN fo.customer_total_cost_inc_vat > (fo.driver_total_cost_inc_vat - fo.driver_total_commission_inc_vat*-1.0)
                      THEN
                        (fo.customer_total_cost_inc_vat - (fo.driver_total_cost_inc_vat - fo.driver_total_commission_inc_vat*-1.0)) / 1.18
                     ELSE
                        (fo.customer_total_cost_inc_vat - (fo.driver_total_cost_inc_vat - fo.driver_total_commission_inc_vat*-1.0)) / 1.00 END) / count(*)as new_gp
from dwh_fact_orders_v fo
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
where fo.origin_location_key = 245
      and fo.order_status_key = 7
      and fo.country_key = 2
      and dct.class_type_group_desc in ('Economy', 'Standard')
      and fo.date_key > '2018-01-01'
      and fo.customer_total_cost_inc_vat is not null
      and fo.driver_total_cost_inc_vat is not null



select
  -1*avg(fo.driver_total_commission_inc_vat) as  avg_commission
  ,avg(fo.customer_total_cost_inc_vat) as avg_check
  ,avg(fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) as bill_difference
  ,avg(fo.driver_total_cost_inc_vat) as driver_total_cost_inc_vat
from dwh_fact_orders_v fo
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
where fo.origin_location_key = 245
      and fo.order_status_key = 7
      and fo.country_key = 2
      and fo.date_key > '2018-01-01'
      and dct.class_type_group_desc in ('Standard')
      and fo.customer_total_cost_inc_vat is not null
      and fo.driver_total_cost_inc_vat is not null



with users as (select
  fo.riding_user_gk
  ,sum(CASE WHEN fo.date_key < current_date - 91 THEN 1 ELSE 0 END) as rides_before
  ,sum(CASE WHEN fo.date_key > current_date - 91 THEN 1 ELSE 0 END) as rides_after
from dwh_fact_orders_v fo
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
where fo.order_status_key = 7
      and fo.ride_type_key = 1
      and dct.class_type_group_desc = 'XL'
      and fo.origin_location_key in (245,246)
group by 1)

select
  u.riding_user_gk
from users u
where u.rides_before > 1 and u.rides_after = 0


select
  dc.activated_date_key
  ,count(dc.external_id) as num
from dwh_dim_coupons_v dc
where (lower(dc.external_id) like 'dmd%' or lower(dc.coupon_container_name) like 'dmd%')
      and dc.activated_date_key between '2018-03-01' and '2018-03-22'
group by 1







with users as (select
  fo.riding_user_gk
  ,sum(CASE WHEN fo.date_key < current_date - 91 THEN 1 ELSE 0 END) as rides_before
  ,sum(CASE WHEN fo.date_key > current_date - 91 THEN 1 ELSE 0 END) as rides_after
from dwh_fact_orders_v fo
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
where fo.order_status_key = 7
      and fo.ride_type_key = 1
      and dct.class_type_group_desc = 'XL'
      and fo.origin_location_key in (245,246)
group by 1)

select
  u.riding_user_gk
from users u
where u.rides_before > 1 and u.rides_after = 0



with users as (select
  fo.riding_user_gk
from dwh_fact_orders_v fo
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
where fo.order_status_key = 7
      and fo.ride_type_key = 1
      and dct.class_type_group_desc in ('Economy', 'Standard')
      and fo.origin_location_key in (245,246)
      and fo.date_key > current_date - 31
group by 1
having count(*) between 1 and 4)

select
    u.riding_user_gk
from users u
  left join dwh_fact_orders_v fo ON fo.riding_user_gk = u.riding_user_gk
  left join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
where fo.order_status_key = 7
group by 1
having sum(CASE WHEN dct.class_type_group_desc = 'XL' THEN 1 ELSE 0 END) = 0



select
  -1*avg(fo.driver_total_commission_inc_vat) as  avg_commission
  ,avg(fo.customer_total_cost_inc_vat) as avg_check
  ,avg(fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) as bill_difference
  ,avg(fo.driver_total_cost_inc_vat) as driver_total_cost_inc_vat
from dwh_fact_orders_v fo
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
where fo.ride_type_key = 1
      and fo.order_status_key = 7
      and dct.class_type_group_desc = 'Economy'
      and fo.origin_location_key = 245
      and fo.date_key > '2018-03-01'



select
  dc.activated_date_key
  ,count(dc.external_id) as num
from dwh_dim_coupons_v dc
where (lower(dc.external_id) like 'dmd%' or lower(dc.coupon_container_name) like 'dmd%')
      and dc.activated_date_key = '2018-03-29'
group by 1


select
  fo.riding_user_gk
  ,min(fo.order_gk) as first_ride_bv_gk
  ,min(fo.date_key) as first_ride_date_key
from dwh_fact_orders_v fo
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
where fo.order_status_key = 7
      and fo.ride_type_key = 1
      and fo.country_key = 2
      and dct.class_type_desc_eng like '%visa%'
group by 1



select
  fo.riding_user_gk as user_gk
  ,sum(CASE WHEN fo.user_base_surge > fo.user_applied_surge THEN
            (fo.user_base_surge - fo.user_applied_surge) * fo.customer_base_price
            ELSE 0 END) as ru_discount_0318
from dbo.dwh_fact_orders_v fo
where fo.order_status_key = 7
      and fo.country_key = 2
      and fo.date_key between '2018-03-01' and '2018-03-31'
group by 1
having sum(CASE WHEN fo.user_base_surge > fo.user_applied_surge THEN
            (fo.user_base_surge - fo.user_applied_surge) * fo.customer_base_price
            ELSE 0 END) > 300




select
  fo.riding_user_gk
  ,sum(CASE WHEN fo.user_base_surge > fo.user_applied_surge THEN
            (fo.user_base_surge - fo.user_actual_surge) * fo.customer_base_price
            ELSE 0 END) as ru_discount_0318
from dwh_fact_orders_v fo
where fo.order_status_key = 7
      and fo.country_key = 2
      and fo.date_key between '2018-03-01' and '2018-03-31'
group by 1
having sum(CASE WHEN fo.user_base_surge > fo.user_applied_surge THEN
            (fo.user_base_surge - fo.user_applied_surge) * fo.customer_base_price
            ELSE 0 END) > 300



select
  CASE WHEN fo.date_key <= '2018-03-29' THEN 'before'
       ELSE 'after' END as period
  ,fo.customer_total_cost_inc_vat
from dwh_fact_orders_v fo
where fo.ride_type_key = 1 and fo.order_status_key = 7 and fo.date_key > '2018-03-28'







-- Ufa 90+
select
  fo.riding_user_gk
from dwh_fact_orders_v fo
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
where fo.origin_location_key = 355
  group by 1
having  sum(CASE WHEN fo.date_key > current_date-91 THEN 1 ELSE 0 END) > 3
        and 1.0 * sum(CASE WHEN fo.date_key > current_date-91 and dct.class_type_group_desc = 'Standard' THEN 1 ELSE 0 END)/1.0 * sum(CASE WHEN fo.date_key > current_date-91 THEN 1 ELSE 0 END) > 0.3
        and sum(CASE WHEN dct.class_type_key = 2000658 THEN 1 ELSE 0 END) = 0

select
  fo.riding_user_gk
from dwh_fact_orders_v fo
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
where fo.origin_location_key = 355
  group by 1
having  sum(CASE WHEN fo.date_key > current_date - 91 THEN 1 ELSE 0 END) > 5
        and  sum(CASE WHEN dct.class_type_key = 2000658 THEN 1 ELSE 0 END) = 0


select
  DISTINCT dc.is_ftr_key
from dbo.dwh_dim_coupons_v dc
where dc.country_key = 2



SELECT
  date_trunc('month', cu.consumption_date_key)::DATE Month_Year
 ,CASE WHEN c.coupon_type = 'appboy' THEN 'CRM'
     WHEN c.is_ftr_key = 1 THEN 'acquisition'
     WHEN c.is_ftr_key in (0, -1) THEN 'retention' END as coupon_type


 ,CASE WHEN lower(c.coupon_container_name) like lower('RU_B2C_NonFTR_31082017') OR
        lower(c.coupon_container_name) like lower('RU_B2C_NonFTR_12102017') OR
        lower(c.coupon_container_name) like lower('RU_B2C_NonFTR_31102017') OR
        lower(c.coupon_container_name) like lower('RU_B2C_NonFTR_07022018') OR
        lower(c.coupon_container_name) like lower('RU_B2C_NonFTR_28022018_SbSp')
  THEN 'Sberbank'

 WHEN lower(c.coupon_container_name) LIKE lower('ru_b2c_nonftr_reg%') OR
 lower(c.coupon_container_name) LIKE lower('ru_b2c_ftr_reg%') OR
 lower(c.Coupon_Text) LIKE lower('c_a_reg%') OR
 lower(c.coupon_text) LIKE lower('c_r_reg%') OR
 lower(c.coupon_container_name) LIKE lower('c_a_reg%') OR
 lower(c.coupon_container_name) LIKE lower('c_r_reg%') OR
 lower(c.external_id) LIKE lower('ru:regions%') OR
 lower(c.coupon_container_name) LIKE lower('ru_ftr_sta%') OR
 lower(c.coupon_container_name) LIKE lower('ru_regions%') OR
 lower(c.coupon_container_name) LIKE lower('kashira%') OR
 lower(c.coupon_container_name) LIKE lower('magnitogorsk_ftr%')
 THEN 'REGIONS'

 WHEN c.coupon_container_name = 'CocaCola Code Coupon Campaign 2016' OR
 c.Coupon_Text = '?????? ???????????????? ?????????? ?????????????????? 1000 ?????????????? ???? ???????? ?????????????????? 10 ?????????????? ?? Gett ?????? ?????????????????? ?????????????? ???????? 200 ??????.' OR
 c.Coupon_Text = '?????? ???????????????? ?????????? ?????????????????? 1000 ?????????????? ???? ???????? ?????????????????? 10 ?????????????? ?? Gett ?????? ?????????????????? ?????????????? ???????? 250 ??????.' OR
 c.Coupon_Text = '?????? ???????????????? ?????????? ?????????????????? 500 ?????????????? ???? ???????? ?????????????????? 10 ?????????????? ?? Gett ?????? ?????????????????? ?????????????? ???????? 100 ??????.' OR
 lower(c.coupon_container_name) LIKE lower('????????????????_????????????%') OR
 lower(c.coupon_container_name) like lower('%северное_сияние%') OR
 lower(c.coupon_container_name) like lower('%siyanie%')
 THEN 'Siyanie'

 WHEN lower(c.Coupon_Text) LIKE lower('c_r_cc%') OR
 lower(c.coupon_container_name) LIKE lower('c_r_cc%') OR
 lower(c.coupon_container_name) LIKE lower('ru_cc%') OR
 lower(c.coupon_container_name) LIKE lower('couponcc%') OR
 lower(c.coupon_container_name) LIKE lower('coupon%cc%') OR
 lower(c.coupon_container_name) LIKE lower('cc%backup%') OR
 lower(c.coupon_container_name) LIKE lower('customercare%') OR
 lower(c.coupon_container_name) LIKE lower('cc%coupons%') OR
 lower(c.Coupon_Text) LIKE lower('cc%coupons%') OR
 lower(c.Coupon_Text) LIKE lower('couponcc%') OR
 lower(c.Coupon_Text) LIKE lower('coupon%cc%') OR
 lower(c.Coupon_Text) LIKE lower('cc%backup%') OR
 lower(c.Coupon_Text) LIKE lower('customercare%')
 THEN 'CC'

 WHEN lower(c.Coupon_Text) LIKE lower('%b_a_bb%') OR
 lower(c.Coupon_Text) LIKE lower('%b_r_bb%') OR
 lower(c.coupon_container_name) LIKE lower('%b_a_bb%') OR
 lower(c.coupon_container_name) LIKE lower('%b_а_bb_%') OR
 lower(c.coupon_container_name) LIKE lower('%b_r_bb%') OR
 lower(c.coupon_container_name) LIKE lower('%ru_b2b%') OR
 lower(c.Coupon_Text) LIKE lower('%??????????????%') OR
 lower(c.Coupon_Text) LIKE lower('%??????????????%') OR
 lower(c.Coupon_Text) LIKE lower('%??????????????%') OR
 lower(c.Coupon_Text) LIKE lower('%b_r_b%') OR
 lower(c.coupon_container_name) LIKE lower('%b_r_b%') OR
 lower(c.coupon_container_name) LIKE lower('%dmdvip%') OR
 lower(c.coupon_container_name) LIKE lower('%dontforgett750%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4bulgari%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4dior%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4evraz%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4goody%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4hend%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4mhen%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4pm%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4tupper%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4vw%') OR
 lower(c.coupon_container_name) LIKE lower('%gettf24%') OR
 lower(c.coupon_container_name) LIKE lower('%gettit%') OR
 lower(c.coupon_container_name) LIKE lower('%gettkiosk%')
 THEN 'B2B'

 WHEN lower(c.Coupon_Text) LIKE lower('c_a_bv%') OR
 lower(c.Coupon_Text) LIKE lower('c_r_bv%') OR
 lower(c.coupon_container_name) LIKE lower('c_a_bv%') OR
 lower(c.coupon_container_name) LIKE lower('c_r_bv%') OR
 lower(c.external_id) LIKE lower('ru:bv%') OR
 lower(c.coupon_container_name) LIKE lower('ru_bvip%') OR
 lower(c.coupon_container_name) LIKE lower('%bv%')
 THEN 'Business&VIP'


 WHEN lower(c.Coupon_Text) LIKE lower('d_a_sup%') OR
 lower(c.Coupon_Text) LIKE lower('d_r_sup%') OR
 lower(c.coupon_container_name) LIKE lower('ru_b2d%') OR
 lower(c.coupon_text) LIKE lower('q_s%') OR
 lower(c.Coupon_Text) LIKE lower('d_r_bv%') OR
 lower(c.coupon_container_name) LIKE lower('d_a_sup%') OR
 lower(c.coupon_container_name) LIKE lower('d_r_sup%') OR
 lower(c.coupon_container_name) LIKE lower('q_s%') OR
 lower(c.coupon_container_name) LIKE lower('d_r_bv%') OR
 lower(c.coupon_container_name) LIKE lower('%total%quality%')
 THEN 'Supply'

 WHEN lower(c.Coupon_Text) LIKE lower('c_a_v%') OR
 lower(c.Coupon_Text) LIKE lower('c_r_v%') OR
 lower(c.coupon_container_name) LIKE lower('c_a_v%') OR
 lower(c.coupon_container_name) LIKE lower('c_r_v%') OR
 lower(c.external_id) LIKE lower('ru:verticals%') OR
 lower(c.external_id) LIKE lower('ru_delivery_ftr%') OR
 lower(c.external_id) LIKE lower('ru_delivery_nonftr%') OR
 lower(c.coupon_container_name) LIKE lower('ru_courier%') OR
 lower(c.coupon_container_name) LIKE lower('ru_delivery%') OR
 lower(c.coupon_container_name) LIKE lower('ru_gett_courier%') OR
 lower(c.coupon_container_name) LIKE lower('%delivery%')
 THEN 'VERTICALS'

 WHEN lower(c.Coupon_Text) LIKE lower('ru_crm%') OR
 lower(c.coupon_container_name) LIKE lower('ru_crm%') OR
 lower(c.coupon_text) = lower('?????? ?? ?????????????? 1000 ?????????????? ?? ?????????? ?????????????????? ?????????? ???????????? ?????????????? ?? Gett!') OR
 lower(c.coupon_text) = lower('?????? ?? ?????????????? 1000 ?????????????? ???? ?????????????? ?? ?????????????? ????????????????????!') OR
 lower(c.coupon_text) = lower('?????? ?? ?????????????? 1500 ?????????????? ???? ?????????????? ?? ?????????????? ????????????????????!') OR
 lower(c.external_id) like lower('ru:%:%:%') OR
 lower(c.Coupon_Text) LIKE lower('c_a_mar%') OR
 lower(c.Coupon_Text) LIKE lower('ru_b2c_ftr%') OR
 lower(c.coupon_container_name) LIKE lower('c_a_mar%') OR
 lower(c.coupon_container_name) LIKE lower('ru_b2c_ftr%') OR
 lower(c.coupon_container_name) LIKE lower('%getttele2%') OR
 lower(c.coupon_container_name) LIKE lower('%spb300%') OR
 lower(c.coupon_container_name) LIKE lower('%takearide%') OR
 lower(c.coupon_container_name) LIKE lower('%gettvarlamov%') OR
 lower(c.coupon_container_name) LIKE lower('%gift-ru%') OR
 lower(c.coupon_container_name) LIKE lower('%gift-us%') OR
 lower(c.coupon_container_name) LIKE lower('%gt300%') OR
 lower(c.coupon_container_name) LIKE lower('%love%') OR
 lower(c.coupon_container_name) LIKE lower('%first300%') OR
 lower(c.coupon_container_name) LIKE lower('%first500%') OR
 lower(c.coupon_container_name) LIKE lower('%dave_ru_10000_unique_codes_campaign%') OR
 lower(c.coupon_container_name) LIKE lower('%rnd%') OR
 lower(c.coupon_container_name) LIKE lower('ride') OR
 lower(c.coupon_container_name) LIKE lower('%rno_weekly%') OR
 lower(c.Coupon_Text) LIKE lower('spb300%') OR
 lower(c.Coupon_Text) LIKE lower('takearide%') OR
 lower(c.Coupon_Text) LIKE lower('gettvarlamov%') OR
 lower(c.Coupon_Text) LIKE lower('gift-ru%') OR
 lower(c.Coupon_Text) LIKE lower('gift-us%') OR
 lower(c.Coupon_Text) LIKE lower('gt300%') OR
 lower(c.Coupon_Text) LIKE lower('love%') OR
 lower(c.Coupon_Text) LIKE lower('first300%') OR
 lower(c.Coupon_Text) LIKE lower('first500%') OR
 lower(c.Coupon_Text) LIKE lower('dave_ru_10000_unique_codes_campaign%') OR
 lower(c.Coupon_Text) LIKE lower('rnd%') OR
 lower(c.Coupon_Text) LIKE lower('ride%') OR
 lower(c.Coupon_Text) LIKE lower('rno_weekly%') OR
 lower(c.Coupon_Text) LIKE lower('c_r_mar%') OR
 lower(c.coupon_container_name) LIKE lower('c_r_mar%') OR
 lower(c.external_id) LIKE lower('ru:marketing%') OR
 lower(c.Coupon_Text) LIKE lower('ru_b2c_nonftr%') OR
 lower(c.coupon_container_name) LIKE lower('ru_b2c_nonftr%') OR
 lower(c.coupon_container_name) LIKE lower('ru_b2c_nftr%')
 THEN 'MAR'

 WHEN lower(c.coupon_type) LIKE lower('if_invitee') OR
 lower(c.coupon_type) LIKE lower('if_inviter') OR
 lower(c.coupon_text) LIKE lower('%moved prepaid balance%') OR
 lower(c.coupon_text) LIKE lower('%???????????? ?????????? ?????????????? ?????????????? ??????????????%')
 THEN 'IF'

 WHEN
   lower(c.Coupon_container_name) LIKE '%employee%' OR
   lower(c.Coupon_container_name) LIKE '%empoloyee_coupon%' OR
   lower(c.Coupon_text) LIKE '%employee%'
 THEN 'EMPLOYEE'

 WHEN
 lower(c.coupon_container_name) LIKE lower('%ru_dmd_nonftr%') OR
 lower(c.coupon_container_name) LIKE lower('%ru_dmd_ftr%') OR
 lower(c.coupon_container_name) LIKE lower('%dmd%') OR
 lower(c.coupon_container_name) LIKE lower('%ru_dme%') OR
 lower(c.coupon_container_name) LIKE lower('%ru_dme%') OR
 lower(c.external_id) LIKE lower('%dmd%')
 THEN 'DMD'


 WHEN
   lower(c.coupon_type) like lower('%ShareTheApp/PayWithGett%')
   OR lower(c.coupon_type) like lower('%ShareTheApp%')
 THEN 'STA'

 WHEN
   lower(c.coupon_container_name) like 'unknown'
 THEN 'unknown'

 ELSE
  'others_strange_names'
  END as Target

 ,SUM(cu.Amount_Redeemed_From_Coupon)  Coupon_Spent



 FROM dbo.Dwh_Dim_Coupons_V c
 JOIN dbo.Dwh_Fact_Coupon_Usages_V cu ON c.Coupon_GK = cu.Coupon_GK
 WHERE c.country_key = 2
 AND cu.consumption_date >= '2017-01-01'
 GROUP BY 1,2,3







select
  CASE WHEN fo.date_key <= '2018-03-29' THEN 'before'
       ELSE 'after' END as period
  ,fo.order_gk
  ,fo.riding_user_gk as user_gk
  ,fo.date_key
  ,fo.customer_total_cost_inc_vat
from dwh_fact_orders_v fo
where fo.ride_type_key = 1
    and fo.order_status_key = 7
    -- and fo.riding_user_gk in {unique_users}
    and fo.date_key between '2018-03-28' - datediff('day', '2018-03-28', current_date) - 1 and '2018-03-28' + datediff('day', '2018-03-28', current_date) - 1

select '2018-03-28' + datediff('day', '2018-03-28', current_date) - 1











with users as (
  select
    trunc(date_trunc('mon', fr.date_key)) as month
    ,du.user_gk
    ,min(fr.ride_gk) as first_month_ride_gk
    ,count(*) as rides
  from dwh_fact_rides_v fr
    inner join dwh_dim_users_v du ON du.user_gk =fr.riding_user_gk
  where fr.country_key = 2 and fr.date_key BETWEEN '2016-01-01' AND current_date
  group by 1,2),

stats as (select
  u.month
  ,u.user_gk
  ,u.first_month_ride_gk
  ,u.rides
  ,sum(CASE WHEN DATEDIFF('month', trunc(date_trunc('mon', fr_last_30.date_key)), u.month) = 1 THEN 1 ELSE 0 END) as num_rides_previous_30
  ,sum(CASE WHEN DATEDIFF('month', trunc(date_trunc('mon', fr_last_30.date_key)), u.month) = 2 THEN 1 ELSE 0 END) as num_rides_30_60
  ,sum(CASE WHEN DATEDIFF('month', trunc(date_trunc('mon', fr_last_30.date_key)), u.month) = 3 THEN 1 ELSE 0 END) as num_rides_60_90
  ,sum(CASE WHEN DATEDIFF('month', trunc(date_trunc('mon', fr_last_30.date_key)), u.month) in (1,2,3) THEN 1 ELSE 0 END) as num_rides_90
from users as u
left join dwh_fact_rides_v fr_last_30 ON u.user_gk = fr_last_30.riding_user_gk
                  AND DATEDIFF('month', trunc(date_trunc('mon', fr_last_30.date_key)), u.month) in (1,2,3)
group by 1,2,3,4)


select
  p.timecategory
  ,p.subperiod2 as Period
  ,CASE WHEN dct.class_type_group_desc in ('VIP','VIP+','Premium') THEN 'B&V'
        WHEN fo_current_month.origin_location_key = 245 THEN 'Msk'
        WHEN fo_current_month.origin_location_key = 246 THEN 'Spb'
        ELSE 'Regions' END as Domain
  ,CASE WHEN s.num_rides_previous_30 > 0 and s.num_rides_30_60 > 0 and s.num_rides_60_90 > 0 and s.num_rides_90 > 9 THEN '1.Core_active'
        WHEN fo.is_ftp_key = 1 THEN '3.FTR'
        WHEN s.num_rides_90 = 0 AND fo.paid_with_prepaid > 0 THEN '5.CRM_reactivation'
        WHEN s.num_rides_90 = 0 AND (fo.paid_with_prepaid = 0 or fo.paid_with_prepaid is null) THEN '4.organic_reactivation'
        ELSE '2.Non_core_active' END as type
  ,count(fo_current_month.order_gk) as rides
  ,count(DISTINCT s.user_gk) as users
  ,1.0 * count(fo_current_month.order_gk)/count(DISTINCT s.user_gk) as rides_user
from stats s
  inner join dwh_fact_orders_v fo ON fo.order_gk = s.first_month_ride_gk
  inner join dwh_fact_orders_v fo_current_month ON fo_current_month.riding_user_gk = s.user_gk
        AND trunc(date_trunc('mon', fo_current_month.date_key)) = s.month
  inner join dbo.dwh_dim_class_types_v dct ON dct.class_type_key = fo_current_month.class_type_key
  join dbo.periods_v p on p.date_key = fo_current_month.date_key
where fo.ride_type_key != 2
      and fo.order_status_key = 7
      and fo_current_month.ride_type_key != 2
      and fo_current_month.order_status_key = 7
      and p.timecategory in ('3.Weeks', '4.Months', '5.Quarters')
      and p.hour_key = 0
group by 1,2,3,4




UNION

select
  p.timecategory
  ,p.subperiod2 as Period
  ,'all' as Domain
  ,CASE WHEN s.num_rides_previous_30 > 0 and s.num_rides_30_60 > 0 and s.num_rides_60_90 > 0 and s.num_rides_90 > 9 THEN '1.Core_active'
        WHEN fo.is_ftp_key = 1 THEN '3.FTR'
        WHEN s.num_rides_90 = 0 AND fo.paid_with_prepaid > 0 THEN '5.CRM_reactivation'
        WHEN s.num_rides_90 = 0 AND (fo.paid_with_prepaid = 0 or fo.paid_with_prepaid is null) THEN '4.organic_reactivation'
        ELSE '2.Non_core_active' END as type
  ,count(fo_current_month.order_gk) as rides
  ,count(DISTINCT s.user_gk) as users
  ,1.0 * count(fo_current_month.order_gk)/count(DISTINCT s.user_gk) rides_user
from stats s
  inner join dwh_fact_orders_v fo ON fo.order_gk = s.first_month_ride_gk
  inner join dwh_fact_orders_v fo_current_month ON fo_current_month.riding_user_gk = s.user_gk
        AND trunc(date_trunc('mon', fo_current_month.date_key)) = s.month
  inner join dbo.dwh_dim_class_types_v dct ON dct.class_type_key = fo_current_month.class_type_key
  join dbo.periods_v p on p.date_key = fo_current_month.date_key
where fo.ride_type_key != 2
      and fo.order_status_key = 7
      and fo_current_month.ride_type_key != 2
      and fo_current_month.order_status_key = 7
      and p.timecategory in ('3.Weeks', '4.Months', '5.Quarters')
      and p.hour_key = 0
group by 1,2,3,4
order by 1,2,3





with rides as (select
  CASE WHEN fo.customer_total_cost_inc_vat < 170 THEN 170 ELSE fo.customer_total_cost_inc_vat END as customer_total_cost_inc_vat
  ,CASE WHEN fo.customer_total_cost_inc_vat < 170 THEN 1 ELSE 0 END as ride
  ,fo.driver_total_commission_inc_vat
  ,fo.driver_total_cost_inc_vat
from dwh_fact_orders_v fo
  inner join dbo.dwh_dim_class_types_v dct on dct.class_type_key = fo.class_type_key
where fo.order_status_key = 7 and fo.date_key between '2018-03-01' and '2018-03-31' and dct.class_type_group_desc = 'Economy' and fo.origin_location_key = 245)

select
  avg(r.driver_total_commission_inc_vat* -1.0 / 1.18 +
                      CASE WHEN r.customer_total_cost_inc_vat > r.driver_total_cost_inc_vat
                          THEN
                            (r.customer_total_cost_inc_vat - r.driver_total_cost_inc_vat) / 1.18
                       ELSE
                          (r.customer_total_cost_inc_vat - r.driver_total_cost_inc_vat) / 1.00 END)  as gp
  ,sum(r.ride) as rides
from rides r


select
  avg(r.driver_total_commission_inc_vat* -1.0 / 1.18 +
                      CASE WHEN r.customer_total_cost_inc_vat > r.driver_total_cost_inc_vat
                          THEN
                            (r.customer_total_cost_inc_vat - r.driver_total_cost_inc_vat) / 1.18
                       ELSE
                          (r.customer_total_cost_inc_vat - r.driver_total_cost_inc_vat) / 1.00 END)  as gp
from dwh_fact_orders_v r
  inner join dbo.dwh_dim_class_types_v dct on dct.class_type_key = r.class_type_key
where r.order_status_key = 7 and r.date_key between '2018-03-01' and '2018-03-31' and dct.class_type_group_desc = 'Economy' and r.origin_location_key = 245



select
  du.user_gk
  ,du.first_name
from dwh_dim_users_v du
where du.username = '79253338465'

'RU_B2C_NonFTR_28032018_sb'


select
  du.user_gk
  ,du.username
from dwh_dim_users_v du
  inner join dwh_fact_orders_v fo ON fo.riding_user_gk = du.user_gk
where du.username in () and fo.date_key >= '2018-04-01'
group by 1,2



select
    fo.origin_location_key
    ,fo.riding_user_gk
    ,fo.driver_total_commission_inc_vat* -1.0 / 1.18 +
                          CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
                              THEN
                                (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
                           ELSE
                              (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END  as gp
    ,fo.customer_total_cost_inc_vat
    ,fo.ride_distance_key
    ,fo.origin_location_key
    ,dct.class_type_group_desc
    ,du.value_loyalty_ranking_key
from dwh_fact_orders_v fo
  inner join dbo.dwh_dim_class_types_v dct on dct.class_type_key = fo.class_type_key
  inner join dbo.dwh_dim_users_v du ON du.user_gk = fo.riding_user_gk
where  fo.order_status_key = 7
        and fo.origin_location_key in (245,246)
        and fo.date_key between '2018-03-01' and '2018-03-31'
        and dct.class_type_group_desc in ('Economy', 'Standard')


select
  fo.loyalty_level_key
  ,fo.rank
from dwh_fact_orders_v fo
where fo.order_status_key = 7 and fo.origin_location_key = 245


select
  *
-- from dwh_dim_fact_promotions_v crm
from dwh_fact_crm_promotions_v fcrm
  -- inner join dwh_dim_crm_promotions_v dcrm ON
  -- inner join dwh_dim_crm_promotions_v dc ON dc.variant_first_step_id = crm.promotion_step_id
where crm.promotion_name

      in ('RU: ftr2ftr4: gamification: welcome: moscow: 20171208')


select

from dwh_fact_orders_v fo
where fo.order_status_key =


select
  dcrm.promotion_variation_name
  ,count(*) as users
from dwh_fact_crm_promotions_v crm
  inner join dwh_dim_crm_promotions_v dcrm ON dcrm.promotion_variation_id = crm.promotion_variation_id
where dcrm.promotion_name = 'RU: ftr2ftr4: gamification: welcome: moscow: 20171208'
group by 1


select
  count(*) as activations
  ,sum(CASE WHEN dc.total_redeemed_amount > 0 THEN 1 ELSE 0 END) as num_redeemed_coupons
  ,sum(dc.total_redeemed_amount) as total_redeemed_amount
from dbo.dwh_dim_coupons_v dc
where dc.activated_date_key between '2018-01-01' and '2018-03-31' and dc.coupon_container_name in ('RU_B2C_NonFTR_12102017',
'RU_B2C_NonFTR_31102017',
'RU_B2C_NonFTR_07022018',
'RU_B2C_NonFTR_28022018_SbSp')


select
  sum(dc.remaining_amount) as remaining_amount
  ,count(*) as num
from dwh_dim_coupons_v dc
where dc.coupon_type = 'IF_Inviter'
      and dc.country_key = 2
      and dc.expiration_date > current_date
      and dc.total_redeemed_amount = 0


-- вокзалы поездки /
select
    TRUNC(DATE_TRUNC('mon', fo.date_key)) as date
    ,cl.class_type_group_desc
    ,count(*) as rides
from dbo.dwh_fact_orders_v fo
  left join dbo.dwh_dim_locations_v dl on dl.location_key = fo.destination_location_key
  inner join dbo.dwh_dim_class_types_v cl on cl.class_type_key = fo.class_type_key
  inner join dbo.dwh_ref_orders_destination_areas_v rooa on fo.order_gk=rooa.order_gk
  inner join dbo.dwh_dim_areas_v da on da.area_gk = rooa.destination_area_gk
where da.area_gk in (20005812, 20005805, 20005803)
      and fo.date_key > '2017-01-01'
      and fo.order_status_key = 7
      and cl.category_desc = 'transport'
      and fo.origin_location_key = 245
group by 1,2





select
  fo.riding_user_gk
from dwh_fact_orders_v fo
  inner join dwh_dim_users_v du ON du.user_gk = fo.riding_user_gk
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
where dct.class_type_desc in
      ('novosibirsk business',
        'kazan business',
        'kazan business fo only',
        'sochi business',
        'krasnodar business',
        'ekaterinburg business',
        'krasnodar business fo only')
      and du.ranking_key in (1,2,3)
      and fo.origin_location_key in (294,
296,
300,
343,
354,
374,
398)
group by 1
HAVING max(fo.date_key) > current_date - 15 and count(*) > 1


select
  fo.order_gk
from dwh_fact_orders_v fo
where fo.dest_full_address like ('Белорусский вокзал, Москва', 'Павелецкий вокзал, Москва', 'Белорусский вокзал, Москва')



select
  TRUNC(DATE_TRUNC('mon', fo.date_key)) as date
  ,dct.class_type_group_desc as class
  ,count(*) as rides
from dwh_fact_orders_v fo
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
where fo.origin_location_key = 245
      and fo.date_key > '2017-08-01'
      and dct.class_type_group_key in (1,3, 4,5)
      and fo.order_status_key = 7
      and (fo.dest_full_address like '%елорусский вокзал%'
      or fo.dest_full_address like '%авелецкий вокзал%'
      or fo.dest_full_address like '%иевский вокзал%')
group by 1,2



SELECT
  l.city_name
  ,count(*) as rides
FROM Dwh_Dim_Users_V u
  INNER JOIN Dwh_Fact_Orders_V fo ON fo.Riding_User_GK = u.User_GK
  LEFT JOIN (SELECT DISTINCT l.city_id, l.city_name, l.location_key
            FROM dwh_dim_locations_v l) l on l.location_key = fo.origin_location_key
where u.Acquisition_Channel_Desc = 'GIS'
       and u.Registration_Date_Key >= '2018-03-01'
       and u.Registration_Date_Key <= '2018-03-31'
GROUP BY 1



-- 2GIS FTRs by month - размещение заказа
SELECT
  l.city_name
  ,count(*) as FTRs
FROM dwh_dim_users_v u
  INNER JOIN Dwh_Fact_Orders_V fo ON fo.Riding_User_GK = u.User_GK
  LEFT JOIN (SELECT DISTINCT l.city_id, l.city_name, l.location_key
            FROM dwh_dim_locations_v l) l on l.location_key = fo.origin_location_key
where u.Acquisition_Channel_Desc = 'GIS'
       and u.Registration_Date_Key between '2018-04-01' and '2018-04-30'
       and fo.is_ftp_key = 0
GROUP BY TRUNC(DATE_TRUNC('mon', u.registration_date_key)), l.city_name
ORDER BY TRUNC(DATE_TRUNC('mon', u.registration_date_key)), count(DISTINCT u.user_gk) DESC



select
  fo.customer_total_cost_inc_vat
  ,fo.driver_total_commission_inc_vat* -1.0 / 1.18 +
                      CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
                          THEN
                            (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
                       ELSE
                          (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END  as gp
from dwh_fact_orders_v fo
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
where fo.date_key between current_date - 60 and current_date
      and fo.order_status_key = 7
      and fo.ride_type_key = 1
      and fo.origin_location_key = 245
      and dct.class_type_group_desc in ('Economy')



select
  fum.cost_inc_vat
  ,fo.order_gk
  ,dmc.component_category
  ,dmc.component_subcategory
  ,fo.customer_total_cost_inc_vat
  ,dmmn.mode_name_desc
from dwh_fact_users_orders_monetization_v fum
  inner join dwh_dim_monetization_components_v dmc ON dmc.component_key = fum.component_key
  inner join dwh_fact_orders_v fo On fo.order_gk = fum.order_gk
  inner join dwh_dim_users_v du on du.user_gk = fo.riding_user_gk
  inner join dwh_dim_monetization_mode_names_v dmmn ON dmmn.mode_name_key = fum.mode_name_key
where du.username = '79253338465' and fo.date_key > '2018-03-31' and fo.order_gk = 2000204738807


select
  fo.order_datetime
from dwh_fact_orders_v fo
where fo.order_gk = 2000204738807

WITH driver_costs AS (
    SELECT
      order_gk,
      SUM(CASE WHEN dcc.component_category_key = 5
        THEN fcdo.cost_inc_vat
          ELSE 0 END)  AS driver_driving,
      -SUM(CASE WHEN dcc.component_category_key = 4
        THEN fcdo.cost_inc_vat
           ELSE 0 END) AS commission,
      SUM(CASE WHEN dcc.component_category_key  in (10, 15)
        THEN fcdo.cost_inc_vat
          ELSE 0 END)  AS driver_waiting,
      SUM(CASE WHEN dcc.component_category_key  = 14
        THEN fcdo.cost_inc_vat
          ELSE 0 END)  AS driver_surge,
      SUM(CASE WHEN dcc.component_category_key  in (6, 13, 2)
        THEN fcdo.cost_inc_vat
          ELSE 0 END)  AS driver_extras
    FROM dbo.dwh_fact_drivers_orders_monetization_v AS fcdo
      JOIN dbo.dwh_dim_monetization_components_v dcc ON dcc.component_key = fcdo.component_key
    WHERE fcdo.origin_location_key  = 245
      and fcdo.order_date_key >= '2018-3-1'
    GROUP BY order_gk),
  user_costs AS (
    SELECT
      order_gk,
      SUM(CASE WHEN dcc.component_category_key = 5
        THEN fcdo.cost_inc_vat
          ELSE 0 END)  AS customer_driving,
      SUM(CASE WHEN dcc.component_category_key  in (10, 15)
        THEN fcdo.cost_inc_vat
          ELSE 0 END)  AS customer_waiting,
      SUM(CASE WHEN dcc.component_category_key  = 14
        THEN fcdo.cost_inc_vat
          ELSE 0 END)  AS customer_surge,
      SUM(CASE WHEN dcc.component_category_key  in (6, 13, 2)
        THEN fcdo.cost_inc_vat
          ELSE 0 END)  AS customer_extras,
      SUM(CASE WHEN dcc.component_category_key  = 9
        THEN fcdo.cost_inc_vat
          ELSE 0 END)  AS customer_tips
    FROM dbo.dwh_fact_users_orders_monetization_v AS fcdo
      JOIN dbo.dwh_dim_monetization_components_v dcc ON dcc.component_key = fcdo.component_key
    WHERE fcdo.origin_location_key  = 245
      and fcdo.order_date_key >= '2018-3-1'
    GROUP BY order_gk),
  contract_types as (
  select distinct order_gk, dcmm.mode_name_desc
  from dbo.dwh_fact_drivers_orders_monetization_v fdom
    join dbo.dwh_dim_charging_mode_names dcmm on dcmm.mode_name_key = fdom.mode_name_key
  where
    fdom.origin_location_key = 245 and
      fdom.order_date_key >='2018-3-1')

select
  fr.dest_longitude,
  fr.dest_latitude,
  fr.origin_longitude,
  fr.origin_latitude,
  fr.date_key,
  fr.hour_key as hour,
  fr.driver_gk,
  fr.order_gk as order_gk,
  uc.*,
  dc.*,
  ct.*,
  ceil(fr.m_ride_duration/60.0) as duration,
  ceil(fr.ride_distance_key) as distance,
  ceil(fr.est_duration/60.0) as est_duration,
  fr.est_distance as est_distance

from dbo.dwh_fact_orders_v fr
join dbo.dwh_dim_class_types_v dct on dct.class_type_key = fr.class_type_key
  join user_costs uc on uc.order_gk = fr.order_gk
  join driver_costs dc on dc.order_gk = fr.order_gk
  join contract_types ct on ct.order_gk = fr.order_gk
where dct.class_type_group_key = 3
and fr.origin_location_key = 245
and fr.ride_type_key = 1
and fr.date_key >= '2018-3-1'
and fr.order_status_key = 7



select
  TRUNC(DATE_TRUNC('mon', du.ftpp_date_key)) as ftp_date_key
  ,TRUNC(DATE_TRUNC('mon', fo.date_key)) as month
  ,DATEDIFF('day', du.ftpp_date_key, fo.date_key) as months_from_fttp
  ,
from dwh_fact_orders_v fo
  inner join dwh_dim_users_v du on du.user_gk = fo.riding_user_gk
where fo.ride_type_key = 1
      and fo.order_status_key = 7





with users as (
  select
    trunc(date_trunc('mon', fr.date_key)) as month
    ,du.user_gk
    ,min(fr.ride_gk) as first_month_ride_gk
    ,count(*) as rides
  from dwh_fact_rides_v fr
    inner join dwh_dim_users_v du ON du.user_gk = fr.riding_user_gk
    inner join dwh_dim_class_types_v dct On dct.class_type_key = fr.class_type_key
  where fr.country_key = 2
        and fr.date_key BETWEEN '2014-01-01' AND current_date
        and fr.origin_location_key = 245 and dct.class_type_group_key in (1,2,3,6) and fr.ride_type_key = 1
  group by 1,2)

 ,stats as (
select
  u.month
  ,u.user_gk
  ,u.first_month_ride_gk
  ,u.rides
  ,sum(CASE WHEN DATEDIFF('month', trunc(date_trunc('mon', fr_last_30.date_key)), u.month) = 1 THEN 1 ELSE 0 END) as num_rides_previous_30
  ,sum(CASE WHEN DATEDIFF('month', trunc(date_trunc('mon', fr_last_30.date_key)), u.month) = 2 THEN 1 ELSE 0 END) as num_rides_30_60
  ,sum(CASE WHEN DATEDIFF('month', trunc(date_trunc('mon', fr_last_30.date_key)), u.month) = 3 THEN 1 ELSE 0 END) as num_rides_60_90
  ,sum(CASE WHEN DATEDIFF('month', trunc(date_trunc('mon', fr_last_30.date_key)), u.month) in (1,2,3) THEN 1 ELSE 0 END) as num_rides_90
from users as u
left join dwh_fact_rides_v fr_last_30 ON u.user_gk = fr_last_30.riding_user_gk
                  AND DATEDIFF('month', trunc(date_trunc('mon', fr_last_30.date_key)), u.month) in (1,2,3)

group by 1,2,3,4),

ftr_stats as (
select
  s.user_gk
  ,CASE WHEN fo.is_ftp_key = 1 THEN '1.FTR'
        WHEN s.num_rides_90 = 0 THEN '2.Reactivation'
        ELSE '3.Active_user' END as FTR_type
  ,trunc(date_trunc('mon', fo.date_key)) as FTR_date
from stats s
  inner join dwh_fact_orders_v fo ON fo.order_gk = s.first_month_ride_gk
where fo.ride_type_key != 2
      and fo.order_status_key = 7
      and (s.num_rides_90 = 0 or fo.is_ftp_key = 1)),

 cohorts as (
  select
  fs.user_gk
  ,fs.FTR_type
  ,fs.FTR_date
  ,min(fs_add.FTR_date) as churn_date
from ftr_stats fs
  left join ftr_stats fs_add ON fs_add.user_gk = fs.user_gk and fs_add.FTR_date > fs.FTR_date
group by 1,2,3)

select
  trunc(date_trunc('mon', c.FTR_date)) as FTR_date
  ,datediff('mon', c.FTR_date, fr.date_key) as num_months_from_ftr
  ,count(DISTINCT c.user_gk) as users
  ,count(c.user_gk) as rides
from cohorts c
  inner join dwh_fact_rides_v fr ON fr.riding_user_gk = c.user_gk and fr.date_key >= c.FTR_date
      and (CASE WHEN c.churn_date IS NOT NULL THEN (fr.date_key <= c.churn_date)
      ELSE (1 = 1) END)
group by 1,2






with users as (select
  fo.riding_user_gk
from dwh_fact_orders_v fo
  inner join dwh_dim_users_v du ON du.user_gk = fo.riding_user_gk
where  fo.order_status_key = 7
      and fo.country_key = 2
      and fo.user_rfm in ('gold', 'platinum')
group by 1
HAVING max(fo.date_key) < current_date - 60
               )

 ,statuses as (
select
  fo.riding_user_gk
  ,fo.dest_full_address
  ,fo.origin_full_address
  ,row_number() OVER(PARTITION BY fo.riding_user_gk ORDER BY count(*) DESC) as rnk
  ,count(*) as num_rides
  ,max(fo.date_key) as last_date_key
from users as u
  inner join dwh_fact_orders_v fo ON fo.riding_user_gk = u.riding_user_gk
where fo.ride_type_key = 1
      and fo.order_status_key = 7
      and fo.country_key = 2
group by 1,2,3
order by 1,5 DESC, 6 DESC)

select
  u.riding_user_gk
  ,u.dest_full_address
  ,u.origin_full_address
from statuses u
  inner join dwh_dim_users_v du on du.user_gk = u.riding_user_gk
where u.rnk = 1 and 1.0 * u.num_rides / du.number_of_private_purchases > 0.25
      and not(u.dest_full_address is null) and not(u.origin_full_address is null)





select
  fo.riding_user_gk
from dwh_fact_orders_v fo
  inner join dwh_dim_class_types_v dct On dct.class_type_key = fo.class_type_key
where dct.class_family in ('Economy', 'Standard')
      and fo.country_key = 2
      and fo.ride_type_key = 1
      and fo.date_key between current_date-30 and current_date
group by 1
having count(*) between 2 and 3




select
  du.username
  ,fo.riding_user_gk
from dwh_fact_orders_v fo
  inner join dwh_dim_users_v du ON du.user_gk = fo.riding_user_gk
  inner join dwh_dim_class_types_v dct On dct.class_type_key = fo.class_type_key
where dct.class_family = 'Premium' and dct.lob_segment = 'B2C'
      and fo.country_key = 2
      and fo.origin_location_key in (245)
group by 1,2
having count(*) > 2






select
  fo.riding_user_gk
from dwh_fact_orders_v fo
   inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
where fo.order_status_key = 7
      and fo.ride_type_key = 1
      and fo.origin_location_key = 300
      and fo.date_key > current_date - 91
group by 1
having (sum(CASE WHEN dct.class_family in ('VIP', 'Premium') THEN 1 ELSE 0 END) > 0
       and sum(CASE WHEN fo.date_key > current_date - 31 and dct.class_family in ('VIP', 'Premium') THEN 1 ELSE 0 END) = 0)
       or sum(CASE WHEN dct.class_family in ('Standard') THEN 1 ELSE 0 END) > 0


select
  fo.riding_user_gk
from dwh_fact_orders_v fo
   inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
where fo.order_status_key = 7
      and fo.ride_type_key = 1
      and fo.origin_location_key = 300
      and dct.class_family in ('VIP', 'Premium')
      and fo.date_key between current_date-91 and current_date-31
group by 1




select
  cu.consumption_date_key
  ,count(*) rides
  ,count(DISTINCT dc.user_gk) as population
  ,sum(CASE WHEN fo.is_ftp_key = 1 THEN 1 ELSE 0 END) as ftrs
from dwh_dim_coupons_v dc
  inner join dwh_fact_coupon_usages_v cu ON cu.coupon_gk = dc.coupon_gk
  inner join dwh_fact_orders_v fo ON fo.order_gk = cu.order_gk
where dc.coupon_container_name in ('RU_B2C_NonFTR_08022018_Guinness',
'RU_B2C_NonFTR_07032018_Guinness')
group by 1









-- CRM
WITH coupon_campaigns_stats as (
SELECT
  crm.promotion_name
  ,max(dc.expiration_date) as promo_period_end
from dwh_dim_crm_promotions_v crm
  left join dwh_dim_coupons_v dc ON lower(dc.external_id) = lower(crm.coupon_external_id)
where crm.creation_date_key between '2017-06-01' and '2018-02-01'
      and crm.country_key = 2
      and crm.coupon_external_id is not null
      and not(crm.promotion_name like '%bv:%')
      and crm.coupon_external_id != -1
group by 1)

  ,coupon_campaigns as (
SELECT
  ccs.promotion_name
  ,crm.promotion_variation_id
  ,ccs.promo_period_end
  ,count(DISTINCT fcrm.user_gk) as population
from coupon_campaigns_stats ccs
  inner join dwh_dim_crm_promotions_v crm ON crm.promotion_name = ccs.promotion_name
  inner join dwh_fact_crm_promotions_v fcrm On fcrm.promotion_variation_id = crm.promotion_variation_id
group by 1,2,3),


users_promo as (SELECT
  TRUNC(DATE_TRUNC('mon', crm.creation_date_key)) as Month
  ,crm.is_control_variant
  ,crm.promotion_goal
  ,crm.promotion_name
  ,crm.promotion_variation_name
  ,cc.promo_period_end
  ,cc.population
  ,fcrm.promotion_entry_date_key
  ,fcrm.user_gk
  ,count(*) as rides
FROM coupon_campaigns cc
  inner join dwh_dim_crm_promotions_v crm ON crm.promotion_name = cc.promotion_name and crm.promotion_variation_id = cc.promotion_variation_id
  inner join dwh_fact_crm_promotions_v fcrm ON fcrm.promotion_variation_id = crm.promotion_variation_id
  inner join dwh_fact_orders_v fo on fo.riding_user_gk = fcrm.user_gk
                                     and fo.ride_type_key = 1
                                     and fo.order_status_key = 7
                                     and fo.date_key between fcrm.promotion_entry_date_key and cc.promo_period_end
group by 1,2,3,4,5,6,7,8,9),

coupons as (
SELECT
  crm.promotion_goal
  ,crm.promotion_name
  ,crm.promotion_variation_name
  ,sum(dc.total_redeemed_amount) as coupon_spent
from dwh_dim_crm_promotions_v crm
  left join dwh_dim_coupons_v dc ON lower(dc.external_id) = lower(crm.coupon_external_id)
where  crm.creation_date_key between '2017-06-01' and '2018-02-01'
      and crm.country_key = 2
      and crm.coupon_external_id is not null
      and not(crm.promotion_name like '%bv:%')
      and crm.coupon_external_id != -1
group by 1,2,3)


select
  u.Month
  ,u.is_control_variant
  ,u.promotion_goal
  ,u.promotion_name
  ,u.promotion_variation_name
  ,u.population
  ,c.coupon_spent
  ,count(DISTINCT CASE WHEN fo.date_key between u.promotion_entry_date_key and u.promo_period_end THEN u.user_gk ELSE null END) as users_promo
  ,count(DISTINCT CASE WHEN fo.date_key between u.promo_period_end and u.promo_period_end+30 THEN u.user_gk ELSE null END) as users_30
  ,count(DISTINCT CASE WHEN fo.date_key between u.promo_period_end and u.promo_period_end+60 THEN u.user_gk ELSE null END) as users_60
  ,count(DISTINCT CASE WHEN fo.date_key between u.promo_period_end and u.promo_period_end+90 THEN u.user_gk ELSE null END) as users_90

  ,count(CASE WHEN fo.date_key between u.promotion_entry_date_key and u.promo_period_end THEN u.user_gk ELSE null END) as rides_promo
  ,count(CASE WHEN fo.date_key between u.promo_period_end and u.promo_period_end+30 THEN u.user_gk ELSE null END) as rides_30
  ,count(CASE WHEN fo.date_key between u.promo_period_end and u.promo_period_end+60 THEN u.user_gk ELSE null END) as rides_60
  ,count(CASE WHEN fo.date_key between u.promo_period_end and u.promo_period_end+90 THEN u.user_gk ELSE null END) as rides_90
from users_promo u
  inner join dwh_fact_orders_v fo on fo.riding_user_gk = u.user_gk
                                     and fo.ride_type_key = 1
                                     and fo.order_status_key = 7
                                     and fo.date_key between u.promotion_entry_date_key and u.promo_period_end + 90

  left join coupons c ON c.promotion_name = u.promotion_name and c.promotion_variation_name = u.promotion_variation_name
group by 1,2,3,4,5,6,7

-- FTR
with ftrs as (SELECT
   TRUNC(DATE_TRUNC('mon', dc.created_date_key)) as Month
  ,dc.coupon_container_name
  ,fo.riding_user_gk
  ,fo.date_key
  ,sum(cu.amount_redeemed_from_coupon) as coupon_spent
FROM dwh_dim_coupons_v dc
  inner join dwh_fact_coupon_usages_v cu ON cu.coupon_gk = dc.coupon_gk
  inner join dwh_fact_orders_v fo On fo.order_gk = cu.order_gk
where dc.is_ftr_key = 1 and dc.country_key = 2 and dc.coupon_type = 'other' and dc.created_date_key > '2017-07-01'
group by 1,2,3,4)

select
  f.Month
  ,f.coupon_container_name
  ,sum(f.coupon_spent) as coupon_spent
  ,count(CASE WHEN fo.date_key between f.date_key and f.date_key+30 THEN fo.riding_user_gk ELSE null END) as rides_promo
  ,count(CASE WHEN fo.date_key between f.date_key+30 and f.date_key+60 THEN fo.riding_user_gk ELSE null END) as rides_30
  ,count(CASE WHEN fo.date_key between f.date_key+30 and f.date_key+90 THEN fo.riding_user_gk ELSE null END) as rides_60
  ,count(CASE WHEN fo.date_key between f.date_key+30 and f.date_key+120 THEN fo.riding_user_gk ELSE null END) as rides_90
from ftrs f
  inner join dwh_fact_orders_v fo On fo.riding_user_gk = f.riding_user_gk and fo.date_key between f.date_key and f.date_key + 120
group by 1,2
having count(CASE WHEN fo.date_key between f.date_key and f.date_key+30 THEN fo.riding_user_gk ELSE null END) > 500


with air as (select
  CASE WHEN (fo.dest_latitude >= 55.383401
      AND fo.dest_latitude <= 55.435248
      AND fo.dest_longitude >= 37.855796
      AND fo.dest_longitude <= 37.952613)
      THEN 'DME-T'

    WHEN (fo.dest_latitude >= 55.95535088
      AND fo.dest_latitude <= 55.98666769
      AND fo.dest_longitude >= 37.36724854
      AND fo.dest_longitude <= 37.45702744)
      THEN 'SVO-T'

    WHEN (fo.dest_latitude >= 55.58406941068366
      AND fo.dest_latitude <= 55.6149104080857
      AND fo.dest_longitude >= 37.2352409362793
      AND fo.dest_longitude <= 37.31334686279297)
      THEN 'VKO-T' END as class
  ,fo.riding_user_gk
from dwh_fact_orders_v fo
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
where fo.ride_type_key = 1 and fo.order_status_key = 7
      and fo.date_key between '2018-04-26' and '2018-04-27'
      and dct.class_group in ('Kids')
group by 1,2)

with air as (select
  CASE WHEN (fo.origin_latitude >= 55.383401
      AND fo.origin_latitude <= 55.435248
      AND fo.origin_longitude >= 37.855796
      AND fo.origin_longitude <= 37.952613)
      THEN 'DME-T' END as type
  ,fo.dest_full_address
from dwh_fact_orders_v fo
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
where fo.ride_type_key = 1 and fo.order_status_key = 7 and fo.dest_full_address is not null
      and fo.date_key >  current_date-120)

select
  air.dest_full_address
from air
where air.type = 'DME-T'
  group by 1
order by count(*) DESC
LIMIT 30


select
  du.user_gk
  ,du.username
  ,du.first_name
  ,du.last_name
  ,du.email
  ,sum(dc.total_redeemed_amount) as coupon_spent
from dwh_dim_coupons_v dc
  inner join dwh_dim_users_v du On du.user_gk = dc.user_gk
where dc.coupon_container_name in ('RU_HR_NonFTR_Employees_2018_April_5600',
'RU_HR_NonFTR_Employees_2018_April_1450',
'RU_HR_NonFTR_Employees_2018_April_11200')
  and dc.activated_date_key >= '2018-01-01'
group by 1,2,3,4,5

SELECT
  date_trunc('month', cu.consumption_date_key)::DATE Month_Year
 ,CASE WHEN c.coupon_type = 'appboy' THEN 'CRM'
     WHEN c.is_ftr_key = 1 THEN 'acquisition'
     WHEN c.is_ftr_key in (0,-1) THEN 'retention' END as coupon_type
,CASE WHEN lower(c.external_id) like '%demand_boost%' THEN 'demand_boost'
           WHEN  lower(c.external_id) like '%reg2ftr%' THEN 'reg2ftr'
           WHEN  lower(c.external_id) like '%reactivation%' THEN 'reactivation'
           ELSE 'others' END as  crm_type
 ,CASE WHEN lower(c.coupon_container_name) like lower('RU_B2C_NonFTR_31082017') OR
        lower(c.coupon_container_name) like lower('RU_B2C_NonFTR_12102017') OR
        lower(c.coupon_container_name) like lower('RU_B2C_NonFTR_31102017') OR
        lower(c.coupon_container_name) like lower('RU_B2C_NonFTR_07022018') OR
        lower(c.coupon_container_name) like lower('RU_B2C_NonFTR_28022018_SbSp') OR
        lower(c.coupon_container_name) like lower('RU_B2C_NonFTR_28032018_sb') OR
        lower(c.coupon_container_name) like lower('RU_B2C_NonFTR_09042018_sb') OR
        lower(c.coupon_container_name) like lower('RU_B2C_NonFTR_16042018_sb')
  THEN 'Sberbank'

 WHEN lower(c.coupon_container_name) LIKE lower('ru_b2c_nonftr_reg%') OR
 lower(c.coupon_container_name) LIKE lower('ru_b2c_ftr_reg%') OR
 lower(c.Coupon_Text) LIKE lower('c_a_reg%') OR
 lower(c.coupon_text) LIKE lower('c_r_reg%') OR
 lower(c.coupon_container_name) LIKE lower('c_a_reg%') OR
 lower(c.coupon_container_name) LIKE lower('c_r_reg%') OR
 lower(c.external_id) LIKE lower('ru:regions%') OR
 lower(c.coupon_container_name) LIKE lower('ru_ftr_sta%') OR
 lower(c.coupon_container_name) LIKE lower('ru_regions%') OR
 lower(c.coupon_container_name) LIKE lower('kashira%') OR
 lower(c.coupon_container_name) LIKE lower('magnitogorsk_ftr%')
 THEN 'REGIONS'

 WHEN c.coupon_container_name = 'CocaCola Code Coupon Campaign 2016' OR
 c.Coupon_Text = '?????? ???????????????? ?????????? ?????????????????? 1000 ?????????????? ???? ???????? ?????????????????? 10 ?????????????? ?? Gett ?????? ?????????????????? ?????????????? ???????? 200 ??????.' OR
 c.Coupon_Text = '?????? ???????????????? ?????????? ?????????????????? 1000 ?????????????? ???? ???????? ?????????????????? 10 ?????????????? ?? Gett ?????? ?????????????????? ?????????????? ???????? 250 ??????.' OR
 c.Coupon_Text = '?????? ???????????????? ?????????? ?????????????????? 500 ?????????????? ???? ???????? ?????????????????? 10 ?????????????? ?? Gett ?????? ?????????????????? ?????????????? ???????? 100 ??????.' OR
 lower(c.coupon_container_name) LIKE lower('????????????????_????????????%') OR
 lower(c.coupon_container_name) like lower('%северное_сияние%') OR
 lower(c.coupon_container_name) like lower('%siyanie%')
 THEN 'Siyanie'

 WHEN lower(c.Coupon_Text) LIKE lower('c_r_cc%') OR
 lower(c.coupon_container_name) LIKE lower('c_r_cc%') OR
 lower(c.coupon_container_name) LIKE lower('ru_cc%') OR
 lower(c.coupon_container_name) LIKE lower('couponcc%') OR
 lower(c.coupon_container_name) LIKE lower('coupon%cc%') OR
 lower(c.coupon_container_name) LIKE lower('cc%backup%') OR
 lower(c.coupon_container_name) LIKE lower('customercare%') OR
 lower(c.coupon_container_name) LIKE lower('cc%coupons%') OR
 lower(c.Coupon_Text) LIKE lower('cc%coupons%') OR
 lower(c.Coupon_Text) LIKE lower('couponcc%') OR
 lower(c.Coupon_Text) LIKE lower('coupon%cc%') OR
 lower(c.Coupon_Text) LIKE lower('cc%backup%') OR
 lower(c.Coupon_Text) LIKE lower('customercare%')
 THEN 'CC'

 WHEN lower(c.Coupon_Text) LIKE lower('%b_a_bb%') OR
 lower(c.Coupon_Text) LIKE lower('%b_r_bb%') OR
 lower(c.coupon_container_name) LIKE lower('%b_a_bb%') OR
 lower(c.coupon_container_name) LIKE lower('%b_а_bb_%') OR
 lower(c.coupon_container_name) LIKE lower('%b_r_bb%') OR
 lower(c.coupon_container_name) LIKE lower('%ru_b2b%') OR
 lower(c.Coupon_Text) LIKE lower('%??????????????%') OR
 lower(c.Coupon_Text) LIKE lower('%??????????????%') OR
 lower(c.Coupon_Text) LIKE lower('%??????????????%') OR
 lower(c.Coupon_Text) LIKE lower('%b_r_b%') OR
 lower(c.coupon_container_name) LIKE lower('%b_r_b%') OR
 lower(c.coupon_container_name) LIKE lower('%dmdvip%') OR
 lower(c.coupon_container_name) LIKE lower('%dontforgett750%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4bulgari%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4dior%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4evraz%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4goody%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4hend%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4mhen%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4pm%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4tupper%') OR
 lower(c.coupon_container_name) LIKE lower('%gett4vw%') OR
 lower(c.coupon_container_name) LIKE lower('%gettf24%') OR
 lower(c.coupon_container_name) LIKE lower('%gettit%') OR
 lower(c.coupon_container_name) LIKE lower('%gettkiosk%')
 THEN 'B2B'

 WHEN lower(c.Coupon_Text) LIKE lower('c_a_bv%') OR
 lower(c.Coupon_Text) LIKE lower('c_r_bv%') OR
 lower(c.coupon_container_name) LIKE lower('c_a_bv%') OR
 lower(c.coupon_container_name) LIKE lower('c_r_bv%') OR
 lower(c.external_id) LIKE lower('ru:bv%') OR
 lower(c.coupon_container_name) LIKE lower('ru_bvip%') OR
 lower(c.coupon_container_name) LIKE lower('%bv%')
 THEN 'Business&VIP'


 WHEN lower(c.Coupon_Text) LIKE lower('d_a_sup%') OR
 lower(c.Coupon_Text) LIKE lower('d_r_sup%') OR
 lower(c.coupon_container_name) LIKE lower('ru_b2d%') OR
 lower(c.coupon_text) LIKE lower('q_s%') OR
 lower(c.Coupon_Text) LIKE lower('d_r_bv%') OR
 lower(c.coupon_container_name) LIKE lower('d_a_sup%') OR
 lower(c.coupon_container_name) LIKE lower('d_r_sup%') OR
 lower(c.coupon_container_name) LIKE lower('q_s%') OR
 lower(c.coupon_container_name) LIKE lower('d_r_bv%') OR
 lower(c.coupon_container_name) LIKE lower('%total%quality%')
 THEN 'Supply'

 WHEN lower(c.Coupon_Text) LIKE lower('c_a_v%') OR
 lower(c.Coupon_Text) LIKE lower('c_r_v%') OR
 lower(c.coupon_container_name) LIKE lower('c_a_v%') OR
 lower(c.coupon_container_name) LIKE lower('c_r_v%') OR
 lower(c.external_id) LIKE lower('ru:verticals%') OR
 lower(c.external_id) LIKE lower('ru_delivery_ftr%') OR
 lower(c.external_id) LIKE lower('ru_delivery_nonftr%') OR
 lower(c.coupon_container_name) LIKE lower('ru_courier%') OR
 lower(c.coupon_container_name) LIKE lower('ru_delivery%') OR
 lower(c.coupon_container_name) LIKE lower('ru_gett_courier%') OR
 lower(c.coupon_container_name) LIKE lower('%delivery%')
 THEN 'VERTICALS'

 WHEN lower(c.Coupon_Text) LIKE lower('ru_crm%') OR
 lower(c.coupon_container_name) LIKE lower('ru_crm%') OR
 lower(c.coupon_text) = lower('?????? ?? ?????????????? 1000 ?????????????? ?? ?????????? ?????????????????? ?????????? ???????????? ?????????????? ?? Gett!') OR
 lower(c.coupon_text) = lower('?????? ?? ?????????????? 1000 ?????????????? ???? ?????????????? ?? ?????????????? ????????????????????!') OR
 lower(c.coupon_text) = lower('?????? ?? ?????????????? 1500 ?????????????? ???? ?????????????? ?? ?????????????? ????????????????????!') OR
 lower(c.external_id) like lower('ru:%:%:%') OR
 lower(c.Coupon_Text) LIKE lower('c_a_mar%') OR
 lower(c.Coupon_Text) LIKE lower('ru_b2c_ftr%') OR
 lower(c.coupon_container_name) LIKE lower('c_a_mar%') OR
 lower(c.coupon_container_name) LIKE lower('ru_b2c_ftr%') OR
 lower(c.coupon_container_name) LIKE lower('%getttele2%') OR
 lower(c.coupon_container_name) LIKE lower('%spb300%') OR
 lower(c.coupon_container_name) LIKE lower('%takearide%') OR
 lower(c.coupon_container_name) LIKE lower('%gettvarlamov%') OR
 lower(c.coupon_container_name) LIKE lower('%gift-ru%') OR
 lower(c.coupon_container_name) LIKE lower('%gift-us%') OR
 lower(c.coupon_container_name) LIKE lower('%gt300%') OR
 lower(c.coupon_container_name) LIKE lower('%love%') OR
 lower(c.coupon_container_name) LIKE lower('%first300%') OR
 lower(c.coupon_container_name) LIKE lower('%first500%') OR
 lower(c.coupon_container_name) LIKE lower('%dave_ru_10000_unique_codes_campaign%') OR
 lower(c.coupon_container_name) LIKE lower('%rnd%') OR
 lower(c.coupon_container_name) LIKE lower('ride') OR
 lower(c.coupon_container_name) LIKE lower('%rno_weekly%') OR
 lower(c.Coupon_Text) LIKE lower('spb300%') OR
 lower(c.Coupon_Text) LIKE lower('takearide%') OR
 lower(c.Coupon_Text) LIKE lower('gettvarlamov%') OR
 lower(c.Coupon_Text) LIKE lower('gift-ru%') OR
 lower(c.Coupon_Text) LIKE lower('gift-us%') OR
 lower(c.Coupon_Text) LIKE lower('gt300%') OR
 lower(c.Coupon_Text) LIKE lower('love%') OR
 lower(c.Coupon_Text) LIKE lower('first300%') OR
 lower(c.Coupon_Text) LIKE lower('first500%') OR
 lower(c.Coupon_Text) LIKE lower('dave_ru_10000_unique_codes_campaign%') OR
 lower(c.Coupon_Text) LIKE lower('rnd%') OR
 lower(c.Coupon_Text) LIKE lower('ride%') OR
 lower(c.Coupon_Text) LIKE lower('rno_weekly%') OR
 lower(c.Coupon_Text) LIKE lower('c_r_mar%') OR
 lower(c.coupon_container_name) LIKE lower('c_r_mar%') OR
 lower(c.external_id) LIKE lower('ru:marketing%') OR
 lower(c.Coupon_Text) LIKE lower('ru_b2c_nonftr%') OR
 lower(c.coupon_container_name) LIKE lower('ru_b2c_nonftr%') OR
 lower(c.coupon_container_name) LIKE lower('ru_b2c_nftr%')
 THEN 'MAR'

 WHEN lower(c.coupon_type) LIKE lower('if_invitee') OR
 lower(c.coupon_type) LIKE lower('if_inviter') OR
 lower(c.coupon_text) LIKE lower('%moved prepaid balance%') OR
 lower(c.coupon_text) LIKE lower('%???????????? ?????????? ?????????????? ?????????????? ??????????????%')
 THEN 'IF'

 WHEN
   lower(c.Coupon_container_name) LIKE '%employee%' OR
   lower(c.Coupon_container_name) LIKE '%empoloyee_coupon%' OR
   lower(c.Coupon_text) LIKE '%employee%'
 THEN 'EMPLOYEE'

 WHEN
 lower(c.coupon_container_name) LIKE lower('%ru_dmd_nonftr%') OR
 lower(c.coupon_container_name) LIKE lower('%ru_dmd_ftr%') OR
 lower(c.coupon_container_name) LIKE lower('%dmd%') OR
 lower(c.coupon_container_name) LIKE lower('%ru_dme%') OR
 lower(c.coupon_container_name) LIKE lower('%ru_dme%') OR
 lower(c.external_id) LIKE lower('%dmd%')
 THEN 'DMD'


 WHEN
   lower(c.coupon_type) like lower('%ShareTheApp/PayWithGett%')
   OR lower(c.coupon_type) like lower('%ShareTheApp%')
 THEN 'STA'

 WHEN
   lower(c.coupon_container_name) like 'unknown'
 THEN 'unknown'

 ELSE
  'others_strange_names'
  END as Target

 ,SUM(cu.Amount_Redeemed_From_Coupon)  Coupon_Spent



 FROM dbo.Dwh_Dim_Coupons_V c
 JOIN dbo.Dwh_Fact_Coupon_Usages_V cu ON c.Coupon_GK = cu.Coupon_GK
 WHERE c.country_key = 2
 AND cu.consumption_date >= '2017-01-01'
 GROUP BY 1,2,3,4

select
  fo.riding_user_gk as user_gk
  ,sum(fo.user_loyalty_surge_giveaway) as ru_discount_0418
from dwh_fact_orders_v fo
where fo.ride_type_key = 1
      and fo.order_status_key = 7
      and fo.date_key between '2018-04-01' and '2018-04-30'
group by 1
having sum(fo.user_loyalty_surge_giveaway) >= 300


select
  fo.riding_user_gk as user_gk
  ,sum(fo.user_loyalty_surge_giveaway) as ru_discount_0418
from dwh_fact_orders_v fo
where fo.ride_type_key = 1
      and fo.order_status_key = 7
      and fo.country_key = 2
      and fo.date_key between '2018-04-01' and '2018-04-30'
group by 1
having sum(fo.user_loyalty_surge_giveaway) >= 300


select
  fo.riding_user_gk as user_gk
  ,sum(CASE WHEN fo.user_base_surge > fo.user_applied_surge THEN
            (fo.user_base_surge - fo.user_applied_surge) * fo.customer_base_price
            ELSE 0 END) as ru_discount_0418
from dbo.dwh_fact_orders_v fo
where fo.order_status_key = 7
      and fo.country_key = 2
      and fo.date_key between '2018-04-01' and '2018-04-30'
group by 1
having sum(CASE WHEN fo.user_base_surge > fo.user_applied_surge THEN
            (fo.user_base_surge - fo.user_applied_surge) * fo.customer_base_price
            ELSE 0 END) >= 300







with promotions_length as (
    select p.promotion_id,
           p.coupon_external_id,
           max(datediff(day,c.created_datetime,c.expiration_date)) promotion_length,
           1 as is_coupon
    from Dwh_Dim_CRM_Promotions_v p
    join dbo.dwh_dim_coupons_v c on case when p.coupon_external_id = 'Unknown' then null else lower(p.coupon_external_id) end = lower(c.External_ID)
    where p.Is_Control_Variant = 0
          and c.created_datetime > '1900-01-01'
          -- and p.promotion_id = '6bbfad7d-754e-4cee-a84f-ed902504ab84'  -- for QA
    group by p.promotion_id, p.coupon_external_id
    union all
    select distinct p.promotion_id,
           null,
           7, -- if there is no coupon, promotion length is set to 7 days
           0
    from Dwh_Dim_CRM_Promotions_v p
    left join dbo.dwh_dim_coupons_v c on case when p.coupon_external_id = 'Unknown' then null else lower(p.coupon_external_id) end = lower(c.External_ID)
    where c.External_ID is null
          and p.Is_Control_Variant = 0
          -- and p.promotion_id = '6bbfad7d-754e-4cee-a84f-ed902504ab84'  -- for QA
    )
, users_promotion_length as (
select user_gk,
       promotion_variation_id,
       Promotion_Id,
       Is_Control_Variation,
       start_promotion,
       case when Is_Control_Variation = 1 then dateadd(day,promotion_length,start_promotion) else COALESCE(expiration_date,dateadd(day,promotion_length,start_promotion)) end end_promotion,
       dateadd(day,promotion_length+1,start_promotion) start_after_promotion,
       dateadd(day,promotion_length+after_promotion_legth,start_promotion) end_after_promotion
from (
    select f.user_gk,
           f.promotion_variation_id,
           f.Promotion_Id,
           d.is_control_variant Is_Control_Variation,
           p.promotion_length,
             case when p.is_coupon = 1 then 61 else 15 end after_promotion_legth,
           min(c.expiration_date) expiration_date,
           -- Logic to find the promotion_start_date -> If has coupons - since coupon started, else since did something, else since resived, else sinse in promotion (control only should get to the last)
           min(cast(COALESCE (c.created_datetime, f.email_open_datetime, f.inapp_messages_click_datetime, f.pushnotification_open_datetime, f.email_delivery_datetime, f.inapp_messages_impression_datetime, f.pushnotification_send_datetime, f.promotion_entry_datetime) as datetime)) as start_promotion
    from dbo.dwh_fact_crm_promotions_v f
    join dbo.dwh_dim_crm_promotions_v d on d.promotion_id = f.promotion_id and d.promotion_variation_id = f.promotion_variation_id
    join promotions_length p on f.promotion_id = p.promotion_id
    left join dbo.dwh_dim_coupons_v c on c.user_gk = f.user_gk and lower(p.coupon_external_id) = lower(c.external_id)
    where 1=1
          --and f.promotion_id in ('17f59593-8446-4102-ba81-2c3ac57aae6e')  -- for QA
          -- and f.promotion_variation_id = '33e20939-3406-4348-9cfc-96f915c8fa65'
    group by f.user_gk,
           f.promotion_variation_id,
           f.Promotion_Id,
           is_control_variant,
           p.promotion_length,
           case when p.is_coupon = 1 then 61 else 15 end
    ) as t
where start_promotion > '1900-01-01'
)
,users_rides_money as (
select p.promotion_id,
       user_gk,
       p.promotion_variation_id,
       p.Is_Control_Variation,
       count(          case when r.order_datetime between p.start_promotion and p.end_promotion then r.order_gk end) num_rides_in_promotion,
       sum(              case when r.order_datetime between p.start_promotion and p.end_promotion then r.Customer_Total_Cost_Inc_Vat else 0 end) ride_val_in_promotion,
       count(          case when r.order_datetime between p.start_after_promotion and p.end_after_promotion then r.order_gk end) num_rides_after_promotion,
       sum(              case when r.order_datetime between p.start_after_promotion and p.end_after_promotion then r.Customer_Total_Cost_Inc_Vat else 0 end) ride_val_after_promotion
from users_promotion_length p
left join dbo.Dwh_Fact_orders_V r on r.Riding_User_GK = p.User_GK
                                --and r.Date_Key >= p.start_promotion -- only rides that were made after the coupon was created
                                and r.Order_Status_Key = 7
  inner join dwh_dim_class_types_v dct ON dct.class_type_key = r.class_type_key
where p.promotion_variation_id <> -1
      and dct.class_family = 'Kids'
group by p.promotion_id,
       user_gk,
       p.promotion_variation_id,
       p.Is_Control_Variation
)

,rides_money as (
select users_rides_money.promotion_id,
       users_rides_money.promotion_variation_id,
       Is_Control_Variation,
       pop.population_size,
       count(distinct user_gk) num_users,
       sum(case when num_rides_in_promotion > 0 then num_rides_in_promotion end)                                num_rides_in_promotion,
       count(distinct case when num_rides_in_promotion > 0 then user_gk end)                                     distinct_riders_in_promotion,
       sum(case when num_rides_in_promotion > 0 then ride_val_in_promotion end)                                 ride_val_in_promotion,
       sum(case when num_rides_in_promotion > 0 then num_rides_after_promotion end)                             num_rides_after_promotion,
       count(distinct case when num_rides_in_promotion > 0 and num_rides_after_promotion > 0 then user_gk end)     distinct_riders_after_promotion,
       sum(case when num_rides_in_promotion > 0 then ride_val_after_promotion end)                                ride_val_after_promotion
from users_rides_money
  left join

  (select
  crm.promotion_variation_id
  ,crm.promotion_id
  ,count(DISTINCT crm.user_gk) as population_size
from dwh_fact_crm_promotions_v crm
group by 1,2) as pop ON pop.promotion_variation_id = users_rides_money.promotion_variation_id

group by users_rides_money.promotion_id,
       users_rides_money.promotion_variation_id,
       Is_Control_Variation,
       pop.population_size
)
, coupons_money as (
select a.promotion_id,
       a.promotion_variation_id,
       a.is_control_variant,
       sum(Total_Redeemed_Amount) coupons_cost
from (

    select distinct b.user_gk,
           a.promotion_id,
           a.promotion_variation_id,
           a.is_control_variant,
           c.Total_Redeemed_Amount
    from dbo.Dwh_Dim_CRM_Promotions_v a
    join dbo.dwh_fact_crm_promotions_v b on a.promotion_id = b.promotion_id and a.promotion_variation_id = b.promotion_variation_id
    join dbo.Dwh_Dim_Coupons_V c on case when a.coupon_external_id = 'Unknown' then null else lower(a.coupon_external_id) end = lower(c.External_ID)
                                    and b.user_gk = c.user_gk -- only users who got the promotion
    where a.promotion_variation_id <> -1
         -- and a.promotion_id = '06bb4ad0-d164-4d1b-bdba-2c69892c31fc'  -- for QA
     )  a
group by a.promotion_id,
       a.promotion_variation_id,
       a.is_control_variant
)

  ,crm_dash_data as (select 'During Promotion' as period_type,
       p.creation_date_key,
       p.country_key,
       a.promotion_id,
       p.promotion_name,
       a.Is_Control_Variation,
       a.promotion_variation_id,
       p.promotion_variation_name,
       p.promotion_timing,
       p.promotion_goal,
       p.promotion_status,
       d.is_coupon,
       case when p.country_key = 1 /*IL ROI*/ then 0.092
            when p.country_key = 3 /*GB ROI*/ then case when lower(p.location_type) = 'regions' then 0.058 else 0.1 end
            when p.country_key = 2 /*RU ROI*/ then case when lower(p.location_type) = 'regions' then 0.039 else 0.156 end
       end roi_multiplier,
       a.population_size,
       a.num_users,
       a.num_rides_in_promotion num_rides,
       a.distinct_riders_in_promotion distinct_riders,
       a.ride_val_in_promotion ride_val,
       b.population_size control_population,
       b.num_users                          control_num_users,
       b.num_rides_in_promotion          control_num_rides,
       b.distinct_riders_in_promotion      contorol_distinct_riders,
       b.ride_val_in_promotion              control_ride_val,
       c.coupons_cost                      coupons_value
from rides_money a
left join rides_money b on a.promotion_id = b.promotion_id and b.Is_Control_Variation = 1
join dbo.dwh_dim_crm_promotions_v p on a.promotion_id = p.promotion_id and a.promotion_variation_id = p.promotion_variation_id
join (select distinct promotion_id, is_coupon from promotions_length) d on d.promotion_id = a.promotion_id
left join coupons_money c on a.promotion_id = c.promotion_id and a.promotion_variation_id = c.promotion_variation_id

                     union all

                     select 'After Promotion' as period_type,
       p.creation_date_key,
       p.country_key,
       a.promotion_id,
       p.promotion_name,
       a.Is_Control_Variation,
       a.promotion_variation_id,
       p.promotion_variation_name,
       p.promotion_timing,
       p.promotion_goal,
       p.promotion_status,
       d.is_coupon,
       case when p.country_key = 1 /*IL ROI*/ then 0.092
            when p.country_key = 3 /*GB ROI*/ then case when lower(p.location_type) = 'regions' then 0.058 else 0.1 end
            when p.country_key = 2 /*RU ROI*/ then case when lower(p.location_type) = 'regions' then 0.039 else 0.156 end
       end roi_multiplier,
       a.population_size,
       a.distinct_riders_in_promotion num_users,
       a.num_rides_after_promotion num_rides,
       a.distinct_riders_after_promotion distinct_riders,
       a.ride_val_after_promotion ride_val,
       b.population_size control_population,
       b.distinct_riders_in_promotion       control_num_users,
       b.num_rides_after_promotion          control_num_rides,
       b.distinct_riders_after_promotion control_distinct_riders,
       b.ride_val_after_promotion          control_ride_val,
       null                       coupons_value
from rides_money a
  left join rides_money b on a.promotion_id = b.promotion_id and b.Is_Control_Variation = 1
  join dbo.dwh_dim_crm_promotions_v p on a.promotion_id = p.promotion_id and a.promotion_variation_id = p.promotion_variation_id
  join (select distinct promotion_id, is_coupon from promotions_length) d on d.promotion_id = a.promotion_id)







with promotions_length as (
    select p.promotion_id,
           p.coupon_external_id,
           max(datediff(day,c.created_datetime,c.expiration_date)) promotion_length,
           1 as is_coupon
    from Dwh_Dim_CRM_Promotions_v p
    join dbo.dwh_dim_coupons_v c on case when p.coupon_external_id = 'Unknown' then null else lower(p.coupon_external_id) end = lower(c.External_ID)
    where p.Is_Control_Variant = 0
          and c.created_datetime > '1900-01-01'
          -- and p.promotion_id = '6bbfad7d-754e-4cee-a84f-ed902504ab84'  -- for QA
    group by p.promotion_id, p.coupon_external_id
    union all
    select distinct p.promotion_id,
           null,
           7, -- if there is no coupon, promotion length is set to 7 days
           0
    from Dwh_Dim_CRM_Promotions_v p
    left join dbo.dwh_dim_coupons_v c on case when p.coupon_external_id = 'Unknown' then null else lower(p.coupon_external_id) end = lower(c.External_ID)
    where c.External_ID is null
          and p.Is_Control_Variant = 0
          -- and p.promotion_id = '6bbfad7d-754e-4cee-a84f-ed902504ab84'  -- for QA
    )
, users_promotion_length as (
select user_gk,
       promotion_variation_id,
       Promotion_Id,
       Is_Control_Variation,
       start_promotion,
       case when Is_Control_Variation = 1 then dateadd(day,promotion_length,start_promotion) else COALESCE(expiration_date,dateadd(day,promotion_length,start_promotion)) end end_promotion,
       dateadd(day,promotion_length+1,start_promotion) start_after_promotion,
       dateadd(day,promotion_length+after_promotion_legth,start_promotion) end_after_promotion
from (
    select f.user_gk,
           f.promotion_variation_id,
           f.Promotion_Id,
           d.is_control_variant Is_Control_Variation,
           p.promotion_length,
             case when p.is_coupon = 1 then 61 else 15 end after_promotion_legth,
           min(c.expiration_date) expiration_date,
           -- Logic to find the promotion_start_date -> If has coupons - since coupon started, else since did something, else since resived, else sinse in promotion (control only should get to the last)
           min(cast(COALESCE (c.created_datetime, f.email_open_datetime, f.inapp_messages_click_datetime, f.pushnotification_open_datetime, f.email_delivery_datetime, f.inapp_messages_impression_datetime, f.pushnotification_send_datetime, f.promotion_entry_datetime) as datetime)) as start_promotion
    from dbo.dwh_fact_crm_promotions_v f
    join dbo.dwh_dim_crm_promotions_v d on d.promotion_id = f.promotion_id and d.promotion_variation_id = f.promotion_variation_id
    join promotions_length p on f.promotion_id = p.promotion_id
    left join dbo.dwh_dim_coupons_v c on c.user_gk = f.user_gk and lower(p.coupon_external_id) = lower(c.external_id)
    where 1=1
          --and f.promotion_id in ('17f59593-8446-4102-ba81-2c3ac57aae6e')  -- for QA
          -- and f.promotion_variation_id = '33e20939-3406-4348-9cfc-96f915c8fa65'
    group by f.user_gk,
           f.promotion_variation_id,
           f.Promotion_Id,
           is_control_variant,
           p.promotion_length,
           case when p.is_coupon = 1 then 61 else 15 end
    ) as t
where start_promotion > '1900-01-01'
)
,users_rides_money as (
select p.promotion_id,
       user_gk,
       p.promotion_variation_id,
       p.Is_Control_Variation,
       count(          case when r.order_datetime between p.start_promotion and p.end_promotion then r.order_gk end) num_rides_in_promotion,
       sum(              case when r.order_datetime between p.start_promotion and p.end_promotion then r.Customer_Total_Cost_Inc_Vat else 0 end) ride_val_in_promotion,
       count(          case when r.order_datetime between p.start_after_promotion and p.end_after_promotion then r.order_gk end) num_rides_after_promotion,
       sum(              case when r.order_datetime between p.start_after_promotion and p.end_after_promotion then r.Customer_Total_Cost_Inc_Vat else 0 end) ride_val_after_promotion
from users_promotion_length p
left join dbo.Dwh_Fact_orders_V r on r.Riding_User_GK = p.User_GK
                                --and r.Date_Key >= p.start_promotion -- only rides that were made after the coupon was created
                                and r.Order_Status_Key = 7
where p.promotion_variation_id <> -1
group by p.promotion_id,
       user_gk,
       p.promotion_variation_id,
       p.Is_Control_Variation
)

,rides_money as (
select users_rides_money.promotion_id,
       users_rides_money.promotion_variation_id,
       Is_Control_Variation,
       pop.population_size,
       count(distinct user_gk) num_users,
       sum(case when num_rides_in_promotion > 0 then num_rides_in_promotion end)                                num_rides_in_promotion,
       count(distinct case when num_rides_in_promotion > 0 then user_gk end)                                     distinct_riders_in_promotion,
       sum(case when num_rides_in_promotion > 0 then ride_val_in_promotion end)                                 ride_val_in_promotion,
       sum(case when num_rides_in_promotion > 0 then num_rides_after_promotion end)                             num_rides_after_promotion,
       count(distinct case when num_rides_in_promotion > 0 and num_rides_after_promotion > 0 then user_gk end)     distinct_riders_after_promotion,
       sum(case when num_rides_in_promotion > 0 then ride_val_after_promotion end)                                ride_val_after_promotion
from users_rides_money
  left join

  (select
  crm.promotion_variation_id
  ,crm.promotion_id
  ,count(DISTINCT crm.user_gk) as population_size
from dwh_fact_crm_promotions_v crm
group by 1,2) as pop ON pop.promotion_variation_id = users_rides_money.promotion_variation_id

group by users_rides_money.promotion_id,
       users_rides_money.promotion_variation_id,
       Is_Control_Variation,
       pop.population_size
)
, coupons_money as (
select a.promotion_id,
       a.promotion_variation_id,
       a.is_control_variant,
       sum(Total_Redeemed_Amount) coupons_cost
from (

    select distinct b.user_gk,
           a.promotion_id,
           a.promotion_variation_id,
           a.is_control_variant,
           c.Total_Redeemed_Amount
    from dbo.Dwh_Dim_CRM_Promotions_v a
    join dbo.dwh_fact_crm_promotions_v b on a.promotion_id = b.promotion_id and a.promotion_variation_id = b.promotion_variation_id
    join dbo.Dwh_Dim_Coupons_V c on case when a.coupon_external_id = 'Unknown' then null else lower(a.coupon_external_id) end = lower(c.External_ID)
                                    and b.user_gk = c.user_gk -- only users who got the promotion
    where a.promotion_variation_id <> -1
         -- and a.promotion_id = '06bb4ad0-d164-4d1b-bdba-2c69892c31fc'  -- for QA
     )  a
group by a.promotion_id,
       a.promotion_variation_id,
       a.is_control_variant
)

select 'During Promotion' as period_type,
p.creation_date_key,
       p.country_key,
       a.promotion_id,
       p.promotion_name,
       a.Is_Control_Variation,
       a.promotion_variation_id,
       p.promotion_variation_name,
       p.promotion_timing,
       p.promotion_goal,
       p.promotion_status,
       d.is_coupon,
       case when p.country_key = 1 /*IL ROI*/ then 0.092
            when p.country_key = 3 /*GB ROI*/ then case when lower(p.location_type) = 'regions' then 0.058 else 0.1 end
            when p.country_key = 2 /*RU ROI*/ then case when lower(p.location_type) = 'regions' then 0.039 else 0.156 end
       end roi_multiplier,
       a.population_size,
       a.num_users,
       a.num_rides_in_promotion num_rides,
       a.distinct_riders_in_promotion distinct_riders,
       a.ride_val_in_promotion ride_val,
       b.population_size control_population,
       b.num_users                          control_num_users,
       b.num_rides_in_promotion          control_num_rides,
       b.distinct_riders_in_promotion      contorol_distinct_riders,
       b.ride_val_in_promotion              control_ride_val,
       c.coupons_cost                      coupons_value
from rides_money a
left join rides_money b on a.promotion_id = b.promotion_id and b.Is_Control_Variation = 1
join dbo.dwh_dim_crm_promotions_v p on a.promotion_id = p.promotion_id and a.promotion_variation_id = p.promotion_variation_id
join (select distinct promotion_id, is_coupon from promotions_length) d on d.promotion_id = a.promotion_id
left join coupons_money c on a.promotion_id = c.promotion_id and a.promotion_variation_id = c.promotion_variation_id
union all
select 'After Promotion' as period_type,
p.creation_date_key,
       p.country_key,
       a.promotion_id,
       p.promotion_name,
       a.Is_Control_Variation,
       a.promotion_variation_id,
       p.promotion_variation_name,
       p.promotion_timing,
       p.promotion_goal,
       p.promotion_status,
       d.is_coupon,
       case when p.country_key = 1 /*IL ROI*/ then 0.092
            when p.country_key = 3 /*GB ROI*/ then case when lower(p.location_type) = 'regions' then 0.058 else 0.1 end
            when p.country_key = 2 /*RU ROI*/ then case when lower(p.location_type) = 'regions' then 0.039 else 0.156 end
       end roi_multiplier,
       a.population_size,
       a.distinct_riders_in_promotion num_users,
       a.num_rides_after_promotion num_rides,
       a.distinct_riders_after_promotion distinct_riders,
       a.ride_val_after_promotion ride_val,
       b.population_size control_population,
       b.distinct_riders_in_promotion       control_num_users,
       b.num_rides_after_promotion          control_num_rides,
       b.distinct_riders_after_promotion control_distinct_riders,
       b.ride_val_after_promotion          control_ride_val,
       null                       coupons_value
from rides_money a
  left join rides_money b on a.promotion_id = b.promotion_id and b.Is_Control_Variation = 1
  join dbo.dwh_dim_crm_promotions_v p on a.promotion_id = p.promotion_id and a.promotion_variation_id = p.promotion_variation_id
  join (select distinct promotion_id, is_coupon from promotions_length) d on d.promotion_id = a.promotion_id






select
  CASE WHEN fo.date_key <= '2018-05-10' THEN 'before'
       ELSE 'after' END as period
  ,fo.order_gk
  ,fo.riding_user_gk as user_gk
  ,fo.date_key
  ,fo.customer_total_cost_inc_vat
  ,fo.ride_distance_key
  ,fo.driver_total_commission_inc_vat* -1.0 / 1.18 +
          CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
              THEN
                (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
           ELSE
              (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END  as gp
from dwh_fact_orders_v fo
    inner join dwh_dim_users_v du ON du.user_gk = fo.riding_user_gk
where fo.ride_type_key = 1
    and fo.order_status_key = 7
    and fo.date_key between '2018-05-10'- datediff('day', '2018-05-10', current_date) and '2018-05-10'+ datediff('day', '2018-05-10', current_date)-1


DELETE FROM analysis.mav_visa_margin
