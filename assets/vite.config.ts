import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from "@tailwindcss/vite"

// https://vite.dev/config/
export default defineConfig({
  //base: '/MY_APP_NAME/',
  plugins: [react()],
  //server: {
  //  allowedHosts: ['YOUR_HOST', 'YOUR_IP', 'localhost'],
  //}
})
