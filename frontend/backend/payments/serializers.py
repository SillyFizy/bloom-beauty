from rest_framework import serializers
from .models import Payment
from orders.serializers import OrderSerializer

class PaymentSerializer(serializers.ModelSerializer):
    order_id = serializers.IntegerField(source='order.id', read_only=True)
    order_number = serializers.CharField(source='order.id', read_only=True)
    order_total = serializers.DecimalField(
        max_digits=10, 
        decimal_places=2, 
        source='order.total_amount', 
        read_only=True
    )
    
    class Meta:
        model = Payment
        fields = [
            'id', 'order_id', 'order_number', 'order_total', 
            'amount', 'payment_method', 'status', 'transaction_id',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at']