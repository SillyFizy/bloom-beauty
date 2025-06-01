from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _
from .models import User, PointTransaction

class PointTransactionInline(admin.TabularInline):
    model = PointTransaction
    extra = 0
    fields = ('transaction_type', 'points', 'description', 'reference', 'created_at')
    readonly_fields = ('created_at',)
    can_delete = False
    
    def has_add_permission(self, request, obj=None):
        return True

@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ('username', 'email', 'first_name', 'last_name', 'tier', 'points', 'is_verified', 'is_staff')
    list_filter = ('tier', 'is_verified', 'is_staff', 'is_active')
    search_fields = ('username', 'email', 'first_name', 'last_name', 'phone_number')
    readonly_fields = ('date_joined', 'last_login')
    
    fieldsets = (
        (None, {'fields': ('username', 'email', 'password')}),
        (_('Personal info'), {'fields': ('first_name', 'last_name', 'phone_number', 'birth_date', 'profile_picture')}),
        (_('Address'), {'fields': ('address_line1', 'address_line2', 'city', 'state', 'country', 'postal_code')}),
        (_('Tier & Points'), {'fields': ('tier', 'points', 'pointz_expiry_date')}),
        (_('Notifications'), {'fields': ('email_notifications', 'sms_notifications')}),
        (_('Status'), {'fields': ('is_verified', 'is_active')}),
        (_('Important dates'), {'fields': ('last_login', 'date_joined')}),
        (_('Permissions'), {'fields': ('is_staff', 'is_superuser', 'groups', 'user_permissions')}),
    )
    
    inlines = [PointTransactionInline]
    
    def save_model(self, request, obj, form, change):
        if change:
            original_obj = self.model.objects.get(pk=obj.pk)
            # Check if points changed
            if original_obj.points != obj.points:
                points_diff = obj.points - original_obj.points
                # Create point transaction
                PointTransaction.objects.create(
                    user=obj,
                    points=points_diff,
                    transaction_type='adjustment',
                    description=f"Manual adjustment by admin {request.user.username}"
                )
            
            # Check if tier changed
            if original_obj.tier != obj.tier:
                # If tier changed manually, we create a note in the description
                PointTransaction.objects.create(
                    user=obj,
                    points=0,
                    transaction_type='adjustment',
                    description=f"Tier manually changed from {original_obj.tier} to {obj.tier} by admin {request.user.username}"
                )
        
        super().save_model(request, obj, form, change)

@admin.register(PointTransaction)
class PointTransactionAdmin(admin.ModelAdmin):
    list_display = ('user', 'transaction_type', 'points', 'reference', 'created_at')
    list_filter = ('transaction_type', 'created_at')
    search_fields = ('user__username', 'user__email', 'description', 'reference')
    date_hierarchy = 'created_at'
    readonly_fields = ('created_at',)
    
    def save_model(self, request, obj, form, change):
        """
        When adding a new transaction, update the user's points
        """
        if not change:  # Only for new transactions
            user = obj.user
            
            # Update user points based on transaction type
            if obj.transaction_type == 'earned':
                user.points += obj.points
            elif obj.transaction_type == 'redeemed':
                if user.points < obj.points:
                    raise ValueError(f"User only has {user.points} points, can't redeem {obj.points} points")
                user.points -= obj.points
            elif obj.transaction_type == 'expired':
                if user.points < obj.points:
                    obj.points = user.points
                user.points -= obj.points
            elif obj.transaction_type == 'adjustment':
                user.points += obj.points  # Can be negative for deduction
            
            # Update user tier based on new points total
            user.update_tier()
            user.save()
            
        super().save_model(request, obj, form, change)
