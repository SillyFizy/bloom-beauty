"use client";

import React from "react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { SameGovernorateCard } from "@/components/shipping/same-governorate-card";
import { ShippingZonesTable } from "@/components/shipping/shipping-zones-table";
import { useShippingSettings } from "@/hooks/use-shipping";
import { AlertCircle, Loader2, Truck } from "lucide-react";

export default function ShippingPage() {
  const { data: shippingSettings, isLoading, error } = useShippingSettings();

  // Get all used governorate IDs to prevent duplicates - MOVED BEFORE CONDITIONAL RETURN
  const usedGovernorateIds = React.useMemo(() => {
    if (!shippingSettings) return [];
    
    const ids: string[] = [];
    
    if (shippingSettings.same_governorate) {
      ids.push(shippingSettings.same_governorate.governorate.id);
    }
    
    shippingSettings.nearby_governorates.forEach(zone => {
      ids.push(zone.governorate.id);
    });
    
    shippingSettings.other_governorates.forEach(zone => {
      ids.push(zone.governorate.id);
    });
    
    return ids;
  }, [shippingSettings]);

  // Handle error state
  if (error) {
    return (
      <DashboardLayout title="Shipping Management">
        <div className="flex flex-1 items-center justify-center">
          <div className="text-center space-y-4 max-w-md">
            <AlertCircle className="mx-auto h-12 w-12 text-red-600" />
            <h2 className="text-lg font-semibold text-gray-900">Error Loading Shipping Settings</h2>
            <p className="text-gray-600">
              Failed to load shipping settings. Please try again later.
            </p>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout title="Shipping Management">
      <div className="space-y-8">
        {/* Header Section */}
        <div className="flex items-center space-x-3 bg-gradient-to-r from-blue-50 to-purple-50 p-6 rounded-lg border">
          <div className="p-2 bg-blue-600 rounded-lg">
            <Truck className="h-6 w-6 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Shipping Management</h1>
            <p className="text-gray-600">
              Configure shipping rates for different governorates across Iraq
            </p>
          </div>
        </div>

        {/* Loading State */}
        {isLoading && (
          <div className="flex items-center justify-center py-12">
            <div className="flex items-center space-x-3">
              <Loader2 className="h-6 w-6 animate-spin text-blue-600" />
              <span className="text-gray-600">Loading shipping settings...</span>
            </div>
          </div>
        )}

        {/* Shipping Configuration */}
        {!isLoading && !error && (
          <div className="space-y-8">
            {/* Same Governorate Section */}
            <section>
              <div className="mb-6">
                <h2 className="text-xl font-semibold text-gray-900 mb-2">
                  Primary Shipping Zone
                </h2>
                <p className="text-gray-600">
                  Set your main business governorate with standard shipping rates. 
                  Only one governorate can be selected as the primary zone.
                </p>
              </div>
              
              <SameGovernorateCard
                sameGovernorate={shippingSettings?.same_governorate}
                isLoading={isLoading}
                usedGovernorateIds={usedGovernorateIds}
              />
            </section>

            {/* Nearby Governorates Section */}
            <section>
              <div className="mb-6">
                <h2 className="text-xl font-semibold text-gray-900 mb-2">
                  Nearby Governorates
                </h2>
                <p className="text-gray-600">
                  Configure shipping rates for governorates close to your primary location. 
                  These typically have moderate shipping costs.
                </p>
              </div>
              
              <ShippingZonesTable
                zones={shippingSettings?.nearby_governorates || []}
                type="nearby"
                isLoading={isLoading}
                usedGovernorateIds={usedGovernorateIds}
              />
            </section>

            {/* Other Governorates Section */}
            <section>
              <div className="mb-6">
                <h2 className="text-xl font-semibold text-gray-900 mb-2">
                  Other Governorates
                </h2>
                <p className="text-gray-600">
                  Set shipping rates for distant governorates. These typically have 
                  higher shipping costs due to increased distance and logistics complexity.
                </p>
              </div>
              
              <ShippingZonesTable
                zones={shippingSettings?.other_governorates || []}
                type="other"
                isLoading={isLoading}
                usedGovernorateIds={usedGovernorateIds}
              />
            </section>
          </div>
        )}

        {/* Information Panel */}
        {!isLoading && !error && (
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <div className="flex items-start space-x-3">
              <AlertCircle className="h-5 w-5 text-blue-600 flex-shrink-0 mt-0.5" />
              <div>
                <h3 className="font-medium text-blue-900 mb-2">Shipping Configuration Tips</h3>
                <div className="text-sm text-blue-800">
                  <ul className="list-disc list-inside space-y-1">
                    <li>Set your business location as the "Same Governorate" for lowest shipping rates</li>
                    <li>Group nearby governorates with similar logistics costs in "Nearby Governorates"</li>
                    <li>All other distant locations should be in "Other Governorates"</li>
                    <li>Each governorate can only be assigned to one shipping category</li>
                    <li>Prices are in Iraqi Dinar (IQD) and should reflect actual shipping costs</li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
} 