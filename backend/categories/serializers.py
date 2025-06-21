from rest_framework import serializers
from .models import NavigationCategory

class NavigationCategorySerializer(serializers.ModelSerializer):
    keywords_list = serializers.SerializerMethodField()
    
    class Meta:
        model = NavigationCategory
        fields = [
            'id',
            'name',
            'value', 
            'icon',
            'description',
            'keywords',
            'keywords_list',
            'order',
            'is_active',
            'created_at',
            'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_keywords_list(self, obj):
        """Return keywords as a list for easier frontend processing"""
        return obj.get_keywords_list()

class NavigationCategoryCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = NavigationCategory
        fields = [
            'name',
            'value',
            'icon', 
            'description',
            'keywords',
            'order',
            'is_active'
        ]

    def validate_value(self, value):
        """Ensure value is lowercase and valid"""
        value = value.lower().strip()
        if not value:
            raise serializers.ValidationError("Value cannot be empty")
        return value

    def validate_keywords(self, value):
        """Validate keywords format"""
        if not value:
            raise serializers.ValidationError("Keywords are required for product filtering")
        return value.strip()

class NavigationCategoryUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = NavigationCategory
        fields = [
            'name',
            'icon',
            'description', 
            'keywords',
            'order',
            'is_active'
        ]

    def validate_keywords(self, value):
        """Validate keywords format"""
        if not value:
            raise serializers.ValidationError("Keywords are required for product filtering")
        return value.strip()

class NavigationCategoryPublicSerializer(serializers.ModelSerializer):
    """Lightweight serializer for public frontend consumption"""
    keywords_list = serializers.SerializerMethodField()
    
    class Meta:
        model = NavigationCategory
        fields = [
            'name',
            'value',
            'icon',
            'keywords_list',
            'order'
        ]

    def get_keywords_list(self, obj):
        return obj.get_keywords_list() 