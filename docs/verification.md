# Verification · fresh implementation

Executed October 20, 2026 America/Los_Angeles (October 21 UTC), using bundled Node.js 24.19.0 and npm 10.2.4. This record applies only to this repository, not the older Tidewater app.

| Check | Executed result |
| --- | --- |
| TypeScript (`npm run typecheck`, also in build) | Passed |
| ESLint (`npm run lint`) | Passed, no diagnostics |
| Vitest (`npm test`) | 15 passed |
| Real hosted Supabase tests (`npm run test:database`) | 31 checks passed |
| Chromium browser suite on localhost (`npm run test:browser`) | 6 passed in 14.8 seconds |
| Production build (`npm run build`) | Passed; map library is loaded separately |
| npm install audit | 0 reported vulnerabilities at installation |

Database tests use two newly created guest identities, without a service-role key. They check workspace isolation, private image read/sign/write denials, no public photo access, immutable reports, direct table mutation denials, server-side validation, category matching, sequential task transitions, completion notes, optimistic conflicts, idempotent concurrent retries, and audit event counts. Synthetic QA workspaces are retained; no existing data is deleted. The outbox and idempotency tables are inaccessible to client roles.

Browser tests use the real Supabase backend. They cover guest entry, sample labeling, an actual file upload and image retrieval, report submission, team assignment, claim/start/complete, persistence after reload, combined filters, map pin details, team details, activity entries, mobile navigation and overflow, keyboard dialog focus/Escape, and a simulated authentication outage that fails closed.

The first browser run had a test selector with the wrong letter case for a sample-team label: 3 passed, 1 failed, 2 skipped. The selector was corrected; the complete rerun passed all 6. Initial package installation used the workstation's older npm-associated Node and emitted engine warnings; all application builds, checks, browser tests, and database scripts ran under Node 24. The Windows helper selects that runtime explicitly.

## Limits

Only Chromium was exercised. The mobile check is browser emulation, not a physical phone. No full accessibility audit or load test was executed. Guest identities have no email recovery: clearing browser storage can lose access. Initial records, team membership counts, and gear are synthetic. There is no cross-user collaboration, automatic classification, dispatch, notifications, or independent verification of completed tasks. Photo metadata is removed by the browser's canvas preparation; there is no automatic face redaction. Storage access rules and tests are useful controls, not a security certification. Failed submissions after upload may leave a private orphaned image; automatic retention cleanup is not implemented. External map tiles depend on OpenStreetMap availability. Existing Supabase infrastructure is reused, but application data lives in new `tw26_*` objects.

## Running checks

Use Node.js 24. On this Windows workstation: `powershell -File scripts/run.ps1 typecheck` (replace the last argument with `lint`, `test`, `build`, or `test:database`). For browser tests, run the dev server on port 5177, install Chromium headless shell with `npx playwright install chromium-headless-shell`, then run `npm run test:browser`. Set `PLAYWRIGHT_BASE_URL` to test a deployed URL instead.

## Production deployment and hosted verification

Live: https://tidewater-neighborhood.vercel.app

Public repository: https://github.com/Aadit28/tidewater-neighborhood (anonymous GitHub API read confirmed HTTP 200 and `private: false`). GitHub creation time is October 21, 2026 UTC, which is October 20 in the team's America/Los_Angeles timezone. All commits in this fresh repository use actual development timestamps.

Vercel production deployment `dpl_DbARG6sj2LVYcYTxzvqUVgiArMzp` reached READY and was aliased to the live URL. Its commit metadata identifies `7025b8838a768443edddd007d48973d67a11a9c9`. This final verification note is a subsequent documentation-only commit; deployed application source is unchanged.

The complete Chromium browser suite was executed again against the public production URL: **6 passed in 12.7 seconds**, including actual image upload/retrieval, report/task persistence, team assignment, progress/completion, filters, map, activity, mobile viewport, and the authentication-outage test. Synthetic QA records remain in their test visitor's isolated workspace.

The Vercel GitHub connection attempt was rejected with an account/repository-access error. Automatic deployments on pushes are not connected. The CLI production deployment succeeded independently. Future deployments can use `vercel --prod --scope flc-india`, or the owner can authorize the correct GitHub account in Vercel. No extra access was granted.
