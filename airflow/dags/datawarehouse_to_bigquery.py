from dotenv import load_dotenv
load_dotenv()
from airflow import DAG
import airflow
from airflow.decorators import dag, task
import datetime
from datetime import timedelta
import logging
import psycopg2
from airflow.operators.python import PythonOperator
from airflow.operators.empty import EmptyOperator
from google.cloud import bigquery
import json

@dag(
    dag_id="a_data_from_datawarehouse_to_bigquery",
    start_date=datetime.datetime(2023, 2, 3),
    end_date=datetime.datetime(2023, 2, 4),
    default_args={
        'owner': 'damon',
        'retries':1,
        'retry_delay': timedelta(minutes=60),
    },
    schedule_interval="@daily",
    max_active_runs=1,
)

def datawarehouse_to_bigquery():

    @task
    def extractdatafromdatawarehouse():
        conn_ware = psycopg2.connect(dbname='datawarehouse1', user='', password='', host='', port='5431')
        logging.info("........................data warehouse connection established!!")

        cursor_ware = conn_ware.cursor()
        sql = """SELECT company_id,
                        transaction_year_month,
                        transaction_year,
                        transaction_month,
                        transaction_day,
                        transaction_amount,
                        payment_method,
                        collect_point_or_not,
                        coupon_used_or_not,
                        transaction_coupon_id,
                        transaction_customer_id,
                        shop_id,
                        customer_gender,
                        customer_age_group,
                        customer_occupation,
                        customer_income_level,
                        customer_living_district,
                        company_name,
                        industry_category,
                        business_type,
                        shop_name,
                        shop_location,
                        coupon_name,
                        coupon_description,
                        coupon_value,
                        points_required,
                        coupon_valid_start,
                        coupon_valid_until,
                        coupon_is_expired_or_not,
                        coupon_company_id,
                        coupon_created_year_month,
                        coupon_created_year,
                        coupon_created_month,
                        coupon_created_day
         FROM staging_transactions"""
        cursor_ware.execute(sql)
        rows=cursor_ware.fetchall()
        rowsarray_list=[]
        for row in rows:
            content = {'company_id': row[0], 'transaction_year_month': row[1], 'transaction_year': row[2], 'transaction_month': row[3], 'transaction_day': row[4], 'transaction_amount': row[5], 'payment_method': row[6], 'collect_point_or_not': row[7], 'coupon_used_or_not': row[8], 'transaction_coupon_id': row[9], 'transaction_customer_id': row[10], 'shop_id': row[11], 'customer_gender': row[12], 'customer_age_group': row[13], 'customer_occupation': row[14], 'customer_income_level': row[15], 'customer_living_district': row[16], 'company_name': row[17], 'industry_category': row[18], 'business_type': row[19], 'shop_name': row[20], 'shop_location': row[21], 'coupon_name': row[22], 'coupon_description': row[23], 'coupon_value': row[24], 'points_required': row[25], 'coupon_valid_start': row[26], 'coupon_valid_until': row[27], 'coupon_is_expired_or_not': row[28], 'coupon_company_id': row[29], 'coupon_created_year_month': row[30], 'coupon_created_year': row[31], 'coupon_created_month': row[32], 'coupon_created_day': row[33]}
            rowsarray_list.append(content)
        json_string = json.dumps(rowsarray_list, default=str)
        print(json_string)
        logging.info("........................data extracted from data warehouse!!")
        conn_ware.commit()
        cursor_ware.close()
        conn_ware.close()
        logging.info(".............................data warehouse disconnected!!")

        return json_string

    @task
    def loaddataintobigquery(json_string):
        datalist = json.loads(json_string)
        # print(datalist[0])

        client = bigquery.Client()
        data_to_bigquerytable = client.get_table('_______________.data_from_datawarehouse.bigquerytransactionstable')

        for data in datalist:
            client.insert_rows_json(data_to_bigquerytable,[data])
        logging.info("........................data loaded into Big Query!!")

    json_string = extractdatafromdatawarehouse()
    loaddataintobigquery(json_string)

datawarehouse_to_bigquery()