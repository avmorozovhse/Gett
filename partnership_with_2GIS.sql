SELECT
  MONTH(u.Registration_Date_Key) as Month
  ,count(*) as installations
FROM Dwh_Dim_Users_V u
 where u.Acquisition_Channel_Desc = 'GIS'
       and u.Registration_Date_Key >= '2017-08-01'
       and u.Registration_Date_Key <= '2017-10-31'
GROUP BY MONTH(u.Registration_Date_Key)
