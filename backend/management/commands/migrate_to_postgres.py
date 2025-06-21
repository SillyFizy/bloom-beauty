"""
Django Management Command: Migrate to PostgreSQL
Command: python manage.py migrate_to_postgres
"""

from django.core.management.base import BaseCommand, CommandError
from django.conf import settings
import os
import sys
import subprocess

class Command(BaseCommand):
    help = 'Migrate data from SQLite to PostgreSQL database'

    def add_arguments(self, parser):
        parser.add_argument(
            '--force',
            action='store_true',
            help='Force migration without confirmation prompt',
        )
        parser.add_argument(
            '--skip-data',
            action='store_true',
            help='Skip data migration, only setup schema',
        )

    def handle(self, *args, **options):
        self.stdout.write(
            self.style.WARNING(
                'Starting PostgreSQL migration for Joulina Beauty Backend'
            )
        )
        
        # Check if .env file exists
        env_file = os.path.join(settings.BASE_DIR, '.env')
        if not os.path.exists(env_file):
            raise CommandError(
                'No .env file found. Please create one with PostgreSQL configuration.'
            )
        
        # Confirm migration
        if not options['force']:
            confirm = input(
                'This will migrate data from SQLite to PostgreSQL. '
                'Existing PostgreSQL data will be overwritten. Continue? (yes/no): '
            )
            if confirm.lower() not in ['yes', 'y']:
                self.stdout.write(self.style.WARNING('Migration cancelled.'))
                return
        
        # Run the migration script
        try:
            migration_script = os.path.join(settings.BASE_DIR, 'migrate_to_postgres.py')
            
            if not os.path.exists(migration_script):
                raise CommandError(f'Migration script not found: {migration_script}')
            
            self.stdout.write('Running migration script...')
            
            # Execute the migration script
            result = subprocess.run([
                sys.executable, migration_script
            ], capture_output=True, text=True, cwd=settings.BASE_DIR)
            
            if result.returncode == 0:
                self.stdout.write(
                    self.style.SUCCESS('Migration completed successfully!')
                )
                self.stdout.write(result.stdout)
            else:
                self.stdout.write(
                    self.style.ERROR('Migration failed!')
                )
                self.stdout.write(result.stderr)
                raise CommandError('Migration process failed')
                
        except Exception as e:
            raise CommandError(f'Error running migration: {str(e)}')
        
        self.stdout.write(
            self.style.SUCCESS(
                'PostgreSQL migration completed. '
                'Please test your application with the new database.'
            )
        ) 