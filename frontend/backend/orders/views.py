from django.shortcuts import render, get_object_or_404
from rest_framework import viewsets, permissions, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from django.db import transaction
from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.conf import settings
from django.utils.html import strip_tags

from .models import Order, OrderItem, ShippingAddress, OrderStatusHistory
from .serializers import (
    OrderSerializer, OrderItemSerializer, ShippingAddressSerializer, 
    CheckoutSerializer, OrderDetailSerializer, OrderStatusHistorySerializer
)
from cart.models import Cart, CartItem
from products.models import Product
from users.models import PointTransaction

class ShippingAddressViewSet(viewsets.ModelViewSet):
    """
    API endpoint for managing shipping addresses
    """
    serializer_class = ShippingAddressSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Return only addresses belonging to the current user"""
        return ShippingAddress.objects.filter(user=self.request.user)
    
    @action(detail=True, methods=['post'])
    def set_default(self, request, pk=None):
        """Set an address as the default shipping address"""
        address = self.get_object()
        address.is_default = True
        address.save()  # This will automatically update other addresses
        
        return Response({"status": "Default address set successfully"})
    
    def perform_create(self, serializer):
        """Set user automatically when creating a new address"""
        serializer.save(user=self.request.user)
    
    def perform_update(self, serializer):
        """Handle setting a new default address"""
        is_default = serializer.validated_data.get('is_default', False)
        if is_default:
            # This will be handled in the model's save method
            pass
        serializer.save()

class OrderViewSet(viewsets.ModelViewSet):
    """
    API endpoint for managing orders
    """
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_serializer_class(self):
        """Return different serializers for list and detail views"""
        if self.action == 'retrieve':
            return OrderDetailSerializer
        return OrderSerializer
    
    def get_queryset(self):
        """Return only orders belonging to the current user"""
        user = self.request.user
        
        # Admin can see all orders
        if user.is_staff:
            return Order.objects.all().order_by('-created_at')
        
        # Regular users can only see their own orders
        return Order.objects.filter(user=user).order_by('-created_at')
    
    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        """Cancel an order if it's still in 'pending' or 'confirmed' status"""
        order = self.get_object()
        
        # Only cancel orders in pending or confirmed status
        if order.status not in ['pending', 'confirmed']:
            return Response(
                {"detail": f"Cannot cancel order in {order.status} status."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Update order status
        order.status = 'cancelled'
        order.save()
        
        # Add to status history
        OrderStatusHistory.objects.create(
            order=order,
            status='cancelled',
            notes=f"Order cancelled by {request.user.username}"
        )
        
        # Return inventory to stock
        for item in order.items.all():
            if item.product:
                item.product.stock += item.quantity
                item.product.save()
            elif item.variant:
                item.variant.stock += item.quantity
                item.variant.save()
        
        # Send cancellation confirmation email
        self._send_order_status_email(order, "Order Cancelled", 
                                     "Your order has been cancelled.")
        
        return Response({"status": "Order cancelled successfully"})
    
    @action(detail=False, methods=['get'])
    def recent(self, request):
        """Get user's recent orders (last 5)"""
        orders = self.get_queryset()[:5]
        serializer = self.get_serializer(orders, many=True)
        return Response(serializer.data)
    
    def _send_order_status_email(self, order, subject_prefix, status_message):
        """Helper method to send order status emails"""
        user = order.user
        subject = f"{subject_prefix} - Order #{order.id}"
        
        context = {
            'user': user,
            'order': order,
            'status_message': status_message,
            'items': order.items.all(),
        }
        
        html_message = render_to_string('orders/email/order_status_update.html', context)
        plain_message = strip_tags(html_message)
        
        send_mail(
            subject,
            plain_message,
            settings.DEFAULT_FROM_EMAIL,
            [user.email],
            html_message=html_message,
            fail_silently=False,
        )

class CheckoutView(viewsets.ViewSet):
    """
    API endpoint for checkout process
    """
    permission_classes = [permissions.IsAuthenticated]
    
    @transaction.atomic
    def create(self, request):
        """
        Process checkout and create an order from the user's cart
        """
        # Get user's cart
        try:
            cart = Cart.objects.get(user=request.user)
        except Cart.DoesNotExist:
            return Response(
                {"detail": "You don't have an active cart."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Validate the cart has items
        if cart.item_count == 0:
            return Response(
                {"detail": "Your cart is empty."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Validate and process checkout data
        serializer = CheckoutSerializer(
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        
        # Create the order from cart
        try:
            order = serializer.create_order(serializer.validated_data, cart)
            
            # Add points for purchase (example: 1 point per $1 spent)
            points_earned = int(order.total_amount)
            if points_earned > 0:
                # Create points transaction
                PointTransaction.objects.create(
                    user=request.user,
                    points=points_earned,
                    transaction_type='earned',
                    description=f"Points earned from Order #{order.id}",
                    reference=f"order_{order.id}"
                )
                
                # Update user points
                user = request.user
                user.points += points_earned
                user.update_tier()
                user.save()
            
            # Send order confirmation email
            self._send_order_confirmation_email(order, points_earned)
            
            # Return the created order
            order_serializer = OrderDetailSerializer(order, context={'request': request})
            return Response(order_serializer.data, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            # Log the error
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Error during checkout: {str(e)}")
            
            # Return error response
            return Response(
                {"detail": "An error occurred during checkout. Please try again."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def _send_order_confirmation_email(self, order, points_earned=0):
        """Send order confirmation email to customer"""
        user = order.user
        subject = f"Order Confirmation - Order #{order.id}"
        
        context = {
            'user': user,
            'order': order,
            'shipping_address': order.shipping_address,
            'items': order.items.all(),
            'points_earned': points_earned,
        }
        
        html_message = render_to_string('orders/email/order_confirmation.html', context)
        plain_message = strip_tags(html_message)
        
        send_mail(
            subject,
            plain_message,
            settings.DEFAULT_FROM_EMAIL,
            [user.email],
            html_message=html_message,
            fail_silently=False,
        )
