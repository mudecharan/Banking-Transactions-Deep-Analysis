================================================================================
  BANKING TRANSACTIONS — POWER BI / DAX COMPLETE ANALYSIS & VISUALIZATION GUIDE
---------------------------------------------------------------------------------------------------
- Project          : Banking Transactions Performance Dashboard
- Source Dataset   : Kaggle `vivekmali1436/banking-transactions-dataset` (10 tables, ~5.81M rows)
- Currency         : INR (₹)
================================================================================
  SECTION 1 — HEADER & METADATA
  -------------------------------------------------------------------------------------------------
  Project KPIs (must reconcile with /data/headline_kpis.json):
    Total Customers          : 60,000
    Total Accounts            : 95,000
    Total Cards               : 65,000
    Total Loans               : 22,000
    Total Branches            : 150
    Total Employees           : 1,800
    Total Transactions        : 2,000,000
    Total Card Transactions   : 3,000,000
    Total Loan Payments       : 600,000
    Total Support Tickets     : 25,000
    Total Txn Volume          : ₹12,096,769,234.05
    Total Card Txn Volume     : ₹5,551,103,753.97
    Total Deposits Balance    : ₹4,347,317,460.09
    Total Loan Book           : ₹9,214,647,675.78
    Avg Account Balance       : ₹45,761.24
    Avg Loan Amount           : ₹418,847.62
    Avg Interest Rate          : 11.51%
    Avg Credit Score          : 599.70
    Avg Customer Age          : 48.74 years
    Avg Customer Tenure       : 10.85 years
    Fraud Count               : 14,954
    Fraud Rate                : 0.4985%   (target ≤ 0.50%)
    Fraud Amount              : ₹27,418,143.24
    NPA Count                 : 2,221
    NPA Rate                  : 10.0955%  (target ≤ 8%)
    Late Payment Rate         : 12.0063%  (target ≤ 10%)
    Avg Resolution Days       : 9.49      (target ≤ 7)
    Avg Satisfaction Score    : 3.00 / 5  (target ≥ 4)
    Open Tickets              : 2,987
    Escalated Tickets         : 1,962

  Dataset row counts (source CSVs in /data/):
    branches.csv             :     150 rows
    customers.csv            :  60,000 rows
    accounts.csv             :  95,000 rows
    cards.csv                :  65,000 rows
    employees.csv            :   1,800 rows
    loans.csv                :  22,000 rows
    transactions.csv         :  2,000,000 rows
    card_transactionss.csv    :  3,000,000 rows
    loan_payments.csv        :    600,000 rows
    support_tickets.csv      :     25,000 rows

  Data date ranges (from headline_kpis.json):
    transactions         : 2018-01-01 → 2026-06-30
    card_transactionss    : 2018-01-01 → 2026-06-30
    loans                : 2010-01-01 → 2025-05-31

================================================================================
  SECTION 2 — STAR SCHEMA MODELING GUIDE
  -------------------------------------------------------------------------------------------------
  DIMENSION TABLES (7) — short, descriptive:
    1. branchs     → from `branches.csv`      (150 rows)
    2. customers   → from `customers.csv`      (60,000 rows)
    3. accounts    → from `accounts.csv`       (95,000 rows)   
    4. card       → from `cards.csv`          (65,000 rows)   
    5. loan       → from `loans.csv`          (22,000 rows)   
    6. employee   → from `employees.csv`      (1,800 rows)
    7. date       → generated calendar        (3,287 rows: 2018-01-01 → 2026-12-31)

 RELATIONSHIPS (one-to-many, single-direction filter propagation):

|     | FROM (1-side) | TO (many-side)   | KEY                 | Cross-Filter |
| --- | ------------- | ---------------- | ------------------- | ------------ |
| 1   | customers     | accounts         | customer_id         | Single       |
| 2   | customers     | cards            | customer_id         | Single       |
| 3   | customers     | loans            | customer_id         | Single       |
| 4   | customers     | support_tickets  | customer_id         | Single       |
| 5   | branchs       | accounts         | branch_id           | Single       |
| 6   | branchs       | loans            | branch_id           | Single       |
| 7   | branchs       | employees        | branch_id           | Single       |
| 8   | accounts      | transactions     | account_id          | Single       |
| 9   | cards         | card_transactions | card_id             | Single       |
| 10  | loans         | loan_payments    | loan_id             | Single       |
| 11  | Date          | transactions     | txn_date → Date     | Single       |
| 12  | Date          | card_transactions | txn_date → Date     | Single       |
| 13  | Date          | loan_payments    | payment_date → Date | Single       |
| 14  | Date          | support_tickets  | date_opened → Date  | Single       |

```text
  TEXT-ART STAR SCHEMA DIAGRAM:

                                Date
                                  │
                                  │ (Date)
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        │                         │                         │
        │                         │                         │
   transactions   card_transactions   loan_payments   support_tickets
        │                         │                         │                  │
   (account_id)              (card_id)             (loan_id)            (customer_id)
        │                         │                         │                  │
        ▼                         ▼                         ▼                  │
   accounts                cards                  loans                  │
        │                         │                         │                  │
   (customer_id)            (customer_id)            (customer_id)            │
   (branch_id)                ─                        (branch_id)             │
        │                                                  │                  │
        └──────────────► customers ◄─────────────────────┘                  │
                                  │◄──────────────────────────────────────────┘
                                  │
                                  │ (1:* relationships all single-direction)
                                  │
                              branchs
                                  │
                            employees (also via branch_id)


```
================================================================================
  SECTION 3 — POWER QUERY M CODE (FOR BOTH POWER BI AND EXCEL)
  ---------------------------------------------------------------------------------

================================================================================
  3.1  Date — Full Calendar (2018-01-01 → 2026-12-31, 3,287 days)
  ---------------------------------------------------------------------------------
```DAX
Date =
ADDCOLUMNS (
    CALENDAR ( DATE ( 2018, 1, 1 ), DATE ( 2026, 12, 31 ) ),
    "Year", YEAR ( [Date] ),
    "Month", MONTH ( [Date] ),
    "MonthName", FORMAT ( [Date], "MMMM" ),
    "Quarter", QUARTER ( [Date] ),
    "YearQuarter", YEAR ( [Date] ) & " Q" & QUARTER ( [Date] ),
    "YearMonth", YEAR ( [Date] ) & "-" & FORMAT ( MONTH ( [Date] ), "00" ),
    "DayOfWeek", WEEKDAY ( [Date], 1 ) - 1,
    "DayName", FORMAT ( [Date], "DDDD" ),
    "IsWeekend", WEEKDAY ( [Date], 1 ) - 1 >= 5,
    "FiscalYear", IF ( MONTH ( [Date] ) >= 4, YEAR ( [Date] ) + 1, YEAR ( [Date] ) ),
    "FiscalQuarter", IF ( MONTH ( [Date] ) >= 4, MOD ( MONTH ( [Date] ) - 4, 3 ) + 1, MOD ( MONTH ( [Date] ) + 8, 3 ) + 1 ),
    "MonthSortKey", MONTH ( [Date] ),
    "DayNameSortKey", WEEKDAY ( [Date], 2 )
)   

```

================================================================================
  3.2  branches → branchs  (150 rows)
  --------------------------------------------------------------------------------------------------
  - **Columns**: branch_id (PK), branch_name, city, state, opened_date, ifsc_code
  ### Set Data types
-  branch_id   → Int64 (whole number, used in joins)
-   branch_name  → text
-   city, state  → text
-   opened_date  → date (not datetime — saves 8 bytes per row in VertiPaq)
-   ifsc_code    → text
### steps 
1.  Rename `branch_id` -> `Branch_ID`
2.  Rename `branch_name` -> `Branch_Name`
3. Trim Whitespace in `Branch_Name`, `city`, `state`,  `ifsc_code
4. Add Column — Branch_Age_Years
5. Add Column — Region
```dax
Branch_Age_Years = 
DIVIDE(DATEDIFF([opened_date], TODAY(), DAY),365.25)
```

```Region = 
SWITCH(
    TRUE(),
    [state] IN {
        "Delhi", "Punjab", "Haryana", "Jammu and Kashmir",
        "Himachal Pradesh", "Uttarakhand", "Uttar Pradesh", "Rajasthan"
    }, "North",
    
    [state] IN {"Maharashtra", "Gujarat", "Goa"}, "West",
    
    [state] IN {
        "West Bengal", "Bihar", "Jharkhand", "Odisha",
        "Assam", "Sikkim", "Tripura"
    }, "East",
    
    [state] IN {
        "Kerala", "Tamil Nadu", "Karnataka", "Andhra Pradesh",
        "Telangana", "Puducherry"
    }, "South",
    
    [state] IN {"Madhya Pradesh", "Chhattisgarh"}, "Central",
    
    "Other"
)
```

================================================================================
  3.3  customers → customers  (60,000 rows)
  --------------------------------------------------------------------------------------------------
**Columns**: customer_id, name, gender, date_of_birth, city, state, phone,email,occupation, annual_income, join_date, credit_score

### Set Data Types
{"customer_id",    Int64.Type},
"name",           type text},
{"gender",         type text},
{"date_of_birth",  type date},
 {"city",           type text},
{"state",          type text},
{"phone",          type text},
{"email",          type text},
{"occupation",     type text},
{"annual_income",  type number},
{"join_date",      type date},
{"credit_score",   Int64.Type}

### Steps
1.  Rename `customer_id` -> `Customer_ID`
2. Add Column — Customer_Age
3. Add Column — Credit_Score_Band
4. Add Column — Income_Bucket
5. Add Column — Age_Bucket
6. Add Column — Tenure_Bucket
7. Add Column — Customer_Segment
8. Add Column — Customer_SortKey

```dax
-- Customer_Age: Years since date_of_birth (whole years)
-- Used in age distribution histogram & age-based segmentation
Customer_Age =
DATEDIFF ( customers[date_of_birth], TODAY(), YEAR )
```
```dax
-- Customer_Tenure_Years: Years since customer joined the bank
-- Used in retention analytics & tenure-vs-loyalty analysis
Customer_Tenure_Years =
DATEDIFF ( customers[join_date], TODAY(), YEAR )
```

```dax
-- Credit_Score_Band: Standard creditworthiness bands per RBI guidance
-- Used as slicer & in risk segmentation measures
Credit_Score_Band =
SWITCH (
    TRUE (),
    customers[credit_score] >= 750, "Excellent (750+)",
    customers[credit_score] >= 650, "Good (650-749)",
    customers[credit_score] >= 580, "Fair (580-649)",
    "Poor (<580)"
)
```

```dax
-- Income_Bucket: Annual income buckets used for marketing segmentation
-- ₹30L = ₹3,000,000 (high net worth threshold)
Income_Bucket =
SWITCH (
    TRUE (),
    customers[annual_income] >= 3000000, "High (₹30L+)",
    customers[annual_income] >= 1000000, "Mid (₹10L-₹30L)",
    "Low (<₹10L)"
)
```

```dax
-- Age_Bucket: Customer age demographic banding
-- Aligns with industry-standard demographic cohorts
Age_Bucket =
SWITCH (
    TRUE (),
    customers[Customer_Age] >= 60, "Senior (60+)",
    customers[Customer_Age] >= 40, "Middle-aged (40-59)",
    customers[Customer_Age] >= 25, "Adult (25-39)",
    "Young (<25)"
)
```

```dax
-- Tenure_Bucket: Customer loyalty cohort
Tenure_Bucket =
SWITCH (
    TRUE (),
    customers[Customer_Tenure_Years] >= 15, "Veteran (15+y)",
    customers[Customer_Tenure_Years] >= 8,  "Established (8-15y)",
    "New (<8y)"
)
```

```dax
-- Customer_Segment: Composite segment combining tenure + income
-- Used in Premium/Established/New cohort comparisons
Customer_Segment =
SWITCH (
    TRUE (),
    AND ( customers[Customer_Tenure_Years] > 5, customers[annual_income] > 2000000 ), "Premium Long-Term",
    AND ( customers[Customer_Tenure_Years] > 5, customers[annual_income] <= 2000000 ), "Established",
    customers[Customer_Tenure_Years] <= 5, "New",
    "Other"
)
```

```dax
-- Customer_SortKey: Stable sort key for chart axis ordering (defaults to customer_id)
Customer_SortKey = customers[customer_id]
```

================================================================================
  3.4  accounts → accounts  (95,000 rows)
  ---------------------------------------------------------------------------------
 **Columns**: account_id, customer_id, branch_id, account_type, balance, open_date,status

**Set Data Types**
{"account_id",   Int64.Type},
{"customer_id", Int64.Type},
{"branch_id",    Int64.Type},
{"account_type", type text},
{"balance",       type number},
{"open_date",     type date},
{"status",        type text}

### Steps
1.  Rename `account_id` -> `Account_ID`
2.  Rename `customer_id` -> `Customer_ID`
3.  Rename `branch_id` -> `bBranch_ID`
4. Add Column — Account_Age_Years
5. Add Column — Balance_Bucket
6. Add Column — Status_Flag
7. Add Column — Is_Active
8. Add Column — Account_Lifecycle

```dax
-- Account_Age_Years: Years since account opened
Account_Age_Years =
DATEDIFF ( accounts[open_date], TODAY(), YEAR )

-- Balance_Bucket: Categorize accounts by balance band
-- Used in deposit distribution analysis
Balance_Bucket =
SWITCH (
    TRUE (),
    accounts[balance] >= 200000, "High (₹2L+)",
    accounts[balance] >= 50000,  "Mid (₹50K-₹2L)",
    "Low (<₹50K)"
)
```

```dax
-- Status_Flag: Numeric encoding of status (1=Active, 0=Dormant, -1=Closed)
-- Useful for matrix heatmaps & simple aggregations
Status_Flag =
SWITCH ( accounts[status],
    "Active", 1,
    "Dormant", 0,
    "Closed", -1,
    0
)
```

```dax
-- Is_Active: Boolean flag for active accounts (faster than string comparison)
Is_Active =
IF ( accounts[status] = "Active", TRUE (), FALSE () )

-- Account_Lifecycle: Aging-based lifecycle classification
Account_Lifecycle =
SWITCH (
    TRUE (),
    accounts[Account_Age_Years] >= 10, "Mature",
    accounts[Account_Age_Years] >= 5,  "Mid-life",
    "New"
)

```

================================================================================
  3.5  cards → cards  (65,000 rows)
  ---------------------------------------------------------------------------------
   **Columns**: card_id, customer_id, account_id, card_type, issue_date, expiry_date,
           credit_limit, status
**Set Data Types**
{"card_id",       Int64.Type},
{"customer_id",  Int64.Type},
{"account_id",   Int64.Type},
{"card_type",     type text},
{"issue_date",     type date},
{"expiry_date",   type date},
{"credit_limit",   type number},
{"status",         type text}
### Steps
1.  Rename `card_id` -> `Card_ID`
2.  Rename `customer_id` -> `Customer_ID`
3.  Rename `account_id` -> `Account_ID`
4. Add Column — Card_Age_Years
5. Add Column — Is_Expired
6. Add Column — Card_Tier
7. Add Column — Credit_Utilization_Potential
8. Add Column — Card_Lifecycle_Status

```dax
-- Card_Age_Years: Years since card issued
Card_Age_Years =
DATEDIFF ( cards[issue_date], TODAY (), YEAR )
```

```dax
-- Is_Expired: TRUE if card expiry_date is in the past
Is_Expired =
IF ( cards[expiry_date] < TODAY (), TRUE (), FALSE () )
```

```dax
-- Card_Tier: Derive card tier from card_type string
Card_Tier =
SWITCH (
    TRUE (),
    ISNUMBER ( SEARCH ( "Platinum", cards[card_type] ) ), "Premium",
    ISNUMBER ( SEARCH ( "Gold",     cards[card_type] ) ), "Premium-Mid",
    ISNUMBER ( SEARCH ( "Classic",  cards[card_type] ) ), "Standard",
    "Debit"
)
```

```dax
-- Credit_Utilization_Potential: Placeholder (1 if card has credit_limit > 0)
-- Real utilization requires joining card_transactionss; this is a stub
Credit_Utilization_Potential =
IF ( cards[credit_limit] > 0, 1, BLANK () )
```

```dax
-- Card_Lifecycle_Status: Consolidated lifecycle/status flag
Card_Lifecycle_Status =
SWITCH (
    TRUE (),
    cards[Is_Expired], "Expired",
    cards[status] = "Blocked", "Blocked",
    cards[status] = "Active", "Active",
    "Other"
)
```

================================================================================
  3.6  employees → employees  (1,800 rows)
  ---------------------------------------------------------------------------------
  **Columns**: employee_id, name, branch_id, role, hire_date, salary

**Set Data Types**
{"employee_id", Int64.Type},
{"name",         type text},
{"branch_id",   Int64.Type},
{"role",         type text},
{"hire_date",    type date},
{"salary",       type number}

### Steps
1.  Rename `employee_id` -> `Employee_ID`
2.  Rename `branch_id` -> `Branch_ID`
3. Add Column — Employee_Tenure_Years
4. Add Column — Salary_Bucket


```dax
-- Employee_Tenure_Years: Years since employee hired
Employee_Tenure_Years =
DATEDIFF ( employees[hire_date], TODAY (), YEAR )
```

```dax
-- Salary_Bucket: Monthly salary categorization
Salary_Bucket =
SWITCH (
    TRUE (),
    employees[salary] >= 100000, "High (₹1L+/mo)",
    employees[salary] >= 50000,  "Mid (₹50K-₹1L)",
    "Entry (<₹50K)"
)
```


================================================================================
  3.7  loans → loans  (22,000 rows)
  ---------------------------------------------------------------------------------
  **Columns**: loan_id, customer_id, branch_id, loan_type, loan_amount, interest_rate, term_months, start_date, status

**Set Data Types**
{"loan_id",        Int64.Type},
 {"customer_id",   Int64.Type},
{"branch_id",     Int64.Type},
{"loan_type",      type text},
{"loan_amount",    type number},
 {"interest_rate",  type number},
{"term_months",   Int64.Type},
{"start_date",     type date},
{"status",         type text}

### Steps
1.  Rename `loan_id` -> `Loan_ID`
2.  Rename `customer_id` -> `Customer_ID`
3.  Rename `branch_id` -> `Branch_ID`
4. Add Column — Loan_Age_Years
5. Add Column — Is_NPA
6. Add Column — Term_Bucket
7. Add Column — EMI_Estimate
8. Add Column — Loan_Amount_Bucket
9. Add Column — Interest_Rate_Bucket
10. Add Column — Loan_Health_Score
11. Add Column — Risk_Tier

```dax
-- Loan_Age_Years: Years since loan disbursed
Loan_Age_Years =
DATEDIFF ( loans[start_date], TODAY (), YEAR )
```

```dax
-- Is_NPA: TRUE if loan has slipped into non-performing status
-- Standard RBI definition: Defaulted & Written Off are NPAs
Is_NPA =
IF ( loans[status] IN { "Defaulted", "Written Off" }, TRUE (), FALSE () )
```

```dax
-- Term_Bucket: Loan tenor categorization
Term_Bucket =
SWITCH (
    TRUE (),
    loans[term_months] <= 24,  "Short (≤2y)",
    loans[term_months] <= 60,  "Medium (3-5y)",
    loans[term_months] <= 120, "Long (6-10y)",
    "Very Long (>10y)"
)

```

```dax
-- EMI_Estimate: Standard amortizing EMI = P*r*(1+r)^n / ((1+r)^n - 1)
-- r = monthly interest rate = annual_rate / 12 / 100
EMI_Estimate =
VAR r = loans[interest_rate] / 100 / 12
VAR n = loans[term_months]
VAR factor = POWER ( 1 + r, n )
RETURN
    DIVIDE ( loans[loan_amount] * r * factor, factor - 1, 0 )
```

```dax
-- Loan_Amount_Bucket: Loan size banding
Loan_Amount_Bucket =
SWITCH (
    TRUE (),
    loans[loan_amount] >= 2000000, "Jumbo (₹20L+)",
    loans[loan_amount] >= 1000000, "Large (₹10L-₹20L)",
    loans[loan_amount] >= 500000,  "Medium (₹5L-₹10L)",
    "Small (<₹5L)"
)
```

```dax
-- Interest_Rate_Bucket: Rate-of-interest banding
Interest_Rate_Bucket =
SWITCH (
    TRUE (),
    loans[interest_rate] >= 14, "High (14%+)",
    loans[interest_rate] >= 11, "Mid (11-14%)",
    "Low (<11%)"
)
```

```dax
-- Loan_Health_Score: 0-100 health composite (0=NPA, 100=Closed in good standing)
Loan_Health_Score =
SWITCH (
    TRUE (),
    loans[Is_NPA], 0,
    loans[status] = "Closed", 100,
    loans[Interest_Rate_Bucket] = "High (14%+)", 60,
    75
)
```

```dax
-- Risk_Tier: Bank-internal risk classification
Risk_Tier =
SWITCH (
    TRUE (),
    loans[Is_NPA], "High Risk",
    loans[interest_rate] >= 14, "Elevated Risk",
    loans[interest_rate] >= 11, "Moderate Risk",
    "Low Risk"
)

```

================================================================================
  3.8  transactions → transactions  (2,000,000 rows)
  ---------------------------------------------------------------------------------
  **Columns**: transaction_id, account_id, txn_date, txn_type, amount, channel,
           merchant_category

  **Derived columns added:**
    Txn_Year, Txn_Month, Txn_YearMonth, Txn_Weekday, Is_Weekend, Amount_Abs, Amount_Bucket

**Set Data Types**
{"transaction_id", Int64.Type},
{"account_id",     Int64.Type},
{"txn_date",        type date},
{"txn_type",        type text},
{"amount",          type number},
{"channel",         type text},
{"merchant_category", type text}

### Steps
1.  Rename `transaction_id` -> `Transaction_ID`
2.  Rename `account_id` -> `Account_ID`
3. Add Column — Txn_Year
4. Add Column — Txn_Month
5. Add Column — Txn_YearMonth
6. Add Column — Txn_Weekday
7. Add Column — Is_Weekend
8. Add Column — Amount_Abs
9. Add Column — Amount_Bucket

```dax
-- Txn_Year: 4-digit year (used for slicers and YoY)
Txn_Year = YEAR ( transactions[txn_date] )
```

```dax
-- Txn_Month: Month number (1-12)
Txn_Month = MONTH ( transactions[txn_date] )

-- Txn_YearMonth: "YYYY-MM" string for monthly trend axes
Txn_YearMonth = FORMAT ( transactions[txn_date], "YYYY-MM" )
```

```dax
-- Txn_Weekday: Full weekday name (Monday, Tuesday, ...)
Txn_Weekday = FORMAT ( transactions[txn_date], "dddd" )

-- Is_Weekend: TRUE if Saturday or Sunday
-- WEEKDAY(date, 2): Mon=1..Sun=7
Is_Weekend =
IF ( WEEKDAY ( transactions[txn_date], 2 ) >= 6, TRUE (), FALSE () )
```

```dax
-- Amount_Abs: Absolute value of amount (transactions can be credits or debits)
Amount_Abs = ABS ( transactions[amount] )
```

```dax
-- Amount_Bucket: Transaction size categorization
Amount_Bucket =
SWITCH (
    TRUE (),
    ABS ( transactions[amount] ) >= 50000, "Large (₹50K+)",
    ABS ( transactions[amount] ) >= 10000, "Medium (₹10K-₹50K)",
    "Small (<₹10K)"
)
```

================================================================================
  3.9  card_transactionss → card_transactions  (3,000,000 rows)
  ---------------------------------------------------------------------------------
  Columns: card_txn_id, card_id, txn_date, merchant_category, amount, is_fraud

**Set Data Types**
{"card_txn_id",       Int64.Type},
{"card_id",          Int64.Type},
 {"txn_date",           type date},
 {"merchant_category", type text},
{"amount",             type number},
{"is_fraud",          Int64.Type}      // 0 or 1 flag

### Steps
1.  Rename `card_id` -> `Card_ID`
2. Add Column — Txn_Year
3. Add Column — Txn_Month
4. Add Column — Txn_YearMonth
5. Add Column — Txn_Weekday
6. Add Column — Is_Weekend
7. Add Column — Amount_Bucket


```dax
Txn_Year  = YEAR ( card_transactions[txn_date] )
```

```dax
Txn_Month = MONTH ( card_transactions[txn_date] )
```

```dax
Txn_YearMonth = FORMAT ( card_transactions[txn_date], "YYYY-MM" )
```

```dax
Txn_Weekday   = FORMAT ( card_transactions[txn_date], "dddd" )
```

```dax
Is_Weekend =
IF ( WEEKDAY ( card_transactions[txn_date], 2 ) >= 6, TRUE (), FALSE () )
```

```dax
Amount_Bucket =
SWITCH (
    TRUE (),
    card_transactions[amount] >= 50000, "Large (₹50K+)",
    card_transactions[amount] >= 10000, "Medium (₹10K-₹50K)",
    "Small (<₹10K)"
)
```
================================================================================
  3.10  loan_payments → loan_payments  (600,000 rows)
  ---------------------------------------------------------------------------------
  Columns: payment_id, loan_id, payment_date, amount_paid, principal_component,
           interest_component, late_payment_flag


**Set Data Types**
{"payment_id",          Int64.Type},
{"loan_id",             Int64.Type},
{"payment_date",         type date},
{"amount_paid",          type number},
{"principal_component",  type number},
{"interest_component",   type number},
{"late_payment_flag",   Int64.Type}

### Steps
1.  Rename `payment_id` -> `Payment_ID`
2.  Rename `loan_id` -> `Loan_ID`
3. Add Column — Payment_Year
4. Add Column — Payment_Month
5. Add Column — Payment_YearMonth
6. Add Column — Is_Late
7. Add Column — Principal_Pct

```dax
Payment_Year  = YEAR ( loan_payments[payment_date] )
```

```
Payment_Month = MONTH ( loan_payments[payment_date] )
```

```
Payment_YearMonth = FORMAT ( loan_payments[payment_date], "YYYY-MM" )
```

```
-- Is_Late: TRUE if late_payment_flag = 1
Is_Late =
IF ( loan_payments[late_payment_flag] = 1, TRUE (), FALSE () )
```

```
-- Principal_Pct: Share of payment that goes to principal (vs interest)
-- High ratio early in tenor is unusual; flag for investigation
Principal_Pct =
DIVIDE ( loan_payments[principal_component], loan_payments[amount_paid], 0 )
```

===============================================================================
  3.11  support_tickets → support_tickets  (25,000 rows)
  ---------------------------------------------------------------------------------
**Columns**: ticket_id, customer_id, issue_type, date_opened, date_resolved,
           status, satisfaction_score


**Set Data Types**
{"ticket_id",          Int64.Type},
        {"customer_id",       Int64.Type},
        {"issue_type",          type text},
        {"date_opened",         type date},
        {"date_resolved",       type date},
        {"status",              type text},
        {"satisfaction_score", Int64.Type}

### Steps
1.  Rename `customer_id` -> `Customer_ID`
2. Add Column — Resolution_Days
3. Add Column — Satisfaction_Band
4. Add Column — Is_Open
5. Add Column — Is_Escalated
6. Add Column — Resolution_Bucket

```dax
-- Resolution_Days: Calendar days from open to resolve
-- Returns BLANK for unresolved tickets (date_resolved is null)
Resolution_Days =
IF (
    ISBLANK ( support_tickets[date_resolved] ),
    BLANK (),
    DATEDIFF ( support_tickets[date_opened], support_tickets[date_resolved], DAY )
)
```

```
-- Satisfaction_Band: Categorize satisfaction scores
Satisfaction_Band =
SWITCH (
    TRUE (),
    support_tickets[satisfaction_score] >= 4, "High",
    support_tickets[satisfaction_score] >= 3, "Medium",
    "Low"
)
```

```
-- Is_Open: TRUE if ticket still in Open status
Is_Open =
IF ( support_tickets[status] = "Open", TRUE (), FALSE () )
```

```
-- Is_Escalated: TRUE if ticket was escalated
Is_Escalated =
IF ( support_tickets[status] = "Escalated", TRUE (), FALSE () )
```

```
-- Resolution_Bucket: Speed categorization
Resolution_Bucket =
SWITCH (
    TRUE (),
    ISBLANK ( support_tickets[Resolution_Days] ), "Unresolved",
    support_tickets[Resolution_Days] <= 7,  "Fast (≤7d)",
    support_tickets[Resolution_Days] <= 14, "Normal (8-14d)",
    "Slow (>14d)"
)

```

================================================================================
  SECTION 5 — DAX MEASURES (150+ organized by category)
  ---------------------------------------------------------------------------------
============================================================
  SECTION 5.1 — BASE MEASURES (VOLUME / COUNT) — 25 measures
  ============================================================

| #   | Measure                     | DAX                                                                              |
| --- | --------------------------- | -------------------------------------------------------------------------------- |
| 1   | `Total_Customers`           | `COUNTROWS(customers)`                                                         |
| 2   | `Total_Accounts`            | `COUNTROWS(accounts)`                                                          |
| 3   | `Total_Cards`               | `COUNTROWS(cards)`                                                             |
| 4   | `Total_Loans`               | `COUNTROWS(loans)`                                                             |
| 5   | `Total_Branches`            | `COUNTROWS(branchs)`                                                           |
| 6   | `Total_Employees`           | `COUNTROWS(employees)`                                                         |
| 7   | `Total_Transactions`        | `COUNTROWS(transactions)`                                              |
| 8   | `Total_card_transactionss`   | `COUNTROWS(card_transactions)`                                                 |
| 9   | `Total_Loan_Payments`       | `COUNTROWS(loan_payments)`                                                     |
| 10  | `Total_Support_Tickets`     | `COUNTROWS(support_tickets)`                                                   |
| 11  | `Total_Txn_Volume`          | `SUM(transactions[Amount_Abs])`                                        |
| 12  | `Total_Card_Txn_Volume`     | `SUM(card_transactions[amount])`                                               |
| 13  | `Total_Deposits_Balance`    | `SUM(accounts[balance])`                                                       |
| 14  | `Total_Loan_Book`           | `SUM(loans[loan_amount])`                                                      |
| 15  | `Active_Accounts`           | `CALCULATE(COUNTROWS(accounts), accounts[status]="Active")`                  |
| 16  | `Dormant_Accounts`          | `CALCULATE(COUNTROWS(accounts), accounts[status]="Dormant")`                 |
| 17  | `Closed_Accounts`           | `CALCULATE(COUNTROWS(accounts), accounts[status]="Closed")`                  |
| 18  | `Blocked_Cards`             | `CALCULATE(COUNTROWS(cards), cards[status]="Blocked")`                       |
| 19  | `Expired_Cards`             | `CALCULATE(COUNTROWS(cards), cards[Is_Expired]=TRUE())`                      |
| 20  | `Active_Cards`              | `CALCULATE(COUNTROWS(cards), cards[status]="Active")`                        |
| 21  | `NPA_Loans`                 | `CALCULATE(COUNTROWS(loans), loans[Is_NPA]=TRUE())`                          |
| 22  | `Active_Loans`              | `CALCULATE(COUNTROWS(loans), loans[status]="Active")`                        |
| 23  | `Closed_Loans`              | `CALCULATE(COUNTROWS(loans), loans[status]="Closed")`                        |
| 24  | `Open_Tickets`              | `CALCULATE(COUNTROWS(support_tickets), support_tickets[status]="Open")`      |
| 25  | `Escalated_Tickets`         | `CALCULATE(COUNTROWS(support_tickets), support_tickets[status]="Escalated")` |
| 26  | `Late_Payments`             | `CALCULATE(COUNTROWS(loan_payments), loan_payments[Is_Late]=TRUE())`         |
| 27  | `Total_Payments_Received`   | `SUM(loan_payments[amount_paid])`                                              |
| 28  | `Total_Principal_Collected` | `SUM(loan_payments[principal_component])`                                      |
| 29  | `Total_Interest_Collected`  | `SUM(loan_payments[interest_component])`                                       |
| 30  | `Fraud_Transactions`        | `CALCULATE(COUNTROWS(card_transactions), card_transactions[is_fraud]=1)`     |

============================================================
  SECTION 5.2 — AVERAGE MEASURES — 15 measures
  ============================================================
| # | Measure | DAX |
|---|---------|-----|
| 1 | `Avg_Account_Balance` | `AVERAGE(accounts[balance])` |
| 2 | `Avg_Loan_Amount` | `AVERAGE(loans[loan_amount])` |
| 3 | `Avg_Interest_Rate` | `AVERAGE(loans[interest_rate])` |
| 4 | `Avg_Credit_Score` | `AVERAGE(customers[credit_score])` |
| 5 | `Avg_Customer_Age` | `AVERAGE(customers[Customer_Age])` |
| 6 | `Avg_Customer_Tenure` | `AVERAGE(customers[Customer_Tenure_Years])` |
| 7 | `Avg_Txn_Amount` | `AVERAGE(transactions[Amount_Abs])` |
| 8 | `Avg_Card_Txn_Amount` | `AVERAGE(card_transactions[amount])` |
| 9 | `Avg_Resolution_Days` | `CALCULATE(AVERAGE(support_tickets[Resolution_Days]), NOT(ISBLANK(support_tickets[Resolution_Days])))` |
| 10 | `Avg_Satisfaction_Score` | `AVERAGE(support_tickets[satisfaction_score])` |
| 11 | `Avg_Salary` | `AVERAGE(employees[salary])` |
| 12 | `Avg_Credit_Limit` | `AVERAGE(cards[credit_limit])` |
| 13 | `Avg_Loan_Term` | `AVERAGE(loans[term_months])` |
| 14 | `Avg_Payment_Amount` | `AVERAGE(loan_payments[amount_paid])` |
| 15 | `Avg_Resolution_Days_Resolved` | `CALCULATE(AVERAGEX(FILTER(support_tickets, NOT(ISBLANK(support_tickets[Resolution_Days]))), support_tickets[Resolution_Days]))` |

============================================================
  SECTION 5.3 — RISK METRICS — 20 measures
  ============================================================
| # | Measure | DAX |
|---|---------|-----|
| 1 | `Fraud_Count` | `CALCULATE(COUNTROWS(card_transactions), card_transactions[is_fraud] = 1)` |
| 2 | `Fraud_Rate_%` | `VAR FraudCount = [Fraud_Count] VAR TotalTxns = [Total_card_transactionss] RETURN DIVIDE(FraudCount, TotalTxns, 0) * 100` |
| 3 | `Fraud_Amount` | `CALCULATE(SUM(card_transactions[amount]), card_transactions[is_fraud] = 1)` |
| 4 | `Fraud_Amount_Pct` | `DIVIDE([Fraud_Amount], [Total_Card_Txn_Volume], 0) * 100` |
| 5 | `NPA_Count` | `[NPA_Loans]` |
| 6 | `NPA_Rate_%` | `VAR NPALoans = [NPA_Loans] VAR TotalLoans = [Total_Loans] RETURN DIVIDE(NPALoans, TotalLoans, 0) * 100` |
| 7 | `NPA_Amount` | `CALCULATE(SUM(loans[loan_amount]), loans[Is_NPA] = TRUE())` |
| 8 | `NPA_Amount_Pct` | `DIVIDE([NPA_Amount], [Total_Loan_Book], 0) * 100` |
| 9 | `Late_Payment_Count` | `[Late_Payments]` |
| 10 | `Late_Payment_Rate_%` | `VAR LatePayments = [Late_Payments] VAR TotalPayments = [Total_Loan_Payments] RETURN DIVIDE(LatePayments, TotalPayments, 0) * 100` |
| 11 | `Late_Payment_Amount` | `CALCULATE(SUM(loan_payments[amount_paid]), loan_payments[Is_Late] = TRUE())` |
| 12 | `Written_Off_Count` | `CALCULATE(COUNTROWS(loans), loans[status] = "Written Off")` |
| 13 | `Defaulted_Count` | `CALCULATE(COUNTROWS(loans), loans[status] = "Defaulted")` |
| 14 | `Risk_Score_Weighted` | `([NPA_Rate_%] * 0.40) + ([Fraud_Rate_%] * 1.50) + ([Late_Payment_Rate_%] * 0.20)` |
| 15 | `Risk_Tier_Distribution_High_Risk_Count` | `CALCULATE(COUNTROWS(loans), loans[Risk_Tier] = "High Risk")` |
| 16 | `Risk_Tier_Distribution_Low_Risk_Count` | `CALCULATE(COUNTROWS(loans), loans[Risk_Tier] = "Low Risk")` |
| 17 | `High_Utilization_Cards` | `VAR UtilThreshold = 0.80 RETURN CALCULATE(DISTINCTCOUNT(card_transactions[card_id]), FILTER(SUMMARIZE(card_transactions, card_transactions[card_id], "TotalSpend", SUM(card_transactions[amount])), [TotalSpend] > UtilThreshold * 100000))` |
| 18 | `Card_Block_Rate_%` | `DIVIDE([Blocked_Cards], [Total_Cards], 0) * 100` |
| 19 | `Dormant_Account_Rate_%` | `DIVIDE([Dormant_Accounts], [Total_Accounts], 0) * 100` |
| 20 | `Portfolio_At_Risk` | `[NPA_Amount] + [Late_Payment_Amount]` |

============================================================
  SECTION 5.4 — TIME INTELLIGENCE — 30 measures
  ============================================================
| # | Measure | DAX |
|---|---------|-----|
| 1 | `Txn_Volume_YTD` | `TOTALYTD([Total_Txn_Volume], Date[Date])` |
| 2 | `Txn_Volume_Prev_Month` | `CALCULATE([Total_Txn_Volume], DATEADD(Date[Date], -1, MONTH))` |
| 3 | `Txn_Volume_MoM_%` | `VAR CurrentMonth = [Total_Txn_Volume] VAR PrevMonth = [Txn_Volume_Prev_Month] RETURN DIVIDE(CurrentMonth - PrevMonth, PrevMonth, 0) * 100` |
| 4 | `Txn_Volume_Prev_Year` | `CALCULATE([Total_Txn_Volume], SAMEPERIODLASTYEAR(Date[Date]))` |
| 5 | `Txn_Volume_YoY_%` | `VAR CurrentYear = [Total_Txn_Volume] VAR PrevYear = [Txn_Volume_Prev_Year] RETURN DIVIDE(CurrentYear - PrevYear, PrevYear, 0) * 100` |
| 6 | `Txn_Count_YTD` | `TOTALYTD([Total_Transactions], Date[Date])` |
| 7 | `Txn_Count_Prev_Month` | `CALCULATE([Total_Transactions], DATEADD(Date[Date], -1, MONTH))` |
| 8 | `Txn_Count_MoM_%` | `VAR Cur = [Total_Transactions] VAR Prev = [Txn_Count_Prev_Month] RETURN DIVIDE(Cur - Prev, Prev, 0) * 100` |
| 9 | `Txn_Count_Prev_Year` | `CALCULATE([Total_Transactions], SAMEPERIODLASTYEAR(Date[Date]))` |
| 10 | `Txn_Count_YoY_%` | `VAR Cur = [Total_Transactions] VAR Prev = [Txn_Count_Prev_Year] RETURN DIVIDE(Cur - Prev, Prev, 0) * 100` |
| 11 | `Fraud_Rate_YTD` | `VAR FraudYTD = TOTALYTD([Fraud_Count], Date[Date]) VAR TxnsYTD = TOTALYTD([Total_card_transactionss], Date[Date]) RETURN DIVIDE(FraudYTD, TxnsYTD, 0) * 100` |
| 12 | `Fraud_Rate_Prev_Month` | `CALCULATE([Fraud_Rate_%], DATEADD(Date[Date], -1, MONTH))` |
| 13 | `Fraud_Rate_MoM_%` | `[Fraud_Rate_%] - [Fraud_Rate_Prev_Month]` |
| 14 | `NPA_Rate_YTD` | `VAR NPACount = [NPA_Loans] VAR TotalLoansCount = [Total_Loans] RETURN DIVIDE(NPACount, TotalLoansCount, 0) * 100` |
| 15 | `NPA_Rate_Prev_Year` | `CALCULATE([NPA_Rate_%], DATEADD(Date[Date], -1, YEAR))` |
| 16 | `NPA_Rate_YoY_%` | `[NPA_Rate_%] - [NPA_Rate_Prev_Year]` |
| 17 | `Deposits_Balance_YTD` | `TOTALYTD([Total_Deposits_Balance], Date[Date])` |
| 18 | `Deposits_Balance_Prev_Year` | `CALCULATE([Total_Deposits_Balance], SAMEPERIODLASTYEAR(Date[Date]))` |
| 19 | `Deposits_Balance_YoY_%` | `VAR Cur = [Total_Deposits_Balance] VAR Prev = [Deposits_Balance_Prev_Year] RETURN DIVIDE(Cur - Prev, Prev, 0) * 100` |
| 20 | `Loan_Book_YTD` | `TOTALYTD([Total_Loan_Book], Date[Date])` |
| 21 | `Loan_Book_Prev_Year` | `CALCULATE([Total_Loan_Book], SAMEPERIODLASTYEAR(Date[Date]))` |
| 22 | `Loan_Book_YoY_%` | `VAR Cur = [Total_Loan_Book] VAR Prev = [Loan_Book_Prev_Year] RETURN DIVIDE(Cur - Prev, Prev, 0) * 100` |
| 23 | `Late_Payment_Rate_YTD` | `VAR LateYTD = TOTALYTD([Late_Payments], Date[Date]) VAR TotalYTD = TOTALYTD([Total_Loan_Payments], Date[Date]) RETURN DIVIDE(LateYTD, TotalYTD, 0) * 100` |
| 24 | `Late_Payment_Rate_Prev_Month` | `CALCULATE([Late_Payment_Rate_%], DATEADD(Date[Date], -1, MONTH))` |
| 25 | `Late_Payment_Rate_MoM_%` | `[Late_Payment_Rate_%] - [Late_Payment_Rate_Prev_Month]` |
| 26 | `Rolling_30D_Txn_Volume` | `CALCULATE([Total_Txn_Volume], DATESINPERIOD(Date[Date], MAX(Date[Date]), -30, DAY))` |
| 27 | `Rolling_7D_Txn_Count` | `CALCULATE([Total_Transactions], DATESINPERIOD(Date[Date], MAX(Date[Date]), -7, DAY))` |
| 28 | `Rolling_90D_Fraud_Rate` | `CALCULATE([Fraud_Rate_%], DATESINPERIOD(Date[Date], MAX(Date[Date]), -90, DAY))` |
| 29 | `3_Month_Moving_Avg_Volume` | `CALCULATE(AVERAGEX(VALUES(Date[YearMonth]), [Total_Txn_Volume]), DATESINPERIOD(Date[Date], MAX(Date[Date]), -3, MONTH))` |
| 30 | `Cumulative_Txn_Volume` | `CALCULATE([Total_Txn_Volume], FILTER(ALL(Date[Date]), Date[Date] <= MAX(Date[Date])))` |
| 31 | `Cumulative_Fraud_Count` | `CALCULATE([Fraud_Count], FILTER(ALL(Date[Date]), Date[Date] <= MAX(Date[Date])))` |

============================================================
  SECTION 5.5 — CUSTOMER SEGMENTATION — 15 measures
  ============================================================
| # | Measure | DAX |
|---|---------|-----|
| 1 | `Active_Customers` | `CALCULATE(DISTINCTCOUNT(accounts[customer_id]), accounts[Is_Active] = TRUE())` |
| 2 | `New_Customers_MTD` | `VAR StartOfMonth = STARTOFMONTH(Date[Date]) RETURN CALCULATE(COUNTROWS(customers), customers[join_date] >= StartOfMonth)` |
| 3 | `New_Customers_YTD` | `VAR StartOfYear = STARTOFYEAR(Date[Date]) RETURN CALCULATE(COUNTROWS(customers), customers[join_date] >= StartOfYear)` |
| 4 | `Customer_Retention_%` | `VAR PrevPeriodCustomers = CALCULATE(DISTINCTCOUNT(customers[customer_id]), DATEADD(Date[Date], -1, YEAR)) VAR RetainedCustomers = CALCULATE(DISTINCTCOUNT(customers[customer_id]), DATESBETWEEN(Date[Date], MIN(Date[Date]), MAX(Date[Date])), USERELATIONSHIP(Date[Date], transactions[txn_date])) RETURN DIVIDE(RetainedCustomers, PrevPeriodCustomers, 0) * 100` |
| 5 | `Customer_Churn_%` | `100 - [Customer_Retention_%]` |
| 6 | `High_Value_Customers` | `CALCULATE(COUNTROWS(customers), customers[annual_income] > 3000000)` |
| 7 | `Low_Credit_Customers` | `CALCULATE(COUNTROWS(customers), customers[credit_score] < 580)` |
| 8 | `Premium_Long_Term_Customers` | `CALCULATE(COUNTROWS(customers), customers[Customer_Segment] = "Premium Long-Term")` |
| 9 | `R_Score` | `VAR CustomerLastTxn = MAX(transactions[txn_date]) VAR DaysSince = DATEDIFF(CustomerLastTxn, TODAY(), DAY) RETURN SWITCH(TRUE(), DaysSince <= 30, 5, DaysSince <= 90, 4, DaysSince <= 180, 3, DaysSince <= 365, 2, 1)` |
| 10 | `F_Score` | `VAR TxnCount90D = CALCULATE(COUNTROWS(transactions), DATESINPERIOD(Date[Date], MAX(Date[Date]), -90, DAY)) RETURN SWITCH(TRUE(), TxnCount90D >= 50, 5, TxnCount90D >= 25, 4, TxnCount90D >= 10, 3, TxnCount90D >= 1, 2, 1)` |
| 11 | `M_Score` | `VAR Spend90D = CALCULATE(SUM(card_transactions[amount]), DATESINPERIOD(Date[Date], MAX(Date[Date]), -90, DAY)) RETURN SWITCH(TRUE(), Spend90D >= 100000, 5, Spend90D >= 50000, 4, Spend90D >= 20000, 3, Spend90D >= 5000, 2, 1)` |
| 12 | `RFM_Score` | `[R_Score] + [F_Score] + [M_Score]` |
| 13 | `Customer_Lifetime_Value` | `DIVIDE([Total_Txn_Volume], [Total_Customers], 0)` |
| 14 | `Avg_Tenure_Years` | `[Avg_Customer_Tenure]` |
| 15 | `Avg_Customer_Age_Distinct` | `[Avg_Customer_Age]` |
| 16 | `Customers_by_Segment` | `COUNTROWS(customers)` |

============================================================
  SECTION 5.6 — BRANCH PERFORMANCE — 15 measures
  ============================================================
| # | Measure | DAX |
|---|---------|-----|
| 1 | `Branch_Account_Count` | `CALCULATE(COUNTROWS(accounts), CROSSFILTER(branchs[Branch_ID], accounts[branch_id], BOTH))` |
| 2 | `Branch_Loan_Book` | `CALCULATE(SUM(loans[loan_amount]), CROSSFILTER(branchs[Branch_ID], loans[branch_id], BOTH))` |
| 3 | `Branch_NPA_Rate_%` | `VAR NPAs = CALCULATE([NPA_Loans], CROSSFILTER(branchs[Branch_ID], loans[branch_id], BOTH)) VAR AllLoans = CALCULATE([Total_Loans], CROSSFILTER(branchs[Branch_ID], loans[branch_id], BOTH)) RETURN DIVIDE(NPAs, AllLoans, 0) * 100` |
| 4 | `Branch_Txn_Volume` | `CALCULATE([Total_Txn_Volume], CROSSFILTER(branchs[Branch_ID], accounts[branch_id], BOTH))` |
| 5 | `Branch_Rank_By_Loan_Book` | `RANKX(ALL(branchs), [Branch_Loan_Book], , DESC, DENSE)` |
| 6 | `Branch_Rank_By_Account_Count` | `RANKX(ALL(branchs), [Branch_Account_Count], , DESC, DENSE)` |
| 7 | `Branch_Rank_By_NPA_Rate` | `RANKX(ALL(branchs), [Branch_NPA_Rate_%], , DESC, DENSE)` |
| 8 | `Branch_Deposit_Balance` | `CALCULATE(SUM(accounts[balance]), CROSSFILTER(branchs[Branch_ID], accounts[branch_id], BOTH))` |
| 9 | `Branch_Avg_Account_Balance` | `DIVIDE([Branch_Deposit_Balance], [Branch_Account_Count], 0)` |
| 10 | `Branch_Top_Merchant_Category` | `VAR TopMerchant = TOPN(1, SUMMARIZE(transactions, transactions[merchant_category], "TxnVol", SUM(transactions[Amount_Abs])), [TxnVol], DESC) RETURN SELECTCOLUMNS(TopMerchant, "Merchant", transactions[merchant_category])` |
| 11 | `Branch_Fraud_Rate_%` | `[Fraud_Rate_%]` |
| 12 | `Branch_Employee_Count` | `CALCULATE(COUNTROWS(employees), CROSSFILTER(branchs[Branch_ID], employees[branch_id], BOTH))` |
| 13 | `Branch_Customer_Count` | `CALCULATE(DISTINCTCOUNT(accounts[customer_id]), CROSSFILTER(branchs[Branch_ID], accounts[branch_id], BOTH))` |
| 14 | `Branch_Txn_Count` | `CALCULATE(COUNTROWS(transactions), CROSSFILTER(branchs[Branch_ID], accounts[branch_id], BOTH))` |
| 15 | `Branch_YoY_Growth_%` | `VAR Cur = [Branch_Txn_Volume] VAR Prev = CALCULATE([Branch_Txn_Volume], SAMEPERIODLASTYEAR(Date[Date])) RETURN DIVIDE(Cur - Prev, Prev, 0) * 100` |

============================================================
  SECTION 5.7 — KPI STATUS / CONDITIONAL FORMATTING — 10 measures
  ============================================================
| # | Measure | DAX |
|---|---------|-----|
| 1 | `KPI_Status_Fraud` | `VAR Rate = [Fraud_Rate_%] RETURN SWITCH(TRUE(), Rate > 1.0, "🔴", Rate > 0.5, "🟡", "🟢")` |
| 2 | `KPI_Status_NPA` | `VAR Rate = [NPA_Rate_%] RETURN SWITCH(TRUE(), Rate > 8.0, "🔴", Rate > 5.0, "🟡", "🟢")` |
| 3 | `KPI_Status_Satisfaction` | `VAR Score = [Avg_Satisfaction_Score] RETURN SWITCH(TRUE(), Score < 3.0, "🔴", Score < 4.0, "🟡", "🟢")` |
| 4 | `KPI_Status_Late_Payment` | `VAR Rate = [Late_Payment_Rate_%] RETURN SWITCH(TRUE(), Rate > 15.0, "🔴", Rate > 10.0, "🟡", "🟢")` |
| 5 | `KPI_Status_Resolution_Time` | `VAR Days = [Avg_Resolution_Days] RETURN SWITCH(TRUE(), Days > 14.0, "🔴", Days > 7.0, "🟡", "🟢")` |
| 6 | `KPI_Status_Active_Account_Rate` | `VAR ActiveRate = DIVIDE([Active_Accounts], [Total_Accounts], 0) * 100 RETURN SWITCH(TRUE(), ActiveRate < 70.0, "🔴", ActiveRate < 85.0, "🟡", "🟢")` |
| 7 | `KPI_Status_Card_Block_Rate` | `VAR BlockRate = [Card_Block_Rate_%] RETURN SWITCH(TRUE(), BlockRate > 10.0, "🔴", BlockRate > 5.0, "🟡", "🟢")` |
| 8 | `KPI_Status_Fraud_Trend` | `VAR Delta = [Fraud_Rate_MoM_%] RETURN SWITCH(TRUE(), Delta > 0.05, "⚠️ Worsening", Delta < -0.05, "✅ Improving", "➡️ Stable")` |
| 9 | `KPI_Status_NPA_Trend` | `VAR Delta = [NPA_Rate_YoY_%] RETURN SWITCH(TRUE(), Delta > 1.0, "⚠️ Worsening", Delta < -1.0, "✅ Improving", "➡️ Stable")` |
| 10 | `YoY_Growth_Color` | `VAR Growth = [Txn_Volume_YoY_%] RETURN SWITCH(TRUE(), Growth > 10, "#06A77D", Growth > 0, "#2A9D8F", Growth > -10, "#F4A261", "#E63946")` |


============================================================
  SECTION 5.8 — ADVANCED DAX PATTERNS — 20 measures
  ============================================================
| # | Measure | DAX |
|---|---------|-----|
| 1 | `Top_5_Merchant_Categories_By_Volume` | `TOPN(5, SUMMARIZE(transactions, transactions[merchant_category], "TotalVolume", SUM(transactions[Amount_Abs])), [TotalVolume], DESC)` |
| 2 | `Top_10_Branches_By_Loan_Book` | `TOPN(10, ADDCOLUMNS(ALL(branchs[Branch_Name]), "LoanBook", [Branch_Loan_Book]), [LoanBook], DESC)` |
| 3 | `Cumulative_Txn_Volume_By_Month` | `CALCULATE([Total_Txn_Volume], FILTER(ALL(Date[YearMonth]), Date[YearMonth] <= MAX(Date[YearMonth])))` |
| 4 | `Same_Store_Growth` | `VAR CurrentCustomers = VALUES(accounts[Account_ID]) VAR PrevYearCustomers = CALCULATETABLE(VALUES(accounts[Account_ID]), DATEADD(Date[Date], -1, YEAR)) VAR Overlap = INTERSECT(CurrentCustomers, PrevYearCustomers) RETURN DIVIDE(CALCULATE([Total_Txn_Volume], Overlap), CALCULATE([Total_Txn_Volume], PrevYearCustomers), 0) - 1` |
| 5 | `Customer_Cohort_Retention_%` | `VAR CohortYear = SELECTEDVALUE(customers[Customer_Tenure_Years]) VAR CohortCustomers = FILTER(ALL(customers), customers[Customer_Tenure_Years] = CohortYear) VAR Retained = CALCULATE(DISTINCTCOUNT(customers[customer_id]), FILTER(transactions, RELATED(customers[Customer_Tenure_Years]) = CohortYear)) RETURN DIVIDE(Retained, COUNTROWS(CohortCustomers), 0) * 100` |
| 6 | `Pareto_80_20_Merchants` | `VAR MerchantVolume = ADDCOLUMNS(ALL(transactions[merchant_category]), "Vol", CALCULATE(SUM(transactions[Amount_Abs]))) VAR TotalVol = SUMX(MerchantVolume, [Vol]) VAR Ranked = ADDCOLUMNS(MerchantVolume, "CumPct", VAR MyVol = [Vol] VAR CumulativeVol = SUMX(FILTER(MerchantVolume, [Vol] >= MyVol), [Vol]) RETURN DIVIDE(CumulativeVol, TotalVol, 0)) RETURN SELECTCOLUMNS(Ranked, "Merchant", transactions[merchant_category], "CumPct", [CumPct])` |
| 7 | `Anomaly_Count` | `VAR Mean = [Avg_Txn_Amount] VAR StdDev = STDEV.P(transactions[Amount_Abs]) VAR Threshold = 2.5 RETURN COUNTROWS(FILTER(transactions, ABS(transactions[Amount_Abs] - Mean) > Threshold * StdDev))` |
| 8 | `Anomaly_Rate_%` | `DIVIDE([Anomaly_Count], [Total_Transactions], 0) * 100` |
| 9 | `Customer_Conversion_Rate` | `DIVIDE([New_Customers_YTD], [Total_Customers], 0) * 100` |
| 10 | `Avg_Txn_Per_Customer` | `DIVIDE([Total_Transactions], [Total_Customers], 0)` |
| 11 | `Avg_Loans_Per_Customer` | `DIVIDE([Total_Loans], [Total_Customers], 0)` |
| 12 | `Portfolio_Concentration_Ratio` | `VAR TopCustomers = TOPN(ROUNDUP([Total_Customers] * 0.10, 0), ADDCOLUMNS(ALL(customers[Customer_ID]), "Vol", CALCULATE(SUM(transactions[Amount_Abs]))), [Vol], DESC) VAR TopVol = SUMX(TopCustomers, [Vol]) RETURN DIVIDE(TopVol, [Total_Txn_Volume], 0)` |
| 13 | `Risk_Weighted_Assets` | `SUMX(loans, loans[loan_amount] * SWITCH(loans[Risk_Tier], "High Risk", 1.50, "Elevated Risk", 1.25, "Moderate Risk", 1.00, "Low Risk", 0.80, 1.00))` |
| 14 | `Expected_Loss` | `[NPA_Amount] * 0.45` |
| 15 | `Capital_Adequacy_Ratio` | `VAR CapitalBase = [Total_Loan_Book] * 0.12 RETURN DIVIDE(CapitalBase, [Risk_Weighted_Assets], 0) * 100` |
| 16 | `Net_Interest_Margin_Estimate` | `DIVIDE([Total_Interest_Collected] - 0.04 * [Total_Deposits_Balance], [Total_Loan_Book], 0) * 100` |
| 17 | `Customer_Lifetime_Value_Estimate` | `[Avg_Txn_Amount] * 12 * [Avg_Customer_Tenure]` |
| 18 | `Cost_To_Serve_Per_Ticket` | `250` |
| 19 | `Total_Support_Cost` | `[Cost_To_Serve_Per_Ticket] * CALCULATE(COUNTROWS(support_tickets), NOT(ISBLANK(support_tickets[date_resolved])))` |
| 20 | `Customer_Profitability_Index` | `VAR AvgIncome = AVERAGE(customers[annual_income]) VAR AvgBal = [Avg_Account_Balance] VAR TxnPerCust = [Avg_Txn_Per_Customer] RETURN (AvgIncome * 0.30 + AvgBal * 0.30 + TxnPerCust * 0.40) / 1000` |

