# Banking Transactions Deep Analysis

A full-stack retail-banking analytics project covering 10 tables and ~5.8 million rows (transactions, cards, loans, payments, support tickets), delivered as an end-to-end analytics pipeline: Python EDA, SQL queries, DAX measures, Excel workbook, and a Power BI dashboard.

## Overview

- **Data source**: Kaggle `vivekmali1436/banking-transactions-dataset`
- **Scale**: 60,000 customers · 95,000 accounts · 65,000 cards · 22,000 loans · 150 branches · 5M+ transactions
- **Currency**: INR (₹) · **Analysis date**: 17 Oct 2026
- **Approach**: CRISP-DM style flow — loading → profiling → standardization → feature engineering → descriptive analytics → statistical testing → prescriptive recommendations

## Key Findings

- Annual transaction volume of **₹12.10 B** against a **₹9.21 B** loan book.
- Portfolio NPA rate of **10.10%**; card-fraud rate of **0.50%**.
- Average customer credit score **599.70** (Fair band).
- Average support-ticket resolution time **9.49 days**, satisfaction **3.00/5**.
- Two priority risk concentrations: **Gold & Education loans** driving NPA book; **ATM-withdrawal merchant fraud** driving card losses.

## Project Structure

```
Banking analysis/
├── Baning.ipynb                      # Canonical narrative notebook
├── Data/                             # Raw CSVs (10 tables)
├── PowerBi/Data_Analysis_PowerBi.pbit# Powerbi dashboard
├── charts/                           # 39 PNG visualizations
├── dax/Banking.txt                   # Dax added columns and measures
├── sql/Banking Analysis.sql          # SQL analytics queries
├── kpi/json/                         # Headline KPIs
└── README.md
```

## Tech Stack

Python (NumPy, pandas, Matplotlib, Seaborn, SciPy), SQL, DAX, Power BI, Excel, Jupyter Notebook.

## Deliverables

- 39 charts with business interpretations
- Headline KPIs JSON
- SQL query pack
- DAX measure library
- Power BI dashboard (.pbix)
- Excel analysis workbook

## How to Run

1. Clone the repo and place Kaggle dataset under `Data/`.
2. Open `Baning.ipynb` in Jupyter and run all cells.
3. Open `PowerBi/Data_Analysis_PowerBi 01.pdf` in Power BI Desktop.

## Resume Bullet Points

- Analyzed 5.8M-row retail-banking dataset across 10 tables (60K customers, 95K accounts, 22K loans) using Python, SQL, and Power BI.
- Built end-to-end analytics pipeline (EDA, feature engineering, statistical testing) producing 39 charts and a Power BI dashboard.
- Identified NPA concentration in Gold & Education loans and ATM-merchant card fraud, quantifying ₹ impact.
- Delivered stakeholder-ready KPIs, DAX measures, and Excel workbook for executive reporting.
