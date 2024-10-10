-- -----------------------------------------------------------------------------
-- DESCRIPTION: This file is a template used to initialize a PostgreSQL
--     database, schema, and admin, RW, and RO roles and users.  It is expected
--     to have the following place holder variables replaced.  Note that all
--     values must be in PostgreSQL friendly format.
--
--     <APP_NAME>....: The application name.
--     ADMIN_PASSWORD: Password for this database's admin account
--     RW_PASSWORD...: Password for the application read-write account
--     RO_PASSWORD...: Password for the application read-only account
-- -----------------------------------------------------------------------------


-- -----------------------------------------------------------------------------
-- Create the application database
-- -----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA tigerranch_schema;
