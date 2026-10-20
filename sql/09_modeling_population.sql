CREATE OR REPLACE VIEW analytics.modeling_population_20110601 AS
SELECT *
FROM analytics.customer_features_20110601
WHERE orders_last_90_days + orders_previous_90_days > 0;