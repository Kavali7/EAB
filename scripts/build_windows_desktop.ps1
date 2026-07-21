param(
  [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$BuildDir = Join-Path $ProjectRoot "build\windows\x64"
$ReleaseDir = Join-Path $BuildDir "runner\$Configuration"
$CMakePath = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"

if (-not (Test-Path $CMakePath)) {
  throw "CMake Visual Studio 2022 introuvable: $CMakePath"
}

Push-Location $ProjectRoot
try {
  flutter pub get

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
