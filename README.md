# Tidewater

A fresh coastal reporting and volunteer-task prototype, started on October 20, 2026 for the October 16–23 Neighborhood Hacks build window.

**Live demo:** https://tidewater-neighborhood.vercel.app · **Public source:** https://github.com/Aadit28/tidewater-neighborhood

## Provenance and disclosure

This is a new implementation. No application source, designs, sample records, or Git history are copied from the earlier Tidewater repository. The name and general coastal-reporting idea were discussed before this build. The team previously evaluated and deployed an existing Tidewater application; that older application is not this submission. This repository's own commits record development as it happens, without backdating.

OpenAI Codex assists with implementation, testing, and documentation. Open-source libraries and external services are credited below. AI is a development tool, not a photo-classification feature in this app. This statement describes provenance, not an organizer's eligibility decision.

## Scope

A personal, authenticated demonstration workspace: coastal hazard reports, an interactive map, sample volunteer teams, task claiming and completion, and an activity log. All initial records are synthetic. Teams represent a coordination prototype, not actual enrolled residents. Workspaces are isolated per visitor; cross-user collaboration is outside this first build.

## Development

Node.js 24 and npm. `npm ci`, `npm run dev`, `npm run typecheck`, `npm run lint`, `npm test`, `npm run build`. Browser and database verification instructions will be recorded in `docs/verification.md`.

Supabase environment configuration belongs in ignored `.env.local`. Only the project URL and public anonymous key enter the browser build. No service-role key is used by the application.

For a new Supabase project, enable anonymous sign-ins, then apply `supabase/001_neighborhood.sql` once using an administrator connection. Copy `.env.example` to `.env.local` and set the two public values. Start the app with `npm run dev`. On this Windows workstation, `powershell -File scripts/run.ps1 dev` selects the bundled Node 24 runtime. Do not apply the migration to a database that already has these objects.

Guest authentication is saved in this browser. Clearing its site data can lose access; this prototype does not offer account recovery. Every guest gets isolated records. Submitted reports and images cannot be rewritten through the client. Task transitions use transactional database functions with optimistic versions, idempotency keys, and an audit/outbox commit. Outbox entries are demo-only and do not send notifications.

## Demo and verification

See [the new demo guide](docs/demo-guide.md) and [executed verification and limits](docs/verification.md). The older app's screenshots and scripts do not describe this implementation. Map tiles are supplied by OpenStreetMap; the homepage illustration is original SVG created during this build.

## Credits

React, TypeScript, Vite, Supabase, Leaflet, OpenStreetMap contributors, Lucide, Zod, Vitest, Playwright, ESLint, and Vercel. No external photographs are bundled.
