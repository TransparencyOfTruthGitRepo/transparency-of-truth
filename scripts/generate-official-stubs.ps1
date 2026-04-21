        $content = @"
---
title: "$($official.full_name)"
date: $(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
draft: false
type: "officials"

official_id: "$pid"
full_name: "$($official.full_name)"
sort_name: ""
photo_url: ""

state: "$stateSlug"
state_abbrev: "$($data.state_abbrev)"
jurisdiction_level: "state"
jurisdiction_name: "State of $((Get-Culture).TextInfo.ToTitleCase($data.state))"
office_title: "$($official.office_title)"
chamber: "$($official.chamber)"
district: "$($official.district)"
party: "$($official.party)"
status: "$($official.status)"

official_website: "$($official.official_website)"
office_page_url: "$($official.office_page_url)"
email: ""
phone: "$($official.phone)"
address: ""

source_ids: []
document_ids: []
last_verified: ""
retrieved_at: "$(Get-Date -Format "yyyy-MM-dd")"
review_status: "$($official.review_status)"

bio_short: "$($official.bio_short)"
bio_long: ""
committees: []
notes: ""
---
"@