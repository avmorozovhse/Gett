SELECT
  fo.Order_GK,
  fo.Riding_User_GK as User_GK,
  fo.M_Ride_Duration,
  fo.Ride_Distance_Key,
  fo.Customer_Total_Cost_Inc_Vat,
  fo.Customer_Total_Cost,
  fo.Driver_Total_Cost_Inc_Vat+fcdo.Cost_Inc_Vat*-1 as Driver_check,
  fo.Order_Confirmed_Datetime,
  dct.Class_Type_Group_Desc,
  fo.Cancelled_By_Type_Key,
  fo.Date_Key,
  fo.Ordering_Corporate_Account_GK as Corporate_Account_GK,
  fcdo.Cost_Inc_Vat* -1 as Commission,
  fcdo.Cost_Exc_Vat * -1 +
    CASE WHEN fo.customer_total_cost_inc_vat > fo.driver_total_cost_inc_vat + fcdo.Cost_Inc_Vat * -1
      THEN
        (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat - fcdo.Cost_Inc_Vat * -1) / 1.18
      ELSE
        (fo.customer_total_cost_inc_vat - fo.driver_total_cost_inc_vat - fcdo.Cost_Inc_Vat * -1) / 1.00 END as margin_sum
from dbo.Dwh_Fact_Orders_V fo
  INNER JOIN dbo.Dwh_Fact_Charging_Drivers_Orders_V fcdo on fcdo.Order_GK = fo.Order_GK
  INNER JOIN dbo.dwh_dim_charging_components_v dcc on fcdo.Component_Key = dcc.Component_Key
  INNER JOIN dbo.dwh_dim_class_types_v dct ON dct.class_type_key = fo.class_type_key
WHERE fo.Date_Key >= '2017-09-04' and fo.Date_Key <= '2017-09-24'
      and dcc.Component_Name_Key = 4
      and fo.Country_Key = 2
      and not(fo.Ride_Type_Key = 2)
      and fo.Order_Status_Key = 7
      and dct.Class_Type_Group_Key = 1
      and fo.Origin_Location_Key = 245
