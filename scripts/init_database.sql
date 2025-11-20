/*
=========================================================================
Create Database ans Schemas
=========================================================================
Script Purpose:
  This script creates a new database named 'DataWarehouse' after checking if it already exists.
  If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas
  within the database: 'braonze', 'silver' and 'gold'.

WARNING:
  Running the script will drop the entire 'DataWarehouse' database if it exists.
  All data in the database will be permanently deleted. Proceed with caution and
  ensure you have proper backups before running this script.
*/

-- Create Database 'DataWarehouse'

USE master;

-- Check if exist, if exist drop and recreate the DataWarehouse database

IF EXISTS( SELECT 1 FROM sys.database WHERE name = 'DataWarehouse')
BEGIN
	ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataWarehouse;
END;

CREATE DATABASE DataWarehouse;

USE DataWarehouse;

-- create schema for each layer

CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO
