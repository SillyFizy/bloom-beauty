# users/serializers.py
from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.utils.translation import gettext_lazy as _
from .models import PointTransaction
from orders.models import Order, OrderItem

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    full_name = serializers.ReadOnlyField()
    full_address = serializers.ReadOnlyField()
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'phone_number', 
                  'address_line1', 'address_line2', 'city', 'state', 'country', 'postal_code',
                  'full_name', 'full_address', 'is_verified', 'tier', 'points', 'pointz_expiry_date',
                  'profile_picture', 'birth_date', 'email_notifications', 'sms_notifications',
                  'preferred_currency', 'preferred_language', 'product_recommendations',
                  'order_updates_notifications', 'marketing_emails', 'wishlist_alerts', 'date_joined']
        read_only_fields = ['id', 'is_verified', 'date_joined', 'points', 'tier', 'pointz_expiry_date']
    
    def to_representation(self, instance):
        representation = super().to_representation(instance)
        if instance.profile_picture:
            request = self.context.get('request')
            if request:
                representation['profile_picture'] = request.build_absolute_uri(instance.profile_picture.url)
        return representation

class UserPreferencesSerializer(serializers.ModelSerializer):
    """Serializer for user preferences"""
    
    class Meta:
        model = User
        fields = [
            'preferred_currency', 'preferred_language', 'email_notifications', 
            'sms_notifications', 'product_recommendations', 'order_updates_notifications', 
            'marketing_emails', 'wishlist_alerts'
        ]

class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True, required=True)

    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'password2', 'first_name', 'last_name', 
                  'phone_number', 'address_line1', 'address_line2', 'city', 'state', 
                  'country', 'postal_code', 'birth_date', 'profile_picture']
        extra_kwargs = {
            'first_name': {'required': True},
            'last_name': {'required': True},
            'email': {'required': True}
        }

    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": _("Password fields didn't match.")})
        
        # Check if email already exists
        if User.objects.filter(email=attrs['email']).exists():
            raise serializers.ValidationError({"email": _("User with this email already exists.")})
        
        return attrs

    def create(self, validated_data):
        validated_data.pop('password2')
        user = User.objects.create_user(**validated_data)
        return user

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        data = super().validate(attrs)
        user = self.user
        data.update({
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'tier': user.tier,
            'points': user.points,
            'is_verified': user.is_verified
        })
        return data

class PasswordChangeSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, validators=[validate_password])
    new_password2 = serializers.CharField(required=True)

    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password2']:
            raise serializers.ValidationError({"new_password": _("Password fields didn't match.")})
        return attrs

class EmailVerificationSerializer(serializers.Serializer):
    token = serializers.CharField()

class AddressSerializer(serializers.Serializer):
    address_line1 = serializers.CharField(required=True)
    address_line2 = serializers.CharField(required=False, allow_blank=True)
    city = serializers.CharField(required=True)
    state = serializers.CharField(required=True)
    country = serializers.CharField(required=True)
    postal_code = serializers.CharField(required=True)

class PointTransactionSerializer(serializers.ModelSerializer):
    username = serializers.ReadOnlyField(source='user.username')
    
    class Meta:
        model = PointTransaction
        fields = ['id', 'user', 'username', 'points', 'transaction_type', 
                  'description', 'reference', 'created_at']
        read_only_fields = ['created_at']

class NotificationPreferencesSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['email_notifications', 'sms_notifications', 'order_updates_notifications', 
                 'marketing_emails', 'product_recommendations', 'wishlist_alerts']

class ProfilePictureSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['profile_picture']
    
    def to_representation(self, instance):
        representation = super().to_representation(instance)
        if instance.profile_picture:
            request = self.context.get('request')
            if request:
                representation['profile_picture'] = request.build_absolute_uri(instance.profile_picture.url)
        return representation

class OrderSummarySerializer(serializers.ModelSerializer):
    """Simplified serializer for order history"""
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    item_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Order
        fields = ['id', 'created_at', 'status', 'status_display', 'total_amount', 
                 'item_count', 'payment_method', 'is_paid', 'tracking_number']
    
    def get_item_count(self, obj):
        return obj.items.count()