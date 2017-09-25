--Version v1, Alex Morozov's code
SELECT
  fo.Order_GK,
  fo.Riding_User_GK,
  fo.M_Ride_Duration,
  fo.Customer_Total_Cost_Inc_Vat,
  fo.Driver_Total_Cost_Inc_Vat,
  fo.Order_Confirmed_Datetime,
  dct.Class_Type_Group_Desc,
  fo.Cancelled_By_Type_Key,
  fo.Date_Key,
  fo.Ordering_Corporate_Account_GK,
  fcdo.Cost_Exc_Vat,
  fcdo.Cost_Exc_Vat * -1 +
    CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat
      THEN
        (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.18
      ELSE
        (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat) / 1.00 END as margin_sum
from dbo.Dwh_Fact_Orders_V fo
  INNER JOIN dbo.Dwh_Fact_Charging_Drivers_Orders_V fcdo on fcdo.Order_GK = fo.Order_GK
  INNER JOIN dbo.dwh_dim_charging_components_v dcc on fcdo.Component_Key = dcc.Component_Key
  INNER JOIN dbo.dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
WHERE dcc.Component_Name_Key = 4 

  and fo.Country_Key = 2 
  and fo.Date_Key > '2017-08-12' 
  and fo.Date_Key < '2017-08-14'
  
  
  
  
  
--Version v2, Alex Morozov's code
SELECT
  fo.Order_GK,
  fo.Riding_User_GK as User_GK,
  fo.M_Ride_Duration,
  fo.Customer_Total_Cost_Inc_Vat,
  fo.Driver_Total_Cost_Inc_Vat,
  fo.Order_Confirmed_Datetime,
  dct.Class_Type_Group_Desc,
  fo.Cancelled_By_Type_Key,
  fo.Date_Key,
  fo.Ordering_Corporate_Account_GK as Corporate_Account_GK,
  fcdo.Cost_Exc_Vat* -1 as Commission,
  fcdo.Cost_Exc_Vat * -1 +
    CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat + fcdo.Cost_Exc_Vat * -1
      THEN
        (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat - fcdo.Cost_Exc_Vat * -1) / 1.18
      ELSE
        (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat - fcdo.Cost_Exc_Vat * -1) / 1.00 END as margin_sum
from dbo.Dwh_Fact_Orders_V fo
  INNER JOIN dbo.Dwh_Fact_Charging_Drivers_Orders_V fcdo on fcdo.Order_GK = fo.Order_GK
  INNER JOIN dbo.dwh_dim_charging_components_v dcc on fcdo.Component_Key = dcc.Component_Key
  INNER JOIN dbo.dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
WHERE fo.Date_Key >= '2017-05-01'
      and dcc.Component_Name_Key = 4
      and fo.Country_Key = 2
      and not(fo.Ride_Type_Key = 2)
      and fo.Order_Status_Key = 7




--Version v1, Dima's code
SELECT
  fo.order_gk,
  fo.customer_total_cost_inc_vat,
  fo.driver_total_cost_inc_vat,
  fcdo.cost_exc_vat,
  fo.customer_total_cost,
  fo.driver_total_cost,
  fo.origin_location_key,
  fcdo.cost_exc_vat * -1 +          /cost_exc_vat = cost_per_order_depended_on_contract_with_park_of_driveres   /
    CASE WHEN customer_total_cost_inc_vat > driver_total_cost_inc_vat
      THEN
        (customer_total_cost_inc_vat - driver_total_cost_inc_vat) / 1.18
      ELSE
        (customer_total_cost_inc_vat - driver_total_cost_inc_vat) / 1.00 END as Margin
FROM
  dbo.dwh_fact_charging_drivers_orders_v fcdo
  JOIN dbo.dwh_dim_charging_components_v dcc ON dcc.component_key = fcdo.component_key
  JOIN dbo.dwh_fact_orders_v fo ON fo.order_gk = fcdo.order_gk
  JOIN dbo.dwh_dim_locations_v dl ON dl.location_key = fo.origin_location_key
  JOIN dbo.dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
WHERE
  fo.country_key = 2
  AND fcdo.country_key = 2
  AND fo.origin_location_key IN (245, 246)
  AND fo.date_key > '2017-01-01'
  AND fcdo.order_date_key > '2017-01-01'
  AND dcc.component_name_key = 4
  AND dct.class_type_group_key IN (1, 3)
ORDER BY fo.order_gk


