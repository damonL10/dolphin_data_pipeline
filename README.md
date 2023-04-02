# dolphin_data_pipeline
Data Pipeline of Dolphin

A. ETL data from Application Database

1. Data was extracted, transformed and loaded from Application Database to Data Warehouse via Apache Spark;

2. Data was further loaded to BigQuery by scheduled workflow via Apache Airflow;


B. ETL data of csv file downloaded from gov.hk

3. Data was extracted, transformed and loaded from csv file to mongoDB via Apache Spark;

4. Data was loaded to and consolidated in BigQuery;

5. Finally, using PowerBI to load the data from BigQuery for data visualisation, reporting and analysis.

If you have any queries/comments, please feel free to contact Damon.
