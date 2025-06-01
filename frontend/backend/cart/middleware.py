from django.utils.deprecation import MiddlewareMixin
from django.contrib.auth import user_logged_in
from django.dispatch import receiver
from .models import Cart
import uuid

class CartMiddleware(MiddlewareMixin):
    """
    Middleware to handle cart session management for anonymous users 
    and to merge anonymous carts with user carts upon login.
    """
    def process_request(self, request):
        # Skip for admin, static, and media requests
        if any(url in request.path for url in ['/admin/', '/static/', '/media/']):
            return None
        
        # Skip for API requests that don't need session cart
        if '/api/' in request.path and request.path not in ['/api/cart/', '/api/cart/add_item/', 
                                                           '/api/cart/remove_item/', '/api/cart/update_item/', 
                                                           '/api/cart/clear/']:
            return None
        
        # For anonymous users, create or get session cart
        if request.user.is_anonymous:
            session_key = request.session.session_key
            
            # Create a new session if needed
            if not session_key:
                request.session.create()
                session_key = request.session.session_key
            
            # Store session_key in the request for later use in views
            request.cart_session_key = session_key
        
        return None

@receiver(user_logged_in)
def merge_carts_on_login(sender, user, request, **kwargs):
    """
    When a user logs in, merge their anonymous cart (if any) with their user cart
    """
    session_key = request.session.session_key
    
    if not session_key:
        return
    
    # Try to find session cart
    try:
        session_cart = Cart.objects.get(
            session_key=session_key, 
            user__isnull=True,
            merged=False
        )
    except Cart.DoesNotExist:
        # No session cart exists
        return
    
    # Get or create user cart
    user_cart, created = Cart.objects.get_or_create(user=user)
    
    # Merge the carts
    user_cart.merge_with(session_cart) 