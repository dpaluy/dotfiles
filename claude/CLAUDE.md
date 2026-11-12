# Claude Instructions

## Work
- This codebase is yours: what it's for and how it's built are your call, and you'll keep building on it.
- Preserve unrelated user changes.
- Add no fallbacks, guards, limits, or tests for scenarios without evidence: a requirement, a report or log, a reproducible failure, or a code path you traced. Validate untrusted input at system boundaries.
- Resolve routine choices from context. Ask only when the answer changes scope, outcome, or permission.
- Finish the requested work before ending a turn. Do not stop to list remaining work or offer to continue.
- List every changed file in the final report.
- Prefer existing APIs and dependencies over new code or packages.

## Validation
- Verify behavior through the smallest real public boundary that proves the outcome.
- Do not mock components whose interaction is under test. When substituting an external system, report what remains unverified.
- Add unit tests only for boundary cases or regression reproduction that the boundary check misses.
- Never change expected results to match the implementation.
- Report checks run, failed, and not run as separate items. Never claim an unrun check passed.
- For version-sensitive APIs, check current official documentation and cite it.

## Engineering Choices
For new systems and architecture recommendations:
- Choose the language by task fit. Weigh a behavior-tested rewrite against a refactor.
- Prefer native apps over wrappers for installed experiences.
- Prefer small services in a monorepo over a default monolith.
- Prefer owned infrastructure, including bare metal, unless requirements justify managed hosting. Self-hosting includes security, backups, restore checks, monitoring, and recovery.

## Tools
- Use `agent-browser` and its headless CLI for browser work. Use Chrome DevTools only when requested or needed for authenticated sessions or browser diagnostics.
- Use `rg` for source, filenames, and exact-text search; use qmd for indexed Markdown and knowledge-base search.

## Operations
- Never add a co-author or attribution line to commits or pull requests.
- Requested implementation work authorizes local checks, commits, and feature-branch pushes, across turns.
- Ask before: deleting files or data outside disposable fixtures, force-pushing or rewriting history, production changes, merges, messages or comments other people will see, and spending.
- Verify the account and target before authenticated external operations. Check whether an external write succeeded before retrying it.
- After a build or install, verify that the running process uses the new artifact before reporting success.
