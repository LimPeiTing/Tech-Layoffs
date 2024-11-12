SELECT *
FROM layoffs;


-- 1. Remove Duplicates 
-- 2. Standardize the Data 
-- 3. Null Values or blank values 
-- 4. Remove any columns 


-- to have another copy of raw data (if working with large database and want to remove any columns)

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT * 
FROM layoffs;


-- 1. Remove Duplicates 

WITH duplicate_cte AS 
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT* 
FROM duplicate_cte
WHERE row_num >1;

-- to delete the duplicates, create another table to delete the one column 
-- right click layoffs_staging > copy to clipboard > create statement > paste 


CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


SELECT *
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

DELETE 
FROM layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging2;

-- 2. Standarsize the data 

-- to remove space 
SELECT company, TRIM(company) 
FROM layoffs_staging2;

-- to change the original company to TRIM(company) in dataset 
UPDATE layoffs_staging2
SET company = TRIM(company);

-- next, check on industry column 
SELECT DISTINCT(industry) 
FROM layoffs_staging2
ORDER BY 1; 

-- notice that there are blank row and also Crypto with variety naming 
-- standardize the naming of Crypto 

SELECT * 
FROM layoffs_staging2 
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY 1;

-- check each column one by one 

SELECT DISTINCT(country)
FROM layoffs_staging2
ORDER BY 1;


SELECT *
FROM layoffs_staging2;

SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY 1;

-- after checking country column, notice that there is one row with United States. behind

SELECT DISTINCT(country), TRIM(TRAILING'.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(Trailing '.' FROM country)
WHERE country LIKE 'United States%';

SELECT DISTINCT(country)
FROM layoffs_staging2
ORDER BY 1;

-- to convert date format (from TEXT to DATE) 

SELECT `date`,
str_to_date(`date`,'%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = str_to_date(`date`,'%m/%d/%Y');

SELECT `date`
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- 3. Remove NULL and blank values 

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL;

-- total_laid_off, percentage_laid_off， funds_rasied_millions with NULL and blank value are most likely hard to fill up with value, it most probably need to be remove the whole row later at step 4.
-- continue to check other column 

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- try to populate the result with NULL / blank values
-- for example, using company = Airbnb to check 

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- the result showed that Airbnb industry is 'Travel', then we can fill up the blank value 
-- continue to populate the other 3 companys to check 


SELECT *
FROM layoffs_staging2
WHERE company = 'Carvana';

-- the result showed that Carvana industry is 'Transportation', then we can fill up the blank value 

-- to fill up the blank with non-blank value
-- check on location as well cause it might have same company name but in different location 

SELECT * 
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company 
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company 
SET t1.industry = t2.industry 
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- after running this query, noticed that there is 0 row updated, which mean still the same, need to find out why 
-- it might probably due to t1.industry are all blank value, so let us set t1.industry which is blank to NULL 

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';


-- check back Airbnb again and can notice industry column with blank value already fill up with 'Travel' 

-- 4. Remove any columns or rows 
-- deleting total_laid_off and percentage_laid_off is blank 

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL; 

SELECT * 
FROM layoffs_staging2;

-- drop the row_num that created before 

ALTER TABLE layoffs_staging2
DROP COLUMN row_num; 

