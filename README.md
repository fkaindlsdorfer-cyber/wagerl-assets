# wagerl-assets

Bild-Assets für **my Wagerl** (Hof-Logos + Produkt-/Katalogbilder).

Dieses Repo ist die **Quelle der Wahrheit** für alle Bilder. Cloudflare R2 ist nur die
**Auslieferungsschicht** (Worker `wagerl-assets.mywagerl.workers.dev`, Edge-Cache). Die
native App lädt Bilder über den Worker, gesteuert per `VITE_ASSETS_BASE`.

```
Bild  ->  lokaler Repo-Ordner  ->  git commit/push   (GitHub = Archiv/Backup)
                               ->  rclone sync        (R2     = Auslieferung)
```

## Pfad-Konvention

```
providers/{slug}/{key}.jpg
```

- `{slug}` = Hof-Slug, **immer kleingeschrieben, Umlaute gefoldet** (`hoedlhof`, `hager`).
- `{key}` = Dateiname **ohne Endung**, **kleingeschrieben, keine Leerzeichen**
  (`waldhonig_500g`, `eier`). Dieser `{key}` ist exakt der `imageKey`, der im Admin
  (my-hof.web.app) ins Bild-Feld des Katalog-Eintrags eingetragen wird.

## Goldene Regeln (teuer gelernt)

1. **Bilder NUR über diesen lokalen Repo-Ordner** anlegen/ändern. **Nie** direkt im
   R2-Dashboard, **nie** über GitHub-Web ("Add files via upload"). Sonst laufen
   GitHub, R2 und lokal auseinander (Casing-/Müll-Konflikte, verlorene Bilder).
2. **Alles lowercase, keine Leerzeichen** — Ordner UND Dateinamen. R2 ist
   case-sensitiv: `providers/Hager/...` liefert 404, wenn die App `hager` abfragt.
3. **Dateiname (ohne `.jpg`) == imageKey im Admin.** Casing muss exakt stimmen.

## Bild hinzufügen — Schritt für Schritt

**1. Lokal ablegen**
```
C:\Users\fkain\projekte\wagerl-assets\providers\{slug}\{key}.jpg
```
(lowercase, keine Leerzeichen)

**2. Committen + pushen** (PowerShell, Befehle einzeln)
```
cd C:\Users\fkain\projekte\wagerl-assets
```
```
git add -A
```
```
git status
```
(Gegencheck: nur die neue Datei als `new file`, sonst nichts Unerwartetes)
```
git commit -m "assets: add {slug} {key} image"
```
```
git push
```

**3. Nach R2 syncen — erst Dry-Run, dann scharf**
```
rclone sync ./ r2:wagerl-assets --exclude ".git/**" --dry-run -v
```
Erwartung: nur die neue Datei als `Copied (new)`, keine unerwarteten Deletes.
Wenn plausibel:
```
rclone sync ./ r2:wagerl-assets --exclude ".git/**" -v
```

**4. imageKey im Admin setzen**
my-hof.web.app -> Anbieter/Sortiment -> Katalog-Eintrag -> Bild-Feld = `{key}`
(ohne `.jpg`) -> Speichern.

**5. Verifizieren**
Admin -> QS -> "Bilder live prüfen" -> der Eintrag muss `OK` zeigen (nicht `BILD_404`).

## Bild ersetzen / löschen

- **Ersetzen (gleicher key):** Datei lokal überschreiben -> commit/push -> `rclone sync`.
  Achtung Edge-Cache: der Worker kann die alte Version weiter ausliefern. Im App-/
  Browser-Tab **Hard-Reload (Strg+Shift+R)**, oder URL mit `?v=2` cache-busten.
- **Löschen:** Datei lokal entfernen -> commit/push -> `rclone sync` (sync spiegelt,
  entfernt die Datei dann auch in R2). imageKey im Admin leeren.

## Fehlersuche bei BILD_404

In dieser Reihenfolge prüfen:
1. **Casing/Leerzeichen** — Ordner und Dateiname exakt lowercase? `{key}` == imageKey?
2. **In R2 vorhanden?** `rclone ls r2:wagerl-assets` -> liegt `providers/{slug}/{key}.jpg`
   da (mit richtigem Casing)?
3. **Edge-Cache** — Browser direkt testen:
   `https://wagerl-assets.mywagerl.workers.dev/providers/{slug}/{key}.jpg?v=2`
   Lädt mit `?v=2`, aber QS zeigt 404 -> Cache; Hard-Reload.
4. **logoUrl-Sonderfall** — Logos laufen über das `logoUrl`-Feld des Anbieters (nicht
   über imageKey). Steht dort noch eine alte `raw.githubusercontent.com`-URL, auf die
   Worker-URL umstellen: `https://wagerl-assets.mywagerl.workers.dev/providers/{slug}/{datei}`.

## rclone-Setup (einmalig)

Remote heißt `r2` (s3 / provider Cloudflare), Endpoint
`https://0e831eabfb93ac8a257f09700650225c.r2.cloudflarestorage.com`, Credentials =
R2-API-Token (Object Read & Write, scoped auf `wagerl-assets`). Konfiguration via
`rclone config`. Bestand prüfen: `rclone ls r2:wagerl-assets`.
