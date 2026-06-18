# Auto-generated client for SchoolDigger API V1 vv1
# Source: https://api.apis.guru/v2/specs/schooldigger.com/v1/swagger.json
# Auth: --token flag or $env.SCHOOLDIGGER_API_V1_TOKEN

const BASE_URL = "https://api.schooldigger.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SCHOOLDIGGER_API_V1_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
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

def base-url-completer [] { ["https://api.schooldigger.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "districts get-list" } } | get name | first)
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

# Returns a list of districts
#
# GET /v1/districts
# operationId: Districts_GetAllDistricts
export def "districts get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --st: string # Two character state (e.g. 'CA') - required
  --q: string # Search term - note: will match district name or city (optional)
  --city: string # Search for districts in this city (optional)
  --zip: string # Search for districts in this 5-digit zip code (optional)
  --near-latitude: float # Search for districts within (distanceMiles) of (nearLatitude)/(nearLongitude) (e.g. 44.982560) (optional) (Pro, Enterprise API levels only. Enterprise API level will flag districts that include lat/long in its attendance boundary.) (format: double)
  --near-longitude: float # Search for districts within (distanceMiles) of (nearLatitude)/(nearLongitude) (e.g. -124.289185) (optional) (Pro, Enterprise API levels only. Enterprise API level will flag districts that include lat/long in its attendance boundary.) (format: double)
  --boundary-address: string # Full U.S. address: flag returned districts that include this address in its attendance boundary. Example: '123 Main St. AnyTown CA 90001' (optional) (Enterprise API level only)
  --distance-miles: int # Search for districts within (distanceMiles) of (nearLatitude)/(nearLongitude) (Default 50 miles) (optional) (Pro, Enterprise API levels only) (format: int32)
  --is-in-boundary-only: oneof<nothing, bool> # Return only the districts that include given location (nearLatitude/nearLongitude) or (boundaryAddress) in its attendance boundary (Enterprise API level only)
  --box-latitude-nw: float # Search for districts within a 'box' defined by (BoxLatitudeNW/BoxLongitudeNW) to (BoxLongitudeSE/BoxLatitudeSE) (optional) (format: double)
  --box-longitude-nw: float # Search for districts within a 'box' defined by (BoxLatitudeNW/BoxLongitudeNW) to (BoxLongitudeSE/BoxLatitudeSE) (optional) (format: double)
  --box-latitude-se: float # Search for districts within a 'box' defined by (BoxLatitudeNW/BoxLongitudeNW) to (BoxLongitudeSE/BoxLatitudeSE) (optional) (format: double)
  --box-longitude-se: float # Search for districts within a 'box' defined by (BoxLatitudeNW/BoxLongitudeNW) to (BoxLongitudeSE/BoxLatitudeSE) (optional) (format: double)
  --page: int # Page number to retrieve (optional, default: 1) (format: int32)
  --per-page: int # Number of districts to retrieve on a page (50 max) (optional, default: 10) (format: int32)
  --sort-by: string # Sort list. Values are: districtname, distance, rank. For descending order, precede with '-' i.e. -districtname (optional, default: districtname)
  --include-unranked-districts-in-rank-sort: oneof<nothing, bool> # If sortBy is 'rank', this boolean determines if districts with no rank are included in the result (optional, default: false)
  --app-id: string # Your API app id
  --app-key: string # Your API app key
]: nothing -> record<districtList: table<address: record, county: record, distance: float, districtID: string, districtName: string, districtYearlyDetails: list, hasBoundary: bool, highGrade: string, isWithinBoundary: bool, locationIsWithinBoundary: bool, lowGrade: string, numberAlternativeSchools: int, numberHighSchools: int, numberMiddleSchools: int, numberPrimarySchools: int, numberTotalSchools: int, phone: string, rankHistory: list, url: string>, numberOfDistricts: int, numberOfPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "st" $st "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "nearLatitude" $near_latitude "scalar") (serialize-qp "nearLongitude" $near_longitude "scalar") (serialize-qp "boundaryAddress" $boundary_address "scalar") (serialize-qp "distanceMiles" $distance_miles "scalar") (serialize-qp "isInBoundaryOnly" $is_in_boundary_only "scalar") (serialize-qp "boxLatitudeNW" $box_latitude_nw "scalar") (serialize-qp "boxLongitudeNW" $box_longitude_nw "scalar") (serialize-qp "boxLatitudeSE" $box_latitude_se "scalar") (serialize-qp "boxLongitudeSE" $box_longitude_se "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $per_page "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "includeUnrankedDistrictsInRankSort" $include_unranked_districts_in_rank_sort "scalar") (serialize-qp "appID" $app_id "scalar") (serialize-qp "appKey" $app_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/districts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a detailed record for one district
#
# GET /v1/districts/{id}
# operationId: Districts_GetDistrict
export def "districts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Your API app id
  --app-key: string # Your API app key
]: nothing -> record<address: record<city: string, cityURL: string, html: string, latLong: record<latitude: float, longitude: float>, state: string, stateFull: string, street: string, zip: string, zip4: string, zipURL: string>, boundary: record<hasBoundary: bool, polylineCollection: list<record>>, county: record<countyName: string, countyURL: string>, districtID: string, districtName: string, districtYearlyDetails: table<numberOfAids: float, numberOfCoordsSupervisors: float, numberOfEnglishLanguageLearnerStudents: int, numberOfGuidanceElem: float, numberOfGuidanceSecondary: float, numberOfGuidanceTotal: float, numberOfLEAAdministrators: float, numberOfLEASupportStaff: float, numberOfLibrarians: float, numberOfLibraryStaff: float, numberOfOtherSupportStaff: float, numberOfSchoolAdminSupportStaff: float, numberOfSchoolAdministrators: float, numberOfSpecialEdStudents: int, numberOfStudentSupportStaff: float, numberOfStudents: int, numberOfTeachers: float, numberOfTeachersElementary: float, numberOfTeachersK: float, numberOfTeachersPK: float, numberOfTeachersSecondary: float, year: int>, highGrade: string, isWithinBoundary: bool, lowGrade: string, numberAlternativeSchools: int, numberHighSchools: int, numberMiddleSchools: int, numberPrimarySchools: int, numberTotalSchools: int, phone: string, rankHistory: table<rank: int, rankOf: int, rankScore: float, rankStars: int, rankStatewidePercentage: float, year: int>, testScores: table<districtTestScore: record, grade: string, schoolTestScore: record, stateTestScore: record, subject: string, test: string, tier1: string, tier2: string, tier3: string, tier4: string, tier5: string, year: int>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appID" $app_id "scalar") (serialize-qp "appKey" $app_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/districts/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a SchoolDigger district ranking list
#
# GET /v1/rankings/districts/{st}
# operationId: Rankings_GetRank_District
export def "rankings-districts get-rank" [
  st: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # The ranking year (leave blank for most recent year) (format: int32)
  --page: int # Page number to retrieve (optional, default: 1) (format: int32)
  --per-page: int # Number of districts to retrieve on a page (50 max) (optional, default: 10) (format: int32)
  --app-id: string # Your API app id
  --app-key: string # Your API app key
]: nothing -> record<districtList: table<address: record, county: record, distance: float, districtID: string, districtName: string, districtYearlyDetails: list, hasBoundary: bool, highGrade: string, isWithinBoundary: bool, locationIsWithinBoundary: bool, lowGrade: string, numberAlternativeSchools: int, numberHighSchools: int, numberMiddleSchools: int, numberPrimarySchools: int, numberTotalSchools: int, phone: string, rankHistory: list, url: string>, numberOfDistricts: int, numberOfPages: int, rankCompareYear: int, rankYear: int, rankYearCompare: int, rankYearsAvailable: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $per_page "scalar") (serialize-qp "appID" $app_id "scalar") (serialize-qp "appKey" $app_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({st: (encode-path-segment $st)} | format pattern "/v1/rankings/districts/{st}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a SchoolDigger school ranking list
#
# GET /v1/rankings/schools/{st}
# operationId: Rankings_GetRank
export def "rankings-schools get-rank" [
  st: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # The ranking year (leave blank for most recent year) (format: int32)
  --level: string # Level of ranking: 'Elementary', 'Middle', or 'High'
  --page: int # Page number to retrieve (optional, default: 1) (format: int32)
  --per-page: int # Number of schools to retrieve on a page (50 max) (optional, default: 10) (format: int32)
  --app-id: string # Your API app id
  --app-key: string # Your API app key
]: nothing -> record<numberOfPages: int, numberOfSchools: int, rankYear: int, rankYearCompare: int, rankYearsAvailable: list<int>, schoolList: table<address: record, county: record, distance: float, district: record, hasBoundary: bool, highGrade: string, isCharterSchool: string, isMagnetSchool: string, isPrivate: bool, isTitleISchool: string, isTitleISchoolwideSchool: string, isVirtualSchool: string, locationIsWithinBoundary: bool, lowGrade: string, phone: string, privateCoed: string, privateDays: int, privateHasLibrary: bool, privateHours: float, privateOrientation: string, rankHistory: list, rankMovement: int, schoolLevel: string, schoolName: string, schoolYearlyDetails: list, schoolid: string, url: string, urlCompare: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "level" $level "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $per_page "scalar") (serialize-qp "appID" $app_id "scalar") (serialize-qp "appKey" $app_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({st: (encode-path-segment $st)} | format pattern "/v1/rankings/schools/{st}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of schools
#
# GET /v1/schools
# operationId: Schools_GetAllSchools
export def "schools get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --st: string # Two character state (e.g. 'CA') - required
  --q: string # Search term - note: will match school name or city (optional)
  --q-search-school-name-only: oneof<nothing, bool> # For parameter 'q', only search school names instead of school and city (optional)
  --district-id: string # Search for schools within this district (7 digit district id) (optional)
  --level: string # Search for schools at this level. Valid values: 'Elementary', 'Middle', 'High', 'Alt', 'Public', 'Private' (optional). 'Public' returns all Elementary, Middle, High and Alternative schools
  --city: string # Search for schools in this city (optional)
  --zip: string # Search for schools in this 5-digit zip code (optional)
  --is-magnet: oneof<nothing, bool> # True = return only magnet schools, False = return only non-magnet schools (optional) (Pro, Enterprise API levels only)
  --is-charter: oneof<nothing, bool> # True = return only charter schools, False = return only non-charter schools (optional) (Pro, Enterprise API levels only)
  --is-virtual: oneof<nothing, bool> # True = return only virtual schools, False = return only non-virtual schools (optional) (Pro, Enterprise API levels only)
  --is-title-i: oneof<nothing, bool> # True = return only Title I schools, False = return only non-Title I schools (optional) (Pro, Enterprise API levels only)
  --is-title-i-schoolwide: oneof<nothing, bool> # True = return only Title I school-wide schools, False = return only non-Title I school-wide schools (optional) (Pro, Enterprise API levels only)
  --near-latitude: float # Search for schools within (distanceMiles) of (nearLatitude)/(nearLongitude) (e.g. 44.982560) (optional) (Pro, Enterprise API levels only. Enterprise API level will flag schools that include lat/long in its attendance boundary.) (format: double)
  --near-longitude: float # Search for schools within (distanceMiles) of (nearLatitude)/(nearLongitude) (e.g. -124.289185) (optional) (Pro, Enterprise API levels only. Enterprise API level will flag schools that include lat/long in its attendance boundary.) (format: double)
  --boundary-address: string # Full U.S. address: flag returned schools that include this address in its attendance boundary. Example: '123 Main St. AnyTown CA 90001' (optional) (Enterprise API level only) IMPORTANT NOTE: If you have the lat/long of the address, use nearLatitude and nearLongitude instead for much faster response times
  --distance-miles: int # Search for schools within (distanceMiles) of (nearLatitude)/(nearLongitude) (Default 5 miles) (optional) (Pro, Enterprise API levels only) (format: int32)
  --is-in-boundary-only: oneof<nothing, bool> # Return only the schools that include given location (nearLatitude/nearLongitude) or (boundaryAddress) in its attendance boundary (Enterprise API level only)
  --box-latitude-nw: float # Search for schools within a 'box' defined by (boxLatitudeNW/boxLongitudeNW) to (boxLongitudeSE/boxLatitudeSE) (optional) (format: double)
  --box-longitude-nw: float # Search for schools within a 'box' defined by (boxLatitudeNW/boxLongitudeNW) to (boxLongitudeSE/boxLatitudeSE) (optional) (format: double)
  --box-latitude-se: float # Search for schools within a 'box' defined by (boxLatitudeNW/boxLongitudeNW) to (boxLongitudeSE/boxLatitudeSE) (optional) (format: double)
  --box-longitude-se: float # Search for schools within a 'box' defined by (boxLatitudeNW/boxLongitudeNW) to (boxLongitudeSE/boxLatitudeSE) (optional) (format: double)
  --page: int # Page number to retrieve (optional, default: 1) (format: int32)
  --per-page: int # Number of schools to retrieve on a page (50 max) (optional, default: 10) (format: int32)
  --sort-by: string # Sort list. Values are: schoolname, distance, rank. For descending order, precede with '-' i.e. -schoolname (optional, default: schoolname)
  --include-unranked-schools-in-rank-sort: oneof<nothing, bool> # If sortBy is 'rank', this boolean determines if schools with no rank are included in the result (optional, default: false)
  --app-id: string # Your API app id
  --app-key: string # Your API app key
]: nothing -> record<numberOfPages: int, numberOfSchools: int, schoolList: table<address: record, county: record, distance: float, district: record, hasBoundary: bool, highGrade: string, isCharterSchool: string, isMagnetSchool: string, isPrivate: bool, isTitleISchool: string, isTitleISchoolwideSchool: string, isVirtualSchool: string, locationIsWithinBoundary: bool, lowGrade: string, phone: string, privateCoed: string, privateDays: int, privateHasLibrary: bool, privateHours: float, privateOrientation: string, rankHistory: list, rankMovement: int, schoolLevel: string, schoolName: string, schoolYearlyDetails: list, schoolid: string, url: string, urlCompare: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "st" $st "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "qSearchSchoolNameOnly" $q_search_school_name_only "scalar") (serialize-qp "districtID" $district_id "scalar") (serialize-qp "level" $level "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "isMagnet" $is_magnet "scalar") (serialize-qp "isCharter" $is_charter "scalar") (serialize-qp "isVirtual" $is_virtual "scalar") (serialize-qp "isTitleI" $is_title_i "scalar") (serialize-qp "isTitleISchoolwide" $is_title_i_schoolwide "scalar") (serialize-qp "nearLatitude" $near_latitude "scalar") (serialize-qp "nearLongitude" $near_longitude "scalar") (serialize-qp "boundaryAddress" $boundary_address "scalar") (serialize-qp "distanceMiles" $distance_miles "scalar") (serialize-qp "isInBoundaryOnly" $is_in_boundary_only "scalar") (serialize-qp "boxLatitudeNW" $box_latitude_nw "scalar") (serialize-qp "boxLongitudeNW" $box_longitude_nw "scalar") (serialize-qp "boxLatitudeSE" $box_latitude_se "scalar") (serialize-qp "boxLongitudeSE" $box_longitude_se "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $per_page "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "includeUnrankedSchoolsInRankSort" $include_unranked_schools_in_rank_sort "scalar") (serialize-qp "appID" $app_id "scalar") (serialize-qp "appKey" $app_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/schools" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a detailed record for one school
#
# GET /v1/schools/{id}
# operationId: Schools_GetSchool10
export def "schools get-school10" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Your API app id
  --app-key: string # Your API app key
]: nothing -> record<address: record<city: string, cityURL: string, html: string, latLong: record<latitude: float, longitude: float>, state: string, stateFull: string, street: string, zip: string, zip4: string, zipURL: string>, boundary: record<hasBoundary: bool, polylineCollection: list<record>>, county: record<countyName: string, countyURL: string>, district: record<districtID: string, districtName: string, rankURL: string, url: string>, highGrade: string, isCharterSchool: string, isMagnetSchool: string, isPrivate: bool, isTitleISchool: string, isTitleISchoolwideSchool: string, isVirtualSchool: string, locale: string, lowGrade: string, phone: string, privateCoed: string, privateDays: int, privateHasLibrary: bool, privateHours: float, privateOrientation: string, rankHistory: table<averageStandardScore: float, rank: int, rankLevel: string, rankOf: int, rankStars: int, rankStatewidePercentage: float, year: int>, rankMovement: int, schoolLevel: string, schoolName: string, schoolYearlyDetails: table<numberOfStudents: int, numberofAfricanAmericanStudents: int, numberofAsianStudents: int, numberofHispanicStudents: int, numberofIndianStudents: int, numberofPacificIslanderStudents: int, numberofTwoOrMoreRaceStudents: int, numberofUnspecifiedRaceStudents: int, numberofWhiteStudents: int, percentFreeDiscLunch: float, percentofAfricanAmericanStudents: float, percentofAsianStudents: float, percentofHispanicStudents: float, percentofIndianStudents: float, percentofPacificIslanderStudents: float, percentofTwoOrMoreRaceStudents: float, percentofUnspecifiedRaceStudents: float, percentofWhiteStudents: float, pupilTeacherRatio: float, teachersFulltime: float, year: int>, schoolid: string, testScores: table<districtTestScore: record, grade: string, schoolTestScore: record, stateTestScore: record, subject: string, test: string, tier1: string, tier2: string, tier3: string, tier4: string, tier5: string, year: int>, url: string, urlCompare: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appID" $app_id "scalar") (serialize-qp "appKey" $app_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/schools/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
