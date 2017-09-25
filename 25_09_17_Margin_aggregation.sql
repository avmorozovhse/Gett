SELECT
  dl.Region_Name,
  dct.Class_Type_Group_Desc,
  avg(fo.Customer_Total_Cost_Inc_Vat) as avg_Customer_Total_Cost_Inc_Vat,
  avg(fo.Driver_Total_Cost_Inc_Vat) as avg_driver_Total_Cost_Inc_Vat,
  count(fo.Order_GK) as NUm,
  avg(fcdo.Cost_Exc_Vat * -1 +
    CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat + fcdo.Cost_Exc_Vat * -1
      THEN
        (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat - fcdo.Cost_Exc_Vat * -1) / 1.18
      ELSE
        (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat - fcdo.Cost_Exc_Vat * -1) / 1.00 END) as margin_sum
from dbo.Dwh_Fact_Orders_V fo
  INNER JOIN dbo.Dwh_Fact_Charging_Drivers_Orders_V fcdo on fcdo.Order_GK = fo.Order_GK
  INNER JOIN dbo.dwh_dim_charging_components_v dcc on fcdo.Component_Key = dcc.Component_Key
  INNER JOIN dbo.dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
  INNER JOIN dbo.dwh_dim_locations_v dl ON dl.location_key = fo.origin_location_key
WHERE fo.Date_Key >= '2017-08-01' and fo.Date_Key <= '2017-08-31'
      and dcc.Component_Name_Key = 4
      and fo.Country_Key = 2
      and fo.origin_location_key IN (245)
      and dct.Class_Type_Group_Key in (1,3,4,5)
      and not(fo.Ride_Type_Key = 2)
      and fo.Order_Status_Key = 7
GROUP BY dl.Region_Name, dct.Class_Type_Group_Desc
