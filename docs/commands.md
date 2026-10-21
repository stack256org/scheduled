# Commands

```bash
pnpm install
cp .env.example .env
pnpm db:local
pnpm db:migrate
pnpm dev
```

Promote an account to admin after the first magic-link sign-in:

```bash
pnpm make:admin you@example.com
```

Useful commands:

```bash
pnpm dev:next
pnpm worker
pnpm typecheck
pnpm lint
pnpm db:generate
pnpm db:push
pnpm db:reset
```

Build the Docker image (web, worker and migrate are one image):

```bash
docker build -t schduled .
```
