import json
import time
from django.utils.deprecation import MiddlewareMixin
from django.http import HttpResponse
from django.conf import settings
from django.urls import resolve
from .models import RequestLog
import logging

logger = logging.getLogger(__name__)

class RequestLoggingMiddleware(MiddlewareMixin):
    """
    Middleware to log all HTTP requests and responses.
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
        super().__init__(get_response)
    
    def process_request(self, request):
        """Process the request and record start time"""
        request._request_start_time = time.time()
        return None
    
    def process_response(self, request, response):
        """Process the response and log the request/response data"""
        
        # Skip logging for certain requests if configured
        if self._should_skip_logging(request):
            return response
        
        try:
            # Calculate response time
            start_time = getattr(request, '_request_start_time', time.time())
            response_time = (time.time() - start_time) * 1000  # Convert to milliseconds
            
            # Get request data
            request_data = self._get_request_data(request)
            
            # Get response data
            response_data = self._get_response_data(response)
            
            # Get client information
            client_info = self._get_client_info(request)
            
            # Determine request type
            request_type_info = self._get_request_type_info(request)
            
            # Create the log entry
            RequestLog.objects.create(
                # Request Information
                method=request.method,
                path=request.path,
                query_params=request.GET.urlencode() if request.GET else None,
                
                # Request Headers and Body
                request_headers=request_data['headers'],
                request_body=request_data['body'],
                content_type=request.content_type,
                
                # Response Information
                response_status=response.status_code,
                response_headers=response_data['headers'],
                response_body=response_data['body'],
                response_size=len(response.content) if hasattr(response, 'content') else 0,
                
                # User and Session Information
                user=request.user if request.user.is_authenticated else None,
                session_key=request.session.session_key,
                
                # Client Information
                ip_address=client_info['ip_address'],
                user_agent=client_info['user_agent'],
                referer=client_info['referer'],
                
                # Timing and Performance
                response_time=response_time,
                
                # Additional Context
                view_name=request_type_info['view_name'],
                is_api_request=request_type_info['is_api_request'],
                is_admin_request=request_type_info['is_admin_request'],
                is_error=response.status_code >= 400,
            )
        
        except Exception as e:
            # Don't let logging errors break the application
            logger.error(f"Error logging request: {e}")
        
        return response
    
    def _should_skip_logging(self, request):
        """Determine if this request should be skipped from logging"""
        
        # Skip static files
        if request.path.startswith('/static/') or request.path.startswith('/media/'):
            return True
        
        # Skip favicon requests
        if request.path == '/favicon.ico':
            return True
        
        # Skip admin dashboard requests unless explicitly enabled
        if request.path.startswith('/admin/'):
            log_admin_requests = getattr(settings, 'REQUEST_LOG_ADMIN_REQUESTS', False)
            if not log_admin_requests:
                return True
        
        # Skip if logging is disabled for this request type
        skip_paths = getattr(settings, 'REQUEST_LOG_SKIP_PATHS', [])
        for skip_path in skip_paths:
            if request.path.startswith(skip_path):
                return True
        
        # Skip based on user agent (e.g., health checks)
        user_agent = request.META.get('HTTP_USER_AGENT', '')
        skip_user_agents = getattr(settings, 'REQUEST_LOG_SKIP_USER_AGENTS', [])
        for skip_agent in skip_user_agents:
            if skip_agent.lower() in user_agent.lower():
                return True
        
        return False
    
    def _get_request_data(self, request):
        """Extract request headers and body"""
        
        # Get headers (exclude sensitive headers)
        headers = {}
        sensitive_headers = ['authorization', 'cookie', 'x-api-key']
        
        for key, value in request.META.items():
            if key.startswith('HTTP_'):
                header_name = key[5:].replace('_', '-').lower()
                if header_name not in sensitive_headers:
                    headers[header_name] = value
        
        # Get request body
        body = None
        try:
            if hasattr(request, 'body') and request.body:
                # Limit body size to prevent huge logs
                max_body_size = getattr(settings, 'REQUEST_LOG_MAX_BODY_SIZE', 10000)
                body_content = request.body.decode('utf-8')[:max_body_size]
                
                # Try to parse JSON for better formatting
                if request.content_type == 'application/json':
                    try:
                        body = json.dumps(json.loads(body_content), indent=2)
                    except json.JSONDecodeError:
                        body = body_content
                else:
                    body = body_content
        except Exception:
            body = "Could not decode request body"
        
        return {
            'headers': headers,
            'body': body
        }
    
    def _get_response_data(self, response):
        """Extract response headers and body"""
        
        # Get response headers
        headers = {}
        for key, value in response.items():
            headers[key.lower()] = value
        
        # Get response body
        body = None
        try:
            if hasattr(response, 'content'):
                # Limit response size to prevent huge logs
                max_body_size = getattr(settings, 'REQUEST_LOG_MAX_BODY_SIZE', 10000)
                content = response.content.decode('utf-8')[:max_body_size]
                
                # Try to parse JSON for better formatting
                content_type = response.get('content-type', '')
                if 'application/json' in content_type:
                    try:
                        body = json.dumps(json.loads(content), indent=2)
                    except json.JSONDecodeError:
                        body = content
                elif content_type.startswith('text/'):
                    body = content
                else:
                    body = f"Binary content ({len(response.content)} bytes)"
        except Exception:
            body = "Could not decode response body"
        
        return {
            'headers': headers,
            'body': body
        }
    
    def _get_client_info(self, request):
        """Extract client information"""
        
        # Get client IP address
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip_address = x_forwarded_for.split(',')[0].strip()
        else:
            ip_address = request.META.get('REMOTE_ADDR', '127.0.0.1')
        
        return {
            'ip_address': ip_address,
            'user_agent': request.META.get('HTTP_USER_AGENT', ''),
            'referer': request.META.get('HTTP_REFERER', '')
        }
    
    def _get_request_type_info(self, request):
        """Determine request type and view information"""
        
        view_name = None
        try:
            resolved = resolve(request.path)
            view_name = resolved.view_name
        except Exception:
            pass
        
        is_api_request = request.path.startswith('/api/')
        is_admin_request = request.path.startswith('/admin/')
        
        return {
            'view_name': view_name,
            'is_api_request': is_api_request,
            'is_admin_request': is_admin_request
        } 