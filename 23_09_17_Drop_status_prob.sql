select
  u.User_GK,
  u.rfm_drop_prob,
  u.rfm_drop_prob_decile_country, /*1 - highest probability, 10 - lowest probability*/
  u.Country_Key,
  u.Ranking_Key
from dbo.dwh_dim_users_v as u
WHERE u.Country_Key = 2 and not(u.RFM_Drop_Prob_Decile_Country= -1) and u.Ranking_Key in (1,2)
