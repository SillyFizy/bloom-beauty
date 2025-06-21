#!/usr/bin/env python3
"""
Robust SQLite to PostgreSQL Migration Script
Handles data type conversions and reserved keywords properly
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
        logging.FileHandler('migration.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class RobustDataMigrator:
    def __init__(self, sqlite_db_path='db.sqlite3'):
        self.sqlite_db_path = sqlite_db_path
        self.postgres_config = {
            'host': os.environ.get('DB_HOST', 'localhost'),
            'port': int(os.environ.get('DB_PORT', 5432)),
            'dbname': os.environ.get('DB_NAME', 'bloom_beauty'),
            'user': os.environ.get('DB_USER', 'postgres'),
            'password': os.environ.get('DB_PASSWORD', '832021'),
        }
        
        # Define column mappings for reserved keywords
        self.column_mappings = {
            'celebrities_celebrityeveningroutine': {'order': '"order"'},
            'celebrities_celebritymorningroutine': {'order': '"order"'},
        }
        
        # Define data type conversions
        self.type_conversions = {
            'boolean': self.convert_boolean,
            'integer': self.convert_integer,
            'decimal': self.convert_decimal,
            'datetime': self.convert_datetime,
        }
    
    def convert_boolean(self, value):
        """Convert SQLite boolean values to PostgreSQL boolean"""
        if value is None:
            return None
        if isinstance(value, str):
            return value.lower() in ('true', '1', 'yes', 'on')
        return bool(int(value))
    
    def convert_integer(self, value):
        """Convert to integer"""
        if value is None or value == '':
            return None
        return int(value)
    
    def convert_decimal(self, value):
        """Convert to decimal"""
        if value is None or value == '':
            return None
        return Decimal(str(value))
    
    def convert_datetime(self, value):
        """Convert datetime strings"""
        if value is None or value == '':
            return None
        if isinstance(value, str):
            try:
                # Handle various datetime formats
                for fmt in ['%Y-%m-%d %H:%M:%S.%f', '%Y-%m-%d %H:%M:%S', '%Y-%m-%d']:
                    try:
                        return datetime.strptime(value, fmt)
                    except ValueError:
                        continue
                # If no format matches, try parsing as ISO format
                return datetime.fromisoformat(value.replace('T', ' ').replace('Z', ''))
            except:
                return value
        return value
    
    def get_table_schema(self, table_name):
        """Get PostgreSQL table schema to understand column types"""
        try:
            conn = psycopg.connect(**self.postgres_config)
            cursor = conn.cursor()
            
            cursor.execute("""
                SELECT column_name, data_type, is_nullable
                FROM information_schema.columns 
                WHERE table_name = %s AND table_schema = 'public'
                ORDER BY ordinal_position
            """, (table_name,))
            
            schema = {}
            for row in cursor.fetchall():
                column_name, data_type, is_nullable = row
                schema[column_name] = {
                    'type': data_type,
                    'nullable': is_nullable == 'YES'
                }
            
            conn.close()
            return schema
            
        except Exception as e:
            logger.error(f"Error getting schema for {table_name}: {e}")
            return {}
    
    def convert_row_data(self, table_name, row_data, schema):
        """Convert row data based on PostgreSQL schema"""
        converted_data = {}
        
        for column, value in row_data.items():
            # Handle reserved keywords
            if table_name in self.column_mappings and column in self.column_mappings[table_name]:
                column_name = self.column_mappings[table_name][column]
            else:
                column_name = column
            
            # Get column type from schema
            if column in schema:
                pg_type = schema[column]['type']
                
                # Convert based on PostgreSQL type
                if pg_type == 'boolean':
                    converted_data[column_name] = self.convert_boolean(value)
                elif pg_type in ['integer', 'bigint', 'smallint']:
                    converted_data[column_name] = self.convert_integer(value)
                elif pg_type in ['numeric', 'decimal']:
                    converted_data[column_name] = self.convert_decimal(value)
                elif pg_type in ['timestamp', 'timestamptz']:
                    converted_data[column_name] = self.convert_datetime(value)
                elif pg_type == 'jsonb':
                    # Handle JSON fields
                    if isinstance(value, str) and value.strip().startswith(('{', '[')):
                        try:
                            converted_data[column_name] = json.loads(value)
                        except:
                            converted_data[column_name] = value
                    else:
                        converted_data[column_name] = value
                else:
                    # Default: keep as is
                    converted_data[column_name] = value if value != '' else None
            else:
                # Column not in schema, keep as is
                converted_data[column_name] = value if value != '' else None
        
        return converted_data
    
    def migrate_table(self, table_name, sqlite_data):
        """Migrate a single table with proper data conversion"""
        if not sqlite_data:
            logger.info(f"No data to migrate for {table_name}")
            return True
        
        try:
            # Get PostgreSQL schema
            schema = self.get_table_schema(table_name)
            if not schema:
                logger.warning(f"Could not get schema for {table_name}, skipping...")
                return False
            
            # Connect to PostgreSQL
            conn = psycopg.connect(**self.postgres_config)
            cursor = conn.cursor()
            
            logger.info(f"Migrating {table_name} with {len(sqlite_data)} records...")
            
            # Process each row
            success_count = 0
            for row in sqlite_data:
                try:
                    # Convert row data
                    converted_row = self.convert_row_data(table_name, row, schema)
                    
                    # Build INSERT statement
                    columns = list(converted_row.keys())
                    placeholders = ', '.join(['%s'] * len(columns))
                    
                    # Handle reserved keywords in column names
                    column_names = ', '.join(columns)
                    
                    insert_sql = f"""
                        INSERT INTO {table_name} ({column_names}) 
                        VALUES ({placeholders})
                        ON CONFLICT DO NOTHING
                    """
                    
                    # Execute insert
                    cursor.execute(insert_sql, list(converted_row.values()))
                    success_count += 1
                    
                except Exception as e:
                    logger.warning(f"Error inserting row in {table_name}: {e}")
                    continue
            
            # Update sequence if table has an id column
            if 'id' in schema:
                try:
                    cursor.execute(f"""
                        SELECT setval(pg_get_serial_sequence('{table_name}', 'id'), 
                                     COALESCE((SELECT MAX(id) FROM {table_name}), 1), 
                                     false)
                    """)
                except Exception as e:
                    logger.warning(f"Could not update sequence for {table_name}: {e}")
            
            # Commit changes
            conn.commit()
            conn.close()
            
            logger.info(f"Successfully migrated {success_count}/{len(sqlite_data)} records for {table_name}")
            return True
            
        except Exception as e:
            logger.error(f"Error migrating {table_name}: {e}")
            return False
    
    def extract_sqlite_data(self):
        """Extract data from SQLite database"""
        if not os.path.exists(self.sqlite_db_path):
            logger.error(f"SQLite database not found: {self.sqlite_db_path}")
            return None
        
        try:
            conn = sqlite3.connect(self.sqlite_db_path)
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            
            # Get all non-system tables
            cursor.execute("""
                SELECT name FROM sqlite_master 
                WHERE type='table' 
                AND name NOT LIKE 'django_%' 
                AND name NOT LIKE 'auth_%' 
                AND name NOT LIKE 'sqlite_%'
                ORDER BY name
            """)
            
            tables = [row[0] for row in cursor.fetchall()]
            logger.info(f"Found {len(tables)} tables to migrate")
            
            extracted_data = {}
            
            for table_name in tables:
                try:
                    cursor.execute(f"SELECT * FROM {table_name}")
                    rows = cursor.fetchall()
                    
                    table_data = []
                    for row in rows:
                        row_dict = {}
                        for key in row.keys():
                            row_dict[key] = row[key]
                        table_data.append(row_dict)
                    
                    extracted_data[table_name] = table_data
                    logger.info(f"Extracted {len(table_data)} records from {table_name}")
                    
                except Exception as e:
                    logger.error(f"Error extracting from {table_name}: {e}")
                    continue
            
            conn.close()
            return extracted_data
            
        except Exception as e:
            logger.error(f"Error connecting to SQLite: {e}")
            return None
    
    def run_migration(self):
        """Run the complete migration"""
        logger.info("Starting robust SQLite to PostgreSQL migration...")
        
        # Extract data
        sqlite_data = self.extract_sqlite_data()
        if not sqlite_data:
            logger.error("No data extracted from SQLite")
            return False
        
        # Migration order (dependencies first)
        migration_order = [
            'users_user',
            'products_category',
            'products_brand',
            'celebrities_celebrity',
            'products_product',
            'products_productimage',
            'products_review',
            'celebrities_celebrityproductpromotion',
            'celebrities_celebrityeveningroutine',
            'celebrities_celebritymorningroutine',
            'orders_shippingaddress',
            'orders_order',
            'orders_orderitem',
            'cart_cart',
            'cart_cartitem',
            'payments_payment',
            'users_pointtransaction',
            'products_productrating',
            'request_logs_requestlog',
        ]
        
        # Migrate tables in order
        successful_migrations = 0
        for table_name in migration_order:
            if table_name in sqlite_data:
                if self.migrate_table(table_name, sqlite_data[table_name]):
                    successful_migrations += 1
        
        # Migrate any remaining tables
        for table_name, data in sqlite_data.items():
            if table_name not in migration_order:
                if self.migrate_table(table_name, data):
                    successful_migrations += 1
        
        logger.info(f"Migration completed! Successfully migrated {successful_migrations} tables")
        return successful_migrations > 0


def main():
    """Main function"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Robust SQLite to PostgreSQL migration')
    parser.add_argument('--sqlite-db', default='db.sqlite3', help='SQLite database path')
    
    args = parser.parse_args()
    
    # Create migrator and run
    migrator = RobustDataMigrator(args.sqlite_db)
    success = migrator.run_migration()
    
    if success:
        logger.info("Migration completed successfully!")
        sys.exit(0)
    else:
        logger.error("Migration failed!")
        sys.exit(1)


if __name__ == '__main__':
    main() 