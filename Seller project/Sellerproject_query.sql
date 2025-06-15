USE SellerDB;
GO

select column_name, data_type from information_schema.columns
where  table_name = 'seller_enrollment';

--Step 1: Data Cleanup & Prep
-- Sample cleanup: trimming spaces and converting to lowercase

UPDATE seller_enrollment
SET platform = LOWER(LTRIM(RTRIM(platform))),
    kind = LOWER(LTRIM(RTRIM(kind))),
    category = LOWER(LTRIM(RTRIM(category))),
    manual_file_ingested = LOWER(LTRIM(RTRIM(manual_file_ingested)));

--Step 2: Funnel Drop-off Metrics
SELECT
  platform,
  category,
  kind,
  manual_file_ingested,
  SUM(impressions) AS total_impressions,
  SUM(clicks) AS total_clicks,
  SUM(CAST(enrolled AS INT)) AS total_enrollments,
  ROUND(1.0 * SUM(clicks) / NULLIF(SUM(impressions), 0), 3) AS click_through_rate,
  ROUND(1.0 * SUM(CAST(enrolled AS INT)) / NULLIF(SUM(clicks), 0), 3) AS enrollment_rate,
  ROUND(1 - (1.0 * SUM(clicks) / NULLIF(SUM(impressions), 0)), 3) AS dropoff_after_impression,
  ROUND(1 - (1.0 * SUM(CAST(enrolled AS INT)) / NULLIF(SUM(clicks), 0)), 3) AS dropoff_after_click
FROM seller_enrollment
GROUP BY platform, category, kind, manual_file_ingested
ORDER BY dropoff_after_impression DESC;

-- Step 3: Tag Validation Check
SELECT
  optin_cta_tagged,
  impression_tag_valid,
  COUNT(*) AS total_sellers,
  SUM(CAST(enrolled AS INT)) AS total_enrollment,
  ROUND(1.0 * SUM(CAST(enrolled AS INT)) / COUNT(*), 3) AS enrollment_rate
FROM seller_enrollment
GROUP BY optin_cta_tagged, impression_tag_valid
ORDER BY enrollment_rate ASC;

---Step 4 Seller Behavior Insights 
---Tenure vs Enrollment
SELECT
  seller_tenure_months,
  ROUND(AVG(CAST(enrolled AS FLOAT)), 3) AS enrollment_rate
FROM seller_enrollment
GROUP BY seller_tenure_months
ORDER BY seller_tenure_months;

---Risk Rating vs Enrollment
SELECT
  risk_rating,
  ROUND(AVG(CAST(enrolled AS FLOAT)), 3) AS enrollment_rate
FROM seller_enrollment
GROUP BY risk_rating;

---Most popular products (product_opted) among enrolled sellers
SELECT 
    product_opted,
    COUNT(*) AS times_opted,
    SUM(enrolled) AS enrolled_sellers
FROM 
    seller_enrollment
GROUP BY 
    product_opted
ORDER BY 
    enrolled_sellers DESC;








