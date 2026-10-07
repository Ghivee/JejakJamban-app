param(
    [string]$PhpExecutable = "php",
    [string]$ComposerExecutable = "composer"
)

$ErrorActionPreference = "Stop"
$backendPath = Split-Path -Parent $PSScriptRoot
$distPath = Join-Path $backendPath "dist"
$stagePath = Join-Path $env:TEMP ("jejakjamban-infinityfree-" + [guid]::NewGuid().ToString("N"))
$zipPath = Join-Path $distPath "jejakjamban-infinityfree-upload.zip"

if (-not (Get-Command $PhpExecutable -ErrorAction SilentlyContinue)) {
    throw "PHP executable '$PhpExecutable' tidak ditemukan. Pasang PHP 8.3 dan masukkan ke PATH, atau berikan -PhpExecutable dengan path php.exe."
}
if ([System.IO.Path]::GetExtension($ComposerExecutable) -eq ".phar") {
    if (-not (Test-Path -LiteralPath $ComposerExecutable -PathType Leaf)) {
        throw "Composer PHAR '$ComposerExecutable' tidak ditemukan."
    }
}
elseif (-not (Get-Command $ComposerExecutable -ErrorAction SilentlyContinue)) {
    throw "Composer '$ComposerExecutable' tidak ditemukan. Pasang Composer 2 dan masukkan ke PATH, atau berikan -ComposerExecutable dengan path composer.phar."
}

New-Item -ItemType Directory -Path $stagePath | Out-Null
New-Item -ItemType Directory -Path $distPath -Force | Out-Null

try {
    $sourceFiles = Get-ChildItem -LiteralPath $backendPath -File -Recurse -Force
    foreach ($sourceFile in $sourceFiles) {
        $relativePath = $sourceFile.FullName.Substring($backendPath.Length).TrimStart([char[]]"\/")
        $normalizedPath = $relativePath -replace "/", "\"

        if ($normalizedPath -match '(^|\\)(\.git|tests|node_modules|dist|vendor|seeders|infinityfree|scripts|docker)(\\|$)') {
            continue
        }
        if ($sourceFile.Name -in @(
            "Dockerfile",
            ".dockerignore",
            ".editorconfig",
            ".gitattributes",
            ".gitignore",
            "composer.json",
            "composer.lock",
            "phpunit.xml",
            "package.json",
            "vite.config.js"
        )) {
            continue
        }
        if ($sourceFile.Name -like ".env*" -or $sourceFile.Extension -in @(".sqlite", ".log", ".cache")) {
            continue
        }

        $targetPath = Join-Path $stagePath $relativePath
        $targetDirectory = Split-Path -Parent $targetPath
        New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
        Copy-Item -LiteralPath $sourceFile.FullName -Destination $targetPath -Force
    }

    Copy-Item -LiteralPath (Join-Path $backendPath "composer.json") -Destination $stagePath
    Copy-Item -LiteralPath (Join-Path $backendPath "composer.lock") -Destination $stagePath

    $composerArgs = @(
        "install",
        "--no-dev",
        "--no-interaction",
        "--prefer-dist",
        "--optimize-autoloader",
        "--no-scripts",
        "--working-dir=$stagePath"
    )
    if ([System.IO.Path]::GetExtension($ComposerExecutable) -eq ".phar") {
        & $PhpExecutable $ComposerExecutable @composerArgs
    }
    else {
        & $ComposerExecutable @composerArgs
    }
    if ($LASTEXITCODE -ne 0) {
        throw "Composer install gagal dengan exit code $LASTEXITCODE."
    }

    $bootstrapCache = Join-Path $stagePath "bootstrap\cache"
    Get-ChildItem -LiteralPath $bootstrapCache -File -Force |
        Where-Object { $_.Name -ne ".gitignore" } |
        Remove-Item -Force

    Push-Location $stagePath
    try {
        & $PhpExecutable artisan package:discover --ansi
        if ($LASTEXITCODE -ne 0) {
            throw "Laravel package discovery gagal dengan exit code $LASTEXITCODE."
        }
    }
    finally {
        Pop-Location
    }

    Remove-Item -LiteralPath (Join-Path $stagePath "composer.lock") -Force

    Copy-Item -LiteralPath (Join-Path $backendPath "infinityfree\htdocs.htaccess") `
        -Destination (Join-Path $stagePath ".htaccess") -Force

    if (Test-Path $zipPath) {
        Remove-Item -LiteralPath $zipPath -Force
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $stagePath,
        $zipPath,
        [System.IO.Compression.CompressionLevel]::Optimal,
        $false
    )

    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        $entries = @($zip.Entries)
        if (-not ($entries.FullName -contains ".htaccess")) {
            throw "Paket tidak memuat .htaccess root; batalkan upload."
        }
        if ($entries.FullName | Where-Object { $_ -match '(^|/)\.env($|\.)' }) {
            throw "Paket memuat file .env; batalkan upload."
        }
        if ($entries.FullName | Where-Object { $_ -match '\.(sqlite|log)$' }) {
            throw "Paket memuat database lokal/log; batalkan upload."
        }
    }
    finally {
        $zip.Dispose()
    }

    Write-Output "Paket siap: $zipPath"
    Write-Output "Database schema untuk phpMyAdmin: $(Join-Path $backendPath 'infinityfree\schema.sql')"
    Write-Output "Jangan unggah .env ke GitHub. Upload .env secara terpisah setelah mengisinya."
}
finally {
    if (Test-Path $stagePath) {
        Remove-Item -LiteralPath $stagePath -Recurse -Force
    }
}
