CREATE OR REPLACE VIEW analytics.customer_features_20110601 AS
WITH parameters AS (
    SELECT TIMESTAMP '2011-06-01 00:00:00' AS cutoff_date
),
historical_orders AS (
    SELECT o.*
    FROM analytics.customer_orders AS o
    CROSS JOIN parameters AS p
    WHERE o.last_line_date < p.cutoff_date
)
SELECT
    o.customer_id,
    p.cutoff_date,
    MIN(o.order_date) AS first_observed_order,
    MAX(o.order_date) AS most_recent_order,

    p.cutoff_date::date - MAX(o.order_date)::date
        AS recency_days,

    COUNT(*) AS order_count,
    SUM(o.order_purchase_value) AS purchase_value,
    ROUND(AVG(o.order_purchase_value), 2) AS avg_order_value,

    p.cutoff_date::date - MIN(o.order_date)::date
        AS observed_tenure_days,

    COUNT(*) FILTER (
        WHERE o.order_date >= p.cutoff_date - INTERVAL '90 days'
    ) AS orders_last_90_days,

    COALESCE(
        SUM(o.order_purchase_value) FILTER (
            WHERE o.order_date >= p.cutoff_date - INTERVAL '90 days'
        ),
        0
    ) AS purchase_value_last_90_days,

    COUNT(*) FILTER (
        WHERE o.order_date >= p.cutoff_date - INTERVAL '180 days'
          AND o.order_date < p.cutoff_date - INTERVAL '90 days'
    ) AS orders_previous_90_days

FROM historical_orders AS o
CROSS JOIN parameters AS p
GROUP BY o.customer_id, p.cutoff_date;