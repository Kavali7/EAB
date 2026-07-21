param(
  [string]$Configuration = "Release",
  [string]$SupabaseUrl = $env:GESTION_EGLISE_SUPABASE_URL,
  [string]$SupabaseAnonKey = $env:GESTION_EGLISE_SUPABASE_ANON_KEY,
  [string]$FiscalPdfConverterUrl = $env:FISCAL_PDF_CONVERTER_URL
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$BuildDir = Join-Path $ProjectRoot "build\windows\x64"
$ReleaseDir = Join-Path $BuildDir "runner\$Configuration"
$CMakePath = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"

if (-not (Test-Path $CMakePath)) {
  throw "CMake Visual Studio 2022 introuvable: $CMakePath"
}

function ConvertTo-DartDefine {
  param([Parameter(Mandatory = $true)][string]$Value)
  return [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Value))
}

function Update-FlutterGeneratedConfig {
  param(
    [Parameter(Mandatory = $true)][string]$ConfigPath,
    [Parameter(Mandatory = $true)][hashtable]$Defines
  )

  if (-not (Test-Path $ConfigPath)) {
    throw "Configuration Flutter Windows introuvable: $ConfigPath"
  }

  $EncodedDefines = @()
  foreach ($Entry in $Defines.GetEnumerator()) {
    if (-not [string]::IsNullOrWhiteSpace($Entry.Value)) {
      $EncodedDefines += ConvertTo-DartDefine "$($Entry.Key)=$($Entry.Value)"
    }
  }

  if ($EncodedDefines.Count -eq 0) {
    return
  }

  $Content = Get-Content $ConfigPath -Raw
  $Match = [regex]::Match($Content, '"DART_DEFINES=([^"]*)"')
  if (-not $Match.Success) {
    throw "Ligne DART_DEFINES introuvable dans: $ConfigPath"
  }

  $ExistingDefines = @()
  if (-not [string]::IsNullOrWhiteSpace($Match.Groups[1].Value)) {
    $ExistingDefines = $Match.Groups[1].Value.Split(',') |
      Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
  }

  $CombinedDefines = @($ExistingDefines + $EncodedDefines) |
    Select-Object -Unique
  $Replacement = '"DART_DEFINES=' + ($CombinedDefines -join ',') + '"'
  $Content = [regex]::Replace($Content, '"DART_DEFINES=[^"]*"', $Replacement, 1)
  Set-Content -Path $ConfigPath -Value $Content -NoNewline -Encoding UTF8
}

Push-Location $ProjectRoot
try {
  flutter pub get

  Update-FlutterGeneratedConfig `
    -ConfigPath (Join-Path $ProjectRoot "windows\flutter\ephemeral\generated_config.cmake") `
    -Defines @{
      SUPABASE_URL = $SupabaseUrl
      SUPABASE_ANON_KEY = $SupabaseAnonKey
      FISCAL_PDF_CONVERTER_URL = $FiscalPdfConverterUrl
    }

  New-Item -ItemType Directory -Force -Path $ReleaseDir | Out-Null
  $InstallPrefix = (Resolve-Path $ReleaseDir).Path.Replace('\', '/')

  & $CMakePath `
    -S windows `
    -B $BuildDir `
    -G "Visual Studio 17 2022" `
    -A x64 `
    -DFLUTTER_TARGET_PLATFORM=windows-x64 `
    -DCMAKE_INSTALL_PREFIX="$InstallPrefix"

  & $CMakePath --build $BuildDir --config $Configuration --target INSTALL

  $ExePath = Join-Path $ReleaseDir "gestion_eglise.exe"
  if (-not (Test-Path $ExePath)) {
    throw "Build termine sans executable attendu: $ExePath"
  }

  Write-Host "Executable Windows pret: $ExePath"
} finally {
  Pop-Location
}
