# Tidewater · Neighborhood edition

A fresh coastal reporting and volunteer-task prototype, started on October 20, 2026 for the October 16–23 Neighborhood Hacks build window.

## Provenance and disclosure

This is a new implementation. No application source, designs, sample records, or Git history are copied from the earlier Tidewater repository. The name and general coastal-reporting idea were discussed before this build. The team previously evaluated and deployed an existing Tidewater application; that older application is not this submission. This repository's own commits record development as it happens, without backdating.

OpenAI Codex assists with implementation, testing, and documentation. Open-source libraries and external services are credited below. AI is a development tool, not a photo-classification feature in this app. This statement describes provenance, not an organizer's eligibility decision.

## Scope

A personal, authenticated demonstration workspace: coastal hazard reports, an interactive map, sample volunteer teams, task claiming and completion, and an activity log. All initial records are synthetic. Teams represent a coordination prototype, not actual enrolled residents. Workspaces are isolated per visitor; cross-user collaboration is outside this first build.

## Development

Node.js 24 and npm. `npm ci`, `npm run dev`, `npm run typecheck`, `npm run lint`, `npm test`, `npm run build`. Browser and database verification instructions will be recorded in `docs/verification.md`.

Supabase environment configuration belongs in ignored `.env.local`. Only the project URL and public anonymous key enter the browser build. No service-role key is used by the application.

## Credits

React, TypeScript, Vite, Supabase, Leaflet, OpenStreetMap contributors, Lucide, Zod, Vitest, Playwright, ESLint, and Vercel. No external photographs are bundled.
