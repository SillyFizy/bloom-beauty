import React from 'react';
import { Customer } from '@/types/customer';
import { format } from 'date-fns';

interface CustomerTableProps {
  customers: Customer[];
}

export const CustomerTable: React.FC<CustomerTableProps> = ({ customers }) => {
  return (
    <div className="w-full overflow-x-auto">
      <table className="min-w-full divide-y divide-slate-200 text-sm">
        <thead className="bg-slate-50 text-slate-700">
          <tr>
            <th className="px-4 py-3 text-left font-semibold">#</th>
            <th className="px-4 py-3 text-left font-semibold">First Name</th>
            <th className="px-4 py-3 text-left font-semibold">Last Name</th>
            <th className="px-4 py-3 text-left font-semibold">Phone</th>
            <th className="px-4 py-3 text-left font-semibold">Email</th>
            <th className="px-4 py-3 text-center font-semibold">Orders</th>
            <th className="px-4 py-3 text-center font-semibold">Beauty Points</th>
            <th className="px-4 py-3 text-left font-semibold">Joined</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-100">
          {customers.map((customer, idx) => (
            <tr key={customer.id} className="hover:bg-slate-50">
              <td className="px-4 py-3 whitespace-nowrap">{idx + 1}</td>
              <td className="px-4 py-3 whitespace-nowrap font-medium text-slate-800">{customer.first_name}</td>
              <td className="px-4 py-3 whitespace-nowrap text-slate-700">{customer.last_name}</td>
              <td className="px-4 py-3 whitespace-nowrap text-slate-600">{customer.phone_number || '-'}</td>
              <td className="px-4 py-3 whitespace-nowrap text-slate-600">{customer.email || '-'}</td>
              <td className="px-4 py-3 text-center font-semibold text-slate-800">{customer.total_orders}</td>
              <td className="px-4 py-3 text-center font-semibold text-rose-600">{customer.total_beauty_points}</td>
              <td className="px-4 py-3 whitespace-nowrap text-slate-500">{format(new Date(customer.date_joined), 'dd MMM yyyy')}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}; 