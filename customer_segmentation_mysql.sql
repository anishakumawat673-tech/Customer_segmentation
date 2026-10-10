-- =====================================================================
-- E-COMMERCE CUSTOMER SEGMENTATION - MySQL DATABASE & ANALYTICS
-- Database: ecommerce_analytics
-- Description: Table schema, data ingestion, and advanced business queries
--              for analyzing K-Means customer segments.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. DATABASE CREATION
-- ---------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS ecommerce_analytics;
USE ecommerce_analytics;

-- ---------------------------------------------------------------------
-- 2. TABLE SCHEMA DEFINITION
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS customer_segments;

CREATE TABLE customer_segments (
    customer_id INT PRIMARY KEY,
    birth_year INT,
    education_level VARCHAR(50),
    marital_status VARCHAR(50),
    annual_income DECIMAL(10, 2),
    kids_home INT,
    teens_home INT,
    customer_since DATE,
    last_purchase_recency INT,
    spent_wine DECIMAL(10, 2),
    spent_fruits DECIMAL(10, 2),
    spent_meat DECIMAL(10, 2),
    spent_fish DECIMAL(10, 2),
    spent_sweets DECIMAL(10, 2),
    spent_gold DECIMAL(10, 2),
    deals_purchased INT,
    web_purchases INT,
    catalog_purchases INT,
    store_purchases INT,
    monthly_web_visits INT,
    campaign1_accepted TINYINT,
    campaign2_accepted TINYINT,
    campaign3_accepted TINYINT,
    campaign4_accepted TINYINT,
    campaign5_accepted TINYINT,
    filed_complaint TINYINT,
    contact_cost DECIMAL(10, 2),
    revenue_contribution DECIMAL(10, 2),
    campaign_response TINYINT,
    country VARCHAR(100),
    city VARCHAR(100),
    region_code INT,
    mobile_app_user TINYINT,
    email_subscriber TINYINT,
    device_type VARCHAR(50),
    referred_by_friend TINYINT,
    social_media_user TINYINT,
    membership_tier VARCHAR(50),
    total_amount_spent DECIMAL(10, 2),
    customer_age INT,
    family_size INT,
    senior_citizen TINYINT,
    tenure_years DECIMAL(5, 2),
    total_children INT,
    total_purchases INT,
    campaigns_accepted INT,
    cluster_id INT,
    kmeans_segment VARCHAR(100),
    INDEX idx_cluster (cluster_id),
    INDEX idx_segment (kmeans_segment),
    INDEX idx_membership (membership_tier),
    INDEX idx_country (country)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 3. DATA IMPORT (VIA LOAD DATA INFILE)
-- Adjust filepath to your MySQL secure-file-priv directory if running via CLI:
-- ---------------------------------------------------------------------
/*
LOAD DATA INFILE '/var/lib/mysql-files/customer_data_clustered.csv'
INTO TABLE customer_segments
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    customer_id, birth_year, education_level, marital_status, annual_income,
    kids_home, teens_home, @customer_since_raw, last_purchase_recency,
    spent_wine, spent_fruits, spent_meat, spent_fish, spent_sweets, spent_gold,
    deals_purchased, web_purchases, catalog_purchases, store_purchases,
    monthly_web_visits, campaign1_accepted, campaign2_accepted, campaign3_accepted,
    campaign4_accepted, campaign5_accepted, filed_complaint, contact_cost,
    revenue_contribution, campaign_response, country, city, region_code,
    mobile_app_user, email_subscriber, device_type, referred_by_friend,
    social_media_user, membership_tier, total_amount_spent, customer_age,
    family_size, senior_citizen, tenure_years, total_children, total_purchases,
    campaigns_accepted, cluster_id, kmeans_segment
)
SET customer_since = STR_TO_DATE(@customer_since_raw, '%Y-%m-%d');
*/


-- =====================================================================
-- 4. BUSINESS ANALYTICS & SEGMENTATION QUERIES
-- =====================================================================

-- ---------------------------------------------------------------------
-- QUERY 1: EXECUTIVE SEGMENT OVERVIEW & REVENUE CONTRIBUTION
-- Purpose: Evaluate customer distribution, average spend, and % contribution
--          to total revenue across the 5 K-Means clusters.
-- ---------------------------------------------------------------------
WITH revenue_summary AS (
    SELECT SUM(total_amount_spent) AS grand_total_revenue
    FROM customer_segments
)
SELECT 
    cs.kmeans_segment,
    COUNT(cs.customer_id) AS total_customers,
    ROUND(COUNT(cs.customer_id) * 100.0 / (SELECT COUNT(*) FROM customer_segments), 2) AS customer_share_pct,
    ROUND(AVG(cs.annual_income), 2) AS avg_annual_income,
    ROUND(AVG(cs.family_size), 2) AS avg_family_size,
    ROUND(AVG(cs.total_amount_spent), 2) AS avg_customer_spend,
    ROUND(SUM(cs.total_amount_spent), 2) AS total_segment_revenue,
    ROUND(SUM(cs.total_amount_spent) * 100.0 / rs.grand_total_revenue, 2) AS revenue_share_pct
FROM customer_segments cs
CROSS JOIN revenue_summary rs
GROUP BY cs.kmeans_segment, rs.grand_total_revenue
ORDER BY total_segment_revenue DESC;


-- ---------------------------------------------------------------------
-- QUERY 2: OMNICHANNEL CHANNEL PREFERENCE BY SEGMENT
-- Purpose: Identify which purchase channels (Web, Store, Catalog) dominate
--          for each cohort to allocate marketing spend effectively.
-- ---------------------------------------------------------------------
SELECT 
    kmeans_segment,
    ROUND(AVG(store_purchases), 2) AS avg_store_purchases,
    ROUND(AVG(web_purchases), 2) AS avg_web_purchases,
    ROUND(AVG(catalog_purchases), 2) AS avg_catalog_purchases,
    ROUND(AVG(deals_purchased), 2) AS avg_discount_deals_purchased,
    ROUND(SUM(web_purchases) * 100.0 / NULLIF(SUM(total_purchases), 0), 2) AS web_share_pct,
    ROUND(SUM(store_purchases) * 100.0 / NULLIF(SUM(total_purchases), 0), 2) AS store_share_pct,
    ROUND(SUM(catalog_purchases) * 100.0 / NULLIF(SUM(total_purchases), 0), 2) AS catalog_share_pct
FROM customer_segments
GROUP BY kmeans_segment
ORDER BY kmeans_segment;


-- ---------------------------------------------------------------------
-- QUERY 3: PRODUCT CATEGORY AFFINITY ANALYSIS
-- Purpose: Discover product category spend patterns across segments to
--          create personalized upsell and cross-sell campaigns.
-- ---------------------------------------------------------------------
SELECT 
    kmeans_segment,
    ROUND(AVG(spent_wine), 2) AS avg_wine_spend,
    ROUND(AVG(spent_meat), 2) AS avg_meat_spend,
    ROUND(AVG(spent_fish), 2) AS avg_fish_spend,
    ROUND(AVG(spent_gold), 2) AS avg_gold_spend,
    ROUND(AVG(spent_sweets), 2) AS avg_sweets_spend,
    ROUND(AVG(spent_fruits), 2) AS avg_fruits_spend
FROM customer_segments
GROUP BY kmeans_segment
ORDER BY kmeans_segment;


-- ---------------------------------------------------------------------
-- QUERY 4: MEMBERSHIP TIER PENETRATION & VALUE
-- Purpose: Cross-tabulate segments with loyalty tiers (Platinum, Gold, Silver, Basic)
--          to target high-value loyalty program upgrades.
-- ---------------------------------------------------------------------
SELECT 
    kmeans_segment,
    membership_tier,
    COUNT(customer_id) AS customer_count,
    ROUND(AVG(annual_income), 2) AS avg_income,
    ROUND(AVG(total_amount_spent), 2) AS avg_spend,
    ROUND(SUM(total_amount_spent), 2) AS total_spend
FROM customer_segments
GROUP BY kmeans_segment, membership_tier
ORDER BY kmeans_segment, avg_spend DESC;


-- ---------------------------------------------------------------------
-- QUERY 5: ADVANCED WINDOW FUNCTION - TOP 3 HIGHEST SPENDERS PER SEGMENT
-- Purpose: Identify VIP customers in each segment using DENSE_RANK()
--          for targeted executive gift outreach and concierge marketing.
-- ---------------------------------------------------------------------
WITH ranked_customers AS (
    SELECT 
        customer_id,
        kmeans_segment,
        membership_tier,
        annual_income,
        total_amount_spent,
        store_purchases,
        web_purchases,
        DENSE_RANK() OVER (
            PARTITION BY kmeans_segment 
            ORDER BY total_amount_spent DESC
        ) AS rank_in_segment
    FROM customer_segments
)
SELECT 
    customer_id,
    kmeans_segment,
    membership_tier,
    annual_income,
    total_amount_spent,
    (store_purchases + web_purchases) AS direct_purchases,
    rank_in_segment
FROM ranked_customers
WHERE rank_in_segment <= 3
ORDER BY kmeans_segment, rank_in_segment;


-- ---------------------------------------------------------------------
-- QUERY 6: CAMPAIGN CONVERSION & RESPONSIVENESS BY SEGMENT
-- Purpose: Evaluate past campaign acceptance rates (Campaign 1-5) and
--          the latest Campaign Response rate to optimize ad targeting.
-- ---------------------------------------------------------------------
SELECT 
    kmeans_segment,
    COUNT(customer_id) AS total_customers,
    SUM(campaign_response) AS latest_campaign_conversions,
    ROUND(AVG(campaign_response) * 100.0, 2) AS response_rate_pct,
    ROUND(AVG(campaigns_accepted), 2) AS avg_historical_campaigns_accepted,
    ROUND(SUM(revenue_contribution) - SUM(contact_cost), 2) AS estimated_net_campaign_margin
FROM customer_segments
GROUP BY kmeans_segment
ORDER BY response_rate_pct DESC;


-- ---------------------------------------------------------------------
-- QUERY 7: CREATION OF AN ANALYTICAL VIEW (RFM LIFECYCLE SUMMARY)
-- Purpose: Provide BI dashboards with a materialized/view-level RFM profile
--          combining Recency, Frequency, and Monetary value.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW view_customer_rfm_summary AS
SELECT 
    customer_id,
    kmeans_segment,
    membership_tier,
    last_purchase_recency AS recency_days,
    total_purchases AS frequency_transactions,
    total_amount_spent AS monetary_value,
    CASE 
        WHEN last_purchase_recency <= 30 THEN 'Active (<= 30 Days)'
        WHEN last_purchase_recency <= 60 THEN 'At-Risk (31-60 Days)'
        ELSE 'Dormant (> 60 Days)'
    END AS activity_status,
    CASE 
        WHEN total_amount_spent >= 1000 THEN 'Tier 1 Spender (> $1,000)'
        WHEN total_amount_spent >= 500  THEN 'Tier 2 Spender ($500 - $1,000)'
        ELSE 'Tier 3 Spender (< $500)'
    END AS value_segment
FROM customer_segments;

-- Test the view
SELECT 
    kmeans_segment,
    activity_status,
    value_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(monetary_value), 2) AS avg_monetary_val
FROM view_customer_rfm_summary
GROUP BY kmeans_segment, activity_status, value_segment
ORDER BY kmeans_segment, customer_count DESC;
