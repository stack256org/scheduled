/**
 * Single source of truth for password strength rules, enforced both
 * client-side (instant feedback) and server-side (lib/auth.ts hook — the
 * client check alone can't be trusted).
 */

import { MAX_PASSWORD_LENGTH, MIN_PASSWORD_LENGTH } from "@/config/platform";

const UPPERCASE_RE = /[A-Z]/;
const LOWERCASE_RE = /[a-z]/;
const SPECIAL_CHAR_RE = /[^A-Za-z0-9]/;

export function passwordComplexityError(password: string): string | null {
  if (password.length < MIN_PASSWORD_LENGTH) {
    return `Password must be at least ${MIN_PASSWORD_LENGTH} characters.`;
  }
  if (password.length > MAX_PASSWORD_LENGTH) {
    return `Password must be at most ${MAX_PASSWORD_LENGTH} characters.`;
  }
  if (!UPPERCASE_RE.test(password)) {
    return "Password must contain at least one uppercase letter.";
  }
  if (!LOWERCASE_RE.test(password)) {
    return "Password must contain at least one lowercase letter.";
  }
  if (!SPECIAL_CHAR_RE.test(password)) {
    return "Password must contain at least one special character.";
  }
  return null;
}
