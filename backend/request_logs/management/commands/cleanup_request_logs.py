from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from request_logs.models import RequestLog

class Command(BaseCommand):
    help = 'Clean up old request logs to prevent database bloat'

    def add_arguments(self, parser):
        parser.add_argument(
            '--days',
            type=int,
            default=30,
            help='Delete logs older than this many days (default: 30)'
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be deleted without actually deleting'
        )
        parser.add_argument(
            '--keep-errors',
            action='store_true',
            help='Keep error logs (4xx and 5xx status codes) even if they are old'
        )

    def handle(self, *args, **options):
        days = options['days']
        dry_run = options['dry_run']
        keep_errors = options['keep_errors']
        
        cutoff_date = timezone.now() - timedelta(days=days)
        
        # Build the queryset
        logs_to_delete = RequestLog.objects.filter(timestamp__lt=cutoff_date)
        
        if keep_errors:
            # Exclude error logs
            logs_to_delete = logs_to_delete.filter(is_error=False)
        
        count = logs_to_delete.count()
        
        if dry_run:
            self.stdout.write(
                self.style.WARNING(
                    f'DRY RUN: Would delete {count} request logs older than {days} days'
                )
            )
            
            # Show breakdown by type
            if count > 0:
                self.stdout.write('\nBreakdown by request type:')
                
                api_count = logs_to_delete.filter(is_api_request=True).count()
                admin_count = logs_to_delete.filter(is_admin_request=True).count()
                error_count = logs_to_delete.filter(is_error=True).count()
                other_count = count - api_count - admin_count - error_count
                
                self.stdout.write(f'  API requests: {api_count}')
                self.stdout.write(f'  Admin requests: {admin_count}')
                self.stdout.write(f'  Error requests: {error_count}')
                self.stdout.write(f'  Other requests: {other_count}')
        else:
            if count == 0:
                self.stdout.write(
                    self.style.SUCCESS(f'No request logs older than {days} days found.')
                )
            else:
                logs_to_delete.delete()
                self.stdout.write(
                    self.style.SUCCESS(
                        f'Successfully deleted {count} request logs older than {days} days'
                    )
                )
        
        # Show current statistics
        total_logs = RequestLog.objects.count()
        recent_logs = RequestLog.objects.filter(timestamp__gte=cutoff_date).count()
        
        self.stdout.write(f'\nCurrent statistics:')
        self.stdout.write(f'  Total logs in database: {total_logs}')
        self.stdout.write(f'  Logs from last {days} days: {recent_logs}') 