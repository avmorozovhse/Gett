SELECT
  lv.City_Name
  ,avg(fo.Customer_Total_Cost_Inc_Vat) as average_check
  ,count(fo.Customer_Total_Cost_Inc_Vat) as rides
from dbo.Dwh_Fact_Orders_V fo
  JOIN dbo.Dwh_Dim_Locations_V lv on fo.Origin_Location_Key = lv.Location_Key
  JOIN dbo.Dwh_Dim_Class_Types_V ct on fo.Class_Type_Key = ct.Class_Type_Key
WHERE fo.Date_Key >= '2017-07-01'
    and fo.Country_Key = 2
    and not(fo.Ride_Type_Key = 2)
    and fo.Order_Status_Key = 7
    and fo.Origin_Location_Key in ( 374, 403, 294, 343, 355, 245, 246, 354)
    and ct.Class_Type_Group_Key in (1,3)
GROUP BY lv.City_Name
