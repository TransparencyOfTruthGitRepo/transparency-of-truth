param(
  [string]$OnlyState = "",
  [switch]$DryRun
)

Import-Module powershell-yaml -ErrorAction Stop

$projectRoot = (Get-Location).Path
$repoDataDir = Join-Path $projectRoot "scripts\data-import\openstates-people\data"
$dataDir     = Join-Path $projectRoot "data\officials"
$contentDir  = Join-Path $projectRoot "content\officials"
$today       = Get-Date -Format "yyyy-MM-dd"
$now         = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"

$stateNames = @{
  "al"="alabama"; "ak"="alaska"; "az"="arizona"; "ar"="arkansas"; "ca"="california"
  "co"="colorado"; "ct"="connecticut"; "de"="delaware"; "fl"="florida"; "ga"="georgia"
  "hi"="hawaii"; "id"="idaho"; "il"="illinois"; "in"="indiana"; "ia"="iowa"
  "ks"="kansas"; "ky"="kentucky"; "la"="louisiana"; "me"="maine"; "md"="maryland"
  "ma"="massachusetts"; "mi"="michigan"; "mn"="minnesota"; "ms"="mississippi"; "mo"="missouri"
  "mt"="montana"; "ne"="nebraska"; "nv"="nevada"; "nh"="new-hampshire"; "nj"="new-jersey"
  "nm"="new-mexico"; "ny"="new-york"; "nc"="north-carolina"; "nd"="north-dakota"; "oh"="ohio"
  "ok"="oklahoma"; "or"="oregon"; "pa"="pennsylvania"; "ri"="rhode-island"; "sc"="south-carolina"
  "sd"="south-dakota"; "tn"="tennessee"; "tx"="texas"; "ut"="utah"; "vt"="vermont"
  "va"="virginia"; "wa"="washington"; "wv"="west-virginia"; "wi"="wisconsin"; "wy"="wyoming"
}

$summary = @()

$stateDirs = Get-ChildItem $repoDataDir -Directory | Where-Object {
  $stateNames.ContainsKey($_.Name.ToLower()) -and
  ($OnlyState -eq "" -or $_.Name.ToLower() -eq $OnlyState.ToLower())
}

foreach ($stateDir in $stateDirs) {
  $abbrev    = $stateDir.Name.ToLower()
  $stateSlug = $stateNames[$abbrev]
  if ($stateSlug -eq "georgia") { Write-Host "SKIP: georgia (hand-curated)"; continue }

  $legDir = Join-Path $stateDir.FullName "legislature"
  if (-not (Test-Path $legDir)) { Write-Host "SKIP: $stateSlug - no legislature/"; continue }

  $personFiles = Get-ChildItem $legDir -Filter "*.yml" -ErrorAction SilentlyContinue
  if ($personFiles.Count -eq 0) { Write-Host "SKIP: $stateSlug - 0 files"; continue }

  $abbrevUpper    = $abbrev.ToUpper()
  $stateTitleName = (Get-Culture).TextInfo.ToTitleCase($stateSlug.Replace("-"," "))
  Write-Host "Processing $stateTitleName ($abbrevUpper) -- $($personFiles.Count) files..."

  $officials  = @()
  $stubsWrit  = 0
  $stubsSkip  = 0
  $stubOutDir = Join-Path $contentDir $stateSlug

  if (-not $DryRun) {
    New-Item -ItemType Directory -Path $dataDir    -Force | Out-Null
    New-Item -ItemType Directory -Path $stubOutDir -Force | Out-Null
  }

  foreach ($file in $personFiles) {
    try {
      $p = Get-Content $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Yaml
    } catch {
      Write-Host "  PARSE ERROR: $($file.Name)"; continue
    }

    $fullName = $p.name
    if (-not $fullName) { continue }

    $party = ""
    if ($p.party -and $p.party.Count -gt 0) {
      $ap = $p.party | Where-Object { -not $_.end_date } | Select-Object -First 1
      $party = if ($ap) { $ap.name } else { $p.party[0].name }
    }

    $chamber = ""; $district = ""
    if ($p.roles -and $p.roles.Count -gt 0) {
      $role = $p.roles | Where-Object {
        ($_.type -eq "upper" -or $_.type -eq "lower") -and (-not $_.end_date)
      } | Select-Object -First 1
      if (-not $role) { $role = $p.roles[0] }
      $chamber  = if ($role.type -eq "upper") { "senate" } else { "house" }
      $district = "$($role.district)"
    }

    $phone = ""; $email = if ($p.email) { $p.email } else { "" }; $address = ""
    if ($p.contact_details -and $p.contact_details.Count -gt 0) {
      $cap = $p.contact_details | Where-Object { $_.note -like "*Capitol*" } | Select-Object -First 1
      $con = if ($cap) { $cap } else { $p.contact_details[0] }
      if ($con.voice)   { $phone   = $con.voice }
      if ($con.address) { $address = ($con.address -replace "`r`n|`n"," ") }
    }

    $officialUrl = ""
    if ($p.links -and $p.links.Count -gt 0) {
      $lnk = $p.links | Where-Object {
        $_.url -notlike "*twitter*" -and $_.url -notlike "*facebook*"
      } | Select-Object -First 1
      if ($lnk) { $officialUrl = $lnk.url }
    }

    $sourceUrls = @()
    if ($p.sources) { $sourceUrls = @($p.sources | ForEach-Object { $_.url }) }

    $photoUrl = if ($p.image)   { $p.image }   else { "" }
    $twitter  = if ($p.twitter) { $p.twitter } else { "" }

    $nameParts  = ($fullName -replace "[^a-zA-Z\s]","").ToLower().Trim() -split "\s+"
    $lastName   = $nameParts[-1]; $firstName = $nameParts[0]
    $chamShort  = if ($chamber.Length -ge 3) { $chamber.Substring(0,3) } else { "leg" }
    $personId   = "$abbrev-$chamShort-$lastName-$firstName"
    if ($personId.Length -gt 60) { $personId = $personId.Substring(0,60) }

    $officeTitle = if ($chamber -eq "senate") { "State Senator" } else { "State Representative" }

    $bioShort = ""
    if ($p.biography) {
      $bioShort = ($p.biography -replace '"',"'" -replace "`r`n|`n"," ")
      if ($bioShort.Length -gt 300) { $bioShort = $bioShort.Substring(0,300) }
    }

    $official = [ordered]@{
      person_id        = $personId
      openstates_id    = "$($p.id)"
      full_name        = $fullName
      office_title     = $officeTitle
      chamber          = $chamber
      district         = $district
      party            = $party
      status           = "active"
      photo_url        = $photoUrl
      phone            = $phone
      email            = $email
      address          = $address
      official_website = $officialUrl
      twitter          = $twitter
      source_urls      = $sourceUrls
      bio_short        = $bioShort
      review_status    = "seeded"
      retrieved_at     = $today
    }
    $officials += $official

    $stubPath = Join-Path $stubOutDir "$personId.md"
    if (Test-Path $stubPath) {
      $stubsSkip++
    } elseif (-not $DryRun) {
      $lines = [System.Collections.Generic.List[string]]::new()
      $lines.Add("---")
      $lines.Add("title: `"$($fullName -replace '"',"'")`"")
      $lines.Add("date: $now")
      $lines.Add("draft: false")
      $lines.Add("type: `"officials`"")
      $lines.Add("")
      $lines.Add("official_id: `"$personId`"")
      $lines.Add("full_name: `"$($fullName -replace '"',"'")`"")
      $lines.Add("state: `"$stateSlug`"")
      $lines.Add("state_abbrev: `"$abbrevUpper`"")
      $lines.Add("office_title: `"$officeTitle`"")
      $lines.Add("chamber: `"$chamber`"")
      $lines.Add("district: `"$district`"")
      $lines.Add("party: `"$party`"")
      $lines.Add("status: `"active`"")
      $lines.Add("official_website: `"$officialUrl`"")
      $lines.Add("email: `"$email`"")
      $lines.Add("phone: `"$($phone -replace '"',"'")`"")
      $lines.Add("review_status: `"seeded`"")
      $lines.Add("retrieved_at: `"$today`"")
      $lines.Add("---")
      $lines.Add("")
      [System.IO.File]::WriteAllLines($stubPath, $lines, [System.Text.UTF8Encoding]::new($false))
      $stubsWrit++
    }
  }

  if (-not $DryRun) {
    $yamlPath = Join-Path $dataDir "$stateSlug.yaml"
    [ordered]@{
      state        = $stateSlug
      state_abbrev = $abbrevUpper
      last_updated = $today
      officials    = $officials
    } | ConvertTo-Yaml | Set-Content -Path $yamlPath -Encoding UTF8
  }

  $summary += [PSCustomObject]@{
    State   = $stateTitleName
    Abbrev  = $abbrevUpper
    Total   = $officials.Count
    Written = $stubsWrit
    Skipped = $stubsSkip
  }
}

Write-Host ""
Write-Host "========= INGEST SUMMARY ========="
$summary | Format-Table -AutoSize
Write-Host "States processed : $($summary.Count)"
Write-Host "Total officials  : $(($summary | Measure-Object -Property Total -Sum).Sum)"
Write-Host "Stubs written    : $(($summary | Measure-Object -Property Written -Sum).Sum)"
