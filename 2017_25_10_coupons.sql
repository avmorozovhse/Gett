WITH

    coupons as (
  SELECT
    c.user_gk
    ,fo.order_gk
    ,sum(c.total_redeemed_amount) as total_redeemed_amount
    ,sum(c.coupon_initial_amount) as coupon_initial_amount
    ,fo.is_ftp_key
    ,fo.order_status_key
  FROM dbo.dwh_dim_coupons_v c
    JOIN dbo.dwh_fact_coupon_usages_v cu ON cu.coupon_gk = c.coupon_gk
    JOIN dbo.dwh_fact_orders_v fo ON fo.order_gk = cu.order_gk
  WHERE c.Coupon_Container_Name Like '%CocaCola Code Coupon Campaign 2016%'
        and fo.Order_Status_Key = 7
  GROUP BY c.user_gk, fo.order_gk, fo.is_ftp_key, fo.order_status_key),


    users as (
  SELECT
    DISTINCT c.user_gk
  FROM dbo.dwh_dim_coupons_v c
  WHERE c.Coupon_Container_Name Like '%CocaCola Code Coupon Campaign 2016%'),


    ftr4 as (
  SELECT
    coupons.user_gk
    ,CASE WHEN COUNT(*) >= 4 THEN 1 ELSE 0 END AS is_ftr4
  FROM coupons
  JOIN dbo.dwh_dim_users_v du ON du.user_gk = coupons.user_gk
  JOIN dbo.dwh_fact_rides_v fr ON fr.ordering_user_gk = du.user_gk
                              AND DATEDIFF('day', du.ftpp_date_key, fr.date_key) <= 90
  GROUP BY coupons.user_gk),


    data as (
  SELECT
    TRUNC(DATE_TRUNC('mon', fo.date_key))
    ,CASE WHEN fo.origin_location_key = 245 THEN 'Moscow'
        WHEN fo.origin_location_key = 246 THEN 'SPB'
        ELSE 'Regions' END AS Location

    ,users.user_gk as User_GK
    ,fo.Order_GK
    ,fo.M_Ride_Duration / 60.0 as M_Ride_Duration
    ,fo.ride_distance_key
    ,fo.Customer_Total_Cost_Inc_Vat as Customer_check
    ,fo.Driver_Total_Cost_Inc_Vat + fcdo.Cost_Inc_Vat * -1 as Driver_check
    ,fo.Order_Confirmed_Datetime
    ,dct.Class_Type_Group_Desc
    ,fo.Date_Key
    ,fcdo.Cost_Inc_Vat * -1 as Commission
    ,fcdo.Cost_Exc_Vat * -1 +
    CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat + fcdo.Cost_Inc_Vat * -1
      THEN
        (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat - fcdo.Cost_Inc_Vat * -1) / 1.18
      ELSE
        (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat - fcdo.Cost_Inc_Vat * -1) / 1.00 END as GP
    ,coupons.total_redeemed_amount as Coupon_spent
    ,coupons.coupon_initial_amount as Amount
    ,coupons.is_ftp_key as Is_ftr
  FROM users
    INNER JOIN dbo.Dwh_Fact_Orders_V fo ON fo.riding_user_gk = users.user_gk
    LEFT JOIN coupons ON coupons.order_gk = fo.order_gk
    INNER JOIN dbo.Dwh_Fact_Charging_Drivers_Orders_V fcdo on fcdo.Order_GK = fo.Order_GK
    INNER JOIN dbo.dwh_dim_charging_components_v dcc on fcdo.Component_Key = dcc.Component_Key
    INNER JOIN dbo.dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
  WHERE fo.Date_Key >= '2017-07-01'
        and dcc.Component_Name_Key = 4
        and fo.Country_Key = 2
        and not(fo.Ride_Type_Key = 2)
        and fo.Order_Status_Key = 7)

  SELECT
     *
  FROM data
