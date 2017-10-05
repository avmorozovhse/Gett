SELECT
  avg(fo.M_Ride_Duration) as duration,
  avg(fo.Ride_Distance_Key) as distance
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
