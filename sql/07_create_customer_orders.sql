CREATE OR REPLACE VIEW analytics.customer_orders AS
SELECT
    invoice,
    customer_id,
    MIN(invoice_date) AS order_date,
    MAX(invoice_date) AS last_line_date,
    MIN(country) AS country,
    COUNT(*) AS line_count,
    COUNT(DISTINCT stock_code) AS distinct_products,
    SUM(quantity) AS total_units,
    SUM(line_purchase_value) AS order_purchase_value
FROM analytics.customer_purchase_lines
GROUP BY invoice, customer_id;