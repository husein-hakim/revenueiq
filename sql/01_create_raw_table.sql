CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE raw.retail_transactions (
    raw_row_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    source_file TEXT NOT NULL,
    source_sheet TEXT NOT NULL,
    source_row_number INTEGER NOT NULL,

    invoice TEXT,
    stock_code TEXT,
    description TEXT,
    quantity INTEGER,
    invoice_date TIMESTAMP WITHOUT TIME ZONE,
    unit_price NUMERIC,
    customer_id TEXT,
    country TEXT,

    ingested_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT unique_source_row
        UNIQUE (source_file, source_sheet, source_row_number)
);