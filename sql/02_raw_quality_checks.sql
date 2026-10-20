SELECT
    source_sheet,
    COUNT(*) AS total_rows,
    MIN(invoice_date) AS earliest_date,
    MAX(invoice_date) AS latest_date,
    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS missing_customer_rows,
    COUNT(*) FILTER (
        WHERE description IS NULL
    ) AS missing_description_rows,
    COUNT(*) FILTER (
        WHERE quantity < 0
    ) AS negative_quantity_rows,
    COUNT(*) FILTER (
        WHERE unit_price = 0
    ) AS zero_price_rows,
    COUNT(*) FILTER (
        WHERE UPPER(invoice) LIKE 'C%'
    ) AS cancellation_rows
FROM raw.retail_transactions
GROUP BY source_sheet
ORDER BY source_sheet;