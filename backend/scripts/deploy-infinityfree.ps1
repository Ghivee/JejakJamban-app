param(
    [Parameter(Mandatory = $true)][string]$FtpHost,
    [Parameter(Mandatory = $true)][string]$FtpUser,
    [Parameter(Mandatory = $true)][string]$FtpPass,
    [Parameter(Mandatory = $true)][string]$Domain,
    [Parameter(Mandatory = $true)][string]$DbHost,
    [Parameter(Mandatory = $true)][string]$DbName,
    [Parameter(Mandatory = $true)][string]$DbUser,
    [Parameter(Mandatory = $true)][string]$DbPass,
    [string]$RemoteDir = "htdocs",
    [switch]$SkipUpload,
    [switch]$SkipCheck
)

$ErrorActionPreference = "Stop"
$backendPath = Split-Path -Parent $PSScriptRoot
$projectRoot = Split-Path -Parent $backendPath
$zipPath = Join-Path $backendPath "dist\jejakjamban-infinityfree-upload.zip"
$stagePath = Join-Path $env:TEMP ("jj-deploy-" + [guid]::NewGuid().ToString("N"))

if (-not (Test-Path -LiteralPath $zipPath)) {
    throw "Paket ZIP tidak ditemukan. Jalankan dulu .\scripts\prepare-infinityfree.ps1"
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-AppKey {
    $key = & php -r "echo 'base64:'.base64_encode(random_bytes(32));"
    if (-not $key) { throw "Gagal generate APP_KEY; pastikan php ada di PATH." }
    return $key.Trim()
}

function New-ProductionEnv([string]$appKey) {
    $template = Get-Content -LiteralPath (Join-Path $backendPath ".env.infinityfree.example") -Raw
    $envText = $template `
        -replace 'REPLACE_WITH_INFINITYFREE_DOMAIN', $Domain `
        -replace 'REPLACE_WITH_MYSQL_HOST_FROM_CONTROL_PANEL', $DbHost `
        -replace 'REPLACE_WITH_FULL_DATABASE_NAME', $DbName `
        -replace 'REPLACE_WITH_FULL_DATABASE_USERNAME', $DbUser `
        -replace 'REPLACE_WITH_DATABASE_PASSWORD', $DbPass `
        -replace 'APP_KEY=', "APP_KEY=$appKey"
    return $envText
}

function Upload-Files([string]$localRoot, [string]$ftpRoot) {
    $files = Get-ChildItem -LiteralPath $localRoot -Recurse -File -Force
    $total = $files.Count
    $i = 0
    $failed = @()
    foreach ($f in $files) {
        $i++
        $rel = $f.FullName.Substring($localRoot.Length).TrimStart([char[]]"\/") -replace "\\", "/"
        $uri = "$ftpRoot/$rel"
        Write-Progress -Activity "Upload ke InfinityFree FTP" -Status "$i/$total  $rel" -PercentComplete ([int](100 * $i / $total))
        $attempts = 0
        while ($attempts -lt 3) {
            $attempts++
            try {
                $out = & curl.exe --silent --show-error --ftp-create-dirs `
                    --user "$FtpUser`:$FtpPass" `
                    --upload-file $f.FullName $uri 2>&1
                if ($LASTEXITCODE -ne 0) { throw "curl exit $LASTEXITCODE : $out" }
                break
            }
            catch {
                if ($attempts -ge 3) { $failed += $rel; Write-Warning "Gagal: $rel - $_" }
                else { Start-Sleep -Seconds 2 }
            }
        }
    }
    Write-Progress -Activity "Upload ke InfinityFree FTP" -Completed
    return $failed
}

# 1. Buat .env production lokal
$appKey = Get-AppKey
$envText = New-ProductionEnv -appKey $appKey
$envStage = Join-Path $env:TEMP ("jj-env-" + [guid]::NewGuid().ToString("N") + ".env")
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($envStage, ($envText -replace "`r`n", "`n"), $utf8NoBom)
Write-Output ".env production dibuat (APP_KEY ter-generate)."

if (-not $SkipUpload) {
    # 2. Ekstrak ZIP ke stage
    New-Item -ItemType Directory -Path $stagePath | Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $stagePath)
    Write-Output "ZIP diekstrak ($((Get-ChildItem $stagePath -Recurse -File).Count) file)."

    # 3. Salin .env ke stage (ikut ter-upload; ZIP sendiri tidak memuat .env)
    Copy-Item -LiteralPath $envStage -Destination (Join-Path $stagePath ".env") -Force

    # 4. Upload
    $ftpRoot = "ftp://$FtpHost/$RemoteDir"
    Write-Output "Upload dimulai ke $ftpRoot ..."
    $failed = Upload-Files -localRoot $stagePath -ftpRoot $ftpRoot
    if ($failed.Count -gt 0) {
        Write-Warning "File gagal upload ($($failed.Count)):"
        $failed | ForEach-Object { Write-Warning "  $_" }
        throw "Upload belum lengkap. Jalankan ulang skrip (upload bersifat idempoten per file)."
    }
    Write-Output "Upload selesai tanpa kegagalan."
    Remove-Item -LiteralPath $stagePath -Recurse -Force
}
else {
    Write-Output "Upload dilewati (-SkipUpload); hanya .env yang disiapkan di $envStage"
}

# 5. Uji endpoint
if (-not $SkipCheck) {
    $base = "https://$Domain"
    Write-Output "Memeriksa $base/up ..."
    Start-Sleep -Seconds 3
    try {
        $resp = Invoke-WebRequest -Uri "$base/up" -UseBasicParsing -TimeoutSec 60
        Write-Output "GET /up -> HTTP $($resp.StatusCode)"
    }
    catch {
        $code = $null
        if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
        Write-Warning "GET /up gagal: $($_.Exception.Message) (HTTP $code)"
        Write-Warning "Cek panel hosting: versi PHP 8.2+/8.3, ekstensi pdo_mysql/mbstring, dan lihat file storage/logs/laravel.log via File Manager."
    }
    try {
        $reg = Invoke-WebRequest -Uri "$base/api/logs" -UseBasicParsing -TimeoutSec 60
        Write-Output "GET /api/logs -> HTTP $($reg.StatusCode)"
    }
    catch {
        $code = $null
        if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
        Write-Output "GET /api/logs -> HTTP $code (401/403 berarti API hidup dan menuntut token; 500 berarti masalah DB/env)."
    }
}

Write-Output ""
Write-Output "Selesai. Simpan APP_KEY ini di tempat aman (jangan commit):"
Write-Output $appKey
if (Test-Path $envStage) { Write-Output "Salinan .env lokal: $envStage" }
