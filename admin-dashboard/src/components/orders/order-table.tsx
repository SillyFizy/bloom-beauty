import React from 'react';
import { Order, OrderStatus } from '@/types/order';
import { useUpdateOrderStatus } from '@/hooks/use-orders';
import { format } from 'date-fns';
import { OrderDetailsDialog } from './order-details-dialog';
import { Eye, MapPin, Calendar, CreditCard } from 'lucide-react';

interface OrderTableProps {
  orders: Order[];
}

const statusOptions: { value: OrderStatus; label: string }[] = [
  { value: 'processing', label: 'Processing' },
  { value: 'shipped', label: 'Shipped' },
  { value: 'returned', label: 'On the Way Back' },
  { value: 'cancelled', label: 'Rejected' },
  { value: 'delivered', label: 'Delivered' },
];

// Format IQD currency
const formatIQD = (amount: number): string => {
  return new Intl.NumberFormat('ar-IQ', {
    style: 'currency',
    currency: 'IQD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount).replace('IQD', '').trim() + ' د.ع';
};

// Status colors
const getStatusColor = (status: OrderStatus): string => {
  const colorMap = {
    processing: "bg-blue-100 text-blue-800 border-blue-200",
    shipped: "bg-green-100 text-green-800 border-green-200",
    returned: "bg-yellow-100 text-yellow-800 border-yellow-200",
    cancelled: "bg-red-100 text-red-800 border-red-200",
    delivered: "bg-emerald-100 text-emerald-800 border-emerald-200",
  };
  return colorMap[status] || "bg-gray-100 text-gray-800 border-gray-200";
};

export const OrderTable: React.FC<OrderTableProps> = ({ orders }) => {
  const updateMutation = useUpdateOrderStatus();

  const [selectedOrder, setSelectedOrder] = React.useState<number | null>(null);
  const [detailsOpen, setDetailsOpen] = React.useState(false);

  const openDetails = (orderId: number) => {
    setSelectedOrder(orderId);
    setDetailsOpen(true);
  };

  const handleStatusChange = (orderId: number, status: OrderStatus) => {
    updateMutation.mutate({ orderId, status });
  };

  return (
    <div className="w-full overflow-x-auto bg-white rounded-xl shadow-sm border border-gray-200">
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gradient-to-r from-gray-50 to-gray-100">
          <tr>
            <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Order #</th>
            <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Customer</th>
            <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Address & City</th>
            <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Total (Items + Shipping)</th>
            <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Date</th>
            <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Status</th>
            <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Actions</th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-100">
          {orders.map((order) => (
            <tr key={order.id} className="hover:bg-gray-50 transition-colors">
              <td className="px-6 py-4 whitespace-nowrap">
                <span className="text-sm font-bold text-indigo-600">#{order.id}</span>
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                <span className="text-sm font-medium text-gray-900">{order.customer_name}</span>
              </td>
              <td className="px-6 py-4">
                <div className="flex items-start gap-2">
                  <MapPin className="h-4 w-4 text-gray-400 mt-0.5 flex-shrink-0" />
                  <div className="text-sm">
                    <p className="text-gray-900 font-medium">{order.shipping_address?.city}</p>
                    <p className="text-gray-500 text-xs truncate max-w-[200px]">
                      {order.shipping_address?.address_line1}
                    </p>
                  </div>
                </div>
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                <div className="text-sm">
                  <div className="flex items-center gap-1 text-gray-900 font-semibold">
                    <CreditCard className="h-4 w-4 text-green-600" />
                    {formatIQD(parseInt(order.total_amount?.toString() || '0'))}
                  </div>
                  <div className="text-xs text-gray-500 mt-1">
                    Items: {formatIQD(parseInt(order.subtotal?.toString() || '0'))} + 
                    Shipping: {formatIQD(parseInt(order.shipping_fee?.toString() || '0'))}
                  </div>
                </div>
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                <div className="flex items-center gap-1 text-sm text-gray-500">
                  <Calendar className="h-4 w-4" />
                  {format(new Date(order.created_at), 'dd MMM yyyy')}
                </div>
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                <select
                  value={order.status}
                  onChange={(e) => handleStatusChange(order.id, e.target.value as OrderStatus)}
                  className={`rounded-full px-3 py-1 text-xs font-semibold border ${getStatusColor(order.status)} 
                    focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent cursor-pointer`}
                >
                  {statusOptions.map((opt) => (
                    <option key={opt.value} value={opt.value}>{opt.label}</option>
                  ))}
                  {!statusOptions.find(opt => opt.value === order.status) && (
                    <option value={order.status}>{order.status.replace('_', ' ').toUpperCase()}</option>
                  )}
                </select>
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-right">
                <button
                  onClick={() => openDetails(order.id)}
                  className="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-blue-600 
                    bg-blue-50 rounded-lg hover:bg-blue-100 transition-colors border border-blue-200"
                >
                  <Eye className="h-4 w-4" />
                  Details
                </button>
              </td>
            </tr>
          ))}
          {orders.length === 0 && (
            <tr>
              <td colSpan={7} className="px-6 py-12 text-center">
                <div className="text-gray-500">
                  <p className="text-lg font-medium mb-2">No orders found</p>
                  <p className="text-sm">Orders will appear here once customers start placing them.</p>
                </div>
              </td>
            </tr>
          )}
        </tbody>
      </table>

      <OrderDetailsDialog
        orderId={selectedOrder}
        open={detailsOpen}
        onOpenChange={setDetailsOpen}
      />
    </div>
  );
}; 