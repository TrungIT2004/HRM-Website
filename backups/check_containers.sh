#!/bin/sh

CONTAINERS="hrm-database hrm-cache hrm-ai-service hrm-backend hrm-frontend hrm-n8n hrm-cloudflared-web hrm-cloudflared-api hrm-cloudflared-ai"
DOWN_LIST=""
UP_COUNT=0
TOTAL_COUNT=0

for C in $CONTAINERS; do
  TOTAL_COUNT=$((TOTAL_COUNT + 1))
  STATUS=`docker inspect --format='{{.State.Status}}' "$C" 2>/dev/null || echo "not_found"`
  HEALTH=`docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$C" 2>/dev/null || echo "none"`

  if [ "$STATUS" != "running" ]; then
    DOWN_LIST="${DOWN_LIST}• ❌ \`${C}\`: Status = *${STATUS}*\n"
  elif [ "$HEALTH" = "unhealthy" ]; then
    DOWN_LIST="${DOWN_LIST}• ⚠️ \`${C}\`: Health = *unhealthy*\n"
  else
    UP_COUNT=$((UP_COUNT + 1))
  fi
done

if [ -n "$DOWN_LIST" ]; then
  echo "STATUS:DOWN"
  printf "%b" "$DOWN_LIST"
else
  echo "STATUS:OK"
  echo "Tất cả ${TOTAL_COUNT} containers đang hoạt động tốt"
fi
