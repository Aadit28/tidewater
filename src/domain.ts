import { z } from 'zod';
export const categories = ['Marine debris', 'Flooding', 'Erosion', 'Access hazard'] as const;
export const statuses = ['open', 'claimed', 'in_progress', 'completed'] as const;
export type Category = typeof categories[number];
export type Status = typeof statuses[number];
export const reportSchema = z.object({
  title: z.string().trim().min(5, 'Use at least 5 characters for the title.').max(100),
  description: z.string().trim().min(15, 'Add at least 15 characters of detail.').max(1500),
  category: z.enum(categories), urgency: z.enum(['Low', 'Medium', 'High']),
  place: z.string().trim().min(3, 'Add a location name.').max(100),
  lat: z.number().finite().min(-85).max(85), lng: z.number().finite().min(-180).max(180),
});
export type ReportInput = z.infer<typeof reportSchema>;
export type Report = ReportInput & { id: string; workspace_id: string; photo_path: string | null; sample: boolean; created_at: string };
export type Pod = { id: string; name: string; focus: string; members: number; equipment: string[]; categories: Category[]; sample: boolean };
export type Task = { id: string; report_id: string; pod_id: string | null; status: Status; assignee_id: string | null; version: number; completion_note: string | null; updated_at: string };
export type Activity = { id: string; kind: string; message: string; report_id: string | null; created_at: string };
export type Workspace = { reports: Report[]; pods: Pod[]; tasks: Task[]; events: Activity[]; userId: string };
export function statusLabel(status: Status) { return { open: 'Open', claimed: 'Claimed', in_progress: 'In progress', completed: 'Completed' }[status]; }
export function taskActions(status: Status): string[] { return { open: ['claim'], claimed: ['start', 'release'], in_progress: ['complete'], completed: [] }[status]; }
export function matchingPods(pods: Pod[], category: Category) { return pods.filter(p => p.categories.includes(category)); }
export function filterReports(reports: Report[], tasks: Task[], query: string, category: string, status: string) {
  const needle = query.trim().toLowerCase();
  const byReport = new Map(tasks.map(t => [t.report_id, t]));
  return reports.filter(r => (!needle || `${r.title} ${r.place} ${r.description}`.toLowerCase().includes(needle)) && (category === 'All categories' || r.category === category) && (status === 'All statuses' || byReport.get(r.id)?.status === status));
}
export function errorMessage(error: unknown) {
  if (error instanceof Error) return error.message;
  if (error && typeof error === 'object' && 'message' in error && typeof error.message === 'string') return error.message;
  return 'Something went wrong. Please try again.';
}
export function formatDate(value: string) { return new Intl.DateTimeFormat('en', { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' }).format(new Date(value)); }
