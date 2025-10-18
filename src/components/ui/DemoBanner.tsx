import { AlertCircle } from 'lucide-react';

/**
 * Demo Banner Component
 *
 * Displays a prominent banner when running in demo/sandbox mode
 * to clearly indicate to users they are in a demo environment.
 *
 * This component only renders when VITE_ENVIRONMENT === 'demo'
 */
export function DemoBanner() {
  const isDemoMode = import.meta.env.VITE_ENVIRONMENT === 'demo';
  const demoMessage = import.meta.env.VITE_DEMO_MESSAGE || 'Demo Environment - Sample Data Only';

  // Don't render in production or other environments
  if (!isDemoMode) {
    return null;
  }

  return (
    <div className="bg-gradient-to-r from-amber-500 to-orange-500 text-white py-2 px-4 shadow-md">
      <div className="container mx-auto flex items-center justify-center gap-2 text-sm font-medium">
        <AlertCircle className="h-4 w-4" />
        <span>{demoMessage}</span>
      </div>
    </div>
  );
}
