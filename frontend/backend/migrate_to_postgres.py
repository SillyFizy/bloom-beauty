#!/usr/bin/env python3
"""
Migration script to transfer data from SQLite to PostgreSQL

This script helps migrate existing data from SQLite to PostgreSQL.
Run this after setting up PostgreSQL and running initial migrations.
"""

import os
import sys
import django
from django.core.management import execute_from_command_line
from django.db import connections
from django.apps import apps

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'joulina_backend.settings')
django.setup()

def backup_sqlite_data():
    """Create a backup of SQLite data before migration."""
    print("Creating SQLite data backup...")
    try:
        execute_from_command_line(['manage.py', 'dumpdata', '--output=sqlite_backup.json'])
        print("✅ SQLite data backed up to sqlite_backup.json")
        return True
    except Exception as e:
        print(f"❌ Backup failed: {e}")
        return False

def setup_postgres_schema():
    """Run migrations on PostgreSQL to create schema."""
    print("Setting up PostgreSQL schema...")
    try:
        execute_from_command_line(['manage.py', 'migrate'])
        print("✅ PostgreSQL schema created successfully")
        return True
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        return False

def load_data_to_postgres():
    """Load data from SQLite backup to PostgreSQL."""
    print("Loading data to PostgreSQL...")
    try:
        if os.path.exists('sqlite_backup.json'):
            execute_from_command_line(['manage.py', 'loaddata', 'sqlite_backup.json'])
            print("✅ Data loaded to PostgreSQL successfully")
            return True
        else:
            print("⚠️ No backup file found. Starting with empty database.")
            return True
    except Exception as e:
        print(f"❌ Data loading failed: {e}")
        print("You may need to manually recreate your data.")
        return False

def create_superuser():
    """Prompt to create a new superuser."""
    response = input("\nWould you like to create a new superuser? (y/n): ")
    if response.lower() == 'y':
        try:
            execute_from_command_line(['manage.py', 'createsuperuser'])
            print("✅ Superuser created successfully")
        except Exception as e:
            print(f"❌ Superuser creation failed: {e}")

def main():
    print("🔄 SQLite to PostgreSQL Migration Script")
    print("=" * 45)
    
    # Check if SQLite database exists
    sqlite_path = 'db.sqlite3'
    if not os.path.exists(sqlite_path):
        print("⚠️ No SQLite database found. Starting fresh with PostgreSQL.")
        if setup_postgres_schema():
            create_superuser()
        return
    
    print(f"📁 Found SQLite database: {sqlite_path}")
    response = input("Do you want to migrate data from SQLite to PostgreSQL? (y/n): ")
    
    if response.lower() != 'y':
        print("Migration cancelled. You can run this script later.")
        return
    
    # Migration steps
    steps = [
        ("Backing up SQLite data", backup_sqlite_data),
        ("Setting up PostgreSQL schema", setup_postgres_schema),
        ("Loading data to PostgreSQL", load_data_to_postgres),
    ]
    
    for step_name, step_func in steps:
        print(f"\n🔄 {step_name}...")
        if not step_func():
            print(f"❌ Migration failed at step: {step_name}")
            sys.exit(1)
    
    create_superuser()
    
    print("\n🎉 Migration completed successfully!")
    print("\nNext steps:")
    print("1. Test your application with PostgreSQL")
    print("2. If everything works, you can remove the SQLite database")
    print("3. Consider removing sqlite_backup.json after verification")

if __name__ == "__main__":
    main() 