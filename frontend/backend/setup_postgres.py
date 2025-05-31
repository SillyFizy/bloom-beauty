#!/usr/bin/env python3
"""
PostgreSQL Database Setup Script for Joulina Backend

This script helps create the PostgreSQL database and user for the Django application.
Run this after installing PostgreSQL locally.
"""

import psycopg
import sys
import os
from psycopg import sql

# Database configuration
DB_NAME = 'bloom_beauty'
DB_USER = 'joulina_user'
DB_PASSWORD = 'joulina_password'
DB_HOST = 'localhost'
DB_PORT = '5432'

def create_database_and_user():
    """Create PostgreSQL database and user for Django application."""
    
    # Get PostgreSQL superuser password
    postgres_password = input("Enter PostgreSQL 'postgres' user password: ")
    
    try:
        # Connect to PostgreSQL as superuser
        print("Connecting to PostgreSQL...")
        conn = psycopg.connect(
            host=DB_HOST,
            port=DB_PORT,
            user='postgres',
            password=postgres_password,
            autocommit=True
        )
        
        cursor = conn.cursor()
        
        # Create user if not exists
        print(f"Creating user '{DB_USER}'...")
        cursor.execute(
            sql.SQL("CREATE USER {} WITH PASSWORD %s").format(
                sql.Identifier(DB_USER)
            ),
            [DB_PASSWORD]
        )
        print(f"User '{DB_USER}' created successfully!")
        
        # Create database if not exists
        print(f"Creating database '{DB_NAME}'...")
        cursor.execute(
            sql.SQL("CREATE DATABASE {} OWNER {}").format(
                sql.Identifier(DB_NAME),
                sql.Identifier(DB_USER)
            )
        )
        print(f"Database '{DB_NAME}' created successfully!")
        
        # Grant privileges
        print("Granting privileges...")
        cursor.execute(
            sql.SQL("GRANT ALL PRIVILEGES ON DATABASE {} TO {}").format(
                sql.Identifier(DB_NAME),
                sql.Identifier(DB_USER)
            )
        )
        print("Privileges granted successfully!")
        
        cursor.close()
        conn.close()
        
        print("\n✅ PostgreSQL setup completed successfully!")
        print(f"Database: {DB_NAME}")
        print(f"User: {DB_USER}")
        print(f"Password: {DB_PASSWORD}")
        print(f"Host: {DB_HOST}")
        print(f"Port: {DB_PORT}")
        
        return True
        
    except psycopg.errors.DuplicateDatabase:
        print(f"Database '{DB_NAME}' already exists!")
        return True
    except psycopg.errors.DuplicateObject:
        print(f"User '{DB_USER}' already exists!")
        return True
    except Exception as e:
        print(f"Error: {e}")
        return False

def test_connection():
    """Test connection to the created database."""
    try:
        print("\nTesting connection to new database...")
        conn = psycopg.connect(
            host=DB_HOST,
            port=DB_PORT,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        
        cursor = conn.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()
        print(f"✅ Connection successful! PostgreSQL version: {version[0]}")
        
        cursor.close()
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return False

if __name__ == "__main__":
    print("🐘 PostgreSQL Database Setup for Joulina Backend")
    print("=" * 50)
    
    if create_database_and_user():
        test_connection()
        print("\n🎉 Setup complete! You can now run Django migrations.")
        print("\nNext steps:")
        print("1. Run: python manage.py makemigrations")
        print("2. Run: python manage.py migrate")
        print("3. Run: python manage.py createsuperuser")
    else:
        print("\n❌ Setup failed. Please check your PostgreSQL installation and try again.")
        sys.exit(1) 