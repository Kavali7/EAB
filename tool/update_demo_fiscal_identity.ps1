param(
  [string]$OrgId = "",
  [string]$Sigle = "EAB"
)

$ErrorActionPreference = "Stop"

function Assert-EnvValue {
  param([string]$Name)

  $value = [Environment]::GetEnvironmentVariable($Name)
  if ([string]::IsNullOrWhiteSpace($value)) {
    throw "Variable d'environnement manquante : $Name"
  }
  return $value.TrimEnd("/")
}

function Get-ProjectRefFromUrl {
  param([string]$Url)

  if ($Url -match "https://([a-z0-9]+)\.supabase\.co") {
    return $Matches[1]
  }

  return ""
}

function Get-AppSupabaseRef {
  $configPath = Join-Path $PSScriptRoot "..\lib\core\config\supabase_config.dart"
  $content = Get-Content -LiteralPath $configPath -Raw
  if ($content -match "https://([a-z0-9]+)\.supabase\.co") {
    return $Matches[1]
  }

  throw "Impossible de lire le projet Supabase configure dans l'application."
}

function Decode-JwtPayload {
  param([string]$Jwt)

  if ([string]::IsNullOrWhiteSpace($Jwt) -or -not $Jwt.Contains(".")) {
    throw "Cle Supabase invalide ou absente."
  }

  $payload = $Jwt.Split(".")[1].Replace("-", "+").Replace("_", "/")
  switch ($payload.Length % 4) {
    2 { $payload += "==" }
    3 { $payload += "=" }
  }

  $json = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload))
  return $json | ConvertFrom-Json
}

function Assert-SupabaseProjectMatchesApp {
  $appRef = Get-AppSupabaseRef
  $urlRef = Get-ProjectRefFromUrl $script:SupabaseUrl
  $servicePayload = Decode-JwtPayload $script:ServiceRoleKey

  if ($servicePayload.role -ne "service_role") {
    throw "SUPABASE_SERVICE_ROLE_KEY ne contient pas une cle service_role."
  }

  if ($urlRef -ne $appRef -or $servicePayload.ref -ne $appRef) {
    throw "Projet Supabase incoherent. Application=$appRef, SUPABASE_URL=$urlRef, SERVICE_ROLE=$($servicePayload.ref). Corrigez les variables d'environnement avant execution."
  }
}

function Invoke-SupabaseRest {
  param(
    [string]$Method,
    [string]$Path,
    [object]$Body = $null,
    [string]$Prefer = ""
  )

  $headers = @{
    apikey        = $script:ServiceRoleKey
    Authorization = "Bearer $script:ServiceRoleKey"
  }

  if (-not [string]::IsNullOrWhiteSpace($Prefer)) {
    $headers["Prefer"] = $Prefer
  }

  $params = @{
    Method  = $Method
    Uri     = "$script:SupabaseUrl$Path"
    Headers = $headers
  }

  if ($null -ne $Body) {
    $headers["Content-Type"] = "application/json"
    $params["Body"] = ($Body | ConvertTo-Json -Depth 30)
  }

  try {
    return Invoke-RestMethod @params
  } catch {
    $response = $_.Exception.Response
    if ($null -ne $response) {
      $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
      $detail = $reader.ReadToEnd()
      if (-not [string]::IsNullOrWhiteSpace($detail)) {
        throw "$($_.Exception.Message)`n$detail"
      }
    }
    throw
  }
}

function ConvertTo-PlainHashtable {
  param([object]$Value)

  if ($null -eq $Value) {
    return @{}
  }

  if ($Value -is [System.Collections.IDictionary]) {
    $result = @{}
    foreach ($key in $Value.Keys) {
      $result[$key] = ConvertTo-PlainValue $Value[$key]
    }
    return $result
  }

  if ($Value -is [pscustomobject]) {
    $result = @{}
    foreach ($property in $Value.PSObject.Properties) {
      $result[$property.Name] = ConvertTo-PlainValue $property.Value
    }
    return $result
  }

  return @{}
}

function ConvertTo-PlainValue {
  param([object]$Value)

  if ($null -eq $Value) {
    return $null
  }

  if ($Value -is [System.Collections.IDictionary] -or $Value -is [pscustomobject]) {
    return ConvertTo-PlainHashtable $Value
  }

  if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
    $items = @()
    foreach ($item in $Value) {
      $items += ConvertTo-PlainValue $item
    }
    return $items
  }

  return $Value
}

function Coalesce-Text {
  param(
    [string]$Current,
    [string]$Fallback
  )

  if ([string]::IsNullOrWhiteSpace($Current)) {
    return $Fallback
  }

  return $Current
}

$script:SupabaseUrl = Assert-EnvValue "SUPABASE_URL"
$script:ServiceRoleKey = Assert-EnvValue "SUPABASE_SERVICE_ROLE_KEY"
Assert-SupabaseProjectMatchesApp

$select = "id,name,sigle,adresse,telephone,email,site_web,devise,parametres"
$organizations = @(Invoke-SupabaseRest -Method "GET" -Path "/rest/v1/organizations?select=$select&order=created_at.asc")

if ($organizations.Count -eq 0) {
  throw "Aucune organisation trouvee dans le projet Supabase."
}

$target = $null
if (-not [string]::IsNullOrWhiteSpace($OrgId)) {
  $target = $organizations | Where-Object { $_.id -eq $OrgId } | Select-Object -First 1
} elseif (-not [string]::IsNullOrWhiteSpace($Sigle)) {
  $target = $organizations | Where-Object { $_.sigle -eq $Sigle } | Select-Object -First 1
}

if ($null -eq $target -and $organizations.Count -eq 1) {
  $target = $organizations[0]
}

if ($null -eq $target) {
  $summary = $organizations |
    Select-Object id,name,sigle |
    ConvertTo-Json -Depth 4
  throw "Organisation cible introuvable. Relancez avec -OrgId ou -Sigle.`nOrganisations disponibles :`n$summary"
}

$parametres = ConvertTo-PlainHashtable $target.parametres

$parametres["fiscal_identity"] = [ordered]@{
  ifu                        = "3202600000001"
  registration_number        = "EAB-DEMO-2026-001"
  tax_center                 = "Centre des impots des organisations religieuses - Cotonou"
  deposit_center             = "Direction generale des impots - Cotonou"
  country                    = "Benin"
  head_office_address        = "Cotonou, Littoral, Benin"
  activity_description       = "Organisation religieuse a but non lucratif, gestion cultuelle, sociale et administrative des eglises locales."
  legal_representative_name  = "Georges GUIDAN"
  legal_representative_title = "Representant legal de demonstration"
  legal_representative_phone = "+229 01 00 00 00 00"
  accountant_name            = "Comptable Demo Eglise"
  accountant_title           = "Comptable responsable des etats SYSCEBNL"
  accountant_phone           = "+229 01 00 00 00 01"
  accountant_email           = "comptable.demo@example.com"
  bank_name                  = "Banque Demo Benin"
  bank_account_label         = "Compte principal de demonstration"
  bank_account_number        = "BJ66DEMO000000000001"
  legal_form_code            = "07"
  tax_regime_code            = "01"
  country_code               = "01"
  establishments_in_country  = "01"
  establishments_outside_country = "00"
  first_fiscal_year          = "2025"
  control_type_code          = "private_national"
  main_activity_code         = "9491"
  social_security_number     = ""
  importer_code              = ""
  legal_representative_fiscal_id = "3202600000099"
  governance_leaders         = "Georges GUIDAN | Rep. legal | 3202600000099 | Cotonou, Littoral, Benin`nMarie HOUNTON | Secretaire | 3202600000100 | Porto-Novo, Benin"
  board_members              = "Paul KOSSOU | President | Cotonou, Benin`nJeanne ADANDE | Membre | Abomey-Calavi, Benin"
  applicable_notes           = "NOTE 2, NOTE 3B, NOTE 3C, NOTE 11, NOTE 21, NOTE 22, NOTE 24, NOTE 25, NOTE 30, NOTE 34, NOTE 35, NOTE 36"
}

$onboarding = @{}
if ($parametres.ContainsKey("onboarding")) {
  $onboarding = ConvertTo-PlainHashtable $parametres["onboarding"]
}

$completed = @()
if ($onboarding.ContainsKey("completed_steps") -and $null -ne $onboarding["completed_steps"]) {
  $completed = @($onboarding["completed_steps"])
}
if ($completed -notcontains "fiscal_identity") {
  $completed += "fiscal_identity"
}
$onboarding["completed_steps"] = @($completed | Select-Object -Unique)
$parametres["onboarding"] = $onboarding

$patch = [ordered]@{
  adresse    = Coalesce-Text $target.adresse "Cotonou, Littoral, Benin"
  telephone  = Coalesce-Text $target.telephone "+229 01 00 00 00 00"
  email      = Coalesce-Text $target.email "contact.demo@example.com"
  site_web   = Coalesce-Text $target.site_web "https://demo.eglisewise.local"
  devise     = Coalesce-Text $target.devise "FCFA"
  parametres = $parametres
}

$updated = Invoke-SupabaseRest `
  -Method "PATCH" `
  -Path "/rest/v1/organizations?id=eq.$($target.id)&select=id,name,sigle,adresse,telephone,email,site_web,devise,parametres" `
  -Body $patch `
  -Prefer "return=representation"

$result = $updated | Select-Object -First 1
[pscustomobject]@{
  organization_id       = $result.id
  organization_name     = $result.name
  organization_sigle    = $result.sigle
  fiscal_fields         = ($result.parametres.fiscal_identity.PSObject.Properties | Measure-Object).Count
  fiscal_step_completed = @($result.parametres.onboarding.completed_steps) -contains "fiscal_identity"
} | ConvertTo-Json -Depth 4
