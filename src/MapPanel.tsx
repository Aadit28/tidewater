import { lazy, Suspense } from 'react';
import type { ComponentProps } from 'react';
import type CoastMap from './CoastMap';
const LazyMap = lazy(() => import('./CoastMap'));
export default function MapPanel(props: ComponentProps<typeof CoastMap>) {
  return <Suspense fallback={<div className="coast-map" aria-busy="true" aria-label="Loading map"/>}><LazyMap {...props}/></Suspense>;
}
