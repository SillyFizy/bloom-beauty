-- Initialize the bloom_beauty database
-- This script runs when the PostgreSQL container starts for the first time

-- The database and user are already created by the Docker environment variables
-- This script can be used for additional setup if needed

-- Grant additional privileges if needed
GRANT ALL PRIVILEGES ON DATABASE bloom_beauty TO joulina_user;

-- Create extensions that might be useful for Django
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Set timezone
SET timezone = 'UTC'; 