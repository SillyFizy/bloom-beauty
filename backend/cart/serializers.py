from rest_framework import serializers
from .models import Cart, CartItem, CartVariantItem
from products.serializers import ProductListSerializer
from products.models import Product, ProductVariant
from products.serializers import ProductListSerializer, ProductVariantSerializer

class CartItemSerializer(serializers.ModelSerializer):
    product = ProductListSerializer(read_only=True)
    product_id = serializers.PrimaryKeyRelatedField(
        queryset=Product.objects.filter(is_active=True), 
        write_only=True, 
        source='product'
    )
    subtotal = serializers.SerializerMethodField()
    
    class Meta:
        model = CartItem
        fields = ['id', 'product', 'product_id', 'quantity', 'subtotal', 'added_at', 'updated_at']
        read_only_fields = ['added_at', 'updated_at']
    
    def get_subtotal(self, obj):
        return obj.subtotal
    
    def validate_quantity(self, value):
        if value < 1:
            raise serializers.ValidationError("Quantity must be at least 1")
        return value
    
    def validate(self, attrs):
        product = attrs.get('product')
        quantity = attrs.get('quantity', 1)
        
        # Check if product is available and has enough stock
        if product and not product.is_active:
            raise serializers.ValidationError({"product": "This product is currently unavailable"})
        
        if product and product.stock < quantity:
            raise serializers.ValidationError(
                {"quantity": f"Not enough stock available. Only {product.stock} items left."}
            )
        
        return attrs

class CartVariantItemSerializer(serializers.ModelSerializer):
    variant = ProductVariantSerializer(read_only=True)
    variant_id = serializers.PrimaryKeyRelatedField(
        queryset=ProductVariant.objects.filter(is_active=True), 
        write_only=True, 
        source='variant'
    )
    subtotal = serializers.SerializerMethodField()
    
    class Meta:
        model = CartVariantItem
        fields = ['id', 'variant', 'variant_id', 'quantity', 'subtotal', 'added_at', 'updated_at']
        read_only_fields = ['added_at', 'updated_at']
    
    def get_subtotal(self, obj):
        return obj.subtotal
    
    def validate_quantity(self, value):
        if value < 1:
            raise serializers.ValidationError("Quantity must be at least 1")
        return value
    
    def validate(self, attrs):
        variant = attrs.get('variant')
        quantity = attrs.get('quantity', 1)
        
        if variant:
            # Check if variant and parent product are available
            if not variant.is_active or not variant.product.is_active:
                raise serializers.ValidationError({"variant": "This product variant is currently unavailable"})
            
            # Check stock
            if variant.stock < quantity:
                raise serializers.ValidationError(
                    {"quantity": f"Not enough stock available. Only {variant.stock} items left."}
                )
        
        return attrs

class CartSerializer(serializers.ModelSerializer):
    items = CartItemSerializer(many=True, read_only=True)
    variant_items = CartVariantItemSerializer(many=True, read_only=True)
    total = serializers.SerializerMethodField()
    item_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Cart
        fields = ['id', 'items', 'variant_items', 'total', 'item_count', 'created_at', 'updated_at']
        read_only_fields = ['created_at', 'updated_at']
    
    def get_total(self, obj):
        return obj.total
    
    def get_item_count(self, obj):
        return obj.item_count

class AddToCartSerializer(serializers.Serializer):
    product_id = serializers.IntegerField(required=False)
    variant_id = serializers.IntegerField(required=False)
    quantity = serializers.IntegerField(min_value=1, default=1)
    
    def validate(self, attrs):
        # Check that either product_id or variant_id is provided, but not both
        if 'product_id' not in attrs and 'variant_id' not in attrs:
            raise serializers.ValidationError("Either product_id or variant_id must be provided")
        
        if 'product_id' in attrs and 'variant_id' in attrs:
            raise serializers.ValidationError("Please provide either product_id or variant_id, not both")
        
        # Validate product exists and is active
        if 'product_id' in attrs:
            try:
                product = Product.objects.get(pk=attrs['product_id'], is_active=True)
                if product.stock < attrs['quantity']:
                    raise serializers.ValidationError({
                        "quantity": f"Not enough stock available. Only {product.stock} items left."
                    })
            except Product.DoesNotExist:
                raise serializers.ValidationError({"product_id": "Product not found or not available"})
        
        # Validate variant exists and is active
        if 'variant_id' in attrs:
            try:
                variant = ProductVariant.objects.get(pk=attrs['variant_id'], is_active=True)
                if not variant.product.is_active:
                    raise serializers.ValidationError({"variant_id": "The product for this variant is not available"})
                
                if variant.stock < attrs['quantity']:
                    raise serializers.ValidationError({
                        "quantity": f"Not enough stock available. Only {variant.stock} items left."
                    })
            except ProductVariant.DoesNotExist:
                raise serializers.ValidationError({"variant_id": "Product variant not found or not available"})
        
        return attrs

class UpdateCartItemSerializer(serializers.Serializer):
    item_id = serializers.IntegerField(required=True)
    quantity = serializers.IntegerField(min_value=1, required=True)
    is_variant = serializers.BooleanField(default=False)

class RemoveFromCartSerializer(serializers.Serializer):
    item_id = serializers.IntegerField(required=True)
    is_variant = serializers.BooleanField(default=False)