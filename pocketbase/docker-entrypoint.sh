#!/bin/sh
set -e

# Данные в /pb/pb_data (на Render лучше с persistent disk — иначе после рестарта пусто).
# migrate up идемпотентен: повторно сиды не дублирует, если миграции уже применены.
/pb/pocketbase migrate up || true
/pb/pocketbase superuser upsert "${PB_ADMIN_EMAIL:-admin@gmail.com}" "${PB_ADMIN_PASSWORD:-admin123}" || true
exec /pb/pocketbase serve --http=0.0.0.0:${PORT:-8090} --dir=/pb/pb_data
