from django.shortcuts import render, get_object_or_404
from rest_framework import viewsets, permissions, status
from rest_framework.response import Response

from .models import Payment
from .serializers import PaymentSerializer
from orders.models import Order, OrderStatusHistory

class PaymentViewSet(viewsets.ReadOnlyModelViewSet):
    """
    A simple ViewSet for viewing payments.
    Payment creation is handled through admin or automatically on COD confirmation.
    """
    serializer_class = PaymentSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Return only payments for orders belonging to the current user"""
        user = self.request.user
        
        # Admin can see all payments
        if user.is_staff:
            return Payment.objects.all().order_by('-created_at')
        
        # Regular users can only see their own payments
        return Payment.objects.filter(order__user=user).order_by('-created_at')
