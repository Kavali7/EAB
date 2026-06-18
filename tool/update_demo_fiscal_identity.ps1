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
