# Auto-generated client for SimplyRETS v1.0.0
# Source: https://api.apis.guru/v2/specs/simplyrets.com/1.0.0/swagger.json
# Auth: --token flag or $env.SIMPLYRETS_TOKEN

const BASE_URL = "https://api.simplyrets.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SIMPLYRETS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
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

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://api.simplyrets.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def type-completer [] { ["commercial" "condominium" "farm" "land" "multifamily" "rental" "residential"] }
def sort-completer [] { ["-baths" "-beds" "-listdate" "-listprice" "baths" "beds" "listdate" "listprice"] }
def accept-completer [] { ["application/json" "application/vnd.simplyrets-v0.1+json"] }
def status-completer [] { ["Active" "ActiveUnderContract" "Closed" "ComingSoon" "Delete" "Expired" "Hold" "Incomplete" "Pending" "Withdrawn"] }
def subtype-completer [] { ["apartment" "boatslip" "cabin" "condominium" "deededparking" "duplex" "manufacturedhome" "manufacturedonland" "ownyourown" "quadruplex" "singlefamilyresidence" "stockcooperative" "timeshare" "townhouse" "triplex"] }
def include-completer [] { ["agreement" "association" "garageSpaces" "maintenanceExpense" "parking" "pool" "rooms" "taxAnnualAmount" "taxYear"] }
def include-completer-1 [] { ["agreement" "association" "garageSpaces" "maintenanceExpense" "parking" "pool" "rooms"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "openhouses list" } } | get name | first)
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

# The SimplyRETS OpenHouses API
#
# GET /openhouses
export def "openhouses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer # Request listings by a specific property type. This defaults to Residential, and you can only specify one type in a single query.
  --listing-id: string # Request openhouses for a specific `listingId`.
  --cities: list<string> # Filter the openhouses returned by a list of valid cities. The `cities` query parameter is case-insensitive. The list of `cities` provided by your RETS vendor can be seen by sending an `OPTIONS` request to the `/properties` endpoint: `curl -XOPTIONS -u simplyrets:simplyrets https://api.simplyrets.com/openhouses`
  --brokers: list<string> # Filter the listings returned by brokerage with a Broker ID. You can specific multiple broker parameters. Note, the Broker ID is provided by your MLS.
  --agent: string # Filter the listings returned by an agent ID. Note, the Agent ID is provided by your MLS.
  --minprice: int # Filter listings by a minimum price.
  --startdate: string # Scheduled date and time of the open house showing (format: date-time)
  --offset: int # Increase the offset parameter by the limit to go to the next "page" of listings. Also take a look at the Link HTTP Header for pre-built pagination. *NOTE:* Use the `lastId` parameter for pagination.
  --last-id: int # Used as a cursor for pagination.
  --limit: int # Set the number of listings to return in the response. This defaults to 20 listings, and can be a maximum of 500. To paginate through to the next page of listings, take a look at the `offset` parameter, or the Link in the HTTP Header.
  --qp-sort: string@sort-completer # Sort the response by a specific field. Values starting with a minus (-) denote descending order, while the others are ascending.
  --include: list<string> # Include a extra fields which are not in the default response body - 'association' includes additional HOA data - 'agreement' information on the listing agreement - 'garageSpaces' additional garage data - 'maintenanceExpense' data on maintenance expenses - 'parking' additional parking data - 'pool' includes an additional pool description - 'taxAnnualAmount' include the annual tax amount - 'taxYear' include the tax year data - 'rooms' include parameter will include any additional rooms as a list. Note that your MLS must provide these fields in their RETS data for them to be available in the API response. In the future, fields which require an 'include' may become available by default.
]: nothing -> table<description: string, endTime: string, inputId: any, listing: record<address: record, agent: record, association: record, coAgent: record, disclaimer: string, geo: record, leaseTerm: string, leaseType: string, listDate: string, listPrice: float, listingId: string, mls: record, mlsId: int, modified: string, office: record, photos: list, privateRemarks: string, property: record, remarks: string, sales: record, school: record, showingInstructions: string, tax: record, virtualTourUrl: string>, openHouseId: string, openHouseKey: string, refreshments: string, startTime: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "listingId" $listing_id "scalar") (serialize-qp "cities" $cities "multi") (serialize-qp "brokers" $brokers "multi") (serialize-qp "agent" $agent "scalar") (serialize-qp "minprice" $minprice "scalar") (serialize-qp "startdate" $startdate "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "lastId" $last_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/openhouses" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"type": $type, "listingId": $listing_id, "cities": $cities, "brokers": $brokers, "agent": $agent, "minprice": $minprice, "startdate": $startdate, "offset": $offset, "lastId": $last_id, "limit": $limit, "sort": $qp_sort, "include": $include} | compact), body: null}
}

# Single OpenHouse Endpoint
#
# GET /openhouses/{openHouseKey}
export def "openhouses get" [
  open_house_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include: list<string> # Include a extra fields which are not in the default response body - 'association' includes additional HOA data - 'agreement' information on the listing agreement - 'garageSpaces' additional garage data - 'maintenanceExpense' data on maintenance expenses - 'parking' additional parking data - 'pool' includes an additional pool description - 'taxAnnualAmount' include the annual tax amount - 'taxYear' include the tax year data - 'rooms' include parameter will include any additional rooms as a list. Note that your MLS must provide these fields in their RETS data for them to be available in the API response. In the future, fields which require an 'include' may become available by default.
]: nothing -> record<description: string, endTime: string, inputId: any, listing: record<address: record<city: string, country: string, crossStreet: string, full: string, postalCode: string, state: string, streetName: string, streetNumber: int, streetNumberText: string>, agent: record<contact: record, firstName: string, id: string, lastName: string>, association: record<amenities: string, fee: int, name: string>, coAgent: record<contact: record, firstName: string, id: string, lastName: string>, disclaimer: string, geo: record<county: string, directions: string, lat: float, lng: float, marketArea: string>, leaseTerm: string, leaseType: string, listDate: string, listPrice: float, listingId: string, mls: record<area: string, areaMinor: string, daysOnMarket: int, originatingSystemName: string, status: string, statusText: string>, mlsId: int, modified: string, office: record<brokerid: string, contact: record, name: string, servingName: string>, photos: list<string>, privateRemarks: string, property: record<accessibility: string, additionalRooms: string, area: int, areaSource: string, bathsFull: int, bathsHalf: int, bathsThreeQuarter: int, bedrooms: int, construction: string, cooling: string, exteriorFeatures: string, fireplaces: int, flooring: string, foundation: string, garageSpaces: float, heating: string, interiorFeatures: string, laundryFeatures: string, lotDescription: string, lotSize: string, lotSizeAcres: float, lotSizeArea: float, lotSizeAreaUnits: string, maintenanceExpense: float, occupantName: string, occupantType: string, ownerName: string, parking: record, poolFeatures: string, roof: string, stories: float, style: string, subType: string, subTypeRaw: string, subdivision: string, type: string, view: string, water: string, yearBuilt: int>, remarks: string, sales: record<agent: string, closeDate: string, closePrice: int, contractDate: string, office: string>, school: record<district: string, elementarySchool: string, highSchool: string, middleSchool: string>, showingInstructions: string, tax: record<id: string, taxAnnualAmount: string, taxYear: int>, virtualTourUrl: string>, openHouseId: string, openHouseKey: string, refreshments: string, startTime: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($open_house_key | is-empty) { error make --unspanned { msg: "path parameter 'openHouseKey' must be non-empty" } }
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({open_house_key: (encode-path-segment $open_house_key)} | format pattern "/openhouses/{open_house_key}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include": $include} | compact), body: null}
}

# The SimplyRETS Listings API
#
# GET /properties
export def "properties list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --q: string # A textual keyword search. This parameter will search the following fields, when available: - listingId (This does _not_ search the `mlsId` field in the SimplyRETS response body) - street number - street name - mls area (major) - city - subdivision name - postal code
  --status: list<string>@status-completer # Request listings by a specific status. This parameter defaults to active and you can specify multiple statuses in a single query. Listing statuses depend on your MLS's availability. Below is a brief description of each status with possible synonyms which may map to your MLS-specific statuses - *Active*: Active Listing which is still on the market - *ActiveUnderContract*: An offer has been accepted but the listing is still on market. Synonyms: Accepting Backup Offers, Backup Offer, Active With Accepted. Synonyms: Offer, Backup, Contingent - *Pending*: An offer has been accepted and the listing is no longer on market. Synonyms: Offer Accepted, Under Contract - *Hold*: The listing has been withdrawn from the market, but a contract still exists between the seller and the listing member. Synonyms: Hold, Hold Do Not Show, Temp Off Market - *Withdrawn*: The listing has been withdrawn from the market, but a contract still exists between the seller and the listing member. Synonyms: Hold, Hold Do Not Show, Temp Off Market - *Closed*: The purchase agreement has been fulfilled or the lease agreement has been executed. Synonyms: Sold, Leased, Rented, Closed Sale - *Expired*: The listing contract has expired - *Delete*: The listing contract was never valid or other reason for the contract to be nullified. Synonyms: Kill, Zap - *Incomplete*: The listing has not yet be completely entered and is not yet published in the MLS. Synonyms: Draft, Partially Complted - *ComingSoon*
  --type: list<string>@type-completer # Request listings by a specific property type. This defaults to Residential and Rental. You can specify multiple property types in a single query.
  --subtype: list<string>@subtype-completer # Request listings by a specific property sub type. *NOTE* not all sub type filters are available for all vendors.
  --agent: string # Filter the listings returned by an agent ID. Note, the Agent ID is provided by your MLS. The co-listing agent is not included in this query parameter.
  --brokers: list<string> # Filter the listings returned by brokerage with a Broker ID. For some MLS areas, this is the ListOfficeId (Listing Office ID). You can specific multiple broker parameters. Note, this query parameter is only available if a Broker ID is provided by your MLS.
  --minprice: int # Filter listings by a minimum price.
  --maxprice: int # Filter listings by a maximum price
  --minarea: int # Filter listings by a minimum area size in Sq Ft.
  --maxarea: int # Filter listings by a maximum area size in Sq Ft.
  --minbaths: int # Filter listings by a minimum number of bathrooms.
  --maxbaths: int # Filter listings by a maximum number of bathrooms.
  --minbeds: int # Filter listings by a minimum number of bedrooms.
  --maxbeds: int # Filter listings by a maximum number of bedrooms.
  --maxdom: int # Filter listings by a maximum number of days on market. _Note that your MLS must provide Days on Market data._
  --minyear: int # Filter listings by a setting a minimum year built.
  --limit: int # Set the number of listings to return in the response. This defaults to 20 listings, and can be a maximum of 500. To paginate through to the next page of listings, take a look at the `offset` parameter, or the Link in the HTTP Header.
  --offset: int # Increase the offset parameter by the limit to go to the next "page" of listings. Also take a look at the Link HTTP Header for pre-built pagination. *NOTE:* Use the `lastId` field to paginate response *NOTE:* If you're offset is too high, you will receive an `HTTP 400 offset too high` error message.
  --last-id: int # Used as a cursor for pagination. When using `lastId`, the `sort` parameter will not work.
  --vendor: string # Used to specify the vendor (MLS) to search from. This parameter is required on multi-MLS apps, and you can only query one vendor at a time. To get your vendor id's make an OPTIONS request to https://api.simplyrets.com. `curl -XOPTIONS https://api.simplyrets.com/properties`
  --postal-codes: list<string> # Filter the listings returned by postal codes / zip code. You can specify multiple.
  --features: list<string> # Filter the listings by specific interior features. You can filter by multiple. For example, to filter trial listings by multiple features you can use, Return listings that are within a set of latitude longitude coordinates. For example, ``` Wet Bar High Ceiling ``` e.g. `https://simplyrets.com/services?features=Wet%20Bar&features=High%20Ceiling` The list of `features` provided by your RETS vendor can be seen by sending an `OPTIONS` request to the `/properties` endpoint: `curl -XOPTIONS -u simplyrets:simplyrets https://api.simplyrets.com/properties`
  --water: string # Query water/waterfront listings only. Specify `true` to filter waterfront listings. If you specify `water=true`, all listings with any `waterfront` value will be queried. If you specify `water=false`, listings which are **NOT** waterfront listings will be queried. If you specify `water=LAKE+NAME` or another valid value contained in your feed, that value will be searched
  --neighborhoods: list<string> # Filter the listings returned by specific neighborhoods and subdivisions. You can specify multiple `neighborhoods` by using the query parameter multiple times. The `neighborhoods` query parameter is case-insensitive. The list of `neighborhoods` provided by your RETS vendor can be seen by sending an `OPTIONS` request to the `/properties` endpoint: `curl -XOPTIONS -u simplyrets:simplyrets https://api.simplyrets.com/properties`
  --cities: list<string> # Filter the listings returned by specific cities. You can specify multiple `cities` query parameters. The `cities` query parameter is case-insensitive. The list of `cities` provided by your RETS vendor can be seen by sending an `OPTIONS` request to the `/properties` endpoint: `curl -XOPTIONS -u simplyrets:simplyrets https://api.simplyrets.com/openhouses`
  --counties: list<string> # Filter the listings returned by specific counties. You can specify multiple `counties` parameters. The `counties` query parameter is case-insensitive. The list of `counties` provided by your RETS vendor can be seen by sending an `OPTIONS` request to the `/properties` endpoint: `curl -XOPTIONS -u simplyrets:simplyrets https://api.simplyrets.com/openhouses`
  --points: list<string> # Return listings that are within a set of latitude longitude coordinates. For example; ``` 29.723837,-95.69778 29.938275,-95.69778 29.938275,-95.32974 29.723837,-95.32974 ``` Note that some MLS's do not provide latitude and longitude for their listings, which is required for this parameter to work. In these cases, SimplyRETS offers a [Geocoding Addon](https://simplyrets.com/services#geocoding). Check out our [blog post](https://simplyrets.com/blog/interactive-map-search.html) on using the `points` parameter to build a map-based app in javascript.
  --include: list<string>@include-completer # Include a extra fields which are not in the default response body - 'association' includes additional HOA data - 'agreement' information on the listing agreement - 'garageSpaces' additional garage data - 'maintenanceExpense' data on maintenance expenses - 'parking' additional parking data - 'pool' includes an additional pool description - 'taxAnnualAmount' include the annual tax amount - 'taxYear' include the tax year data - 'rooms' include parameter will include any additional rooms as a list. Note that your MLS must provide these fields in their RETS data for them to be available in the API response. In the future, fields which require an 'include' may become available by default.
  --qp-sort: string@sort-completer # Sort the response by a specific field. Values starting with a minus (-) denote descending order, while the others are ascending.
  --count: int # When set to `false`, The `X-Total-Count` header will not be returned Counting the listings can contribute to slower API calls due to the extra queries that need to be run to get an exact count. Disabling count can increase query speeds.
]: nothing -> table<address: record<city: string, country: string, crossStreet: string, full: string, postalCode: string, state: string, streetName: string, streetNumber: int, streetNumberText: string>, agent: record<contact: record, firstName: string, id: string, lastName: string>, association: record<amenities: string, fee: int, name: string>, coAgent: record<contact: record, firstName: string, id: string, lastName: string>, disclaimer: string, geo: record<county: string, directions: string, lat: float, lng: float, marketArea: string>, leaseTerm: string, leaseType: string, listDate: string, listPrice: float, listingId: string, mls: record<area: string, areaMinor: string, daysOnMarket: int, originatingSystemName: string, status: string, statusText: string>, mlsId: int, modified: string, office: record<brokerid: string, contact: record, name: string, servingName: string>, photos: list<string>, privateRemarks: string, property: record<accessibility: string, additionalRooms: string, area: int, areaSource: string, bathsFull: int, bathsHalf: int, bathsThreeQuarter: int, bedrooms: int, construction: string, cooling: string, exteriorFeatures: string, fireplaces: int, flooring: string, foundation: string, garageSpaces: float, heating: string, interiorFeatures: string, laundryFeatures: string, lotDescription: string, lotSize: string, lotSizeAcres: float, lotSizeArea: float, lotSizeAreaUnits: string, maintenanceExpense: float, occupantName: string, occupantType: string, ownerName: string, parking: record, poolFeatures: string, roof: string, stories: float, style: string, subType: string, subTypeRaw: string, subdivision: string, type: string, view: string, water: string, yearBuilt: int>, remarks: string, sales: record<agent: string, closeDate: string, closePrice: int, contractDate: string, office: string>, school: record<district: string, elementarySchool: string, highSchool: string, middleSchool: string>, showingInstructions: string, tax: record<id: string, taxAnnualAmount: string, taxYear: int>, virtualTourUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "status" $status "multi") (serialize-qp "type" $type "multi") (serialize-qp "subtype" $subtype "multi") (serialize-qp "agent" $agent "scalar") (serialize-qp "brokers" $brokers "multi") (serialize-qp "minprice" $minprice "scalar") (serialize-qp "maxprice" $maxprice "scalar") (serialize-qp "minarea" $minarea "scalar") (serialize-qp "maxarea" $maxarea "scalar") (serialize-qp "minbaths" $minbaths "scalar") (serialize-qp "maxbaths" $maxbaths "scalar") (serialize-qp "minbeds" $minbeds "scalar") (serialize-qp "maxbeds" $maxbeds "scalar") (serialize-qp "maxdom" $maxdom "scalar") (serialize-qp "minyear" $minyear "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "lastId" $last_id "scalar") (serialize-qp "vendor" $vendor "scalar") (serialize-qp "postalCodes" $postal_codes "multi") (serialize-qp "features" $features "multi") (serialize-qp "water" $water "scalar") (serialize-qp "neighborhoods" $neighborhoods "multi") (serialize-qp "cities" $cities "multi") (serialize-qp "counties" $counties "multi") (serialize-qp "points" $points "multi") (serialize-qp "include" $include "multi") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/properties" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "status": $status, "type": $type, "subtype": $subtype, "agent": $agent, "brokers": $brokers, "minprice": $minprice, "maxprice": $maxprice, "minarea": $minarea, "maxarea": $maxarea, "minbaths": $minbaths, "maxbaths": $maxbaths, "minbeds": $minbeds, "maxbeds": $maxbeds, "maxdom": $maxdom, "minyear": $minyear, "limit": $limit, "offset": $offset, "lastId": $last_id, "vendor": $vendor, "postalCodes": $postal_codes, "features": $features, "water": $water, "neighborhoods": $neighborhoods, "cities": $cities, "counties": $counties, "points": $points, "include": $include, "sort": $qp_sort, "count": $count} | compact), body: null}
}

# Single Listing Endpoint
#
# GET /properties/{mlsId}
export def "properties get" [
  mls_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include: list<string>@include-completer-1 # Include a extra fields which are not in the default response body - 'association' includes additional HOA data - 'agreement' information on the listing agreement - 'garageSpaces' additional garage data - 'maintenanceExpense' data on maintenance expenses - 'parking' additional parking data - 'pool' includes an additional pool description - 'rooms' include parameter will include any additional rooms as a list. Note that your MLS must provide these fields in their RETS data for them to be available with valid data in the API response. If your MLS does not offer these fields, they will contain 'null'. In the future, fields which require an 'include' may become available by default.
]: nothing -> record<address: record<city: string, country: string, crossStreet: string, full: string, postalCode: string, state: string, streetName: string, streetNumber: int, streetNumberText: string>, agent: record<contact: record<cell: string, email: string, office: string>, firstName: string, id: string, lastName: string>, association: record<amenities: string, fee: int, name: string>, coAgent: record<contact: record<cell: string, email: string, office: string>, firstName: string, id: string, lastName: string>, disclaimer: string, geo: record<county: string, directions: string, lat: float, lng: float, marketArea: string>, leaseTerm: string, leaseType: string, listDate: string, listPrice: float, listingId: string, mls: record<area: string, areaMinor: string, daysOnMarket: int, originatingSystemName: string, status: string, statusText: string>, mlsId: int, modified: string, office: record<brokerid: string, contact: record<cell: string, email: string, office: string>, name: string, servingName: string>, photos: list<string>, privateRemarks: string, property: record<accessibility: string, additionalRooms: string, area: int, areaSource: string, bathsFull: int, bathsHalf: int, bathsThreeQuarter: int, bedrooms: int, construction: string, cooling: string, exteriorFeatures: string, fireplaces: int, flooring: string, foundation: string, garageSpaces: float, heating: string, interiorFeatures: string, laundryFeatures: string, lotDescription: string, lotSize: string, lotSizeAcres: float, lotSizeArea: float, lotSizeAreaUnits: string, maintenanceExpense: float, occupantName: string, occupantType: string, ownerName: string, parking: record<description: string, leased: string, spaces: int>, poolFeatures: string, roof: string, stories: float, style: string, subType: string, subTypeRaw: string, subdivision: string, type: string, view: string, water: string, yearBuilt: int>, remarks: string, sales: record<agent: string, closeDate: string, closePrice: int, contractDate: string, office: string>, school: record<district: string, elementarySchool: string, highSchool: string, middleSchool: string>, showingInstructions: string, tax: record<id: string, taxAnnualAmount: string, taxYear: int>, virtualTourUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($mls_id | is-empty) { error make --unspanned { msg: "path parameter 'mlsId' must be non-empty" } }
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({mls_id: (encode-path-segment $mls_id)} | format pattern "/properties/{mls_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include": $include} | compact), body: null}
}
