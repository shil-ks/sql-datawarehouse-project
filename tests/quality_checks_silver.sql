-- DATA TRANSFORMATION of each table

-- to check primary key- agg and if value is >1 then there is duplicates in data
SELECT
cst_id,
COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) >1 OR cst_id IS NULL;

-- Data Standardization & consistency
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info

-- Check for unwanted spaces
SELECT cst_lastname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)

SELECT * FROM bronze.crm_cust_info


PRINT '>> Truncatiing Table: silver.crm_cust_info'
TRUNCATE TABLE silver.crm_cust_info;
PRINT '>> Inserting Data Into Table: silver.crm_cust_info'
---Inserting Transformed data into Silver layer for silver.crm_cust_info
INSERT INTO silver.crm_cust_info(
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_gndr,
	cst_marital_status,
	cst_create_date)
SELECT 
cst_id,
cst_key,
TRIM(cst_firstname) AS cst_firstname,
TRIM(cst_lastname) AS cst_lastname,
-- Data normalization for gender and maritial status
CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	 ELSE 'n/a'
END cst_gndr,
CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
	 WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
	 ELSE 'n/a' -- NULL handling
END
cst_marital_status,
cst_create_date
-- Removing duplicates in the data
FROM(
	SELECT
	*,
	ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
)t
WHERE flag_last = 1 


-- Recheck quality of data for silver.crm_cust_info in silver layer

SELECT
cst_id,
COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) >1 OR cst_id IS NULL;


SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)


SELECT *
FROM silver.crm_cust_info

-- DATA TRANSFORMATION for bronze.crm_prd_info

SELECT * 
FROM bronze.crm_prd_info
SELECT DISTINCT id FROM bronze.erp_px_cat_g1v2

-- Checking for duplicates
SELECT
prd_id,
COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) >1

-- checking for unwanted spaces
SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

-- check for negative or null values in prd_cost
SELECT *
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Check for Invalid Date Orders
-- END date must not be earlier than start date
SELECT *
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt 

-- Finding logic to deal with end_date < start_date
SELECT 
prd_id,
prd_key,
prd_nm,
prd_start_dt,
prd_end_dt,
LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS prd_end_dt_test
FROM bronze.crm_prd_info
WHERE prd_key IN('AC-HE-HL-U509-R', 'AC-HE-HL-U509')


PRINT '>> Truncatiing Table: silver.crm_prd_info'
TRUNCATE TABLE silver.crm_prd_info;
PRINT '>> Inserting Data Into Table: silver.crm_prd_info'
--- Inserting Transformed data into Silver layer for silver.crm_prd_info
INSERT INTO silver.crm_prd_info(
	prd_id,
	cat_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
)
SELECT
prd_id,
REPLACE(SUBSTRING(prd_key, 1,5), '-', '_') AS cat_id,-- Derived column
SUBSTRING(prd_key, 7, lEN(prd_key)) AS prd_key, -- Derived column
prd_nm,
ISNULL(prd_cost, 0) AS prd_cost, -- handling null/missing info
-- Data Normalization
CASE WHEN UPPER(TRIM(prd_line)) ='M' THEN 'Mountain'
	 WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
	 WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
	 WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
	 ELSE 'n/a'
END AS prd_line,
-- Data type casting start date as date instead of date time
CAST(prd_start_dt AS DATE) AS prd_start_dt,
-- in our records we found the end date < start date, so we are implementing the below logic
-- we are deriving the end date from start date of next rec - 1
CAST(
	LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 
	AS DATE
) AS prd_end_dt 
FROM bronze.crm_prd_info

-- Rechecking data quality in silver.crm_prd_info


SELECT * FROM silver.crm_prd_info

-- Checking for duplicates
SELECT
prd_id,
COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) >1

-- checking for unwanted spaces
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

-- check for negative or null values in prd_cost
SELECT *
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Check for Invalid Date Orders
-- END date must not be earlier than start date
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt 

-- DATA TRANSFORMATION for bronze.crm_sales_details
SELECT *
FROM bronze.crm_sales_details


SELECT
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details


-- To check sls_ord_num
SELECT
*
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num)


-- we are connecting prd_key to  crm_prd_info table and 
-- cst_id to crm_cust_info table 
-- so we will check if there are any that prd_key that are missing out
SELECT
*
FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info)
AND sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info)



-- check sales order date and transform
SELECT 
NULLIF(sls_order_dt,0) sls_order_dt
FROM bronze.crm_sales_details 
WHERE sls_order_dt <= 0 
OR LEN(sls_order_dt) != 8 
OR sls_order_dt > 20500101
OR sls_order_dt < 19000101

SELECT 
CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
	 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) 
END AS sls_order_dt
FROM bronze.crm_sales_details


-- check sales ship date and transform
SELECT 
NULLIF(sls_ship_dt,0) sls_ship_dt
FROM bronze.crm_sales_details 
WHERE sls_ship_dt <= 0 
OR LEN(sls_ship_dt) != 8 
OR sls_ship_dt > 20500101
OR sls_ship_dt < 19000101


SELECT 
CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
	 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) 
END AS sls_ship_dt
FROM bronze.crm_sales_details


-- Check for due date and transform
SELECT  
NULLIF(sls_due_dt,0) sls_due_dt
FROM bronze.crm_sales_details 
WHERE sls_due_dt <= 0 
OR LEN(sls_due_dt) != 8 
OR sls_due_dt > 20500101
OR sls_due_dt < 19000101

SELECT 
CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
	 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) 
END AS sls_due_dt
FROM bronze.crm_sales_details

-- Check for invalid date orders 
-- order date > ship date and order date < due date


SELECT
*
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt


-- Sales  = Qty * price and positive numbers

SELECT DISTINCT
sls_sales AS old_sls_sales,
sls_quantity,
sls_price AS old_sls_price,

CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity* ABS(sls_price)
	 THEN sls_quantity * ABS(sls_price)
	 ELSE sls_sales
END AS sls_sales, 

CASE WHEN sls_price IS NULL OR sls_price <= 0
	 THEN sls_sales/NULLIF(sls_quantity, 0)
	 ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity*sls_price
OR sls_sales IS NULL 
OR sls_quantity IS NULL
OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales,
sls_quantity,
sls_price




--- Final query integrating all transformations
-- Insert the transformed data into silver.crm_sales_details
PRINT '>> Truncatiing Table: silver.crm_sales_details'
TRUNCATE TABLE silver.crm_sales_details;
PRINT '>> Inserting Data Into Table: silver.crm_sales_details'
INSERT INTO silver.crm_sales_details(
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
)
SELECT
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
	 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) 
END AS sls_order_dt,
CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
	 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) 
END AS sls_ship_dt,
CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
	 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) 
END AS sls_due_dt,
-- Recalculate sales if original value is missing or incorrect
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity* ABS(sls_price)
	 THEN sls_quantity * ABS(sls_price)
	 ELSE sls_sales
END AS sls_sales, 
sls_quantity,
-- Derive price if original value is invalid
CASE WHEN sls_price IS NULL OR sls_price <= 0
	 THEN sls_sales/NULLIF(sls_quantity, 0)
	 ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details


SELECT
*
FROM silver.crm_sales_details



--- Transforming bronze.erp_cust_az12

SELECT
cid,
bdate,
gen 
FROM bronze.erp_cust_az12


SELECT * FROM silver.crm_cust_info


SELECT
-- Removing the 'NAS' from cid
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
	 ELSE cid
END cid,
bdate,
gen 
FROM bronze.erp_cust_az12
WHERE CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
	 ELSE cid
END NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info)
-- REMOVE NAS from cid 

SELECT DISTINCT
bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()

-- Data STandardization & Consistency
SELECT DISTINCT 
gen,
CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
	 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
	 ELSE 'n/a'
END gen
FROM bronze.erp_cust_az12


PRINT '>> Truncatiing Table: silver.erp_cust_az12'
TRUNCATE TABLE silver.erp_cust_az12;
PRINT '>> Inserting Data Into Table: silver.erp_cust_az12'
INSERT INTO silver.erp_cust_az12(
cid,
bdate,
gen 
)
SELECT
-- Removing the 'NAS' from cid
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
	 ELSE cid
END cid,
-- if bdate is greater than today it doesnt make senese so replace with NULL 
CASE WHEN bdate > GETDATE() THEN NULL
	 ELSE bdate
END bdate,
-- data standardization 
CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
	 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
	 ELSE 'n/a'
END gen
FROM bronze.erp_cust_az12


SELECT * FROM silver.erp_cust_az12


-- TRANSFORM bronze.erp_loc_a101
SELECT 
cntry as old_cntry,
CASE WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
	 WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	 WHEN TRIM(cntry) = '' OR cntry is NULL THEN 'n/a'
	 ELSE TRIM(cntry)
END cntry
FROM bronze.erp_loc_a101

-- cid is linked to cst_key from crm_cust_info
select * FROM silver.crm_cust_info


-- remove hypen from cid from erp table
SELECT
REPLACE(cid, '-', '') cid,
cntry
FROM bronze.erp_loc_a101
-- checkinf if theres any data missing 
WHERE REPLACE(cid, '-', '') NOT IN
(SELECT cst_key FROM silver.crm_cust_info)


PRINT '>> Truncatiing Table: silver.erp_loc_a101'
TRUNCATE TABLE silver.erp_loc_a101;
PRINT '>> Inserting Data Into Table: silver.erp_loc_a101'
-- Insert the transformed data into silver.erp_loc_a101
INSERT INTO silver.erp_loc_a101 (cid, cntry)
SELECT
REPLACE(cid, '-', '') cid, --handled invalid values
CASE WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
	 WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	 -- Handlded missing values and empty spaces
	 WHEN TRIM(cntry) = '' OR cntry is NULL THEN 'n/a'
	 ELSE TRIM(cntry)
END cntry
FROM bronze.erp_loc_a101


-- Double checking 
SELECT * FROM silver.erp_loc_a101

SELECT DISTINCT
cntry
FROM silver.erp_loc_a101

PRINT '>> Truncatiing Table: silver.erp_px_cat_g1v2'
TRUNCATE TABLE silver.erp_px_cat_g1v2;
PRINT '>> Inserting Data Into Table: silver.erp_px_cat_g1v2'
INSERT INTO silver.erp_px_cat_g1v2
(id,cat,subcat,maintenance)
SELECT 
id,
cat,
subcat,
maintenance
FROM bronze.erp_px_cat_g1v2
-- Check for unwanted spaces
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)


-- Data Standardization & Consistency
SELECT DISTINCT
maintenance
FROM bronze.erp_px_cat_g1v2


SELECT *
FROM silver.erp_px_cat_g1v2
