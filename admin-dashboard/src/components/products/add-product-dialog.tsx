import React, { useEffect } from 'react';
import { X } from 'lucide-react';
import { AddProductForm } from './add-product-form';

interface AddProductDialogProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export function AddProductDialog({ open, onClose, onSuccess }: AddProductDialogProps) {
  const handleSuccess = () => {
    onSuccess();
    onClose();
  };

  // Prevent body scroll when modal is open
  useEffect(() => {
    if (open) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = 'unset';
    }

    return () => {
      document.body.style.overflow = 'unset';
    };
  }, [open]);

  // Close on escape key
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };

    if (open) {
      document.addEventListener('keydown', handleEscape);
    }

    return () => {
      document.removeEventListener('keydown', handleEscape);
    };
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div 
        className="fixed inset-0 bg-black/60 backdrop-blur-sm transition-opacity duration-300 ease-out"
        onClick={onClose}
        aria-hidden="true"
      />
      
      {/* Modal Container */}
      <div className="relative z-50 w-full h-full flex items-center justify-center p-4 sm:p-6 lg:p-8">
        <div 
          className="relative bg-white rounded-2xl shadow-2xl max-w-7xl w-full max-h-[95vh] flex flex-col transform transition-all duration-300 ease-out scale-100"
          style={{ 
            animation: open ? 'modalSlideIn 0.3s ease-out' : 'modalSlideOut 0.2s ease-in'
          }}
        >
          {/* Close Button */}
          <button
            onClick={onClose}
            className="absolute top-6 right-6 z-10 p-2 rounded-full bg-white/90 hover:bg-white shadow-lg hover:shadow-xl transition-all duration-200 group border border-slate-200"
            aria-label="Close dialog"
          >
            <X className="w-5 h-5 text-slate-500 group-hover:text-slate-700 transition-colors" />
          </button>

          {/* Scrollable Content */}
          <div className="overflow-y-auto flex-1">
            <div className="p-6 sm:p-8 lg:p-10">
              <AddProductForm
                onSuccess={handleSuccess}
                onCancel={onClose}
              />
            </div>
          </div>
        </div>
      </div>

      <style jsx>{`
        @keyframes modalSlideIn {
          from {
            opacity: 0;
            transform: scale(0.95) translateY(-20px);
          }
          to {
            opacity: 1;
            transform: scale(1) translateY(0);
          }
        }

        @keyframes modalSlideOut {
          from {
            opacity: 1;
            transform: scale(1) translateY(0);
          }
          to {
            opacity: 0;
            transform: scale(0.95) translateY(-20px);
          }
        }
      `}</style>
    </div>
  );
} 