from django.shortcuts import render
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db import transaction
from products.models import Product, ProductVariant
from .models import Cart, CartItem, CartVariantItem
from .serializers import (
    CartSerializer, CartItemSerializer, AddToCartSerializer, 
    UpdateCartItemSerializer, RemoveFromCartSerializer, CartVariantItemSerializer
)

class CartViewSet(viewsets.GenericViewSet):
    serializer_class = CartSerializer
    # Allow anonymous cart access
    permission_classes = [permissions.AllowAny]
    
    def get_cart(self, create=True):
        """
        Get the current user's cart or create a new one if it doesn't exist.
        For anonymous users, use the session key to retrieve/create the cart.
        """
        if self.request.user.is_authenticated:
            # For logged-in users, get or create their cart
            cart, created = Cart.objects.get_or_create(user=self.request.user)
            return cart
        else:
            # For anonymous users, get or create a session-based cart
            session_key = getattr(self.request, 'cart_session_key', None)
            if not session_key:
                return None
            
            if create:
                cart, created = Cart.objects.get_or_create(
                    session_key=session_key,
                    user__isnull=True,
                    merged=False
                )
                return cart
            else:
                try:
                    return Cart.objects.get(
                        session_key=session_key,
                        user__isnull=True,
                        merged=False
                    )
                except Cart.DoesNotExist:
                    return None
    
    def list(self, request):
        """Get the current user's cart"""
        cart = self.get_cart(create=False)
        if not cart:
            return Response({
                "id": None,
                "items": [],
                "variant_items": [],
                "total": 0,
                "item_count": 0
            })
        
        serializer = self.get_serializer(cart)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'])
    def add_item(self, request):
        """Add an item to the cart"""
        serializer = AddToCartSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Get cart
        cart = self.get_cart()
        if not cart:
            return Response(
                {"detail": "Unable to create cart. Please try again or log in."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        with transaction.atomic():
            # Check if we're adding a variant or a regular product
            if 'variant_id' in serializer.validated_data:
                variant_id = serializer.validated_data['variant_id']
                quantity = serializer.validated_data['quantity']
                
                # Get the variant
                variant = get_object_or_404(ProductVariant, pk=variant_id, is_active=True)
                
                # Check if variant has enough stock
                if variant.stock < quantity:
                    return Response(
                        {"detail": f"Not enough stock available. Only {variant.stock} items left."},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                # Check if variant is already in cart
                cart_item, created = CartVariantItem.objects.get_or_create(
                    cart=cart, 
                    variant=variant,
                    defaults={'quantity': quantity}
                )
                
                # If variant already exists, update quantity
                if not created:
                    cart_item.quantity += quantity
                    # Check if updated quantity exceeds stock
                    if cart_item.quantity > variant.stock:
                        return Response(
                            {"detail": f"Cannot add more items. Only {variant.stock} items available in stock."},
                            status=status.HTTP_400_BAD_REQUEST
                        )
                    cart_item.save()
                
                # Serialize the updated cart
                cart_serializer = self.get_serializer(cart)
                return Response(cart_serializer.data, status=status.HTTP_200_OK)
            
            else:  # Regular product
                product_id = serializer.validated_data['product_id']
                quantity = serializer.validated_data['quantity']
                
                # Get product
                product = get_object_or_404(Product, pk=product_id, is_active=True)
                
                # Check if product has enough stock
                if product.stock < quantity:
                    return Response(
                        {"detail": f"Not enough stock available. Only {product.stock} items left."},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                # Check if item is already in cart
                cart_item, created = CartItem.objects.get_or_create(
                    cart=cart, 
                    product=product,
                    defaults={'quantity': quantity}
                )
                
                # If item already exists, update quantity
                if not created:
                    cart_item.quantity += quantity
                    # Check if updated quantity exceeds stock
                    if cart_item.quantity > product.stock:
                        return Response(
                            {"detail": f"Cannot add more items. Only {product.stock} items available in stock."},
                            status=status.HTTP_400_BAD_REQUEST
                        )
                    cart_item.save()
            
            # Return updated cart
            cart_serializer = self.get_serializer(cart)
            return Response(cart_serializer.data, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['post'])
    def remove_item(self, request):
        """Remove an item from cart"""
        serializer = RemoveFromCartSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        item_id = serializer.validated_data['item_id']
        is_variant = serializer.validated_data['is_variant']
        
        # Get cart without creating a new one
        cart = self.get_cart(create=False)
        if not cart:
            return Response({"detail": "Cart not found"}, status=status.HTTP_404_NOT_FOUND)
        
        try:
            if is_variant:
                cart_item = CartVariantItem.objects.get(cart=cart, id=item_id)
            else:
                cart_item = CartItem.objects.get(cart=cart, id=item_id)
                
            cart_item.delete()
            
            cart_serializer = self.get_serializer(cart)
            return Response(cart_serializer.data)
        except (CartItem.DoesNotExist, CartVariantItem.DoesNotExist):
            return Response({"detail": "Item not found in cart"}, status=status.HTTP_404_NOT_FOUND)
    
    @action(detail=False, methods=['post'])
    def update_item(self, request):
        """Update item quantity in cart"""
        serializer = UpdateCartItemSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        item_id = serializer.validated_data['item_id']
        quantity = serializer.validated_data['quantity']
        is_variant = serializer.validated_data['is_variant']
        
        # Get cart without creating a new one
        cart = self.get_cart(create=False)
        if not cart:
            return Response({"detail": "Cart not found"}, status=status.HTTP_404_NOT_FOUND)
        
        try:
            if is_variant:
                cart_item = CartVariantItem.objects.get(cart=cart, id=item_id)
                
                # Check if new quantity exceeds stock
                if quantity > cart_item.variant.stock:
                    return Response(
                        {"detail": f"Cannot update quantity. Only {cart_item.variant.stock} items available in stock."},
                        status=status.HTTP_400_BAD_REQUEST
                    )
            else:
                cart_item = CartItem.objects.get(cart=cart, id=item_id)
                
                # Check if new quantity exceeds stock
                if quantity > cart_item.product.stock:
                    return Response(
                        {"detail": f"Cannot update quantity. Only {cart_item.product.stock} items available in stock."},
                        status=status.HTTP_400_BAD_REQUEST
                    )
            
            cart_item.quantity = quantity
            cart_item.save()
            
            cart_serializer = self.get_serializer(cart)
            return Response(cart_serializer.data)
        except (CartItem.DoesNotExist, CartVariantItem.DoesNotExist):
            return Response({"detail": "Item not found in cart"}, status=status.HTTP_404_NOT_FOUND)
    
    @action(detail=False, methods=['post'])
    def clear(self, request):
        """Clear all items from cart"""
        cart = self.get_cart(create=False)
        if not cart:
            return Response({"detail": "Cart not found"}, status=status.HTTP_404_NOT_FOUND)
        
        # Delete all items
        cart.clear()
        
        cart_serializer = self.get_serializer(cart)
        return Response(cart_serializer.data)
