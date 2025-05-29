from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
import json

User = get_user_model()

class RequestLog(models.Model):
    # Request Information
    method = models.CharField(max_length=10)  # GET, POST, PUT, DELETE, etc.
    path = models.TextField()  # The requested URL path
    query_params = models.TextField(blank=True, null=True)  # GET parameters
    
    # Request Headers and Body
    request_headers = models.JSONField(default=dict, blank=True)
    request_body = models.TextField(blank=True, null=True)
    content_type = models.CharField(max_length=100, blank=True, null=True)
    
    # Response Information
    response_status = models.PositiveIntegerField()
    response_headers = models.JSONField(default=dict, blank=True)
    response_body = models.TextField(blank=True, null=True)
    response_size = models.PositiveIntegerField(default=0)  # Response size in bytes
    
    # User and Session Information
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    session_key = models.CharField(max_length=40, blank=True, null=True)
    
    # Client Information
    ip_address = models.GenericIPAddressField()
    user_agent = models.TextField(blank=True, null=True)
    referer = models.TextField(blank=True, null=True)
    
    # Timing and Performance
    timestamp = models.DateTimeField(default=timezone.now)
    response_time = models.FloatField(help_text="Response time in milliseconds")
    
    # Additional Context
    view_name = models.CharField(max_length=200, blank=True, null=True)
    is_api_request = models.BooleanField(default=False)
    is_admin_request = models.BooleanField(default=False)
    is_error = models.BooleanField(default=False)
    
    class Meta:
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['timestamp']),
            models.Index(fields=['method']),
            models.Index(fields=['response_status']),
            models.Index(fields=['user']),
            models.Index(fields=['is_api_request']),
            models.Index(fields=['is_error']),
        ]
    
    def __str__(self):
        return f"{self.method} {self.path} [{self.response_status}] - {self.timestamp}"
    
    @property
    def is_successful(self):
        """Check if the request was successful (2xx status codes)"""
        return 200 <= self.response_status < 300
    
    @property
    def status_category(self):
        """Categorize the response status"""
        if self.response_status < 200:
            return "Informational"
        elif self.response_status < 300:
            return "Success"
        elif self.response_status < 400:
            return "Redirection"
        elif self.response_status < 500:
            return "Client Error"
        else:
            return "Server Error"
    
    @property
    def formatted_response_time(self):
        """Format response time for display"""
        if self.response_time < 1000:
            return f"{self.response_time:.2f} ms"
        else:
            return f"{self.response_time/1000:.2f} s"
    
    def get_request_data_preview(self, max_length=100):
        """Get a preview of request data for admin display"""
        if self.request_body:
            preview = self.request_body[:max_length]
            if len(self.request_body) > max_length:
                preview += "..."
            return preview
        return "No body"
    
    def get_response_data_preview(self, max_length=100):
        """Get a preview of response data for admin display"""
        if self.response_body:
            preview = self.response_body[:max_length]
            if len(self.response_body) > max_length:
                preview += "..."
            return preview
        return "No body"
