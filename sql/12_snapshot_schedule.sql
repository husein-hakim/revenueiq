CREATE TABLE analytics.snapshot_schedule (
    cutoff_date TIMESTAMP WITHOUT TIME ZONE PRIMARY KEY,
    dataset_split TEXT NOT NULL UNIQUE,
    CHECK (dataset_split IN ('train', 'validation', 'test'))
);

INSERT INTO analytics.snapshot_schedule (
    cutoff_date,
    dataset_split
)
VALUES
    ('2011-03-01 00:00:00', 'train'),
    ('2011-06-01 00:00:00', 'validation'),
    ('2011-09-01 00:00:00', 'test')
ON CONFLICT (cutoff_date) DO NOTHING;