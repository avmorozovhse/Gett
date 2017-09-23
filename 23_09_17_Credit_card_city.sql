SELECT
  du.User_GK,
  du.UserName,
  du.Phone
FROM Dwh_Dim_Users_V du
WHERE du.UserName = '89168024235' OR du.Phone = '89168024235' OR du.UserName = '79168024235' OR du.Phone = '79168024235' OR du.UserName = '09168024235' OR du.Phone = '09168024235'
