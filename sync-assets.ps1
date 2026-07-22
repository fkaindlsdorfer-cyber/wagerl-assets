# sync-assets.ps1
# Bündelt Git + R2-Sync fuer das wagerl-assets Repo in einem Aufruf.
# Aufruf (aus dem Repo-Root):  .\sync-assets.ps1 "add die-nudelmanufaktur-huber logo"
# Muss im Repo-Root von wagerl-assets liegen.

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Message
)

$repo   = $PSScriptRoot
$remote = "r2:wagerl-assets"

Push-Location $repo
try {
    # rclone vorhanden?
    if (-not (Get-Command rclone -ErrorAction SilentlyContinue)) {
        Write-Host "FEHLER: rclone nicht gefunden. Sync nicht moeglich." -ForegroundColor Red
        return
    }

    # 1. Staging
    git add -A

    # 2. Ueberhaupt Aenderungen?
    $staged = git status --short
    if (-not $staged) {
        Write-Host "Nichts zu committen - Arbeitsbaum ist sauber." -ForegroundColor Yellow
        return
    }

    Write-Host "Diese Aenderungen werden committet:" -ForegroundColor Cyan
    git status --short
    Write-Host ""

    # 3. Commit
    git commit -m $Message
    if ($LASTEXITCODE -ne 0) {
        Write-Host "git commit fehlgeschlagen - Abbruch." -ForegroundColor Red
        return
    }

    # 4. Push
    git push
    if ($LASTEXITCODE -ne 0) {
        Write-Host "git push fehlgeschlagen - Abbruch, R2 NICHT gesynct." -ForegroundColor Red
        return
    }
    Write-Host "Git: committet und gepusht." -ForegroundColor Green
    Write-Host ""

    # 5. Dry-Run
    Write-Host "R2 Dry-Run (noch nichts veraendert)..." -ForegroundColor Cyan
    $dry = rclone sync $repo $remote --exclude ".git/**" --exclude "sync-assets.ps1" --dry-run -v 2>&1
    $dry | ForEach-Object { Write-Host "  $_" }
    Write-Host ""

    # 6. Deletes? -> nachfragen
    $deletes = $dry | Select-String "Skipped delete"
    if ($deletes) {
        Write-Host "ACHTUNG - folgende Dateien wuerden in R2 GELOESCHT:" -ForegroundColor Red
        $deletes | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        Write-Host ""
        $answer = Read-Host "Wirklich syncen inkl. dieser Loeschungen? (j/n)"
        if ($answer -ne "j") {
            Write-Host "Sync abgebrochen. Git ist gepusht, R2 unveraendert." -ForegroundColor Yellow
            return
        }
    }

    # 7. Scharfer Sync
    Write-Host "R2 Sync..." -ForegroundColor Cyan
    rclone sync $repo $remote --exclude ".git/**" --exclude "sync-assets.ps1" -v
    if ($LASTEXITCODE -ne 0) {
        Write-Host "rclone sync fehlgeschlagen." -ForegroundColor Red
        return
    }
    Write-Host ""
    Write-Host "Fertig. Bilder sind in R2." -ForegroundColor Green
    Write-Host "Jetzt nur noch logoUrl / imageKey im Admin (my-hof.web.app) setzen." -ForegroundColor Green
}
finally {
    Pop-Location
}
