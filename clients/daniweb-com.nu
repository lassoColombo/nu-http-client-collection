# Auto-generated client for DaniWeb Connect API v4
# Source: https://api.apis.guru/v2/specs/daniweb.com/4/openapi.json
# Auth: --token flag or $env.DANIWEB_CONNECT_API_TOKEN

const BASE_URL = "https://www.daniweb.com/connect/api/v4"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DANIWEB_CONNECT_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = ($name | url encode)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[($in.k | into string | url encode)]=($in.v | into string | url encode)" }) }
  if not $is_list { return [$"($n)=($value | into string | url encode)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
    "csv" => { let joined = ($value | each { $in | into string | url encode } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string | url encode } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string | url encode } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string | url encode } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=($v | into string | url encode)" } }
    _ => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
  }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "put" => { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "patch" => { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status == 204 { null } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else { $resp.body }
}

def base-url-completer [] { ["https://www.daniweb.com/connect/api/v4"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-completer [] { ["asc" "desc"] }
def filter-completer [] { ["introductions" "new" "notifications" "unreplied"] }
def metadata-0-privacy-completer [] { ["Bubbled" "Private" "Public" "User"] }
def metadata-1-privacy-completer [] { ["Bubbled" "Private" "Public" "User"] }
def metadata-2-privacy-completer [] { ["Bubbled" "Private" "Public" "User"] }
def privacy-completer [] { ["Private" "Public" "Unlisted"] }
def category-completer [] { ["Affiliations" "Awards" "Education" "Experience" "Portfolio"] }
def organization-size-completer [] { ["10 - 49 Employees" "100 - 499 Employees" "1000 - 4999 Employees" "2 - 9 Employees" "50 - 99 Employees" "500 - 999 Employees" "5000+ Employees" "Don't Know" "Self-employed"] }
def position-completer [] { ["Executive Management (C-level)" "IT Consultant" "Manager / Director / Supervisor" "Other non-technology related" "Other technology related" "Retired" "Sales" "Software Development" "Student" "Systems Development" "Technical Support" "VP-level Executive" "Web Developer"] }
def filter-completer-1 [] { ["connections" "matches" "muted" "skipped"] }
def order-by-completer [] { ["first_name" "id" "industry" "last_activity" "last_name"] }
def company-size-completer [] { ["10 - 49 Employees" "100 - 499 Employees" "1000 - 4999 Employees" "2 - 9 Employees" "50 - 99 Employees" "500 - 999 Employees" "5000+ Employees" "Don't Know" "Self-employed"] }
def goals-completer [] { ["Find a co-founder" "Find a job" "Find business partnerships" "Find prospective clients" "Hire employees" "Mentor others" "Receive mentorship from others"] }
def industry-completer [] { ["Accounting" "Airlines/Aviation" "Alternative Dispute Resolution" "Alternative Medicine" "Animation" "Apparel & Fashion" "Architecture & Planning" "Arts and Crafts" "Automotive" "Aviation & Aerospace" "Banking" "Biotechnology" "Broadcast Media" "Building Materials" "Business Supplies and Equipment" "Capital Markets" "Chemicals" "Civic & Social Organization" "Civil Engineering" "Commercial Real Estate" "Computer & Network Security" "Computer Games" "Computer Hardware" "Computer Networking" "Computer Software" "Construction" "Consumer Electronics" "Consumer Goods" "Consumer Services" "Cosmetics" "Dairy" "Defense & Space" "Design" "E-Learning" "Education Management" "Electrical/Electronic Manufacturing" "Entertainment" "Environmental Services" "Events Services" "Executive Office" "Facilities Services" "Farming" "Financial Services" "Fine Art" "Fishery" "Food & Beverages" "Food Production" "Fund-Raising" "Furniture" "Gambling & Casinos" "Glass, Ceramics & Concrete" "Government Administration" "Government Relations" "Graphic Design" "Health, Wellness and Fitness" "Higher Education" "Hospital & Health Care" "Hospitality" "Human Resources" "Import and Export" "Individual & Family Services" "Industrial Automation" "Information Services" "Information Technology and Services" "Insurance" "International Affairs" "International Trade and Development" "Internet" "Investment Banking" "Investment Management" "Judiciary" "Law Enforcement" "Law Practice" "Legal Services" "Legislative Office" "Leisure, Travel & Tourism" "Libraries" "Logistics and Supply Chain" "Luxury Goods & Jewelry" "Machinery" "Management Consulting" "Maritime" "Market Research" "Marketing and Advertising" "Mechanical or Industrial Engineering" "Media Production" "Medical Devices" "Medical Practice" "Mental Health Care" "Military" "Mining & Metals" "Motion Pictures and Film" "Museums and Institutions" "Music" "Nanotechnology" "Newspapers" "Non-Profit Organization Management" "Oil & Energy" "Online Media" "Outsourcing/Offshoring" "Package/Freight Delivery" "Packaging and Containers" "Paper & Forest Products" "Performing Arts" "Pharmaceuticals" "Philanthropy" "Photography" "Plastics" "Political Organization" "Primary/Secondary Education" "Printing" "Professional Training & Coaching" "Program Development" "Public Policy" "Public Relations and Communications" "Public Safety" "Publishing" "Railroad Manufacture" "Ranching" "Real Estate" "Recreational Facilities and Services" "Religious Institutions" "Renewables & Environment" "Research" "Restaurants" "Retail" "Security and Investigations" "Semiconductors" "Shipbuilding" "Sporting Goods" "Sports" "Staffing and Recruiting" "Supermarkets" "Telecommunications" "Textiles" "Think Tanks" "Tobacco" "Translation and Localization" "Transportation/Trucking/Railroad" "Utilities" "Venture Capital & Private Equity" "Veterinary" "Warehousing" "Wholesale" "Wine and Spirits" "Wireless" "Writing and Editing"] }
def job-position-completer [] { ["Executive Management (C-level)" "IT Consultant" "Manager / Director / Supervisor" "Other non-technology related" "Other technology related" "Retired" "Sales" "Software Development" "Student" "Systems Development" "Technical Support" "VP-level Executive" "Web Developer"] }
def location-importance-completer [] { ["No" "Somewhat" "Yes"] }
def targeted-industry-completer [] { ["Accounting" "Airlines/Aviation" "Alternative Dispute Resolution" "Alternative Medicine" "Animation" "Apparel & Fashion" "Architecture & Planning" "Arts and Crafts" "Automotive" "Aviation & Aerospace" "Banking" "Biotechnology" "Broadcast Media" "Building Materials" "Business Supplies and Equipment" "Capital Markets" "Chemicals" "Civic & Social Organization" "Civil Engineering" "Commercial Real Estate" "Computer & Network Security" "Computer Games" "Computer Hardware" "Computer Networking" "Computer Software" "Construction" "Consumer Electronics" "Consumer Goods" "Consumer Services" "Cosmetics" "Dairy" "Defense & Space" "Design" "E-Learning" "Education Management" "Electrical/Electronic Manufacturing" "Entertainment" "Environmental Services" "Events Services" "Executive Office" "Facilities Services" "Farming" "Financial Services" "Fine Art" "Fishery" "Food & Beverages" "Food Production" "Fund-Raising" "Furniture" "Gambling & Casinos" "Glass, Ceramics & Concrete" "Government Administration" "Government Relations" "Graphic Design" "Health, Wellness and Fitness" "Higher Education" "Hospital & Health Care" "Hospitality" "Human Resources" "Import and Export" "Individual & Family Services" "Industrial Automation" "Information Services" "Information Technology and Services" "Insurance" "International Affairs" "International Trade and Development" "Internet" "Investment Banking" "Investment Management" "Judiciary" "Law Enforcement" "Law Practice" "Legal Services" "Legislative Office" "Leisure, Travel & Tourism" "Libraries" "Logistics and Supply Chain" "Luxury Goods & Jewelry" "Machinery" "Management Consulting" "Maritime" "Market Research" "Marketing and Advertising" "Mechanical or Industrial Engineering" "Media Production" "Medical Devices" "Medical Practice" "Mental Health Care" "Military" "Mining & Metals" "Motion Pictures and Film" "Museums and Institutions" "Music" "Nanotechnology" "Newspapers" "Non-Profit Organization Management" "Oil & Energy" "Online Media" "Outsourcing/Offshoring" "Package/Freight Delivery" "Packaging and Containers" "Paper & Forest Products" "Performing Arts" "Pharmaceuticals" "Philanthropy" "Photography" "Plastics" "Political Organization" "Primary/Secondary Education" "Printing" "Professional Training & Coaching" "Program Development" "Public Policy" "Public Relations and Communications" "Public Safety" "Publishing" "Railroad Manufacture" "Ranching" "Real Estate" "Recreational Facilities and Services" "Religious Institutions" "Renewables & Environment" "Research" "Restaurants" "Retail" "Security and Investigations" "Semiconductors" "Shipbuilding" "Sporting Goods" "Sports" "Staffing and Recruiting" "Supermarkets" "Telecommunications" "Textiles" "Think Tanks" "Tobacco" "Translation and Localization" "Transportation/Trucking/Railroad" "Utilities" "Venture Capital & Private Equity" "Veterinary" "Warehousing" "Wholesale" "Wine and Spirits" "Wireless" "Writing and Editing"] }
def event-completer [] { ["conversation_message" "conversation_seen" "group_message" "group_seen" "group_update" "user_online" "user_update"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "apps list" } } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name not-in [$mod_name "commands"] | get decl_id)
  scope commands | where decl_id in $cmd_ids | each {|cmd|
    let sig = $cmd.signatures | values | first
    let params = $sig
      | where parameter_type not-in ["input" "output"]
      | where parameter_name not-in $builtin_flags
      | select parameter_name parameter_type syntax_shape is_optional description
    let return_type = ($sig | where parameter_type == "output" | get -o syntax_shape | first | default "any")
    {
      name: ($cmd.name | str replace $"($mod_name) " "")
      description: $cmd.description
      extra_description: $cmd.extra_description
      return_type: $return_type
      params: $params
    }
  }
}

# Fetch all Daniapps that are currently in production mode.
#
# GET /apps
export def "apps list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> record<data: table<about: record, id: float, legal: record>, pagination: record<limit: float, offset: float, total_records: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an array of Daniapps that are currently in production mode.
#
# GET /apps/{ID}
export def "apps get" [
  ID: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<about: record, id: float, legal: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($ID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch all Daniapp audience segments that comprise the current access token's bubble.
#
# GET /audiences
export def "audiences list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> record<data: table<about: record, id: float>, pagination: record<limit: float, offset: float, total_records: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/audiences" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an array of Daniapp audience segments that comprise the current access token's bubble.
#
# GET /audiences/{ID}
export def "audiences get" [
  ID: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<about: record, id: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/audiences/($ID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a membership record for the OAuth'ed end-user based on the current audience segment/bubble combination.
#
# POST /audiences/{ID}/memberships
export def "audiences-memberships post" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<audience: record<id: float>, member: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/audiences/($ID)/memberships")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an array of names and locations, filtered by category, that begin with the query string passed in. Ideally used for search autocomplete dropdowns, as the search functionality filters against name and location. The four potential categories are: `conversations` for names of users you are in existing conversations with; `matches` for names of users you have previously skipped over; `people` for names of all other users; `locations` for locations of users. Only users and their locations who exist with the current access token's bubble are considered.
#
# GET /autocompletes
export def "autocompletes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # allows empty value
]: nothing -> record<data: record<conversations: list<string>, locations: list<string>, matches: list<string>, people: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/autocompletes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Paginated report of information about messages contributed by conversation and date. Only conversations that exist within the current access token's bubble are considered in the calculations. Optionally roll up all conversations to retrieve one record per date. Optionally specify a date formatted as YYYY-MM-DD to retrieve information just from the single date, along with additional navigational information, which is useful when generating a transcript for a single day and wanting to reference the previous and next days there were messages.
#
# POST /conversations/schedules
export def "conversations-schedules post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --roll-up: oneof<nothing, bool> # default: false
  --body-sort: string@sort-completer # default: desc
]: any -> record<data: table<author_count: float, conversation_count: float, conversation_id: float, date: string, first_message: record, last_message: record, message_count: float, my_message_count: float, navigation: record>, pagination: record<limit: float, offset: float, total_records: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations/schedules")
  let body = {date: $date, limit: $limit, offset: $offset, roll_up: $roll_up, sort: $body_sort} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Fetch messages authored from within the current bubble that match a query string passed in as a search parameter along with their relevancy score.
#
# POST /conversations/searches
export def "conversations-searches post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string
  --gt-message-id: int # format: int32
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  query: string
]: any -> record<data: table<message: record, relevance: record>, pagination: record<limit: float, offset: float, total_records: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations/searches")
  let body = {date: $date, gt_message_id: $gt_message_id, limit: $limit, offset: $offset, query: $query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve conversations that you are participating in with users who exists within the same bubble, along with your current relationship with the conversations. The user_a / user_b properties of the conversation are populated with as much data as is available if the user is not you. If the user is you, only the id field is populated. There is a separate status endpoint to retrieve relationship information for individual conversations. Optionally filter: 'new' to only show conversations with messages you haven't yet seen; 'introductions' to only show conversations where users have introduced themselves to you but nothing more; 'unreplied' to only show conversations where you have introduced yourself to other users but nothing more; 'notifications' to show all conversations where the other user was the last person to message. Optionally only show conversations engaging within the existing access token's bubble. This report is limited to your ~500-1000 most recently active conversations you've engaged in within current the access token's bubble.
#
# GET /conversations/statuses
export def "conversations-statuses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer # allows empty value
  --include-archived: oneof<nothing, bool> # default: false, allows empty value
  --bubbled: oneof<nothing, bool> # default: false, allows empty value
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> record<data: table<archived_status: bool, bubbled: record, conversation: record, earliest_unseen_message: record, new_message_count: float>, pagination: record<limit: float, offset: float, total_records: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "include_archived" $include_archived "scalar") (serialize-qp "bubbled" $bubbled "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversations/statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an array of conversations. You can only retrieve conversations with users who exist within the current access token's bubble.
#
# GET /conversations/{ID}
export def "conversations get" [
  ID: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<first_message: record, id: float, latest_message: record, user_a: record, user_b: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/($ID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the last {limit} messages in the conversation, provided the conversations exist within the current access token's bubble. If a timeout is 0 or greater, the batch is sorted oldest first. Otherwise, if timeout is a negative number, the transcript is paginated and sorted newest first. Specify a timeout for long polling (which delays the server sending back results for up to n seconds or until results are available, whichever comes first), or default to 0 for immediate results. Optionally record your status as online along with sharing the latest message you've seen with the other conversation participant. Optionally specify a gt_message_id to retrieve only messages with an ID greater than that specified (such as greater than the latest message ID received in the last poll). Optionally only poll for messages authored by the other person in the conversation, and echo messages authored by you when sending, for a perceived increase in performance. Optionally only retrieve messages that were posted from within the current access token's bubble. Optionally specify a date formatted as YYYY-MM-DD to retrieve a transcript of messages from a single day. When record_seen is set to true, the new message count for the conversation is reset to zero.
#
# GET /conversations/{ID}/messages
export def "conversations-messages get" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --gt-message-id: int # format: int32, allows empty value
  --exclude-self: oneof<nothing, bool> # default: false, allows empty value
  --date: string # allows empty value
  --bubbled: oneof<nothing, bool> # default: false, allows empty value
  --record-seen: oneof<nothing, bool> # default: false, allows empty value
  --timeout: int # format: int32, default: 0, allows empty value
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> record<data: table<author: record, conversation: record, id: float, last_seen: record, text: record, timestamp: string>, pagination: record<limit: float, offset: float, total_records: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gt_message_id" $gt_message_id "scalar") (serialize-qp "exclude_self" $exclude_self "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "bubbled" $bubbled "scalar") (serialize-qp "record_seen" $record_seen "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/conversations/($ID)/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Post a message to a conversation that is with a user who exists within the current access token's bubble. Optionally specify whether emoticons should be parsed into smiley images. Optionally specify whether the message should be bubbled within the app. Additionally, optionally attach a single metadata key/value pair to the message upon submission.
#
# POST /conversations/{ID}/messages
export def "conversations-messages post" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bubbled: oneof<nothing, bool> # default: false
  --metadata-0-key: string
  --metadata-0-privacy: string@metadata-0-privacy-completer
  --metadata-0-values: list
  --metadata-1-key: string
  --metadata-1-privacy: string@metadata-1-privacy-completer
  --metadata-1-values: list
  --metadata-2-key: string
  --metadata-2-privacy: string@metadata-2-privacy-completer
  --metadata-2-values: list
  --text-emoticons: oneof<nothing, bool> # default: false
  text_raw: string
]: any -> record<data: record<author: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>, conversation: record<first_message: record, id: float, latest_message: any, user_a: record, user_b: record>, id: float, last_seen: record<timestamp: string, user: record>, text: record<parsed: string>, timestamp: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/($ID)/messages")
  let body = {bubbled: $bubbled, metadata_0_key: $metadata_0_key, metadata_0_privacy: $metadata_0_privacy, metadata_0_values[]: $metadata_0_values, metadata_1_key: $metadata_1_key, metadata_1_privacy: $metadata_1_privacy, metadata_1_values[]: $metadata_1_values, metadata_2_key: $metadata_2_key, metadata_2_privacy: $metadata_2_privacy, metadata_2_values[]: $metadata_2_values, text_emoticons: $text_emoticons, text_raw: $text_raw} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Paginated report of information about messages contributed by conversation and date. Only conversations that exist within the current access token's bubble are considered in the calculations. Optionally roll up all conversations to retrieve one record per date. Optionally specify a date formatted as YYYY-MM-DD to retrieve information just from the single date, along with additional navigational information, which is useful when generating a transcript for a single day and wanting to reference the previous and next days there were messages within the conversation(s).
#
# POST /conversations/{ID}/schedules
export def "conversations-schedules post-by-ID" [
  ID: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --roll-up: oneof<nothing, bool> # default: false
  --body-sort: string@sort-completer # default: desc
]: any -> record<data: table<author_count: float, conversation_count: float, conversation_id: float, date: string, first_message: record, last_message: record, message_count: float, my_message_count: float, navigation: record>, pagination: record<limit: float, offset: float, total_records: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/($ID)/schedules")
  let body = {date: $date, limit: $limit, offset: $offset, roll_up: $roll_up, sort: $body_sort} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Fetch messages authored from within specified conversations that match a query string passed in as a search parameter along with their relevancy score.
#
# POST /conversations/{ID}/searches
export def "conversations-searches post-by-ID" [
  ID: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string
  --gt-message-id: int # format: int32
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  query: string
]: any -> record<data: table<message: record, relevance: record>, pagination: record<limit: float, offset: float, total_records: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/($ID)/searches")
  let body = {date: $date, gt_message_id: $gt_message_id, limit: $limit, offset: $offset, query: $query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Status information about your current relationship with one or more conversations you participating in, provided the conversations exist within the current access token's bubble.
#
# GET /conversations/{ID}/statuses
export def "conversations-statuses get" [
  ID: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<archived_status: bool, bubbled: record, conversation: record, earliest_unseen_message: record, new_message_count: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/($ID)/statuses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Archive or unarchive a conversation that is with a user who exists within the same bubble.
#
# PATCH /conversations/{ID}/statuses
export def "conversations-statuses patch" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --archived-status: oneof<nothing, bool>
]: any -> record<data: record<archived_status: bool, conversation: record<first_message: record, id: float, latest_message: record, user_a: record, user_b: record>>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/($ID)/statuses")
  let body = {archived_status: $archived_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Fetch an array of all groups that were created by users existing within the current access token's bubble. The groups must be either Public or you must be a member of them. Unlisted and Private groups that you are not a member of are not listed.
#
# GET /groups
export def "groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> record<data: table<first_message: record, id: float, latest_message: record, member_count: float, owner: record, properties: record>, pagination: record<limit: float, offset: float, total_records: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new group for other members to join. Any user who is using an access token whose bubble you exist in can join your group provided it is not a private group. Private groups can only be joined by members who know its passphrase. Unlisted groups can be joined by anybody as long as they know the Group ID, but they are not referenced anywhere to non-members. Public groups can be joined by anybody, are discoverable, and anyone can see the public groups a user is a member of, provided the group owner exists in their access token's bubble. Groups each have their own discussions, transcripts, schedules, and ability to list and search their members.
#
# POST /groups
export def "groups post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string
  name: string
  --passphrase: string
  privacy: string@privacy-completer
  slug: string
]: any -> record<data: record<first_message: record<timestamp: string>, id: float, latest_message: record<author: record, group: any, id: float, last_seen: record, moderated: record, text: record, timestamp: string>, member_count: float, owner: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>, properties: record<description: string, name: string, privacy: string, slug: string>>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups")
  let body = {description: $description, name: $name, passphrase: $passphrase, privacy: $privacy, slug: $slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Paginated listing of messages filtered by arbitrary metadata criteria. Messages must match on all key/value pairs passed in. Messages may only match on one value of an array passed in. However, messages are sorted based on how many distinct values they match on (most matches first).
#
# POST /groups/messages/metadata/filters
export def "groups-messages-metadata-filters post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int32, default: 50
  --metadata-0-key: string
  --metadata-0-values: list
  --metadata-1-key: string
  --metadata-1-values: list
  --metadata-2-key: string
  --metadata-2-values: list
  --offset: int # format: int32, default: 0
]: any -> record<data: table<matched_metadata: record, message: record>, pagination: record<limit: float, offset: float, total_records: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups/messages/metadata/filters")
  let body = {limit: $limit, metadata_0_key: $metadata_0_key, metadata_0_values[]: $metadata_0_values, metadata_1_key: $metadata_1_key, metadata_1_values[]: $metadata_1_values, metadata_2_key: $metadata_2_key, metadata_2_values[]: $metadata_2_values, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Delete an array of group messages. You must be the owner or moderator of the group.
#
# DELETE /groups/messages/{ID}
export def "groups-messages delete" [
  ID: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<author: record, group: record, id: float, last_seen: record, moderated: record, text: record, timestamp: string>, status: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/messages/($ID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an array of group messages. You can only retrieve messages authored by you or by users existing within the current access token's bubble.
#
# GET /groups/messages/{ID}
export def "groups-messages get-by-ID" [
  ID: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<author: record, group: record, id: float, last_seen: record, moderated: record, text: record, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/messages/($ID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all key/value pairs attached to the current message that you have access to, so long as the user who created the group exists within the current access token's bubble. This includes all public metadata, bubbled metadata that was created by an access token existing within the current bubble, user metadata that was created by you, or private metadata created by you from an access token existing within the current bubble.
#
# GET /groups/messages/{ID}/metadata
export def "groups-messages-metadata get" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> record<data: table<app: record, content: record, id: float, message: record, owner: record, settings: record, status: record>, pagination: record<limit: float, offset: float, total_records: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/messages/($ID)/metadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attach one-to-many key/value pairs of metadata to a group message, so long as the user who authored the message exists within the current access token's bubble and you are a member of their group. A key is unique for each author/bubble combination. Attaching metadata with an existing key that was previously created by you, from within the same bubble, overwrites the key with the new value or set of values. The privacy setting allows you to specify who will have access to the metadata: Public metadata by anyone using an access token which grants them access to the user who authored the message and who is also a member of the group the message belongs to; Bubbled metadata by anyone using an access token existing within the current bubble who is also a member of the group the message belongs to; User metadata by you, so long as you are using an access token which grants you access to the user who authored the message and you remain a member of the group; Private metadata by you, so long as you are using an access token existing within the current bubble and you remain a member of the group.
#
# POST /groups/messages/{ID}/metadata
export def "groups-messages-metadata post" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata-0-key: string
  --metadata-0-privacy: string@metadata-0-privacy-completer
  --metadata-0-values: list
  --metadata-1-key: string
  --metadata-1-privacy: string@metadata-1-privacy-completer
  --metadata-1-values: list
  --metadata-2-key: string
  --metadata-2-privacy: string@metadata-2-privacy-completer
  --metadata-2-values: list
]: any -> record<data: record, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/messages/($ID)/metadata")
  let body = {metadata_0_key: $metadata_0_key, metadata_0_privacy: $metadata_0_privacy, metadata_0_values[]: $metadata_0_values, metadata_1_key: $metadata_1_key, metadata_1_privacy: $metadata_1_privacy, metadata_1_values[]: $metadata_1_values, metadata_2_key: $metadata_2_key, metadata_2_privacy: $metadata_2_privacy, metadata_2_values[]: $metadata_2_values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve all key/value pairs attached to the current message that you have access to, so long as the user who created the group exists within the current access token's bubble. This includes all public metadata, bubbled metadata that was created by an access token existing within the current bubble, user metadata that was created by you, or private metadata created by you from an access token existing within the current bubble. Metadata will be grouped by key.
#
# GET /groups/messages/{ID}/metadata/collections
export def "groups-messages-metadata-collections get" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/messages/($ID)/metadata/collections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Paginated report of information about messages contributed by group and date. Only groups you're a member of and group messages authored by users the current access token has access to are considered in the calculations. Optionally roll up all groups to retrieve one record per date. Optionally specify a date formatted as YYYY-MM-DD to retrieve information just from the single date, along with additional navigational information, which is useful when generating a transcript for a single day and wanting to reference the previous and next days there were messages.
#
# POST /groups/schedules
export def "groups-schedules post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --roll-up: oneof<nothing, bool> # default: false
  --body-sort: string@sort-completer # default: desc
]: any -> record<data: table<author_count: float, date: string, first_message: record, group_count: float, group_id: float, last_message: record, message_count: float, my_message_count: float, navigation: record>, pagination: record<limit: float, offset: float, total_records: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups/schedules")
  let body = {date: $date, limit: $limit, offset: $offset, roll_up: $roll_up, sort: $body_sort} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve groups that were created by users within the current access token's bubble, along with your current relationship with the groups. The groups must be either Public or you must be a member of them. Unlisted and Private groups that you are not a member of are not listed. Optionally only retrieve groups that you are a member of.
#
# GET /groups/statuses
export def "groups-statuses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --existing-membership: oneof<nothing, bool> # default: false, allows empty value
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> record<data: table<earliest_unseen_message: record, group: record, new_message_count: float>, pagination: record<limit: float, offset: float, total_records: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "existing_membership" $existing_membership "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups/statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an array of groups. You can only retrieve groups created by users existing within the current access token's bubble.
#
# GET /groups/{ID}
export def "groups get" [
  ID: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<first_message: record, id: float, latest_message: record, member_count: float, owner: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($ID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a group you previously created.
#
# PATCH /groups/{ID}
export def "groups patch" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --name: string
  --passphrase: string
  --privacy: string@privacy-completer
  --slug: string
]: any -> record<data: record<first_message: record<timestamp: string>, id: float, latest_message: record<author: record, group: any, id: float, last_seen: record, moderated: record, text: record, timestamp: string>, member_count: float, owner: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>, properties: record<description: string, name: string, privacy: string, slug: string>>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($ID)")
  let body = {description: $description, name: $name, passphrase: $passphrase, privacy: $privacy, slug: $slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Leave a group that you are a member of and that was created by a user who exists within the current access token's bubble.
#
# DELETE /groups/{ID}/memberships
export def "groups-memberships delete" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($ID)/memberships")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an array of users who are members of specific groups that you are also a member of. You can only retrieve users existing within the current access token's bubble.
#
# GET /groups/{ID}/memberships
export def "groups-memberships get" [
  ID: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --moderators-only: oneof<nothing, bool> # default: false, allows empty value
  --offset: int # format: int32, default: 0, allows empty value
]: nothing -> record<data: table<group: record, member: record, privileges: record>, pagination: record<limit: float, offset: float, total_records: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "moderators_only" $moderators_only "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($ID)/memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Promote or demote a member's privileges within a group that you created. The user must exist within the current access token's bubble and be an existing member of the group.
#
# PATCH /groups/{ID}/memberships
export def "groups-memberships patch" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --moderator: oneof<nothing, bool> # default: false
  user_id: int # format: int32
]: any -> record<data: table<group: record, member: record, privileges: record>, pagination: record<limit: float, offset: float, total_records: float>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($ID)/memberships")
  let body = {moderator: $moderator, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Join a group that was created by a user who exists within the current access token's bubble, or join other users into a group that you created. If you are the group owner, you can pass in a user_id to create membership records for a user you are in a conversation with. The user must exist within the current access token's bubble. If the group is private, you must successfully pass in its passphrase in order to join. You can obtain the passphrase from the group's owner.
#
# POST /groups/{ID}/memberships
export def "groups-memberships post" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --passphrase: string
  --user-id: int # format: int32
]: any -> record<data: record<group: record<first_message: record, id: float, latest_message: record, member_count: float, owner: record, properties: record>, member: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($ID)/memberships")
  let body = {passphrase: $passphrase, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve the last {limit} messages in the group, for messages authored by users within the current access token's bubble. If a timeout is 0 or greater, the batch is sorted oldest first. Otherwise, if timeout is a negative number, the transcript is paginated and sorted newest first. Specify a timeout for long polling (which delays the server sending back results for up to n seconds or until results are available, whichever comes first), or default to 0 for immediate results. Optionally record your status as online along with sharing the latest message you've seen with other group members. Optionally specify a gt_message_id to retrieve only messages with an ID greater than that specified (such as greater than the latest message ID received in the last poll). Optionally only poll for messages authored by other members of the group, and echo messages authored by you when sending, for a perceived increase in performance. Optionally only retrieve messages that were posted from within the current access token's bubble. Optionally specify a date formatted as YYYY-MM-DD to retrieve a transcript of messages from a single day. When record_seen is set to true, the new message count for the group is reset to zero.
#
# GET /groups/{ID}/messages
export def "groups-messages get-by-ID-1" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --gt-message-id: int # format: int32, allows empty value
  --exclude-self: oneof<nothing, bool> # default: false, allows empty value
  --include-deleted: oneof<nothing, bool> # default: false, allows empty value
  --date: string # allows empty value
  --bubbled: oneof<nothing, bool> # default: false, allows empty value
  --record-seen: oneof<nothing, bool> # default: false, allows empty value
  --timeout: int # format: int32, default: 0, allows empty value
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> record<data: table<author: record, group: record, id: float, last_seen: record, moderated: record, text: record, timestamp: string>, pagination: record<limit: float, offset: float, total_records: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gt_message_id" $gt_message_id "scalar") (serialize-qp "exclude_self" $exclude_self "scalar") (serialize-qp "include_deleted" $include_deleted "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "bubbled" $bubbled "scalar") (serialize-qp "record_seen" $record_seen "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($ID)/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Post a message to a group that you are a member of and that was created by a user who exists within the current access token's bubble. Optionally specify whether emoticons should be parsed into smiley images. Additionally, optionally attach a single metadata key/value pair to the group message upon submission.
#
# POST /groups/{ID}/messages
export def "groups-messages post" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata-0-key: string
  --metadata-0-privacy: string@metadata-0-privacy-completer
  --metadata-0-values: list
  --metadata-1-key: string
  --metadata-1-privacy: string@metadata-1-privacy-completer
  --metadata-1-values: list
  --metadata-2-key: string
  --metadata-2-privacy: string@metadata-2-privacy-completer
  --metadata-2-values: list
  --text-emoticons: oneof<nothing, bool> # default: false
  text_raw: string
]: any -> record<data: table<author: record, group: record, id: float, last_seen: record, moderated: record, text: record, timestamp: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($ID)/messages")
  let body = {metadata_0_key: $metadata_0_key, metadata_0_privacy: $metadata_0_privacy, metadata_0_values[]: $metadata_0_values, metadata_1_key: $metadata_1_key, metadata_1_privacy: $metadata_1_privacy, metadata_1_values[]: $metadata_1_values, metadata_2_key: $metadata_2_key, metadata_2_privacy: $metadata_2_privacy, metadata_2_values[]: $metadata_2_values, text_emoticons: $text_emoticons, text_raw: $text_raw} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Paginated report of information about group messages contributed by conversation and date. Only groups you're a member of and group messages authored by users existing within the current access token's bubble are considered in the calculations. Optionally roll up all groups to retrieve one record per date. Optionally specify a date formatted as YYYY-MM-DD to retrieve information just from the single date, along with additional navigational information, which is useful when generating a transcript for a single day and wanting to reference the previous and next days there were messages within the group discussion(s).
#
# POST /groups/{ID}/schedules
export def "groups-schedules post-by-ID" [
  ID: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --roll-up: oneof<nothing, bool> # default: false
  --body-sort: string@sort-completer # default: desc
]: any -> record<data: table<author_count: float, date: string, first_message: record, group_count: float, group_id: float, last_message: record, message_count: float, my_message_count: float, navigation: record>, pagination: record<limit: float, offset: float, total_records: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($ID)/schedules")
  let body = {date: $date, limit: $limit, offset: $offset, roll_up: $roll_up, sort: $body_sort} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Status information about your current relationship with one or more groups you are a member of, provided the users who created the groups exist within the current access token's bubble.
#
# GET /groups/{ID}/statuses
export def "groups-statuses get" [
  ID: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<earliest_unseen_message: record, group: record, membership_status: bool, new_message_count: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($ID)/statuses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /industries
export def "industries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/industries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /markdown
export def "markdown post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text-emoticons: oneof<nothing, bool> # default: false
  text_raw: string
]: any -> record<data: record<parsed: string, raw: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/markdown")
  let body = {text_emoticons: $text_emoticons, text_raw: $text_raw} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# GET /markdown/emoticons
export def "markdown-emoticons get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<alt: string, emoticon: string, image: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/markdown/emoticons")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Paginated listing of messages filtered by arbitrary metadata criteria. Messages must match on all key/value pairs passed in. Messages may only match on one value of an array passed in. However, messages are sorted based on how many distinct values they match on (most matches first).
#
# POST /messages/metadata/filters
export def "messages-metadata-filters post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int32, default: 50
  --metadata-0-key: string
  --metadata-0-values: list
  --metadata-1-key: string
  --metadata-1-values: list
  --metadata-2-key: string
  --metadata-2-values: list
  --offset: int # format: int32, default: 0
]: any -> record<data: table<matched_metadata: record, message: record>, pagination: record<limit: float, offset: float, total_records: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/messages/metadata/filters")
  let body = {limit: $limit, metadata_0_key: $metadata_0_key, metadata_0_values[]: $metadata_0_values, metadata_1_key: $metadata_1_key, metadata_1_values[]: $metadata_1_values, metadata_2_key: $metadata_2_key, metadata_2_values[]: $metadata_2_values, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Fetch an array of messages. You can only retrieve messages authored by you or by users who exist within the current access token's bubble.
#
# GET /messages/{ID}
export def "messages get" [
  ID: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<author: record, conversation: record, id: float, last_seen: record, text: record, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/messages/($ID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all key/value pairs attached to the current message that you have access to, so long as the user who authored the message exists within the current access token's bubble. This includes all public metadata, bubbled metadata that was created by an access token existing within the current bubble, user metadata that was created by you, or private metadata created by you from an access token existing within the current bubble.
#
# GET /messages/{ID}/metadata
export def "messages-metadata get" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> record<data: table<app: record, content: record, id: float, message: record, owner: record, settings: record, status: record>, pagination: record<limit: float, offset: float, total_records: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/messages/($ID)/metadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attach one-to-many key/value pairs of metadata to a message, so long as the user who authored the message exists within the current access token's bubble. A key is unique for each author/bubble combination. Attaching metadata with an existing key that was previously created by you, from within the same bubble, overwrites the key with the new value or set of values. The privacy setting allows you to specify who will have access to the metadata: Public metadata by you or the other user in the message's conversation, using an access token which grants you access to the user who authored the message, if it wasn't you; Bubbled metadata by you or the other user in the message's conversation, using an access token existing within the current bubble; User metadata by you, so long as you are using an access token which grants you access to the user who authored the message, if it wasn't you; Private metadata by you, so long as you are using an access token existing within the current bubble.
#
# POST /messages/{ID}/metadata
export def "messages-metadata post" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata-0-key: string
  --metadata-0-privacy: string@metadata-0-privacy-completer
  --metadata-0-values: list
  --metadata-1-key: string
  --metadata-1-privacy: string@metadata-1-privacy-completer
  --metadata-1-values: list
  --metadata-2-key: string
  --metadata-2-privacy: string@metadata-2-privacy-completer
  --metadata-2-values: list
]: any -> record<data: record, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/messages/($ID)/metadata")
  let body = {metadata_0_key: $metadata_0_key, metadata_0_privacy: $metadata_0_privacy, metadata_0_values[]: $metadata_0_values, metadata_1_key: $metadata_1_key, metadata_1_privacy: $metadata_1_privacy, metadata_1_values[]: $metadata_1_values, metadata_2_key: $metadata_2_key, metadata_2_privacy: $metadata_2_privacy, metadata_2_values[]: $metadata_2_values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve all key/value pairs attached to the current message that you have access to, so long as the user who authored the message exists within the current access token's bubble. This includes all public metadata, bubbled metadata that was created by an access token existing within the current bubble, user metadata that was created by you, or private metadata created by you from an access token existing within the current bubble. Metadata will be grouped by key.
#
# GET /messages/{ID}/metadata/collections
export def "messages-metadata-collections get" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/messages/($ID)/metadata/collections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the OAuth'ed end user's Curriculum Vitae by adding a position.
#
# POST /positions
export def "positions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  category: string@category-completer
  --end-date: string
  organization: string
  --organization-size: string@organization-size-completer
  --position: string@position-completer
  role: string
  start_date: string
  --summary: string
  --body-url: string
]: any -> record<data: record<app: record<about: record, id: float, legal: record>, category: string, id: float, organization: record<industry: string, name: string, size: string, ticker: string, type: string, url: string>, role: record<end_date: string, start_date: string, summary: string, title: string>, user: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/positions")
  let body = {category: $category, end_date: $end_date, organization: $organization, organization_size: $organization_size, position: $position, role: $role, start_date: $start_date, summary: $summary, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Remove an item from the OAuth'ed end user's Curriculum Vitae.
#
# DELETE /positions/{ID}
export def "positions delete" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/positions/($ID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the OAuth'ed end user's Curriculum Vitae by modifying an existing position.
#
# PATCH /positions/{ID}
export def "positions patch" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  category: string@category-completer
  --end-date: string
  organization: string
  --organization-size: string@organization-size-completer
  --position: string@position-completer
  role: string
  start_date: string
  --summary: string
  --body-url: string
]: any -> record<data: record<app: record<about: record, id: float, legal: record>, category: string, id: float, organization: record<industry: string, name: string, size: string, ticker: string, type: string, url: string>, role: record<end_date: string, start_date: string, summary: string, title: string>, user: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/positions/($ID)")
  let body = {category: $category, end_date: $end_date, organization: $organization, organization_size: $organization_size, position: $position, role: $role, start_date: $start_date, summary: $summary, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Fetch an array of users that you've been matched with, connected with, skipped, or muted. You can only retrieve users existing within the current access token's bubble. This report may be limited to the last ~500-1000 users you've communicated with within the access token's bubble. Matches are always ordered by synergy, and the order_by parameter is ignored. You can only retrieve bubbled users when retrieving matches, and the bubbled parameter is ignored otherwise. Your 100 best algorithmic matches are based on: Complementary data submitted to Profiles, CVs, and Metadata; Complementary data acquired from third-parties; Location information; Many behavioral data points, such as how responsive users are to connections; Degrees of separation (mutual connections); etc. You may connect with 3 of these algorithmic matches per day for free. However, new members are allowed a grace period of additional daily matches. Each time you choose to meet or mute one of your algorithmic matches, a new match is introduced.
#
# GET /users
export def "users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-1 # default: connections, allows empty value
  --order-by: string@order-by-completer # default: id, allows empty value
  --bubbled: oneof<nothing, bool> # default: false, allows empty value
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> record<data: table<business_card: record, community_persona: record, id: float, profile: record, usage: record>, pagination: record<limit: float, offset: float, total_records: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "bubbled" $bubbled "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invite users to into your current access token's bubble by having Dazah send out email invitations on your behalf. The invitation sends users to begin the OAuth flow for the current application (based on the settings specified in the application's profile), and therefore they will be redirected to the application upon signing up / logging in. Upon doing so, if they aren't already, they will automatically be connected with you as well. If your current access token does not escape the bubble, the invitation will specify you wish to connect within the application's name. If your current access token escapes the bubble, the invitation will specify you wish to connect within Dazah. Submit either a list of emails, or a LinkedIn or Outlook CSV file. You can retrieve your LinkedIn CSV file by exporting your LinkedIn Connections at https://www.linkedin.com/people/export-settings. You can retrieve your Outlook CSV file by using the Outlook Import and Export Wizard. This endpoint buckets the invitations into four categories: Existing invites are existing users who are already connected with you within the current bubble, and are therefore not emailed; Discovered invites are existing Dazah users who are available to be connected with within the current bubble, and are therefore not emailed. Now that they have been discovered, the users/{:ID}/meet API endpoint may be used to connect with them; Invalid invites are existing Dazah users who are unavailable to be connected with, because they have deactivated accounts, are muting you, etc., and are therefore not emailed; Emailed invites are queued to receive an invitation within approximately 1 hour. Note that if you are attempting to invite an existing Dazah user who does not currently exist within your current access token's bubble, they will fall within the Discovered bucket if your current access token escapes the bubble, but will be emailed an invitation to join the application if your current access token does not escape the bubble.
#
# POST /users/invites
export def "users-invites post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --csv: string # format: binary
  --emails: list
]: any -> record<data: record<discovered: record<users: list>, emailed: record<emails: list>, existing: record<conversations: list>, invalid: record<emails: list>>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/invites")
  let body = {csv: $csv, emails[]: $emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Paginated listing of users filtered by arbitrary metadata criteria. Users must match on all key/value pairs passed in. Users may only match on one value of an array passed in. However, users are sorted based on how many distinct values they match on (most matches first).
#
# POST /users/metadata/filters
export def "users-metadata-filters post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int32, default: 50
  --metadata-0-key: string
  --metadata-0-values: list
  --metadata-1-key: string
  --metadata-1-values: list
  --metadata-2-key: string
  --metadata-2-values: list
  --offset: int # format: int32, default: 0
]: any -> record<data: table<matched_metadata: record, user: record>, pagination: record<limit: float, offset: float, total_records: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/metadata/filters")
  let body = {limit: $limit, metadata_0_key: $metadata_0_key, metadata_0_values[]: $metadata_0_values, metadata_1_key: $metadata_1_key, metadata_1_values[]: $metadata_1_values, metadata_2_key: $metadata_2_key, metadata_2_values[]: $metadata_2_values, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Fetch an array of users that are geographically close to a set of coordinates. You can only retrieve users existing within the current access token's bubble.
#
# GET /users/nearby
export def "users-nearby get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --latitude: float # format: float, allows empty value
  --longitude: float # format: float, allows empty value
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> record<data: table<distance_away: record, user: record>, pagination: record<limit: float, offset: float, total_records: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/nearby" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Filter and perform a weighted search against user profile fields, CV fields, and metadata by specifying a string to search on for each individual field. By default, results are filtered such that all words in the string must exist, unless you seprate the words with OR. To perform a weighted search (as opposed to filtering), specify the weight (from 0-100) the search algorithm should assign to the field. You can optionally exclude users who you are already in or not in conversations with, exclude users who you previously skipped, or exclude users who you are muting. By doing so, you can effectively customize your own matching algorithm. You can specify geo coordinates to only find users a certain distance away from a specific location, or only find users within a certain distance from the OAuth'ed end-user's last known location. If your app utilizes multiple audience segments, you can specify which audiences you would like to search. You can also limit users to just those who have been recently active. You can also choose to only receive users originating from the current access token's bubble. Only users existing within the current access token's bubble will be matched, and you can only search within a group created by a bubbled user.
#
# POST /users/searches
export def "users-searches post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active-within-x-days: int # format: int32
  --audience-ids: list
  --bubbled: oneof<nothing, bool> # default: false
  --exclude-connections: oneof<nothing, bool> # default: false
  --exclude-matches: oneof<nothing, bool> # default: false
  --exclude-muted: oneof<nothing, bool> # default: false
  --exclude-skipped: oneof<nothing, bool> # default: false
  --geo-latitude: float # format: float
  --geo-longitude: float # format: float
  --geo-miles-away: float # format: float
  --group-id: int # format: int32
  --limit: int # format: int32, default: 50
  --location-city-query: string
  --location-city-weight: int # format: int32
  --location-country-query: string
  --location-country-weight: int # format: int32
  --location-region-query: string
  --location-region-weight: int # format: int32
  --metadata-0-key: string
  --metadata-0-query: string
  --metadata-0-weight: int # format: int32
  --metadata-1-key: string
  --metadata-1-query: string
  --metadata-1-weight: int # format: int32
  --metadata-2-key: string
  --metadata-2-query: string
  --metadata-2-weight: int # format: int32
  --offset: int # format: int32, default: 0
  --position-organization-query: string
  --position-organization-weight: int # format: int32
  --position-role-query: string
  --position-role-weight: int # format: int32
  --position-summary-query: string
  --position-summary-weight: int # format: int32
  --profile-first-name-query: string
  --profile-first-name-weight: int # format: int32
  --profile-goals-query: string
  --profile-goals-weight: string
  --profile-headline-query: string
  --profile-headline-weight: int # format: int32
  --profile-industry-query: string
  --profile-industry-weight: int # format: int32
  --profile-last-name-query: string
  --profile-last-name-weight: int # format: int32
  --profile-pitch-query: string
  --profile-pitch-weight: int # format: int32
]: any -> record<data: table<relevance: record, user: record>, pagination: record<limit: float, offset: float, total_records: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/searches")
  let body = {active_within_x_days: $active_within_x_days, audience_ids[]: $audience_ids, bubbled: $bubbled, exclude_connections: $exclude_connections, exclude_matches: $exclude_matches, exclude_muted: $exclude_muted, exclude_skipped: $exclude_skipped, geo_latitude: $geo_latitude, geo_longitude: $geo_longitude, geo_miles_away: $geo_miles_away, group_id: $group_id, limit: $limit, location_city_query: $location_city_query, location_city_weight: $location_city_weight, location_country_query: $location_country_query, location_country_weight: $location_country_weight, location_region_query: $location_region_query, location_region_weight: $location_region_weight, metadata_0_key: $metadata_0_key, metadata_0_query: $metadata_0_query, metadata_0_weight: $metadata_0_weight, metadata_1_key: $metadata_1_key, metadata_1_query: $metadata_1_query, metadata_1_weight: $metadata_1_weight, metadata_2_key: $metadata_2_key, metadata_2_query: $metadata_2_query, metadata_2_weight: $metadata_2_weight, offset: $offset, position_organization_query: $position_organization_query, position_organization_weight: $position_organization_weight, position_role_query: $position_role_query, position_role_weight: $position_role_weight, position_summary_query: $position_summary_query, position_summary_weight: $position_summary_weight, profile_first_name_query: $profile_first_name_query, profile_first_name_weight: $profile_first_name_weight, profile_goals_query: $profile_goals_query, profile_goals_weight: $profile_goals_weight, profile_headline_query: $profile_headline_query, profile_headline_weight: $profile_headline_weight, profile_industry_query: $profile_industry_query, profile_industry_weight: $profile_industry_weight, profile_last_name_query: $profile_last_name_query, profile_last_name_weight: $profile_last_name_weight, profile_pitch_query: $profile_pitch_query, profile_pitch_weight: $profile_pitch_weight} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Fetch an array of users. You can only retrieve users existing within the current access token's bubble.
#
# GET /users/{ID}
export def "users get-by-ID" [
  ID: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<business_card: record, community_persona: record, id: float, profile: record, usage: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($ID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# You can only retrieve groups that were created by users existing within the current access token's bubble.
#
# GET /users/{ID}/groups
export def "users-groups get" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<first_message: record, id: float, latest_message: record, member_count: float, owner: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($ID)/groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Paginated transcript of group messages authored by an individual user who exists within the current access token's bubble. Messages are sorted oldest to newest.
#
# GET /users/{ID}/groups/messages
export def "users-groups-messages get" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> record<data: table<author: record, group: record, id: float, last_seen: record, moderated: record, text: record, timestamp: string>, pagination: record<limit: float, offset: float, total_records: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($ID)/groups/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initiate a conversation with a user who exists within the current access token's bubble by sending them an introductory message. If you aren't already in a conversation with them, this endpoint meets them first, and then sends the message. Note that if you aren't in an existing conversation, you still must meet the criteria to meet them, meaning the user must currently be free for you to meet. You will receive an error message unless it is currently free for you to meet the user. You can use the users/{:IDS}/synergies endpoint to first determine if the user isn't already in a conversation with you and is free for you to meet and, if they aren't, how to pay to meet them. If you don't specify a message, it defaults to your custom introductory message defined in your settings.
#
# POST /users/{ID}/messages
export def "users-messages post" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bubbled: oneof<nothing, bool> # default: false
  --metadata-0-key: string
  --metadata-0-privacy: string@metadata-0-privacy-completer
  --metadata-0-values: list
  --metadata-1-key: string
  --metadata-1-privacy: string@metadata-1-privacy-completer
  --metadata-1-values: list
  --metadata-2-key: string
  --metadata-2-privacy: string@metadata-2-privacy-completer
  --metadata-2-values: list
  --text-emoticons: oneof<nothing, bool> # default: false
  --text-raw: string
]: any -> record<data: record<author: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>, conversation: record<first_message: record, id: float, latest_message: any, user_a: record, user_b: record>, id: float, last_seen: record<timestamp: string, user: record>, text: record<parsed: string>, timestamp: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($ID)/messages")
  let body = {bubbled: $bubbled, metadata_0_key: $metadata_0_key, metadata_0_privacy: $metadata_0_privacy, metadata_0_values[]: $metadata_0_values, metadata_1_key: $metadata_1_key, metadata_1_privacy: $metadata_1_privacy, metadata_1_values[]: $metadata_1_values, metadata_2_key: $metadata_2_key, metadata_2_privacy: $metadata_2_privacy, metadata_2_values[]: $metadata_2_values, text_emoticons: $text_emoticons, text_raw: $text_raw} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve all key/value pairs attached to the current user that you have access to, so long as the user exists within the current access token's bubble. This includes all public metadata, bubbled metadata that was created by an access token existing within the current bubble, user metadata that was created by you, or private metadata created by you from an access token existing within the current bubble. You will receive an error message unless either the current access token is bubbled, the user is an algorithmic match for you and you have not reached your quota of new introductions for the day, or you have paid to meet them. However, you can always use the /users/metadata/filters endpoint to filter across all users, including those that are unmatched, existing within the current access token's bubble based on preknown metadata key/value pairs.
#
# GET /users/{ID}/metadata
export def "users-metadata get" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> record<data: table<app: record, content: record, id: float, owner: record, settings: record, status: record, user: record>, pagination: record<limit: float, offset: float, total_records: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($ID)/metadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attach one-to-many key/value pairs of metadata to a user, so long as the user exists within the current access token's bubble. You can set one key at a time, with one or many values. A key is unique for each author/bubble combination. Attaching metadata with an existing key that was previously created by you, from within the same bubble, overwrites the key with the new value or set of values. The privacy setting allows you to specify who will have access to the metadata: Public metadata by anyone using an access token which grants them access to the user; Bubbled metadata by anyone using an access token existing within the current bubble; User metadata by you, so long as you are using an access token which grants you access to the user; Private metadata by you, so long as you are using an access token existing within the current bubble.
#
# POST /users/{ID}/metadata
export def "users-metadata post" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata-0-key: string
  --metadata-0-privacy: string@metadata-0-privacy-completer
  --metadata-0-values: list
  --metadata-1-key: string
  --metadata-1-privacy: string@metadata-1-privacy-completer
  --metadata-1-values: list
  --metadata-2-key: string
  --metadata-2-privacy: string@metadata-2-privacy-completer
  --metadata-2-values: list
]: any -> record<data: record, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($ID)/metadata")
  let body = {metadata_0_key: $metadata_0_key, metadata_0_privacy: $metadata_0_privacy, metadata_0_values[]: $metadata_0_values, metadata_1_key: $metadata_1_key, metadata_1_privacy: $metadata_1_privacy, metadata_1_values[]: $metadata_1_values, metadata_2_key: $metadata_2_key, metadata_2_privacy: $metadata_2_privacy, metadata_2_values[]: $metadata_2_values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve all key/value pairs attached to the current user that you have access to, so long as the user exists within the current access token's bubble. This includes all public metadata, bubbled metadata that was created by an access token existing within the current bubble, user metadata that was created by you, or private metadata created by you from an access token existing within the current bubble. You will receive an error message unless either the current access token is bubbled, the user is an algorithmic match for you and you have not reached your quota of new introductions for the day, or you have paid to meet them. However, you can always use the /users/metadata/filters endpoint to filter across all users, including those that are unmatched, existing within the current access token's bubble based on preknown metadata key/value pairs. Metadata will be grouped by key.
#
# GET /users/{ID}/metadata/collections
export def "users-metadata-collections get" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($ID)/metadata/collections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the CV of a user who exists within the current access token's bubble. You will receive an error message unless either the current access token is bubbled, the user is an algorithmic match for you and you have not reached your quota of new introductions for the day, or you have paid to meet them. You can only record CV data to your own account. However, any app that you have OAuth'ed against can do so. By default, you will receive CV data that all apps have recorded for the user. Optionally, you can choose to only receive data that the current access token's bubble has recorded.
#
# GET /users/{ID}/positions
export def "users-positions get" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bubbled: oneof<nothing, bool> # default: false, allows empty value
]: nothing -> record<data: table<app: record, category: string, id: float, organization: record, role: record, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bubbled" $bubbled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($ID)/positions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Determine your match relationship with one or more users who exist within the current access token's bubble. Under some conditions, the price to meet the user will be $0. However, if this is not the case, the PayPal URL payment method will be provided along with the price to meet the user. The PayPal API can be leveraged to send payments programatically, provided the parameters passed in remain the same to ensure that the payment is correctly recorded. Once the payment has been recorded via PayPal IPN, the price to meet the user changes to $0. You can then call the users/{:ID}/meet endpoint to meet the user.
#
# GET /users/{ID}/synergies
export def "users-synergies get" [
  ID: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<additional: record, conversation: record, match: record, meet: record, relationship: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($ID)/synergies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Skip, mute or unmute a user you've been matched with. Skipped matches are only presented as algorithmic matches after all other candidates have been exhausted. You cannot be matched with or meet muted users. You can only skip, mute or unmute users existing within the same bubble.
#
# PATCH /users/{ID}/synergies
export def "users-synergies patch" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --relationship-muted: oneof<nothing, bool>
  --relationship-skipped: oneof<nothing, bool>
]: any -> record<data: record<relationship: record<muted: bool, skipped: bool>>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($ID)/synergies")
  let body = {relationship_muted: $relationship_muted, relationship_skipped: $relationship_skipped} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve the currently OAuth'ed end-user, based on the access token being used, including private information and settings such as their email address.
#
# GET /users/~
export def "users get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<business_card: record<company_name: string, company_size: string, headline: string, industry: string, interest_tags: list, job_position: string, summary: string, website: record>, community_persona: record<id: float, identity: record, location: record, personal: record, signature: record, stats: record>, id: float, location: record<city: string, country: float, ip_address: string, latitude: string, longitude: string, region: string>, matching: record<goals: list, interest_tags: list, location_importance: string, targeted_industry: string>, profile: record<first_name: string, introduction: string, last_name: string>, settings: record<email: string, email_verified: bool, notifications: string, timezone: float>, usage: record<available_status: bool, joined_timestamp: string, last_activity_timestamp: string, online_status: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/~")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the OAuth'ed end user's account profile. At this time, for anti-spam reasons, restrictions preclude the ability to update email address and some other settings via the API.
#
# PATCH /users/~
export def "users patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --company: string
  --company-size: string@company-size-completer
  --first-name: string
  --goals: list@goals-completer
  --headline: string
  --industry: string@industry-completer
  --introduction: string
  --job-position: string@job-position-completer
  --last-name: string
  --location-importance: string@location-importance-completer
  --match-tags: list
  --pitch: string
  --tags: list
  --targeted-industry: string@targeted-industry-completer
  --body-url: string
]: any -> record<data: record<business_card: record<company_name: string, company_size: string, headline: string, industry: string, interest_tags: list, job_position: string, summary: string, website: record>, community_persona: record<id: float, identity: record, location: record, personal: record, signature: record, stats: record>, id: float, location: record<city: string, country: float, ip_address: string, latitude: string, longitude: string, region: string>, matching: record<goals: list, interest_tags: list, location_importance: string, targeted_industry: string>, profile: record<first_name: string, introduction: string, last_name: string>, settings: record<email: string, email_verified: bool, notifications: string, timezone: float>, usage: record<available_status: bool, joined_timestamp: string, last_activity_timestamp: string, online_status: bool>>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/~")
  let body = {company: $company, company_size: $company_size, first_name: $first_name, goals[]: $goals, headline: $headline, industry: $industry, introduction: $introduction, job_position: $job_position, last_name: $last_name, location_importance: $location_importance, match_tags[]: $match_tags, pitch: $pitch, tags[]: $tags, targeted_industry: $targeted_industry, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Fetch a listing of all webhooks owned by the current user/bubble combination.
#
# GET /webhooks
export def "webhooks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<app: record, event: record, id: float, name: string, object: record, uri: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register a new webhook for the current user/bubble combination. Specify an object_id to only be notified on an event related to that specific Conversation ID, Group ID, or User ID. Your access token must have access to the user being tracked, user you are in the conversation with, or user who created the group. You must be connected with a user in order to keep track of their online status. Alternatively, do not specify an object_id to be notified on all events that are related to conversations you're in, groups you're a member of, or users you are in conversations with. You may only have one webhook for each object_id/event. The webhook URI must reside on your own server. Webhooks do not expire when the access token used to create them expires. However, they will temporarily cease to function if the user who created them deauthorizes access to the application (effectively no longer existing within the bubble), unless/until the user reauthorizes the application using OAuth.
#
# POST /webhooks
export def "webhooks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bubbled: oneof<nothing, bool> # default: false
  event: string@event-completer
  name: string
  --object-id: int # format: int32
  uri: string
]: any -> record<data: record<app: record<about: record, id: float, legal: record>, event: record<action: string>, id: float, name: string, object: record<id: float, type: string>, uri: string, user: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let body = {bubbled: $bubbled, event: $event, name: $name, object_id: $object_id, uri: $uri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Delete a webhook that was previously registered by the current user/bubble combination.
#
# DELETE /webhooks/{ID}
export def "webhooks delete" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($ID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
