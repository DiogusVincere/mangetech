import { fileURLToPath } from 'node:url'

// Caminho absoluto da config: funciona mesmo rodando o Vite de outra pasta.
export default {
  plugins: {
    tailwindcss: { config: fileURLToPath(new URL('./tailwind.config.js', import.meta.url)) },
    autoprefixer: {},
  },
}
