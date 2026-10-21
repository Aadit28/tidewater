import { createClient } from '@supabase/supabase-js';
import type { Activity, Pod, Report, ReportInput, Task, Workspace } from './domain';
const url = import.meta.env.VITE_SUPABASE_URL;
const key = import.meta.env.VITE_SUPABASE_ANON_KEY;
export const configured = Boolean(url && key);
const db = configured ? createClient(url, key, { auth: { storageKey: 'tidewater-neighborhood-auth' } }) : null;
function client() { if (!db) throw new Error('This deployment needs its Supabase project URL and public key. No changes were saved.'); return db; }
let opening: Promise<Workspace> | null = null;
export async function openWorkspace(): Promise<Workspace> {
  if (opening) return opening;
  opening = (async () => {
    const c = client();
    const session = await c.auth.getSession();
    if (session.error) throw session.error;
    if (!session.data.session) { const signed = await c.auth.signInAnonymously(); if (signed.error) throw signed.error; }
    const result = await c.rpc('tw26_bootstrap');
    if (result.error) throw result.error;
    return loadWorkspace();
  })();
  try { return await opening; } finally { opening = null; }
}
export async function loadWorkspace(): Promise<Workspace> {
  const c = client();
  const user = await c.auth.getUser();
  if (user.error || !user.data.user) throw new Error('Your session expired. Return home and reopen your workspace.');
  const results = await Promise.all([
    c.from('tw26_reports').select('*').order('created_at', { ascending: false }),
    c.from('tw26_pods').select('*').order('name'),
    c.from('tw26_tasks').select('*'),
    c.from('tw26_events').select('*').order('created_at', { ascending: false }).limit(100),
  ]);
  for (const r of results) if (r.error) throw r.error;
  return { reports: results[0].data as Report[], pods: results[1].data as Pod[], tasks: results[2].data as Task[], events: results[3].data as Activity[], userId: user.data.user.id };
}
export async function createReport(key: string, id: string, data: ReportInput, photoPath: string | null) {
  const { error } = await client().rpc('tw26_create_report', { p_key: key, p_id: id, p_payload: { ...data, photo_path: photoPath } });
  if (error) throw error;
}
export async function taskCommand(key: string, task: Task, action: string, note = '', pod: string | null = null) {
  const { error } = await client().rpc('tw26_task_command', { p_key: key, p_task: task.id, p_version: task.version, p_action: action, p_note: note, p_pod: pod });
  if (error) throw error;
}
export async function preparePhoto(file: File): Promise<Blob> {
  if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) throw new Error('Choose a JPG, PNG, or WebP image.');
  if (file.size > 5 * 1024 * 1024) throw new Error('Choose an image smaller than 5 MB.');
  const image = await createImageBitmap(file);
  try {
    if (image.width * image.height > 40_000_000) throw new Error('Choose an image smaller than 40 megapixels.');
    const scale = Math.min(1, 1600 / Math.max(image.width, image.height));
    const canvas = document.createElement('canvas'); canvas.width = Math.round(image.width * scale); canvas.height = Math.round(image.height * scale);
    const ctx = canvas.getContext('2d'); if (!ctx) throw new Error('Your browser cannot prepare this image.');
    ctx.fillStyle = '#fff'; ctx.fillRect(0, 0, canvas.width, canvas.height); ctx.drawImage(image, 0, 0, canvas.width, canvas.height);
    return await new Promise<Blob>((resolve, reject) => canvas.toBlob(b => b ? resolve(b) : reject(new Error('The image could not be prepared.')), 'image/jpeg', 0.85));
  } finally { image.close(); }
}
export async function uploadPhoto(id: string, photo: Blob, userId: string) {
  const path = `${userId}/${id}.jpg`;
  const uploaded = await client().storage.from('tw26-private-photos').upload(path, photo, { contentType: 'image/jpeg', upsert: false });
  if (uploaded.error) {
    // A lost response may follow a successful upload. Verify the same private path before retrying its report command.
    const existing = await client().storage.from('tw26-private-photos').download(path);
    if (existing.error) throw uploaded.error;
    if (existing.data.size !== photo.size || !await sameBytes(existing.data, photo)) throw new Error('An image already exists for this submission. Close and start a new report.');
  }
  return path;
}
async function sameBytes(a: Blob, b: Blob) {
  const [x, y] = await Promise.all([a.arrayBuffer(), b.arrayBuffer()]);
  const [hx, hy] = await Promise.all([crypto.subtle.digest('SHA-256', x), crypto.subtle.digest('SHA-256', y)]);
  return new Uint8Array(hx).every((n, i) => n === new Uint8Array(hy)[i]);
}
export async function photoUrl(path: string) {
  const result = await client().storage.from('tw26-private-photos').createSignedUrl(path, 60);
  if (result.error) throw result.error;
  return result.data.signedUrl;
}
