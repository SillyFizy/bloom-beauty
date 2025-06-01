from rest_framework import serializers
from .models import ShippingAddress, Order, OrderItem, OrderStatusHistory
from products.models import Product, ProductVariant
from users.serializers import UserSerializer
from django.db import transaction

class ShippingAddressSerializer(serializers.ModelSerializer):
    class Meta:
        model = ShippingAddress
        fields = ['id', 'full_name', 'phone_number', 'address_line1', 'address_line2', 
                 'city', 'state', 'country', 'postal_code', 'is_default']
        
    def create(self, validated_data):
        # Link the address to the current user
        user = self.context['request'].user
        validated_data['user'] = user
        return super().create(validated_data)

class OrderItemSerializer(serializers.ModelSerializer):
    product_name = serializers.SerializerMethodField()
    product_image = serializers.SerializerMethodField()
    
    class Meta:
        model = OrderItem
        fields = ['id', 'product', 'variant', 'quantity', 'unit_price', 'subtotal', 
                 'product_name', 'product_image']
        read_only_fields = ['unit_price', 'subtotal']
    
    def get_product_name(self, obj):
        if obj.product:
            return obj.product.name
        elif obj.variant:
            return f"{obj.variant.product.name} - {obj.variant.name}"
        return None
    
    def get_product_image(self, obj):
        request = self.context.get('request')
        if not request:
            return None
            
        if obj.product and obj.product.primary_image:
            return request.build_absolute_uri(obj.product.primary_image.url)
        elif obj.variant and obj.variant.image:
            return request.build_absolute_uri(obj.variant.image.url)
        elif obj.variant and obj.variant.product.primary_image:
            return request.build_absolute_uri(obj.variant.product.primary_image.url)
        return None

class OrderStatusHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = OrderStatusHistory
        fields = ['id', 'status', 'notes', 'created_at']
        read_only_fields = ['created_at']

class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    status_history = OrderStatusHistorySerializer(many=True, read_only=True)
    shipping_address = ShippingAddressSerializer(read_only=True)
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = Order
        fields = ['id', 'user', 'shipping_address', 'status', 'payment_method', 
                 'subtotal', 'shipping_fee', 'discount', 'total_amount', 'notes',
                 'tracking_number', 'is_paid', 'payment_status', 'created_at', 
                 'updated_at', 'items', 'status_history']
        read_only_fields = ['user', 'created_at', 'updated_at', 'payment_status']

class OrderDetailSerializer(OrderSerializer):
    """Extended serializer for order details"""
    pass
        
class CheckoutSerializer(serializers.Serializer):
    shipping_address_id = serializers.IntegerField(required=False)
    new_shipping_address = ShippingAddressSerializer(required=False)
    notes = serializers.CharField(required=False, allow_blank=True)
    
    def validate(self, attrs):
        # Validate that either shipping_address_id or new_shipping_address is provided
        if 'shipping_address_id' not in attrs and 'new_shipping_address' not in attrs:
            raise serializers.ValidationError({
                "shipping_address": "Either shipping_address_id or new_shipping_address must be provided"
            })
        
        # If shipping_address_id is provided, validate it exists and belongs to the user
        if 'shipping_address_id' in attrs:
            user = self.context['request'].user
            try:
                shipping_address = ShippingAddress.objects.get(
                    id=attrs['shipping_address_id'], 
                    user=user
                )
                attrs['shipping_address'] = shipping_address
            except ShippingAddress.DoesNotExist:
                raise serializers.ValidationError({
                    "shipping_address_id": "Shipping address does not exist or does not belong to you"
                })
                
        return attrs
    
    @transaction.atomic
    def create_order(self, validated_data, cart):
        request = self.context['request']
        user = request.user
        
        # Get or create shipping address
        if 'shipping_address' in validated_data:
            shipping_address = validated_data['shipping_address']
        else:
            # Create new shipping address
            address_data = validated_data['new_shipping_address']
            address_data['user'] = user
            shipping_address = ShippingAddress.objects.create(**address_data)
        
        # Calculate totals
        subtotal = cart.total
        shipping_fee = 0  # Could be calculated based on address, weight, etc.
        discount = 0  # Could be calculated based on user tier, promotions, etc.
        total_amount = subtotal + shipping_fee - discount
        
        # Create order
        order = Order.objects.create(
            user=user,
            shipping_address=shipping_address,
            subtotal=subtotal,
            shipping_fee=shipping_fee,
            discount=discount,
            total_amount=total_amount,
            notes=validated_data.get('notes', '')
        )
        
        # Create order status history
        OrderStatusHistory.objects.create(
            order=order,
            status='pending',
            notes='Order created'
        )
        
        # Create order items from cart
        for cart_item in cart.items.all():
            OrderItem.objects.create(
                order=order,
                product=cart_item.product,
                variant=None,
                quantity=cart_item.quantity,
                unit_price=cart_item.product.price,
                subtotal=cart_item.subtotal
            )
            
            # Update product stock
            product = cart_item.product
            product.stock -= cart_item.quantity
            product.save()
        
        # Create order items for variants
        for cart_variant_item in cart.variant_items.all():
            OrderItem.objects.create(
                order=order,
                product=None,
                variant=cart_variant_item.variant,
                quantity=cart_variant_item.quantity,
                unit_price=cart_variant_item.variant.product.price + cart_variant_item.variant.price_adjustment,
                subtotal=cart_variant_item.subtotal
            )
            
            # Update variant stock
            variant = cart_variant_item.variant
            variant.stock -= cart_variant_item.quantity
            variant.save()
        
        # Clear the cart
        cart.clear()
        
        return order