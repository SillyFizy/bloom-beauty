from django.db.models.signals import post_save
from django.dispatch import receiver
from datetime import date, timedelta
from decimal import Decimal

from orders.models import Order
from .models import User, PointTransaction

@receiver(post_save, sender=Order)
def create_points_for_order(sender, instance, created, **kwargs):
    """
    Award points to users when an order is completed
    """
    # Only process orders that have been completed
    if instance.status == 'delivered':
        # Check if we've already processed this order for points
        points_already_awarded = PointTransaction.objects.filter(
            user=instance.user,
            transaction_type='earned',
            reference=f"order_{instance.id}"
        ).exists()
        
        if not points_already_awarded:
            # Calculate points based on order total (1 point per $1 spent)
            points = int(instance.total_amount)
            
            # Apply tier multiplier
            multiplier = 1.0  # Normal tier
            if instance.user.tier == 'pointz_tier_1':
                multiplier = 1.1  # 10% bonus
            elif instance.user.tier == 'pointz_tier_2':
                multiplier = 1.2  # 20% bonus
            elif instance.user.tier == 'pointz_tier_3':
                multiplier = 1.5  # 50% bonus
            
            # Apply the multiplier
            points = int(points * multiplier)
            
            # Create the point transaction
            transaction = PointTransaction.objects.create(
                user=instance.user,
                points=points,
                transaction_type='earned',
                description=f"Points earned for order #{instance.id}",
                reference=f"order_{instance.id}"
            )
            
            # Set the points expiry date (1 year from now)
            if instance.user.pointz_expiry_date is None:
                instance.user.pointz_expiry_date = date.today() + timedelta(days=365)
            
            # Save the user to update points total and trigger tier update
            instance.user.add_points(points)

def expire_points():
    """
    Utility function to expire points
    This would typically be called by a scheduled task/cron job
    """
    today = date.today()
    
    # Get all users with points expiring today
    users_with_expiring_points = User.objects.filter(
        pointz_expiry_date=today,
        points__gt=0
    )
    
    for user in users_with_expiring_points:
        # Create a transaction to expire all points
        PointTransaction.objects.create(
            user=user,
            points=user.points,
            transaction_type='expired',
            description=f"Points expired on {today}"
        )
        
        # Update user points
        user.points = 0
        user.pointz_expiry_date = None
        user.update_tier()
        user.save() 