SELECT
    invoice,
    customer_id,
    MIN(invoice_date) AS first_line_time,
    MAX(invoice_date) AS last_line_time,
    MAX(invoice_date) - MIN(invoice_date) AS time_difference,
    COUNT(DISTINCT invoice_date::date) AS calendar_days,
    COUNT(*) AS line_count
FROM analytics.customer_purchase_lines
GROUP BY invoice, customer_id
HAVING COUNT(DISTINCT invoice_date) > 1
ORDER BY time_difference DESC, invoice;