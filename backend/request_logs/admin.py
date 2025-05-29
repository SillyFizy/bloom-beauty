from django.contrib import admin
from django.utils.html import format_html
from django.utils.safestring import mark_safe
from django.db.models import Count, Avg
from django.urls import reverse
from .models import RequestLog
import json

@admin.register(RequestLog)
class RequestLogAdmin(admin.ModelAdmin):
    list_display = [
        'colored_method', 'path_short', 'colored_status', 'user_display', 
        'response_time_display', 'timestamp_display', 'request_type_display'
    ]
    list_filter = [
        'method', 'response_status', 'is_api_request', 'is_admin_request', 
        'is_error', 'timestamp', 'user'
    ]
    search_fields = [
        'path', 'user__username', 'user__email', 'ip_address', 'user_agent'
    ]
    readonly_fields = [
        'method', 'path', 'query_params', 'request_headers_display', 
        'request_body_display', 'response_headers_display', 'response_body_display',
        'response_status', 'user', 'ip_address', 'user_agent', 'referer',
        'timestamp', 'response_time', 'view_name', 'is_api_request', 
        'is_admin_request', 'is_error', 'session_key', 'content_type', 'response_size'
    ]
    date_hierarchy = 'timestamp'
    ordering = ['-timestamp']
    list_per_page = 50
    list_max_show_all = 200
    
    fieldsets = (
        ('Request Information', {
            'fields': ('method', 'path', 'query_params', 'view_name', 'content_type'),
            'classes': ['collapse']
        }),
        ('Request Headers & Body', {
            'fields': ('request_headers_display', 'request_body_display'),
            'classes': ['collapse']
        }),
        ('Response Information', {
            'fields': ('response_status', 'response_size', 'response_headers_display', 'response_body_display'),
            'classes': ['collapse']
        }),
        ('User & Session', {
            'fields': ('user', 'session_key'),
            'classes': ['collapse']
        }),
        ('Client Information', {
            'fields': ('ip_address', 'user_agent', 'referer'),
            'classes': ['collapse']
        }),
        ('Performance & Context', {
            'fields': ('timestamp', 'response_time', 'is_api_request', 'is_admin_request', 'is_error'),
            'classes': ['collapse']
        }),
    )
    
    def colored_method(self, obj):
        """Display HTTP method with color coding"""
        colors = {
            'GET': '#28a745',    # Green
            'POST': '#007bff',   # Blue
            'PUT': '#ffc107',    # Yellow
            'PATCH': '#fd7e14',  # Orange
            'DELETE': '#dc3545', # Red
        }
        color = colors.get(obj.method, '#6c757d')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 2px 6px; border-radius: 3px; font-weight: bold;">{}</span>',
            color, obj.method
        )
    colored_method.short_description = 'Method'
    colored_method.admin_order_field = 'method'
    
    def colored_status(self, obj):
        """Display status code with color coding"""
        if obj.response_status < 300:
            color = '#28a745'  # Green for success
        elif obj.response_status < 400:
            color = '#17a2b8'  # Cyan for redirect
        elif obj.response_status < 500:
            color = '#ffc107'  # Yellow for client error
        else:
            color = '#dc3545'  # Red for server error
        
        return format_html(
            '<span style="background-color: {}; color: white; padding: 2px 6px; border-radius: 3px; font-weight: bold;">{}</span>',
            color, obj.response_status
        )
    colored_status.short_description = 'Status'
    colored_status.admin_order_field = 'response_status'
    
    def path_short(self, obj):
        """Display shortened path"""
        path = obj.path
        if len(path) > 50:
            return format_html('<span title="{}">{}</span>', path, path[:47] + '...')
        return path
    path_short.short_description = 'Path'
    path_short.admin_order_field = 'path'
    
    def user_display(self, obj):
        """Display user information"""
        if obj.user:
            user_url = reverse('admin:users_user_change', args=[obj.user.pk])
            return format_html('<a href="{}">{}</a>', user_url, obj.user.username)
        return format_html('<span style="color: #6c757d;">Anonymous</span>')
    user_display.short_description = 'User'
    user_display.admin_order_field = 'user__username'
    
    def response_time_display(self, obj):
        """Display formatted response time"""
        if obj.response_time < 100:
            color = '#28a745'  # Green for fast
        elif obj.response_time < 1000:
            color = '#ffc107'  # Yellow for medium
        else:
            color = '#dc3545'  # Red for slow
        
        return format_html(
            '<span style="color: {}; font-weight: bold;">{}</span>',
            color, obj.formatted_response_time
        )
    response_time_display.short_description = 'Response Time'
    response_time_display.admin_order_field = 'response_time'
    
    def timestamp_display(self, obj):
        """Display formatted timestamp"""
        return obj.timestamp.strftime('%Y-%m-%d %H:%M:%S')
    timestamp_display.short_description = 'Time'
    timestamp_display.admin_order_field = 'timestamp'
    
    def request_type_display(self, obj):
        """Display request type indicators"""
        indicators = []
        if obj.is_api_request:
            indicators.append('<span style="background-color: #007bff; color: white; padding: 1px 4px; border-radius: 2px; font-size: 10px;">API</span>')
        if obj.is_admin_request:
            indicators.append('<span style="background-color: #6f42c1; color: white; padding: 1px 4px; border-radius: 2px; font-size: 10px;">ADMIN</span>')
        if obj.is_error:
            indicators.append('<span style="background-color: #dc3545; color: white; padding: 1px 4px; border-radius: 2px; font-size: 10px;">ERROR</span>')
        
        return format_html(' '.join(indicators)) if indicators else '-'
    request_type_display.short_description = 'Type'
    
    def request_headers_display(self, obj):
        """Display formatted request headers"""
        if obj.request_headers:
            try:
                formatted_json = json.dumps(obj.request_headers, indent=2)
                return format_html('<pre style="background: #f8f9fa; padding: 10px; border-radius: 5px; max-height: 300px; overflow-y: auto;">{}</pre>', formatted_json)
            except:
                return obj.request_headers
        return 'No headers'
    request_headers_display.short_description = 'Request Headers'
    
    def request_body_display(self, obj):
        """Display formatted request body"""
        if obj.request_body:
            # Try to format as JSON if possible
            try:
                if obj.content_type == 'application/json':
                    json_data = json.loads(obj.request_body)
                    formatted_json = json.dumps(json_data, indent=2)
                    return format_html('<pre style="background: #f8f9fa; padding: 10px; border-radius: 5px; max-height: 400px; overflow-y: auto;">{}</pre>', formatted_json)
            except:
                pass
            
            return format_html('<pre style="background: #f8f9fa; padding: 10px; border-radius: 5px; max-height: 400px; overflow-y: auto;">{}</pre>', obj.request_body)
        return 'No body'
    request_body_display.short_description = 'Request Body'
    
    def response_headers_display(self, obj):
        """Display formatted response headers"""
        if obj.response_headers:
            try:
                formatted_json = json.dumps(obj.response_headers, indent=2)
                return format_html('<pre style="background: #f0f0f0; padding: 10px; border-radius: 5px; max-height: 300px; overflow-y: auto;">{}</pre>', formatted_json)
            except:
                return obj.response_headers
        return 'No headers'
    response_headers_display.short_description = 'Response Headers'
    
    def response_body_display(self, obj):
        """Display formatted response body"""
        if obj.response_body:
            # Try to format as JSON if possible
            try:
                content_type = obj.response_headers.get('content-type', '')
                if 'application/json' in content_type:
                    json_data = json.loads(obj.response_body)
                    formatted_json = json.dumps(json_data, indent=2)
                    return format_html('<pre style="background: #f0f0f0; padding: 10px; border-radius: 5px; max-height: 400px; overflow-y: auto;">{}</pre>', formatted_json)
            except:
                pass
            
            return format_html('<pre style="background: #f0f0f0; padding: 10px; border-radius: 5px; max-height: 400px; overflow-y: auto;">{}</pre>', obj.response_body)
        return 'No body'
    response_body_display.short_description = 'Response Body'
    
    def has_add_permission(self, request):
        """Disable adding new logs through admin"""
        return False
    
    def has_change_permission(self, request, obj=None):
        """Disable editing logs through admin"""
        return False
    
    def has_delete_permission(self, request, obj=None):
        """Allow deletion of logs for cleanup"""
        return request.user.is_superuser
    
    def changelist_view(self, request, extra_context=None):
        """Add summary statistics to the changelist view"""
        response = super().changelist_view(request, extra_context=extra_context)
        
        try:
            qs = response.context_data['cl'].queryset
            
            # Calculate summary statistics
            total_requests = qs.count()
            error_requests = qs.filter(is_error=True).count()
            api_requests = qs.filter(is_api_request=True).count()
            avg_response_time = qs.aggregate(avg_time=Avg('response_time'))['avg_time'] or 0
            
            # Add to context
            summary_stats = {
                'total_requests': total_requests,
                'error_requests': error_requests,
                'success_rate': ((total_requests - error_requests) / total_requests * 100) if total_requests > 0 else 0,
                'api_requests': api_requests,
                'avg_response_time': f"{avg_response_time:.2f} ms" if avg_response_time else "0 ms",
            }
            
            response.context_data['summary_stats'] = summary_stats
        except (AttributeError, KeyError):
            pass
        
        return response
