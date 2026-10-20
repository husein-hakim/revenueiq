CREATE OR REPLACE VIEW analytics.customer_labels_20110601 AS
SELECT
    p.customer_id,
    p.cutoff_date,
    p.cutoff_date + INTERVAL '90 days' AS label_end,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM analytics.customer_orders_cached AS o
            WHERE o.customer_id = p.customer_id
              AND o.order_date >= p.cutoff_date
              AND o.order_date < p.cutoff_date + INTERVAL '90 days'
        )
        THEN 0
        ELSE 1
    END AS inactive_next_90_days
FROM analytics.modeling_population_20110601 AS p;