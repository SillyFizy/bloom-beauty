from django.core.management.base import BaseCommand, CommandError
from django.conf import settings
import os
import sys
import subprocess
from pathlib import Path


class Command(BaseCommand):
    help = 'Extract data from SQLite and populate PostgreSQL database'

    def add_arguments(self, parser):
        parser.add_argument(
            '--overwrite',
            action='store_true',
            help='Overwrite existing PostgreSQL data'
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Extract data but do not populate PostgreSQL'
        )
        parser.add_argument(
            '--sqlite-db',
            type=str,
            default='db.sqlite3',
            help='SQLite database path (default: db.sqlite3)'
        )

    def handle(self, *args, **options):
        self.stdout.write(
            self.style.SUCCESS('Starting data extraction and population...')
        )
        
        # Get the path to the extraction script
        script_path = Path(settings.BASE_DIR) / 'extract_and_populate_data.py'
        
        if not script_path.exists():
            raise CommandError(f'Extraction script not found: {script_path}')
        
        # Build command arguments
        cmd_args = [sys.executable, str(script_path)]
        
        if options['sqlite_db']:
            cmd_args.extend(['--sqlite-db', options['sqlite_db']])
        
        if options['overwrite']:
            cmd_args.append('--overwrite')
            self.stdout.write(
                self.style.WARNING('⚠️  OVERWRITE MODE: Existing data will be cleared!')
            )
        
        if options['dry_run']:
            cmd_args.append('--dry-run')
            self.stdout.write(
                self.style.WARNING('🔍 DRY RUN MODE: Only extracting data, not populating PostgreSQL')
            )
        
        # Set environment variables
        env = os.environ.copy()
        env.update({
            'DB_NAME': getattr(settings, 'DATABASES', {}).get('default', {}).get('NAME', 'bloom_beauty'),
            'DB_USER': getattr(settings, 'DATABASES', {}).get('default', {}).get('USER', 'postgres'),
            'DB_PASSWORD': getattr(settings, 'DATABASES', {}).get('default', {}).get('PASSWORD', '832021'),
            'DB_HOST': getattr(settings, 'DATABASES', {}).get('default', {}).get('HOST', 'localhost'),
            'DB_PORT': str(getattr(settings, 'DATABASES', {}).get('default', {}).get('PORT', 5432)),
        })
        
        try:
            # Run the extraction script
            self.stdout.write('Executing data extraction script...')
            result = subprocess.run(
                cmd_args,
                env=env,
                capture_output=True,
                text=True,
                check=True
            )
            
            # Print script output
            if result.stdout:
                self.stdout.write(result.stdout)
            
            if result.stderr:
                self.stdout.write(
                    self.style.WARNING('Script warnings/errors:')
                )
                self.stdout.write(result.stderr)
            
            self.stdout.write(
                self.style.SUCCESS('✅ Data extraction and population completed successfully!')
            )
            
        except subprocess.CalledProcessError as e:
            self.stdout.write(
                self.style.ERROR(f'❌ Script execution failed with exit code {e.returncode}')
            )
            if e.stdout:
                self.stdout.write('Script output:')
                self.stdout.write(e.stdout)
            if e.stderr:
                self.stdout.write('Script errors:')
                self.stdout.write(e.stderr)
            raise CommandError('Data extraction failed')
        
        except Exception as e:
            raise CommandError(f'Unexpected error: {e}')
        
        # Check for log file
        log_file = Path(settings.BASE_DIR) / 'data_migration.log'
        if log_file.exists():
            self.stdout.write(
                self.style.SUCCESS(f'📝 Detailed log saved to: {log_file}')
            )
        
        # Check for extracted data file (in dry-run mode)
        if options['dry_run']:
            data_file = Path(settings.BASE_DIR) / 'extracted_data.json'
            if data_file.exists():
                self.stdout.write(
                    self.style.SUCCESS(f'💾 Extracted data saved to: {data_file}')
                ) 