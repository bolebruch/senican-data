# senican-data

Verejný dátový kanál pre homepage **senican.sk** (mestský servis).

`senican-mesto.json` je zdroj pravdy pre 4 sekcie homepage: **Z mesta, Podujatia, Servis, Transparentnosť**.
Súbor sa generuje automaticky (Cowork akcia `senican-mesto-feed`, ~06:00) a denne sem pushuje Claude Code routine.
Téma `senican.sk` ho fetchuje client-side z raw URL — dáta sa obnovujú **bez redeployu témy**.

- Raw URL: `https://raw.githubusercontent.com/bolebruch/senican-data/main/senican-mesto.json`
- Schéma a pravidlá: viď handoff v hlavnom repe `senican-sk-ghost`.

Obsah je verejná samosprávna informácia (zdroj: mesto Senica / TIC Senica). Žiadne secrets.
