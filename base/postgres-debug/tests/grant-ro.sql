GRANT SELECT ON ALL TABLES IN SCHEMA <APP>_schema TO <APP>_ro_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA <APP>_schema GRANT SELECT ON TABLES TO <APP>_ro_user;