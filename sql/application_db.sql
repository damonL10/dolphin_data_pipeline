CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DROP TABLE IF EXISTS points;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS coupons_mapping;
DROP TABLE IF EXISTS coupons;
DROP TABLE IF EXISTS shop_of_companies;
DROP TABLE IF EXISTS companies;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    customer_uuid UUID DEFAULT uuid_generate_v4(),
    customer_name VARCHAR(60) not null,
    phone INTEGER not null,
    email VARCHAR(60) not null,
    username VARCHAR(60),
    password VARCHAR(60),
    gender VARCHAR(60),
    age_group VARCHAR(60),
    occupation VARCHAR(60),
    income_level VARCHAR(60),
    living_district VARCHAR(60),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE companies (
    id SERIAL PRIMARY KEY,
    company_name VARCHAR(60) not null,
    industry_category VARCHAR(60) not null,
    business_type VARCHAR(60) not null,
    username VARCHAR(60),
    password VARCHAR(60),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE shop_of_companies (
    id SERIAL PRIMARY KEY,
    shop_name VARCHAR(60) not null,
    shop_location VARCHAR(60) not null,
    company_id INTEGER not null,
    FOREIGN KEY (company_id) REFERENCES companies(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE coupons (
    id SERIAL PRIMARY KEY,
    coupon_name VARCHAR(60) not null,
    description VARCHAR(255) not null,
    coupon_value INTEGER not null,
    points_required INTEGER not null,
    valid_start DATE not null,
    valid_until DATE not null,
    is_expired BOOLEAN DEFAULT false not null,
    company_id INTEGER not null,
    FOREIGN KEY (company_id) REFERENCES companies(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE coupons_mapping (
    id SERIAL PRIMARY KEY,
    coupon_id INTEGER not null,
    coupon_uuid UUID DEFAULT uuid_generate_v4(),
    is_used BOOLEAN DEFAULT false not null,
    customer_id INTEGER not null,
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    transaction_date TIMESTAMP not null,
    transaction_amount DECIMAL(8,2) not null,
    payment_method VARCHAR(60) not null,
    collect_point BOOLEAN DEFAULT true not null,
    coupon_used BOOLEAN DEFAULT false not null,
    coupon_id INTEGER,
    FOREIGN KEY (coupon_id) REFERENCES coupons(id),
    customer_id INTEGER,
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    company_id INTEGER not null,
    FOREIGN KEY (company_id) REFERENCES companies(id),
    shop_id INTEGER not null,
    FOREIGN KEY (shop_id) REFERENCES shop_of_companies(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE points (
    id SERIAL PRIMARY KEY,
    point_amount INTEGER not null,
    point_type VARCHAR(60) not null,
    transaction_date TIMESTAMP DEFAULT NOW() not null,
    customer_id INTEGER not null,
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
