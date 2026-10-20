CREATE OR REPLACE VIEW analytics.modeling_dataset AS
SELECT
    p.*,
    l.inactive_next_90_days
FROM analytics.customer_snapshot_population AS p
JOIN analytics.customer_snapshot_labels AS l
    ON l.customer_id = p.customer_id
   AND l.cutoff_date = p.cutoff_date
   AND l.dataset_split = p.dataset_split;