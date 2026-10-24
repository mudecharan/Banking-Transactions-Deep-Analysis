# The data set is avaliable at https://www.kaggle.com/datasets/vivekmali1436/banking-transactions-dataset/data

## The Data Overview
# Install dependencies as needed:
# pip install kagglehub[pandas-datasets]
import kagglehub
from kagglehub import KaggleDatasetAdapter

# Set the path to the file you'd like to load
file_path = ""

# Load the latest version
df = kagglehub.load_dataset(
  KaggleDatasetAdapter.PANDAS,
  "vivekmali1436/banking-transactions-dataset",
  file_path,
  # Provide any additional arguments like 
  # sql_query or pandas_kwargs. See the 
  # documenation for more information:
  # https://github.com/Kaggle/kagglehub/blob/main/README.md#kaggledatasetadapterpandas
)

print("First 5 records:", df.head())

# About Dataset
### Banking Dataset
A realistic synthetic banking dataset designed for SQL, Python, and Power BI projects.

### Features
Customers (Can be downloaded from kaggle)
Accounts (Avaliable)
Transactions (Can be downloaded from kaggle)
Cards (Avaliable)
Card Transactions (Can be downloaded from kaggle)
Loans (Can be downloaded from kaggle)
Loan Payments (Can be downloaded from kaggle)
Employees (Can be downloaded from kaggle)
Branches (Avaliable)
Support Tickets

