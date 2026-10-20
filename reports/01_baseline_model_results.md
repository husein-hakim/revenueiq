# RevenueIQ: Baseline Churn Model Results

## Objective

Predict which recently active customers will make no qualifying purchase during the following 90 days, using only purchase history available before the prediction cutoff.

The outcome represents **90-day purchase inactivity**, rather than confirmed permanent churn.

## Dataset and preparation

Source: [UCI Online Retail II](https://archive.ics.uci.edu/dataset/502/online+retail+ii), covering December 2009 through December 2011.

Dataset attribution: Chen, D. (2012). *Online Retail II*. UCI Machine Learning Repository. https://doi.org/10.24432/C5CG6D. Licensed under CC BY 4.0.

The raw import contains 1,067,371 transaction lines across two sheets. Data quality checks reconciled imported row counts, date ranges, missing values, negative quantities, zero prices, and cancellation counts against the workbook.

Cross-sheet comparison identified 22,523 repeated transaction lines, representing 22,202 distinct business patterns. Every shared pattern had equal multiplicity in both sheets. The staging view retains the first sheet’s copies and excludes matching copies from the second, leaving 1,044,848 lines. Repeated lines within the retained sheet remain intact. Raw records are preserved.

A qualifying customer purchase line must have:

- A customer identifier.
- Positive quantity.
- Positive unit price.
- An invoice number that does not begin with `C`, ignoring case.

This produces 791,045 eligible lines, aggregated into 36,969 orders for 5,878 customers. Positive purchase value totals £17,431,551.178. This measure excludes returns and unidentified customers; it is not total business revenue.

Invoice checks found 64 invoices with multiple timestamps. All occurred within one calendar day, with gaps of one or two minutes. Customer and country were consistent. Each invoice is treated as one order, using its earliest eligible line timestamp and retaining its latest line timestamp.

## Modeling population and target

A customer is eligible at a cutoff if they have at least one qualifying order during the preceding 180 days.

The binary target is:

- **0:** at least one qualifying order during the following 90 days.
- **1:** no qualifying order during the following 90 days.

Future windows include their starting timestamp and exclude their ending timestamp.

## Temporal evaluation design

| Split | Prediction cutoff | Label window end, exclusive | Customers | Purchased again | Inactive |
|---|---|---|---:|---:|---:|
| Training | 1 March 2011 | 30 May 2011 | 3,349 | 1,416 | 1,933 |
| Validation | 1 June 2011 | 30 August 2011 | 2,659 | 1,331 | 1,328 |
| Test | 1 September 2011 | 30 November 2011 | 2,772 | 1,683 | 1,089 |

Training labels finish before the validation cutoff, and validation labels finish before the test cutoff. All label windows fit within the observed dataset.

Customers may appear in multiple snapshots, reflecting repeated predictions for existing customers. Each modeling row is identified by customer ID and cutoff date.

Historical features include only orders whose latest eligible line timestamp precedes the cutoff. Scaling and model fitting use training data only. Customer identifiers, cutoff dates, split names, and future outcomes are excluded from model inputs.

Checks confirmed one row per eligible customer snapshot, exactly one label per snapshot, no missing labels, and no nonfinite model inputs.

## Features

| Feature | Definition |
|---|---|
| `recency_days` | Calendar days since the most recent qualifying order |
| `order_count` | Number of qualifying historical orders |
| `purchase_value` | Total historical positive purchase value |
| `avg_order_value` | Average positive purchase value per order |
| `observed_tenure_days` | Calendar days since the first observed qualifying order |
| `orders_last_90_days` | Orders during the 90 days immediately before the cutoff |
| `purchase_value_last_90_days` | Positive purchase value during the preceding 90 days |
| `orders_previous_90_days` | Orders between 180 and 90 days before the cutoff |

Historical totals cover the available dataset history, not customers’ complete lifetimes. Recent windows include their start and exclude their end.

## Models and benchmarks

### Majority-class baseline

A scikit-learn `DummyClassifier(strategy="most_frequent")` predicts the most common training outcome: inactivity.

It ignores customer features and predicts class 1 for every customer.

### Logistic regression

The model uses a scikit-learn pipeline containing:

1. `StandardScaler`.
2. `LogisticRegression(max_iter=2000)`.

Classification uses a fixed probability threshold of 0.5.

### Recency targeting benchmark

For a fixed outreach budget, customers are ranked by days since their most recent purchase, with the longest-inactive customers selected first.

Both targeting methods use the same budget: the top 20% of eligible customers, rounded up. Customer ID breaks ranking ties consistently.

## Classification results

Precision and recall below refer to inactivity, class 1.

| Metric | Validation dummy | Validation logistic regression | Test logistic regression |
|---|---:|---:|---:|
| Accuracy | 0.499 | 0.687 | 0.650 |
| Balanced accuracy | 0.500 | 0.688 | 0.663 |
| Precision | 0.499 | 0.667 | 0.541 |
| Recall | 1.000 | 0.747 | 0.725 |
| ROC AUC | — | 0.754 | 0.730 |

The dummy achieves perfect inactivity recall by flagging everyone, making it unsuitable for prioritizing limited outreach.

Logistic regression improves validation classification performance and retains useful discrimination on the later test snapshot. Performance declines between validation and test.

For context, predicting “purchased again” for every test customer would achieve 60.7% accuracy. Logistic regression achieves 65.0%.

### Test confusion matrix

| Actual outcome | Predicted purchased again | Predicted inactive |
|---|---:|---:|
| Purchased again | 1,012 | 671 |
| Inactive | 299 | 790 |

At the 0.5 threshold, the model flags 1,461 test customers, identifying 790 of the 1,089 inactive customers.

## Targeting performance at a 20% budget

| Split | Method | Selected | Inactive identified | Precision | Recall | Lift |
|---|---|---:|---:|---:|---:|---:|
| Validation | Logistic regression | 532 | 403 | 0.758 | 0.303 | 1.517 |
| Validation | Recency rule | 532 | 370 | 0.695 | 0.279 | 1.393 |
| Test | Logistic regression | 555 | 366 | 0.659 | 0.336 | 1.679 |
| Test | Recency rule | 555 | 343 | 0.618 | 0.315 | 1.573 |

Lift is the selected group’s inactivity rate divided by the overall inactivity rate for that snapshot.

At the same test targeting budget, logistic regression identifies **23 additional inactive customers** compared with recency alone, approximately **6.7% more**. Precision improves by approximately 4.1 percentage points.

Selecting approximately 20% of test customers captures 33.6% of inactive customers.

This demonstrates improved prioritization on the observed test snapshot. It does not establish that outreach would prevent inactivity.

## Model interpretation

Standardized coefficients show that:

- More historical and recent orders are associated with lower predicted inactivity risk.
- Longer recency is associated with higher predicted risk.
- Longer observed tenure is associated with lower predicted risk.

These are conditional associations, not causal effects. Several features overlap mathematically or statistically, so individual coefficients should not be treated as definitive feature-importance rankings.

## Limitations

- Evaluation uses one training, validation, and test snapshot. Results may vary across other periods.
- Inactivity rates change from 57.7% in training to 49.9% in validation and 39.3% in test. The cause has not been established.
- Some eligible customers were already inactive for more than 90 days at the prediction cutoff. The task includes predicting continued inactivity, rather than only the onset of inactivity.
- Returns and cancellations are excluded from purchase features. Positive purchase value may overstate a customer’s retained economic value.
- The dataset has a fixed observation window. First observed purchase may not be the customer’s first-ever purchase.
- Newer customers have less opportunity to accumulate historical activity.
- The 180-day eligibility window, 90-day outcome window, and 20% targeting budget are initial assumptions.
- Probability calibration and statistical uncertainty around performance differences have not been evaluated.
- The model predicts observed purchase behavior, not responsiveness