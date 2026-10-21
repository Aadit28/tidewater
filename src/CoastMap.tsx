import { useEffect, useRef } from 'react';
import L from 'leaflet';
import type { Report, Task } from './domain';
import 'leaflet/dist/leaflet.css';
type Props = { reports?: Report[]; tasks?: Task[]; onSelect?: (report: Report) => void; pick?: { lat: number; lng: number }; onPick?: (lat: number, lng: number) => void };
const emptyReports: Report[] = [];
const emptyTasks: Task[] = [];
export default function CoastMap({ reports = emptyReports, tasks = emptyTasks, onSelect, pick, onPick }: Props) {
  const container = useRef<HTMLDivElement>(null);
  const callbacks = useRef({ onSelect, onPick });
  useEffect(() => { callbacks.current = { onSelect, onPick }; }, [onSelect, onPick]);
  useEffect(() => {
    if (!container.current) return;
    // This view is replaced when filters or locations change. Avoid a pending
    // CSS zoom callback targeting a removed map pane during navigation.
    const map = L.map(container.current, { scrollWheelZoom: false, zoomAnimation: false, fadeAnimation: false, markerZoomAnimation: false }).setView([31.417, -81.271], 13);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19, attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors' }).addTo(map);
    const bounds: L.LatLngExpression[] = [];
    for (const report of reports) {
      const complete = tasks.find(t => t.report_id === report.id)?.status === 'completed';
      const className = complete ? 'complete' : report.urgency.toLowerCase();
      const marker = L.marker([report.lat, report.lng], { icon: L.divIcon({ className: `coast-marker ${className}`, html: '<span></span>', iconSize: [26, 26], iconAnchor: [13, 13] }), keyboard: true, title: report.title });
      const label = document.createElement('span'); label.textContent = report.title;
      marker.bindTooltip(label).on('click', () => callbacks.current.onSelect?.(report)).addTo(map);
      bounds.push([report.lat, report.lng]);
    }
    if (pick) {
      L.marker([pick.lat, pick.lng], { icon: L.divIcon({ className: 'coast-marker picked', html: '<span></span>', iconSize: [30, 30], iconAnchor: [15, 15] }) }).addTo(map);
      map.setView([pick.lat, pick.lng], 13);
    } else if (bounds.length) map.fitBounds(L.latLngBounds(bounds), { padding: [42, 42], maxZoom: 14 });
    if (onPick) map.on('click', (event: L.LeafletMouseEvent) => callbacks.current.onPick?.(Number(event.latlng.lat.toFixed(5)), Number(event.latlng.lng.toFixed(5))));
    const observer = new ResizeObserver(() => map.invalidateSize()); observer.observe(container.current);
    return () => { observer.disconnect(); map.stop(); map.remove(); };
  }, [reports, tasks, pick, onPick]);
  return <div className="coast-map" ref={container} role="region" aria-label={onPick ? 'Choose report location on the map, or enter coordinates below' : 'Interactive coastal report map'} />;
}
