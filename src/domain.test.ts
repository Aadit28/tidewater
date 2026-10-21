import { describe, expect, it } from 'vitest';
import { errorMessage, filterReports, matchingPods, reportSchema, taskActions } from './domain';
import type { Pod, Report, Task } from './domain';
const input = { title: 'Fishing line at the landing', description: 'A synthetic observation with enough detail to review.', category: 'Marine debris' as const, urgency: 'Medium' as const, place: 'North shore', lat: 31.4, lng: -81.2 };
const reports = [{ ...input, id: 'one' }, { ...input, id: 'two', title: 'Flooded path', category: 'Flooding' as const, place: 'Village trail' }] as Report[];
const tasks = [{ report_id: 'one', status: 'completed' }, { report_id: 'two', status: 'open' }] as Task[];
describe('report validation and discovery', () => {
  it('normalizes submitted text', () => expect(reportSchema.parse({ ...input, title: ` ${input.title} ` }).title).toBe(input.title));
  it.each([{ lat: NaN }, { lat: Infinity }, { lat: 90 }, { lng: -181 }, { title: '    ' }, { description: 'short' }, { place: '' }, { category: 'Other' }, { urgency: 'Emergency' }, { description: 'x'.repeat(1501) }])('rejects invalid submission %j', change => expect(reportSchema.safeParse({ ...input, ...change }).success).toBe(false));
  it('searches case-insensitively and combines category and task state', () => {
    expect(filterReports(reports, tasks, ' NORTH ', 'Marine debris', 'completed').map(r => r.id)).toEqual(['one']);
    expect(filterReports(reports, tasks, 'north', 'Flooding', 'All statuses')).toEqual([]);
    expect(filterReports(reports, tasks, 'trail', 'All categories', 'open').map(r => r.id)).toEqual(['two']);
  });
  it('has no forward transition from completion', () => {
    expect(taskActions('completed')).toEqual([]); expect(taskActions('open')).toEqual(['claim']); expect(taskActions('claimed')).toEqual(['start', 'release']); expect(taskActions('in_progress')).toEqual(['complete']);
  });
  it('only offers matching team capabilities', () => {
    const pods = [{ id: 'a', categories: ['Marine debris'] }, { id: 'b', categories: ['Flooding', 'Erosion'] }] as Pod[];
    expect(matchingPods(pods, 'Flooding').map(p => p.id)).toEqual(['b']);
  });
  it('provides useful provider errors without stringifying arbitrary objects', () => {
    expect(errorMessage({ message: 'Version conflict', code: 'P0001' })).toBe('Version conflict'); expect(errorMessage(new Error('Offline'))).toBe('Offline'); expect(errorMessage({ token: 'private' })).not.toContain('private');
  });
});
