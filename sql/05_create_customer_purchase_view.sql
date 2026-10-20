CREATE SCHEMA IF NOT EXISTS analytics;

CREATE OR REPLACE VIEW analytics.customer_purchase_lines AS
SELECT
    raw_row_id,
    source_file,
    source_sheet,
    source_row_number,
    invoice,
    stock_code,
    description,
    quantity,
    invoice_date,
    unit_price,
    customer_id,
    country,
    quantity * unit_price AS line_purchase_value
FROM staging.retail_transactions
WHERE customer_id IS NOT NULL
  AND quantity > 0
  AND unit_price > 0
  AND UPPER(invoice) NOT LIKE 'C%';