'use client';

import React, { useState } from 'react';
import Image from 'next/image';
import { Plus, Sun, Moon, Package, Edit, Trash2 } from 'lucide-react';

import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';

import {
  useMorningRoutine,
  useEveningRoutine,
  useDeleteMorningRoutineItem,
  useDeleteEveningRoutineItem,
} from '@/hooks/use-celebrities';

import { AddRoutineDialog } from './add-routine-dialog';
import { EditRoutineDialog } from './edit-routine-dialog';
import {
  CelebrityMorningRoutineItem,
  CelebrityEveningRoutineItem,
} from '@/types/celebrity';
import { apiClient } from '@/lib/api';

interface RoutineManagerProps {
  celebrityId: number;
  celebrityName?: string;
}

export const RoutineManager: React.FC<RoutineManagerProps> = ({ celebrityId, celebrityName = '' }) => {
  const { data: morning } = useMorningRoutine(celebrityId);
  const { data: evening } = useEveningRoutine(celebrityId);

  const deleteMorning = useDeleteMorningRoutineItem();
  const deleteEvening = useDeleteEveningRoutineItem();

  const [activeTab, setActiveTab] = useState<'morning' | 'evening'>('morning');
  const [showAdd, setShowAdd] = useState(false);
  const [dialogType, setDialogType] = useState<'morning' | 'evening'>('morning');
  const [editing, setEditing] = useState<
    CelebrityMorningRoutineItem | CelebrityEveningRoutineItem | null
  >(null);
  const [showEdit, setShowEdit] = useState(false);

  const handleAdd = (type: 'morning' | 'evening') => {
    setDialogType(type);
    setShowAdd(true);
  };

  const handleEdit = (
    item: CelebrityMorningRoutineItem | CelebrityEveningRoutineItem,
    type: 'morning' | 'evening'
  ) => {
    setEditing(item);
    setDialogType(type);
    setShowEdit(true);
  };

  const handleDelete = async (
    item: CelebrityMorningRoutineItem | CelebrityEveningRoutineItem,
    type: 'morning' | 'evening'
  ) => {
    if (!confirm('Remove this step?')) return;
    if (type === 'morning') {
      await deleteMorning.mutateAsync({ itemId: item.id, celebrityId });
    } else {
      await deleteEvening.mutateAsync({ itemId: item.id, celebrityId });
    }
  };

  const renderItems = (
    items: (CelebrityMorningRoutineItem | CelebrityEveningRoutineItem)[],
    type: 'morning' | 'evening'
  ) =>
    items.map((item) => (
      <div key={item.id} className="flex items-center gap-4 p-4 border rounded-lg">
        <div
          className={`flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
            type === 'morning' ? 'bg-orange-600 text-white' : 'bg-blue-600 text-white'
          }`}
        >
          {item.order}
        </div>
        <div className="relative w-12 h-12 rounded-lg overflow-hidden bg-muted">
          {item.product.featured_image ? (
            <Image
              src={apiClient.getMediaUrl(item.product.featured_image)}
              alt={item.product.name}
              fill
              className="object-cover"
            />
          ) : (
            <div className="w-full h-full bg-gradient-to-br from-muted to-muted/50 flex items-center justify-center">
              <Package className="h-5 w-5 text-muted-foreground" />
            </div>
          )}
        </div>
        <div className="flex-1">
          <h4 className="font-medium text-foreground">{item.product.name}</h4>
          {item.product.brand && (
            <p className="text-sm text-muted-foreground">by {item.product.brand.name}</p>
          )}
          {item.description && (
            <p className="text-sm text-muted-foreground mt-1 line-clamp-2">{item.description}</p>
          )}
        </div>
        <div className="flex items-center gap-1">
          <Button variant="ghost" size="sm" onClick={() => handleEdit(item, type)}>
            <Edit className="h-4 w-4" />
          </Button>
          <Button
            variant="ghost"
            size="sm"
            className="text-destructive"
            onClick={() => handleDelete(item, type)}
          >
            <Trash2 className="h-4 w-4" />
          </Button>
        </div>
      </div>
    ));

  return (
    <div className="space-y-6">
      <Tabs value={activeTab} onValueChange={(val) => setActiveTab(val as 'morning' | 'evening')}>
        <TabsList className="grid w-full grid-cols-2 mb-4">
          <TabsTrigger value="morning" className="flex items-center gap-2">
            <Sun className="h-4 w-4" /> Morning
          </TabsTrigger>
          <TabsTrigger value="evening" className="flex items-center gap-2">
            <Moon className="h-4 w-4" /> Evening
          </TabsTrigger>
        </TabsList>

        {/* Morning */}
        <TabsContent value="morning" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center justify-between">
                <span className="flex items-center gap-2">
                  <Sun className="h-5 w-5" /> Morning Routine ({morning?.morning_routine.length ?? 0})
                </span>
                <Button size="sm" onClick={() => handleAdd('morning')}>
                  <Plus className="h-4 w-4 mr-1" /> Add Step
                </Button>
              </CardTitle>
            </CardHeader>
            <CardContent>
              {morning?.morning_routine?.length ? (
                <div className="space-y-4">{renderItems(morning.morning_routine, 'morning')}</div>
              ) : (
                <div className="text-sm text-muted-foreground text-center py-4">No morning steps yet.</div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* Evening */}
        <TabsContent value="evening" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center justify-between">
                <span className="flex items-center gap-2">
                  <Moon className="h-5 w-5" /> Evening Routine ({evening?.evening_routine.length ?? 0})
                </span>
                <Button size="sm" onClick={() => handleAdd('evening')}>
                  <Plus className="h-4 w-4 mr-1" /> Add Step
                </Button>
              </CardTitle>
            </CardHeader>
            <CardContent>
              {evening?.evening_routine?.length ? (
                <div className="space-y-4">{renderItems(evening.evening_routine, 'evening')}</div>
              ) : (
                <div className="text-sm text-muted-foreground text-center py-4">No evening steps yet.</div>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* dialogs */}
      <AddRoutineDialog
        open={showAdd}
        onOpenChange={setShowAdd}
        celebrityId={celebrityId}
        celebrityName={celebrityName}
        routineType={dialogType}
      />

      {editing && (
        <EditRoutineDialog
          open={showEdit}
          onOpenChange={(open) => {
            setShowEdit(open);
            if (!open) setEditing(null);
          }}
          routineItem={editing}
          routineType={dialogType}
        />
      )}
    </div>
  );
}; 