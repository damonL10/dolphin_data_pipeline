import os
from dotenv import load_dotenv
load_dotenv()

import pandas as pd
import pymongo
from google.cloud import bigquery
from google.cloud.bigquery import SchemaField

# mongodb config
MONGO_URI = os.getenv('MONGO_URI')
MONGO_DATABASE = os.getenv("MONGO_DATABASE")
MONGO_COLLECTION = os.getenv("MONGO_COLLECTION")

# extract, transform data from mongodb
mongoclient = pymongo.MongoClient(f"mongodb://{MONGO_URI}")
db = mongoclient[MONGO_DATABASE]
coll = db[MONGO_COLLECTION]
df = pd.DataFrame(list(coll.find()))
df = df.astype({"_id": str})
# print(df.head())
   
# load data to bigquery
bigqueryclient = bigquery.Client()
table_id = "data_from_datawarehouse.hkgov_statistics"
schema = []
schema.append(SchemaField("_id", "STRING"))
schema.append(SchemaField("date", "STRING"))
schema.append(SchemaField("year_month", "STRING"))
schema.append(SchemaField("confirmed_cases", "INTEGER"))
schema.append(SchemaField("death_cases", "INTEGER"))
schema.append(SchemaField("tested_positive_cases", "INTEGER"))
schema.append(SchemaField("rapid_tested_positive_cases", "INTEGER"))
job_config = bigquery.LoadJobConfig(
    schema=schema,
    write_disposition="WRITE_TRUNCATE"
)
job = bigqueryclient.load_table_from_dataframe(
    df, table_id, job_config=job_config
)
job.result()

mongoclient.close()