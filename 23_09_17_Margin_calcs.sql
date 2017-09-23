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
