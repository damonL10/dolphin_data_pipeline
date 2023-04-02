from pyspark.sql import SparkSession
from dotenv import load_dotenv
import os
load_dotenv()

packages = [
    "org.mongodb.spark:mongo-spark-connector_2.12:3.0.1"
]

spark = SparkSession.builder.appName("ETL from csv to mongodb")\
    .master("spark://spark:7077")\
    .config("spark.jars.packages", ",".join(packages))\
    .getOrCreate()   

df_csv = spark.read.csv(path = "./csvdata/hkgov_covid_reportedcases_2022.csv", header=True, inferSchema=True)
# df_csv.printSchema()
# df_csv.show(1)

df_csv.createOrReplaceTempView("covidStatistics")
df_new = spark.sql("""
    SELECT `As of date` AS date,
    from_unixtime(unix_timestamp(`As of date`, 'dd/MM/yyyy'), 'yyyy-MM') AS year_month,
    `Number of confirmed cases` AS confirmed_cases,
    `Number of death cases` AS death_cases,
    `Number of cases tested positive for SARS-CoV-2 virus by nucleic acid tests` AS tested_positive_cases,
    `Number of cases tested positive for SARS-CoV-2 virus by rapid antigen tests` AS rapid_tested_positive_cases
    FROM covidStatistics
""")
df = df_new.fillna(value=0)
# df.show(5)
# df_new.printSchema()

MONGO_URI = os.getenv("MONGO_URI")
MONGO_DATABASE = os.getenv("MONGO_DATABASE")
MONGO_COLLECTION = os.getenv("MONGO_COLLECTION")  

df.write.format("mongo")\
    .option("spark.mongodb.output.uri", f"mongodb://{MONGO_URI}/{MONGO_DATABASE}.{MONGO_COLLECTION}")\
    .mode("append")\
    .save()
