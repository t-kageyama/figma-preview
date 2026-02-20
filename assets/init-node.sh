#!/usr/bin/env bash
#
# This script is used to initialize the node environment in the Docker container.
# @author Toru Kageyama
# date 2026-01-20
#
cd
echo "" | npm create vite@latest figma-preview -- --template react-ts --rolldown true
cd /home/node/figma-preview
npm install
npm i lucide-react
npm i -D tailwindcss @tailwindcss/postcss

mv src src.orig
mkdir src
cd src
mv /home/node/project.zip .
unzip project.zip
rm project.zip
cd ..
cp ./src.orig/main.tsx src
mv ~/postcss.config.js .
mv ~/tailwind.config.js .
mv ~/vite.config.ts .
mv ~/index.css src