"use client";

import { ThemeProvider as NextThemesProvider } from "next-themes";

// next-themes renders an inline FOUC-prevention <script>. It must stay a real
// script on the server so it runs before paint. When React creates that element
// on the client it never executes, and React warns about it in dev; typing it as
// a data block there silences the warning. The server-rendered node is reused on
// hydration, so its attributes are left as-is.
const clientScriptType =
  typeof window === "undefined" ? undefined : "application/json";

export function ThemeProvider({
  children,
  ...props
}: React.ComponentProps<typeof NextThemesProvider>) {
  return (
    <NextThemesProvider {...props} scriptProps={{ type: clientScriptType }}>
      {children}
    </NextThemesProvider>
  );
}
