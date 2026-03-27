-- ============================================
-- Financial Transaction Data Quality Analysis
-- Author: Shivansh Vaid
-- Tools: SQL (SQLite compatible)
-- Dataset: Bank Transaction Dataset (Kaggle)
-- ============================================

-- ============================================
-- QUERY 1: Overall dataset overview
-- ============================================
SELECT
    COUNT(*)                        AS total_transactions,
    COUNT(DISTINCT transaction_id)  AS unique_ids,
    COUNT(*) - COUNT(DISTINCT transaction_id) AS duplicate_ids,
    ROUND(
        (COUNT(*) - COUNT(DISTINCT transaction_id)) * 100.0
        / COUNT(*), 2
    )                               AS duplicate_rate_pct,
    ROUND(AVG(amount), 2)           AS avg_transaction_amount,
    MAX(amount)                     AS max_amount,
    MIN(amount)                     AS min_amount
FROM transactions;


-- ============================================
-- QUERY 2: Null value check across key fields
-- ============================================
SELECT
    SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END) AS null_ids,
    SUM(CASE WHEN amount        IS NULL THEN 1 ELSE 0 END) AS null_amounts,
    SUM(CASE WHEN merchant      IS NULL THEN 1 ELSE 0 END) AS null_merchants,
    SUM(CASE WHEN category      IS NULL THEN 1 ELSE 0 END) AS null_categories,
    SUM(CASE WHEN date          IS NULL THEN 1 ELSE 0 END) AS null_dates,
    COUNT(*)                                                AS total_records
FROM transactions;


-- ============================================
-- QUERY 3: Duplicate transaction IDs
-- ============================================
SELECT
    transaction_id,
    COUNT(*) AS occurrences
FROM transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 20;


-- ============================================
-- QUERY 4: Transaction failure rate by category
-- ============================================
SELECT
    category,
    COUNT(*)                                              AS total,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END)  AS failed,
    SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) AS success,
    ROUND(
        SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                                                    AS failure_rate_pct
FROM transactions
GROUP BY category
ORDER BY failure_rate_pct DESC;


-- ============================================
-- QUERY 5: High-value transaction detection
-- ============================================
-- Flags transactions more than 3 standard deviations
-- above the mean amount (outlier threshold)
WITH stats AS (
    SELECT
        AVG(amount)                       AS mean_amount,
        AVG(amount) + 3 * STDEV(amount)  AS outlier_threshold
    FROM transactions
)
SELECT
    t.transaction_id,
    t.amount,
    t.category,
    t.merchant,
    t.date,
    t.status,
    ROUND(s.outlier_threshold, 2) AS threshold_used
FROM transactions t, stats s
WHERE t.amount > s.outlier_threshold
ORDER BY t.amount DESC;


-- ============================================
-- QUERY 6: Daily transaction volume trend
-- ============================================
SELECT
    DATE(date)              AS transaction_date,
    COUNT(*)                AS total_transactions,
    SUM(amount)             AS total_volume,
    ROUND(AVG(amount), 2)   AS avg_amount,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS failed_count
FROM transactions
GROUP BY DATE(date)
ORDER BY transaction_date;


-- ============================================
-- QUERY 7: Reconciliation gap summary
-- Total records that need manual review
-- ============================================
SELECT
    'Duplicate IDs'    AS issue_type,
    COUNT(*) - COUNT(DISTINCT transaction_id) AS affected_records
FROM transactions
UNION ALL
SELECT
    'Null Merchant'    AS issue_type,
    SUM(CASE WHEN merchant IS NULL THEN 1 ELSE 0 END)
FROM transactions
UNION ALL
SELECT
    'High-Value Unreviewed' AS issue_type,
    SUM(CASE WHEN amount > 10000 THEN 1 ELSE 0 END)
FROM transactions;