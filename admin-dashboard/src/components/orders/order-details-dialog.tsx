"use client";

import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import { MapPin, User, Phone, Package, Truck, CreditCard, Calendar } from "lucide-react";
import { useOrder } from "@/hooks/use-orders";
import { Loader2 } from "lucide-react";

interface OrderDetailsDialogProps {
  orderId: number | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

// Format IQD currency
const formatIQD = (amount: number): string => {
  return new Intl.NumberFormat('ar-IQ', {
    style: 'currency',
    currency: 'IQD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount).replace('IQD', '').trim() + ' د.ع';
};

// Status mapping with colors
const getStatusInfo = (status: string) => {
  const statusMap = {
    processing: { label: "Processing", color: "bg-blue-100 text-blue-800" },
    shipped: { label: "Shipped", color: "bg-green-100 text-green-800" },
    returned: { label: "On the Way Back", color: "bg-yellow-100 text-yellow-800" },
    cancelled: { label: "Rejected", color: "bg-red-100 text-red-800" },
    delivered: { label: "Delivered", color: "bg-emerald-100 text-emerald-800" },
  };
  
  return statusMap[status as keyof typeof statusMap] || { 
    label: status, 
    color: "bg-gray-100 text-gray-800" 
  };
};

export const OrderDetailsDialog: React.FC<OrderDetailsDialogProps> = ({ orderId, open, onOpenChange }) => {
  const { data: order, isLoading, isError } = useOrder(orderId ?? 0);

  if (!order && !isLoading) return null;

  const statusInfo = order ? getStatusInfo(order.status) : null;
  const subtotal = parseInt(order?.subtotal?.toString() || '0');
  const shipping = parseInt(order?.shipping_fee?.toString() || '0');
  const discount = parseInt(order?.discount?.toString() || '0');
  const total = parseInt(order?.total_amount?.toString() || '0');

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-6xl max-h-[95vh] overflow-y-auto bg-white">
        <DialogHeader>
          <DialogTitle className="text-2xl font-bold text-gray-900 flex items-center gap-3">
            <Package className="h-6 w-6 text-blue-600" />
            Order #{orderId}
          </DialogTitle>
        </DialogHeader>
        
        {isLoading ? (
          <div className="flex items-center justify-center py-8">
            <Loader2 className="h-8 w-8 animate-spin" />
            <span className="ml-2">Loading order details...</span>
          </div>
        ) : isError ? (
          <p className="text-sm text-destructive">Failed to load order details.</p>
        ) : order ? (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Customer & Status Info */}
            <div className="lg:col-span-1 space-y-4">
              <div className="bg-gradient-to-br from-blue-50 to-indigo-50 p-6 rounded-xl border border-blue-200">
                <h3 className="font-bold text-lg mb-4 flex items-center gap-2 text-blue-900">
                  <User className="h-5 w-5" />
                  Customer Details
                </h3>
                <div className="space-y-3">
                  <div className="flex items-center gap-2">
                    <User className="h-4 w-4 text-gray-500" />
                    <span className="font-medium">{order.customer_name}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Calendar className="h-4 w-4 text-gray-500" />
                    <span>{new Date(order.created_at).toLocaleDateString('en-GB')}</span>
                  </div>
                  <div className="pt-2">
                    <Badge className={`${statusInfo?.color} px-3 py-1 text-sm font-semibold`}>
                      {statusInfo?.label}
                    </Badge>
                  </div>
                </div>
              </div>

              {/* Shipping Address */}
              <div className="bg-gradient-to-br from-green-50 to-emerald-50 p-6 rounded-xl border border-green-200">
                <h3 className="font-bold text-lg mb-4 flex items-center gap-2 text-green-900">
                  <MapPin className="h-5 w-5" />
                  Delivery Address
                </h3>
                {order.shipping_address ? (
                  <div className="space-y-1 text-sm">
                    <p className="font-semibold">{order.shipping_address.full_name}</p>
                    <p className="text-gray-700">{order.shipping_address.address_line1}</p>
                    {order.shipping_address.address_line2 && (
                      <p className="text-gray-700">{order.shipping_address.address_line2}</p>
                    )}
                    <div className="pt-2">
                      <div className="bg-green-100 px-3 py-2 rounded-lg border border-green-300">
                        <p className="font-bold text-green-800">{order.shipping_address.city}</p>
                        <p className="text-sm text-green-700">{order.shipping_address.state} Governorate</p>
                        <p className="text-xs text-green-600">Iraq</p>
                      </div>
                    </div>
                  </div>
                ) : (
                  <p className="text-gray-500">No shipping address</p>
                )}
              </div>
            </div>

            {/* Order Items */}
            <div className="lg:col-span-2 space-y-6">
              <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
                <h3 className="font-bold text-xl mb-6 flex items-center gap-2 text-gray-900">
                  <Package className="h-6 w-6 text-purple-600" />
                  Order Items ({order.items?.length || 0})
                </h3>
                <div className="space-y-4">
                  {order.items && order.items.length > 0 ? (
                    order.items.map((item: any, index: number) => (
                      <div key={index} className="flex justify-between items-center p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                        <div className="flex-1">
                          <p className="font-semibold text-gray-900">{item.product_name}</p>
                          <p className="text-sm text-gray-600 mt-1">Quantity: {item.quantity}</p>
                        </div>
                        <div className="text-right ml-4">
                          <p className="font-semibold text-lg">{formatIQD(parseInt(item.unit_price?.toString() || '0'))} <span className="text-sm font-normal">each</span></p>
                          <p className="text-sm text-gray-600 mt-1">{formatIQD(parseInt(item.subtotal?.toString() || '0'))} <span className="text-xs">total</span></p>
                        </div>
                      </div>
                    ))
                  ) : (
                    <p className="text-gray-500 text-center py-8">No items in this order</p>
                  )}
                </div>
              </div>

              {/* Order Summary */}
              <div className="bg-gradient-to-br from-amber-50 to-orange-50 p-6 rounded-xl border border-amber-200">
                <h3 className="font-bold text-xl mb-6 flex items-center gap-2 text-amber-900">
                  <CreditCard className="h-6 w-6" />
                  Payment Summary
                </h3>
                <div className="space-y-4">
                  <div className="flex justify-between items-center py-2">
                    <span className="text-gray-700">Items Value:</span>
                    <span className="font-semibold text-lg">{formatIQD(subtotal)}</span>
                  </div>
                  <div className="flex justify-between items-center py-2">
                    <span className="text-gray-700 flex items-center gap-2">
                      <Truck className="h-4 w-4" />
                      Shipping to {order.shipping_address?.city}:
                    </span>
                    <span className="font-semibold text-lg text-blue-600">{formatIQD(shipping)}</span>
                  </div>
                  {discount > 0 && (
                    <div className="flex justify-between items-center py-2">
                      <span className="text-gray-700">Discount:</span>
                      <span className="font-semibold text-lg text-green-600">-{formatIQD(discount)}</span>
                    </div>
                  )}
                  <Separator className="my-4" />
                  <div className="flex justify-between items-center py-3 bg-white rounded-lg px-4 border-2 border-amber-300">
                    <span className="text-xl font-bold text-amber-900">Total Amount:</span>
                    <span className="text-2xl font-bold text-amber-900">{formatIQD(total)}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        ) : null}
        
        <div className="flex justify-end gap-3 mt-8 pt-6 border-t border-gray-200">
          <Button onClick={() => onOpenChange(false)} variant="outline" size="lg">
            Close
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}; 