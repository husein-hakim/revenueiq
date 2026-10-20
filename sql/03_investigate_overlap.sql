WITH matching_patterns AS (
    SELECT
        invoice,
        stock_code,
        description,
        quantity,
        invoice_date,
        unit_price,
        customer_id,
        country,

        COUNT(*) FILTER (
            WHERE source_sheet = 'Year 2009-2010'
        ) AS copies_first_sheet,

        COUNT(*) FILTER (
            WHERE source_sheet = 'Year 2010-2011'
        ) AS copies_second_sheet

    FROM raw.retail_transactions
    WHERE source_file = 'online_retail_II.xlsx'

    GROUP BY
        invoice,
        stock_code,
        description,
        quantity,
        invoice_date,
        unit_price,
        customer_id,
        country
)
SELECT
    COUNT(*) AS shared_business_patterns,

    SUM(copies_first_sheet) AS matching_rows_first_sheet,

    SUM(copies_second_sheet) AS matching_rows_second_sheet,

    COUNT(*) FILTER (
        WHERE copies_first_sheet <> copies_second_sheet
    ) AS patterns_with_different_copy_counts,

    MIN(invoice_date) AS earliest_shared_date,
    MAX(invoice_date) AS latest_shared_date

FROM matching_patterns
WHERE copies_first_sheet > 0
  AND copies_second_sheet > 0;