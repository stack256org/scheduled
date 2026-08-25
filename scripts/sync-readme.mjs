#!/usr/bin/env node
// Keeps README.md's quick-start block in step with package.json's `version`
// and the actual repo owner — the same values release.yml derives the git
// tag, GHCR image tags, and checkout ref from — so the two can never
// disagree. This is the drift that shipped a `ghcr.io/sahajtavethiya96/...`
// owner nobody publishes to across README/SELF-HOSTING/CHANGELOG/docs/compose
// files, none of which matched either git remote. Run bare to rewrite the
// generated block, `--check` to fail CI.

import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const readmePath = join(root, "README.md");

// Matches release.yml's checkout URLs and its `image_name: schduled` /
// `schduled-worker` matrix entries. Registries reject capitals, so this is
// lowercase throughout, same as release.yml lowercasing the repo owner.
const OWNER_REPO = "stack256org/scheduled";
const WEB_IMAGE = "ghcr.io/stack256org/schduled";
const WORKER_IMAGE = "ghcr.io/stack256org/schduled-worker";

const { version } = JSON.parse(
  readFileSync(join(root, "package.json"), "utf8")
);

// The same shape release.yml enforces before it will tag anything. Checking
// it here too means a malformed version is caught by a lint-speed local
// command rather than after CI has run the full build.
if (!/^\d+\.\d+\.\d+$/.test(version)) {
  console.error(`package.json version '${version}' is not X.Y.Z`);
  process.exit(1);
}

// release.yml only cuts a release once CHANGELOG.md carries a matching
// `## [<version>]` heading (its own "Require a changelog entry" gate). Using
// the same signal here means this script never advertises a version ladder
// for a version that hasn't actually been tagged and published yet.
const changelog = readFileSync(join(root, "CHANGELOG.md"), "utf8");
const isRelease = changelog
  .split("\n")
  .some((line) => line.startsWith(`## [${version}]`));

const major = version.split(".")[0];
const minor = version.split(".").slice(0, 2).join(".");

const quickStart = isRelease
  ? `\`\`\`bash
curl -O https://raw.githubusercontent.com/${OWNER_REPO}/main/docker-compose.yml
curl -o .env https://raw.githubusercontent.com/${OWNER_REPO}/main/.env.docker.example
# set APP_SECRET, APP_URL, and (recommended) INITIAL_ADMIN_EMAIL
IMAGE_TAG=${version} docker compose up -d
\`\`\`

This pulls prebuilt, published images (multi-arch: Intel + ARM) rather than
building on your server. Pin a version in production, because \`latest\`
moves with every release — available tags are \`latest\`, the \`${major}\` /
\`${minor}\` / \`${version}\` ladder, \`main\` (rebuilt on every change, expect
rough edges), and a fixed \`sha-<short>\` per build:

\`\`\`bash
docker pull ${WEB_IMAGE}:${version}
docker pull ${WORKER_IMAGE}:${version}
\`\`\``
  : `\`\`\`bash
curl -O https://raw.githubusercontent.com/${OWNER_REPO}/main/docker-compose.yml
curl -o .env https://raw.githubusercontent.com/${OWNER_REPO}/main/.env.docker.example
# set APP_SECRET, APP_URL, and (recommended) INITIAL_ADMIN_EMAIL
docker compose up -d
\`\`\`

This pulls a prebuilt, published image (multi-arch: Intel + ARM) rather than
building on your server. **This repo hasn't cut its first tagged release
yet**, so until it has, run with \`IMAGE_TAG=main docker compose up -d\`
instead — see the comment at the top of \`docker-compose.yml\`.`;

/** One entry per generated region: key = the name in the marker comment,
 * value = the exact text between the markers. Edit the prose HERE — anything
 * typed into README.md between the markers is what gets overwritten. */
const blocks = {
  "quick-start": quickStart,
};

const original = readFileSync(readmePath, "utf8");
let updated = original;

for (const [name, body] of Object.entries(blocks)) {
  const begin = `<!-- BEGIN GENERATED: ${name} -->`;
  const end = `<!-- END GENERATED: ${name} -->`;

  // A missing marker means someone deleted it while editing the prose around
  // it. Failing loudly beats silently generating nothing and reporting
  // success, which would let the drift this script exists to prevent come
  // straight back.
  if (!original.includes(begin) || !original.includes(end)) {
    console.error(`README.md is missing the ${begin} / ${end} markers.`);
    process.exit(1);
  }

  // Non-greedy, and anchored on the literal markers, so a second generated
  // block later in the file cannot be swallowed by this one's replacement.
  const region = new RegExp(
    `${escapeRegExp(begin)}[\\s\\S]*?${escapeRegExp(end)}`
  );
  updated = updated.replace(region, `${begin}\n${body}\n${end}`);
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

const checkOnly = process.argv.includes("--check");

if (updated === original) {
  console.log(`README.md is in step with package.json (${version}).`);
  process.exit(0);
}

if (checkOnly) {
  console.error(
    `::error file=README.md::README.md is out of date for version ${version}. Run 'pnpm docs:sync' and commit the result.`
  );
  process.exit(1);
}

writeFileSync(readmePath, updated);
console.log(`README.md updated for version ${version}.`);
