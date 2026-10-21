# Fresh build · October 20, 2026

Owner: main Codex session. This repository is independent of the prior Tidewater implementation.

1. React/TypeScript/Vite application with original coastal visual design.
2. Supabase authenticated, visitor-isolated workspaces, immutable reports, sample teams, and versioned tasks. Private image storage. Transactional audit/outbox and idempotent commands.
3. Landing, overview, map, report form/detail, teams, tasks, and activity.
4. Type checks, lint, unit tests, database access/concurrency tests, browser flow tests, production build.
5. Public GitHub repository, separate Vercel deployment, truthful demo documentation.

Current status: initialized new repository; implementation starting. Shared Supabase infrastructure may be reused, with all new objects prefixed `tw26_`. Existing application tables and data remain untouched.
