#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# make cwd the script dir
cd "$(dirname "$0")"

ES_URL="http://localhost:9200"

export LOG_FILE="/tmp/post-start/post-start.txt"


echo "" > ${LOG_FILE}

# Wait for Elasticsearch to be ready
while [[ "$(curl -s -o /dev/null -w '%{http_code}' ${ES_URL}/_cluster/health)" != "200" ]]; do
  echo "Waiting for Elasticsearch to be ready..." >> ${LOG_FILE}
  sleep 5
done

# Run script commands after Elasticsearch is ready
echo "Elasticsearch is ready. Executing further actions." >> ${LOG_FILE}
# API calls to configure Elasticsearch here
curl -s -S -XPOST ${ES_URL}/_nodes/reload_secure_settings >> ${LOG_FILE}
curl -s -S -XPUT ${ES_URL}/_snapshot/sewol_s3_repository -H "Content-Type: application/json" -d @snapshot-repository.json >> ${LOG_FILE}
curl -s -S -XPUT ${ES_URL}/_slm/policy/sewol-auditlogs-snapshots -H "Content-Type: application/json" -d @backup-policy.json >> ${LOG_FILE}
curl -s -S -XPUT ${ES_URL}/ilm/policy/audit-logs-lifecycle-policy -H "Content-Type: application/json" -d @index-policy.json >> ${LOG_FILE}
