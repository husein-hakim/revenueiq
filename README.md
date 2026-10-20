# RevenueIQ

A retail analytics portfolio project using Python, PostgreSQL, and machine learning to turn messy transaction data into customer purchase histories and inactivity predictions.

**Status:** In progress. Ingestion, SQL transformations, customer features, and a first temporally evaluated model are implemented. Cohort analysis and workflow automation are next.

## Business question

Which recently active customers are likely to make no purchase during the next 90 days?

RevenueIQ predicts **90-day purchase inactivity**, rather than confirmed permanent churn. It also evaluates whether predicted risk can prioritize customers more effectively than a simple recency rule.

## Dataset

[UCI Online Retail II](https://archive.ics.uci.edu/dataset/502/online+retail+ii) contains real transactions from a UK online retailer between December 2009 and December 2011.

The workbook includes missing customer identifiers, cancellations, negative quantities, unusual prices, and overlapping records across two sheets.

Download the workbook from the dataset page and place it at:

```text
data/raw/online_retail_II.xlsx
```

The workbook is excluded from Git. Keep the downloaded source unchanged.

**Attribution:** Chen, D. (2012). *Online Retail II*. UCI Machine Learning Repository. https://doi.org/10.24432/C5CG6D. Licensed under CC BY 4.0.

## Pipeline

```text
Original Excel workbook
    → Python ingestion
    → PostgreSQL raw transaction table
    → Cross-sheet overlap handling
    → Eligible purchase lines
    → Customer orders
    → Historical customer snapshots
    → Future inactivity labels
    → Temporal model evaluation
```

Raw records remain intact. SQL views define transformations, and a materialized order view avoids repeatedly computing expensive aggregations.

## Implemented

- Source workbook exploration and data quality profiling.
- Batched Python ingestion into PostgreSQL.
- Source-row tracking and duplicate import protection.
- SQL checks reconciled against workbook summaries.
- Cross-sheet overlap analysis and a documented exclusion rule.
- Purchase-line and order-level views.
- Historical customer features at three prediction cutoffs.
- Future 90-day inactivity labels.
- Majority-class and recency benchmarks.
- Logistic regression with training-only feature scaling.
- Validation and test evaluation, including fixed-budget targeting.

Current checks include SQL reconciliation queries and notebook assertions. A standalone automated test suite is not yet implemented.

## Data preparation decisions

| Stage | Records |
|---|---:|
| Raw transaction lines | 1,067,371 |
| Lines after cross-sheet overlap handling | 1,044,848 |
| Eligible customer purchase lines | 791,045 |
| Orders from eligible purchase lines | 36,969 |
| Customers with eligible purchases | 5,878 |

The source sheets share 22,523 transaction lines with matching multiplicities. The staging view keeps the first sheet’s copies and excludes matching copies from the second sheet. Repeated lines within the retained sheet remain intact.

Eligible purchase lines require:

- A known customer ID.
- Positive quantity.
- Positive unit price.
- An invoice number that does not begin with `C`, ignoring case.

These rules measure positive customer purchase activity. They do not calculate net revenue after returns.

Invoice checks found 64 invoices with multiple timestamps, all within one or two minutes on the same day. Each invoice is treated as one order using its earliest eligible line timestamp; the latest timestamp is also retained.

## Features and target

A customer is eligible for prediction if they purchased at least once in the preceding 180 days.

Features describe purchase history available before each cutoff:

- Days since the most recent order.
- Historical order count and positive purchase value.
- Average order value.
- Observed customer tenure.
- Order count and purchase value in the last 90 days.
- Order count in the preceding 90-day window.

The target is:

- **0:** at least one qualifying purchase in the following 90 days.
- **1:** no qualifying purchase in that window.

Historical totals cover available dataset history, rather than complete customer lifetimes.

## Temporal evaluation

| Split | Prediction cutoff | Label window end, exclusive | Customers |
|---|---|---|---:|
| Training | 1 March 2011 | 30 May 2011 | 3,349 |
| Validation | 1 June 2011 | 30 August 2011 | 2,659 |
| Test | 1 September 2011 | 30 November 2011 | 2,772 |

Features exclude orders whose latest eligible line timestamp is at or after the cutoff. Labels use future purchases separately. Scaling and model fitting use training data only.

Customers may appear in multiple periods, reflecting repeated predictions for existing customers. The modeling key is customer ID plus cutoff date.

## First model results

The first model uses `StandardScaler` followed by logistic regression.

| Metric | Validation | Test |
|---|---:|---:|
| Accuracy | 0.687 | 0.650 |
| Balanced accuracy | 0.688 | 0.663 |
| Inactivity precision | 0.667 | 0.541 |
| Inactivity recall | 0.747 | 0.725 |
| ROC AUC | 0.754 | 0.730 |

Classification metrics use a probability threshold of 0.5.

### Targeting the highest-risk 20%

On the test snapshot, both methods select 555 customers:

| Method | Inactive customers identified | Precision | Lift over random selection |
|---|---:|---:|---:|
| Logistic regression | 366 | 65.9% | 1.68× |
| Recency rule | 343 | 61.8% | 1.57× |

Logistic regression identifies **23 additional inactive customers**, approximately **6.7% more than recency alone**, at the same targeting budget.

These results measure predictive prioritization. They do not establish that a retention campaign would change customer behavior or generate incremental revenue.

See [the model results report](reports/01_baseline_model_results.md) for methodology and limitations.

## Project structure

```text
revenueiq/
├── README.md
├── .gitignore
├── requirements.txt
├── data/
│   ├── raw/
│   └── processed/
├── notebooks/
│   ├── 01_data_understanding.ipynb
│   └── 02_churn_modeling.ipynb
├── src/
│   └── revenueiq/
├── sql/
├── tests/
└── reports/
    └── 01_baseline_model_results.md
```

The `src/` and `tests/` directories are reserved for extracting reusable pipeline code and automated tests from the current notebook workflow.

## Local setup

### 1. Create a Python environment

From the project root:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
```

### 2. Start PostgreSQL

The current development setup uses Postgres.app on macOS.

Create a database named `revenueiq` and ensure the server is running. Update notebook connection strings to use your local PostgreSQL username and authentication settings.

Do not commit credentials.

### 3. Download the dataset

Place the original workbook at:

```text
data/raw/online_retail_II.xlsx
```

### 4. Run the current workflow

The workflow currently requires manual execution:

1. Run `sql/01_create_raw_table.sql`.
2. Run the exploration and ingestion cells in `notebooks/01_data_understanding.ipynb`.
3. Execute the remaining SQL files in their documented dependency order.
4. Run `notebooks/02_churn_modeling.ipynb`.

The overlap view uses an index on the raw table’s source file, source sheet, and invoice columns. Create that index before running expensive overlap queries.

Create `analytics.customer_orders_cached` after the order view and before queries that depend on it:

```sql
CREATE MATERIALIZED VIEW analytics.customer_orders_cached AS
SELECT *
FROM analytics.customer_orders;

CREATE INDEX idx_cached_customer_order_date
ON analytics.customer_orders_cached (customer_id, order_date);

ANALYZE analytics.customer_orders_cached;
```

Create the cache once. If source data or order transformation rules change, refresh it before downstream analysis:

```sql
REFRESH MATERIALIZED VIEW analytics.customer_orders_cached;
ANALYZE analytics.customer_orders_cached;
```

Run notebooks from their `notebooks/` directory, or adjust their project-root paths accordingly.

An end-to-end runner and fully verified clean-environment setup are planned.

## Limitations

- Evaluation covers one training, validation, and test snapshot.
- Inactivity rates differ between periods; their causes have not been established.
- The outcome includes continued inactivity among customers already inactive for more than 90 days.
- Purchase features exclude returns and cancellations.
- Missing customer IDs prevent some transactions from contributing to customer histories.
- First observed purchase may not be the customer’s first-ever purchase.
- Eligibility and outcome windows are initial assumptions.
- Probability calibration and uncertainty around performance differences have not been evaluated.
- The first model is frozen following test evaluation. Further changes require fresh temporal evaluation.

## Next steps

- Build monthly cohort retention analysis.
- Extract ingestion into reusable Python code.
- Add automated tests for ingestion and transformation behavior.
- Document and verify the complete SQL execution order.
- Add a repeatable end-to-end workflow.
- Preserve model artifacts and experiment configuration.
- Evaluate future improvements across additional temporal snapshots.