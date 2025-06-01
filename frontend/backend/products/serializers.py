from rest_framework import serializers
from .models import (
    Category, Product, ProductImage, Brand, 
    ProductAttribute, ProductAttributeValue, 
    ProductVariant, InventoryLog
)

class CategorySerializer(serializers.ModelSerializer):
    parent_name = serializers.ReadOnlyField(source='parent.name', default=None)
    
    class Meta:
        model = Category
        fields = ['id', 'name', 'description', 'parent', 'parent_name', 
                  'image', 'slug', 'is_active', 'created_at', 'updated_at']
        read_only_fields = ['created_at', 'updated_at']
    
    def to_representation(self, instance):
        representation = super().to_representation(instance)
        if instance.image:
            request = self.context.get('request')
            if request:
                representation['image'] = request.build_absolute_uri(instance.image.url)
        return representation

class BrandSerializer(serializers.ModelSerializer):
    class Meta:
        model = Brand
        fields = ['id', 'name', 'description', 'logo', 'slug', 'is_active', 'created_at', 'updated_at']
        read_only_fields = ['created_at', 'updated_at']
    
    def to_representation(self, instance):
        representation = super().to_representation(instance)
        if instance.logo:
            request = self.context.get('request')
            if request:
                representation['logo'] = request.build_absolute_uri(instance.logo.url)
        return representation

class ProductAttributeSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductAttribute
        fields = ['id', 'name']

class ProductAttributeValueSerializer(serializers.ModelSerializer):
    attribute_name = serializers.ReadOnlyField(source='attribute.name')
    
    class Meta:
        model = ProductAttributeValue
        fields = ['id', 'attribute', 'attribute_name', 'value']

class ProductImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductImage
        fields = ['id', 'image', 'alt_text', 'is_feature', 'created_at']
        read_only_fields = ['created_at']
    
    def to_representation(self, instance):
        representation = super().to_representation(instance)
        if instance.image:
            request = self.context.get('request')
            if request:
                representation['image'] = request.build_absolute_uri(instance.image.url)
        return representation

class ProductVariantSerializer(serializers.ModelSerializer):
    attributes = ProductAttributeValueSerializer(many=True, read_only=True)
    attribute_ids = serializers.PrimaryKeyRelatedField(
        queryset=ProductAttributeValue.objects.all(),
        many=True, 
        write_only=True,
        source='attributes',
        required=False
    )
    
    class Meta:
        model = ProductVariant
        fields = ['id', 'name', 'sku', 'price_adjustment', 'stock', 
                 'attributes', 'attribute_ids', 'is_active', 'price', 
                 'created_at', 'updated_at']
        read_only_fields = ['created_at', 'updated_at', 'price']

class ProductListSerializer(serializers.ModelSerializer):
    category_name = serializers.ReadOnlyField(source='category.name')
    brand_name = serializers.ReadOnlyField(source='brand.name', default=None)
    discount_percentage = serializers.ReadOnlyField()
    is_on_sale = serializers.ReadOnlyField()
    
    class Meta:
        model = Product
        fields = ['id', 'name', 'price', 'sale_price', 'category_name', 
                  'brand_name', 'featured_image', 'stock', 'slug', 
                  'is_active', 'is_featured', 'is_on_sale', 'discount_percentage']
    
    def to_representation(self, instance):
        representation = super().to_representation(instance)
        if instance.featured_image:
            request = self.context.get('request')
            if request:
                representation['featured_image'] = request.build_absolute_uri(instance.featured_image.url)
        return representation

class ProductSerializer(serializers.ModelSerializer):
    category_name = serializers.ReadOnlyField(source='category.name')
    brand_name = serializers.ReadOnlyField(source='brand.name', default=None)
    discount_percentage = serializers.ReadOnlyField()
    is_on_sale = serializers.ReadOnlyField()
    is_low_stock = serializers.ReadOnlyField()
    images = ProductImageSerializer(many=True, read_only=True)
    variants = ProductVariantSerializer(many=True, read_only=True)
    attributes = ProductAttributeValueSerializer(many=True, read_only=True)
    attribute_ids = serializers.PrimaryKeyRelatedField(
        queryset=ProductAttributeValue.objects.all(),
        many=True, 
        write_only=True,
        source='attributes',
        required=False
    )
    
    class Meta:
        model = Product
        fields = ['id', 'name', 'description', 'price', 'sale_price', 
                  'category', 'category_name', 'brand', 'brand_name',
                  'attributes', 'attribute_ids', 'featured_image', 
                  'stock', 'sku', 'slug', 'is_active', 'is_featured',
                  'weight', 'dimensions', 'meta_keywords', 'meta_description',
                  'low_stock_threshold', 'is_on_sale', 'discount_percentage',
                  'is_low_stock', 'images', 'variants', 'created_at', 'updated_at']
        read_only_fields = ['created_at', 'updated_at']
    
    def to_representation(self, instance):
        representation = super().to_representation(instance)
        if instance.featured_image:
            request = self.context.get('request')
            if request:
                representation['featured_image'] = request.build_absolute_uri(instance.featured_image.url)
        return representation

class InventoryLogSerializer(serializers.ModelSerializer):
    product_name = serializers.ReadOnlyField(source='product.name')
    variant_name = serializers.ReadOnlyField(source='variant.name', default=None)
    user_name = serializers.ReadOnlyField(source='user.username', default=None)
    
    class Meta:
        model = InventoryLog
        fields = ['id', 'product', 'product_name', 'variant', 'variant_name',
                  'quantity', 'adjustment_type', 'reference', 'created_at', 
                  'user', 'user_name']
        read_only_fields = ['created_at', 'user_name']
    
    def create(self, validated_data):
        user = self.context['request'].user
        validated_data['user'] = user
        return super().create(validated_data)