from django.core.exceptions import PermissionDenied, ValidationError
from django.http import Http404
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import exception_handler
from rest_framework.exceptions import APIException
from datetime import datetime, timedelta

def custom_exception_handler(exc, context):
    """Custom exception handler for standardized error responses"""
    # Call REST framework's default exception handler first
    response = exception_handler(exc, context)
    
    # If this is already handled by DRF, add additional info
    if response is not None:
        error_data = {
            'status_code': response.status_code,
            'error': True,
            'timestamp': datetime.now().isoformat(),
            'message': '',
            'details': {}
        }
        
        if hasattr(exc, 'detail'):
            # Process the exception detail
            if isinstance(exc.detail, dict):
                for key, value in exc.detail.items():
                    if isinstance(value, list):
                        error_data['details'][key] = ' '.join(str(x) for x in value)
                    else:
                        error_data['details'][key] = str(value)
                
                # Add a general message
                if error_data['details']:
                    error_data['message'] = 'Validation error'
                else:
                    error_data['message'] = str(exc)
            else:
                error_data['message'] = str(exc.detail)
        else:
            error_data['message'] = str(exc)
        
        response.data = error_data
        return response
    
    # Handle Django exceptions that won't be caught by DRF's exception handler
    if isinstance(exc, Http404):
        return Response(
            {
                'status_code': status.HTTP_404_NOT_FOUND, 
                'error': True,
                'timestamp': datetime.now().isoformat(),
                'message': 'Resource not found',
                'details': {}
            }, 
            status=status.HTTP_404_NOT_FOUND
        )
    
    if isinstance(exc, PermissionDenied):
        return Response(
            {
                'status_code': status.HTTP_403_FORBIDDEN, 
                'error': True,
                'timestamp': datetime.now().isoformat(),
                'message': 'Permission denied',
                'details': {}
            }, 
            status=status.HTTP_403_FORBIDDEN
        )
    
    if isinstance(exc, ValidationError):
        return Response(
            {
                'status_code': status.HTTP_400_BAD_REQUEST, 
                'error': True,
                'timestamp': datetime.now().isoformat(),
                'message': 'Validation error',
                'details': {'general': str(exc)}
            }, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Fallback for any other exception
    return Response(
        {
            'status_code': status.HTTP_500_INTERNAL_SERVER_ERROR, 
            'error': True,
            'timestamp': datetime.now().isoformat(),
            'message': 'Internal server error',
            'details': {'general': str(exc) if str(exc) else 'An unexpected error occurred'}
        }, 
        status=status.HTTP_500_INTERNAL_SERVER_ERROR
    )

class APIKeyAuthentication:
    """
    Custom authentication for API key based access.
    Use with services or trusted third-party applications.
    """
    def __init__(self, get_response):
        self.get_response = get_response
        
    def __call__(self, request):
        from django.conf import settings
        from django.contrib.auth import get_user_model
        
        User = get_user_model()
        api_key_header = settings.API_KEY_CUSTOM_HEADER
        
        # Skip API key auth if accessing admin or docs
        path = request.path
        if path.startswith('/admin/') or path.startswith('/docs/'):
            return self.get_response(request)
        
        # Check if API key is provided in header
        if api_key_header in request.META:
            api_key = request.META[api_key_header]
            
            try:
                # This is simplified, in a real app you would have an APIKey model
                # with token field and user relation, then fetch:
                # api_key_obj = APIKey.objects.get(token=api_key, is_active=True)
                # request.user = api_key_obj.user
                
                # For demonstration, just use a hardcoded key for admin
                if api_key == 'YOUR_TEST_API_KEY':
                    admin_user = User.objects.filter(is_superuser=True).first()
                    if admin_user:
                        request.user = admin_user
            except Exception:
                pass

        return self.get_response(request)

def set_cookie(response, key, value, days_expire=30):
    """Helper to set a cookie with standard parameters"""
    if days_expire is None:
        max_age = 365 * 24 * 60 * 60  # One year
    else:
        max_age = days_expire * 24 * 60 * 60
    expires = datetime.now() + timedelta(seconds=max_age)
    
    response.set_cookie(
        key,
        value,
        max_age=max_age,
        expires=expires,
        httponly=True,
        samesite='Lax'  # Prevents CSRF in most contexts, still allows navigation from external sites
    )
    return response 