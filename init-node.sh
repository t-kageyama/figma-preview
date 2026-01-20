#!/usr/bin/env bash
cd
echo "" | npm create vite@latest figma-preview -- --template react-ts --rolldown true
cd /home/node/figma-preview
npm install
npm i lucide-react
npm i -D tailwindcss @tailwindcss/postcss

mv ./src ./src.orig
mv /home/node/figma-downloads src
cp ./src.orig/main.tsx src
mv ~/postcss.config.js .
mv ~/tailwind.config.js .
mv ~/vite.config.ts .
#mv ~/index.css ./src
#mv ~/App.tsx ./src/App.tsx
#mv ~/components ./src
#mv ~/styles ./src
