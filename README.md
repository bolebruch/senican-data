# senican-data

Verejný dátový kanál pre homepage **senican.sk** (mestský servis).

`senican-mesto.json` je zdroj pravdy pre 4 sekcie homepage: **Z mesta, Podujatia, Servis, Transparentnosť**.
Súbor sa generuje automaticky (Cowork akcia `senican-mesto-feed`, ~06:00) a denne sem pushuje Claude Code routine.
Téma `senican.sk` ho fetchuje client-side z raw URL — dáta sa obnovujú **bez redeployu témy**.

- Raw URL: `https://raw.githubusercontent.com/bolebruch/senican-data/main/senican-mesto.json`
- Schéma a pravidlá: viď handoff v hlavnom repe `senican-sk-ghost`.

Obsah je verejná samosprávna informácia (zdroj: mesto Senica / TIC Senica). Žiadne secrets.

## Ranný push — dva spôsoby (vyber jeden)

JSON sa do tohto repa dostáva jedným z dvoch mechanizmov. **Aktívny má byť vždy len jeden** (oba sú idempotentné, ale dva paralelné pushe sú zbytočná duplicita).

### A) Lokálna launchd routine (aktívna) — `sync.sh`

macOS LaunchAgent `sk.senican.feed-sync` (`~/Library/LaunchAgents/`) spúšťa `sync.sh` denne **06:15**: skopíruje lokálny Cowork JSON (`~/Cowork/Senican/senican-mesto.json`), zvaliduje a `git push`-ne sem. **Podmienka: Mac zapnutý** o 06:15 (ak spí, dobehne po prebudení). Log: `~/Library/Logs/senican-feed-sync.log`.

### B) Cloud fallback (bez Macu) — `cowork-push.sh`

Pushne JSON priamo cez **GitHub Contents API** (curl, žiadny git/lokálne credentials) — vhodné spustiť priamo v **Cowork** (cloud) prostredí po vygenerovaní JSON. Mac netreba.

Aktivácia:
1. Fine-grained PAT (github.com → Settings → Developer settings): repo **iba `bolebruch/senican-data`**, permission **Contents: Read and write**, nič viac.
2. Token do Cowork tasku ako secret `GITHUB_TOKEN` (NIKDY do kódu/chatu).
3. V Cowork tasku po generovaní JSON spusti:
   ```bash
   GITHUB_TOKEN="$GITHUB_TOKEN" bash cowork-push.sh /cesta/k/senican-mesto.json
   ```
4. Vypni launchd, nech nepushujú dvaja: `launchctl bootout gui/$(id -u)/sk.senican.feed-sync`
