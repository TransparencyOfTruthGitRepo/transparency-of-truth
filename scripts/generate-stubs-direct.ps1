$stateSlug = "georgia"
$stateAbbrev = "GA"
$today = Get-Date -Format "yyyy-MM-dd"
$now = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"

$officials = @(
  @{ pid="ga-gov-kemp-brian"; name="Brian Kemp"; office="Governor"; chamber="executive"; party="Republican"; phone="(404) 656-1776"; website="https://gov.georgia.gov"; status="active" },
  @{ pid="ga-ltgov-jones-burt"; name="Burt Jones"; office="Lieutenant Governor"; chamber="executive"; party="Republican"; phone="(404) 656-5030"; website="https://ltgov.georgia.gov"; status="active" },
  @{ pid="ga-ag-carr-chris"; name="Chris Carr"; office="Attorney General"; chamber="executive"; party="Republican"; phone="(404) 656-3300"; website="https://law.georgia.gov"; status="active" },
  @{ pid="ga-sos-raffensperger-brad"; name="Brad Raffensperger"; office="Secretary of State"; chamber="executive"; party="Republican"; phone="(404) 656-2881"; website="https://sos.ga.gov"; status="active" },
  @{ pid="ga-sfr-scott-gary"; name="Gary Black"; office="Commissioner of Agriculture"; chamber="executive"; party="Republican"; phone="(404) 656-3600"; website="https://agr.georgia.gov"; status="active" },
  @{ pid="ga-ins-hudgens-ralph"; name="John King"; office="Commissioner of Insurance"; chamber="executive"; party="Republican"; phone="(404) 656-2070"; website="https://oci.georgia.gov"; status="active" },
  @{ pid="ga-labor-butler-bruce"; name="Bruce Thompson"; office="Commissioner of Labor"; chamber="executive"; party="Republican"; phone="(404) 656-3011"; website="https://dol.georgia.gov"; status="active" },
  @{ pid="ga-sen-president-jones-burt"; name="Burt Jones"; office="President of the Senate"; chamber="senate"; party="Republican"; phone="(404) 656-5030"; website="https://www.senate.ga.gov"; status="active" },
  @{ pid="ga-sen-pro-tem-miller-blake"; name="Blake Tillery"; office="Senate President Pro Tempore"; chamber="senate"; party="Republican"; phone="(404) 656-0089"; website="https://www.senate.ga.gov"; status="active" },
  @{ pid="ga-sen-majority-leader"; name="Steve Gooch"; office="Senate Majority Leader"; chamber="senate"; party="Republican"; phone="(404) 656-9221"; website="https://www.senate.ga.gov"; status="active" },
  @{ pid="ga-sen-minority-leader"; name="Gloria Butler"; office="Senate Minority Leader"; chamber="senate"; party="Democrat"; phone="(404) 463-8053"; website="https://www.senate.ga.gov"; status="active" },
  @{ pid="ga-house-speaker-burns-jon"; name="Jon Burns"; office="Speaker of the House"; chamber="house"; party="Republican"; phone="(404) 656-5020"; website="https://www.house.ga.gov"; status="active" },
  @{ pid="ga-house-speaker-pro-tem"; name="Jan Jones"; office="Speaker Pro Tempore"; chamber="house"; party="Republican"; phone="(404) 656-5072"; website="https://www.house.ga.gov"; status="active" },
  @{ pid="ga-house-majority-leader"; name="Chuck Efstration"; office="House Majority Leader"; chamber="house"; party="Republican"; phone="(404) 656-5943"; website="https://www.house.ga.gov"; status="active" },
  @{ pid="ga-house-minority-leader"; name="Carolyn Hugley"; office="House Minority Leader"; chamber="house"; party="Democrat"; phone="(404) 656-6372"; website="https://www.house.ga.gov"; status="active" }
)

$outDir = "content\officials\$stateSlug"
if (-not (Test-Path $outDir)) {
  New-Item -ItemType Directory -Path $outDir | Out-Null
  Write-Host "Created $outDir"
}

foreach ($o in $officials) {
  $dest = "$outDir\$($o.pid).md"
  if (Test-Path $dest) { Write-Host "SKIP: $dest"; continue }

  $content = "---`ntitle: `"$($o.name)`"`ndate: $now`ndraft: false`ntype: `"officials`"`n`nofficial_id: `"$($o.pid)`"`nfull_name: `"$($o.name)`"`nsort_name: `"`"`nphoto_url: `"`"`n`nstate: `"$stateSlug`"`nstate_abbrev: `"$stateAbbrev`"`njurisdiction_level: `"state`"`njurisdiction_name: `"State of Georgia`"`noffice_title: `"$($o.office)`"`nchamber: `"$($o.chamber)`"`ndistrict: `"`"`nparty: `"$($o.party)`"`nstatus: `"$($o.status)`"`n`nofficial_website: `"$($o.website)`"`noffice_page_url: `"$($o.website)`"`nemail: `"`"`nphone: `"$($o.phone)`"`naddress: `"`"`n`nsource_ids: []`ndocument_ids: []`nlast_verified: `"`"`nretrieved_at: `"$today`"`nreview_status: `"source-confirmed`"`n`nbio_short: `"`"`nbio_long: `"`"`ncommittees: []`nnotes: `"`"`n---`n"

  Set-Content -Path $dest -Value $content -Encoding UTF8
  Write-Host "CREATED: $dest"
}

Write-Host "`nDone. $($officials.Count) stubs processed."