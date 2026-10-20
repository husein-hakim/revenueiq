CREATE SCHEMA IF NOT EXISTS staging;

CREATE OR REPLACE VIEW staging.retail_transactions AS
SELECT later.*
FROM raw.retail_transactions AS later
WHERE NOT (
    later.source_sheet = 'Year 2010-2011'

    AND EXISTS (
        SELECT 1
        FROM raw.retail_transactions AS earlier
        WHERE earlier.source_file = later.source_file
          AND earlier.source_sheet = 'Year 2009-2010'

          AND ROW(
              earlier.invoice,
              earlier.stock_code,
              earlier.description,
              earlier.quantity,
              earlier.invoice_date,
              earlier.unit_price,
              earlier.customer_id,
              earlier.country
          ) IS NOT DISTINCT FROM ROW(
              later.invoice,
              later.stock_code,
              later.description,
              later.quantity,
              later.invoice_date,
              later.unit_price,
              later.customer_id,
              later.country
          )
    )
);