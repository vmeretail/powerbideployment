# Import required libraries
import sys
import pandas as pd
import numpy as np
from mlxtend.frequent_patterns import apriori
from mlxtend.frequent_patterns import association_rules
import pyodbc

print('Number of arguments: {}'.format(len(sys.argv)))
print('Argument(s) passed: {}'.format(str(sys.argv)))

# Set up the parameters
databaseName = sys.argv[1]

# Get the starting sales data to be mined
print('Python: ' + sys.version.split('|')[0])
print('Pandas: ' + pd.__version__)
print('pyODBC: ' + pyodbc.version)# parameters
DB = {'servername': 'eposity-datawarehouse.cpevcayzsht6.eu-west-1.rds.amazonaws.com', 'database': databaseName}

# create the connection
#conn = pyodbc.connect('DRIVER={SQL Server};SERVER=' + DB['servername'] + ';DATABASE=' + DB['database'] + ';UID=admin;PWD=treb8houp5boct_GHAN')
conn = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER=' + DB['servername'] + ';DATABASE=' + DB['database'] + ';UID=admin;PWD=treb8houp5boct_GHAN')

# query db
sql = """

DECLARE @startDate datetime
DECLARE @endDate datetime

set @startDate = CONVERT(DATE,DATEADD(DAY, -7, GETDATE()))
set @endDate = CONVERT(DATE,DATEADD(DAY, -1, GETDATE()))

SELECT BasketID = sl.AggregateId, sl.Quantity, StoreProductReportingId = sp.StoreProductReportingId
FROM salestransactioncompleted SH
INNER JOIN salestransactionline SL on SL.AggregateId = SH.AggregateId
inner join StoreProductStateProjection sp on sp.StoreProductId = sl.storeProductId
where sh.CompletedDate between @startDate and @endDate

"""
df = pd.read_sql(sql, conn)
df.head()
df.shape

# Flip the transactions to show a single line per basket
basket = (df
          .groupby(['BasketID','StoreProductReportingId'])['Quantity']
          .sum().unstack().reset_index().fillna(0)
          .set_index('BasketID'))
basket.head()
print(len(basket))

# Convert the quantity sum values to be boolean flags for apriori
def encode_units(x):
    if x <= 0:
        return 0
    if x >= 1:
        return 1    
    return 0

basket_sets = basket.applymap(encode_units)
#print(len(basket_sets))

# compute frequent items using the Apriori algorithm - Get up to three items
frequent_itemsets = apriori(basket_sets, min_support = 0.01, max_len = 3, use_colnames=True, low_memory=True)
print(len(frequent_itemsets))

# compute all association rules for frequent_itemsets
rules = association_rules(frequent_itemsets, metric="support", min_threshold=0.001)
print(len(rules))

# Creating a new dataframe to be used as the output for SQL tables
rules["antecedents"] = rules["antecedents"].apply(lambda x: list(x)[0]).astype("unicode")
rules["consequents"] = rules["consequents"].apply(lambda x: list(x)[0]).astype("unicode")
df3 = rules[['antecedents', 'consequents', 'support', 'lift']]
print(len(df3))

# Writing results into SQL server table

from sqlalchemy import create_engine
import urllib

server = 'eposity-datawarehouse.cpevcayzsht6.eu-west-1.rds.amazonaws.com'
database = databaseName
username = 'admin'
password = 'treb8houp5boct_GHAN'

params = urllib.parse.quote_plus(
'DRIVER={ODBC Driver 17 for SQL Server};'+
'SERVER='+server+';DATABASE='+database+';UID='+username+';PWD='+ password)

engine = create_engine("mssql+pyodbc:///?odbc_connect=%s" % params)

df3.to_sql(name = 'AI_BasketAnalysis_Last7Days', con = engine, if_exists = 'replace', index = False)