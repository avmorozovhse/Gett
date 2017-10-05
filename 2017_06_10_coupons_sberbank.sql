WITH users AS (
SELECT c.user_gk
  ,c.coupon_gk
  ,c.max_amount_per_usage
FROM dbo.dwh_dim_coupons_v c
WHERE c.coupon_text IN ('C_R_MAR_11052017', 'RU_B2C_NonFTR_16062017',
                        'RU_B2C_NonFTR_12112017', 'RU_B2C_NonFTR_15082017',
                        'RU_B2C_NonFTR_28082017', 'RU_B2C_NonFTR_31082017')
GROUP BY c.user_gk, c.coupon_gk, c.max_amount_per_usage
  ),
  ftr AS (
  SELECT users.user_gk
    ,1 AS is_ftr
  FROM users
    JOIN dbo.dwh_fact_rides_v fr ON fr.ordering_user_gk = users.user_gk
    JOIN dbo.dwh_fact_coupon_usages_v cu ON cu.order_gk = fr.ride_gk
    JOIN dbo.dwh_dim_coupons_v c ON c.coupon_gk = cu.coupon_gk
  WHERE c.coupon_text IN ('C_R_MAR_11052017', 'RU_B2C_NonFTR_16062017',
                          'RU_B2C_NonFTR_12112017', 'RU_B2C_NonFTR_15082017',
                          'RU_B2C_NonFTR_28082017', 'RU_B2C_NonFTR_31082017')
    AND fr.is_ftp_key = 1
  GROUP BY users.user_gk
  ),
  ftr4 AS (
    SELECT ftr.user_gk
      ,CASE WHEN COUNT(*) >= 4 THEN 1 ELSE 0 END AS is_ftr4
    FROM ftr
    JOIN dbo.dwh_dim_users_v du ON du.user_gk = ftr.user_gk
    JOIN dbo.dwh_fact_rides_v fr ON fr.ordering_user_gk = du.user_gk
                                AND DATEDIFF('day', du.ftpp_date_key, fr.date_key) <= 90
    GROUP BY ftr.user_gk
  )
SELECT TRUNC(DATE_TRUNC('mon', date_key))
  ,CASE WHEN fo.origin_location_key = 245 THEN 'Moscow'
        WHEN fo.origin_location_key = 246 THEN 'SPB'
        ELSE 'Regions' END AS Location
  ,users.max_amount_per_usage AS Amount
  ,COUNT(DISTINCT fo.order_gk) AS total_rides
  ,COUNT(DISTINCT CASE WHEN cu.order_gk IS NOT NULL AND cu.coupon_gk = users.coupon_gk THEN fo.order_gk ELSE NULL END) AS coupon_rides
  ,COUNT(DISTINCT CASE WHEN cu.order_gk IS NOT NULL THEN fo.order_gk END) -
     COUNT(DISTINCT CASE WHEN cu.order_gk IS NOT NULL AND cu.coupon_gk = users.coupon_gk AND cu.amount_redeemed_from_coupon > 0.2 * fo.customer_total_cost_inc_vat
                THEN fo.order_gk END) AS other_coupon_rides
  ,SUM(CASE WHEN cu.order_gk IS NOT NULL AND cu.coupon_gk = users.coupon_gk THEN cu.amount_redeemed_from_coupon / 100.0 ELSE NULL END) AS coupon_spent
  ,SUM(CASE WHEN cu.order_gk IS NOT NULL AND cu.coupon_gk = users.coupon_gk THEN fo.customer_total_cost_inc_vat / 100.0 ELSE NULL END) AS customer_cost_coupon_rides
  ,SUM(fo.customer_total_cost_inc_vat / 100.0) AS customer_cost_total
  ,COUNT(DISTINCT CASE WHEN ftr.is_ftr = 1 THEN fo.riding_user_gk ELSE NULL END) AS FTRs
  ,COUNT(DISTINCT CASE WHEN ftr4.is_ftr4 = 1 AND ftr.is_ftr = 1 THEN users.user_gk ELSE NULL END) AS FTR4
  ,SUM(CASE WHEN fo.Customer_Total_Cost_Inc_Vat > fo.Driver_Total_Cost_Inc_Vat AND fo.origin_location_key = 245 AND cu.order_gk IS NOT NULL AND cu.coupon_gk = users.coupon_gk
            THEN ((fo.Customer_Total_Cost_Inc_Vat / 100.0 - fo.Driver_Total_Cost_Inc_Vat / 100.0) / 1.18) +
                  (fo.Driver_Total_Cost_Inc_Vat / 100.0 * 0.166)
            WHEN fo.Customer_Total_Cost_Inc_Vat > fo.Driver_Total_Cost_Inc_Vat AND fo.origin_location_key = 246 AND cu.order_gk IS NOT NULL AND cu.coupon_gk = users.coupon_gk
            THEN ((fo.Customer_Total_Cost_Inc_Vat / 100.0 - fo.Driver_Total_Cost_Inc_Vat / 100.0) / 1.18) +
                  (fo.Driver_Total_Cost_Inc_Vat / 100.0 * 0.177)
            WHEN fo.Customer_Total_Cost_Inc_Vat > fo.Driver_Total_Cost_Inc_Vat AND cu.order_gk IS NOT NULL AND cu.coupon_gk = users.coupon_gk
            THEN ((fo.Customer_Total_Cost_Inc_Vat / 100.0 - fo.Driver_Total_Cost_Inc_Vat / 100.0) / 1.18) +
                  (fo.Driver_Total_Cost_Inc_Vat / 100.0 * 0.05)
            WHEN fo.Customer_Total_Cost_Inc_Vat <= fo.Driver_Total_Cost_Inc_Vat AND fo.origin_location_key = 245 AND cu.order_gk IS NOT NULL AND cu.coupon_gk = users.coupon_gk
            THEN (fo.Customer_Total_Cost_Inc_Vat / 100.0 - fo.Driver_Total_Cost_Inc_Vat / 100.0) +
                  (fo.Driver_Total_Cost_Inc_Vat * 0.166 / 100.0)
            WHEN fo.Customer_Total_Cost_Inc_Vat <= fo.Driver_Total_Cost_Inc_Vat AND fo.origin_location_key = 246 AND cu.order_gk IS NOT NULL AND cu.coupon_gk = users.coupon_gk
            THEN (fo.Customer_Total_Cost_Inc_Vat / 100.0 - fo.Driver_Total_Cost_Inc_Vat / 100.0) +
                  (fo.Driver_Total_Cost_Inc_Vat * 0.177 / 100.0)
            WHEN fo.Customer_Total_Cost_Inc_Vat <= fo.Driver_Total_Cost_Inc_Vat AND cu.order_gk IS NOT NULL AND cu.coupon_gk = users.coupon_gk
            THEN (fo.Customer_Total_Cost_Inc_Vat / 100.0 - fo.Driver_Total_Cost_Inc_Vat / 100.0) +
                  (fo.Driver_Total_Cost_Inc_Vat * 0.05 / 100.0)
            ELSE NULL END) AS GP
  ,COUNT(DISTINCT users.user_gk) AS users
FROM users
  LEFT JOIN ftr ON ftr.user_gk = users.user_gk
  LEFT JOIN ftr4 ON ftr4.user_gk = users.user_gk
  JOIN dbo.dwh_fact_orders_v fo on fo.ordering_user_gk = users.user_gk
  LEFT JOIN dbo.dwh_fact_coupon_usages_v cu on cu.order_gk = fo.order_gk
WHERE fo.order_status_key = 7
  AND fo.ride_type_key = 1
  AND fo.date_key >= '2016-01-01'
GROUP BY trunc(date_trunc('mon', date_key))
  ,users.max_amount_per_usage
  ,CASE WHEN fo.origin_location_key = 245 THEN 'Moscow'
        WHEN fo.origin_location_key = 246 THEN 'SPB'
        ELSE 'Regions' END
ORDER BY trunc(date_trunc('mon', date_key))
  ,users.max_amount_per_usage
  ,CASE WHEN fo.origin_location_key = 245 THEN 'Moscow'
        WHEN fo.origin_location_key = 246 THEN 'SPB'
        ELSE 'Regions' END
