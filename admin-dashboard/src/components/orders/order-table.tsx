import React from 'react';
import { Order, OrderStatus } from '@/types/order';
import { useUpdateOrderStatus } from '@/hooks/use-orders';
import { format } from 'date-fns';
import { Select } from '@/components/ui/select';

interface OrderTableProps {
  orders: Order[];
}

const statusOptions: OrderStatus[] = [
  'pending',
  'confirmed',
  'processing',
  'packed',
  'shipped',
  'delivered',
  'cancelled',
  'returned',
];

export const OrderTable: React.FC<OrderTableProps> = ({ orders }) => {
  const updateMutation = useUpdateOrderStatus();

  const handleStatusChange = (orderId: number, status: OrderStatus) => {
    updateMutation.mutate({ orderId, status });
  };

  return (
    <div className="w-full overflow-x-auto">
      <table className="min-w-full divide-y divide-slate-200 text-sm">
        <thead className="bg-slate-50 text-slate-700">
          <tr>
            <th className="px-4 py-3 text-left font-semibold">Order #</th>
            <th className="px-4 py-3 text-left font-semibold">Customer</th>
            <th className="px-4 py-3 text-left font-semibold">Total</th>
            <th className="px-4 py-3 text-left font-semibold">Date</th>
            <th className="px-4 py-3 text-left font-semibold">Status</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-100">
          {orders.map((order) => (
            <tr key={order.id} className="hover:bg-slate-50">
              <td className="px-4 py-3 whitespace-nowrap font-medium text-slate-800">{order.id}</td>
              <td className="px-4 py-3 whitespace-nowrap text-slate-700">{order.customer_name}</td>
              <td className="px-4 py-3 whitespace-nowrap text-slate-600">${order.total_amount.toFixed(2)}</td>
              <td className="px-4 py-3 whitespace-nowrap text-slate-500">{format(new Date(order.created_at), 'dd MMM yyyy')}</td>
              <td className="px-4 py-3 whitespace-nowrap">
                <select
                  value={order.status}
                  onChange={(e) => handleStatusChange(order.id, e.target.value as OrderStatus)}
                  className="border border-slate-300 rounded-md px-2 py-1 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  {statusOptions.map((status) => (
                    <option key={status} value={status}>
                      {status.replace('_', ' ').toUpperCase()}
                    </option>
                  ))}
                </select>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}; 