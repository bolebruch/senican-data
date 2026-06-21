#!/usr/bin/env bash
# Denný sync mestského servisu: /Cowork/Senican/senican-mesto.json -> verejný repo senican-data.
# Spúšťa Claude Code routine po Cowork akcii senican-mesto-feed (~06:00).
# Web (www.senican.sk) feed fetchuje client-side => žiadny redeploy témy netreba.
set -euo pipefail
SRC="/Users/peterbolebruch/Cowork/Senican/senican-mesto.json"
REPO="/Users/peterbolebruch/Projects/senican-data"
cd "$REPO"
git pull -q --ff-only origin main || true
# validuj JSON pred publikovaním (nepushuj rozbitý feed)
python3 -c "import json,sys; json.load(open('$SRC'))"
cp "$SRC" "$REPO/senican-mesto.json"
if git diff --quiet -- senican-mesto.json; then
  echo "Žiadna zmena vo feede — nič na push ($(date '+%F %T'))."
  exit 0
fi
DATE=$(python3 -c "import json;print(json.load(open('senican-mesto.json'))['meta'].get('generated_for_date','?'))")
git add senican-mesto.json
git -c user.name="Peter Bolebruch" -c user.email="pbolebruch@gmail.com" \
    commit -q -m "feed: mestský servis $DATE"
git push -q origin main
echo "Feed publikovaný pre $DATE ($(date '+%F %T'))."
