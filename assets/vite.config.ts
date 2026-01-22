import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

function normalizeBase(v: string | undefined, def: string) {
  const b = (v && v.trim()) ? v.trim() : def;
  if (b === "/") return "/";
  const withSlash = b.startsWith("/") ? b : `/${b}`;
  return withSlash.endsWith("/") ? withSlash : `${withSlash}/`;
}

function parseCsv(v: string | undefined): string[] {
  return (v ?? "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
}

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), "");

  const base = normalizeBase(env.VITE_BASE, "/");

  const defaultAllowed = ["localhost"];
  const allowedHosts = parseCsv(env.VITE_ALLOWED_HOSTS);
  const finalAllowedHosts = allowedHosts.length ? allowedHosts : defaultAllowed;

  return {
    base,
    plugins: [react()],
    server: {
      allowedHosts: finalAllowedHosts,
    },
  };
});