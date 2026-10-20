CREATE OR REPLACE VIEW analytics.modeling_dataset_20110601 AS
SELECT
    features.*,
    labels.inactive_next_90_days
FROM analytics.modeling_population_20110601 AS features
JOIN analytics.customer_labels_20110601 AS labels
    ON features.customer_id = labels.customer_id
   AND features.cutoff_date = labels.cutoff_date;