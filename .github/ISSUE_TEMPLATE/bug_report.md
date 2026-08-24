---
name: Bug report
about: Something isn't working as expected
labels: bug
---

**Describe the bug**
A clear description of what's wrong.

**To reproduce**
Steps to reproduce the behavior.

**Expected behavior**
What you expected to happen instead.

**Environment**
- Deployment: Docker Compose / manual-Node / other
- Version: (from `/api/version`, or the git commit you're on)
- `NEXT_PUBLIC_PASSWORD_AUTH_ENABLED`, `STORAGE_DRIVER`, and any other
  non-default env vars relevant to the bug (**do not paste secrets**)

**Logs**
Relevant output from `docker compose logs web worker` (or your process
manager's logs). Redact anything sensitive.
