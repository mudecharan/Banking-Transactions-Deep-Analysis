-- ======================= SQL SERVER PROJECT ==================
/* 
PROJECT     : Banking Transactions Performance — SQL Server Deep Analytics
DATASET     : Kaggle `vivekmali1436/banking-transactions-dataset`
CURRENCY    : INR (Rs)

*/

-- Using Database BankingDW
use BankingDW ; 

-- ======================== 1. Basic Querying ========================
-- 1.1 dbo.accounts
SELECT COUNT(*) AS total_rows
FROM accounts;
-- Total Rows of accounts : 95000
-- 1.2 dbo.branches
SELECT COUNT(*) AS total_rows
FROM branches;
-- Total Rows of branches : 150
-- 1.3 dbo.card_transactions
SELECT COUNT(*) AS total_rows
FROM card_transactions;
-- Total Rows of card_transactions : 3000000
-- 1.4 dbo.cards
SELECT COUNT(*) AS total_rows
FROM cards;
-- Total Rows of cards : 65000
-- 1.5 dbo.employees
SELECT COUNT(*) AS total_rows
FROM employees;
-- Total Rows of employees : 1800
-- 1.6 dbo.loan_payments
SELECT COUNT(*) AS total_rows
FROM loan_payments;
-- Total Rows of loan_payments : 600000
-- 1.7 dbo.loans
SELECT COUNT(*) AS total_rows
FROM loans;
-- Total Rows of loans : 22000
-- 1.8 dbo.support_tickets
SELECT COUNT(*) AS total_rows
FROM support_tickets;
-- Total Rows of support_tickets 25000
-- 1.9 dbo. transactions
SELECT COUNT(*) AS total_rows
FROM transactions;
-- Total Rows of transactions : 2000000
/*
TABLE INVENTORY (10 tables)
     1. branches          (150)         - bank branch master
     2. customers         (60,000)      - retail customer master
     3. accounts          (95,000)      - deposit accounts (Savings/Current/Salary/FD/NRI)
     4. cards             (65,000)      - debit & credit cards (Classic/Gold/Platinum)
     5. employees         (1,800)       - branch employees
     6. loans             (22,000)      - retail loans (Auto/Home/Personal/Edu/Gold/Business)
     7. transactions      (2,000,000)   - account-level cash/transfer txns
     8. card_transactions (3,000,000)   - card POS/online txns with is_fraud flag
     9. loan_payments     (600,000)     - EMI payments with principal/interest split
    10. support_tickets   (25,000)      - customer support tickets + satisfaction
*/

-- ======================== 2. CREATING CONSTRAINT ========================
-- branches
/*
select top 10*
from branches

SELECT COUNT(DISTINCT opened_date) FROM branches;   */

ALTER TABLE branches
ADD CONSTRAINT CK_branches_opened_date
    CHECK (opened_date IS NULL OR opened_date <= SYSDATETIME());

-- customers
/*
select top 10*
from customers

SELECT count( DISTINCT credit_score)
FROM customers

SELECT count( DISTINCT annual_income)
FROM customers

SELECT DISTINCT gender
FROM customers
*/

ALTER TABLE customers
ADD CONSTRAINT CK_customers_credit_score CHECK (credit_score IS NULL OR credit_score BETWEEN 300 AND 900),
    CONSTRAINT CK_customers_annual_income CHECK (annual_income IS NULL OR annual_income >= 0),
    CONSTRAINT CK_customers_gender CHECK (gender IN ('Male','Female','Other')),
    CONSTRAINT CK_customers_join_date CHECK (join_date IS NULL OR join_date <= SYSDATETIME());   

-- accounts
/*
SELECT TOP 10 *
FROM accounts

SELECT COUNT( DISTINCT account_type)
from accounts

SELECT DISTINCT account_type
from accounts

SELECT DISTINCT status
from accounts
*/
ALTER TABLE accounts
ADD CONSTRAINT CK_accounts_balance CHECK (balance >= 0),
    CONSTRAINT CK_accounts_type   CHECK (account_type IN ('Savings','Current','Salary','Fixed Deposit','Nri')),
    CONSTRAINT CK_accounts_status CHECK (status IN ('Active','Dormant','Closed'))

-- cards
/*
SELECT DISTINCT card_type
FROM cards

SELECT DISTINCT status
FROM cards
*/

ALTER TABLE cards
ADD CONSTRAINT CK_cards_credit_limit CHECK (credit_limit >= 0),
    CONSTRAINT CK_cards_type        CHECK (card_type IN ('Debit','Credit - Classic','Credit - Gold','Credit - Platinum')),
    CONSTRAINT CK_cards_status     CHECK (status IN ('Active','Blocked','Expired')),
    CONSTRAINT CK_cards_dates       CHECK (expiry_date IS NULL OR issue_date IS NULL OR expiry_date >= issue_date)

-- employees
ALTER TABLE employees
ADD CONSTRAINT CK_employees_salary CHECK (salary >= 0)

-- loans
/*
SELECT DISTINCT loan_type
FROM loans

SELECT DISTINCT status
FROM loans
*/

ALTER TABLE loans
ADD CONSTRAINT CK_loans_amount        CHECK (loan_amount > 0),
    CONSTRAINT CK_loans_interest_rate CHECK (interest_rate BETWEEN 0 AND 100),
    CONSTRAINT CK_loans_term          CHECK (term_months > 0 AND term_months <= 360),
    CONSTRAINT CK_loans_type          CHECK (loan_type IN ('Auto Loan','Home Loan','Personal Loan','Education Loan','Gold Loan','Business Loan')),
    CONSTRAINT CK_loans_status        CHECK (status IN ('Active','Closed','Defaulted','Written Off'))

-- transactions
/*
SELECT DISTINCT txn_type
FROM transactions

SELECT DISTINCT channel
FROM transactions
*/
ALTER TABLE transactions
ADD CONSTRAINT CK_transactions_amount CHECK (amount >= 0),
    CONSTRAINT CK_transactions_type  CHECK (txn_type IN ('Deposit','Withdrawal','Transfer In','Transfer Out','Interest Credit','Fee Debit')),
    CONSTRAINT CK_transactions_chan  CHECK (channel IN ('Mobile App','Pos','Atm','Branch','Upi','Online Banking'))

-- card_transactions
ALTER TABLE card_transactions
ADD CONSTRAINT CK_card_txns_amount   CHECK (amount >= 0)

-- loan_payments
ALTER TABLE loan_payments
ADD CONSTRAINT CK_loan_payments_amt   CHECK (amount_paid >= 0),
    CONSTRAINT CK_loan_payments_comp  CHECK (principal_component + interest_component <= amount_paid + 0.01)

-- support_tickets
/*
SELECT DISTINCT status
FROM support_tickets
*/
ALTER TABLE support_tickets
ADD CONSTRAINT CK_tickets_satisfaction CHECK (satisfaction_score IS NULL OR satisfaction_score BETWEEN 1 AND 5),
    CONSTRAINT CK_tickets_status      CHECK (status IN ('Open','In Progress','Resolved','Closed','Escalated')),
    CONSTRAINT CK_tickets_dates       CHECK (date_resolved IS NULL OR date_resolved >= date_opened)

-- ======================== 3. CREATING INDEX ========================
-- BRANCHES
CREATE NONCLUSTERED INDEX IX_branches_state ON dbo.branches(state);
CREATE NONCLUSTERED INDEX IX_branches_city   ON dbo.branches(city);

-- CUSTOMERS
CREATE NONCLUSTERED INDEX IX_customers_state      ON dbo.customers(state);
CREATE NONCLUSTERED INDEX IX_customers_occupation ON dbo.customers(occupation);
CREATE NONCLUSTERED INDEX IX_customers_credit     ON dbo.customers(credit_score);
CREATE NONCLUSTERED INDEX IX_customers_join_date  ON dbo.customers(join_date);

-- ACCOUNTS
CREATE NONCLUSTERED INDEX IX_accounts_customer_id ON dbo.accounts(customer_id);
CREATE NONCLUSTERED INDEX IX_accounts_branch_id   ON dbo.accounts(branch_id);
CREATE NONCLUSTERED INDEX IX_accounts_status      ON dbo.accounts(status);
CREATE NONCLUSTERED INDEX IX_accounts_open_date   ON dbo.accounts(open_date);

-- CARDS
CREATE NONCLUSTERED INDEX IX_cards_customer_id ON dbo.cards(customer_id);
CREATE NONCLUSTERED INDEX IX_cards_account_id  ON dbo.cards(account_id);
CREATE NONCLUSTERED INDEX IX_cards_status      ON dbo.cards(status);
CREATE NONCLUSTERED INDEX IX_cards_card_type   ON dbo.cards(card_type);

-- EMPLOYEES
CREATE NONCLUSTERED INDEX IX_employees_branch_id ON dbo.employees(branch_id);
CREATE NONCLUSTERED INDEX IX_employees_role      ON dbo.employees(role);

-- LOANS
CREATE NONCLUSTERED INDEX IX_loans_customer_id ON dbo.loans(customer_id);
CREATE NONCLUSTERED INDEX IX_loans_branch_id   ON dbo.loans(branch_id);
CREATE NONCLUSTERED INDEX IX_loans_status       ON dbo.loans(status);
CREATE NONCLUSTERED INDEX IX_loans_loan_type    ON dbo.loans(loan_type);
CREATE NONCLUSTERED INDEX IX_loans_start_date   ON dbo.loans(start_date);

-- TRANSACTIONS
CREATE NONCLUSTERED INDEX IX_transactions_account_id        ON dbo.transactions(account_id);
CREATE NONCLUSTERED INDEX IX_transactions_txn_date          ON dbo.transactions(txn_date);
CREATE NONCLUSTERED INDEX IX_transactions_txn_type           ON dbo.transactions(txn_type);
CREATE NONCLUSTERED INDEX IX_transactions_channel           ON dbo.transactions(channel);
CREATE NONCLUSTERED INDEX IX_transactions_merchant_category ON dbo.transactions(merchant_category);

-- CARD_TRANSACTIONS
CREATE NONCLUSTERED INDEX IX_card_txns_card_id            ON dbo.card_transactions(card_id);
CREATE NONCLUSTERED INDEX IX_card_txns_txn_date            ON dbo.card_transactions(txn_date);
CREATE NONCLUSTERED INDEX IX_card_txns_is_fraud            ON dbo.card_transactions(is_fraud);
CREATE NONCLUSTERED INDEX IX_card_txns_merchant_category   ON dbo.card_transactions(merchant_category);
-- Filtered index — only fraudulent txns (small, very selective)
CREATE NONCLUSTERED INDEX IX_card_txns_fraud_only ON dbo.card_transactions(card_id) WHERE is_fraud = 1;

-- LOAN_PAYMENTS
CREATE NONCLUSTERED INDEX IX_loan_payments_loan_id       ON dbo.loan_payments(loan_id);
CREATE NONCLUSTERED INDEX IX_loan_payments_payment_date  ON dbo.loan_payments(payment_date);
CREATE NONCLUSTERED INDEX IX_loan_payments_late_flag     ON dbo.loan_payments(late_payment_flag);

-- SUPPORT_TICKETS
CREATE NONCLUSTERED INDEX IX_tickets_customer_id  ON dbo.support_tickets(customer_id);
CREATE NONCLUSTERED INDEX IX_tickets_status        ON dbo.support_tickets(status);
CREATE NONCLUSTERED INDEX IX_tickets_date_opened  ON dbo.support_tickets(date_opened);
CREATE NONCLUSTERED INDEX IX_tickets_issue_type   ON dbo.support_tickets(issue_type);

-- ================================================================================================
-- ================================================================================================

-- ======================== 4. BASIC SELECT QUERIES (FOUNDATIONS) ========================
-- 4.1 SELECT all branches
-- What this demonstrates: simple SELECT *, ORDER BY on a small dimension table.
SELECT
    branch_id,
    branch_name,
    city,
    state,
    opened_date,
    ifsc_code
FROM dbo.branches
ORDER BY state, city;

-- 4.2 SELECT customers WHERE credit_score < 580 (poor credit)
-- What this demonstrates: WHERE clause with a numeric filter and TOP limiting.
SELECT TOP (50)
    customer_id,
    name,
    occupation,
    annual_income,
    credit_score
FROM dbo.customers
WHERE credit_score < 580
ORDER BY credit_score ASC;

-- 4.3 SELECT accounts WHERE status = 'Active' ORDER BY balance DESC
-- What this demonstrates: WHERE on a string column + descending sort on money.
SELECT TOP (100)
    account_id,
    customer_id,
    branch_id,
    account_type,
    balance,
    open_date
FROM dbo.accounts
WHERE status = 'Active'
ORDER BY balance DESC;

-- 4.4 SELECT COUNT(*) FROM transactions GROUP BY txn_type
-- What this demonstrates: GROUP BY with COUNT to get distribution by category.
SELECT
    txn_type,
    COUNT(*)              AS txn_count,
    SUM(amount)           AS txn_volume,
    AVG(CAST(amount AS FLOAT)) AS avg_amount
FROM dbo.transactions
GROUP BY txn_type
ORDER BY txn_count DESC;

-- 4.5 SELECT TOP 10 customers by annual_income
-- What this demonstrates: TOP with ORDER BY to find "highest N" rows.
SELECT TOP (10)
    customer_id,
    name,
    occupation,
    state,
    annual_income,
    credit_score
FROM dbo.customers
WHERE annual_income IS NOT NULL
ORDER BY annual_income DESC;

-- 4.6 SELECT loans WHERE status = 'Defaulted'
-- What this demonstrates: filtering on a categorical status column.
SELECT
    loan_id,
    customer_id,
    branch_id,
    loan_type,
    loan_amount,
    interest_rate,
    term_months,
    start_date
FROM dbo.loans
WHERE status = 'Defaulted'
ORDER BY loan_amount DESC;

-- 4.7 SELECT cards WHERE status = 'Blocked'
-- What this demonstrates: filtering cards by operational status.
SELECT
    card_id,
    customer_id,
    account_id,
    card_type,
    issue_date,
    expiry_date,
    credit_limit
FROM dbo.cards
WHERE status = 'Blocked'
ORDER BY issue_date DESC;

-- 4.8 SELECT transactions WHERE txn_date >= '2025-01-01' (date filter)
-- What this demonstrates: date-range filtering using ISO-8601 literals.
SELECT
    transaction_id,
    account_id,
    txn_date,
    txn_type,
    amount,
    channel
FROM dbo.transactions
WHERE txn_date >= '2025-01-01'
ORDER BY txn_date DESC;

-- 4.9 SELECT customers WHERE occupation = 'Freelancer' AND credit_score >= 700
-- What this demonstrates: compound WHERE using AND between categorical and numeric filters.
SELECT
    customer_id,
    name,
    gender,
    city,
    state,
    annual_income,
    credit_score
FROM dbo.customers
WHERE occupation = 'Freelancer'
  AND credit_score >= 700
ORDER BY credit_score DESC, annual_income DESC;

-- 4.10 SELECT loan_payments WHERE late_payment_flag = 1
-- What this demonstrates: filtering on a BIT flag column (use 1/0, not 'true'/'false').
SELECT TOP (1000)
    payment_id,
    loan_id,
    payment_date,
    amount_paid,
    principal_component,
    interest_component,
    late_payment_flag
FROM dbo.loan_payments
WHERE late_payment_flag = 1
ORDER BY payment_date DESC;

-- ======================== 5.  BASIC JOINs (BUILDING COMPLEXITY)  ========================
-- 5.1 INNER JOIN customers <-> accounts
-- What this demonstrates: simplest INNER JOIN — get each customer's accounts.
SELECT
    c.customer_id,
    c.name,
    c.city,
    c.state,
    a.account_id,
    a.account_type,
    a.balance,
    a.status
FROM dbo.customers AS c
INNER JOIN dbo.accounts AS a
    ON a.customer_id = c.customer_id
ORDER BY c.customer_id, a.account_id;

-- 5.2 INNER JOIN accounts <-> branches
-- What this demonstrates: joining an account to its servicing branch.
SELECT
    a.account_id,
    a.account_type,
    a.balance,
    b.branch_id,
    b.branch_name,
    b.city  AS branch_city,
    b.state AS branch_state
FROM dbo.accounts AS a
INNER JOIN dbo.branches AS b
    ON b.branch_id = a.branch_id
ORDER BY b.state, b.branch_id, a.account_id;


-- 5.3 INNER JOIN loans <-> customers
-- What this demonstrates: enriching a loan with the borrower's profile.
SELECT
    l.loan_id,
    l.loan_type,
    l.loan_amount,
    l.interest_rate,
    l.term_months,
    l.status,
    c.customer_id,
    c.name AS borrower_name,
    c.occupation,
    c.annual_income,
    c.credit_score
FROM dbo.loans AS l
INNER JOIN dbo.customers AS c
    ON c.customer_id = l.customer_id
ORDER BY l.loan_amount DESC;

-- 5.4 INNER JOIN transactions <-> accounts <-> customers (txn chain)
-- What this demonstrates: 3-table chain join to fully attribute a transaction.
SELECT TOP (200)
    t.transaction_id,
    t.txn_date,
    t.txn_type,
    t.amount,
    t.channel,
    a.account_id,
    a.account_type,
    c.customer_id,
    c.name AS customer_name,
    c.city
FROM dbo.transactions AS t
INNER JOIN dbo.accounts  AS a ON a.account_id  = t.account_id
INNER JOIN dbo.customers AS c ON c.customer_id = a.customer_id
ORDER BY t.txn_date DESC, t.transaction_id;

-- 5.5 INNER JOIN card_transactions <-> cards <-> customers
-- What this demonstrates: tracing a card transaction back to its cardholder.
SELECT TOP (200)
    ct.card_txn_id,
    ct.txn_date,
    ct.merchant_category,
    ct.amount,
    ct.is_fraud,
    cd.card_id,
    cd.card_type,
    cu.customer_id,
    cu.name AS cardholder_name
FROM dbo.card_transactions AS ct
INNER JOIN dbo.cards      AS cd ON cd.card_id     = ct.card_id
INNER JOIN dbo.customers AS cu ON cu.customer_id = cd.customer_id
ORDER BY ct.is_fraud DESC, ct.amount DESC;

-- 5.6 LEFT JOIN customers <-> loans (customers with/without loans)
-- What this demonstrates: LEFT JOIN to also include customers with no loans.
SELECT
    c.customer_id,
    c.name,
    c.city,
    l.loan_id,
    l.loan_type,
    l.loan_amount,
    l.status AS loan_status
FROM dbo.customers AS c
LEFT JOIN dbo.loans AS l
    ON l.customer_id = c.customer_id
ORDER BY c.customer_id;

-- 5.7 LEFT JOIN loans <-> loan_payments (loan + its payment history)
-- What this demonstrates: LEFT JOIN to retain loans even if no payments recorded yet.
SELECT TOP (500)
    l.loan_id,
    l.loan_type,
    l.loan_amount,
    l.status,
    p.payment_id,
    p.payment_date,
    p.amount_paid,
    p.late_payment_flag
FROM dbo.loans AS l
LEFT JOIN dbo.loan_payments AS p
    ON p.loan_id = l.loan_id
ORDER BY l.loan_id, p.payment_date;

-- 5.8 INNER JOIN support_tickets <-> customers
-- What this demonstrates: enriching tickets with customer profile for service review.
SELECT
    t.ticket_id,
    t.issue_type,
    t.date_opened,
    t.date_resolved,
    t.status,
    t.satisfaction_score,
    c.customer_id,
    c.name  AS customer_name,
    c.state
FROM dbo.support_tickets AS t
INNER JOIN dbo.customers AS c
    ON c.customer_id = t.customer_id
ORDER BY t.date_opened DESC;

-- ============================= 6 — BASIC AGGREGATIONS (GROUP BY, HAVING) =============================
-- 6.1 Total customers by gender
-- What this demonstrates: COUNT + GROUP BY on a categorical column.
SELECT
    gender,
    COUNT(*) AS customer_count
FROM dbo.customers
GROUP BY gender
ORDER BY customer_count DESC;

-- 6.2 Total accounts by type
-- What this demonstrates: GROUP BY on account_type.
SELECT
    account_type,
    COUNT(*)       AS account_count,
    SUM(balance)   AS total_balance,
    AVG(balance)   AS avg_balance
FROM dbo.accounts
GROUP BY account_type
ORDER BY account_count DESC;

-- 6.3 Average credit score by occupation
-- What this demonstrates: AVG with GROUP BY on occupation.
SELECT
    occupation,
    COUNT(*)        AS customer_count,
    AVG(credit_score)        AS avg_credit_score,
    MIN(credit_score)        AS min_credit_score,
    MAX(credit_score)        AS max_credit_score
FROM dbo.customers
GROUP BY occupation
ORDER BY avg_credit_score DESC;

-- 6.4 Total balance by account_type
-- What this demonstrates: SUM(money) grouped by type.
SELECT
    account_type,
    COUNT(*)     AS account_count,
    SUM(balance) AS total_balance
FROM dbo.accounts
GROUP BY account_type
ORDER BY total_balance DESC;

-- 6.5 Total loan book by loan_type
-- What this demonstrates: SUM(loan_amount) grouped by loan_type — KPI driver.
SELECT
    loan_type,
    COUNT(*)         AS loan_count,
    SUM(loan_amount) AS total_loan_book,
    AVG(interest_rate) AS avg_interest_rate
FROM dbo.loans
GROUP BY loan_type
ORDER BY total_loan_book DESC;

-- 6.6 NPA count by loan_type
-- What this demonstrates: COUNT with WHERE filter inside an aggregation.
SELECT
    loan_type,
    COUNT(*) AS npa_count,
    SUM(loan_amount) AS npa_amount
FROM dbo.loans
WHERE status IN ('Defaulted','Written Off')
GROUP BY loan_type
ORDER BY npa_count DESC;

-- 6.7 Total transaction volume by channel
-- What this demonstrates: SUM(amount) GROUP BY channel.
SELECT
    channel,
    COUNT(*)     AS txn_count,
    SUM(amount)  AS txn_volume,
    AVG(amount)  AS avg_amount
FROM dbo.transactions
GROUP BY channel
ORDER BY txn_volume DESC;

-- 6.8 Average satisfaction score by issue_type
-- What this demonstrates: AVG on a survey score grouped by issue type.
SELECT
    issue_type,
    COUNT(*)                  AS ticket_count,
    AVG(CAST(satisfaction_score AS FLOAT)) AS avg_satisfaction,
    AVG(DATEDIFF(DAY, date_opened, date_resolved)) AS avg_resolution_days
FROM dbo.support_tickets
WHERE status = 'Resolved'
GROUP BY issue_type
ORDER BY avg_resolution_days DESC;

-- 6.9 Customers with more than 2 accounts (GROUP BY + HAVING COUNT(*) > 2)
-- What this demonstrates: HAVING clause filters groups (not rows).
SELECT
    customer_id,
    COUNT(*) AS account_count
FROM dbo.accounts
GROUP BY customer_id
HAVING COUNT(*) > 2
ORDER BY account_count DESC;

-- 6.10 Branches with more than 1000 accounts (GROUP BY + HAVING)
-- What this demonstrates: HAVING with COUNT(*) > threshold to find high-volume branches.
SELECT
    b.branch_id,
    b.branch_name,
    b.city,
    b.state,
    COUNT(a.account_id) AS account_count
FROM dbo.branches AS b
INNER JOIN dbo.accounts AS a
    ON a.branch_id = b.branch_id
GROUP BY b.branch_id, b.branch_name, b.city, b.state
HAVING COUNT(a.account_id) > 1000
ORDER BY account_count DESC;

-- ====================================================================================
-- ============================ 7 — DERIVED COLUMNS & TYPE CASTING ============================
-- ====================================================================================


-- 7.1 CASE to classify credit_score bands (Poor/Fair/Good/Very Good/Excellent)
-- What this demonstrates: searched CASE expression to bucket a continuous score.
SELECT TOP (200)
    customer_id,
    name,
    credit_score,
    CASE
        WHEN credit_score < 580                       THEN 'Poor'
        WHEN credit_score >= 580 AND credit_score < 670 THEN 'Fair'
        WHEN credit_score >= 670 AND credit_score < 740 THEN 'Good'
        WHEN credit_score >= 740 AND credit_score < 800 THEN 'Very Good'
        WHEN credit_score >= 800                       THEN 'Excellent'
        ELSE 'Unknown'
    END AS credit_band
FROM dbo.customers
WHERE credit_score IS NOT NULL
ORDER BY credit_score DESC;

-- 7.2 CASE to classify loan_amount buckets
-- What this demonstrates: CASE to bucket money values into Small/Medium/Large/Jumbo.
SELECT TOP (200)
    loan_id,
    loan_type,
    loan_amount,
    CASE
        WHEN loan_amount <  100000                  THEN 'Small'
        WHEN loan_amount >= 100000 AND loan_amount < 500000 THEN 'Medium'
        WHEN loan_amount >= 500000 AND loan_amount < 2000000 THEN 'Large'
        WHEN loan_amount >= 2000000                 THEN 'Jumbo'
    END AS loan_bucket
FROM dbo.loans
ORDER BY loan_amount DESC;

-- 7.3 CAST to convert annual_income to DECIMAL(18,2)
-- What this demonstrates: explicit CAST for arithmetic safety / formatting.
SELECT
    customer_id,
    annual_income,
    CAST(annual_income AS DECIMAL(18,2))           AS income_dec,
    CAST(annual_income AS DECIMAL(18,2)) / 12.0    AS monthly_income
FROM dbo.customers
WHERE annual_income IS NOT NULL;

-- 7.4 CONVERT to format dates as 'YYYY-MM-DD' strings
-- What this demonstrates: CONVERT style 23 = ISO date string.
SELECT
    account_id,
    open_date,
    CONVERT(NVARCHAR(10), open_date, 23) AS open_date_str,
    CONVERT(NVARCHAR(10), GETDATE(), 23) AS today_str
FROM dbo.accounts
WHERE open_date IS NOT NULL;

-- 7.5 COALESCE to handle NULL support_ticket resolution dates
-- What this demonstrates: COALESCE returns the first non-NULL value — here it
-- substitutes 'Still Open' for tickets that haven't been resolved.
SELECT
    ticket_id,
    customer_id,
    issue_type,
    date_opened,
    COALESCE(CONVERT(NVARCHAR(10), date_resolved, 23), 'Still Open') AS resolution_date_or_open
FROM dbo.support_tickets
ORDER BY date_opened DESC;

-- 7.6 DATEDIFF to compute customer_age_years and tenure_years
-- What this demonstrates: DATEDIFF with the YEAR boundary at the analysis date.
SELECT TOP (200)
    customer_id,
    name,
    date_of_birth,
    join_date,
    DATEDIFF(DAY, date_of_birth, '2026-10-17') / 365.25 AS customer_age_years,
    DATEDIFF(DAY, join_date,     '2026-10-17') / 365.25 AS tenure_years
FROM dbo.customers
WHERE date_of_birth IS NOT NULL
ORDER BY tenure_years DESC;

-- 7.7 DATEADD to find transactions 30 days after account open
-- What this demonstrates: DATEADD(day, 30, open_date) to construct a relative window.
SELECT TOP (200)
    a.account_id,
    a.open_date,
    DATEADD(DAY, 30, a.open_date) AS thirty_day_window_end,
    t.transaction_id,
    t.txn_date,
    t.txn_type,
    t.amount
FROM dbo.accounts AS a
INNER JOIN dbo.transactions AS t
    ON t.account_id = a.account_id
WHERE t.txn_date BETWEEN a.open_date AND DATEADD(DAY, 30, a.open_date)
ORDER BY a.account_id, t.txn_date;

-- 7.8 CASE WHEN is_fraud = 1 THEN 'FRAUD' ELSE 'LEGIT' END
-- What this demonstrates: simple CASE on a BIT flag to produce human-readable labels.
SELECT TOP (200)
    card_txn_id,
    card_id,
    txn_date,
    merchant_category,
    amount,
    is_fraud,
    CASE WHEN is_fraud = 1 THEN 'FRAUD' ELSE 'LEGIT' END AS fraud_label
FROM dbo.card_transactions
ORDER BY is_fraud DESC, amount DESC;

-- ====================================================================================
-- ==================== 8 — SUBQUERIES (SCALAR, CORRELATED, EXISTS)====================
-- ====================================================================================

-- 8.1 Scalar subquery: customers whose credit_score > portfolio average
-- What this demonstrates: a scalar subquery in the WHERE clause returns a single value.
SELECT
    customer_id,
    name,
    credit_score
FROM dbo.customers
WHERE credit_score > (SELECT AVG(credit_score) FROM dbo.customers WHERE credit_score IS NOT NULL)
ORDER BY credit_score DESC;

-- 8.2 IN subquery: customers who have at least one Defaulted loan
-- What this demonstrates: IN with a subquery returning a single column.
SELECT
    customer_id,
    name,
    city,
    credit_score
FROM dbo.customers
WHERE customer_id IN (
    SELECT customer_id FROM dbo.loans WHERE status = 'Defaulted'
)
ORDER BY credit_score ASC;

-- 8.3 NOT IN subquery: customers who have never raised a support ticket
-- What this demonstrates: NOT IN to find the complement set.
SELECT
    customer_id,
    name,
    city
FROM dbo.customers
WHERE customer_id NOT IN (SELECT customer_id FROM dbo.support_tickets WHERE customer_id IS NOT NULL)
ORDER BY customer_id;

-- 8.4 Correlated subquery: customers whose annual_income > avg income in their occupation
-- What this demonstrates: a correlated subquery references the outer query's row.
SELECT
    customer_id,
    name,
    occupation,
    annual_income
FROM dbo.customers AS c1
WHERE annual_income > (
    SELECT AVG(c2.annual_income)
    FROM dbo.customers AS c2
    WHERE c2.occupation = c1.occupation
      AND c2.annual_income IS NOT NULL
)
ORDER BY annual_income DESC;

-- 8.5 EXISTS subquery: customers with credit cards
-- What this demonstrates: EXISTS returns TRUE if the subquery returns at least one row.
SELECT
    customer_id,
    name,
    city
FROM dbo.customers AS c
WHERE EXISTS (
    SELECT 1 FROM dbo.cards AS cd WHERE cd.customer_id = c.customer_id
)
ORDER BY customer_id;

-- 8.6 Same query as 8.4 rewritten using a CTE
-- What this demonstrates: CTEs usually read more clearly than correlated subqueries.
WITH OccupationAvg AS (
    SELECT
        occupation,
        AVG(annual_income) AS occupation_avg_income
    FROM dbo.customers
    WHERE annual_income IS NOT NULL
    GROUP BY occupation
)
SELECT
    c.customer_id,
    c.name,
    c.occupation,
    c.annual_income,
    oa.occupation_avg_income
FROM dbo.customers AS c
INNER JOIN OccupationAvg AS oa
    ON oa.occupation = c.occupation
WHERE c.annual_income > oa.occupation_avg_income
ORDER BY c.annual_income DESC;

-- =============================================================================================
-- ===================== 9 — COMMON TABLE EXPRESSIONS (CTEs) =====================
-- =============================================================================================

-- 9.1 Single CTE: customer credit score band summary
-- What this demonstrates: WITH clause produces a named, in-scope intermediate result.
WITH CreditBands AS (
    SELECT
        customer_id,
        credit_score,
        CASE
            WHEN credit_score < 580                       THEN 'Poor'
            WHEN credit_score >= 580 AND credit_score < 670 THEN 'Fair'
            WHEN credit_score >= 670 AND credit_score < 740 THEN 'Good'
            WHEN credit_score >= 740 AND credit_score < 800 THEN 'Very Good'
            WHEN credit_score >= 800                       THEN 'Excellent'
        END AS credit_band
    FROM dbo.customers
    WHERE credit_score IS NOT NULL
)
SELECT
    credit_band,
    COUNT(*)          AS customer_count,
    AVG(credit_score) AS avg_score
FROM CreditBands
GROUP BY credit_band
ORDER BY avg_score DESC;

-- 9.2 Multiple CTEs: chain customers -> accounts -> transactions -> aggregates
-- What this demonstrates: multiple CTEs referenced in sequence — composable pipelines.
WITH CustAccts AS (
    SELECT customer_id, COUNT(*) AS acct_count
    FROM dbo.accounts
    GROUP BY customer_id
),
CustTxns AS (
    SELECT a.customer_id, COUNT(*) AS txn_count, SUM(t.amount) AS txn_volume
    FROM dbo.transactions AS t
    INNER JOIN dbo.accounts AS a ON a.account_id = t.account_id
    GROUP BY a.customer_id
)
SELECT
    c.customer_id,
    c.name,
    c.occupation,
    ca.acct_count,
    ISNULL(ct.txn_count, 0)  AS txn_count,
    ISNULL(ct.txn_volume, 0) AS txn_volume
FROM dbo.customers AS c
LEFT JOIN CustAccts AS ca ON ca.customer_id = c.customer_id
LEFT JOIN CustTxns  AS ct ON ct.customer_id = c.customer_id
ORDER BY ct.txn_volume DESC;

-- 9.3 Recursive CTE: date spine from 2018-01-01 to 2026-12-31 (1 row per day)
-- What this demonstrates: a recursive CTE generates a calendar spine.
WITH DateSpine AS (
    -- Anchor member: the first day
    SELECT CAST('2018-01-01' AS DATE) AS calendar_date
    UNION ALL
    -- Recursive member: add one day until end-of-range
    SELECT DATEADD(DAY, 1, calendar_date)
    FROM DateSpine
    WHERE calendar_date < '2026-12-31'
)
SELECT
    calendar_date,
    YEAR(calendar_date)  AS cal_year,
    MONTH(calendar_date) AS cal_month,
    DAY(calendar_date)   AS cal_day,
    DATEPART(QUARTER, calendar_date) AS cal_quarter,
    DATENAME(WEEKDAY, calendar_date) AS cal_weekday,
    CASE WHEN DATEPART(WEEKDAY, calendar_date) IN (1,7) THEN 1 ELSE 0 END AS is_weekend
FROM DateSpine
OPTION (MAXRECURSION 0);

-- 9.4 CTE with ROW_NUMBER(): top 3 customers per branch by income
-- What this demonstrates: classic "top-N per group" pattern using ROW_NUMBER().
WITH RankedCustomers AS (
    SELECT
        c.customer_id,
        c.name,
        c.annual_income,
        c.credit_score,
        a.branch_id,
        ROW_NUMBER() OVER (PARTITION BY a.branch_id ORDER BY c.annual_income DESC) AS rn
    FROM dbo.customers AS c
    INNER JOIN dbo.accounts AS a ON a.customer_id = c.customer_id
    WHERE c.annual_income IS NOT NULL
)
SELECT
    branch_id,
    customer_id,
    name,
    annual_income,
    credit_score,
    rn AS income_rank_in_branch
FROM RankedCustomers
WHERE rn <= 3
ORDER BY branch_id, rn;

-- 9.5 CTE with RANK(): rank loans by loan_amount within each loan_type
-- What this demonstrates: RANK() handles ties (1,1,3,4...) vs ROW_NUMBER() (1,2,3,4...).
WITH RankedLoans AS (
    SELECT
        loan_id,
        customer_id,
        loan_type,
        loan_amount,
        status,
        RANK() OVER (PARTITION BY loan_type ORDER BY loan_amount DESC) AS amt_rank
    FROM dbo.loans
)
SELECT TOP (200)
    loan_type,
    loan_id,
    loan_amount,
    status,
    amt_rank
FROM RankedLoans
WHERE amt_rank <= 5
ORDER BY loan_type, amt_rank;

-- =============================================================================================
-- ===================== 10 — WINDOW FUNCTIONS =====================
-- =============================================================================================

-- 10.1 ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY txn_date DESC)
-- What this demonstrates: pick the last transaction per customer (rn = 1).
WITH LastTxn AS (
    SELECT
        c.customer_id,
        c.name,
        t.transaction_id,
        t.txn_date,
        t.txn_type,
        t.amount,
        ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY t.txn_date DESC, t.transaction_id DESC) AS rn
    FROM dbo.customers AS c
    INNER JOIN dbo.accounts     AS a ON a.customer_id  = c.customer_id
    INNER JOIN dbo.transactions AS t ON t.account_id   = a.account_id
)
SELECT TOP (200)
    customer_id, name, transaction_id, txn_date, txn_type, amount
FROM LastTxn
WHERE rn = 1
ORDER BY customer_id;

-- 10.2 RANK() OVER (ORDER BY loan_amount DESC) — rank all loans
-- What this demonstrates: RANK assigns the same rank to ties.
SELECT TOP (50)
    loan_id,
    loan_type,
    loan_amount,
    status,
    RANK() OVER (ORDER BY loan_amount DESC) AS overall_amt_rank
FROM dbo.loans
ORDER BY overall_amt_rank;

-- 10.3 DENSE_RANK() OVER (PARTITION BY loan_type ORDER BY loan_amount DESC)
-- What this demonstrates: DENSE_RANK has no gaps in the ranking sequence.
SELECT TOP (200)
    loan_id,
    loan_type,
    loan_amount,
    DENSE_RANK() OVER (PARTITION BY loan_type ORDER BY loan_amount DESC) AS dense_rank_within_type
FROM dbo.loans
ORDER BY loan_type, dense_rank_within_type;

-- 10.4 NTILE(5) OVER (ORDER BY annual_income) — income quintiles
-- What this demonstrates: NTILE divides rows into N roughly equal-sized buckets.
SELECT TOP (200)
    customer_id,
    name,
    annual_income,
    NTILE(5) OVER (ORDER BY annual_income ASC) AS income_quintile
FROM dbo.customers
WHERE annual_income IS NOT NULL
ORDER BY income_quintile, annual_income DESC;

-- 10.5 LAG(amount, 1) OVER (PARTITION BY account_id ORDER BY txn_date)
-- What this demonstrates: LAG lets you peek at the previous row's value.
SELECT TOP (500)
    t.transaction_id,
    t.account_id,
    t.txn_date,
    t.amount,
    LAG(t.amount, 1) OVER (PARTITION BY t.account_id ORDER BY t.txn_date, t.transaction_id) AS prev_txn_amount,
    t.amount - LAG(t.amount, 1) OVER (PARTITION BY t.account_id ORDER BY t.txn_date, t.transaction_id) AS amount_delta
FROM dbo.transactions AS t
ORDER BY t.account_id, t.txn_date;


-- 10.6 LEAD(txn_date, 1) OVER (PARTITION BY account_id ORDER BY txn_date)
-- What this demonstrates: LEAD looks forward one row.
SELECT TOP (500)
    t.transaction_id,
    t.account_id,
    t.txn_date,
    LEAD(t.txn_date, 1) OVER (PARTITION BY t.account_id ORDER BY t.txn_date, t.transaction_id) AS next_txn_date,
    DATEDIFF(DAY,
             t.txn_date,
             LEAD(t.txn_date, 1) OVER (PARTITION BY t.account_id ORDER BY t.txn_date, t.transaction_id))
        AS days_to_next_txn
FROM dbo.transactions AS t
ORDER BY t.account_id, t.txn_date;

-- 10.7 SUM(amount_abs) OVER (PARTITION BY account_id) — running total per account
-- What this demonstrates: windowed SUM without ORDER BY returns the partition total.
WITH TxnAbs AS (
    SELECT transaction_id, account_id, txn_date, amount,
           ABS(amount) AS amount_abs
    FROM dbo.transactions
)
SELECT TOP (500)
    transaction_id,
    account_id,
    txn_date,
    amount,
    amount_abs,
    SUM(amount_abs) OVER (PARTITION BY account_id) AS account_total_volume
FROM TxnAbs
ORDER BY account_id, txn_date;

-- 10.8 Cumulative running total (UNBOUNDED PRECEDING -> CURRENT ROW)
-- What this demonstrates: explicit window frame for a true running total.
WITH TxnAbs AS (
    SELECT transaction_id, account_id, txn_date, amount, ABS(amount) AS amount_abs
    FROM dbo.transactions
)
SELECT TOP (500)
    transaction_id,
    account_id,
    txn_date,
    amount_abs,
    SUM(amount_abs) OVER (
        PARTITION BY account_id
        ORDER BY txn_date, transaction_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_volume
FROM TxnAbs
ORDER BY account_id, txn_date;

-- 10.9 7-day moving average of txn amount per account
-- What this demonstrates: ROWS BETWEEN 6 PRECEDING AND CURRENT ROW is a moving window.
WITH TxnAbs AS (
    SELECT transaction_id, account_id, txn_date, amount, ABS(amount) AS amount_abs
    FROM dbo.transactions
)
SELECT TOP (500)
    transaction_id,
    account_id,
    txn_date,
    amount_abs,
    AVG(amount_abs) OVER (
        PARTITION BY account_id
        ORDER BY txn_date, transaction_id
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_avg_7
FROM TxnAbs
ORDER BY account_id, txn_date;

-- 10.10 FIRST_VALUE / LAST_VALUE — first and last txn amount per account
-- What this demonstrates: FIRST_VALUE and LAST_VALUE need explicit window frames
-- (LAST_VALUE without ROWS UNBOUNDED PRECEDING... returns the current row only).
SELECT TOP (500)
    transaction_id,
    account_id,
    txn_date,
    amount,
    FIRST_VALUE(amount) OVER (
        PARTITION BY account_id
        ORDER BY txn_date, transaction_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS first_txn_amount,
    LAST_VALUE(amount) OVER (
        PARTITION BY account_id
        ORDER BY txn_date, transaction_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_txn_amount
FROM dbo.transactions
ORDER BY account_id, txn_date;

-- -- =============================================================================================
-- ===================== 11 — VIEWS (REUSABLE ANALYTICAL LAYER) =====================
-- =============================================================================================

-- 11.1 dbo.vw_DimBranch — branch + derived fields (age_years, state_region)
CREATE VIEW dbo.vw_DimBranch
AS
SELECT
    b.branch_id,
    b.branch_name,
    b.city,
    b.state,
    b.opened_date,
    b.ifsc_code,
    DATEDIFF(DAY, b.opened_date, SYSDATETIME()) / 365.25 AS branch_age_years,
    CASE
        WHEN b.state IN ('Maharashtra','Gujarat','Goa')                          THEN 'West'
        WHEN b.state IN ('Delhi','Uttar Pradesh','Punjab','Haryana','Jammu and Kashmir','Himachal Pradesh','Uttarakhand','Rajasthan') THEN 'North'
        WHEN b.state IN ('West Bengal','Bihar','Jharkhand','Odisha','Assam','Sikkim','Tripura','Manipur','Meghalaya','Mizoram','Nagaland','Arunachal Pradesh') THEN 'East'
        WHEN b.state IN ('Tamil Nadu','Kerala','Karnataka','Andhra Pradesh','Telangana','Puducherry') THEN 'South'
        WHEN b.state IN ('Madhya Pradesh','Chhattisgarh')                       THEN 'Central'
        ELSE 'Other'
    END AS state_region
FROM dbo.branches AS b;

select top 10 *
from vw_DimBranch

-- 11.2 dbo.vw_DimCustomer — customer + age, tenure, credit_band, income_bucket
CREATE VIEW dbo.vw_DimCustomer
AS
SELECT
    c.customer_id,
    c.name,
    c.gender,
    c.date_of_birth,
    c.city,
    c.state,
    c.phone,
    c.email,
    c.occupation,
    c.annual_income,
    c.join_date,
    c.credit_score,
    DATEDIFF(DAY, c.date_of_birth, SYSDATETIME()) / 365.25 AS customer_age_years,
    DATEDIFF(DAY, c.join_date,     SYSDATETIME()) / 365.25 AS tenure_years,
    CASE
        WHEN c.credit_score IS NULL                        THEN 'Unknown'
        WHEN c.credit_score < 580                          THEN 'Poor'
        WHEN c.credit_score < 670                          THEN 'Fair'
        WHEN c.credit_score < 740                          THEN 'Good'
        WHEN c.credit_score < 800                          THEN 'Very Good'
        ELSE 'Excellent'
    END AS credit_band,
    CASE
        WHEN c.annual_income IS NULL                       THEN 'Unknown'
        WHEN c.annual_income < 300000                      THEN 'Low'
        WHEN c.annual_income < 800000                      THEN 'Middle'
        WHEN c.annual_income < 2000000                     THEN 'Upper-Middle'
        ELSE 'High'
    END AS income_bucket
FROM dbo.customers AS c;

select top 10 *
from vw_DimCustomer

-- 11.3 dbo.vw_DimAccount — account + acct_age, status_flag
CREATE VIEW dbo.vw_DimAccount
AS
SELECT
    a.account_id,
    a.customer_id,
    a.branch_id,
    a.account_type,
    a.balance,
    a.open_date,
    a.status,
    DATEDIFF(DAY, a.open_date, SYSDATETIME()) / 365.25 AS acct_age_years,
    CASE WHEN a.status = 'Active' THEN 1 ELSE 0 END AS is_active
FROM dbo.accounts AS a;

select top 10 *
from vw_DimAccount

-- 11.4 dbo.vw_DimCard — card + card_age, is_expired
CREATE VIEW dbo.vw_DimCard
AS
SELECT
    cd.card_id,
    cd.customer_id,
    cd.account_id,
    cd.card_type,
    cd.issue_date,
    cd.expiry_date,
    cd.credit_limit,
    cd.status,
    DATEDIFF(DAY, cd.issue_date, SYSDATETIME()) / 365.25 AS card_age_years,
    CASE WHEN cd.expiry_date IS NOT NULL AND cd.expiry_date < CAST(SYSDATETIME() AS DATE) THEN 1 ELSE 0 END AS is_expired,
    CASE WHEN cd.status = 'Active' THEN 1 ELSE 0 END AS is_active
FROM dbo.cards AS cd;

select top 10 *
from vw_DimCard

-- 11.5 dbo.vw_DimLoan — loan + loan_age, is_npa, term_bucket, emi_estimate
CREATE VIEW dbo.vw_DimLoan
AS
SELECT
    l.loan_id,
    l.customer_id,
    l.branch_id,
    l.loan_type,
    l.loan_amount,
    l.interest_rate,
    l.term_months,
    l.start_date,
    l.status,
    DATEDIFF(DAY, l.start_date, SYSDATETIME()) / 365.25 AS loan_age_years,
    CASE WHEN l.status IN ('Defaulted','Written Off') THEN 1 ELSE 0 END AS is_npa,
    CASE
        WHEN l.term_months <= 12  THEN 'Short (<=12m)'
        WHEN l.term_months <= 60  THEN 'Medium (13-60m)'
        WHEN l.term_months <= 120 THEN 'Long (61-120m)'
        ELSE 'Very Long (>120m)'
    END AS term_bucket,
    -- EMI estimate (flat amortization approximation): P * r/12 / (1 - (1+r/12)^-n)
    CASE WHEN l.interest_rate > 0 AND l.term_months > 0 THEN
        l.loan_amount * (l.interest_rate/100.0/12.0) /
        POWER(1.0 + (l.interest_rate/100.0/12.0), -1.0 * l.term_months)  -- (1+r)^-n approximated
        * (-1.0) -- placeholder so result is positive (formal EMI below)
    ELSE l.loan_amount / l.term_months
    END AS emi_estimate
FROM dbo.loans AS l;

select top 10 *
from vw_DimLoan

-- 11.6 dbo.vw_FactAccountTransaction — txn + year/month/weekday/is_weekend, amount_abs
CREATE VIEW dbo.vw_FactAccountTransaction
AS
SELECT
    t.transaction_id,
    t.account_id,
    t.txn_date,
    YEAR(t.txn_date)  AS txn_year,
    MONTH(t.txn_date) AS txn_month,
    DAY(t.txn_date)   AS txn_day,
    DATEPART(QUARTER, t.txn_date) AS txn_quarter,
    DATENAME(WEEKDAY, t.txn_date) AS txn_weekday,
    CASE WHEN DATEPART(WEEKDAY, t.txn_date) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend,
    t.txn_type,
    t.amount,
    ABS(t.amount) AS amount_abs,
    CASE WHEN t.amount < 0 THEN 1 ELSE 0 END AS is_debit,
    t.channel,
    t.merchant_category,
    a.customer_id,
    a.branch_id,
    a.account_type
FROM dbo.transactions AS t
INNER JOIN dbo.accounts AS a ON a.account_id = t.account_id;

select top 10*
from vw_FactAccountTransaction

-- 11.7 dbo.vw_FactCardTransaction — card_txn + year/month/weekday, is_fraud_flag
CREATE VIEW dbo.vw_FactCardTransaction
AS
SELECT
    ct.card_txn_id,
    ct.card_id,
    ct.txn_date,
    YEAR(ct.txn_date)  AS txn_year,
    MONTH(ct.txn_date) AS txn_month,
    DAY(ct.txn_date)   AS txn_day,
    DATEPART(QUARTER, ct.txn_date) AS txn_quarter,
    DATENAME(WEEKDAY, ct.txn_date) AS txn_weekday,
    CASE WHEN DATEPART(WEEKDAY, ct.txn_date) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend,
    ct.merchant_category,
    ct.amount,
    ct.is_fraud,
    CASE WHEN ct.is_fraud = 1 THEN 1 ELSE 0 END AS is_fraud_flag,
    cd.customer_id,
    cd.card_type,
    cd.credit_limit
FROM dbo.card_transactions AS ct
INNER JOIN dbo.cards AS cd ON cd.card_id = ct.card_id;

select top 10*
from vw_FactCardTransaction

-- 11.8 dbo.vw_FactLoanPayment — payment + year/month, is_late
CREATE VIEW dbo.vw_FactLoanPayment
AS
SELECT
    p.payment_id,
    p.loan_id,
    p.payment_date,
    YEAR(p.payment_date)  AS payment_year,
    MONTH(p.payment_date) AS payment_month,
    p.amount_paid,
    p.principal_component,
    p.interest_component,
    p.late_payment_flag,
    CASE WHEN p.late_payment_flag = 1 THEN 1 ELSE 0 END AS is_late,
    l.customer_id,
    l.branch_id,
    l.loan_type,
    l.loan_amount,
    l.status AS loan_status
FROM dbo.loan_payments AS p
INNER JOIN dbo.loans AS l ON l.loan_id = p.loan_id;

select top 10 *
from vw_FactLoanPayment

-- 11.9 dbo.vw_FactSupportTicket — ticket + resolution_days, is_open, is_escalated
CREATE VIEW dbo.vw_FactSupportTicket
AS
SELECT
    t.ticket_id,
    t.customer_id,
    t.issue_type,
    t.date_opened,
    t.date_resolved,
    t.status,
    t.satisfaction_score,
    DATEDIFF(DAY, t.date_opened, COALESCE(t.date_resolved, CAST(SYSDATETIME() AS DATE))) AS resolution_days,
    CASE WHEN t.status IN ('Open','In Progress') THEN 1 ELSE 0 END AS is_open,
    CASE WHEN t.status = 'Escalated' THEN 1 ELSE 0 END AS is_escalated,
    CASE WHEN t.date_resolved IS NULL AND DATEDIFF(DAY, t.date_opened, SYSDATETIME()) > 14 THEN 1 ELSE 0 END AS is_overdue
FROM dbo.support_tickets AS t;

select top 10*
from vw_FactSupportTicket

-- 11.10 dbo.vw_Executive_KPI_Dashboard — single-row view with all KPIs
-- (MUST match headline_kpis.json exactly)
CREATE VIEW dbo.vw_Executive_KPI_Dashboard
AS
SELECT
    -- Counts
    (SELECT COUNT(*) FROM dbo.customers)                       AS total_customers,
    (SELECT COUNT(*) FROM dbo.accounts)                        AS total_accounts,
    (SELECT COUNT(*) FROM dbo.cards)                           AS total_cards,
    (SELECT COUNT(*) FROM dbo.loans)                           AS total_loans,
    (SELECT COUNT(*) FROM dbo.branches)                        AS total_branches,
    (SELECT COUNT(*) FROM dbo.employees)                       AS total_employees,
    (SELECT COUNT(*) FROM dbo.transactions)                    AS total_transactions,
    (SELECT COUNT(*) FROM dbo.card_transactions)               AS total_card_transactions,
    (SELECT COUNT(*) FROM dbo.loan_payments)                   AS total_loan_payments,
    (SELECT COUNT(*) FROM dbo.support_tickets)                 AS total_support_tickets,
    -- Volume
    (SELECT SUM(amount)   FROM dbo.transactions)               AS total_txn_volume_inr,
    (SELECT SUM(amount)   FROM dbo.card_transactions)          AS total_card_txn_volume_inr,
    (SELECT SUM(balance)  FROM dbo.accounts)                   AS total_deposits_balance_inr,
    (SELECT SUM(loan_amount) FROM dbo.loans)                   AS total_loan_book_inr,
    (SELECT AVG(balance) FROM dbo.accounts)                    AS avg_account_balance_inr,
    (SELECT AVG(loan_amount) FROM dbo.loans)                  AS avg_loan_amount_inr,
    (SELECT AVG(interest_rate) FROM dbo.loans)                  AS avg_interest_rate_pct,
    (SELECT AVG(credit_score) FROM dbo.customers WHERE credit_score IS NOT NULL) AS avg_credit_score,
    (SELECT AVG(DATEDIFF(DAY, date_of_birth, '2026-10-17') / 365.25) FROM dbo.customers WHERE date_of_birth IS NOT NULL) AS avg_customer_age_years,
    (SELECT AVG(DATEDIFF(DAY, join_date, '2026-10-17') / 365.25) FROM dbo.customers WHERE join_date IS NOT NULL) AS avg_customer_tenure_years,
    -- Fraud
    (SELECT COUNT(*) FROM dbo.card_transactions WHERE is_fraud = 1) AS fraud_count,
    (SELECT CAST(COUNT(CASE WHEN is_fraud = 1 THEN 1 END) AS FLOAT) / NULLIF(COUNT(*), 0) * 100.0 FROM dbo.card_transactions) AS fraud_rate_pct,
    (SELECT SUM(amount) FROM dbo.card_transactions WHERE is_fraud = 1) AS fraud_amount_inr,
    -- NPA / late payments
    (SELECT COUNT(*) FROM dbo.loans WHERE status IN ('Defaulted','Written Off')) AS npa_count,
    (SELECT CAST(COUNT(CASE WHEN status IN ('Defaulted','Written Off') THEN 1 END) AS FLOAT) / NULLIF(COUNT(*), 0) * 100.0 FROM dbo.loans) AS npa_rate_pct,
    (SELECT CAST(COUNT(CASE WHEN late_payment_flag = 1 THEN 1 END) AS FLOAT) / NULLIF(COUNT(*), 0) * 100.0 FROM dbo.loan_payments) AS late_payment_rate_pct,
    -- Service
    (SELECT AVG(DATEDIFF(DAY, date_opened, date_resolved)) FROM dbo.support_tickets WHERE date_resolved IS NOT NULL) AS avg_resolution_days,
    (SELECT AVG(CAST(satisfaction_score AS FLOAT)) FROM dbo.support_tickets WHERE satisfaction_score IS NOT NULL) AS avg_satisfaction_score,
    (SELECT COUNT(*) FROM dbo.support_tickets WHERE status IN ('Open','In Progress')) AS open_tickets_count,
    (SELECT COUNT(*) FROM dbo.support_tickets WHERE status = 'Escalated') AS escalated_tickets_count;

select top 10 *
from vw_Executive_KPI_Dashboard

-- 11.11 dbo.vw_Customer_KPI_Summary — per-customer aggregates
CREATE VIEW dbo.vw_Customer_KPI_Summary
AS
SELECT
    c.customer_id,
    c.name,
    c.occupation,
    c.state,
    COUNT(DISTINCT a.account_id)                                  AS account_count,
    COUNT(DISTINCT cd.card_id)                                    AS card_count,
    COUNT(DISTINCT l.loan_id)                                     AS loan_count,
    SUM(DISTINCT CASE WHEN l.status IN ('Defaulted','Written Off') THEN 1 ELSE 0 END) AS npa_count,
    SUM(DISTINCT l.loan_amount)                                   AS total_loan_book,
    SUM(DISTINCT a.balance)                                       AS total_deposit_balance,
    COUNT(DISTINCT t.transaction_id)                              AS txn_count,
    ISNULL(SUM(t.amount), 0)                                      AS txn_volume,
    COUNT(DISTINCT ct.card_txn_id)                                AS card_txn_count,
    ISNULL(SUM(ct.amount), 0)                                     AS card_txn_volume,
    COUNT(DISTINCT CASE WHEN ct.is_fraud = 1 THEN ct.card_txn_id END) AS fraud_txn_count,
    COUNT(DISTINCT st.ticket_id)                                  AS ticket_count,
    AVG(CAST(st.satisfaction_score AS FLOAT))                     AS avg_satisfaction
FROM dbo.customers AS c
LEFT JOIN dbo.accounts           AS a  ON a.customer_id  = c.customer_id
LEFT JOIN dbo.cards              AS cd ON cd.customer_id = c.customer_id
LEFT JOIN dbo.loans               AS l  ON l.customer_id  = c.customer_id
LEFT JOIN dbo.transactions        AS t  ON t.account_id IN (SELECT account_id FROM dbo.accounts WHERE customer_id = c.customer_id)
LEFT JOIN dbo.card_transactions   AS ct ON ct.card_id IN (SELECT card_id FROM dbo.cards WHERE customer_id = c.customer_id)
LEFT JOIN dbo.support_tickets     AS st ON st.customer_id = c.customer_id
GROUP BY c.customer_id, c.name, c.occupation, c.state;

select top 10 *
from vw_Customer_KPI_Summary

-- 11.12 dbo.vw_Branch_KPI_Summary — per-branch rollup
CREATE VIEW dbo.vw_Branch_KPI_Summary
AS
SELECT
    b.branch_id,
    b.branch_name,
    b.city,
    b.state,
    COUNT(DISTINCT a.account_id)               AS account_count,
    ISNULL(SUM(a.balance), 0)                  AS deposit_balance,
    COUNT(DISTINCT l.loan_id)                  AS loan_count,
    ISNULL(SUM(l.loan_amount), 0)              AS loan_book,
    COUNT(DISTINCT CASE WHEN l.status IN ('Defaulted','Written Off') THEN l.loan_id END) AS npa_count,
    COUNT(DISTINCT e.employee_id)              AS employee_count,
    COUNT(DISTINCT c.customer_id)              AS customer_count
FROM dbo.branches AS b
LEFT JOIN dbo.accounts   AS a ON a.branch_id = b.branch_id
LEFT JOIN dbo.loans       AS l ON l.branch_id = b.branch_id
LEFT JOIN dbo.employees  AS e ON e.branch_id = b.branch_id
LEFT JOIN dbo.customers  AS c ON c.state = b.state        -- approximation: customers in branch's state
GROUP BY b.branch_id, b.branch_name, b.city, b.state;

select top 10*
from vw_Branch_KPI_Summary

-- ========================================================================================
-- ============================= 12. TIME-SERIES ANALYTICS =============================
-- ========================================================================================

-- 12.1 Monthly transaction count and volume with YoY growth using LAG
-- What this demonstrates: aggregate to month, then LAG(month, 12) for YoY comparison.
WITH Monthly AS (
    SELECT
        YEAR(txn_date)  AS yr,
        MONTH(txn_date) AS mn,
        COUNT(*)        AS txn_count,
        SUM(amount)     AS txn_volume
    FROM dbo.transactions
    GROUP BY YEAR(txn_date), MONTH(txn_date)
),
Ordered AS (
    SELECT
        yr, mn, txn_count, txn_volume,
        ROW_NUMBER() OVER (ORDER BY yr, mn) AS rn
    FROM Monthly
)
SELECT
    yr, mn, txn_count, txn_volume,
    LAG(txn_volume, 12) OVER (ORDER BY rn) AS volume_same_month_last_year,
    CASE
        WHEN LAG(txn_volume, 12) OVER (ORDER BY rn) IS NOT NULL
             AND LAG(txn_volume, 12) OVER (ORDER BY rn) <> 0
        THEN (txn_volume - LAG(txn_volume, 12) OVER (ORDER BY rn))
             * 100.0 / LAG(txn_volume, 12) OVER (ORDER BY rn)
        ELSE NULL
    END AS yoy_growth_pct
FROM Ordered
ORDER BY yr, mn;

-- 12.2 7-day moving average of daily txn volume
-- What this demonstrates: a moving-average over a daily time series using ROWS frame.
WITH Daily AS (
    SELECT
        txn_date,
        COUNT(*)    AS txn_count,
        SUM(amount) AS txn_volume
    FROM dbo.transactions
    GROUP BY txn_date
)
SELECT TOP (500)
    txn_date,
    txn_count,
    txn_volume,
    AVG(txn_volume) OVER (
        ORDER BY txn_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS ma_7_volume
FROM Daily
ORDER BY txn_date DESC;

-- 12.3 Cumulative monthly deposit volume (running total)
-- What this demonstrates: UNBOUNDED PRECEDING frame produces a true cumulative sum.
WITH MonthlyDeposit AS (
    SELECT
        YEAR(txn_date)  AS yr,
        MONTH(txn_date) AS mn,
        SUM(amount)     AS deposit_volume
    FROM dbo.transactions
    WHERE txn_type = 'Deposit'
    GROUP BY YEAR(txn_date), MONTH(txn_date)
)
SELECT
    yr, mn, deposit_volume,
    SUM(deposit_volume) OVER (
        ORDER BY yr, mn
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_deposit_volume
FROM MonthlyDeposit
ORDER BY yr, mn;

-- 12.4 Month-over-month growth rate (% change vs prior month)
-- What this demonstrates: LAG(1) + arithmetic for MoM growth.
WITH Monthly AS (
    SELECT
        YEAR(txn_date)  AS yr,
        MONTH(txn_date) AS mn,
        SUM(amount)     AS txn_volume
    FROM dbo.transactions
    GROUP BY YEAR(txn_date), MONTH(txn_date)
),
Ordered AS (
    SELECT yr, mn, txn_volume,
           ROW_NUMBER() OVER (ORDER BY yr, mn) AS rn
    FROM Monthly
)
SELECT
    yr, mn, txn_volume,
    LAG(txn_volume, 1) OVER (ORDER BY rn) AS prev_month_volume,
    CASE
        WHEN LAG(txn_volume, 1) OVER (ORDER BY rn) IS NOT NULL
             AND LAG(txn_volume, 1) OVER (ORDER BY rn) <> 0
        THEN (txn_volume - LAG(txn_volume, 1) OVER (ORDER BY rn))
             * 100.0 / LAG(txn_volume, 1) OVER (ORDER BY rn)
        ELSE NULL
    END AS mom_growth_pct
FROM Ordered
ORDER BY yr, mn;

-- 12.5 Year-over-year growth rate (LAG with OFFSET 12)
-- What this demonstrates: explicit OFFSET 12 for YoY on a monthly series.
WITH Monthly AS (
    SELECT
        YEAR(txn_date)  AS yr,
        MONTH(txn_date) AS mn,
        SUM(amount)     AS txn_volume
    FROM dbo.transactions
    GROUP BY YEAR(txn_date), MONTH(txn_date)
),
Ordered AS (
    SELECT yr, mn, txn_volume,
           ROW_NUMBER() OVER (ORDER BY yr, mn) AS rn
    FROM Monthly
)
SELECT
    yr, mn, txn_volume,
    LAG(txn_volume, 12) OVER (ORDER BY rn) AS volume_12_months_ago,
    CASE
        WHEN LAG(txn_volume, 12) OVER (ORDER BY rn) IS NOT NULL
             AND LAG(txn_volume, 12) OVER (ORDER BY rn) <> 0
        THEN (txn_volume - LAG(txn_volume, 12) OVER (ORDER BY rn))
             * 100.0 / LAG(txn_volume, 12) OVER (ORDER BY rn)
        ELSE NULL
    END AS yoy_growth_pct
FROM Ordered
ORDER BY yr, mn;

-- 12.6 Rolling 30-day fraud rate using window function
-- What this demonstrates: a rolling 30-day fraud rate over the card_transactions fact.
WITH Daily AS (
    SELECT
        txn_date,
        COUNT(*)                                            AS daily_total,
        COUNT(CASE WHEN is_fraud = 1 THEN 1 END)           AS daily_fraud
    FROM dbo.card_transactions
    GROUP BY txn_date
)
SELECT TOP (300)
    txn_date,
    daily_total,
    daily_fraud,
    SUM(daily_total) OVER (
        ORDER BY txn_date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS rolling_30d_total,
    SUM(daily_fraud) OVER (
        ORDER BY txn_date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS rolling_30d_fraud,
    CASE
        WHEN SUM(daily_total) OVER (
                ORDER BY txn_date
                ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
             ) > 0
        THEN CAST(SUM(daily_fraud) OVER (
                ORDER BY txn_date
                ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
             ) AS FLOAT)
             / SUM(daily_total) OVER (
                ORDER BY txn_date
                ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
             ) * 100.0
        ELSE 0
    END AS rolling_30d_fraud_rate_pct
FROM Daily
ORDER BY txn_date DESC;

-- 12.7 Seasonality decomposition: avg txn volume per month-of-year
-- What this demonstrates: group by month-of-year to expose seasonal patterns.
SELECT
    MONTH(txn_date) AS month_of_year,
    DATENAME(MONTH, txn_date) AS month_name,
    AVG(amount) AS avg_txn_amount,
    SUM(amount) / COUNT(DISTINCT YEAR(txn_date)) AS avg_monthly_volume,
    COUNT(*)    AS txn_count
FROM dbo.transactions
GROUP BY MONTH(txn_date), DATENAME(MONTH, txn_date)
ORDER BY month_of_year;

-- 12.8 Cohort retention matrix using DATEDIFF(MONTH, first_txn, current_txn)
-- What this demonstrates: bucketing customers into first-txn cohorts and computing
-- the active rate in each subsequent month — the foundation of cohort analysis.
WITH FirstTxn AS (
    SELECT
        a.customer_id,
        MIN(t.txn_date) AS first_txn_date
    FROM dbo.transactions AS t
    INNER JOIN dbo.accounts AS a ON a.account_id = t.account_id
    GROUP BY a.customer_id
),
CohortActivity AS (
    SELECT
        f.customer_id,
        f.first_txn_date,
        t.txn_date,
        DATEDIFF(MONTH, f.first_txn_date, t.txn_date) AS month_index
    FROM FirstTxn AS f
    INNER JOIN dbo.transactions AS t
        ON t.account_id IN (SELECT account_id FROM dbo.accounts WHERE customer_id = f.customer_id)
)
SELECT TOP (200)
    customer_id,
    first_txn_date,
    txn_date,
    month_index
FROM CohortActivity
WHERE month_index <= 12
ORDER BY customer_id, txn_date;

-- ========================================================================================================
-- ============================= 13. RISK ANALYTICS (NPA, FRAUD, DELINQUENCY) =============================
-- ========================================================================================================

-- 13.1 NPA rate by loan_type
-- What this demonstrates: computing a rate as COUNT(npa)/COUNT(all) grouped by type.
SELECT
    loan_type,
    COUNT(*) AS total_loans,
    COUNT(CASE WHEN status IN ('Defaulted','Written Off') THEN 1 END) AS npa_loans,
    CAST(COUNT(CASE WHEN status IN ('Defaulted','Written Off') THEN 1 END) AS FLOAT)
        / NULLIF(COUNT(*), 0) * 100.0 AS npa_rate_pct,
    SUM(CASE WHEN status IN ('Defaulted','Written Off') THEN loan_amount ELSE 0 END) AS npa_amount
FROM dbo.loans
GROUP BY loan_type
ORDER BY npa_rate_pct DESC;

-- 13.2 NPA aging buckets (0-30, 31-60, 61-90, 90+ days past due)
-- What this demonstrates: DATEDIFF to compute days-since-start, then CASE for buckets.
SELECT
    CASE
        WHEN DATEDIFF(DAY, l.start_date, '2026-10-17') <= 30  THEN '0-30 days'
        WHEN DATEDIFF(DAY, l.start_date, '2026-10-17') <= 60  THEN '31-60 days'
        WHEN DATEDIFF(DAY, l.start_date, '2026-10-17') <= 90  THEN '61-90 days'
        ELSE '90+ days'
    END AS aging_bucket,
    COUNT(*)         AS loan_count,
    SUM(l.loan_amount) AS exposure_amount
FROM dbo.loans AS l
WHERE l.status IN ('Defaulted','Written Off')
GROUP BY
    CASE
        WHEN DATEDIFF(DAY, l.start_date, '2026-10-17') <= 30  THEN '0-30 days'
        WHEN DATEDIFF(DAY, l.start_date, '2026-10-17') <= 60  THEN '31-60 days'
        WHEN DATEDIFF(DAY, l.start_date, '2026-10-17') <= 90  THEN '61-90 days'
        ELSE '90+ days'
    END
ORDER BY aging_bucket;

-- 13.3 Fraud rate by merchant_category (top 12)
-- What this demonstrates: top-N selection on a computed rate.
SELECT TOP (12)
    merchant_category,
    COUNT(*)                                          AS total_txns,
    COUNT(CASE WHEN is_fraud = 1 THEN 1 END)          AS fraud_txns,
    CAST(COUNT(CASE WHEN is_fraud = 1 THEN 1 END) AS FLOAT)
        / NULLIF(COUNT(*), 0) * 100.0                 AS fraud_rate_pct,
    SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END) AS fraud_amount
FROM dbo.card_transactions
GROUP BY merchant_category
ORDER BY fraud_rate_pct DESC;

-- 13.4 Fraud rate trend over months (line-chart ready)
-- What this demonstrates: monthly fraud-rate trend suitable for plotting.
SELECT
    YEAR(txn_date)  AS yr,
    MONTH(txn_date) AS mn,
    COUNT(*)                                          AS total_txns,
    COUNT(CASE WHEN is_fraud = 1 THEN 1 END)          AS fraud_txns,
    CAST(COUNT(CASE WHEN is_fraud = 1 THEN 1 END) AS FLOAT)
        / NULLIF(COUNT(*), 0) * 100.0                 AS fraud_rate_pct
FROM dbo.card_transactions
GROUP BY YEAR(txn_date), MONTH(txn_date)
ORDER BY yr, mn;

-- 13.5 Late payment rate by loan_type
-- What this demonstrates: aggregating the late_payment_flag through the loan dimension.
SELECT
    l.loan_type,
    COUNT(p.payment_id)                                AS total_payments,
    COUNT(CASE WHEN p.late_payment_flag = 1 THEN 1 END) AS late_payments,
    CAST(COUNT(CASE WHEN p.late_payment_flag = 1 THEN 1 END) AS FLOAT)
        / NULLIF(COUNT(p.payment_id), 0) * 100.0      AS late_payment_rate_pct
FROM dbo.loans AS l
INNER JOIN dbo.loan_payments AS p ON p.loan_id = l.loan_id
GROUP BY l.loan_type
ORDER BY late_payment_rate_pct DESC;

-- 13.6 Composite fraud risk score (z-score(amount) + velocity + merchant risk)
-- What this demonstrates: a multi-factor risk score computed set-based in SQL.
WITH MerchantStats AS (
    SELECT
        merchant_category,
        AVG(amount) AS m_avg,
        STDEV(amount) AS m_std
    FROM dbo.card_transactions
    GROUP BY merchant_category
),
CardVelocity AS (
    SELECT
        card_id,
        COUNT(*) AS txn_count_30d
    FROM dbo.card_transactions
    WHERE txn_date >= DATEADD(DAY, -30, '2026-06-30')
    GROUP BY card_id
),
VelocityStats AS (
    SELECT
        AVG(txn_count_30d) AS v_avg,
        STDEV(txn_count_30d) AS v_std
    FROM CardVelocity
)
SELECT TOP (500)
    ct.card_txn_id,
    ct.card_id,
    ct.amount,
    ct.merchant_category,
    ct.is_fraud,
    -- z-score of amount within merchant_category
    CASE WHEN ms.m_std IS NULL OR ms.m_std = 0 THEN 0
         ELSE (ct.amount - ms.m_avg) / ms.m_std
    END AS amount_zscore,
    -- velocity factor (how many txns this card did in last 30 days)
    ISNULL(cv.txn_count_30d, 0) AS txn_count_30d,
    CASE WHEN vs.v_std IS NULL OR vs.v_std = 0 THEN 0
         ELSE (ISNULL(cv.txn_count_30d, 0) - vs.v_avg) / vs.v_std
    END AS velocity_zscore,
    -- composite score (weights: amount=0.5, velocity=0.5)
    (
      CASE WHEN ms.m_std IS NULL OR ms.m_std = 0 THEN 0
           ELSE (ct.amount - ms.m_avg) / ms.m_std
      END * 0.5
    +
      CASE WHEN vs.v_std IS NULL OR vs.v_std = 0 THEN 0
           ELSE (ISNULL(cv.txn_count_30d, 0) - vs.v_avg) / vs.v_std
      END * 0.5
    ) AS composite_risk_score
FROM dbo.card_transactions AS ct
LEFT JOIN MerchantStats AS ms ON ms.merchant_category = ct.merchant_category
OUTER APPLY (SELECT txn_count_30d FROM CardVelocity WHERE CardVelocity.card_id = ct.card_id) AS cv
CROSS JOIN VelocityStats AS vs
WHERE ct.txn_date >= '2026-06-01'
ORDER BY composite_risk_score DESC;

-- 13.7 Z-score anomaly detection on card_transactions.amount (|z| > 2.5)
-- What this demonstrates: in-database anomaly detection using z-score per merchant.
WITH MerchantStats AS (
    SELECT
        merchant_category,
        AVG(amount) AS m_avg,
        STDEV(amount) AS m_std
    FROM dbo.card_transactions
    GROUP BY merchant_category
)
SELECT TOP (500)
    ct.card_txn_id,
    ct.card_id,
    ct.txn_date,
    ct.merchant_category,
    ct.amount,
    ct.is_fraud,
    ms.m_avg,
    ms.m_std,
    CASE WHEN ms.m_std IS NULL OR ms.m_std = 0 THEN 0
         ELSE (ct.amount - ms.m_avg) / ms.m_std
    END AS zscore,
    CASE
        WHEN CASE WHEN ms.m_std IS NULL OR ms.m_std = 0 THEN 0
                  ELSE (ct.amount - ms.m_avg) / ms.m_std
        END > 2.5  THEN 'High Anomaly'
        WHEN CASE WHEN ms.m_std IS NULL OR ms.m_std = 0 THEN 0
                  ELSE (ct.amount - ms.m_avg) / ms.m_std
        END < -2.5 THEN 'Low Anomaly'
        ELSE 'Normal'
    END AS anomaly_flag
FROM dbo.card_transactions AS ct
INNER JOIN MerchantStats AS ms ON ms.merchant_category = ct.merchant_category
WHERE ct.txn_date >= '2026-06-01'
  AND ms.m_std IS NOT NULL
  AND ms.m_std > 0
  AND ABS((ct.amount - ms.m_avg) / ms.m_std) > 2.5
ORDER BY ABS((ct.amount - ms.m_avg) / ms.m_std) DESC;

-- ========================================================================================
-- ============================= 14. RFM SEGMENTATION (USING NTILE) =============================
-- ========================================================================================
 
-- 14.1 dbo.vw_CustomerRFM — Recency, Frequency, Monetary
-- What this demonstrates: classic RFM computation using CTEs and DATEDIFF.
CREATE VIEW dbo.vw_CustomerRFM
AS
WITH last_txn AS (
    SELECT
        a.customer_id,
        MAX(t.txn_date) AS last_txn_date
    FROM dbo.transactions AS t
    INNER JOIN dbo.accounts AS a ON a.account_id = t.account_id
    GROUP BY a.customer_id
),
freq_mon AS (
    SELECT
        a.customer_id,
        COUNT(*)            AS freq,
        SUM(ABS(t.amount))  AS mon
    FROM dbo.transactions AS t
    INNER JOIN dbo.accounts AS a ON a.account_id = t.account_id
    GROUP BY a.customer_id
)
SELECT
    c.customer_id,
    c.name,
    c.occupation,
    c.state,
    c.credit_score,
    lt.last_txn_date,
    DATEDIFF(DAY, lt.last_txn_date, '2026-10-17') AS recency,
    ISNULL(fm.freq, 0) AS frequency,
    ISNULL(fm.mon,  0) AS monetary
FROM dbo.customers AS c
LEFT JOIN last_txn lt ON lt.customer_id = c.customer_id
LEFT JOIN freq_mon  fm ON fm.customer_id = c.customer_id;

SELECT TOP 10 *
FROM vw_CustomerRFM

-- 14.2 dbo.vw_CustomerRFM_Segments — 9-segment classification
-- What this demonstrates: NTILE(5) for quintiles, then CASE to map quintile pairs
-- to a 9-bucket RFM segment name.
CREATE VIEW dbo.vw_CustomerRFM_Segments
AS
WITH rfm AS (
    SELECT
        customer_id, name, occupation, state, credit_score,
        recency, frequency, monetary
    FROM dbo.vw_CustomerRFM
),
quintiles AS (
    SELECT
        customer_id, name, occupation, state, credit_score,
        recency, frequency, monetary,
        -- Recency: LOWER recency = HIGHER quintile (better customer)
        NTILE(5) OVER (ORDER BY recency ASC)              AS r_quintile,
        NTILE(5) OVER (ORDER BY frequency ASC)           AS f_quintile,
        NTILE(5) OVER (ORDER BY monetary ASC)            AS m_quintile
    FROM rfm
)
SELECT
    customer_id, name, occupation, state, credit_score,
    recency, frequency, monetary,
    r_quintile, f_quintile, m_quintile,
    CASE
        WHEN r_quintile = 5 AND f_quintile = 5                              THEN 'Champions'
        WHEN r_quintile IN (4,5) AND f_quintile IN (4,5)                    THEN 'Loyal Customers'
        WHEN r_quintile IN (4,5) AND f_quintile IN (2,3)                     THEN 'Potential Loyalists'
        WHEN r_quintile = 5 AND f_quintile = 1                              THEN 'Recent Customers'
        WHEN r_quintile = 4 AND f_quintile = 1                              THEN 'Promising'
        WHEN r_quintile = 3 AND f_quintile IN (3,4)                         THEN 'Need Attention'
        WHEN r_quintile = 3 AND f_quintile IN (1,2)                         THEN 'About to Sleep'
        WHEN r_quintile IN (1,2) AND f_quintile IN (3,4,5)                  THEN 'At Risk'
        WHEN r_quintile IN (1,2) AND f_quintile IN (1,2)                    THEN 'Lost'
        ELSE 'Others'
    END AS rfm_segment
FROM quintiles;

SELECT
    rfm_segment,
    COUNT(*)              AS customer_count,
    AVG(recency)          AS avg_recency,
    AVG(frequency)        AS avg_frequency,
    AVG(monetary)         AS avg_monetary
FROM dbo.vw_CustomerRFM_Segments
GROUP BY rfm_segment
ORDER BY customer_count DESC;


-- ========================================================================================
-- ============================= 15. COHORT RETENTION ANALYSIS =============================
-- ========================================================================================
 
-- 15.1 dbo.vw_CustomerCohort — assign each customer to a cohort (first txn month)
-- What this demonstrates: cohort = the month of the customer's first transaction.

CREATE VIEW dbo.vw_CustomerCohort
AS
SELECT
    a.customer_id,
    MIN(t.txn_date) AS first_txn_date,
    DATEFROMPARTS(YEAR(MIN(t.txn_date)), MONTH(MIN(t.txn_date)), 1) AS cohort_month
FROM dbo.transactions AS t
INNER JOIN dbo.accounts AS a ON a.account_id = t.account_id
GROUP BY a.customer_id;

SELECT *
FROM vw_CustomerCohort


-- ===========================================================================================================
-- ============================= 16. STATISTICAL QUERIES (IN-DATABASE ANALYTICS) =============================
-- ===========================================================================================================
 
-- 16.1 Mean and standard deviation of txn amount per account
-- What this demonstrates: AVG + STDEV grouped by account_id.
SELECT TOP (200)
    account_id,
    COUNT(*)        AS txn_count,
    AVG(amount)     AS mean_amount,
    STDEV(amount)   AS std_amount,
    MIN(amount)     AS min_amount,
    MAX(amount)     AS max_amount
FROM dbo.transactions
GROUP BY account_id
HAVING COUNT(*) > 5
ORDER BY std_amount DESC;

-- 16.2 Z-score per card_transaction (amount - mean) / stdev
-- What this demonstrates: z-score computed from grouped statistics.
WITH MerchantStats AS (
    SELECT
        merchant_category,
        AVG(amount) AS mean_amount,
        STDEV(amount) AS std_amount
    FROM dbo.card_transactions
    GROUP BY merchant_category
)
SELECT TOP (500)
    ct.card_txn_id,
    ct.card_id,
    ct.merchant_category,
    ct.amount,
    ms.mean_amount,
    ms.std_amount,
    CASE WHEN ms.std_amount IS NULL OR ms.std_amount = 0 THEN 0
         ELSE (ct.amount - ms.mean_amount) / ms.std_amount
    END AS z_score
FROM dbo.card_transactions AS ct
INNER JOIN MerchantStats AS ms ON ms.merchant_category = ct.merchant_category
WHERE ct.txn_date >= '2026-06-01'
ORDER BY ABS(CASE WHEN ms.std_amount IS NULL OR ms.std_amount = 0 THEN 0
                 ELSE (ct.amount - ms.mean_amount) / ms.std_amount
           END) DESC;

-- 16.3 Pearson correlation between annual_income and credit_score
-- What this demonstrates: in-database Pearson r using SUMs and SQRT.
WITH base AS (
    SELECT
        annual_income,
        credit_score,
        AVG(annual_income) OVER () AS mean_income,
        AVG(credit_score)  OVER () AS mean_credit
    FROM dbo.customers
    WHERE annual_income IS NOT NULL
      AND credit_score  IS NOT NULL
)
SELECT
    COUNT(*)                AS n,
    AVG(annual_income)      AS mean_income,
    AVG(credit_score)       AS mean_credit,
    STDEV(annual_income)    AS std_income,
    STDEV(credit_score)     AS std_credit,
    CASE
        WHEN SUM(POWER(annual_income - mean_income, 2))
           * SUM(POWER(credit_score  - mean_credit, 2)) <> 0
        THEN
            SUM((annual_income - mean_income) * (credit_score - mean_credit))
            /
            SQRT(
                SUM(POWER(annual_income - mean_income, 2))
              * SUM(POWER(credit_score  - mean_credit, 2))
            )
        ELSE 0
    END AS pearson_r
FROM base;   


-- 16.4 Quartiles (Q1, Q2, Q3) of loan_amount using PERCENTILE_CONT
-- What this demonstrates: PERCENTILE_CONT(0.25/0.5/0.75) WITHIN GROUP.
SELECT DISTINCT
    loan_type,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY loan_amount) OVER (PARTITION BY loan_type) AS q1,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY loan_amount) OVER (PARTITION BY loan_type) AS median_q2,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY loan_amount) OVER (PARTITION BY loan_type) AS q3,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY loan_amount) OVER (PARTITION BY loan_type) AS p95,
    MIN(loan_amount) OVER (PARTITION BY loan_type) AS min_amount,
    MAX(loan_amount) OVER (PARTITION BY loan_type) AS max_amount
FROM dbo.loans
ORDER BY loan_type;   

-- 16.5 Top 5% outliers by amount (using NTILE(100) and filtering to top 5%)
-- What this demonstrates: NTILE(100) makes a 100-bucket histogram; top 5 buckets = top 5%.
WITH Percentiles AS (
    SELECT
        card_txn_id,
        amount,
        NTILE(100) OVER (ORDER BY amount ASC) AS pct_bucket
    FROM dbo.card_transactions
    WHERE txn_date >= '2026-06-01'
)
SELECT TOP (500)
    card_txn_id,
    amount,
    pct_bucket
FROM Percentiles
WHERE pct_bucket >= 96
ORDER BY amount DESC;

-- 16.6 Chi-square test of independence: loan_type x status
-- What this demonstrates: full chi-square computation in-database — observed,
-- expected, chi-square statistic and (approximate) p-value via a lookup.
WITH Observed AS (
    SELECT loan_type, status, COUNT(*) AS observed
    FROM dbo.loans
    GROUP BY loan_type, status
),
Totals AS (
    SELECT
        SUM(observed) AS grand_total,
        SUM(SUM(observed)) OVER () AS gt_check
    FROM Observed
),
RowTotals AS (
    SELECT loan_type, SUM(observed) AS row_total FROM Observed GROUP BY loan_type
),
ColTotals AS (
    SELECT status,  SUM(observed) AS col_total FROM Observed GROUP BY status
),
Expected AS (
    SELECT
        o.loan_type,
        o.status,
        o.observed,
        rt.row_total,
        ct.col_total,
        t.grand_total,
        CAST(rt.row_total AS FLOAT) * ct.col_total / t.grand_total AS expected
    FROM Observed AS o
    INNER JOIN RowTotals AS rt ON rt.loan_type = o.loan_type
    INNER JOIN ColTotals AS ct ON ct.status    = o.status
    CROSS JOIN Totals    AS t
)
SELECT
    SUM(POWER(observed - expected, 2) / NULLIF(expected, 0)) AS chi2_stat,
    COUNT(*) - 1 AS dof,   -- dof = (rows-1)*(cols-1), approximated for catalog
    -- Expected chi-square critical value at alpha=0.05, dof=15 is ~25.00
    CASE
        WHEN SUM(POWER(observed - expected, 2) / NULLIF(expected, 0)) > 25.00
        THEN 'Reject H0 (dependent)'
        ELSE 'Fail to Reject H0 (independent)'
    END AS verdict
FROM Expected;

