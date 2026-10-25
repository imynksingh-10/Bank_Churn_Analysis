-- DATABSE SETUP & TESTING

-- Start the database
use bank_churn_analysis;

-- Create table in th datbase
CREATE TABLE account_info_2(
    CustomerId	INT,
    Balance	DECIMAL(12,2),
    NumOfProducts	INT,
    HasCrCard	VARCHAR(5),
    Tenure	INT,
    IsActiveMember	VARCHAR(5),
    Exited INT
);

-- To load a CSV: enable it first with SET GLOBAL local_infile = 1; and connect via terminal using: mysql --local-infile=1 -u root -p
-- Then run LOAD DATA LOCAL INFILE (skips header, converts blank CustomerId to NULL); result checked: 10,002 rows loaded
SET GLOBAL local_infile = 1;
-- checking if local_infile is on or off!
SHOW GLOBAL VARIABLES LIKE 'local_infile';

-- import the data in table
LOAD DATA LOCAL INFILE '/Users/PC_USER/Desktop/Practice dataset/Bank Churn Data/Account_Info_2.csv'
INTO TABLE account_info_2
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@id, Balance, NumOfProducts, HasCrCard, Tenure, IsActiveMember, Exited)
SET CustomerId = NULLIF(@id, '');


-- Create table in th datbase
CREATE TABLE customer_info_2(
    CustomerId	INT,
    Surname	VARCHAR(50),
    CreditScore	INT,
    Geography	VARCHAR(50),
    Gender	VARCHAR(50),
    Age	INT,
    Tenure	INT,
    EstimatedSalary DECIMAL(12,2)
);

-- import the data in table
LOAD DATA LOCAL INFILE '/Users/PC_USER/Desktop/Practice dataset/Bank Churn Data/Customer_Info_2.csv'
INTO TABLE customer_info_2
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@id, Surname, CreditScore, Geography, Gender, Age, Tenure, EstimatedSalary)
SET CustomerId = NULLIF(@id, '');

-- check if the tables created or not!
SHOW TABLES;

-- details about the table
DESCRIBE account_info_2;
DESCRIBE customer_info_2;

-- checking if data is imported correctly or not!
SELECT *
FROM account_info_2
LIMIT 10;

SELECT *
FROM customer_info_2
LIMIT 10;

-- counting the no of rows in the created tables are correct
SELECT COUNT(*)
FROM Account_info_2;

SELECT count(*)
from customer_info_2;


-- rows with blank CustomerIds should show as NULL
SELECT COUNT(*) FROM account_info_2 WHERE CustomerId IS NULL;
SELECT COUNT(*) FROM customer_info_2 WHERE CustomerId IS NULL;

-- Make sure the values loaded correctly
SELECT * FROM account_info_2 LIMIT 5;
SELECT * FROM customer_info_2 LIMIT 5;

-- testing with conditions
SELECT Tenure
FROM account_info_2
WHERE CustomerId = '15701354';


SELECT Tenure
FROM customer_info_2
WHERE CustomerId = '15701354';


-- CLEANING

USE bank_churn_analysis;

-- for customer_info_2
-- Checking for duplicate values
SELECT *
FROM customer_info_2
WHERE CustomerId IN
(
    SELECT CustomerId
    FROM customer_info_2
    GROUP BY CustomerId
    HAVING COUNT(CustomerId) >= 2
);

-- Adding a new column as a preimary key
ALTER TABLE customer_info_2
ADD COLUMN RowId INT AUTO_INCREMENT PRIMARY KEY;


-- deletion of duplicate entry
DELETE X.*
FROM customer_info_2 AS X
-- using inner join to find only common row of data
JOIN(
    SELECT CustomerId, MAX(RowId) AS max_id -- using MAX() so the higher row number is getting out
    FROM customer_info_2
    GROUP BY CustomerId
    HAVING COUNT(*) >= 2
) AS Y 
ON X.CustomerId = Y.CustomerId
AND X.RowId = Y.max_id; -- using two points to join on, so that it can be more specific otherwise the join will be create with two entries

-- droping the column after use
ALTER TABLE customer_info_2
DROP COLUMN RowId;


-- for account_info_2
-- Checking for duplicate values
SELECT *
FROM account_info_2
WHERE CustomerId IN
(
    SELECT CustomerId
    FROM account_info_2
    GROUP BY CustomerId
    HAVING COUNT(CustomerId) >= 2
);

-- Adding a new row as a preimary key
ALTER TABLE account_info_2
ADD COLUMN RowId INT AUTO_INCREMENT PRIMARY KEY;


-- deletion of duplicate entry
DELETE X.*
FROM account_info_2 AS X
-- using inner join to find only common row of data
JOIN(
    SELECT CustomerId, MAX(RowId) AS max_id -- using MAX() so the higher row number is getting out
    FROM account_info_2
    GROUP BY CustomerId
    HAVING COUNT(*) >= 2
) AS Y 
ON X.CustomerId = Y.CustomerId
AND X.RowId = Y.max_id; -- using two points to join on, so that it can be more specific otherwise the join will be create with two entries

-- droping the column after use
ALTER TABLE account_info_2
DROP COLUMN RowId;


-- TRANSFORMING 
-- creating a new table. with joining both the tables 
CREATE TABLE bank_churn_transfomation AS
SELECT c.CustomerId, c.Surname, c.Gender, c.Age, c.Geography, c.CreditScore, c.Tenure, a.HasCrCard, a.IsActiveMember, a.NumOfProducts, c.EstimatedSalary, a.Balance, a.Exited
FROM customer_info_2 as c
LEFT JOIN account_info_2 as a
ON c.CustomerId = a.CustomerId
ORDER BY c.CustomerId ASC;


-- checking if table is created correctly or not!!!
SELECT * 
FROM bank_churn_transfomation;


-- replacing in correctly spelled entries with corrected one
select Geography
from bank_churn_transfomation
group by Geography;


-- Updating with correct data
update bank_churn_transfomation
SET Geography = CASE
    WHEN Geography = 'French' THEN 'France'
    WHEN Geography = 'FRA' THEN 'France'
    ELSE Geography
END;
-- OR
update bank_churn_transfomation
set Geography = 'France'
where Geography in ('FRA', 'French');

-- checking empty or null values
SELECT CustomerId, Surname
from bank_churn_transfomation
WHERE Surname IS NULL OR TRIM(Surname) = '';

SELECT CustomerId, Age
from bank_churn_transfomation
WHERE Age IS NULL OR TRIM(Age) = '' OR Age = 0;


-- filling up the null/empty data and peole with 0 Age
update bank_churn_transfomation
set Surname = 'Kennedy' and Age = 39
where CustomerId = '15580203';

update bank_churn_transfomation
set Age = 39
where CustomerId = '15580203';

update bank_churn_transfomation
set Surname = 'McWilliams'
where CustomerId = '15728693';

update bank_churn_transfomation
set Age = 43
where CustomerId = '15728693';

update bank_churn_transfomation
set Surname = 'Lombardo'
where CustomerId = '15756954';

update bank_churn_transfomation
set Age = 32
where CustomerId = '15756954';


/* run in terminal : /usr/local/mysql-shell/bin/mysqlsh root@localhost:3306 -- util export-table bank_churn_analysis.bank_churn_transfomation /Users/PC_USER/Desktop/bank_churn_final.csv --dialect=csv-unix

The export worked: 10,000 rows were written to bank_churn_final.csv on your Desktop. You can ignore the util.importTable(...) text at the end. It’s just a hint for loading the file back into MySQL, which you don’t need.
Add the header row. exportTable doesn’t write column names, so the file starts directly with data. First, get your exact column order by running this in a SQL block:
  
*/


SELECT GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION) AS header
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'bank_churn_analysis' AND TABLE_NAME = 'bank_churn_transfomation';

/* in terminal
cd ~/Desktop
(echo "PASTE_HEADER_LINE_HERE"; cat bank_churn_final.csv) > bank_churn_final_with_header.csv

head -3 bank_churn_final_with_header.csv
wc -l bank_churn_final_with_header.csv

check the desktop

wooooooooowww its done :)
*/


