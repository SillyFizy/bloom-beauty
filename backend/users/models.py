# users/models.py
from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.utils.translation import gettext_lazy as _
from django.core.validators import RegexValidator

class UserManager(BaseUserManager):
    """Custom user manager for User model that uses phone number instead of username"""
    
    def create_user(self, phone_number, password=None, **extra_fields):
        """Create and return a regular user with a phone number and password"""
        if not phone_number:
            raise ValueError('The phone number must be set')
        
        extra_fields.setdefault('is_staff', False)
        extra_fields.setdefault('is_superuser', False)
        
        user = self.model(phone_number=phone_number, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user
    
    def create_superuser(self, phone_number, password=None, **extra_fields):
        """Create and return a superuser with a phone number and password"""
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        
        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')
        
        return self.create_user(phone_number, password, **extra_fields)

class User(AbstractUser):
    phone_regex = RegexValidator(
        regex=r'^\+?1?\d{9,15}$',
        message="Phone number must be entered in the format: '+999999999'. Up to 15 digits allowed."
    )
    phone_number = models.CharField(
        validators=[phone_regex], 
        max_length=17, 
        unique=True,  # Make phone number unique
        help_text="Phone number for authentication"
    )
    
    # Make email optional since we're using phone number for auth
    email = models.EmailField(_('email address'), blank=True, null=True)
    
    # Override username field to not be required for authentication
    username = models.CharField(
        _('username'),
        max_length=150,
        blank=True,
        null=True,
        help_text=_('Optional. 150 characters or fewer. Letters, digits and @/./+/-/_ only.'),
    )
    
    # Use phone number as the unique identifier for authentication
    USERNAME_FIELD = 'phone_number'
    REQUIRED_FIELDS = ['first_name', 'last_name']  # Remove email from required fields
    
    # Use the custom user manager
    objects = UserManager()
    
    address_line1 = models.CharField(max_length=255, blank=True, null=True)
    address_line2 = models.CharField(max_length=255, blank=True, null=True)
    city = models.CharField(max_length=100, blank=True, null=True)
    state = models.CharField(max_length=100, blank=True, null=True)
    country = models.CharField(max_length=100, blank=True, null=True)
    postal_code = models.CharField(max_length=20, blank=True, null=True)
    is_verified = models.BooleanField(default=False)
    profile_picture = models.ImageField(upload_to='profile_pictures/', blank=True, null=True)
    birth_date = models.DateField(null=True, blank=True)
    
    # Fields for different user tiers and points system
    TIER_CHOICES = (
        ('normal', 'Normal'),
        ('celebrity', 'Celebrity'),
        ('pointz_tier_1', 'Pointz Tier 1'),
        ('pointz_tier_2', 'Pointz Tier 2'),
        ('pointz_tier_3', 'Pointz Tier 3'),
    )
    tier = models.CharField(max_length=20, choices=TIER_CHOICES, default='normal')
    points = models.PositiveIntegerField(default=0)
    pointz_expiry_date = models.DateField(null=True, blank=True)
    
    # Notification preferences
    email_notifications = models.BooleanField(default=True)
    sms_notifications = models.BooleanField(default=False)
    
    # Additional user preferences
    CURRENCY_CHOICES = (
        ('USD', 'US Dollar'),
        ('EUR', 'Euro'),
        ('GBP', 'British Pound'),
        ('AED', 'UAE Dirham'),
    )
    
    LANGUAGE_CHOICES = (
        ('en', 'English'),
        ('ar', 'Arabic'),
        ('fr', 'French'),
    )
    
    preferred_currency = models.CharField(max_length=3, choices=CURRENCY_CHOICES, default='USD')
    preferred_language = models.CharField(max_length=2, choices=LANGUAGE_CHOICES, default='en')
    product_recommendations = models.BooleanField(default=True, help_text="Receive product recommendations based on browsing history")
    order_updates_notifications = models.BooleanField(default=True, help_text="Receive notifications about order status changes")
    marketing_emails = models.BooleanField(default=True, help_text="Receive marketing emails and promotions")
    wishlist_alerts = models.BooleanField(default=True, help_text="Receive alerts when wishlist items go on sale")
    
    class Meta:
        verbose_name = _('user')
        verbose_name_plural = _('users')
    
    def __str__(self):
        return self.phone_number or f"User {self.id}"
    
    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}".strip()
    
    @property
    def full_address(self):
        address_parts = [
            self.address_line1,
            self.address_line2,
            self.city,
            self.state,
            self.postal_code,
            self.country
        ]
        return ', '.join(filter(None, address_parts))
    
    def add_points(self, points):
        """Add points to user's account"""
        self.points += points
        self.update_tier()
        self.save()
    
    def update_tier(self):
        """Update user tier based on points"""
        if self.points >= 10000:
            self.tier = 'pointz_tier_3'
        elif self.points >= 5000:
            self.tier = 'pointz_tier_2'
        elif self.points >= 1000:
            self.tier = 'pointz_tier_1'
        # Celebrity tier is manually assigned


class PointTransaction(models.Model):
    """Model to track point transactions"""
    TRANSACTION_TYPES = (
        ('earned', 'Earned'),
        ('redeemed', 'Redeemed'),
        ('expired', 'Expired'),
        ('adjustment', 'Adjustment'),
    )
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='point_transactions')
    points = models.IntegerField()
    transaction_type = models.CharField(max_length=20, choices=TRANSACTION_TYPES)
    description = models.TextField(blank=True, null=True)
    reference = models.CharField(max_length=255, blank=True, null=True) # For order reference, etc.
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.transaction_type} - {self.points} - {self.user.phone_number}"