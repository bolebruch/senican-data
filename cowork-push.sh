#!/usr/bin/env bash
# FALLBACK push mestského servisu do repa senican-data PRIAMO cez GitHub API.
# Nezávislé na zapnutom Macu — určené pre Cowork (cloud) prostredie ako alternatíva
# k lokálnej launchd routine (sync.sh). Žiadny git ani lokálne credentials — len curl.
#
# Vyžaduje:
#   - env GITHUB_TOKEN = fine-grained PAT, repo bolebruch/senican-data, Contents: Read+Write
#   - python3, curl, base64
#
# Použitie:
#   GITHUB_TOKEN=ghp_... bash cowork-push.sh [cesta_k_json]
# Default cesta: /Users/peterbolebruch/Cowork/Senican/senican-mesto.json
set -euo pipefail

SRC="${1:-/Users/peterbolebruch/Cowork/Senican/senican-mesto.json}"
REPO="bolebruch/senican-data"
FILE="senican-mesto.json"
BRANCH="main"
API="https://api.github.com/repos/$REPO/contents/$FILE"

: "${GITHUB_TOKEN:?Chýba GITHUB_TOKEN (fine-grained PAT s Contents:write na $REPO)}"
[ -f "$SRC" ] || { echo "Zdroj neexistuje: $SRC"; exit 1; }

# 1) validuj JSON (nepushuj rozbitý feed)
python3 -c "import json; json.load(open('$SRC'))"
DATE=$(python3 -c "import json;print(json.load(open('$SRC'))['meta'].get('generated_for_date','?'))")

# 2) stiahni aktuálny stav súboru v repe (sha + obsah pre porovnanie)
RESP=$(curl -fsS -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" "$API?ref=$BRANCH" || echo '{}')
SHA=$(printf '%s' "$RESP" | python3 -c "import json,sys; print(json.load(sys.stdin).get('sha',''))")

# 3) idempotencia: ak je obsah v repe identický, nič nepushuj
if [ -n "$SHA" ]; then
  printf '%s' "$RESP" | python3 -c "
import json,sys,base64
d=json.load(sys.stdin)
remote=base64.b64decode(d.get('content','')) if d.get('content') else b''
local=open('$SRC','rb').read()
sys.exit(0 if remote==local else 1)
" && { echo "Žiadna zmena vo feede — nič na push ($DATE)."; exit 0; }
fi

# 4) PUT (create/update) — base64 obsah + sha (ak update)
CONTENT=$(base64 < "$SRC" | tr -d '\n')
PAYLOAD=$(python3 -c "
import json,sys
p={'message':'feed: mestský servis $DATE','content':'''$CONTENT''','branch':'$BRANCH',
   'committer':{'name':'Cowork senican-mesto-feed','email':'pbolebruch@gmail.com'}}
sha='$SHA'
if sha: p['sha']=sha
print(json.dumps(p))
")
HTTP=$(curl -fsS -w '%{http_code}' -o /tmp/cowork-push-resp.json \
  -X PUT -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -d "$PAYLOAD" "$API")

if [ "$HTTP" -ge 200 ] && [ "$HTTP" -lt 300 ]; then
  echo "Feed publikovaný pre $DATE (HTTP $HTTP)."
else
  echo "Push zlyhal (HTTP $HTTP):"; cat /tmp/cowork-push-resp.json; exit 1
fi
