from pyspark.sql import SparkSession
from dotenv import load_dotenv
load_dotenv()
import os

POSTGRES_HOST_APPLICATIONDB=os.getenv('POSTGRES_HOST_APPLICATIONDB')
POSTGRES_DB_APPLICATIONDB=os.getenv('POSTGRES_DB_APPLICATIONDB')
POSTGRES_HOST_DATAWAREHOUSE=os.getenv('POSTGRES_HOST_DATAWAREHOUSE')
POSTGRES_DB_DATAWAREHOUSE=os.getenv('POSTGRES_DB_DATAWAREHOUSE')
POSTGRES_USER=os.getenv('POSTGRES_USER')
POSTGRES_PASSWORD=os.getenv('POSTGRES_PASSWORD')
SPARK_MASTER=os.getenv('SPARK_MASTER')

packages = [
    "org.postgresql:postgresql:42.2.18"
    ]
spark = SparkSession.builder.appName("ETL from application db to data warehouse")\
        .master(f"spark://{SPARK_MASTER}:7077")\
        .config("spark.jars.packages",",".join(packages))\
        .getOrCreate()

transactions_query = """
    (SELECT 
        transactions.company_id,
        transactions.transaction_date,
        transactions.transaction_amount,
        transactions.payment_method,
        transactions.collect_point,
        transactions.coupon_used,
        transactions.coupon_id,
        transactions.customer_id,
        transactions.shop_id,
        customers.gender,
        customers.age_group,
        customers.occupation,
        customers.income_level,
        customers.living_district,
        companies.company_name,
        companies.industry_category,
        companies.business_type,
        shop_of_companies.shop_name,
        shop_of_companies.shop_location,
        coupons.coupon_name,
        coupons.description,
        coupons.coupon_value,
        coupons.points_required,
        coupons.valid_start,
        coupons.valid_until,
        coupons.is_expired,
        coupons.company_id coupon_company_id,
        coupons.created_at
    FROM transactions
    INNER JOIN customers ON customers.id = transactions.customer_id
    INNER JOIN companies ON companies.id = transactions.company_id
    INNER JOIN shop_of_companies ON shop_of_companies.id = transactions.shop_id
    INNER JOIN coupons ON coupons.id = transactions.coupon_id)
    transactions_details
    """

df = spark.read.format('jdbc') \
         .option('url',f"jdbc:postgresql://{POSTGRES_HOST_APPLICATIONDB}:5432/{POSTGRES_DB_APPLICATIONDB}")\
         .option('dbtable', transactions_query)\
         .option('user', POSTGRES_USER)\
         .option('password', POSTGRES_PASSWORD)\
         .option('driver','org.postgresql.Driver').load()

df.createOrReplaceTempView('transactions_table')
df_to_dw = spark.sql('''
    SELECT 
        company_id AS company_id,
        DATE_FORMAT(transaction_date, "yyyy-MM") AS transaction_year_month,
        EXTRACT (year FROM transaction_date) AS transaction_year,
        EXTRACT (month FROM transaction_date) AS transaction_month,
        EXTRACT (day FROM transaction_date) AS transaction_day,
        transaction_amount AS transaction_amount,
        payment_method AS payment_method,
        collect_point AS collect_point_or_not,
        coupon_used AS coupon_used_or_not,
        coupon_id AS transaction_coupon_id,
        customer_id AS transaction_customer_id,
        shop_id AS shop_id,
        gender AS customer_gender,
        age_group AS customer_age_group,
        occupation AS customer_occupation,
        income_level AS customer_income_level,
        living_district AS customer_living_district,
        company_name As company_name,
        industry_category AS industry_category,
        business_type AS business_type,
        shop_name AS shop_name,
        shop_location AS shop_location,
        coupon_name AS coupon_name,
        description AS coupon_description,
        coupon_value AS coupon_value,
        points_required AS points_required,
        valid_start AS coupon_valid_start,
        valid_until AS coupon_valid_until,
        is_expired AS coupon_is_expired_or_not,
        coupon_company_id AS coupon_company_id,
        DATE_FORMAT(created_at, "yyyy-MM") AS coupon_created_year_month,
        EXTRACT (year FROM created_at) AS coupon_created_year,
        EXTRACT (month FROM created_at) AS coupon_created_month,
        EXTRACT (day FROM created_at) AS coupon_created_day
    FROM transactions_table
''')

df_to_dw.show()

df_to_dw.write.format('jdbc')\
    .option('url',f"jdbc:postgresql://{POSTGRES_HOST_DATAWAREHOUSE}:5432/{POSTGRES_DB_DATAWAREHOUSE}")\
    .option('dbtable', 'staging_transactions')\
    .option('user', POSTGRES_USER)\
    .option('password', POSTGRES_PASSWORD)\
    .option('driver', 'org.postgresql.Driver')\
    .mode('append')\
    .save()