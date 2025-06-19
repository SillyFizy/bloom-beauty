from rest_framework import serializers
from .models import Celebrity, CelebrityProductPromotion, CelebrityMorningRoutine, CelebrityEveningRoutine
from products.serializers import ProductSerializer


class CelebrityBasicSerializer(serializers.ModelSerializer):
    """Basic celebrity information without product relationships"""
    full_name = serializers.CharField(read_only=True)
    social_media_links = serializers.DictField(read_only=True)
    
    class Meta:
        model = Celebrity
        fields = [
            'id', 'first_name', 'last_name', 'full_name', 'image', 
            'bio', 'instagram_url', 'facebook_url', 'snapchat_url', 
            'social_media_links', 'is_active', 'created_at'
        ]


class CelebrityProductPromotionSerializer(serializers.ModelSerializer):
    """Serializer for celebrity product promotions"""
    celebrity = CelebrityBasicSerializer(read_only=True)
    product = ProductSerializer(read_only=True)
    
    class Meta:
        model = CelebrityProductPromotion
        fields = [
            'id', 'celebrity', 'product', 'testimonial', 'promotion_type',
            'is_featured', 'created_at', 'updated_at'
        ]


class CelebrityRoutineItemSerializer(serializers.ModelSerializer):
    """Base serializer for routine items"""
    product = ProductSerializer(read_only=True)
    
    class Meta:
        fields = ['id', 'product', 'order', 'description', 'created_at']


class CelebrityMorningRoutineSerializer(CelebrityRoutineItemSerializer):
    """Serializer for celebrity morning routine items"""
    
    class Meta(CelebrityRoutineItemSerializer.Meta):
        model = CelebrityMorningRoutine


class CelebrityEveningRoutineSerializer(CelebrityRoutineItemSerializer):
    """Serializer for celebrity evening routine items"""
    
    class Meta(CelebrityRoutineItemSerializer.Meta):
        model = CelebrityEveningRoutine


class CelebrityDetailSerializer(serializers.ModelSerializer):
    """Detailed celebrity information with all product relationships"""
    full_name = serializers.CharField(read_only=True)
    social_media_links = serializers.DictField(read_only=True)
    
    # Product relationships
    morning_routine_items = CelebrityMorningRoutineSerializer(many=True, read_only=True)
    evening_routine_items = CelebrityEveningRoutineSerializer(many=True, read_only=True)
    product_promotions = CelebrityProductPromotionSerializer(many=True, read_only=True)
    
    # Computed fields
    total_promotions = serializers.SerializerMethodField()
    featured_promotions = serializers.SerializerMethodField()
    morning_routine_count = serializers.SerializerMethodField()
    evening_routine_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Celebrity
        fields = [
            'id', 'first_name', 'last_name', 'full_name', 'image', 
            'bio', 'instagram_url', 'facebook_url', 'snapchat_url', 
            'social_media_links', 'is_active', 'created_at', 'updated_at',
            'morning_routine_items', 'evening_routine_items', 'product_promotions',
            'total_promotions', 'featured_promotions', 'morning_routine_count',
            'evening_routine_count'
        ]
    
    def get_total_promotions(self, obj):
        return obj.product_promotions.count()
    
    def get_featured_promotions(self, obj):
        return obj.product_promotions.filter(is_featured=True).count()
    
    def get_morning_routine_count(self, obj):
        return obj.morning_routine_items.count()
    
    def get_evening_routine_count(self, obj):
        return obj.evening_routine_items.count()


class CelebrityListSerializer(serializers.ModelSerializer):
    """Serializer for celebrity list view with summary information"""
    full_name = serializers.CharField(read_only=True)
    social_media_links = serializers.DictField(read_only=True)
    total_promotions = serializers.SerializerMethodField()
    featured_promotions_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Celebrity
        fields = [
            'id', 'first_name', 'last_name', 'full_name', 'image',
            'bio', 'social_media_links', 'is_active', 'created_at',
            'total_promotions', 'featured_promotions_count'
        ]
    
    def get_total_promotions(self, obj):
        return obj.product_promotions.count()
    
    def get_featured_promotions_count(self, obj):
        return obj.product_promotions.filter(is_featured=True).count()


# Product serializers with celebrity information
class ProductCelebrityEndorsementSerializer(serializers.ModelSerializer):
    """Serializer for celebrity endorsements on products"""
    celebrity_name = serializers.CharField(source='celebrity.full_name', read_only=True)
    celebrity_image = serializers.ImageField(source='celebrity.image', read_only=True)
    celebrity_id = serializers.IntegerField(source='celebrity.id', read_only=True)
    
    class Meta:
        model = CelebrityProductPromotion
        fields = [
            'id', 'celebrity_name', 'celebrity_image', 'celebrity_id',
            'testimonial', 'promotion_type', 'is_featured'
        ] 