CREATE OR REPLACE VIEW analytics.customer_snapshot_features AS
SELECT
    o.customer_id,
    s.cutoff_date,
    s.dataset_split,

    MIN(o.order_date) AS first_observed_order,
    MAX(o.order_date) AS most_recent_order,

    s.cutoff_date::date - MAX(o.order_date)::date
        AS recency_days,

    COUNT(*) AS order_count,

    SUM(o.order_purchase_value) AS purchase_value,

    ROUND(AVG(o.order_purchase_value), 2)
        AS avg_order_value,

    s.cutoff_date::date - MIN(o.order_date)::date
        AS observed_tenure_days,

    COUNT(*) FILTER (
        WHERE o.order_date >= s.cutoff_date - INTERVAL '90 days'
    ) AS orders_last_90_days,

    COALESCE(
        SUM(o.order_purchase_value) FILTER (
            WHERE o.order_date >= s.cutoff_date - INTERVAL '90 days'
        ),
        0
    ) AS purchase_value_last_90_days,

    COUNT(*) FILTER (
        WHERE o.order_date >= s.cutoff_date - INTERVAL '180 days'
          AND o.order_date < s.cutoff_date - INTERVAL '90 days'
    ) AS orders_previous_90_days

FROM analytics.snapshot_schedule AS s
JOIN analytics.customer_orders_cached AS o
    ON o.last_line_date < s.cutoff_date

GROUP BY
    o.customer_id,
    s.cutoff_date,
    s.dataset_split;