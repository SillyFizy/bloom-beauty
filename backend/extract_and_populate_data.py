#!/usr/bin/env python3
"""
Data Extraction and Population Script
Extracts data from SQLite database and populates PostgreSQL database
"""

import os
import sys
import sqlite3
import psycopg
import json
import logging
from datetime import datetime
from decimal import Decimal
from pathlib import Path

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('data_migration.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class DataExtractor:
    def __init__(self, sqlite_db_path='db.sqlite3'):
        self.sqlite_db_path = sqlite_db_path
        self.postgres_config = self.get_postgres_config()
        
    def get_postgres_config(self):
        """Get PostgreSQL configuration from environment or defaults"""
        return {
            'host': os.environ.get('DB_HOST', 'localhost'),
            'port': int(os.environ.get('DB_PORT', 5432)),
            'dbname': os.environ.get('DB_NAME', 'bloom_beauty'),
            'user': os.environ.get('DB_USER', 'postgres'),
            'password': os.environ.get('DB_PASSWORD', '832021'),
        }
    
    def extract_sqlite_data(self):
        """Extract all data from SQLite database"""
        if not os.path.exists(self.sqlite_db_path):
            logger.error(f"SQLite database not found: {self.sqlite_db_path}")
            return None
            
        logger.info(f"Extracting data from SQLite: {self.sqlite_db_path}")
        
        try:
            conn = sqlite3.connect(self.sqlite_db_path)
            conn.row_factory = sqlite3.Row  # Enable column access by name
            cursor = conn.cursor()
            
            # Get all table names (excluding Django system tables)
            cursor.execute("""
                SELECT name FROM sqlite_master 
                WHERE type='table' 
                AND name NOT LIKE 'django_%' 
                AND name NOT LIKE 'auth_%' 
                AND name NOT LIKE 'sqlite_%'
                ORDER BY name
            """)
            
            tables = [row[0] for row in cursor.fetchall()]
            logger.info(f"Found tables: {', '.join(tables)}")
            
            extracted_data = {}
            
            # Define table extraction order (dependencies first)
            table_order = [
                # Core tables first
                'users_user',
                'navigation_categories',
                'products_category',
                'products_brand',
                'celebrities_celebrity',
                
                # Products and related
                'products_product',
                'products_productattribute',
                'products_productattributevalue',
                'products_productvariant',
                'products_review',
                'products_platformstats',
                'celebrities_celebrityproductpromotion',
                
                # Cart and Orders
                'cart_cart',
                'cart_cartitem',
                'orders_shippingaddress',
                'orders_order',
                'orders_orderitem',
                'orders_orderstatushistory',
                
                # Payments and other
                'payments_payment',
                'users_pointtransaction',
                'request_logs_requestlog',
            ]
            
            # Extract tables in order, then any remaining tables
            all_tables = table_order + [t for t in tables if t not in table_order]
            
            for table_name in all_tables:
                if table_name in tables:
                    try:
                        cursor.execute(f"SELECT * FROM {table_name}")
                        rows = cursor.fetchall()
                        
                        # Convert rows to dictionaries
                        table_data = []
                        for row in rows:
                            row_dict = {}
                            for key in row.keys():
                                value = row[key]
                                # Handle different data types
                                if isinstance(value, bytes):
                                    # Convert bytes to string if possible
                                    try:
                                        value = value.decode('utf-8')
                                    except:
                                        value = str(value)
                                row_dict[key] = value
                            table_data.append(row_dict)
                        
                        extracted_data[table_name] = table_data
                        logger.info(f"Extracted {len(table_data)} records from {table_name}")
                        
                    except Exception as e:
                        logger.error(f"Error extracting from {table_name}: {e}")
                        continue
            
            conn.close()
            logger.info(f"Successfully extracted data from {len(extracted_data)} tables")
            return extracted_data
            
        except Exception as e:
            logger.error(f"Error connecting to SQLite: {e}")
            return None
    
    def create_postgres_database(self):
        """Create PostgreSQL database if it doesn't exist"""
        try:
            # Connect to PostgreSQL server (not specific database)
            conn_params = self.postgres_config.copy()
            db_name = conn_params.pop('dbname')
            
            conn = psycopg.connect(**conn_params, dbname='postgres')
            conn.autocommit = True
            cursor = conn.cursor()
            
            # Check if database exists
            cursor.execute("SELECT 1 FROM pg_database WHERE datname = %s", (db_name,))
            exists = cursor.fetchone()
            
            if not exists:
                logger.info(f"Creating database: {db_name}")
                cursor.execute(f'CREATE DATABASE "{db_name}"')
                logger.info(f"Database {db_name} created successfully")
            else:
                logger.info(f"Database {db_name} already exists")
            
            conn.close()
            return True
            
        except Exception as e:
            logger.error(f"Error creating PostgreSQL database: {e}")
            return False
    
    def populate_postgres_data(self, extracted_data, overwrite=False):
        """Populate PostgreSQL database with extracted data"""
        if not extracted_data:
            logger.error("No data to populate")
            return False
        
        try:
            # Connect to PostgreSQL
            conn = psycopg.connect(**self.postgres_config)
            conn.autocommit = False
            cursor = conn.cursor()
            
            logger.info("Connected to PostgreSQL database")
            
            # If overwrite is True, clear existing data
            if overwrite:
                logger.warning("OVERWRITE MODE: Clearing existing data...")
                self.clear_postgres_data(cursor)
            
            # Populate data table by table
            for table_name, table_data in extracted_data.items():
                if not table_data:
                    logger.info(f"No data to insert for {table_name}")
                    continue
                
                try:
                    logger.info(f"Populating {table_name} with {len(table_data)} records...")
                    
                    # Get column names from first record
                    columns = list(table_data[0].keys())
                    
                    # Create INSERT statement
                    placeholders = ', '.join(['%s'] * len(columns))
                    insert_sql = f"""
                        INSERT INTO {table_name} ({', '.join(columns)}) 
                        VALUES ({placeholders})
                        ON CONFLICT DO NOTHING
                    """
                    
                    # Prepare data for insertion
                    insert_data = []
                    for record in table_data:
                        row_values = []
                        for col in columns:
                            value = record.get(col)
                            # Handle JSON fields
                            if isinstance(value, (dict, list)):
                                value = json.dumps(value)
                            # Handle None values
                            elif value == '':
                                value = None
                            row_values.append(value)
                        insert_data.append(row_values)
                    
                    # Execute batch insert
                    cursor.executemany(insert_sql, insert_data)
                    
                    # Update sequence for tables with auto-incrementing IDs
                    if any(col.lower() == 'id' for col in columns):
                        cursor.execute(f"""
                            SELECT setval(pg_get_serial_sequence('{table_name}', 'id'), 
                                         COALESCE((SELECT MAX(id) FROM {table_name}), 1), 
                                         false)
                        """)
                    
                    logger.info(f"Successfully populated {table_name}")
                    
                except Exception as e:
                    logger.error(f"Error populating {table_name}: {e}")
                    logger.info(f"Skipping {table_name} and continuing...")
                    continue
            
            # Commit all changes
            conn.commit()
            logger.info("All data committed successfully")
            
            # Generate summary report
            self.generate_population_report(cursor)
            
            conn.close()
            return True
            
        except Exception as e:
            logger.error(f"Error populating PostgreSQL: {e}")
            return False
    
    def clear_postgres_data(self, cursor):
        """Clear all data from PostgreSQL tables (for overwrite mode)"""
        try:
            # Get all table names
            cursor.execute("""
                SELECT tablename FROM pg_tables 
                WHERE schemaname = 'public' 
                AND tablename NOT LIKE 'django_%' 
                AND tablename NOT LIKE 'auth_%'
                ORDER BY tablename
            """)
            
            tables = [row[0] for row in cursor.fetchall()]
            
            # Disable foreign key checks temporarily
            cursor.execute("SET session_replication_role = replica;")
            
            # Truncate all tables
            for table in tables:
                try:
                    cursor.execute(f"TRUNCATE TABLE {table} RESTART IDENTITY CASCADE")
                    logger.info(f"Cleared table: {table}")
                except Exception as e:
                    logger.warning(f"Could not clear {table}: {e}")
            
            # Re-enable foreign key checks
            cursor.execute("SET session_replication_role = DEFAULT;")
            
            logger.info("All tables cleared successfully")
            
        except Exception as e:
            logger.error(f"Error clearing PostgreSQL data: {e}")
    
    def generate_population_report(self, cursor):
        """Generate a report of populated data"""
        try:
            logger.info("\n" + "="*50)
            logger.info("DATA POPULATION REPORT")
            logger.info("="*50)
            
            # Get table counts
            cursor.execute("""
                SELECT tablename, n_tup_ins as "rows"
                FROM pg_stat_user_tables 
                WHERE schemaname = 'public'
                ORDER BY tablename
            """)
            
            total_rows = 0
            for row in cursor.fetchall():
                table, rows = row
                logger.info(f"{table}: {rows} rows")
                total_rows += rows or 0
            
            logger.info(f"\nTotal rows populated: {total_rows}")
            logger.info("="*50)
            
        except Exception as e:
            logger.error(f"Error generating report: {e}")
    
    def run_migration(self, overwrite=False):
        """Run the complete migration process"""
        logger.info("Starting data extraction and population process...")
        logger.info(f"SQLite source: {self.sqlite_db_path}")
        logger.info(f"PostgreSQL target: {self.postgres_config['host']}:{self.postgres_config['port']}/{self.postgres_config['dbname']}")
        logger.info(f"Overwrite mode: {overwrite}")
        
        # Step 1: Extract data from SQLite
        extracted_data = self.extract_sqlite_data()
        if not extracted_data:
            logger.error("Failed to extract data from SQLite")
            return False
        
        # Step 2: Create PostgreSQL database if needed
        if not self.create_postgres_database():
            logger.error("Failed to create PostgreSQL database")
            return False
        
        # Step 3: Populate PostgreSQL with extracted data
        if not self.populate_postgres_data(extracted_data, overwrite):
            logger.error("Failed to populate PostgreSQL database")
            return False
        
        logger.info("Data migration completed successfully!")
        return True


def main():
    """Main function to run the data migration"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Extract SQLite data and populate PostgreSQL')
    parser.add_argument('--sqlite-db', default='db.sqlite3', help='SQLite database path')
    parser.add_argument('--overwrite', action='store_true', help='Overwrite existing PostgreSQL data')
    parser.add_argument('--dry-run', action='store_true', help='Extract data but do not populate PostgreSQL')
    
    args = parser.parse_args()
    
    # Load environment variables from .env file if it exists
    env_file = Path('.env')
    if env_file.exists():
        logger.info("Loading environment variables from .env file")
        with open(env_file) as f:
            for line in f:
                if line.strip() and not line.startswith('#') and '=' in line:
                    key, value = line.strip().split('=', 1)
                    os.environ[key] = value
    
    # Create extractor instance
    extractor = DataExtractor(args.sqlite_db)
    
    if args.dry_run:
        logger.info("DRY RUN MODE: Only extracting data, not populating PostgreSQL")
        data = extractor.extract_sqlite_data()
        if data:
            logger.info(f"Successfully extracted data from {len(data)} tables")
            # Save extracted data to JSON file for inspection
            with open('extracted_data.json', 'w') as f:
                json.dump(data, f, indent=2, default=str)
            logger.info("Extracted data saved to extracted_data.json")
        return
    
    # Run full migration
    success = extractor.run_migration(overwrite=args.overwrite)
    
    if success:
        logger.info("Migration completed successfully!")
        sys.exit(0)
    else:
        logger.error("Migration failed!")
        sys.exit(1)


if __name__ == '__main__':
    main() 