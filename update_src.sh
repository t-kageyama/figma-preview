#!/usr/bin/env bash
#
# src directory update script.
# date: 2026-02-20
# author: Toru Kageyama
#
set -euo pipefail

WORKDIR="${1:-.}"
COMPOSE_FILE="$WORKDIR/docker-compose.yml"
ZIP_PATH="$WORKDIR/project.zip"

if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo "Not found: $COMPOSE_FILE"
  exit 1
fi
if [[ ! -f "$ZIP_PATH" ]]; then
  echo "Not found: $ZIP_PATH"
  exit 1
fi

TARGET=$(cd "$(dirname "$COMPOSE_FILE")" && pwd)/$(basename "$COMPOSE_FILE")

# ---- find candidate containers that belong to TARGET compose file
mapfile -t CAND < <(
  docker ps -a --format '{{.ID}}\t{{.Names}}' |
  while IFS=$'\t' read -r id name; do
    cfg=$(docker inspect "$id" --format '{{ index .Config.Labels "com.docker.compose.project.config_files" }}' 2>/dev/null || true)
    [[ -z "$cfg" ]] && continue
    if echo "$cfg" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -Fxq "$TARGET"; then
      proj=$(docker inspect "$id" --format '{{ index .Config.Labels "com.docker.compose.project" }}' 2>/dev/null || true)
      svc=$(docker inspect "$id" --format '{{ index .Config.Labels "com.docker.compose.service" }}' 2>/dev/null || true)
      state=$(docker inspect "$id" --format '{{.State.Status}}' 2>/dev/null || true)
      echo -e "${id}\t${name}\t${svc}\t${proj}\t${state}"
    fi
  done
)

if [[ ${#CAND[@]} -eq 0 ]]; then
  echo "No containers found for compose file:"
  echo "  $TARGET"
  exit 2
fi

echo "Compose file:"
echo "  $TARGET"
echo

i=1
for line in "${CAND[@]}"; do
  IFS=$'\t' read -r id name svc proj state <<<"$line"
  printf "  [%d] %s (service=%s project=%s state=%s)\n" "$i" "$name" "$svc" "$proj" "$state"
  i=$((i+1))
done

if [[ ${#CAND[@]} -eq 1 ]]; then
  pick=1
else
  read -r -p "Which container? (1-${#CAND[@]}): " pick
fi

if ! [[ "$pick" =~ ^[0-9]+$ ]] || (( pick < 1 || pick > ${#CAND[@]} )); then
  echo "Invalid selection."
  exit 3
fi

IFS=$'\t' read -r id name svc proj state <<<"${CAND[$((pick-1))]}"

if [[ "$state" != "running" ]]; then
  echo "Selected container is not running: $name (state=$state)"
  exit 4
fi

ZIP_IN_CONTAINER="/tmp/project.zip"
WORK="/tmp/figma_unpack.$$"
SRC_DIR="/home/node/figma-preview/src"
DATE_STR=`date "+%Y%m%d%H%M%S"`

echo
echo "Target container: $name (service=$svc)"
echo "Upload: $ZIP_PATH -> $ZIP_IN_CONTAINER"
docker cp "$ZIP_PATH" "$name:$ZIP_IN_CONTAINER"

echo "Swap src: $SRC_DIR"
docker exec -u root -it "$name" sh -lc "
  set -e
  command -v unzip >/dev/null 2>&1 || (echo 'unzip not found in container' && exit 10)
  test -d '$SRC_DIR' || (echo 'src dir not found: $SRC_DIR' && exit 11)

  rm -rf '$WORK'
  mkdir -p '$WORK/unz/src'
  # project zip does not contains src directory in it's top level.
  unzip -q '$ZIP_IN_CONTAINER' -d '$WORK/unz/src'

  NEW_SRC='$WORK/unz/src'
  [ -n \"\$NEW_SRC\" ] || (echo 'src directory not found in zip' && exit 12)

  rm -rf '$WORK/src.new'
  mkdir -p '$WORK/src.new'
  cp -a \"\$NEW_SRC\"/. '$WORK/src.new'/ 2>/dev/null || true

  # Carry over from the old src/ if necessary.
  for f in index.css main.tsx; do
    if [ -f '$SRC_DIR/'\"\$f\" ]; then
      cp -a '$SRC_DIR/'\"\$f\" '$WORK/src.new/'\"\$f\"
    fi
  done

  rm -rf '$SRC_DIR.bak'
  mv -T '$SRC_DIR' '$SRC_DIR.bak'
  mv -T '$WORK/src.new' '$SRC_DIR'

  rm -rf '$WORK'
  rm -f '$ZIP_IN_CONTAINER'
  #echo 'chown /home/node/figma-preview for node:node'
  chown -R node:node '$SRC_DIR'
  chown -R node:node '$SRC_DIR.bak'
  mv -T '$SRC_DIR.bak' '$SRC_DIR.$DATE_STR'

  echo 'OK: src swapped. Backup at: $SRC_DIR.$DATE_STR'
"