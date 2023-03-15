DROP TABLE IF EXISTS fact_transactions_details;
DROP TABLE IF EXISTS dim_transaction_datetimes;
DROP TABLE IF EXISTS dim_coupons;
DROP TABLE IF EXISTS dim_customers;
DROP TABLE IF EXISTS dim_shops;
DROP TABLE IF EXISTS dim_companies;
DROP TABLE IF EXISTS staging_transactions;


CREATE TABLE staging_transactions(
id SERIAL PRIMARY KEY,
company_id INTEGER,
transaction_year_month VARCHAR,
transaction_year INTEGER,
transaction_month INTEGER,
transaction_day INTEGER,
transaction_amount DECIMAL(8,2),
payment_method VARCHAR,
collect_point_or_not BOOLEAN,
coupon_used_or_not BOOLEAN,
transaction_coupon_id INTEGER,
transaction_customer_id INTEGER,
shop_id INTEGER,
customer_gender VARCHAR,
customer_age_group VARCHAR,
customer_occupation VARCHAR,
customer_income_level VARCHAR,
customer_living_district varchar,
company_name VARCHAR,
industry_category VARCHAR,
business_type VARCHAR,
shop_name VARCHAR,
shop_location VARCHAR,
coupon_name VARCHAR,
coupon_description VARCHAR,
coupon_value INTEGER,
points_required INTEGER,
coupon_valid_start DATE,
coupon_valid_until DATE,
coupon_is_expired_or_not BOOLEAN,
coupon_company_id INTEGER,
coupon_created_year_month VARCHAR,
coupon_created_year INTEGER,
coupon_created_month INTEGER,
coupon_created_day INTEGER,
created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE dim_companies(
id SERIAL PRIMARY KEY,
company_name VARCHAR,
industry_category VARCHAR,
business_type VARCHAR,
created_at TIMESTAMP DEFAULT NOW(),
updated_at TIMESTAMP DEFAULT NOW()
);

CREATE UNIQUE INDEX companies_unique_idx on dim_companies (company_name);

CREATE TABLE dim_shops(
id SERIAL PRIMARY KEY,
shop_name VARCHAR,
shop_location VARCHAR,
company_id INTEGER,
FOREIGN KEY (company_id) REFERENCES dim_companies(id),
created_at TIMESTAMP DEFAULT NOW(),
updated_at TIMESTAMP DEFAULT NOW()
);

CREATE UNIQUE INDEX shops_unique_idx on dim_shops (shop_name, shop_location);

CREATE TABLE dim_customers(
id SERIAL PRIMARY KEY,
customer_gender VARCHAR,
customer_age_group VARCHAR,
customer_occupation VARCHAR,
customer_income_level VARCHAR,
customer_living_district varchar,
created_at TIMESTAMP DEFAULT NOW(),
updated_at TIMESTAMP DEFAULT NOW()
);

CREATE UNIQUE INDEX customers_unique_idx on dim_customers (customer_gender, customer_age_group, customer_occupation, customer_income_level, customer_living_district);

CREATE TABLE dim_coupons(
id SERIAL PRIMARY KEY,
coupon_name VARCHAR,
coupon_description VARCHAR,
coupon_value INTEGER,
points_required INTEGER,
coupon_valid_start DATE,
coupon_valid_until DATE,
coupon_is_expired_or_not BOOLEAN,
coupon_company_id INTEGER,
FOREIGN KEY (coupon_company_id) REFERENCES dim_companies(id),
created_at TIMESTAMP DEFAULT NOW(),
updated_at TIMESTAMP DEFAULT NOW()
);

CREATE UNIQUE INDEX coupons_unique_idx on dim_coupons (coupon_name, coupon_description, coupon_value, points_required, coupon_valid_start, coupon_valid_until);

CREATE TABLE dim_transaction_datetimes(
id SERIAL PRIMARY KEY,
transaction_year_month VARCHAR,
transaction_year INTEGER,
transaction_month INTEGER,
transaction_day INTEGER,
created_at TIMESTAMP DEFAULT NOW(),
updated_at TIMESTAMP DEFAULT NOW()
);

CREATE UNIQUE INDEX transaction_datetimes_unique_idx on dim_transaction_datetimes (transaction_year_month, transaction_year, transaction_month, transaction_day);

CREATE TABLE fact_transactions_details(
id SERIAL PRIMARY KEY,
transaction_amount DECIMAL(8,2),
payment_method VARCHAR(60),
collect_point_or_not BOOLEAN,
coupon_used_or_not BOOLEAN,
transaction_coupon_id INTEGER,
FOREIGN KEY (transaction_coupon_id) REFERENCES dim_coupons(id),
transaction_customer_id INTEGER,
FOREIGN KEY (transaction_customer_id) REFERENCES dim_customers(id),
company_id INTEGER,
FOREIGN KEY (company_id) REFERENCES dim_companies(id),
shop_id INTEGER,
FOREIGN KEY (shop_id) REFERENCES dim_shops(id),
transaction_datetimes_id INTEGER,
FOREIGN KEY (transaction_datetimes_id) REFERENCES dim_transaction_datetimes(id),
created_at TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION insert_transactions() RETURNS trigger AS $$
    DECLARE
        company_id INTEGER;
        shop_id INTEGER;
        transaction_customer_id INTEGER;
        transaction_coupon_id INTEGER;
        transaction_datetimes_id INTEGER;
        
    BEGIN

        INSERT INTO dim_companies (company_name, industry_category, business_type) VALUES
            (NEW.company_name, NEW.industry_category, NEW.business_type) ON CONFLICT(company_name)
            DO UPDATE set updated_at = NOW() RETURNING id into company_id;

        INSERT INTO dim_shops (shop_name, shop_location, company_id) VALUES
            (NEW.shop_name, NEW.shop_location, company_id) ON CONFLICT(shop_name, shop_location)
            DO UPDATE set updated_at = NOW() RETURNING id into shop_id;

        INSERT INTO dim_customers (customer_gender, customer_age_group, customer_occupation, customer_income_level, customer_living_district) VALUES
            (NEW.customer_gender, NEW.customer_age_group, NEW.customer_occupation, NEW.customer_income_level, NEW.customer_living_district) ON CONFLICT(customer_gender, customer_age_group, customer_occupation, customer_income_level, customer_living_district)
            DO UPDATE set updated_at = NOW() RETURNING id into transaction_customer_id;

        INSERT INTO dim_coupons (coupon_name, coupon_description, coupon_value, points_required, coupon_valid_start, coupon_valid_until, coupon_is_expired_or_not, coupon_company_id) VALUES
            (NEW.coupon_name, NEW.coupon_description, NEW.coupon_value, NEW.points_required, NEW.coupon_valid_start, NEW.coupon_valid_until, NEW.coupon_is_expired_or_not, company_id) ON CONFLICT(coupon_name, coupon_description, coupon_value, points_required, coupon_valid_start, coupon_valid_until)
            DO UPDATE set updated_at = NOW() RETURNING id into transaction_coupon_id;

        INSERT INTO dim_transaction_datetimes (transaction_year_month, transaction_year, transaction_month, transaction_day) VALUES 
            (NEW.transaction_year_month, NEW.transaction_year, NEW.transaction_month, NEW.transaction_day) on conflict(transaction_year_month, transaction_year, transaction_month, transaction_day)
            DO UPDATE set updated_at = NOW() RETURNING id into transaction_datetimes_id;

        INSERT INTO fact_transactions_details (transaction_amount, payment_method, collect_point_or_not, coupon_used_or_not, transaction_coupon_id, transaction_customer_id, company_id, shop_id, transaction_datetimes_id) VALUES
            (NEW.transaction_amount, NEW.payment_method, NEW.collect_point_or_not, NEW.coupon_used_or_not, transaction_coupon_id, transaction_customer_id, company_id, shop_id, transaction_datetimes_id);
        return NEW;
    END
$$ LANGUAGE plpgsql;

CREATE TRIGGER transactions_trigger AFTER INSERT ON staging_transactions
FOR EACH ROW EXECUTE PROCEDURE insert_transactions();
