# Fresh build · October 20, 2026

Owner: main Codex session. This repository is independent of the prior Tidewater implementation.

1. React/TypeScript/Vite application with original coastal visual design.
2. Supabase authenticated, visitor-isolated workspaces, immutable reports, sample teams, and versioned tasks. Private image storage. Transactional audit/outbox and idempotent commands.
3. Landing, overview, map, report form/detail, teams, tasks, and activity.
4. Type checks, lint, unit tests, database access/concurrency tests, browser flow tests, production build.
5. Public GitHub repository, separate Vercel deployment, truthful demo documentation.

Current status: application and isolated Supabase schema implemented; local type checks, lint, 15 unit tests, and 6 browser tests passed. Public repository created at https://github.com/Aadit28/tidewater-neighborhood. Shared Supabase infrastructure is reused with all new objects prefixed `tw26_`; existing application tables and data remain untouched. Separate Vercel project created and its public frontend configuration set. Deployment and hosted verification are next.
