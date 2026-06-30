# Auto-generated client for Marketcheck APIs v2.01
# Source: https://api.apis.guru/v2/specs/apigee.net/marketcheck-cars/2.01/openapi.json
# Auth: --token flag or $env.MARKETCHECK_APIS_TOKEN

const BASE_URL = "https://marketcheck-prod.apigee.net/v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o MARKETCHECK_APIS_TOKEN | default "" }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body}.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk.
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://marketcheck-prod.apigee.net/v2"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def car-type-completer [] { ["certified" "new" "used"] }
def carfax-1-owner-completer [] { ["false" "true"] }
def carfax-clean-title-completer [] { ["false" "true"] }
def sort-order-completer [] { ["ASC" "DESC" "asc" "desc"] }
def facet-sort-completer [] { ["count" "index"] }
def country-completer [] { ["ALL" "CA" "US" "all" "ca" "us"] }
def dealer-type-completer [] { ["franchise" "independent"] }
def in-transit-completer [] { ["false" "true"] }
def country-completer-1 [] { ["CA" "UK" "US"] }
def country-completer-2 [] { ["CA" "US" "ca" "england" "northan ireland" "scotland" "uk" "us" "wales"] }
def country-completer-3 [] { ["CA" "US" "ca" "us"] }
def car-type-completer-1 [] { ["new" "used"] }
def transmission-completer [] { ["Automatic" "Manual"] }
def drivetrain-completer [] { ["4WD" "AWD" "FWD" "RWD"] }
def engine-block-completer [] { ["H" "I" "V"] }
def country-completer-4 [] { ["ca" "us"] }
def price-change-completer [] { ["negative" "positive"] }
def inventory-type-completer [] { ["new" "used"] }
def title-type-completer [] { ["clean" "salvage"] }
def field-completer [] { ["body_subtype" "body_type" "city" "drivetrain" "engine" "engine_block" "engine_size" "exterior_color" "fuel_type" "interior_color" "make" "mm" "model" "state" "transmission" "trim" "vehicle_type" "ymm"] }
def include-non-vin-listings-completer [] { ["false" "true"] }
def sort-by-completer [] { ["count" "index"] }
def offer-type-completer [] { ["cash" "finance" "lease"] }
def expired-completer [] { ["false" "true"] }
def country-completer-5 [] { ["england" "northan ireland" "scotland" "uk" "wales"] }
def client-filters-completer [] { ["false" "true"] }
def boost-completer [] { ["false" "true"] }
def field-completer-1 [] { ["body_type" "category" "city" "drivetrain" "engine" "exterior_color" "fuel_type" "interior_color" "make" "model" "state" "sub_category" "transmission" "trim"] }
def field-completer-2 [] { ["body_type" "city" "color" "drivetrain" "engine" "fuel_type" "make" "model" "state" "transmission" "trim" "vehicle_type"] }
def field-completer-3 [] { ["city" "class" "engine" "exterior_color" "fuel_type" "interior_color" "make" "model" "state" "transmission" "trim"] }
def field-completer-4 [] { ["body_subtype" "body_type" "drivetrain" "engine" "engine_block" "engine_size" "fuel_type" "make" "model" "transmission" "trim" "vehicle_type"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "car-dealer-inventory-active get" } } | get name | first)
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

# Get dealers active inventory
#
# GET /car/dealer/inventory/active
export def "car-dealer-inventory-active get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --include-lease: oneof<nothing, bool> # Boolean param to search for listings that include leasing options in them
  --include-finance: oneof<nothing, bool> # Boolean param to search for listings that include finance options in them
  --lease-term: string # Search listings with exact lease term, or inside a range with min and max seperated by a dash like lease_term=30-60
  --lease-down-payment: string # Search listings with exact down payment in lease offers, or inside a range with min and max seperated by a dash like lease_down_payment=30-60
  --lease-emp: string # Search listings with lease offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like lease_emp=30-60
  --finance-loan-term: string # Search listings with exact finance loan term, or inside a range with min and max seperated by a dash like finance_loan_term=30-60
  --finance-loan-apr: string # Search listings with finance offers exactly matching loans Annual Percentage Rate, or inside a range with min and max seperated by a dash like finance_loan_apr=30-60
  --finance-emp: string # Search listings with finance offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like finance_emp=30-60
  --finance-down-payment: string # Search listings with exact down payment in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment=30-60
  --finance-down-payment-per: string # Search listings with exact down payment percentage in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment_per=30-60
  --car-type: string@car-type-completer # Car type. Allowed values are - new / used / certified
  --carfax-1-owner: string@carfax-1-owner-completer # Indicates whether car has had only one owner or not
  --carfax-clean-title: string@carfax-clean-title-completer # Indicates whether car has clean ownership records
  --year-range: string # Year range to filter listings with the year in the range given. Range to be given in the format - min-max e.g. 2019-2021 (format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --vin: string # To filter listing on their VIN
  --qp-source: string # To filter listing on their source
  --body-type: string # To filter listing on their body type
  --body-subtype: string # Body subtype to filter the listings on. Valid filter values are those that our Search facets API returns for unique body subtypes. You can pass in multiple body subtype values comma separated (format: string)
  --vehicle-type: string # To filter listing on their vehicle type
  --vins: string # Comma separated list of 17 digit vins to search the matching cars for. Only 10 VINs allowed per request. If the request contains more than 10 VINs the first 10 VINs will be considered. Could be used as a More Like This or Similar Vehicles search for the given VINs. Ths vins parameter is an alternative to taxonomy_vins or ymmt parameters available with the search API. vins and taxonomy_vins parameters could be used to filter our cars with the exact build represented by the vins or taxonomy_vins whereas ymmt is a top level filter that does not filter cars by the build attributes like doors, drivetrain, cylinders, body type, body subtype, vehicle type etc
  --taxonomy-vins: string # Comma separated list of 10 letters excert from the 17 letter VIN. The 10 letters to be picked up from the 17 letter VIN are - first 8 letters and the 10th and 11th letter. E.g. For a VIN - 1FTFW1EF3EKE57182 the taxonomy vin would be - 1FTFW1EFEK A taxonomy VIN identified a build of a car and could be used to filter our cars of a particular build. This is an alternative to the vin or ymmt parameters to the search API.
  --mm: string # Make-Model concatenated string. To help passing the results of auto-complete API on mm field, use this parameter and pass in the selected value as is
  --ymm: string # Year-Make-Model concatenated string. To help passing the results of auto-complete API on ymm field, use this parameter and pass in the selected value as is
  --ymmt: string # Comma separated list of Year, Make, Model, Trim combinations. Each combination needs to have the year,make,model, trim values separated by a pipe '|' character in the form year|make|model|trim. e.g. 2010|Audi|A5,2014|Nissan|Sentra|S 6MT,|Honda|City| You could just provide strings of the form - 'year|make||' or 'year|make|model' or '|make|model|' combinations. Individual year / make / model filters provied with the API calls will take precedence over the Year, Make, Model, Trim combinations. The Make, Model, Trim values must be valid values as per the Marketcheck Vin Decoder. If you are using a separate vin decoder then look at using the 'vins' or 'taxonomy_vins' parameter to the search api instead the year|make|model|trim combinations.
  --qp-match: string # Comma separated list of Year, Make, Model, Trim fields. For example - year,make,model,trim fields for which user wants to do an exact match
  --cylinders: string # To filter listing on their cylinders
  --transmission: string # To filter listing on their transmission
  --doors: string # Doors to filter the cars on. Valid filter values are those that our Search facets API returns for unique doors. You can pass in multiple doors values comma separated (format: string)
  --drivetrain: string # To filter listing on their drivetrain
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --base-exterior-color: string # Base exterior color to match. Valid filter values are those that our Search facets API returns for unique base exterior colors. You can pass in multiple base interior color values comma separated
  --base-interior-color: string # Base interior color to match. Valid filter values are those that our Search facets API returns for unique base interior colors. You can pass in multiple base interior color values comma separated
  --engine: string # To filter listing on their engine
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-aspiration: string # Engine Aspiration to match. Valid filter values are those that our Search facets API returns for unique Engine Aspirations. You can pass in multiple Engine aspirations values comma separated
  --engine-block: string # Engine Block to match. Valid filter values are those that our Search facets API returns for unique Engine Block. You can pass in multiple Engine Block values comma separated
  --highway-mpg-range: string # Highway mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --city-mpg-range: string # City mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --dom-range: string # Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --include-non-vin-listings: oneof<nothing, bool> # To include non vin listings. Default is false (default: false)
  --msa-code: string # To filter listing on msa code in which they are listed
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --country: string@country-completer # To filter listing on Country in which they are listed (default: US)
  --plot: oneof<nothing, bool> # If plot has value true results in around 25k coordinates with limited fields to plot respective graph
  --nodedup: oneof<nothing, bool> # If nodedup is set to true then API will give results without is_searchable i.e multiple listings for single vin
  --dedup: oneof<nothing, bool> # If dedup is set to true then will give results with is_searchable irrespecive of dealer_id or source
  --owned: oneof<nothing, bool> # Used in combination with dealer_id or source, when true returns the listings actually owned by dealer himself
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --dealer-name: string # Filter listings on dealer_name
  --dealership-group-name: string # Name of the dealership group to search for (format: string)
  --trim-o: string # Filter listings on web scraped trim
  --trim-r: string # Filter trim on custom possible matches
  --dom-active-range: string # Active Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dom-180-range: string # Last 180 Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --exclude-certified: oneof<nothing, bool> # Boolean param to exclude certified cars from search results
  --fuel-type: string # To filter listing on their fuel type
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --photo-links: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links in search results, And discard those that don't have them
  --photo-links-cached: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links_cached in search results, And discard those that don't have them
  --stock-no: string # To filter listing on their stock number on lot
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-source-range: string # First seen at source date range to filter listings with the first seen at source in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-mc-range: string # First seen at MC date range to filter listings with the first seen at MC in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-source-days: string # First seen at source days range to filter listings with the first seen at source in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-mc-days: string # First seen at MC days range to filter listings with the first seen at MC in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --include-relevant-links: oneof<nothing, bool> # To include_relevant_links. Default is true (default: false)
  --inventory-count-range: string # Inventory count range to filter listings with count of total listings in dealers inventory. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --in-transit: string@in-transit-completer # A boolean to filter in transit vehicles
  --seating-capacity: string # To filter on vehicle seating capacity (format: string)
  --engine-size-range: string # Engine size range to filter listings with engine size in the given range. Range to be given in the format - min-max e.g. 1.0-2 (format: string)
  --powertrain-type: string # To filter on powertrain_type (format: string)
  --min-photo-links: string # Filter listings based by number of photo links within given range (format: string)
  --min-photo-links-cached: string # Filter listings based by number of cached photo links within given range (format: string)
]: nothing -> record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fuel_type: list<record>, interior_color: list<record>, make: list<record>, model: list<record>, seller_name: list<record>, seller_name_o: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, trim_o: list<record>, trim_r: list<record>, vehicle_type: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, vdp_url: string, vin: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "append_api_key" $append_api_key "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "include_lease" $include_lease "scalar") (serialize-qp "include_finance" $include_finance "scalar") (serialize-qp "lease_term" $lease_term "scalar") (serialize-qp "lease_down_payment" $lease_down_payment "scalar") (serialize-qp "lease_emp" $lease_emp "scalar") (serialize-qp "finance_loan_term" $finance_loan_term "scalar") (serialize-qp "finance_loan_apr" $finance_loan_apr "scalar") (serialize-qp "finance_emp" $finance_emp "scalar") (serialize-qp "finance_down_payment" $finance_down_payment "scalar") (serialize-qp "finance_down_payment_per" $finance_down_payment_per "scalar") (serialize-qp "car_type" $car_type "scalar") (serialize-qp "carfax_1_owner" $carfax_1_owner "scalar") (serialize-qp "carfax_clean_title" $carfax_clean_title "scalar") (serialize-qp "year_range" $year_range "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "trim" $trim "scalar") (serialize-qp "dealer_id" $dealer_id "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "body_type" $body_type "scalar") (serialize-qp "body_subtype" $body_subtype "scalar") (serialize-qp "vehicle_type" $vehicle_type "scalar") (serialize-qp "vins" $vins "scalar") (serialize-qp "taxonomy_vins" $taxonomy_vins "scalar") (serialize-qp "mm" $mm "scalar") (serialize-qp "ymm" $ymm "scalar") (serialize-qp "ymmt" $ymmt "scalar") (serialize-qp "match" $qp_match "scalar") (serialize-qp "cylinders" $cylinders "scalar") (serialize-qp "transmission" $transmission "scalar") (serialize-qp "doors" $doors "scalar") (serialize-qp "drivetrain" $drivetrain "scalar") (serialize-qp "exterior_color" $exterior_color "scalar") (serialize-qp "interior_color" $interior_color "scalar") (serialize-qp "base_exterior_color" $base_exterior_color "scalar") (serialize-qp "base_interior_color" $base_interior_color "scalar") (serialize-qp "engine" $engine "scalar") (serialize-qp "engine_size" $engine_size "scalar") (serialize-qp "engine_aspiration" $engine_aspiration "scalar") (serialize-qp "engine_block" $engine_block "scalar") (serialize-qp "highway_mpg_range" $highway_mpg_range "scalar") (serialize-qp "city_mpg_range" $city_mpg_range "scalar") (serialize-qp "miles_range" $miles_range "scalar") (serialize-qp "price_range" $price_range "scalar") (serialize-qp "msrp_range" $msrp_range "scalar") (serialize-qp "dom_range" $dom_range "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "include_non_vin_listings" $include_non_vin_listings "scalar") (serialize-qp "msa_code" $msa_code "scalar") (serialize-qp "facets" $facets "scalar") (serialize-qp "range_facets" $range_facets "scalar") (serialize-qp "facet_sort" $facet_sort "scalar") (serialize-qp "stats" $stats "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "plot" $plot "scalar") (serialize-qp "nodedup" $nodedup "scalar") (serialize-qp "dedup" $dedup "scalar") (serialize-qp "owned" $owned "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "dealer_name" $dealer_name "scalar") (serialize-qp "dealership_group_name" $dealership_group_name "scalar") (serialize-qp "trim_o" $trim_o "scalar") (serialize-qp "trim_r" $trim_r "scalar") (serialize-qp "dom_active_range" $dom_active_range "scalar") (serialize-qp "dom_180_range" $dom_180_range "scalar") (serialize-qp "exclude_certified" $exclude_certified "scalar") (serialize-qp "fuel_type" $fuel_type "scalar") (serialize-qp "dealer_type" $dealer_type "scalar") (serialize-qp "photo_links" $photo_links "scalar") (serialize-qp "photo_links_cached" $photo_links_cached "scalar") (serialize-qp "stock_no" $stock_no "scalar") (serialize-qp "last_seen_range" $last_seen_range "scalar") (serialize-qp "first_seen_range" $first_seen_range "scalar") (serialize-qp "first_seen_at_source_range" $first_seen_at_source_range "scalar") (serialize-qp "first_seen_at_mc_range" $first_seen_at_mc_range "scalar") (serialize-qp "last_seen_days" $last_seen_days "scalar") (serialize-qp "first_seen_days" $first_seen_days "scalar") (serialize-qp "first_seen_at_source_days" $first_seen_at_source_days "scalar") (serialize-qp "first_seen_at_mc_days" $first_seen_at_mc_days "scalar") (serialize-qp "include_relevant_links" $include_relevant_links "scalar") (serialize-qp "inventory_count_range" $inventory_count_range "scalar") (serialize-qp "in_transit" $in_transit "scalar") (serialize-qp "seating_capacity" $seating_capacity "scalar") (serialize-qp "engine_size_range" $engine_size_range "scalar") (serialize-qp "powertrain_type" $powertrain_type "scalar") (serialize-qp "min_photo_links" $min_photo_links "scalar") (serialize-qp "min_photo_links_cached" $min_photo_links_cached "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/car/dealer/inventory/active" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "append_api_key": $append_api_key, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "zip": $zip, "include_lease": $include_lease, "include_finance": $include_finance, "lease_term": $lease_term, "lease_down_payment": $lease_down_payment, "lease_emp": $lease_emp, "finance_loan_term": $finance_loan_term, "finance_loan_apr": $finance_loan_apr, "finance_emp": $finance_emp, "finance_down_payment": $finance_down_payment, "finance_down_payment_per": $finance_down_payment_per, "car_type": $car_type, "carfax_1_owner": $carfax_1_owner, "carfax_clean_title": $carfax_clean_title, "year_range": $year_range, "year": $year, "make": $make, "model": $model, "trim": $trim, "dealer_id": $dealer_id, "vin": $vin, "source": $qp_source, "body_type": $body_type, "body_subtype": $body_subtype, "vehicle_type": $vehicle_type, "vins": $vins, "taxonomy_vins": $taxonomy_vins, "mm": $mm, "ymm": $ymm, "ymmt": $ymmt, "match": $qp_match, "cylinders": $cylinders, "transmission": $transmission, "doors": $doors, "drivetrain": $drivetrain, "exterior_color": $exterior_color, "interior_color": $interior_color, "base_exterior_color": $base_exterior_color, "base_interior_color": $base_interior_color, "engine": $engine, "engine_size": $engine_size, "engine_aspiration": $engine_aspiration, "engine_block": $engine_block, "highway_mpg_range": $highway_mpg_range, "city_mpg_range": $city_mpg_range, "miles_range": $miles_range, "price_range": $price_range, "msrp_range": $msrp_range, "dom_range": $dom_range, "sort_by": $sort_by, "sort_order": $sort_order, "rows": $rows, "start": $start, "include_non_vin_listings": $include_non_vin_listings, "msa_code": $msa_code, "facets": $facets, "range_facets": $range_facets, "facet_sort": $facet_sort, "stats": $stats, "country": $country, "plot": $plot, "nodedup": $nodedup, "dedup": $dedup, "owned": $owned, "state": $state, "city": $city, "dealer_name": $dealer_name, "dealership_group_name": $dealership_group_name, "trim_o": $trim_o, "trim_r": $trim_r, "dom_active_range": $dom_active_range, "dom_180_range": $dom_180_range, "exclude_certified": $exclude_certified, "fuel_type": $fuel_type, "dealer_type": $dealer_type, "photo_links": $photo_links, "photo_links_cached": $photo_links_cached, "stock_no": $stock_no, "last_seen_range": $last_seen_range, "first_seen_range": $first_seen_range, "first_seen_at_source_range": $first_seen_at_source_range, "first_seen_at_mc_range": $first_seen_at_mc_range, "last_seen_days": $last_seen_days, "first_seen_days": $first_seen_days, "first_seen_at_source_days": $first_seen_at_source_days, "first_seen_at_mc_days": $first_seen_at_mc_days, "include_relevant_links": $include_relevant_links, "inventory_count_range": $inventory_count_range, "in_transit": $in_transit, "seating_capacity": $seating_capacity, "engine_size_range": $engine_size_range, "powertrain_type": $powertrain_type, "min_photo_links": $min_photo_links, "min_photo_links_cached": $min_photo_links_cached} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Recall info by vin
#
# GET /car/recall/{vin}
# operationId: getRecallHistory
export def "car-recall get-history" [
  vin: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --page: float # Page number to fetch the results for the given criteria. Default is 1. (format: number)
]: nothing -> record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fuel_type: list<record>, interior_color: list<record>, make: list<record>, model: list<record>, seller_name: list<record>, seller_name_o: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, trim_o: list<record>, trim_r: list<record>, vehicle_type: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, vdp_url: string, vin: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($vin | is-empty) { error make --unspanned { msg: "path parameter 'vin' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({vin: (encode-path-segment $vin)} | format pattern "/car/recall/{vin}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# get client filters
#
# GET /client/configure/get
# operationId: get
export def "client-configure-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --country: string@country-completer-1 # To filter listing on Country in which they are listed
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/client/configure/get" $qp $auth.query)
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "country": $country} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# set client filters
#
# POST /client/configure/set
# operationId: set
export def "client-configure-set update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --country: string@country-completer-1 # To filter listing on Country in which they are listed
  csvfile: string # csv file with filters (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/client/configure/set" $qp $auth.query)
  let req_body = {"csvfile": $csvfile} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["csvfile"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: ({"api_key": $api_key, "country": $country} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# CRM check of a particular vin
#
# GET /crm_check/car/{vin}
# operationId: crmCheck
export def "crm-check-car check" [
  vin: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --sale-date: string # sale date to check whether after this listing has appeared or not. Must be 8 character long, with YYYYMMDD format (format: string)
]: nothing -> record<for_sale: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($vin | is-empty) { error make --unspanned { msg: "path parameter 'vin' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "sale_date" $sale_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({vin: (encode-path-segment $vin)} | format pattern "/crm_check/car/{vin}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "sale_date": $sale_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Dealer by id
#
# GET /dealer/car/uk/{id}
export def "dealer-car-uk get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --provider: oneof<nothing, bool> # boolean param to include site providers name in response (default: false)
]: nothing -> record<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "provider" $provider "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dealer/car/uk/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "provider": $provider} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Dealer by id
#
# GET /dealer/car/{id}
# operationId: getDealer
export def "dealer-car get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --provider: oneof<nothing, bool> # boolean param to include site providers name in response (default: false)
]: nothing -> record<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "provider" $provider "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dealer/car/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "provider": $provider} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Dealer by id
#
# GET /dealer/heavy-equipment/{id}
export def "dealer-heavy-equipment get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --provider: oneof<nothing, bool> # boolean param to include site providers name in response (default: false)
]: nothing -> record<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "provider" $provider "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dealer/heavy-equipment/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "provider": $provider} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Dealer by id
#
# GET /dealer/motorcycle/{id}
export def "dealer-motorcycle get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --provider: oneof<nothing, bool> # boolean param to include site providers name in response (default: false)
]: nothing -> record<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "provider" $provider "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dealer/motorcycle/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "provider": $provider} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Dealer by id
#
# GET /dealer/rv/{id}
export def "dealer-rv get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --provider: oneof<nothing, bool> # boolean param to include site providers name in response (default: false)
]: nothing -> record<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "provider" $provider "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dealer/rv/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "provider": $provider} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Find car dealers around
#
# GET /dealers/car
# operationId: dealerSearch
export def "dealers-car list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --country: string@country-completer-2 # To filter listing on Country in which they are listed
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --city: string # To filter listing on City in which they are listed
  --state: string # To filter listing on State in which they are listed
  --listing-count-range: string # To filter dealers based on their inventory size. Range can be given in the format - min-max e.g. 50-100 (format: string)
  --inventory-url: string # inventory_url of dealer to be searched (format: string)
  --zip: string # To filter listing on ZIP around which they are listed
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --provider: oneof<nothing, bool> # boolean param to include site providers name in response (default: false)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
]: nothing -> record<dealers: table<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>, num_found: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "dealer_type" $dealer_type "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "listing_count_range" $listing_count_range "scalar") (serialize-qp "inventory_url" $inventory_url "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "provider" $provider "scalar") (serialize-qp "facets" $facets "scalar") (serialize-qp "range_facets" $range_facets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dealers/car" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "rows": $rows, "start": $start, "country": $country, "dealer_type": $dealer_type, "city": $city, "state": $state, "listing_count_range": $listing_count_range, "inventory_url": $inventory_url, "zip": $zip, "sort_by": $sort_by, "sort_order": $sort_order, "provider": $provider, "facets": $facets, "range_facets": $range_facets} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Find car dealers around
#
# GET /dealers/car/uk
export def "dealers-car-uk get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --country: string@country-completer-2 # To filter listing on Country in which they are listed
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --city: string # To filter listing on City in which they are listed
  --county: string # To filter listing on county in which they are listed
  --listing-count-range: string # To filter dealers based on their inventory size. Range can be given in the format - min-max e.g. 50-100 (format: string)
  --inventory-url: string # inventory_url of dealer to be searched (format: string)
  --postal-code: string # To filter listing on postal code around which they are listed
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --provider: oneof<nothing, bool> # boolean param to include site providers name in response (default: false)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
]: nothing -> record<dealers: table<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>, num_found: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "dealer_type" $dealer_type "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "county" $county "scalar") (serialize-qp "listing_count_range" $listing_count_range "scalar") (serialize-qp "inventory_url" $inventory_url "scalar") (serialize-qp "postal_code" $postal_code "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "provider" $provider "scalar") (serialize-qp "facets" $facets "scalar") (serialize-qp "range_facets" $range_facets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dealers/car/uk" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "rows": $rows, "start": $start, "country": $country, "dealer_type": $dealer_type, "city": $city, "county": $county, "listing_count_range": $listing_count_range, "inventory_url": $inventory_url, "postal_code": $postal_code, "sort_by": $sort_by, "sort_order": $sort_order, "provider": $provider, "facets": $facets, "range_facets": $range_facets} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Find car dealers around
#
# GET /dealers/heavy-equipment
export def "dealers-heavy-equipment get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --country: string@country-completer-2 # To filter listing on Country in which they are listed
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --city: string # To filter listing on City in which they are listed
  --state: string # To filter listing on State in which they are listed
  --listing-count-range: string # To filter dealers based on their inventory size. Range can be given in the format - min-max e.g. 50-100 (format: string)
  --inventory-url: string # inventory_url of dealer to be searched (format: string)
  --zip: string # To filter listing on ZIP around which they are listed
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --provider: oneof<nothing, bool> # boolean param to include site providers name in response (default: false)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
]: nothing -> record<dealers: table<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>, num_found: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "dealer_type" $dealer_type "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "listing_count_range" $listing_count_range "scalar") (serialize-qp "inventory_url" $inventory_url "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "provider" $provider "scalar") (serialize-qp "facets" $facets "scalar") (serialize-qp "range_facets" $range_facets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dealers/heavy-equipment" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "rows": $rows, "start": $start, "country": $country, "dealer_type": $dealer_type, "city": $city, "state": $state, "listing_count_range": $listing_count_range, "inventory_url": $inventory_url, "zip": $zip, "sort_by": $sort_by, "sort_order": $sort_order, "provider": $provider, "facets": $facets, "range_facets": $range_facets} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Find car dealers around
#
# GET /dealers/motorcycle
export def "dealers-motorcycle get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --country: string@country-completer-2 # To filter listing on Country in which they are listed
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --city: string # To filter listing on City in which they are listed
  --state: string # To filter listing on State in which they are listed
  --listing-count-range: string # To filter dealers based on their inventory size. Range can be given in the format - min-max e.g. 50-100 (format: string)
  --inventory-url: string # inventory_url of dealer to be searched (format: string)
  --zip: string # To filter listing on ZIP around which they are listed
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --provider: oneof<nothing, bool> # boolean param to include site providers name in response (default: false)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
]: nothing -> record<dealers: table<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>, num_found: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "dealer_type" $dealer_type "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "listing_count_range" $listing_count_range "scalar") (serialize-qp "inventory_url" $inventory_url "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "provider" $provider "scalar") (serialize-qp "facets" $facets "scalar") (serialize-qp "range_facets" $range_facets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dealers/motorcycle" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "rows": $rows, "start": $start, "country": $country, "dealer_type": $dealer_type, "city": $city, "state": $state, "listing_count_range": $listing_count_range, "inventory_url": $inventory_url, "zip": $zip, "sort_by": $sort_by, "sort_order": $sort_order, "provider": $provider, "facets": $facets, "range_facets": $range_facets} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Find car dealers around
#
# GET /dealers/rv
export def "dealers-rv get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --country: string@country-completer-2 # To filter listing on Country in which they are listed
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --city: string # To filter listing on City in which they are listed
  --state: string # To filter listing on State in which they are listed
  --listing-count-range: string # To filter dealers based on their inventory size. Range can be given in the format - min-max e.g. 50-100 (format: string)
  --inventory-url: string # inventory_url of dealer to be searched (format: string)
  --zip: string # To filter listing on ZIP around which they are listed
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --provider: oneof<nothing, bool> # boolean param to include site providers name in response (default: false)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
]: nothing -> record<dealers: table<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>, num_found: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "dealer_type" $dealer_type "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "listing_count_range" $listing_count_range "scalar") (serialize-qp "inventory_url" $inventory_url "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "provider" $provider "scalar") (serialize-qp "facets" $facets "scalar") (serialize-qp "range_facets" $range_facets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dealers/rv" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "rows": $rows, "start": $start, "country": $country, "dealer_type": $dealer_type, "city": $city, "state": $state, "listing_count_range": $listing_count_range, "inventory_url": $inventory_url, "zip": $zip, "sort_by": $sort_by, "sort_order": $sort_order, "provider": $provider, "facets": $facets, "range_facets": $range_facets} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# EPI VIN Decoder
#
# GET /decode/car/epi/{vin}/specs
# operationId: decodeViaEPI
export def "decode-car-epi-specs get-via" [
  vin: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> record<antibrake_sys: string, body_subtype: string, body_type: string, city_miles: string, city_mpg: int, cylinders: int, doors: int, drivetrain: string, engine: string, engine_aspiration: string, engine_block: string, engine_measure: string, engine_size: float, fuel_type: string, highway_miles: string, highway_mpg: int, made_in: string, make: string, model: string, opt_seating: string, overall_height: string, overall_length: string, overall_width: string, powertrain_type: string, short_trim: string, std_seating: string, steering_type: string, tank_size: string, transmission: string, trim: string, trim_r: string, vehicle_type: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($vin | is-empty) { error make --unspanned { msg: "path parameter 'vin' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({vin: (encode-path-segment $vin)} | format pattern "/decode/car/epi/{vin}/specs") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# NeoVIN Decoder
#
# GET /decode/car/neovin/{vin}/specs
# operationId: decodeViaNeoVIN
export def "decode-car-neovin-specs get-via-neo" [
  vin: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --include-generic: oneof<nothing, bool> # Boolean variable to indicate wheather to include generic data as well in response (default: false)
  --force-decode: oneof<nothing, bool> # Decode VIN on the fly instead of cached response (default: false)
]: nothing -> record<available_options_details: record, body_subtype: string, body_type: string, city_mpg: float, combined_msrp: float, created_at: int, created_at_date: string, decode_version: int, delivery_charges: float, doors: int, drivetrain: string, engine: string, exterior_color: record, features: record, fuel_type: string, height: float, highway_mpg: float, installed_equipment: record, installed_options_details: record, installed_options_msrp: float, interior_color: record, length: float, listing_confidence: string, make: string, manufacturer_code: string, model: string, msrp: float, options_packages: string, package_code: string, package_description: string, seating_capacity: float, squish_vin: string, transmission: string, transmission_confidence: string, transmission_description: string, trim: string, trim_confidence: string, updated_at: int, updated_at_date: string, version: string, version_confidence: string, vin: string, weight: float, width: float, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($vin | is-empty) { error make --unspanned { msg: "path parameter 'vin' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "include_generic" $include_generic "scalar") (serialize-qp "force_decode" $force_decode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({vin: (encode-path-segment $vin)} | format pattern "/decode/car/neovin/{vin}/specs") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "include_generic": $include_generic, "force_decode": $force_decode} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# VIN Decoder
#
# GET /decode/car/{vin}/specs
# operationId: decode
export def "decode-car-specs get" [
  vin: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> record<antibrake_sys: string, body_subtype: string, body_type: string, city_miles: string, city_mpg: int, cylinders: int, doors: int, drivetrain: string, engine: string, engine_aspiration: string, engine_block: string, engine_measure: string, engine_size: float, fuel_type: string, highway_miles: string, highway_mpg: int, made_in: string, make: string, model: string, opt_seating: string, overall_height: string, overall_length: string, overall_width: string, powertrain_type: string, short_trim: string, std_seating: string, steering_type: string, tank_size: string, transmission: string, trim: string, trim_r: string, vehicle_type: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($vin | is-empty) { error make --unspanned { msg: "path parameter 'vin' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({vin: (encode-path-segment $vin)} | format pattern "/decode/car/{vin}/specs") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a cars online listing history
#
# GET /history/car/uk/{vrm}
export def "history-car-uk get" [
  vrm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --page: float # Page number to fetch the results for the given criteria. Default is 1. (format: number)
  --include-duplicates: oneof<nothing, bool> # Flag to indicate whether to include duplicate historical records as well in the response
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
]: nothing -> table<carfax_1_owner: bool, carfax_clean_title: bool, city: string, data_source: string, dealer_id: int, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list<record>, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, is_certified: int, is_searchable: string, last_seen_at: int, last_seen_at_date: string, latitude: string, leasing_options: list<record>, longitude: string, miles: int, msrp: int, price: int, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: int, scraped_at_date: string, seller_name: string, seller_name_o: string, seller_type: string, source: string, state: string, status_date: int, stock_no: string, street: string, trim_r: string, vdp_url: string, vin: string, zip: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($vrm | is-empty) { error make --unspanned { msg: "path parameter 'vrm' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_duplicates" $include_duplicates "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({vrm: (encode-path-segment $vrm)} | format pattern "/history/car/uk/{vrm}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "page": $page, "include_duplicates": $include_duplicates, "sort_order": $sort_order} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a cars online listing history
#
# GET /history/car/{vin}
# operationId: getCarHistory
export def "history-car get" [
  vin: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --fields: string # List of fields to fetch, in case the default fields list in the response is to be trimmed down (format: string)
  --page: float # Page number to fetch the results for the given criteria. Default is 1. (format: number)
  --include-duplicates: oneof<nothing, bool> # Flag to indicate whether to include duplicate historical records as well in the response
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
]: nothing -> table<carfax_1_owner: bool, carfax_clean_title: bool, city: string, data_source: string, dealer_id: int, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list<record>, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, is_certified: int, is_searchable: string, last_seen_at: int, last_seen_at_date: string, latitude: string, leasing_options: list<record>, longitude: string, miles: int, msrp: int, price: int, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: int, scraped_at_date: string, seller_name: string, seller_name_o: string, seller_type: string, source: string, state: string, status_date: int, stock_no: string, street: string, trim_r: string, vdp_url: string, vin: string, zip: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($vin | is-empty) { error make --unspanned { msg: "path parameter 'vin' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_duplicates" $include_duplicates "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({vin: (encode-path-segment $vin)} | format pattern "/history/car/{vin}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "fields": $fields, "page": $page, "include_duplicates": $include_duplicates, "sort_order": $sort_order} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Fetch cached image
#
# GET /image/cache/car/{listingID}/{imageID}
# operationId: getCachedImage
export def "image-cache-car get-cached" [
  listing_id: string
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($listing_id | is-empty) { error make --unspanned { msg: "path parameter 'listingID' must be non-empty" } }
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'imageID' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({listing_id: (encode-path-segment $listing_id), image_id: (encode-path-segment $image_id)} | format pattern "/image/cache/car/{listing_id}/{image_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Listing by id
#
# GET /listing/car/auction/{id}
export def "listing-car-auction get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
  --include-relevant-links: oneof<nothing, bool> # To include_relevant_links. Default is true (default: false)
]: nothing -> record<base_ext_color: string, base_int_color: string, build: record<antibrake_sys: string, body_subtype: string, body_type: string, city_miles: string, city_mpg: int, cylinders: int, doors: int, drivetrain: string, engine: string, engine_aspiration: string, engine_block: string, engine_measure: string, engine_size: float, fuel_type: string, highway_miles: string, highway_mpg: int, made_in: string, make: string, model: string, opt_seating: string, overall_height: string, overall_length: string, overall_width: string, powertrain_type: string, short_trim: string, std_seating: string, steering_type: string, tank_size: string, transmission: string, trim: string, trim_r: string, vehicle_type: string, year: int>, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dom: int, dom_180: int, dom_active: int, exterior_color: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, financing_options: table<down_payment: float, down_payment_percentage: float, estimated_monthly_payment: float, loan_apr: float, loan_term: int>, first_seen_at: int, first_seen_at_date: string, first_seen_at_mc: int, first_seen_at_mc_date: string, first_seen_at_source: int, first_seen_at_source_date: string, heading: string, id: string, interior_color: string, inventory_type: string, is_certified: int, last_seen_at: int, last_seen_at_date: string, leasing_options: table<down_payment: float, estimated_monthly_payment: float, lease_term: int>, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, price_change_percent: float, rank: int, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, score: float, scraped_at: int, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vdp_url: string, vehicle_registration_mark: string, vin: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "append_api_key" $append_api_key "scalar") (serialize-qp "include_relevant_links" $include_relevant_links "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/car/auction/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "append_api_key": $append_api_key, "include_relevant_links": $include_relevant_links} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Long text Listings attributes for Listing with the given id
#
# GET /listing/car/auction/{id}/extra
export def "listing-car-auction-extra get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/car/auction/{id}/extra") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Listing media by id
#
# GET /listing/car/auction/{id}/media
export def "listing-car-auction-media get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
]: nothing -> record<id: string, photo_links: list<string>, photo_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "append_api_key" $append_api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/car/auction/{id}/media") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "append_api_key": $append_api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Listing by id
#
# GET /listing/car/fsbo/{id}
export def "listing-car-fsbo get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
  --include-relevant-links: oneof<nothing, bool> # To include_relevant_links. Default is true (default: false)
]: nothing -> record<base_ext_color: string, base_int_color: string, build: record<antibrake_sys: string, body_subtype: string, body_type: string, city_miles: string, city_mpg: int, cylinders: int, doors: int, drivetrain: string, engine: string, engine_aspiration: string, engine_block: string, engine_measure: string, engine_size: float, fuel_type: string, highway_miles: string, highway_mpg: int, made_in: string, make: string, model: string, opt_seating: string, overall_height: string, overall_length: string, overall_width: string, powertrain_type: string, short_trim: string, std_seating: string, steering_type: string, tank_size: string, transmission: string, trim: string, trim_r: string, vehicle_type: string, year: int>, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dom: int, dom_180: int, dom_active: int, exterior_color: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, financing_options: table<down_payment: float, down_payment_percentage: float, estimated_monthly_payment: float, loan_apr: float, loan_term: int>, first_seen_at: int, first_seen_at_date: string, first_seen_at_mc: int, first_seen_at_mc_date: string, first_seen_at_source: int, first_seen_at_source_date: string, heading: string, id: string, interior_color: string, inventory_type: string, is_certified: int, last_seen_at: int, last_seen_at_date: string, leasing_options: table<down_payment: float, estimated_monthly_payment: float, lease_term: int>, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, price_change_percent: float, rank: int, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, score: float, scraped_at: int, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vdp_url: string, vehicle_registration_mark: string, vin: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "append_api_key" $append_api_key "scalar") (serialize-qp "include_relevant_links" $include_relevant_links "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/car/fsbo/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "append_api_key": $append_api_key, "include_relevant_links": $include_relevant_links} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Long text Listings attributes for Listing with the given id
#
# GET /listing/car/fsbo/{id}/extra
export def "listing-car-fsbo-extra get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/car/fsbo/{id}/extra") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Listing media by id
#
# GET /listing/car/fsbo/{id}/media
export def "listing-car-fsbo-media get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
]: nothing -> record<id: string, photo_links: list<string>, photo_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "append_api_key" $append_api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/car/fsbo/{id}/media") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "append_api_key": $append_api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Listing by id
#
# GET /listing/car/uk/{id}
export def "listing-car-uk get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
]: nothing -> record<base_ext_color: string, base_int_color: string, build: record<antibrake_sys: string, body_subtype: string, body_type: string, city_miles: string, city_mpg: int, cylinders: int, doors: int, drivetrain: string, engine: string, engine_aspiration: string, engine_block: string, engine_measure: string, engine_size: float, fuel_type: string, highway_miles: string, highway_mpg: int, made_in: string, make: string, model: string, opt_seating: string, overall_height: string, overall_length: string, overall_width: string, powertrain_type: string, short_trim: string, std_seating: string, steering_type: string, tank_size: string, transmission: string, trim: string, trim_r: string, vehicle_type: string, year: int>, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dom: int, dom_180: int, dom_active: int, exterior_color: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, financing_options: table<down_payment: float, down_payment_percentage: float, estimated_monthly_payment: float, loan_apr: float, loan_term: int>, first_seen_at: int, first_seen_at_date: string, first_seen_at_mc: int, first_seen_at_mc_date: string, first_seen_at_source: int, first_seen_at_source_date: string, heading: string, id: string, interior_color: string, inventory_type: string, is_certified: int, last_seen_at: int, last_seen_at_date: string, leasing_options: table<down_payment: float, estimated_monthly_payment: float, lease_term: int>, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, price_change_percent: float, rank: int, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, score: float, scraped_at: int, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vdp_url: string, vehicle_registration_mark: string, vin: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "append_api_key" $append_api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/car/uk/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "append_api_key": $append_api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Long text Listings attributes for Listing with the given id
#
# GET /listing/car/uk/{id}/extra
export def "listing-car-uk-extra get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/car/uk/{id}/extra") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Listing media by id
#
# GET /listing/car/uk/{id}/media
export def "listing-car-uk-media get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
]: nothing -> record<id: string, photo_links: list<string>, photo_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "append_api_key" $append_api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/car/uk/{id}/media") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "append_api_key": $append_api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Listing by id
#
# GET /listing/car/{id}
# operationId: getListing
export def "listing-car get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
  --include-relevant-links: oneof<nothing, bool> # To include_relevant_links. Default is true (default: false)
]: nothing -> record<base_ext_color: string, base_int_color: string, build: record<antibrake_sys: string, body_subtype: string, body_type: string, city_miles: string, city_mpg: int, cylinders: int, doors: int, drivetrain: string, engine: string, engine_aspiration: string, engine_block: string, engine_measure: string, engine_size: float, fuel_type: string, highway_miles: string, highway_mpg: int, made_in: string, make: string, model: string, opt_seating: string, overall_height: string, overall_length: string, overall_width: string, powertrain_type: string, short_trim: string, std_seating: string, steering_type: string, tank_size: string, transmission: string, trim: string, trim_r: string, vehicle_type: string, year: int>, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dom: int, dom_180: int, dom_active: int, exterior_color: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, financing_options: table<down_payment: float, down_payment_percentage: float, estimated_monthly_payment: float, loan_apr: float, loan_term: int>, first_seen_at: int, first_seen_at_date: string, first_seen_at_mc: int, first_seen_at_mc_date: string, first_seen_at_source: int, first_seen_at_source_date: string, heading: string, id: string, interior_color: string, inventory_type: string, is_certified: int, last_seen_at: int, last_seen_at_date: string, leasing_options: table<down_payment: float, estimated_monthly_payment: float, lease_term: int>, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, price_change_percent: float, rank: int, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, score: float, scraped_at: int, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vdp_url: string, vehicle_registration_mark: string, vin: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "append_api_key" $append_api_key "scalar") (serialize-qp "include_relevant_links" $include_relevant_links "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/car/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "append_api_key": $append_api_key, "include_relevant_links": $include_relevant_links} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Long text Listings attributes for Listing with the given id
#
# GET /listing/car/{id}/extra
export def "listing-car-extra get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/car/{id}/extra") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Listing media by id
#
# GET /listing/car/{id}/media
export def "listing-car-media get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
]: nothing -> record<id: string, photo_links: list<string>, photo_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "append_api_key" $append_api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/car/{id}/media") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "append_api_key": $append_api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Heavy equipment listing by id
#
# GET /listing/heavy-equipment/{id}
export def "listing-heavy-equipment get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> record<build: record<area: string, class: string, engine: string, fuel_type: string, gvwr: string, length: string, made_in: string, make: string, model: string, sleeps: string, slideouts: string, transmission: string, year: int>, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dp_url: string, exterior_color: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vin: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/heavy-equipment/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Long text Heavy equipment Listings attributes for Listing with the given id
#
# GET /listing/heavy-equipment/{id}/extra
export def "listing-heavy-equipment-extra get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/heavy-equipment/{id}/extra") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Listing media by id
#
# GET /listing/heavy-equipment/{id}/media
export def "listing-heavy-equipment-media get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> record<id: string, photo_links: list<string>, photo_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/heavy-equipment/{id}/media") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Motorcycle listing by id
#
# GET /listing/motorcycle/{id}
export def "listing-motorcycle get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> record<build: record<body_type: string, cylinders: int, drivetrain: string, dry_weight: string, engine: string, fuel_type: string, made_in: string, make: string, model: string, transmission: string, trim: string, vehicle_type: string, year: int>, color: string, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dp_url: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vin: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/motorcycle/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Long text Motorcycle Listings attributes for Listing with the given id
#
# GET /listing/motorcycle/{id}/extra
export def "listing-motorcycle-extra get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/motorcycle/{id}/extra") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Motorcycle listing media by id
#
# GET /listing/motorcycle/{id}/media
export def "listing-motorcycle-media get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> record<id: string, photo_links: list<string>, photo_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/motorcycle/{id}/media") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# RV listing by id
#
# GET /listing/rv/uk/{id}
export def "listing-rv-uk get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> record<build: record<area: string, class: string, engine: string, fuel_type: string, gvwr: string, length: string, made_in: string, make: string, model: string, sleeps: string, slideouts: string, transmission: string, year: int>, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dp_url: string, exterior_color: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vin: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/rv/uk/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Long text RV Listings attributes for Listing with the given id
#
# GET /listing/rv/uk/{id}/extra
export def "listing-rv-uk-extra get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/rv/uk/{id}/extra") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Listing media by id
#
# GET /listing/rv/uk/{id}/media
export def "listing-rv-uk-media get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> record<id: string, photo_links: list<string>, photo_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/rv/uk/{id}/media") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# RV listing by id
#
# GET /listing/rv/{id}
export def "listing-rv get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> record<build: record<area: string, class: string, engine: string, fuel_type: string, gvwr: string, length: string, made_in: string, make: string, model: string, sleeps: string, slideouts: string, transmission: string, year: int>, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dp_url: string, exterior_color: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vin: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/rv/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Long text RV Listings attributes for Listing with the given id
#
# GET /listing/rv/{id}/extra
export def "listing-rv-extra get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/rv/{id}/extra") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Listing media by id
#
# GET /listing/rv/{id}/media
export def "listing-rv-media get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> record<id: string, photo_links: list<string>, photo_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/listing/rv/{id}/media") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Market Days Supply
#
# GET /mds/car
# operationId: getMDS
export def "mds-car get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --vin: string # VIN to decode (format: string)
  --exact: oneof<nothing, bool> # Exact parameter (default: false)
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --msa-code: string # To filter listing on msa code in which they are listed
  --debug: oneof<nothing, bool> # Debug parameter (default: false)
  --include-sold: oneof<nothing, bool> # To fetch sold vins (default: false)
  --country: string@country-completer-3 # To filter listing on Country in which they are listed (default: US)
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --ymmt: string # Comma separated list of Year, Make, Model, Trim combinations. Each combination needs to have the year,make,model, trim values separated by a pipe '|' character in the form year|make|model|trim. e.g. 2010|Audi|A5,2014|Nissan|Sentra|S 6MT,|Honda|City| You could just provide strings of the form - 'year|make||' or 'year|make|model' or '|make|model|' combinations. Individual year / make / model filters provied with the API calls will take precedence over the Year, Make, Model, Trim combinations. The Make, Model, Trim values must be valid values as per the Marketcheck Vin Decoder. If you are using a separate vin decoder then look at using the 'vins' or 'taxonomy_vins' parameter to the search api instead the year|make|model|trim combinations.
  --car-type: string@car-type-completer # Car type. Allowed values are - new / used / certified
  --lease-term: string # Search listings with exact lease term, or inside a range with min and max seperated by a dash like lease_term=30-60
  --lease-down-payment: string # Search listings with exact down payment in lease offers, or inside a range with min and max seperated by a dash like lease_down_payment=30-60
  --lease-emp: string # Search listings with lease offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like lease_emp=30-60
  --finance-loan-term: string # Search listings with exact finance loan term, or inside a range with min and max seperated by a dash like finance_loan_term=30-60
  --finance-loan-apr: string # Search listings with finance offers exactly matching loans Annual Percentage Rate, or inside a range with min and max seperated by a dash like finance_loan_apr=30-60
  --finance-emp: string # Search listings with finance offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like finance_emp=30-60
  --finance-down-payment: string # Search listings with exact down payment in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment=30-60
  --finance-down-payment-per: string # Search listings with exact down payment percentage in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment_per=30-60
  --carfax-1-owner: string@carfax-1-owner-completer # Indicates whether car has had only one owner or not
  --carfax-clean-title: string@carfax-clean-title-completer # Indicates whether car has clean ownership records
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --qp-source: string # To filter listing on their source
  --body-type: string # To filter listing on their body type
  --body-subtype: string # Body subtype to filter the listings on. Valid filter values are those that our Search facets API returns for unique body subtypes. You can pass in multiple body subtype values comma separated (format: string)
  --vehicle-type: string # To filter listing on their vehicle type
  --cylinders: string # To filter listing on their cylinders
  --transmission: string # To filter listing on their transmission
  --doors: string # Doors to filter the cars on. Valid filter values are those that our Search facets API returns for unique doors. You can pass in multiple doors values comma separated (format: string)
  --drivetrain: string # To filter listing on their drivetrain
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --base-exterior-color: string # Base exterior color to match. Valid filter values are those that our Search facets API returns for unique base exterior colors. You can pass in multiple base interior color values comma separated
  --base-interior-color: string # Base interior color to match. Valid filter values are those that our Search facets API returns for unique base interior colors. You can pass in multiple base interior color values comma separated
  --engine: string # To filter listing on their engine
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-aspiration: string # Engine Aspiration to match. Valid filter values are those that our Search facets API returns for unique Engine Aspirations. You can pass in multiple Engine aspirations values comma separated
  --engine-block: string # Engine Block to match. Valid filter values are those that our Search facets API returns for unique Engine Block. You can pass in multiple Engine Block values comma separated
  --highway-mpg-range: string # Highway mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --city-mpg-range: string # City mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --dom-range: string # Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dealership-group-name: string # Name of the dealership group to search for (format: string)
  --dom-active-range: string # Active Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dom-180-range: string # Last 180 Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --fuel-type: string # To filter listing on their fuel type
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --engine-size-range: string # Engine size range to filter listings with engine size in the given range. Range to be given in the format - min-max e.g. 1.0-2 (format: string)
]: nothing -> record<make: string, mds: int, model: string, sold_vins: list<string>, total_active_cars_for_ymmt: int, total_cars_sold_in_last_45_days: int, trim: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "exact" $exact "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "msa_code" $msa_code "scalar") (serialize-qp "debug" $debug "scalar") (serialize-qp "include_sold" $include_sold "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "ymmt" $ymmt "scalar") (serialize-qp "car_type" $car_type "scalar") (serialize-qp "lease_term" $lease_term "scalar") (serialize-qp "lease_down_payment" $lease_down_payment "scalar") (serialize-qp "lease_emp" $lease_emp "scalar") (serialize-qp "finance_loan_term" $finance_loan_term "scalar") (serialize-qp "finance_loan_apr" $finance_loan_apr "scalar") (serialize-qp "finance_emp" $finance_emp "scalar") (serialize-qp "finance_down_payment" $finance_down_payment "scalar") (serialize-qp "finance_down_payment_per" $finance_down_payment_per "scalar") (serialize-qp "carfax_1_owner" $carfax_1_owner "scalar") (serialize-qp "carfax_clean_title" $carfax_clean_title "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "trim" $trim "scalar") (serialize-qp "dealer_id" $dealer_id "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "body_type" $body_type "scalar") (serialize-qp "body_subtype" $body_subtype "scalar") (serialize-qp "vehicle_type" $vehicle_type "scalar") (serialize-qp "cylinders" $cylinders "scalar") (serialize-qp "transmission" $transmission "scalar") (serialize-qp "doors" $doors "scalar") (serialize-qp "drivetrain" $drivetrain "scalar") (serialize-qp "exterior_color" $exterior_color "scalar") (serialize-qp "interior_color" $interior_color "scalar") (serialize-qp "base_exterior_color" $base_exterior_color "scalar") (serialize-qp "base_interior_color" $base_interior_color "scalar") (serialize-qp "engine" $engine "scalar") (serialize-qp "engine_size" $engine_size "scalar") (serialize-qp "engine_aspiration" $engine_aspiration "scalar") (serialize-qp "engine_block" $engine_block "scalar") (serialize-qp "highway_mpg_range" $highway_mpg_range "scalar") (serialize-qp "city_mpg_range" $city_mpg_range "scalar") (serialize-qp "miles_range" $miles_range "scalar") (serialize-qp "price_range" $price_range "scalar") (serialize-qp "msrp_range" $msrp_range "scalar") (serialize-qp "dom_range" $dom_range "scalar") (serialize-qp "dealership_group_name" $dealership_group_name "scalar") (serialize-qp "dom_active_range" $dom_active_range "scalar") (serialize-qp "dom_180_range" $dom_180_range "scalar") (serialize-qp "fuel_type" $fuel_type "scalar") (serialize-qp "dealer_type" $dealer_type "scalar") (serialize-qp "engine_size_range" $engine_size_range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mds/car" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "vin": $vin, "exact": $exact, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "zip": $zip, "msa_code": $msa_code, "debug": $debug, "include_sold": $include_sold, "country": $country, "state": $state, "city": $city, "ymmt": $ymmt, "car_type": $car_type, "lease_term": $lease_term, "lease_down_payment": $lease_down_payment, "lease_emp": $lease_emp, "finance_loan_term": $finance_loan_term, "finance_loan_apr": $finance_loan_apr, "finance_emp": $finance_emp, "finance_down_payment": $finance_down_payment, "finance_down_payment_per": $finance_down_payment_per, "carfax_1_owner": $carfax_1_owner, "carfax_clean_title": $carfax_clean_title, "year": $year, "make": $make, "model": $model, "trim": $trim, "dealer_id": $dealer_id, "source": $qp_source, "body_type": $body_type, "body_subtype": $body_subtype, "vehicle_type": $vehicle_type, "cylinders": $cylinders, "transmission": $transmission, "doors": $doors, "drivetrain": $drivetrain, "exterior_color": $exterior_color, "interior_color": $interior_color, "base_exterior_color": $base_exterior_color, "base_interior_color": $base_interior_color, "engine": $engine, "engine_size": $engine_size, "engine_aspiration": $engine_aspiration, "engine_block": $engine_block, "highway_mpg_range": $highway_mpg_range, "city_mpg_range": $city_mpg_range, "miles_range": $miles_range, "price_range": $price_range, "msrp_range": $msrp_range, "dom_range": $dom_range, "dealership_group_name": $dealership_group_name, "dom_active_range": $dom_active_range, "dom_180_range": $dom_180_range, "fuel_type": $fuel_type, "dealer_type": $dealer_type, "engine_size_range": $engine_size_range} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get make model wise top 50 popular cars on national, state, city level
#
# GET /popular/cars
# operationId: getPopularCars
export def "popular-cars get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --state: string # State level sales count (format: string)
  --city-state: string # City level sales count, pipe seperated like city_state=jacksonville|FL (format: string)
  --car-type: string@car-type-completer-1 # Inventory type for which popular count is to be searched (format: string)
  --country: string@country-completer-3 # Country for which the popular cars are to be searched (default: us)
]: nothing -> record<new_top50: table<city: string, counts: string, dom_stats: record, inventoryType: string, make: string, miles_stats: record, model: string, price_stats: record, state: string>, used_top50: table<city: string, counts: string, dom_stats: record, inventoryType: string, make: string, miles_stats: record, model: string, price_stats: record, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "city_state" $city_state "scalar") (serialize-qp "car_type" $car_type "scalar") (serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/popular/cars" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "state": $state, "city_state": $city_state, "car_type": $car_type, "country": $country} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Predict car price based on it's specifications
#
# GET /predict/car/price
# operationId: predictCarPrice
export def "predict-car-price get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --vin: string # Predict price for a VIN
  --car-type: string@car-type-completer-1 # Car condition
  --year: int # Car manufacturing year
  --make: string # Car's make
  --model: string # Car's model
  --trim: string # Car's trim
  --is-certified: oneof<nothing, bool> # Boolean to indicate car is certified or not
  --carfax-1-owner: oneof<nothing, bool> # Boolean to indicate car is carfax one owner or not
  --carfax-clean-title: oneof<nothing, bool> # Boolean to indicate car has clean title or not
  --base-exterior-color: string # Base exterior color of the car
  --base-interior-color: string # Base interior color of the car
  --transmission: string@transmission-completer # Transmission on the car
  --drivetrain: string@drivetrain-completer # Drivetrain on the car
  --engine-size: float # Engine Size of the car
  --engine-block: string@engine-block-completer # Engine Block of the car
  --cylinders: int # Number of cylinders in the vehicle
  --doors: int # Number of doors in the vehicle
  --highway-mpg: int # Highway mileage
  --city-mpg: int # City mileage of the car
  --latitude: float # Latitude component of the location
  --longitude: float # Longitude component of the location
  --miles: int # miles vehicle has driven in total
  --zip: string # Location zip
  --country: string@country-completer-4 # Country for which car price will be predicted (default: us)
]: nothing -> record<predicted_price: int, price_range: record<lower_bound: int, upper_bound: int>, specs: record<base_exterior_color: string, base_interior_color: string, carfax_1_owner: bool, carfax_clean_title: bool, city_mpg: float, cylinders: int, doors: int, drivetrain: string, engine_block: string, engine_size: float, highway_mpg: float, is_certified: bool, latitude: float, longitude: float, make: string, miles: int, model: string, transmission: string, trim: string, year: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "car_type" $car_type "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "trim" $trim "scalar") (serialize-qp "is_certified" $is_certified "scalar") (serialize-qp "carfax_1_owner" $carfax_1_owner "scalar") (serialize-qp "carfax_clean_title" $carfax_clean_title "scalar") (serialize-qp "base_exterior_color" $base_exterior_color "scalar") (serialize-qp "base_interior_color" $base_interior_color "scalar") (serialize-qp "transmission" $transmission "scalar") (serialize-qp "drivetrain" $drivetrain "scalar") (serialize-qp "engine_size" $engine_size "scalar") (serialize-qp "engine_block" $engine_block "scalar") (serialize-qp "cylinders" $cylinders "scalar") (serialize-qp "doors" $doors "scalar") (serialize-qp "highway_mpg" $highway_mpg "scalar") (serialize-qp "city_mpg" $city_mpg "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "miles" $miles "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/predict/car/price" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "vin": $vin, "car_type": $car_type, "year": $year, "make": $make, "model": $model, "trim": $trim, "is_certified": $is_certified, "carfax_1_owner": $carfax_1_owner, "carfax_clean_title": $carfax_clean_title, "base_exterior_color": $base_exterior_color, "base_interior_color": $base_interior_color, "transmission": $transmission, "drivetrain": $drivetrain, "engine_size": $engine_size, "engine_block": $engine_block, "cylinders": $cylinders, "doors": $doors, "highway_mpg": $highway_mpg, "city_mpg": $city_mpg, "latitude": $latitude, "longitude": $longitude, "miles": $miles, "zip": $zip, "country": $country} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Predict fare value of car for UK based on YMMT & miles
#
# GET /predict/car/uk/fmv
# operationId: fareValue
export def "predict-car-uk-fmv get-fare-value" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --vrm: string # Predict price for a VRM
  --year: int # Car manufacturing year
  --make: string # Car's make
  --model: string # Car's model
  --variant: string # Car's variant
  --miles: int # miles vehicle has driven in total
  --postal-code: string # Postal code of the car
  --radius: int # Radius around postal code
]: nothing -> record<avg_days_to_sold_local: int, avg_days_to_sold_national: int, fmv_local: int, fmv_national: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "vrm" $vrm "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "variant" $variant "scalar") (serialize-qp "miles" $miles "scalar") (serialize-qp "postal_code" $postal_code "scalar") (serialize-qp "radius" $radius "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/predict/car/uk/fmv" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "vrm": $vrm, "year": $year, "make": $make, "model": $model, "variant": $variant, "miles": $miles, "postal_code": $postal_code, "radius": $radius} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Predict car price for UK based on it's specifications
#
# GET /predict/car/uk/price
# operationId: predictUkCarPrice
export def "predict-car-uk-price get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --vrm: string # Predict price for a VRM
  --year: int # Car manufacturing year
  --make: string # Car's make
  --model: string # Car's model
  --trim: string # Car's trim
  --base-exterior-color: string # Base exterior color of the car
  --transmission: string@transmission-completer # Transmission on the car
  --drivetrain: string # Drivetrain on the car
  --engine-size: float # Engine Size of the car (format: double)
  --cylinders: int # Number of cylinders in the vehicle
  --doors: int # Number of doors in the vehicle
  --fuel-type: string # Fuel type of the car
  --highway-mpg: float # Highway mileage (format: double)
  --city-mpg: float # City mileage of the car (format: double)
  --combined-mpg: float # Combiined mileage of the car (format: double)
  --latitude: float # Latitude component of the location
  --longitude: float # Longitude component of the location
  --miles: int # miles vehicle has driven in total
  --zip: string # Location zip
]: nothing -> record<predicted_price: int, price_range: record<lower_bound: int, upper_bound: int>, specs: record<base_exterior_color: string, base_interior_color: string, carfax_1_owner: bool, carfax_clean_title: bool, city_mpg: float, cylinders: int, doors: int, drivetrain: string, engine_block: string, engine_size: float, highway_mpg: float, is_certified: bool, latitude: float, longitude: float, make: string, miles: int, model: string, transmission: string, trim: string, year: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "vrm" $vrm "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "trim" $trim "scalar") (serialize-qp "base_exterior_color" $base_exterior_color "scalar") (serialize-qp "transmission" $transmission "scalar") (serialize-qp "drivetrain" $drivetrain "scalar") (serialize-qp "engine_size" $engine_size "scalar") (serialize-qp "cylinders" $cylinders "scalar") (serialize-qp "doors" $doors "scalar") (serialize-qp "fuel_type" $fuel_type "scalar") (serialize-qp "highway_mpg" $highway_mpg "scalar") (serialize-qp "city_mpg" $city_mpg "scalar") (serialize-qp "combined_mpg" $combined_mpg "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "miles" $miles "scalar") (serialize-qp "zip" $zip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/predict/car/uk/price" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "vrm": $vrm, "year": $year, "make": $make, "model": $model, "trim": $trim, "base_exterior_color": $base_exterior_color, "transmission": $transmission, "drivetrain": $drivetrain, "engine_size": $engine_size, "cylinders": $cylinders, "doors": $doors, "fuel_type": $fuel_type, "highway_mpg": $highway_mpg, "city_mpg": $city_mpg, "combined_mpg": $combined_mpg, "latitude": $latitude, "longitude": $longitude, "miles": $miles, "zip": $zip} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get sales count by make, model, year, trim or taxonomy vin
#
# GET /sales/car
# operationId: getSalesCount
export def "sales-car get-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --car-type: string@car-type-completer-1 # Inventory type for which sales count is to be searched, default is used (format: string, default: used)
  --make: string # Make for which sales count is to be searched (format: string)
  --mm: string # Make-Model for which sales count is to be searched, pipe seperated like mm=ford|f-150 (format: string)
  --ymm: string # Year-Make-Model for which sales count is to be searched, pipe seperated like ymm=2015|ford|f-150 (format: string)
  --ymmt: string # Year-Make-Model-Trim for which sales count is to be searched, pipe seperated like ymmt=2015|ford|f-150|platinum (format: string)
  --taxonomy-vin: string # taxonomy_vin for which sales count is to be searched (format: string)
  --state: string # State level sales count (format: string)
  --city-state: string # City level sales count, pipe seperated like city_state=jacksonville|FL (format: string)
  --vin: string # VIN that will be transformed to taxonomy_vin (format: string)
  --country: string@country-completer-3 # Country for which the sales records are to be searched (default: us)
]: nothing -> record<city: string, counts: int, cpo: int, dom_stats: record<absolute_mean_deviation: float, iqr: float, mean: float, median: float, population_standard_deviation: float, standard_deviation: float, trimmed_mean: float, variance: float, weighted_mean: float>, inventory_type: string, make: string, miles_stats: record<absolute_mean_deviation: float, iqr: float, mean: float, median: float, population_standard_deviation: float, standard_deviation: float, trimmed_mean: float, variance: float, weighted_mean: float>, model: string, non_cpo: int, price_stats: record<absolute_mean_deviation: float, iqr: float, mean: float, median: float, population_standard_deviation: float, standard_deviation: float, trimmed_mean: float, variance: float, weighted_mean: float>, state: string, taxonomy_vin: string, trim: string, year: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "car_type" $car_type "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "mm" $mm "scalar") (serialize-qp "ymm" $ymm "scalar") (serialize-qp "ymmt" $ymmt "scalar") (serialize-qp "taxonomy_vin" $taxonomy_vin "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "city_state" $city_state "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sales/car" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "car_type": $car_type, "make": $make, "mm": $mm, "ymm": $ymm, "ymmt": $ymmt, "taxonomy_vin": $taxonomy_vin, "state": $state, "city_state": $city_state, "vin": $vin, "country": $country} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets active car listings for the given search criteria
#
# GET /search/car/active
export def "search-car-active get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --include-lease: oneof<nothing, bool> # Boolean param to search for listings that include leasing options in them
  --include-finance: oneof<nothing, bool> # Boolean param to search for listings that include finance options in them
  --lease-term: string # Search listings with exact lease term, or inside a range with min and max seperated by a dash like lease_term=30-60
  --lease-down-payment: string # Search listings with exact down payment in lease offers, or inside a range with min and max seperated by a dash like lease_down_payment=30-60
  --lease-emp: string # Search listings with lease offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like lease_emp=30-60
  --finance-loan-term: string # Search listings with exact finance loan term, or inside a range with min and max seperated by a dash like finance_loan_term=30-60
  --finance-loan-apr: string # Search listings with finance offers exactly matching loans Annual Percentage Rate, or inside a range with min and max seperated by a dash like finance_loan_apr=30-60
  --finance-emp: string # Search listings with finance offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like finance_emp=30-60
  --finance-down-payment: string # Search listings with exact down payment in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment=30-60
  --finance-down-payment-per: string # Search listings with exact down payment percentage in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment_per=30-60
  --car-type: string@car-type-completer # Car type. Allowed values are - new / used / certified
  --carfax-1-owner: string@carfax-1-owner-completer # Indicates whether car has had only one owner or not
  --carfax-clean-title: string@carfax-clean-title-completer # Indicates whether car has clean ownership records
  --year-range: string # Year range to filter listings with the year in the range given. Range to be given in the format - min-max e.g. 2019-2021 (format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --vin: string # To filter listing on their VIN
  --body-type: string # To filter listing on their body type
  --body-subtype: string # Body subtype to filter the listings on. Valid filter values are those that our Search facets API returns for unique body subtypes. You can pass in multiple body subtype values comma separated (format: string)
  --vehicle-type: string # To filter listing on their vehicle type
  --vins: string # Comma separated list of 17 digit vins to search the matching cars for. Only 10 VINs allowed per request. If the request contains more than 10 VINs the first 10 VINs will be considered. Could be used as a More Like This or Similar Vehicles search for the given VINs. Ths vins parameter is an alternative to taxonomy_vins or ymmt parameters available with the search API. vins and taxonomy_vins parameters could be used to filter our cars with the exact build represented by the vins or taxonomy_vins whereas ymmt is a top level filter that does not filter cars by the build attributes like doors, drivetrain, cylinders, body type, body subtype, vehicle type etc
  --taxonomy-vins: string # Comma separated list of 10 letters excert from the 17 letter VIN. The 10 letters to be picked up from the 17 letter VIN are - first 8 letters and the 10th and 11th letter. E.g. For a VIN - 1FTFW1EF3EKE57182 the taxonomy vin would be - 1FTFW1EFEK A taxonomy VIN identified a build of a car and could be used to filter our cars of a particular build. This is an alternative to the vin or ymmt parameters to the search API.
  --mm: string # Make-Model concatenated string. To help passing the results of auto-complete API on mm field, use this parameter and pass in the selected value as is
  --ymm: string # Year-Make-Model concatenated string. To help passing the results of auto-complete API on ymm field, use this parameter and pass in the selected value as is
  --ymmt: string # Comma separated list of Year, Make, Model, Trim combinations. Each combination needs to have the year,make,model, trim values separated by a pipe '|' character in the form year|make|model|trim. e.g. 2010|Audi|A5,2014|Nissan|Sentra|S 6MT,|Honda|City| You could just provide strings of the form - 'year|make||' or 'year|make|model' or '|make|model|' combinations. Individual year / make / model filters provied with the API calls will take precedence over the Year, Make, Model, Trim combinations. The Make, Model, Trim values must be valid values as per the Marketcheck Vin Decoder. If you are using a separate vin decoder then look at using the 'vins' or 'taxonomy_vins' parameter to the search api instead the year|make|model|trim combinations.
  --qp-match: string # Comma separated list of Year, Make, Model, Trim fields. For example - year,make,model,trim fields for which user wants to do an exact match
  --cylinders: string # To filter listing on their cylinders
  --transmission: string # To filter listing on their transmission
  --doors: string # Doors to filter the cars on. Valid filter values are those that our Search facets API returns for unique doors. You can pass in multiple doors values comma separated (format: string)
  --drivetrain: string # To filter listing on their drivetrain
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --base-exterior-color: string # Base exterior color to match. Valid filter values are those that our Search facets API returns for unique base exterior colors. You can pass in multiple base interior color values comma separated
  --base-interior-color: string # Base interior color to match. Valid filter values are those that our Search facets API returns for unique base interior colors. You can pass in multiple base interior color values comma separated
  --engine: string # To filter listing on their engine
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-aspiration: string # Engine Aspiration to match. Valid filter values are those that our Search facets API returns for unique Engine Aspirations. You can pass in multiple Engine aspirations values comma separated
  --engine-block: string # Engine Block to match. Valid filter values are those that our Search facets API returns for unique Engine Block. You can pass in multiple Engine Block values comma separated
  --highway-mpg-range: string # Highway mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --city-mpg-range: string # City mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --dom-range: string # Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --include-non-vin-listings: oneof<nothing, bool> # To include non vin listings. Default is false (default: false)
  --msa-code: string # To filter listing on msa code in which they are listed
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --country: string@country-completer # To filter listing on Country in which they are listed (default: US)
  --plot: oneof<nothing, bool> # If plot has value true results in around 25k coordinates with limited fields to plot respective graph
  --nodedup: oneof<nothing, bool> # If nodedup is set to true then API will give results without is_searchable i.e multiple listings for single vin
  --dedup: oneof<nothing, bool> # If dedup is set to true then will give results with is_searchable irrespecive of dealer_id or source
  --owned: oneof<nothing, bool> # Used in combination with dealer_id or source, when true returns the listings actually owned by dealer himself
  --qp-source: string # To filter listing on their source only for widget requests
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --trim-o: string # Filter listings on web scraped trim
  --trim-r: string # Filter trim on custom possible matches
  --dom-active-range: string # Active Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dom-180-range: string # Last 180 Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --exclude-certified: oneof<nothing, bool> # Boolean param to exclude certified cars from search results
  --fuel-type: string # To filter listing on their fuel type
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --photo-links: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links in search results, And discard those that don't have them
  --photo-links-cached: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links_cached in search results, And discard those that don't have them
  --stock-no: string # To filter listing on their stock number on lot
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-source-range: string # First seen at source date range to filter listings with the first seen at source in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-mc-range: string # First seen at MC date range to filter listings with the first seen at MC in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-source-days: string # First seen at source days range to filter listings with the first seen at source in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-mc-days: string # First seen at MC days range to filter listings with the first seen at MC in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --include-relevant-links: oneof<nothing, bool> # To include_relevant_links. Default is true (default: false)
  --inventory-count-range: string # Inventory count range to filter listings with count of total listings in dealers inventory. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --exclude-dealer-ids: string # A list of dealer ids to exclude from result (format: string)
  --exclude-sources: string # A list of sources to exclude from result (format: string)
  --in-transit: string@in-transit-completer # A boolean to filter in transit vehicles
  --seating-capacity: string # To filter on vehicle seating capacity (format: string)
  --powertrain-type: string # To filter on powertrain_type (format: string)
  --price-change: string@price-change-completer # Query to filter listings based on their positive and negative price change
  --price-change-range: string # Price change range to filter listings with price change within given price_change_range. Range to be given in the format - min-max e.g. 10-500 (format: string)
  --active-inventory-date-range: string # date range to filter listings that were active within given date range. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --engine-size-range: string # Engine size range to filter listings with engine size in the given range. Range to be given in the format - min-max e.g. 1.0-2 (format: string)
  --high-value-features: string # To filter listings on their high_value_features. Results will be intersection of provided HVFs
  --min-photo-links: string # Filter listings based by number of photo links within given range (format: string)
  --min-photo-links-cached: string # Filter listings based by number of cached photo links within given range (format: string)
]: nothing -> record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fuel_type: list<record>, interior_color: list<record>, make: list<record>, model: list<record>, seller_name: list<record>, seller_name_o: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, trim_o: list<record>, trim_r: list<record>, vehicle_type: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, vdp_url: string, vin: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "append_api_key" $append_api_key "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "include_lease" $include_lease "scalar") (serialize-qp "include_finance" $include_finance "scalar") (serialize-qp "lease_term" $lease_term "scalar") (serialize-qp "lease_down_payment" $lease_down_payment "scalar") (serialize-qp "lease_emp" $lease_emp "scalar") (serialize-qp "finance_loan_term" $finance_loan_term "scalar") (serialize-qp "finance_loan_apr" $finance_loan_apr "scalar") (serialize-qp "finance_emp" $finance_emp "scalar") (serialize-qp "finance_down_payment" $finance_down_payment "scalar") (serialize-qp "finance_down_payment_per" $finance_down_payment_per "scalar") (serialize-qp "car_type" $car_type "scalar") (serialize-qp "carfax_1_owner" $carfax_1_owner "scalar") (serialize-qp "carfax_clean_title" $carfax_clean_title "scalar") (serialize-qp "year_range" $year_range "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "trim" $trim "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "body_type" $body_type "scalar") (serialize-qp "body_subtype" $body_subtype "scalar") (serialize-qp "vehicle_type" $vehicle_type "scalar") (serialize-qp "vins" $vins "scalar") (serialize-qp "taxonomy_vins" $taxonomy_vins "scalar") (serialize-qp "mm" $mm "scalar") (serialize-qp "ymm" $ymm "scalar") (serialize-qp "ymmt" $ymmt "scalar") (serialize-qp "match" $qp_match "scalar") (serialize-qp "cylinders" $cylinders "scalar") (serialize-qp "transmission" $transmission "scalar") (serialize-qp "doors" $doors "scalar") (serialize-qp "drivetrain" $drivetrain "scalar") (serialize-qp "exterior_color" $exterior_color "scalar") (serialize-qp "interior_color" $interior_color "scalar") (serialize-qp "base_exterior_color" $base_exterior_color "scalar") (serialize-qp "base_interior_color" $base_interior_color "scalar") (serialize-qp "engine" $engine "scalar") (serialize-qp "engine_size" $engine_size "scalar") (serialize-qp "engine_aspiration" $engine_aspiration "scalar") (serialize-qp "engine_block" $engine_block "scalar") (serialize-qp "highway_mpg_range" $highway_mpg_range "scalar") (serialize-qp "city_mpg_range" $city_mpg_range "scalar") (serialize-qp "miles_range" $miles_range "scalar") (serialize-qp "price_range" $price_range "scalar") (serialize-qp "msrp_range" $msrp_range "scalar") (serialize-qp "dom_range" $dom_range "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "include_non_vin_listings" $include_non_vin_listings "scalar") (serialize-qp "msa_code" $msa_code "scalar") (serialize-qp "facets" $facets "scalar") (serialize-qp "range_facets" $range_facets "scalar") (serialize-qp "facet_sort" $facet_sort "scalar") (serialize-qp "stats" $stats "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "plot" $plot "scalar") (serialize-qp "nodedup" $nodedup "scalar") (serialize-qp "dedup" $dedup "scalar") (serialize-qp "owned" $owned "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "trim_o" $trim_o "scalar") (serialize-qp "trim_r" $trim_r "scalar") (serialize-qp "dom_active_range" $dom_active_range "scalar") (serialize-qp "dom_180_range" $dom_180_range "scalar") (serialize-qp "exclude_certified" $exclude_certified "scalar") (serialize-qp "fuel_type" $fuel_type "scalar") (serialize-qp "dealer_type" $dealer_type "scalar") (serialize-qp "photo_links" $photo_links "scalar") (serialize-qp "photo_links_cached" $photo_links_cached "scalar") (serialize-qp "stock_no" $stock_no "scalar") (serialize-qp "last_seen_range" $last_seen_range "scalar") (serialize-qp "first_seen_range" $first_seen_range "scalar") (serialize-qp "first_seen_at_source_range" $first_seen_at_source_range "scalar") (serialize-qp "first_seen_at_mc_range" $first_seen_at_mc_range "scalar") (serialize-qp "last_seen_days" $last_seen_days "scalar") (serialize-qp "first_seen_days" $first_seen_days "scalar") (serialize-qp "first_seen_at_source_days" $first_seen_at_source_days "scalar") (serialize-qp "first_seen_at_mc_days" $first_seen_at_mc_days "scalar") (serialize-qp "include_relevant_links" $include_relevant_links "scalar") (serialize-qp "inventory_count_range" $inventory_count_range "scalar") (serialize-qp "dealer_id" $dealer_id "scalar") (serialize-qp "exclude_dealer_ids" $exclude_dealer_ids "scalar") (serialize-qp "exclude_sources" $exclude_sources "scalar") (serialize-qp "in_transit" $in_transit "scalar") (serialize-qp "seating_capacity" $seating_capacity "scalar") (serialize-qp "powertrain_type" $powertrain_type "scalar") (serialize-qp "price_change" $price_change "scalar") (serialize-qp "price_change_range" $price_change_range "scalar") (serialize-qp "active_inventory_date_range" $active_inventory_date_range "scalar") (serialize-qp "engine_size_range" $engine_size_range "scalar") (serialize-qp "high_value_features" $high_value_features "scalar") (serialize-qp "min_photo_links" $min_photo_links "scalar") (serialize-qp "min_photo_links_cached" $min_photo_links_cached "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/car/active" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "append_api_key": $append_api_key, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "zip": $zip, "include_lease": $include_lease, "include_finance": $include_finance, "lease_term": $lease_term, "lease_down_payment": $lease_down_payment, "lease_emp": $lease_emp, "finance_loan_term": $finance_loan_term, "finance_loan_apr": $finance_loan_apr, "finance_emp": $finance_emp, "finance_down_payment": $finance_down_payment, "finance_down_payment_per": $finance_down_payment_per, "car_type": $car_type, "carfax_1_owner": $carfax_1_owner, "carfax_clean_title": $carfax_clean_title, "year_range": $year_range, "year": $year, "make": $make, "model": $model, "trim": $trim, "vin": $vin, "body_type": $body_type, "body_subtype": $body_subtype, "vehicle_type": $vehicle_type, "vins": $vins, "taxonomy_vins": $taxonomy_vins, "mm": $mm, "ymm": $ymm, "ymmt": $ymmt, "match": $qp_match, "cylinders": $cylinders, "transmission": $transmission, "doors": $doors, "drivetrain": $drivetrain, "exterior_color": $exterior_color, "interior_color": $interior_color, "base_exterior_color": $base_exterior_color, "base_interior_color": $base_interior_color, "engine": $engine, "engine_size": $engine_size, "engine_aspiration": $engine_aspiration, "engine_block": $engine_block, "highway_mpg_range": $highway_mpg_range, "city_mpg_range": $city_mpg_range, "miles_range": $miles_range, "price_range": $price_range, "msrp_range": $msrp_range, "dom_range": $dom_range, "sort_by": $sort_by, "sort_order": $sort_order, "rows": $rows, "start": $start, "include_non_vin_listings": $include_non_vin_listings, "msa_code": $msa_code, "facets": $facets, "range_facets": $range_facets, "facet_sort": $facet_sort, "stats": $stats, "country": $country, "plot": $plot, "nodedup": $nodedup, "dedup": $dedup, "owned": $owned, "source": $qp_source, "state": $state, "city": $city, "trim_o": $trim_o, "trim_r": $trim_r, "dom_active_range": $dom_active_range, "dom_180_range": $dom_180_range, "exclude_certified": $exclude_certified, "fuel_type": $fuel_type, "dealer_type": $dealer_type, "photo_links": $photo_links, "photo_links_cached": $photo_links_cached, "stock_no": $stock_no, "last_seen_range": $last_seen_range, "first_seen_range": $first_seen_range, "first_seen_at_source_range": $first_seen_at_source_range, "first_seen_at_mc_range": $first_seen_at_mc_range, "last_seen_days": $last_seen_days, "first_seen_days": $first_seen_days, "first_seen_at_source_days": $first_seen_at_source_days, "first_seen_at_mc_days": $first_seen_at_mc_days, "include_relevant_links": $include_relevant_links, "inventory_count_range": $inventory_count_range, "dealer_id": $dealer_id, "exclude_dealer_ids": $exclude_dealer_ids, "exclude_sources": $exclude_sources, "in_transit": $in_transit, "seating_capacity": $seating_capacity, "powertrain_type": $powertrain_type, "price_change": $price_change, "price_change_range": $price_change_range, "active_inventory_date_range": $active_inventory_date_range, "engine_size_range": $engine_size_range, "high_value_features": $high_value_features, "min_photo_links": $min_photo_links, "min_photo_links_cached": $min_photo_links_cached} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Compute relative rank for car listings.
#
# POST /search/car/active/rank
# operationId: searchAndRankCar
export def "search-car-active-rank list-and" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --include-lease: oneof<nothing, bool> # Boolean param to search for listings that include leasing options in them
  --include-finance: oneof<nothing, bool> # Boolean param to search for listings that include finance options in them
  --lease-term: string # Search listings with exact lease term, or inside a range with min and max seperated by a dash like lease_term=30-60
  --lease-down-payment: string # Search listings with exact down payment in lease offers, or inside a range with min and max seperated by a dash like lease_down_payment=30-60
  --lease-emp: string # Search listings with lease offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like lease_emp=30-60
  --finance-loan-term: string # Search listings with exact finance loan term, or inside a range with min and max seperated by a dash like finance_loan_term=30-60
  --finance-loan-apr: string # Search listings with finance offers exactly matching loans Annual Percentage Rate, or inside a range with min and max seperated by a dash like finance_loan_apr=30-60
  --finance-emp: string # Search listings with finance offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like finance_emp=30-60
  --finance-down-payment: string # Search listings with exact down payment in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment=30-60
  --finance-down-payment-per: string # Search listings with exact down payment percentage in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment_per=30-60
  --car-type: string@car-type-completer # Car type. Allowed values are - new / used / certified
  --carfax-1-owner: string@carfax-1-owner-completer # Indicates whether car has had only one owner or not
  --carfax-clean-title: string@carfax-clean-title-completer # Indicates whether car has clean ownership records
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --vin: string # To filter listing on their VIN
  --body-type: string # To filter listing on their body type
  --body-subtype: string # Body subtype to filter the listings on. Valid filter values are those that our Search facets API returns for unique body subtypes. You can pass in multiple body subtype values comma separated (format: string)
  --vehicle-type: string # To filter listing on their vehicle type
  --vins: string # Comma separated list of 17 digit vins to search the matching cars for. Only 10 VINs allowed per request. If the request contains more than 10 VINs the first 10 VINs will be considered. Could be used as a More Like This or Similar Vehicles search for the given VINs. Ths vins parameter is an alternative to taxonomy_vins or ymmt parameters available with the search API. vins and taxonomy_vins parameters could be used to filter our cars with the exact build represented by the vins or taxonomy_vins whereas ymmt is a top level filter that does not filter cars by the build attributes like doors, drivetrain, cylinders, body type, body subtype, vehicle type etc
  --taxonomy-vins: string # Comma separated list of 10 letters excert from the 17 letter VIN. The 10 letters to be picked up from the 17 letter VIN are - first 8 letters and the 10th and 11th letter. E.g. For a VIN - 1FTFW1EF3EKE57182 the taxonomy vin would be - 1FTFW1EFEK A taxonomy VIN identified a build of a car and could be used to filter our cars of a particular build. This is an alternative to the vin or ymmt parameters to the search API.
  --ymmt: string # Comma separated list of Year, Make, Model, Trim combinations. Each combination needs to have the year,make,model, trim values separated by a pipe '|' character in the form year|make|model|trim. e.g. 2010|Audi|A5,2014|Nissan|Sentra|S 6MT,|Honda|City| You could just provide strings of the form - 'year|make||' or 'year|make|model' or '|make|model|' combinations. Individual year / make / model filters provied with the API calls will take precedence over the Year, Make, Model, Trim combinations. The Make, Model, Trim values must be valid values as per the Marketcheck Vin Decoder. If you are using a separate vin decoder then look at using the 'vins' or 'taxonomy_vins' parameter to the search api instead the year|make|model|trim combinations.
  --qp-match: string # Comma separated list of Year, Make, Model, Trim fields. For example - year,make,model,trim fields for which user wants to do an exact match
  --cylinders: string # To filter listing on their cylinders
  --transmission: string # To filter listing on their transmission
  --doors: string # Doors to filter the cars on. Valid filter values are those that our Search facets API returns for unique doors. You can pass in multiple doors values comma separated (format: string)
  --drivetrain: string # To filter listing on their drivetrain
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --base-exterior-color: string # Base exterior color to match. Valid filter values are those that our Search facets API returns for unique base exterior colors. You can pass in multiple base interior color values comma separated
  --base-interior-color: string # Base interior color to match. Valid filter values are those that our Search facets API returns for unique base interior colors. You can pass in multiple base interior color values comma separated
  --engine: string # To filter listing on their engine
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-aspiration: string # Engine Aspiration to match. Valid filter values are those that our Search facets API returns for unique Engine Aspirations. You can pass in multiple Engine aspirations values comma separated
  --engine-block: string # Engine Block to match. Valid filter values are those that our Search facets API returns for unique Engine Block. You can pass in multiple Engine Block values comma separated
  --highway-mpg-range: string # Highway mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --city-mpg-range: string # City mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string, default: 1-)
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string, default: 1-)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --dom-range: string # Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --include-non-vin-listings: oneof<nothing, bool> # To include non vin listings. Default is false (default: false)
  --msa-code: string # To filter listing on msa code in which they are listed
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --country: string@country-completer # To filter listing on Country in which they are listed (default: US)
  --plot: oneof<nothing, bool> # If plot has value true results in around 25k coordinates with limited fields to plot respective graph
  --nodedup: oneof<nothing, bool> # If nodedup is set to true then API will give results without is_searchable i.e multiple listings for single vin
  --dedup: oneof<nothing, bool> # If dedup is set to true then will give results with is_searchable irrespecive of dealer_id or source
  --owned: oneof<nothing, bool> # Used in combination with dealer_id or source, when true returns the listings actually owned by dealer himself
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --trim-o: string # Filter listings on web scraped trim
  --trim-r: string # Filter trim on custom possible matches
  --dom-active-range: string # Active Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dom-180-range: string # Last 180 Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --exclude-certified: oneof<nothing, bool> # Boolean param to exclude certified cars from search results
  --fuel-type: string # To filter listing on their fuel type
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --photo-links: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links in search results, And discard those that don't have them
  --photo-links-cached: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links_cached in search results, And discard those that don't have them
  --stock-no: string # To filter listing on their stock number on lot
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-source-range: string # First seen at source date range to filter listings with the first seen at source in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-mc-range: string # First seen at MC date range to filter listings with the first seen at MC in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-source-days: string # First seen at source days range to filter listings with the first seen at source in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-mc-days: string # First seen at MC days range to filter listings with the first seen at MC in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --inventory-type: string@inventory-type-completer # To filter listing on their condition. Either used or new
  --page: float # Page number to fetch the results for the given criteria. Default is 1. (format: number)
  --listing-ids: list<string>
  --ranking-criteria: record
]: any -> record<num_ranked: int, ranked_listings: table<ranked_listing: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "append_api_key" $append_api_key "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "include_lease" $include_lease "scalar") (serialize-qp "include_finance" $include_finance "scalar") (serialize-qp "lease_term" $lease_term "scalar") (serialize-qp "lease_down_payment" $lease_down_payment "scalar") (serialize-qp "lease_emp" $lease_emp "scalar") (serialize-qp "finance_loan_term" $finance_loan_term "scalar") (serialize-qp "finance_loan_apr" $finance_loan_apr "scalar") (serialize-qp "finance_emp" $finance_emp "scalar") (serialize-qp "finance_down_payment" $finance_down_payment "scalar") (serialize-qp "finance_down_payment_per" $finance_down_payment_per "scalar") (serialize-qp "car_type" $car_type "scalar") (serialize-qp "carfax_1_owner" $carfax_1_owner "scalar") (serialize-qp "carfax_clean_title" $carfax_clean_title "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "trim" $trim "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "body_type" $body_type "scalar") (serialize-qp "body_subtype" $body_subtype "scalar") (serialize-qp "vehicle_type" $vehicle_type "scalar") (serialize-qp "vins" $vins "scalar") (serialize-qp "taxonomy_vins" $taxonomy_vins "scalar") (serialize-qp "ymmt" $ymmt "scalar") (serialize-qp "match" $qp_match "scalar") (serialize-qp "cylinders" $cylinders "scalar") (serialize-qp "transmission" $transmission "scalar") (serialize-qp "doors" $doors "scalar") (serialize-qp "drivetrain" $drivetrain "scalar") (serialize-qp "exterior_color" $exterior_color "scalar") (serialize-qp "interior_color" $interior_color "scalar") (serialize-qp "base_exterior_color" $base_exterior_color "scalar") (serialize-qp "base_interior_color" $base_interior_color "scalar") (serialize-qp "engine" $engine "scalar") (serialize-qp "engine_size" $engine_size "scalar") (serialize-qp "engine_aspiration" $engine_aspiration "scalar") (serialize-qp "engine_block" $engine_block "scalar") (serialize-qp "highway_mpg_range" $highway_mpg_range "scalar") (serialize-qp "city_mpg_range" $city_mpg_range "scalar") (serialize-qp "miles_range" $miles_range "scalar") (serialize-qp "price_range" $price_range "scalar") (serialize-qp "msrp_range" $msrp_range "scalar") (serialize-qp "dom_range" $dom_range "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "include_non_vin_listings" $include_non_vin_listings "scalar") (serialize-qp "msa_code" $msa_code "scalar") (serialize-qp "facets" $facets "scalar") (serialize-qp "range_facets" $range_facets "scalar") (serialize-qp "facet_sort" $facet_sort "scalar") (serialize-qp "stats" $stats "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "plot" $plot "scalar") (serialize-qp "nodedup" $nodedup "scalar") (serialize-qp "dedup" $dedup "scalar") (serialize-qp "owned" $owned "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "trim_o" $trim_o "scalar") (serialize-qp "trim_r" $trim_r "scalar") (serialize-qp "dom_active_range" $dom_active_range "scalar") (serialize-qp "dom_180_range" $dom_180_range "scalar") (serialize-qp "exclude_certified" $exclude_certified "scalar") (serialize-qp "fuel_type" $fuel_type "scalar") (serialize-qp "dealer_type" $dealer_type "scalar") (serialize-qp "photo_links" $photo_links "scalar") (serialize-qp "photo_links_cached" $photo_links_cached "scalar") (serialize-qp "stock_no" $stock_no "scalar") (serialize-qp "last_seen_range" $last_seen_range "scalar") (serialize-qp "first_seen_range" $first_seen_range "scalar") (serialize-qp "first_seen_at_source_range" $first_seen_at_source_range "scalar") (serialize-qp "first_seen_at_mc_range" $first_seen_at_mc_range "scalar") (serialize-qp "last_seen_days" $last_seen_days "scalar") (serialize-qp "first_seen_days" $first_seen_days "scalar") (serialize-qp "first_seen_at_source_days" $first_seen_at_source_days "scalar") (serialize-qp "first_seen_at_mc_days" $first_seen_at_mc_days "scalar") (serialize-qp "inventory_type" $inventory_type "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/car/active/rank" $qp $auth.query)
  let req_body = {"listing_ids": $listing_ids, "ranking_criteria": $ranking_criteria} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api_key": $api_key, "append_api_key": $append_api_key, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "zip": $zip, "include_lease": $include_lease, "include_finance": $include_finance, "lease_term": $lease_term, "lease_down_payment": $lease_down_payment, "lease_emp": $lease_emp, "finance_loan_term": $finance_loan_term, "finance_loan_apr": $finance_loan_apr, "finance_emp": $finance_emp, "finance_down_payment": $finance_down_payment, "finance_down_payment_per": $finance_down_payment_per, "car_type": $car_type, "carfax_1_owner": $carfax_1_owner, "carfax_clean_title": $carfax_clean_title, "year": $year, "make": $make, "model": $model, "trim": $trim, "vin": $vin, "body_type": $body_type, "body_subtype": $body_subtype, "vehicle_type": $vehicle_type, "vins": $vins, "taxonomy_vins": $taxonomy_vins, "ymmt": $ymmt, "match": $qp_match, "cylinders": $cylinders, "transmission": $transmission, "doors": $doors, "drivetrain": $drivetrain, "exterior_color": $exterior_color, "interior_color": $interior_color, "base_exterior_color": $base_exterior_color, "base_interior_color": $base_interior_color, "engine": $engine, "engine_size": $engine_size, "engine_aspiration": $engine_aspiration, "engine_block": $engine_block, "highway_mpg_range": $highway_mpg_range, "city_mpg_range": $city_mpg_range, "miles_range": $miles_range, "price_range": $price_range, "msrp_range": $msrp_range, "dom_range": $dom_range, "sort_by": $sort_by, "sort_order": $sort_order, "rows": $rows, "start": $start, "include_non_vin_listings": $include_non_vin_listings, "msa_code": $msa_code, "facets": $facets, "range_facets": $range_facets, "facet_sort": $facet_sort, "stats": $stats, "country": $country, "plot": $plot, "nodedup": $nodedup, "dedup": $dedup, "owned": $owned, "state": $state, "city": $city, "trim_o": $trim_o, "trim_r": $trim_r, "dom_active_range": $dom_active_range, "dom_180_range": $dom_180_range, "exclude_certified": $exclude_certified, "fuel_type": $fuel_type, "dealer_type": $dealer_type, "photo_links": $photo_links, "photo_links_cached": $photo_links_cached, "stock_no": $stock_no, "last_seen_range": $last_seen_range, "first_seen_range": $first_seen_range, "first_seen_at_source_range": $first_seen_at_source_range, "first_seen_at_mc_range": $first_seen_at_mc_range, "last_seen_days": $last_seen_days, "first_seen_days": $first_seen_days, "first_seen_at_source_days": $first_seen_at_source_days, "first_seen_at_mc_days": $first_seen_at_mc_days, "inventory_type": $inventory_type, "page": $page} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Compute relative rank for car listings.
#
# POST /search/car/active/rank/listings
# operationId: rankCar
export def "search-car-active-rank-listings create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
  --listing-ids: list<string>
  --ranking-criteria: record
]: any -> record<num_ranked: int, ranked_listings: table<ranked_listing: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "append_api_key" $append_api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/car/active/rank/listings" $qp $auth.query)
  let req_body = {"listing_ids": $listing_ids, "ranking_criteria": $ranking_criteria} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api_key": $api_key, "append_api_key": $append_api_key} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets active auction car listings for the given search criteria
#
# GET /search/car/auction/active
export def "search-car-auction-active get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --include-lease: oneof<nothing, bool> # Boolean param to search for listings that include leasing options in them
  --include-finance: oneof<nothing, bool> # Boolean param to search for listings that include finance options in them
  --lease-term: string # Search listings with exact lease term, or inside a range with min and max seperated by a dash like lease_term=30-60
  --lease-down-payment: string # Search listings with exact down payment in lease offers, or inside a range with min and max seperated by a dash like lease_down_payment=30-60
  --lease-emp: string # Search listings with lease offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like lease_emp=30-60
  --finance-loan-term: string # Search listings with exact finance loan term, or inside a range with min and max seperated by a dash like finance_loan_term=30-60
  --finance-loan-apr: string # Search listings with finance offers exactly matching loans Annual Percentage Rate, or inside a range with min and max seperated by a dash like finance_loan_apr=30-60
  --finance-emp: string # Search listings with finance offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like finance_emp=30-60
  --finance-down-payment: string # Search listings with exact down payment in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment=30-60
  --finance-down-payment-per: string # Search listings with exact down payment percentage in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment_per=30-60
  --car-type: string@car-type-completer # Car type. Allowed values are - new / used / certified
  --carfax-1-owner: string@carfax-1-owner-completer # Indicates whether car has had only one owner or not
  --carfax-clean-title: string@carfax-clean-title-completer # Indicates whether car has clean ownership records
  --year-range: string # Year range to filter listings with the year in the range given. Range to be given in the format - min-max e.g. 2019-2021 (format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --vin: string # To filter listing on their VIN
  --body-type: string # To filter listing on their body type
  --body-subtype: string # Body subtype to filter the listings on. Valid filter values are those that our Search facets API returns for unique body subtypes. You can pass in multiple body subtype values comma separated (format: string)
  --vehicle-type: string # To filter listing on their vehicle type
  --vins: string # Comma separated list of 17 digit vins to search the matching cars for. Only 10 VINs allowed per request. If the request contains more than 10 VINs the first 10 VINs will be considered. Could be used as a More Like This or Similar Vehicles search for the given VINs. Ths vins parameter is an alternative to taxonomy_vins or ymmt parameters available with the search API. vins and taxonomy_vins parameters could be used to filter our cars with the exact build represented by the vins or taxonomy_vins whereas ymmt is a top level filter that does not filter cars by the build attributes like doors, drivetrain, cylinders, body type, body subtype, vehicle type etc
  --taxonomy-vins: string # Comma separated list of 10 letters excert from the 17 letter VIN. The 10 letters to be picked up from the 17 letter VIN are - first 8 letters and the 10th and 11th letter. E.g. For a VIN - 1FTFW1EF3EKE57182 the taxonomy vin would be - 1FTFW1EFEK A taxonomy VIN identified a build of a car and could be used to filter our cars of a particular build. This is an alternative to the vin or ymmt parameters to the search API.
  --mm: string # Make-Model concatenated string. To help passing the results of auto-complete API on mm field, use this parameter and pass in the selected value as is
  --ymm: string # Year-Make-Model concatenated string. To help passing the results of auto-complete API on ymm field, use this parameter and pass in the selected value as is
  --ymmt: string # Comma separated list of Year, Make, Model, Trim combinations. Each combination needs to have the year,make,model, trim values separated by a pipe '|' character in the form year|make|model|trim. e.g. 2010|Audi|A5,2014|Nissan|Sentra|S 6MT,|Honda|City| You could just provide strings of the form - 'year|make||' or 'year|make|model' or '|make|model|' combinations. Individual year / make / model filters provied with the API calls will take precedence over the Year, Make, Model, Trim combinations. The Make, Model, Trim values must be valid values as per the Marketcheck Vin Decoder. If you are using a separate vin decoder then look at using the 'vins' or 'taxonomy_vins' parameter to the search api instead the year|make|model|trim combinations.
  --qp-match: string # Comma separated list of Year, Make, Model, Trim fields. For example - year,make,model,trim fields for which user wants to do an exact match
  --cylinders: string # To filter listing on their cylinders
  --transmission: string # To filter listing on their transmission
  --doors: string # Doors to filter the cars on. Valid filter values are those that our Search facets API returns for unique doors. You can pass in multiple doors values comma separated (format: string)
  --drivetrain: string # To filter listing on their drivetrain
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --base-exterior-color: string # Base exterior color to match. Valid filter values are those that our Search facets API returns for unique base exterior colors. You can pass in multiple base interior color values comma separated
  --base-interior-color: string # Base interior color to match. Valid filter values are those that our Search facets API returns for unique base interior colors. You can pass in multiple base interior color values comma separated
  --engine: string # To filter listing on their engine
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-aspiration: string # Engine Aspiration to match. Valid filter values are those that our Search facets API returns for unique Engine Aspirations. You can pass in multiple Engine aspirations values comma separated
  --engine-block: string # Engine Block to match. Valid filter values are those that our Search facets API returns for unique Engine Block. You can pass in multiple Engine Block values comma separated
  --highway-mpg-range: string # Highway mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --city-mpg-range: string # City mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --dom-range: string # Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --include-non-vin-listings: oneof<nothing, bool> # To include non vin listings. Default is false (default: false)
  --msa-code: string # To filter listing on msa code in which they are listed
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --country: string@country-completer # To filter listing on Country in which they are listed (default: US)
  --plot: oneof<nothing, bool> # If plot has value true results in around 25k coordinates with limited fields to plot respective graph
  --nodedup: oneof<nothing, bool> # If nodedup is set to true then API will give results without is_searchable i.e multiple listings for single vin
  --dedup: oneof<nothing, bool> # If dedup is set to true then will give results with is_searchable irrespecive of dealer_id or source
  --owned: oneof<nothing, bool> # Used in combination with dealer_id or source, when true returns the listings actually owned by dealer himself
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --qp-source: string # To filter listing on their source only for widget requests
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --trim-o: string # Filter listings on web scraped trim
  --trim-r: string # Filter trim on custom possible matches
  --dom-active-range: string # Active Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dom-180-range: string # Last 180 Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --exclude-certified: oneof<nothing, bool> # Boolean param to exclude certified cars from search results
  --fuel-type: string # To filter listing on their fuel type
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --photo-links: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links in search results, And discard those that don't have them
  --photo-links-cached: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links_cached in search results, And discard those that don't have them
  --stock-no: string # To filter listing on their stock number on lot
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-source-range: string # First seen at source date range to filter listings with the first seen at source in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-mc-range: string # First seen at MC date range to filter listings with the first seen at MC in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-source-days: string # First seen at source days range to filter listings with the first seen at source in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-mc-days: string # First seen at MC days range to filter listings with the first seen at MC in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --include-relevant-links: oneof<nothing, bool> # To include_relevant_links. Default is true (default: false)
  --inventory-count-range: string # Inventory count range to filter listings with count of total listings in dealers inventory. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --exclude-dealer-ids: string # A list of dealer ids to exclude from result (format: string)
  --exclude-sources: string # A list of sources to exclude from result (format: string)
  --in-transit: string@in-transit-completer # A boolean to filter in transit vehicles
  --title-type: string@title-type-completer # To filter on title type
  --seating-capacity: string # To filter on vehicle seating capacity (format: string)
  --engine-size-range: string # Engine size range to filter listings with engine size in the given range. Range to be given in the format - min-max e.g. 1.0-2 (format: string)
  --min-photo-links: string # Filter listings based by number of photo links within given range (format: string)
  --min-photo-links-cached: string # Filter listings based by number of cached photo links within given range (format: string)
]: nothing -> record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fuel_type: list<record>, interior_color: list<record>, make: list<record>, model: list<record>, seller_name: list<record>, seller_name_o: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, trim_o: list<record>, trim_r: list<record>, vehicle_type: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, vdp_url: string, vin: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "append_api_key" $append_api_key "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "include_lease" $include_lease "scalar") (serialize-qp "include_finance" $include_finance "scalar") (serialize-qp "lease_term" $lease_term "scalar") (serialize-qp "lease_down_payment" $lease_down_payment "scalar") (serialize-qp "lease_emp" $lease_emp "scalar") (serialize-qp "finance_loan_term" $finance_loan_term "scalar") (serialize-qp "finance_loan_apr" $finance_loan_apr "scalar") (serialize-qp "finance_emp" $finance_emp "scalar") (serialize-qp "finance_down_payment" $finance_down_payment "scalar") (serialize-qp "finance_down_payment_per" $finance_down_payment_per "scalar") (serialize-qp "car_type" $car_type "scalar") (serialize-qp "carfax_1_owner" $carfax_1_owner "scalar") (serialize-qp "carfax_clean_title" $carfax_clean_title "scalar") (serialize-qp "year_range" $year_range "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "trim" $trim "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "body_type" $body_type "scalar") (serialize-qp "body_subtype" $body_subtype "scalar") (serialize-qp "vehicle_type" $vehicle_type "scalar") (serialize-qp "vins" $vins "scalar") (serialize-qp "taxonomy_vins" $taxonomy_vins "scalar") (serialize-qp "mm" $mm "scalar") (serialize-qp "ymm" $ymm "scalar") (serialize-qp "ymmt" $ymmt "scalar") (serialize-qp "match" $qp_match "scalar") (serialize-qp "cylinders" $cylinders "scalar") (serialize-qp "transmission" $transmission "scalar") (serialize-qp "doors" $doors "scalar") (serialize-qp "drivetrain" $drivetrain "scalar") (serialize-qp "exterior_color" $exterior_color "scalar") (serialize-qp "interior_color" $interior_color "scalar") (serialize-qp "base_exterior_color" $base_exterior_color "scalar") (serialize-qp "base_interior_color" $base_interior_color "scalar") (serialize-qp "engine" $engine "scalar") (serialize-qp "engine_size" $engine_size "scalar") (serialize-qp "engine_aspiration" $engine_aspiration "scalar") (serialize-qp "engine_block" $engine_block "scalar") (serialize-qp "highway_mpg_range" $highway_mpg_range "scalar") (serialize-qp "city_mpg_range" $city_mpg_range "scalar") (serialize-qp "miles_range" $miles_range "scalar") (serialize-qp "price_range" $price_range "scalar") (serialize-qp "msrp_range" $msrp_range "scalar") (serialize-qp "dom_range" $dom_range "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "include_non_vin_listings" $include_non_vin_listings "scalar") (serialize-qp "msa_code" $msa_code "scalar") (serialize-qp "facets" $facets "scalar") (serialize-qp "range_facets" $range_facets "scalar") (serialize-qp "facet_sort" $facet_sort "scalar") (serialize-qp "stats" $stats "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "plot" $plot "scalar") (serialize-qp "nodedup" $nodedup "scalar") (serialize-qp "dedup" $dedup "scalar") (serialize-qp "owned" $owned "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "dealer_id" $dealer_id "scalar") (serialize-qp "trim_o" $trim_o "scalar") (serialize-qp "trim_r" $trim_r "scalar") (serialize-qp "dom_active_range" $dom_active_range "scalar") (serialize-qp "dom_180_range" $dom_180_range "scalar") (serialize-qp "exclude_certified" $exclude_certified "scalar") (serialize-qp "fuel_type" $fuel_type "scalar") (serialize-qp "dealer_type" $dealer_type "scalar") (serialize-qp "photo_links" $photo_links "scalar") (serialize-qp "photo_links_cached" $photo_links_cached "scalar") (serialize-qp "stock_no" $stock_no "scalar") (serialize-qp "last_seen_range" $last_seen_range "scalar") (serialize-qp "first_seen_range" $first_seen_range "scalar") (serialize-qp "first_seen_at_source_range" $first_seen_at_source_range "scalar") (serialize-qp "first_seen_at_mc_range" $first_seen_at_mc_range "scalar") (serialize-qp "last_seen_days" $last_seen_days "scalar") (serialize-qp "first_seen_days" $first_seen_days "scalar") (serialize-qp "first_seen_at_source_days" $first_seen_at_source_days "scalar") (serialize-qp "first_seen_at_mc_days" $first_seen_at_mc_days "scalar") (serialize-qp "include_relevant_links" $include_relevant_links "scalar") (serialize-qp "inventory_count_range" $inventory_count_range "scalar") (serialize-qp "exclude_dealer_ids" $exclude_dealer_ids "scalar") (serialize-qp "exclude_sources" $exclude_sources "scalar") (serialize-qp "in_transit" $in_transit "scalar") (serialize-qp "title_type" $title_type "scalar") (serialize-qp "seating_capacity" $seating_capacity "scalar") (serialize-qp "engine_size_range" $engine_size_range "scalar") (serialize-qp "min_photo_links" $min_photo_links "scalar") (serialize-qp "min_photo_links_cached" $min_photo_links_cached "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/car/auction/active" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "append_api_key": $append_api_key, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "zip": $zip, "include_lease": $include_lease, "include_finance": $include_finance, "lease_term": $lease_term, "lease_down_payment": $lease_down_payment, "lease_emp": $lease_emp, "finance_loan_term": $finance_loan_term, "finance_loan_apr": $finance_loan_apr, "finance_emp": $finance_emp, "finance_down_payment": $finance_down_payment, "finance_down_payment_per": $finance_down_payment_per, "car_type": $car_type, "carfax_1_owner": $carfax_1_owner, "carfax_clean_title": $carfax_clean_title, "year_range": $year_range, "year": $year, "make": $make, "model": $model, "trim": $trim, "vin": $vin, "body_type": $body_type, "body_subtype": $body_subtype, "vehicle_type": $vehicle_type, "vins": $vins, "taxonomy_vins": $taxonomy_vins, "mm": $mm, "ymm": $ymm, "ymmt": $ymmt, "match": $qp_match, "cylinders": $cylinders, "transmission": $transmission, "doors": $doors, "drivetrain": $drivetrain, "exterior_color": $exterior_color, "interior_color": $interior_color, "base_exterior_color": $base_exterior_color, "base_interior_color": $base_interior_color, "engine": $engine, "engine_size": $engine_size, "engine_aspiration": $engine_aspiration, "engine_block": $engine_block, "highway_mpg_range": $highway_mpg_range, "city_mpg_range": $city_mpg_range, "miles_range": $miles_range, "price_range": $price_range, "msrp_range": $msrp_range, "dom_range": $dom_range, "sort_by": $sort_by, "sort_order": $sort_order, "rows": $rows, "start": $start, "include_non_vin_listings": $include_non_vin_listings, "msa_code": $msa_code, "facets": $facets, "range_facets": $range_facets, "facet_sort": $facet_sort, "stats": $stats, "country": $country, "plot": $plot, "nodedup": $nodedup, "dedup": $dedup, "owned": $owned, "state": $state, "city": $city, "source": $qp_source, "dealer_id": $dealer_id, "trim_o": $trim_o, "trim_r": $trim_r, "dom_active_range": $dom_active_range, "dom_180_range": $dom_180_range, "exclude_certified": $exclude_certified, "fuel_type": $fuel_type, "dealer_type": $dealer_type, "photo_links": $photo_links, "photo_links_cached": $photo_links_cached, "stock_no": $stock_no, "last_seen_range": $last_seen_range, "first_seen_range": $first_seen_range, "first_seen_at_source_range": $first_seen_at_source_range, "first_seen_at_mc_range": $first_seen_at_mc_range, "last_seen_days": $last_seen_days, "first_seen_days": $first_seen_days, "first_seen_at_source_days": $first_seen_at_source_days, "first_seen_at_mc_days": $first_seen_at_mc_days, "include_relevant_links": $include_relevant_links, "inventory_count_range": $inventory_count_range, "exclude_dealer_ids": $exclude_dealer_ids, "exclude_sources": $exclude_sources, "in_transit": $in_transit, "title_type": $title_type, "seating_capacity": $seating_capacity, "engine_size_range": $engine_size_range, "min_photo_links": $min_photo_links, "min_photo_links_cached": $min_photo_links_cached} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# API for auto-completion of inputs
#
# GET /search/car/auto-complete
# operationId: autoComplete
export def "search-car-auto-complete complete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --field: string@field-completer # Field name for which you want auto-completion (format: string)
  --input: string # Input entered so far (format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --body-type: string # To filter listing on their body type
  --body-subtype: string # Body subtype to filter the listings on. Valid filter values are those that our Search facets API returns for unique body subtypes. You can pass in multiple body subtype values comma separated (format: string)
  --vehicle-type: string # To filter listing on their vehicle type
  --transmission: string # To filter listing on their transmission
  --drivetrain: string # To filter listing on their drivetrain
  --fuel-type: string # To filter listing on their fuel type
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --engine: string # To filter listing on their engine
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-block: string # Engine Block to match. Valid filter values are those that our Search facets API returns for unique Engine Block. You can pass in multiple Engine Block values comma separated
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --qp-source: string # To filter listing on their source only for widget requests
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --country: string@country-completer-3 # To filter listing on Country in which they are listed (default: US)
  --car-type: string@car-type-completer-1 # Car type. Allowed values are - new / used
  --include-non-vin-listings: string@include-non-vin-listings-completer # Flag to indicate whether to include non vin listing terms in results or not. Default is false to avoid un-normalised terms from non vin listings out of results (default: false)
  --ignore-case: oneof<nothing, bool> # Boolean variable to indicate ignore case of current input (default: true)
  --term-counts: oneof<nothing, bool> # Boolean variable to indicate wheather to include term counts as well in response (default: false)
  --sort-by: string@sort-by-completer # Sort the response, either by index or count(default) (default: index)
  --seller-type: string # seller type for autocomplete
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --inventory-count-range: string # Inventory count range to filter listings with count of total listings in dealers inventory. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --exclude-dealer-ids: string # A list of dealer ids to exclude from result (format: string)
  --exclude-sources: string # A list of sources to exclude from result (format: string)
  --in-transit: string@in-transit-completer # A boolean to filter in transit vehicles
  --facet-min-count: float # Provide minimum count value for facets (format: number, default: 1)
]: nothing -> record<terms: table<count: int, item: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "field" $field "scalar") (serialize-qp "input" $input "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "trim" $trim "scalar") (serialize-qp "body_type" $body_type "scalar") (serialize-qp "body_subtype" $body_subtype "scalar") (serialize-qp "vehicle_type" $vehicle_type "scalar") (serialize-qp "transmission" $transmission "scalar") (serialize-qp "drivetrain" $drivetrain "scalar") (serialize-qp "fuel_type" $fuel_type "scalar") (serialize-qp "exterior_color" $exterior_color "scalar") (serialize-qp "interior_color" $interior_color "scalar") (serialize-qp "engine" $engine "scalar") (serialize-qp "engine_size" $engine_size "scalar") (serialize-qp "engine_block" $engine_block "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "dealer_id" $dealer_id "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "car_type" $car_type "scalar") (serialize-qp "include_non_vin_listings" $include_non_vin_listings "scalar") (serialize-qp "ignore_case" $ignore_case "scalar") (serialize-qp "term_counts" $term_counts "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "seller_type" $seller_type "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "inventory_count_range" $inventory_count_range "scalar") (serialize-qp "exclude_dealer_ids" $exclude_dealer_ids "scalar") (serialize-qp "exclude_sources" $exclude_sources "scalar") (serialize-qp "in_transit" $in_transit "scalar") (serialize-qp "facet_min_count" $facet_min_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/car/auto-complete" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "field": $field, "input": $input, "year": $year, "make": $make, "model": $model, "trim": $trim, "body_type": $body_type, "body_subtype": $body_subtype, "vehicle_type": $vehicle_type, "transmission": $transmission, "drivetrain": $drivetrain, "fuel_type": $fuel_type, "exterior_color": $exterior_color, "interior_color": $interior_color, "engine": $engine, "engine_size": $engine_size, "engine_block": $engine_block, "state": $state, "city": $city, "source": $qp_source, "dealer_id": $dealer_id, "country": $country, "car_type": $car_type, "include_non_vin_listings": $include_non_vin_listings, "ignore_case": $ignore_case, "term_counts": $term_counts, "sort_by": $sort_by, "seller_type": $seller_type, "radius": $radius, "zip": $zip, "inventory_count_range": $inventory_count_range, "exclude_dealer_ids": $exclude_dealer_ids, "exclude_sources": $exclude_sources, "in_transit": $in_transit, "facet_min_count": $facet_min_count} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets active private party car listings for the given search criteria
#
# GET /search/car/fsbo/active
export def "search-car-fsbo-active get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --include-lease: oneof<nothing, bool> # Boolean param to search for listings that include leasing options in them
  --include-finance: oneof<nothing, bool> # Boolean param to search for listings that include finance options in them
  --lease-term: string # Search listings with exact lease term, or inside a range with min and max seperated by a dash like lease_term=30-60
  --lease-down-payment: string # Search listings with exact down payment in lease offers, or inside a range with min and max seperated by a dash like lease_down_payment=30-60
  --lease-emp: string # Search listings with lease offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like lease_emp=30-60
  --finance-loan-term: string # Search listings with exact finance loan term, or inside a range with min and max seperated by a dash like finance_loan_term=30-60
  --finance-loan-apr: string # Search listings with finance offers exactly matching loans Annual Percentage Rate, or inside a range with min and max seperated by a dash like finance_loan_apr=30-60
  --finance-emp: string # Search listings with finance offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like finance_emp=30-60
  --finance-down-payment: string # Search listings with exact down payment in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment=30-60
  --finance-down-payment-per: string # Search listings with exact down payment percentage in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment_per=30-60
  --car-type: string@car-type-completer # Car type. Allowed values are - new / used / certified
  --carfax-1-owner: string@carfax-1-owner-completer # Indicates whether car has had only one owner or not
  --carfax-clean-title: string@carfax-clean-title-completer # Indicates whether car has clean ownership records
  --year-range: string # Year range to filter listings with the year in the range given. Range to be given in the format - min-max e.g. 2019-2021 (format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --vin: string # To filter listing on their VIN
  --body-type: string # To filter listing on their body type
  --body-subtype: string # Body subtype to filter the listings on. Valid filter values are those that our Search facets API returns for unique body subtypes. You can pass in multiple body subtype values comma separated (format: string)
  --vehicle-type: string # To filter listing on their vehicle type
  --vins: string # Comma separated list of 17 digit vins to search the matching cars for. Only 10 VINs allowed per request. If the request contains more than 10 VINs the first 10 VINs will be considered. Could be used as a More Like This or Similar Vehicles search for the given VINs. Ths vins parameter is an alternative to taxonomy_vins or ymmt parameters available with the search API. vins and taxonomy_vins parameters could be used to filter our cars with the exact build represented by the vins or taxonomy_vins whereas ymmt is a top level filter that does not filter cars by the build attributes like doors, drivetrain, cylinders, body type, body subtype, vehicle type etc
  --taxonomy-vins: string # Comma separated list of 10 letters excert from the 17 letter VIN. The 10 letters to be picked up from the 17 letter VIN are - first 8 letters and the 10th and 11th letter. E.g. For a VIN - 1FTFW1EF3EKE57182 the taxonomy vin would be - 1FTFW1EFEK A taxonomy VIN identified a build of a car and could be used to filter our cars of a particular build. This is an alternative to the vin or ymmt parameters to the search API.
  --mm: string # Make-Model concatenated string. To help passing the results of auto-complete API on mm field, use this parameter and pass in the selected value as is
  --ymm: string # Year-Make-Model concatenated string. To help passing the results of auto-complete API on ymm field, use this parameter and pass in the selected value as is
  --ymmt: string # Comma separated list of Year, Make, Model, Trim combinations. Each combination needs to have the year,make,model, trim values separated by a pipe '|' character in the form year|make|model|trim. e.g. 2010|Audi|A5,2014|Nissan|Sentra|S 6MT,|Honda|City| You could just provide strings of the form - 'year|make||' or 'year|make|model' or '|make|model|' combinations. Individual year / make / model filters provied with the API calls will take precedence over the Year, Make, Model, Trim combinations. The Make, Model, Trim values must be valid values as per the Marketcheck Vin Decoder. If you are using a separate vin decoder then look at using the 'vins' or 'taxonomy_vins' parameter to the search api instead the year|make|model|trim combinations.
  --qp-match: string # Comma separated list of Year, Make, Model, Trim fields. For example - year,make,model,trim fields for which user wants to do an exact match
  --cylinders: string # To filter listing on their cylinders
  --transmission: string # To filter listing on their transmission
  --doors: string # Doors to filter the cars on. Valid filter values are those that our Search facets API returns for unique doors. You can pass in multiple doors values comma separated (format: string)
  --drivetrain: string # To filter listing on their drivetrain
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --base-exterior-color: string # Base exterior color to match. Valid filter values are those that our Search facets API returns for unique base exterior colors. You can pass in multiple base interior color values comma separated
  --base-interior-color: string # Base interior color to match. Valid filter values are those that our Search facets API returns for unique base interior colors. You can pass in multiple base interior color values comma separated
  --engine: string # To filter listing on their engine
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-aspiration: string # Engine Aspiration to match. Valid filter values are those that our Search facets API returns for unique Engine Aspirations. You can pass in multiple Engine aspirations values comma separated
  --engine-block: string # Engine Block to match. Valid filter values are those that our Search facets API returns for unique Engine Block. You can pass in multiple Engine Block values comma separated
  --highway-mpg-range: string # Highway mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --city-mpg-range: string # City mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --dom-range: string # Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --include-non-vin-listings: oneof<nothing, bool> # To include non vin listings. Default is false (default: false)
  --msa-code: string # To filter listing on msa code in which they are listed
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --country: string@country-completer # To filter listing on Country in which they are listed (default: US)
  --plot: oneof<nothing, bool> # If plot has value true results in around 25k coordinates with limited fields to plot respective graph
  --nodedup: oneof<nothing, bool> # If nodedup is set to true then API will give results without is_searchable i.e multiple listings for single vin
  --dedup: oneof<nothing, bool> # If dedup is set to true then will give results with is_searchable irrespecive of dealer_id or source
  --owned: oneof<nothing, bool> # Used in combination with dealer_id or source, when true returns the listings actually owned by dealer himself
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --qp-source: string # To filter listing on their source only for widget requests
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --trim-o: string # Filter listings on web scraped trim
  --trim-r: string # Filter trim on custom possible matches
  --dom-active-range: string # Active Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dom-180-range: string # Last 180 Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --exclude-certified: oneof<nothing, bool> # Boolean param to exclude certified cars from search results
  --fuel-type: string # To filter listing on their fuel type
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --photo-links: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links in search results, And discard those that don't have them
  --photo-links-cached: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links_cached in search results, And discard those that don't have them
  --stock-no: string # To filter listing on their stock number on lot
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-source-range: string # First seen at source date range to filter listings with the first seen at source in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-mc-range: string # First seen at MC date range to filter listings with the first seen at MC in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-source-days: string # First seen at source days range to filter listings with the first seen at source in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-mc-days: string # First seen at MC days range to filter listings with the first seen at MC in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --include-relevant-links: oneof<nothing, bool> # To include_relevant_links. Default is true (default: false)
  --inventory-count-range: string # Inventory count range to filter listings with count of total listings in dealers inventory. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --exclude-dealer-ids: string # A list of dealer ids to exclude from result (format: string)
  --exclude-sources: string # A list of sources to exclude from result (format: string)
  --exclude-dealer-listings: oneof<nothing, bool> # A list of fsbo listings to exclude from result
  --in-transit: string@in-transit-completer # A boolean to filter in transit vehicles
  --seating-capacity: string # To filter on vehicle seating capacity (format: string)
  --engine-size-range: string # Engine size range to filter listings with engine size in the given range. Range to be given in the format - min-max e.g. 1.0-2 (format: string)
  --min-photo-links: string # Filter listings based by number of photo links within given range (format: string)
  --min-photo-links-cached: string # Filter listings based by number of cached photo links within given range (format: string)
]: nothing -> record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fuel_type: list<record>, interior_color: list<record>, make: list<record>, model: list<record>, seller_name: list<record>, seller_name_o: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, trim_o: list<record>, trim_r: list<record>, vehicle_type: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, vdp_url: string, vin: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "append_api_key" $append_api_key "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "include_lease" $include_lease "scalar") (serialize-qp "include_finance" $include_finance "scalar") (serialize-qp "lease_term" $lease_term "scalar") (serialize-qp "lease_down_payment" $lease_down_payment "scalar") (serialize-qp "lease_emp" $lease_emp "scalar") (serialize-qp "finance_loan_term" $finance_loan_term "scalar") (serialize-qp "finance_loan_apr" $finance_loan_apr "scalar") (serialize-qp "finance_emp" $finance_emp "scalar") (serialize-qp "finance_down_payment" $finance_down_payment "scalar") (serialize-qp "finance_down_payment_per" $finance_down_payment_per "scalar") (serialize-qp "car_type" $car_type "scalar") (serialize-qp "carfax_1_owner" $carfax_1_owner "scalar") (serialize-qp "carfax_clean_title" $carfax_clean_title "scalar") (serialize-qp "year_range" $year_range "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "trim" $trim "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "body_type" $body_type "scalar") (serialize-qp "body_subtype" $body_subtype "scalar") (serialize-qp "vehicle_type" $vehicle_type "scalar") (serialize-qp "vins" $vins "scalar") (serialize-qp "taxonomy_vins" $taxonomy_vins "scalar") (serialize-qp "mm" $mm "scalar") (serialize-qp "ymm" $ymm "scalar") (serialize-qp "ymmt" $ymmt "scalar") (serialize-qp "match" $qp_match "scalar") (serialize-qp "cylinders" $cylinders "scalar") (serialize-qp "transmission" $transmission "scalar") (serialize-qp "doors" $doors "scalar") (serialize-qp "drivetrain" $drivetrain "scalar") (serialize-qp "exterior_color" $exterior_color "scalar") (serialize-qp "interior_color" $interior_color "scalar") (serialize-qp "base_exterior_color" $base_exterior_color "scalar") (serialize-qp "base_interior_color" $base_interior_color "scalar") (serialize-qp "engine" $engine "scalar") (serialize-qp "engine_size" $engine_size "scalar") (serialize-qp "engine_aspiration" $engine_aspiration "scalar") (serialize-qp "engine_block" $engine_block "scalar") (serialize-qp "highway_mpg_range" $highway_mpg_range "scalar") (serialize-qp "city_mpg_range" $city_mpg_range "scalar") (serialize-qp "miles_range" $miles_range "scalar") (serialize-qp "price_range" $price_range "scalar") (serialize-qp "msrp_range" $msrp_range "scalar") (serialize-qp "dom_range" $dom_range "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "include_non_vin_listings" $include_non_vin_listings "scalar") (serialize-qp "msa_code" $msa_code "scalar") (serialize-qp "facets" $facets "scalar") (serialize-qp "range_facets" $range_facets "scalar") (serialize-qp "facet_sort" $facet_sort "scalar") (serialize-qp "stats" $stats "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "plot" $plot "scalar") (serialize-qp "nodedup" $nodedup "scalar") (serialize-qp "dedup" $dedup "scalar") (serialize-qp "owned" $owned "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "dealer_id" $dealer_id "scalar") (serialize-qp "trim_o" $trim_o "scalar") (serialize-qp "trim_r" $trim_r "scalar") (serialize-qp "dom_active_range" $dom_active_range "scalar") (serialize-qp "dom_180_range" $dom_180_range "scalar") (serialize-qp "exclude_certified" $exclude_certified "scalar") (serialize-qp "fuel_type" $fuel_type "scalar") (serialize-qp "dealer_type" $dealer_type "scalar") (serialize-qp "photo_links" $photo_links "scalar") (serialize-qp "photo_links_cached" $photo_links_cached "scalar") (serialize-qp "stock_no" $stock_no "scalar") (serialize-qp "last_seen_range" $last_seen_range "scalar") (serialize-qp "first_seen_range" $first_seen_range "scalar") (serialize-qp "first_seen_at_source_range" $first_seen_at_source_range "scalar") (serialize-qp "first_seen_at_mc_range" $first_seen_at_mc_range "scalar") (serialize-qp "last_seen_days" $last_seen_days "scalar") (serialize-qp "first_seen_days" $first_seen_days "scalar") (serialize-qp "first_seen_at_source_days" $first_seen_at_source_days "scalar") (serialize-qp "first_seen_at_mc_days" $first_seen_at_mc_days "scalar") (serialize-qp "include_relevant_links" $include_relevant_links "scalar") (serialize-qp "inventory_count_range" $inventory_count_range "scalar") (serialize-qp "exclude_dealer_ids" $exclude_dealer_ids "scalar") (serialize-qp "exclude_sources" $exclude_sources "scalar") (serialize-qp "exclude_dealer_listings" $exclude_dealer_listings "scalar") (serialize-qp "in_transit" $in_transit "scalar") (serialize-qp "seating_capacity" $seating_capacity "scalar") (serialize-qp "engine_size_range" $engine_size_range "scalar") (serialize-qp "min_photo_links" $min_photo_links "scalar") (serialize-qp "min_photo_links_cached" $min_photo_links_cached "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/car/fsbo/active" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "append_api_key": $append_api_key, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "zip": $zip, "include_lease": $include_lease, "include_finance": $include_finance, "lease_term": $lease_term, "lease_down_payment": $lease_down_payment, "lease_emp": $lease_emp, "finance_loan_term": $finance_loan_term, "finance_loan_apr": $finance_loan_apr, "finance_emp": $finance_emp, "finance_down_payment": $finance_down_payment, "finance_down_payment_per": $finance_down_payment_per, "car_type": $car_type, "carfax_1_owner": $carfax_1_owner, "carfax_clean_title": $carfax_clean_title, "year_range": $year_range, "year": $year, "make": $make, "model": $model, "trim": $trim, "vin": $vin, "body_type": $body_type, "body_subtype": $body_subtype, "vehicle_type": $vehicle_type, "vins": $vins, "taxonomy_vins": $taxonomy_vins, "mm": $mm, "ymm": $ymm, "ymmt": $ymmt, "match": $qp_match, "cylinders": $cylinders, "transmission": $transmission, "doors": $doors, "drivetrain": $drivetrain, "exterior_color": $exterior_color, "interior_color": $interior_color, "base_exterior_color": $base_exterior_color, "base_interior_color": $base_interior_color, "engine": $engine, "engine_size": $engine_size, "engine_aspiration": $engine_aspiration, "engine_block": $engine_block, "highway_mpg_range": $highway_mpg_range, "city_mpg_range": $city_mpg_range, "miles_range": $miles_range, "price_range": $price_range, "msrp_range": $msrp_range, "dom_range": $dom_range, "sort_by": $sort_by, "sort_order": $sort_order, "rows": $rows, "start": $start, "include_non_vin_listings": $include_non_vin_listings, "msa_code": $msa_code, "facets": $facets, "range_facets": $range_facets, "facet_sort": $facet_sort, "stats": $stats, "country": $country, "plot": $plot, "nodedup": $nodedup, "dedup": $dedup, "owned": $owned, "state": $state, "city": $city, "source": $qp_source, "dealer_id": $dealer_id, "trim_o": $trim_o, "trim_r": $trim_r, "dom_active_range": $dom_active_range, "dom_180_range": $dom_180_range, "exclude_certified": $exclude_certified, "fuel_type": $fuel_type, "dealer_type": $dealer_type, "photo_links": $photo_links, "photo_links_cached": $photo_links_cached, "stock_no": $stock_no, "last_seen_range": $last_seen_range, "first_seen_range": $first_seen_range, "first_seen_at_source_range": $first_seen_at_source_range, "first_seen_at_mc_range": $first_seen_at_mc_range, "last_seen_days": $last_seen_days, "first_seen_days": $first_seen_days, "first_seen_at_source_days": $first_seen_at_source_days, "first_seen_at_mc_days": $first_seen_at_mc_days, "include_relevant_links": $include_relevant_links, "inventory_count_range": $inventory_count_range, "exclude_dealer_ids": $exclude_dealer_ids, "exclude_sources": $exclude_sources, "exclude_dealer_listings": $exclude_dealer_listings, "in_transit": $in_transit, "seating_capacity": $seating_capacity, "engine_size_range": $engine_size_range, "min_photo_links": $min_photo_links, "min_photo_links_cached": $min_photo_links_cached} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets oem incentive listings for the given search criteria
#
# GET /search/car/incentive/oem
# operationId: oemSearch
export def "search-car-incentive-oem list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --offer-type: string@offer-type-completer # The type of the incentive
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --msrp: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --apr: string # APR range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --monthly: string # To filter listing on Monthly payment amount, usually populated in Lease offers
  --monthly-per-thousand: string # To filter listing on monthly amount to be paid by customer for every $1000 financed at the advertised APR rate
  --down-payment: string # To filter listing on down payment offer on car
  --due-at-signing: string # To filter listing on total amount due at signing, that usually includes first month payment, down payment, acquisition fee etc
  --security-deposit: string # To filter listing on security deposit required for the offer
  --disposition-fee: string # To filter listing on disposition fee of the car
  --acquisition-fee: string # To filter listing on acquisition fee of the car
  --duration: string # To filter listing on offer duration in months
  --dealer-contribution: string # To filter listing on any contribution from dealer's side
  --mileage-charge: string # Mileage Charge Range range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 100-1000 (format: string)
  --mileage-charge-limit: string # To filter listing on mileage charge limit the offer is valid up to under the default clauses
  --cashback-amount: string # To filter listing on cashback amounts listed in offer
  --cashback-target-group: string # To filter listing on the demographic or any other entity for whom this cashback offer is for. Not all target groups are identified but the most common ones are tagged like Military, Grad students Current owners etc
  --lease-end-purchase-option: string # To filter listing on amount at the lease end to pay for buying the car
  --net-capitalised-cost: string # To filter listing on net capitalised cost of the car
  --gross-capitalised-cost: string # To filter listing on gross capitalised cost of the car
  --total-monthly-payment: string # To filter listing on gross capitalised cost of the car
  --zip: string # To filter listing on ZIP around which they are listed
  --city: string # To filter listing on City in which they are listed
  --state: string # To filter listing on State in which they are listed
  --country: string@country-completer-3 # To filter listing on Country in which they are listed (default: US)
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --search-text: string # To search a substring across entire document
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
]: nothing -> record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fuel_type: list<record>, interior_color: list<record>, make: list<record>, model: list<record>, seller_name: list<record>, seller_name_o: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, trim_o: list<record>, trim_r: list<record>, vehicle_type: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, vdp_url: string, vin: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "offer_type" $offer_type "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "trim" $trim "scalar") (serialize-qp "msrp" $msrp "scalar") (serialize-qp "apr" $apr "scalar") (serialize-qp "monthly" $monthly "scalar") (serialize-qp "monthly_per_thousand" $monthly_per_thousand "scalar") (serialize-qp "down_payment" $down_payment "scalar") (serialize-qp "due_at_signing" $due_at_signing "scalar") (serialize-qp "security_deposit" $security_deposit "scalar") (serialize-qp "disposition_fee" $disposition_fee "scalar") (serialize-qp "acquisition_fee" $acquisition_fee "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "dealer_contribution" $dealer_contribution "scalar") (serialize-qp "mileage_charge" $mileage_charge "scalar") (serialize-qp "mileage_charge_limit" $mileage_charge_limit "scalar") (serialize-qp "cashback_amount" $cashback_amount "scalar") (serialize-qp "cashback_target_group" $cashback_target_group "scalar") (serialize-qp "lease_end_purchase_option" $lease_end_purchase_option "scalar") (serialize-qp "net_capitalised_cost" $net_capitalised_cost "scalar") (serialize-qp "gross_capitalised_cost" $gross_capitalised_cost "scalar") (serialize-qp "total_monthly_payment" $total_monthly_payment "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "search_text" $search_text "scalar") (serialize-qp "last_seen_range" $last_seen_range "scalar") (serialize-qp "first_seen_range" $first_seen_range "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facets" $facets "scalar") (serialize-qp "range_facets" $range_facets "scalar") (serialize-qp "facet_sort" $facet_sort "scalar") (serialize-qp "stats" $stats "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/car/incentive/oem" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "offer_type": $offer_type, "year": $year, "make": $make, "model": $model, "trim": $trim, "msrp": $msrp, "apr": $apr, "monthly": $monthly, "monthly_per_thousand": $monthly_per_thousand, "down_payment": $down_payment, "due_at_signing": $due_at_signing, "security_deposit": $security_deposit, "disposition_fee": $disposition_fee, "acquisition_fee": $acquisition_fee, "duration": $duration, "dealer_contribution": $dealer_contribution, "mileage_charge": $mileage_charge, "mileage_charge_limit": $mileage_charge_limit, "cashback_amount": $cashback_amount, "cashback_target_group": $cashback_target_group, "lease_end_purchase_option": $lease_end_purchase_option, "net_capitalised_cost": $net_capitalised_cost, "gross_capitalised_cost": $gross_capitalised_cost, "total_monthly_payment": $total_monthly_payment, "zip": $zip, "city": $city, "state": $state, "country": $country, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "search_text": $search_text, "last_seen_range": $last_seen_range, "first_seen_range": $first_seen_range, "sort_by": $sort_by, "sort_order": $sort_order, "rows": $rows, "start": $start, "facets": $facets, "range_facets": $range_facets, "facet_sort": $facet_sort, "stats": $stats} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets Recent car listings for the given search criteria
#
# GET /search/car/recents
export def "search-car-recents get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --include-lease: oneof<nothing, bool> # Boolean param to search for listings that include leasing options in them
  --include-finance: oneof<nothing, bool> # Boolean param to search for listings that include finance options in them
  --lease-term: string # Search listings with exact lease term, or inside a range with min and max seperated by a dash like lease_term=30-60
  --lease-down-payment: string # Search listings with exact down payment in lease offers, or inside a range with min and max seperated by a dash like lease_down_payment=30-60
  --lease-emp: string # Search listings with lease offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like lease_emp=30-60
  --finance-loan-term: string # Search listings with exact finance loan term, or inside a range with min and max seperated by a dash like finance_loan_term=30-60
  --finance-loan-apr: string # Search listings with finance offers exactly matching loans Annual Percentage Rate, or inside a range with min and max seperated by a dash like finance_loan_apr=30-60
  --finance-emp: string # Search listings with finance offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like finance_emp=30-60
  --finance-down-payment: string # Search listings with exact down payment in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment=30-60
  --finance-down-payment-per: string # Search listings with exact down payment percentage in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment_per=30-60
  --car-type: string@car-type-completer # Car type. Allowed values are - new / used / certified
  --carfax-1-owner: string@carfax-1-owner-completer # Indicates whether car has had only one owner or not
  --carfax-clean-title: string@carfax-clean-title-completer # Indicates whether car has clean ownership records
  --year-range: string # Year range to filter listings with the year in the range given. Range to be given in the format - min-max e.g. 2019-2021 (format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --vin: string # To filter listing on their VIN
  --qp-source: string # To filter listing on their source
  --body-type: string # To filter listing on their body type
  --body-subtype: string # Body subtype to filter the listings on. Valid filter values are those that our Search facets API returns for unique body subtypes. You can pass in multiple body subtype values comma separated (format: string)
  --vehicle-type: string # To filter listing on their vehicle type
  --vins: string # Comma separated list of 17 digit vins to search the matching cars for. Only 10 VINs allowed per request. If the request contains more than 10 VINs the first 10 VINs will be considered. Could be used as a More Like This or Similar Vehicles search for the given VINs. Ths vins parameter is an alternative to taxonomy_vins or ymmt parameters available with the search API. vins and taxonomy_vins parameters could be used to filter our cars with the exact build represented by the vins or taxonomy_vins whereas ymmt is a top level filter that does not filter cars by the build attributes like doors, drivetrain, cylinders, body type, body subtype, vehicle type etc
  --taxonomy-vins: string # Comma separated list of 10 letters excert from the 17 letter VIN. The 10 letters to be picked up from the 17 letter VIN are - first 8 letters and the 10th and 11th letter. E.g. For a VIN - 1FTFW1EF3EKE57182 the taxonomy vin would be - 1FTFW1EFEK A taxonomy VIN identified a build of a car and could be used to filter our cars of a particular build. This is an alternative to the vin or ymmt parameters to the search API.
  --ymmt: string # Comma separated list of Year, Make, Model, Trim combinations. Each combination needs to have the year,make,model, trim values separated by a pipe '|' character in the form year|make|model|trim. e.g. 2010|Audi|A5,2014|Nissan|Sentra|S 6MT,|Honda|City| You could just provide strings of the form - 'year|make||' or 'year|make|model' or '|make|model|' combinations. Individual year / make / model filters provied with the API calls will take precedence over the Year, Make, Model, Trim combinations. The Make, Model, Trim values must be valid values as per the Marketcheck Vin Decoder. If you are using a separate vin decoder then look at using the 'vins' or 'taxonomy_vins' parameter to the search api instead the year|make|model|trim combinations.
  --qp-match: string # Comma separated list of Year, Make, Model, Trim fields. For example - year,make,model,trim fields for which user wants to do an exact match
  --cylinders: string # To filter listing on their cylinders
  --transmission: string # To filter listing on their transmission
  --doors: string # Doors to filter the cars on. Valid filter values are those that our Search facets API returns for unique doors. You can pass in multiple doors values comma separated (format: string)
  --drivetrain: string # To filter listing on their drivetrain
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --base-exterior-color: string # Base exterior color to match. Valid filter values are those that our Search facets API returns for unique base exterior colors. You can pass in multiple base interior color values comma separated
  --base-interior-color: string # Base interior color to match. Valid filter values are those that our Search facets API returns for unique base interior colors. You can pass in multiple base interior color values comma separated
  --engine: string # To filter listing on their engine
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-aspiration: string # Engine Aspiration to match. Valid filter values are those that our Search facets API returns for unique Engine Aspirations. You can pass in multiple Engine aspirations values comma separated
  --engine-block: string # Engine Block to match. Valid filter values are those that our Search facets API returns for unique Engine Block. You can pass in multiple Engine Block values comma separated
  --highway-mpg-range: string # Highway mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --city-mpg-range: string # City mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --dom-range: string # Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-source-range: string # First seen at source date range to filter listings with the first seen at source in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-mc-range: string # First seen at MC date range to filter listings with the first seen at MC in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-source-days: string # First seen at source days range to filter listings with the first seen at source in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-mc-days: string # First seen at MC days range to filter listings with the first seen at MC in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --include-non-vin-listings: oneof<nothing, bool> # To include non vin listings. Default is false (default: false)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --country: string@country-completer # To filter listing on Country in which they are listed (default: US)
  --plot: oneof<nothing, bool> # If plot has value true results in around 25k coordinates with limited fields to plot respective graph
  --nodedup: oneof<nothing, bool> # If nodedup is set to true then API will give results without is_searchable i.e multiple listings for single vin
  --dedup: oneof<nothing, bool> # If dedup is set to true then will give results with is_searchable irrespecive of dealer_id or source
  --owned: oneof<nothing, bool> # Used in combination with dealer_id or source, when true returns the listings actually owned by dealer himself
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --msa-code: string # To filter listing on msa code in which they are listed
  --dealer-name: string # Filter listings on dealer_name
  --dealership-group-name: string # Name of the dealership group to search for (format: string)
  --trim-o: string # Filter listings on web scraped trim
  --trim-r: string # Filter trim on custom possible matches
  --dom-active-range: string # Active Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dom-180-range: string # Last 180 Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --exclude-certified: oneof<nothing, bool> # Boolean param to exclude certified cars from search results
  --fuel-type: string # To filter listing on their fuel type
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --photo-links: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links in search results, And discard those that don't have them
  --photo-links-cached: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links_cached in search results, And discard those that don't have them
  --stock-no: string # To filter listing on their stock number on lot
  --sold: oneof<nothing, bool> # sold parameter to fetch only sold listings
  --include-relevant-links: oneof<nothing, bool> # To include_relevant_links. Default is true (default: false)
  --expired: string@expired-completer # Boolean falg to either fetch only the expired listings or active ones
  --exclude-dealer-ids: string # A list of dealer ids to exclude from result (format: string)
  --exclude-sources: string # A list of sources to exclude from result (format: string)
  --in-transit: string@in-transit-completer # A boolean to filter in transit vehicles
  --seating-capacity: string # To filter on vehicle seating capacity (format: string)
  --active-inventory-date-range: string # date range to filter listings that were active within given date range. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --engine-size-range: string # Engine size range to filter listings with engine size in the given range. Range to be given in the format - min-max e.g. 1.0-2 (format: string)
  --price-change-range: string # Price change range to filter listings with price change within given price_change_range. Range to be given in the format - min-max e.g. 10-500 (format: string)
]: nothing -> record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fuel_type: list<record>, interior_color: list<record>, make: list<record>, model: list<record>, seller_name: list<record>, seller_name_o: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, trim_o: list<record>, trim_r: list<record>, vehicle_type: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, vdp_url: string, vin: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "append_api_key" $append_api_key "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "include_lease" $include_lease "scalar") (serialize-qp "include_finance" $include_finance "scalar") (serialize-qp "lease_term" $lease_term "scalar") (serialize-qp "lease_down_payment" $lease_down_payment "scalar") (serialize-qp "lease_emp" $lease_emp "scalar") (serialize-qp "finance_loan_term" $finance_loan_term "scalar") (serialize-qp "finance_loan_apr" $finance_loan_apr "scalar") (serialize-qp "finance_emp" $finance_emp "scalar") (serialize-qp "finance_down_payment" $finance_down_payment "scalar") (serialize-qp "finance_down_payment_per" $finance_down_payment_per "scalar") (serialize-qp "car_type" $car_type "scalar") (serialize-qp "carfax_1_owner" $carfax_1_owner "scalar") (serialize-qp "carfax_clean_title" $carfax_clean_title "scalar") (serialize-qp "year_range" $year_range "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "trim" $trim "scalar") (serialize-qp "dealer_id" $dealer_id "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "body_type" $body_type "scalar") (serialize-qp "body_subtype" $body_subtype "scalar") (serialize-qp "vehicle_type" $vehicle_type "scalar") (serialize-qp "vins" $vins "scalar") (serialize-qp "taxonomy_vins" $taxonomy_vins "scalar") (serialize-qp "ymmt" $ymmt "scalar") (serialize-qp "match" $qp_match "scalar") (serialize-qp "cylinders" $cylinders "scalar") (serialize-qp "transmission" $transmission "scalar") (serialize-qp "doors" $doors "scalar") (serialize-qp "drivetrain" $drivetrain "scalar") (serialize-qp "exterior_color" $exterior_color "scalar") (serialize-qp "interior_color" $interior_color "scalar") (serialize-qp "base_exterior_color" $base_exterior_color "scalar") (serialize-qp "base_interior_color" $base_interior_color "scalar") (serialize-qp "engine" $engine "scalar") (serialize-qp "engine_size" $engine_size "scalar") (serialize-qp "engine_aspiration" $engine_aspiration "scalar") (serialize-qp "engine_block" $engine_block "scalar") (serialize-qp "highway_mpg_range" $highway_mpg_range "scalar") (serialize-qp "city_mpg_range" $city_mpg_range "scalar") (serialize-qp "miles_range" $miles_range "scalar") (serialize-qp "price_range" $price_range "scalar") (serialize-qp "msrp_range" $msrp_range "scalar") (serialize-qp "dom_range" $dom_range "scalar") (serialize-qp "last_seen_range" $last_seen_range "scalar") (serialize-qp "first_seen_range" $first_seen_range "scalar") (serialize-qp "first_seen_at_source_range" $first_seen_at_source_range "scalar") (serialize-qp "first_seen_at_mc_range" $first_seen_at_mc_range "scalar") (serialize-qp "last_seen_days" $last_seen_days "scalar") (serialize-qp "first_seen_days" $first_seen_days "scalar") (serialize-qp "first_seen_at_source_days" $first_seen_at_source_days "scalar") (serialize-qp "first_seen_at_mc_days" $first_seen_at_mc_days "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "include_non_vin_listings" $include_non_vin_listings "scalar") (serialize-qp "facets" $facets "scalar") (serialize-qp "range_facets" $range_facets "scalar") (serialize-qp "facet_sort" $facet_sort "scalar") (serialize-qp "stats" $stats "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "plot" $plot "scalar") (serialize-qp "nodedup" $nodedup "scalar") (serialize-qp "dedup" $dedup "scalar") (serialize-qp "owned" $owned "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "msa_code" $msa_code "scalar") (serialize-qp "dealer_name" $dealer_name "scalar") (serialize-qp "dealership_group_name" $dealership_group_name "scalar") (serialize-qp "trim_o" $trim_o "scalar") (serialize-qp "trim_r" $trim_r "scalar") (serialize-qp "dom_active_range" $dom_active_range "scalar") (serialize-qp "dom_180_range" $dom_180_range "scalar") (serialize-qp "exclude_certified" $exclude_certified "scalar") (serialize-qp "fuel_type" $fuel_type "scalar") (serialize-qp "dealer_type" $dealer_type "scalar") (serialize-qp "photo_links" $photo_links "scalar") (serialize-qp "photo_links_cached" $photo_links_cached "scalar") (serialize-qp "stock_no" $stock_no "scalar") (serialize-qp "sold" $sold "scalar") (serialize-qp "include_relevant_links" $include_relevant_links "scalar") (serialize-qp "expired" $expired "scalar") (serialize-qp "exclude_dealer_ids" $exclude_dealer_ids "scalar") (serialize-qp "exclude_sources" $exclude_sources "scalar") (serialize-qp "in_transit" $in_transit "scalar") (serialize-qp "seating_capacity" $seating_capacity "scalar") (serialize-qp "active_inventory_date_range" $active_inventory_date_range "scalar") (serialize-qp "engine_size_range" $engine_size_range "scalar") (serialize-qp "price_change_range" $price_change_range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/car/recents" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "append_api_key": $append_api_key, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "zip": $zip, "include_lease": $include_lease, "include_finance": $include_finance, "lease_term": $lease_term, "lease_down_payment": $lease_down_payment, "lease_emp": $lease_emp, "finance_loan_term": $finance_loan_term, "finance_loan_apr": $finance_loan_apr, "finance_emp": $finance_emp, "finance_down_payment": $finance_down_payment, "finance_down_payment_per": $finance_down_payment_per, "car_type": $car_type, "carfax_1_owner": $carfax_1_owner, "carfax_clean_title": $carfax_clean_title, "year_range": $year_range, "year": $year, "make": $make, "model": $model, "trim": $trim, "dealer_id": $dealer_id, "vin": $vin, "source": $qp_source, "body_type": $body_type, "body_subtype": $body_subtype, "vehicle_type": $vehicle_type, "vins": $vins, "taxonomy_vins": $taxonomy_vins, "ymmt": $ymmt, "match": $qp_match, "cylinders": $cylinders, "transmission": $transmission, "doors": $doors, "drivetrain": $drivetrain, "exterior_color": $exterior_color, "interior_color": $interior_color, "base_exterior_color": $base_exterior_color, "base_interior_color": $base_interior_color, "engine": $engine, "engine_size": $engine_size, "engine_aspiration": $engine_aspiration, "engine_block": $engine_block, "highway_mpg_range": $highway_mpg_range, "city_mpg_range": $city_mpg_range, "miles_range": $miles_range, "price_range": $price_range, "msrp_range": $msrp_range, "dom_range": $dom_range, "last_seen_range": $last_seen_range, "first_seen_range": $first_seen_range, "first_seen_at_source_range": $first_seen_at_source_range, "first_seen_at_mc_range": $first_seen_at_mc_range, "last_seen_days": $last_seen_days, "first_seen_days": $first_seen_days, "first_seen_at_source_days": $first_seen_at_source_days, "first_seen_at_mc_days": $first_seen_at_mc_days, "sort_by": $sort_by, "sort_order": $sort_order, "rows": $rows, "start": $start, "include_non_vin_listings": $include_non_vin_listings, "facets": $facets, "range_facets": $range_facets, "facet_sort": $facet_sort, "stats": $stats, "country": $country, "plot": $plot, "nodedup": $nodedup, "dedup": $dedup, "owned": $owned, "state": $state, "city": $city, "msa_code": $msa_code, "dealer_name": $dealer_name, "dealership_group_name": $dealership_group_name, "trim_o": $trim_o, "trim_r": $trim_r, "dom_active_range": $dom_active_range, "dom_180_range": $dom_180_range, "exclude_certified": $exclude_certified, "fuel_type": $fuel_type, "dealer_type": $dealer_type, "photo_links": $photo_links, "photo_links_cached": $photo_links_cached, "stock_no": $stock_no, "sold": $sold, "include_relevant_links": $include_relevant_links, "expired": $expired, "exclude_dealer_ids": $exclude_dealer_ids, "exclude_sources": $exclude_sources, "in_transit": $in_transit, "seating_capacity": $seating_capacity, "active_inventory_date_range": $active_inventory_date_range, "engine_size_range": $engine_size_range, "price_change_range": $price_change_range} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets active car listings in UK for the given search criteria
#
# GET /search/car/uk/active
# operationId: search
export def "search-car-uk-active list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --postal-code: string # To filter listing on postal code around which they are listed
  --zip: string # To filter listing on ZIP around which they are listed
  --car-type: string@car-type-completer-1 # Car type. Allowed values are - new / used
  --year: string # To filter listing on their year
  --year-range: string # Year range to filter listings with the year in the range given. Range to be given in the format - min-max e.g. 2019-2021 (format: string)
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --variant: string # To filter listing on their variant
  --trim: string # To filter listing on their trim
  --vin: string # To filter listing on their VIN
  --body-type: string # To filter listing on their body type
  --ymmt: string # Comma separated list of Year, Make, Model, Trim combinations. Each combination needs to have the year,make,model, trim values separated by a pipe '|' character in the form year|make|model|trim. e.g. 2010|Audi|A5,2014|Nissan|Sentra|S 6MT,|Honda|City| You could just provide strings of the form - 'year|make||' or 'year|make|model' or '|make|model|' combinations. Individual year / make / model filters provied with the API calls will take precedence over the Year, Make, Model, Trim combinations. The Make, Model, Trim values must be valid values as per the Marketcheck Vin Decoder. If you are using a separate vin decoder then look at using the 'vins' or 'taxonomy_vins' parameter to the search api instead the year|make|model|trim combinations.
  --transmission: string # To filter listing on their transmission
  --doors: string # Doors to filter the cars on. Valid filter values are those that our Search facets API returns for unique doors. You can pass in multiple doors values comma separated (format: string)
  --drivetrain: string # To filter listing on their drivetrain
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --engine: string # To filter listing on their engine
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --msa-code: string # To filter listing on msa code in which they are listed
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --country: string@country-completer-5 # To filter listing on Country in which they are listed (default: uk)
  --plot: oneof<nothing, bool> # If plot has value true results in around 25k coordinates with limited fields to plot respective graph
  --nodedup: oneof<nothing, bool> # If nodedup is set to true then API will give results without is_searchable i.e multiple listings for single vin
  --dedup: oneof<nothing, bool> # If dedup is set to true then will give results with is_searchable irrespecive of dealer_id or source
  --county: string # To filter listing on county in which they are listed
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --fuel-type: string # To filter listing on their fuel type
  --stock-no: string # To filter listing on their stock number on lot
  --dom-range: string # Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dom-active-range: string # Active Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dom-180-range: string # Last 180 Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-source-range: string # First seen at source date range to filter listings with the first seen at source in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-mc-range: string # First seen at MC date range to filter listings with the first seen at MC in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-source-days: string # First seen at source days range to filter listings with the first seen at source in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-mc-days: string # First seen at MC days range to filter listings with the first seen at MC in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --co2-emissions: string # CO2 emissions
  --insurance-group: string # Insurance Group
  --vehicle-registration-mark: string # Vehicle Registration Mark
  --vehicle-registration-date-range: string # Vehicle registration date range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --num-owners: string # Number of owners. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --inventory-count-range: string # Inventory count range to filter listings with count of total listings in dealers inventory. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --qp-source: string # To filter listing on their source only for widget requests
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --exclude-sources: string # A list of sources to exclude from result (format: string)
  --exclude-dealer-ids: string # A list of dealer ids to exclude from result (format: string)
  --in-transit: string@in-transit-completer # A boolean to filter in transit vehicles
  --include-non-vin-listings: oneof<nothing, bool> # To include non vin listings. Default is false (default: false)
  --cylinders: string # To filter listing on their cylinders
  --photo-links: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links in search results, And discard those that don't have them
  --photo-links-cached: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links_cached in search results, And discard those that don't have them
  --base-exterior-color: string # Base exterior color to match. Valid filter values are those that our Search facets API returns for unique base exterior colors. You can pass in multiple base interior color values comma separated
  --base-interior-color: string # Base interior color to match. Valid filter values are those that our Search facets API returns for unique base interior colors. You can pass in multiple base interior color values comma separated
  --write-off-category: string # write off category (format: string)
  --exclude-write-off-category: string # To exclude write off category (format: string)
  --fca-status: string # To filter on fca status (format: string)
  --seating-capacity: string # To filter on vehicle seating capacity (format: string)
  --vrm: string # To filter on vrm (format: string)
  --powertrain-type: string # To filter on powertrain_type (format: string)
  --client-filters: oneof<nothing, bool> # Flag to add explicit filters set on client level in solr (default: true)
  --boost: oneof<nothing, bool> # Flag to sort listings based on client filter score in solr (default: true)
  --car-location-seller-name: string # Filter cars on seller name
  --car-location-street: string # Filter cars on street name
  --car-location-city: string # Filter cars on city
  --car-location-county: string # Filter cars on county
  --car-location-zip: string # To filter listing on car ZIP around which they are listed
  --car-location-latitude: float # Latitude component of car location (format: double)
  --car-location-longitude: float # Longitude component of car location (format: double)
  --price-change: string@price-change-completer # Query to filter listings based on their positive and negative price change
  --price-change-range: string # Price change range to filter listings with price change within given price_change_range. Range to be given in the format - min-max e.g. 10-500 (format: string)
  --active-inventory-date-range: string # date range to filter listings that were active within given date range. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-size-range: string # Engine size range to filter listings with engine size in the given range. Range to be given in the format - min-max e.g. 1.0-2 (format: string)
  --uvc-id: string # To filter on uvc id (format: string)
  --highway-mpg-range: string # Highway mileage range for UK to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --city-mpg-range: string # City mileage range for UK to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --combined-mpg-range: string # Combined mileage range for UK to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --owned: oneof<nothing, bool> # Used in combination with dealer_id or source, when true returns the listings actually owned by dealer himself
  --min-photo-links: string # Filter listings based by number of photo links within given range (format: string)
  --min-photo-links-cached: string # Filter listings based by number of cached photo links within given range (format: string)
]: nothing -> record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_location_city: list<record>, car_location_county: list<record>, car_location_seller_name: list<record>, car_location_street: list<record>, car_location_zip: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, co2_emissions: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, dealership_group_name: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fca_status: list<record>, fuel_type: list<record>, in_transit: list<record>, insurance_group: list<record>, interior_color: list<record>, make: list<record>, mas_code: list<record>, model: list<record>, num_owners: list<record>, powertrain_type: list<record>, seating_capacity: list<record>, seller_name: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, vehicle_registration_mark: list<record>, vehicle_type: list<record>, vrm: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, car_location: record, carfax_1_owner: bool, carfax_clean_title: bool, co2_emissions: string, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, insurance_group: string, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, num_owners: string, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, uvc_id: string, vdp_url: string, vehicle_registration_mark: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "postal_code" $postal_code "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "car_type" $car_type "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "year_range" $year_range "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "variant" $variant "scalar") (serialize-qp "trim" $trim "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "body_type" $body_type "scalar") (serialize-qp "ymmt" $ymmt "scalar") (serialize-qp "transmission" $transmission "scalar") (serialize-qp "doors" $doors "scalar") (serialize-qp "drivetrain" $drivetrain "scalar") (serialize-qp "exterior_color" $exterior_color "scalar") (serialize-qp "interior_color" $interior_color "scalar") (serialize-qp "engine" $engine "scalar") (serialize-qp "miles_range" $miles_range "scalar") (serialize-qp "price_range" $price_range "scalar") (serialize-qp "msrp_range" $msrp_range "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "msa_code" $msa_code "scalar") (serialize-qp "facets" $facets "scalar") (serialize-qp "range_facets" $range_facets "scalar") (serialize-qp "facet_sort" $facet_sort "scalar") (serialize-qp "stats" $stats "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "plot" $plot "scalar") (serialize-qp "nodedup" $nodedup "scalar") (serialize-qp "dedup" $dedup "scalar") (serialize-qp "county" $county "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "fuel_type" $fuel_type "scalar") (serialize-qp "stock_no" $stock_no "scalar") (serialize-qp "dom_range" $dom_range "scalar") (serialize-qp "dom_active_range" $dom_active_range "scalar") (serialize-qp "dom_180_range" $dom_180_range "scalar") (serialize-qp "last_seen_range" $last_seen_range "scalar") (serialize-qp "first_seen_range" $first_seen_range "scalar") (serialize-qp "first_seen_at_source_range" $first_seen_at_source_range "scalar") (serialize-qp "first_seen_at_mc_range" $first_seen_at_mc_range "scalar") (serialize-qp "last_seen_days" $last_seen_days "scalar") (serialize-qp "first_seen_days" $first_seen_days "scalar") (serialize-qp "first_seen_at_source_days" $first_seen_at_source_days "scalar") (serialize-qp "first_seen_at_mc_days" $first_seen_at_mc_days "scalar") (serialize-qp "co2_emissions" $co2_emissions "scalar") (serialize-qp "insurance_group" $insurance_group "scalar") (serialize-qp "vehicle_registration_mark" $vehicle_registration_mark "scalar") (serialize-qp "vehicle_registration_date_range" $vehicle_registration_date_range "scalar") (serialize-qp "num_owners" $num_owners "scalar") (serialize-qp "inventory_count_range" $inventory_count_range "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "dealer_id" $dealer_id "scalar") (serialize-qp "exclude_sources" $exclude_sources "scalar") (serialize-qp "exclude_dealer_ids" $exclude_dealer_ids "scalar") (serialize-qp "in_transit" $in_transit "scalar") (serialize-qp "include_non_vin_listings" $include_non_vin_listings "scalar") (serialize-qp "cylinders" $cylinders "scalar") (serialize-qp "photo_links" $photo_links "scalar") (serialize-qp "photo_links_cached" $photo_links_cached "scalar") (serialize-qp "base_exterior_color" $base_exterior_color "scalar") (serialize-qp "base_interior_color" $base_interior_color "scalar") (serialize-qp "write_off_category" $write_off_category "scalar") (serialize-qp "exclude_write_off_category" $exclude_write_off_category "scalar") (serialize-qp "fca_status" $fca_status "scalar") (serialize-qp "seating_capacity" $seating_capacity "scalar") (serialize-qp "vrm" $vrm "scalar") (serialize-qp "powertrain_type" $powertrain_type "scalar") (serialize-qp "client_filters" $client_filters "scalar") (serialize-qp "boost" $boost "scalar") (serialize-qp "car_location_seller_name" $car_location_seller_name "scalar") (serialize-qp "car_location_street" $car_location_street "scalar") (serialize-qp "car_location_city" $car_location_city "scalar") (serialize-qp "car_location_county" $car_location_county "scalar") (serialize-qp "car_location_zip" $car_location_zip "scalar") (serialize-qp "car_location_latitude" $car_location_latitude "scalar") (serialize-qp "car_location_longitude" $car_location_longitude "scalar") (serialize-qp "price_change" $price_change "scalar") (serialize-qp "price_change_range" $price_change_range "scalar") (serialize-qp "active_inventory_date_range" $active_inventory_date_range "scalar") (serialize-qp "engine_size" $engine_size "scalar") (serialize-qp "engine_size_range" $engine_size_range "scalar") (serialize-qp "uvc_id" $uvc_id "scalar") (serialize-qp "highway_mpg_range" $highway_mpg_range "scalar") (serialize-qp "city_mpg_range" $city_mpg_range "scalar") (serialize-qp "combined_mpg_range" $combined_mpg_range "scalar") (serialize-qp "owned" $owned "scalar") (serialize-qp "min_photo_links" $min_photo_links "scalar") (serialize-qp "min_photo_links_cached" $min_photo_links_cached "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/car/uk/active" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "postal_code": $postal_code, "zip": $zip, "car_type": $car_type, "year": $year, "year_range": $year_range, "make": $make, "model": $model, "variant": $variant, "trim": $trim, "vin": $vin, "body_type": $body_type, "ymmt": $ymmt, "transmission": $transmission, "doors": $doors, "drivetrain": $drivetrain, "exterior_color": $exterior_color, "interior_color": $interior_color, "engine": $engine, "miles_range": $miles_range, "price_range": $price_range, "msrp_range": $msrp_range, "sort_by": $sort_by, "sort_order": $sort_order, "rows": $rows, "start": $start, "msa_code": $msa_code, "facets": $facets, "range_facets": $range_facets, "facet_sort": $facet_sort, "stats": $stats, "country": $country, "plot": $plot, "nodedup": $nodedup, "dedup": $dedup, "county": $county, "state": $state, "city": $city, "fuel_type": $fuel_type, "stock_no": $stock_no, "dom_range": $dom_range, "dom_active_range": $dom_active_range, "dom_180_range": $dom_180_range, "last_seen_range": $last_seen_range, "first_seen_range": $first_seen_range, "first_seen_at_source_range": $first_seen_at_source_range, "first_seen_at_mc_range": $first_seen_at_mc_range, "last_seen_days": $last_seen_days, "first_seen_days": $first_seen_days, "first_seen_at_source_days": $first_seen_at_source_days, "first_seen_at_mc_days": $first_seen_at_mc_days, "co2_emissions": $co2_emissions, "insurance_group": $insurance_group, "vehicle_registration_mark": $vehicle_registration_mark, "vehicle_registration_date_range": $vehicle_registration_date_range, "num_owners": $num_owners, "inventory_count_range": $inventory_count_range, "source": $qp_source, "dealer_id": $dealer_id, "exclude_sources": $exclude_sources, "exclude_dealer_ids": $exclude_dealer_ids, "in_transit": $in_transit, "include_non_vin_listings": $include_non_vin_listings, "cylinders": $cylinders, "photo_links": $photo_links, "photo_links_cached": $photo_links_cached, "base_exterior_color": $base_exterior_color, "base_interior_color": $base_interior_color, "write_off_category": $write_off_category, "exclude_write_off_category": $exclude_write_off_category, "fca_status": $fca_status, "seating_capacity": $seating_capacity, "vrm": $vrm, "powertrain_type": $powertrain_type, "client_filters": $client_filters, "boost": $boost, "car_location_seller_name": $car_location_seller_name, "car_location_street": $car_location_street, "car_location_city": $car_location_city, "car_location_county": $car_location_county, "car_location_zip": $car_location_zip, "car_location_latitude": $car_location_latitude, "car_location_longitude": $car_location_longitude, "price_change": $price_change, "price_change_range": $price_change_range, "active_inventory_date_range": $active_inventory_date_range, "engine_size": $engine_size, "engine_size_range": $engine_size_range, "uvc_id": $uvc_id, "highway_mpg_range": $highway_mpg_range, "city_mpg_range": $city_mpg_range, "combined_mpg_range": $combined_mpg_range, "owned": $owned, "min_photo_links": $min_photo_links, "min_photo_links_cached": $min_photo_links_cached} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets Recent UK car listings for the given search criteria
#
# GET /search/car/uk/recents
export def "search-car-uk-recents get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --include-lease: oneof<nothing, bool> # Boolean param to search for listings that include leasing options in them
  --include-finance: oneof<nothing, bool> # Boolean param to search for listings that include finance options in them
  --lease-term: string # Search listings with exact lease term, or inside a range with min and max seperated by a dash like lease_term=30-60
  --lease-down-payment: string # Search listings with exact down payment in lease offers, or inside a range with min and max seperated by a dash like lease_down_payment=30-60
  --lease-emp: string # Search listings with lease offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like lease_emp=30-60
  --finance-loan-term: string # Search listings with exact finance loan term, or inside a range with min and max seperated by a dash like finance_loan_term=30-60
  --finance-loan-apr: string # Search listings with finance offers exactly matching loans Annual Percentage Rate, or inside a range with min and max seperated by a dash like finance_loan_apr=30-60
  --finance-emp: string # Search listings with finance offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like finance_emp=30-60
  --finance-down-payment: string # Search listings with exact down payment in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment=30-60
  --finance-down-payment-per: string # Search listings with exact down payment percentage in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment_per=30-60
  --car-type: string@car-type-completer # Car type. Allowed values are - new / used / certified
  --carfax-1-owner: string@carfax-1-owner-completer # Indicates whether car has had only one owner or not
  --carfax-clean-title: string@carfax-clean-title-completer # Indicates whether car has clean ownership records
  --year-range: string # Year range to filter listings with the year in the range given. Range to be given in the format - min-max e.g. 2019-2021 (format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --vin: string # To filter listing on their VIN
  --qp-source: string # To filter listing on their source
  --body-type: string # To filter listing on their body type
  --body-subtype: string # Body subtype to filter the listings on. Valid filter values are those that our Search facets API returns for unique body subtypes. You can pass in multiple body subtype values comma separated (format: string)
  --vehicle-type: string # To filter listing on their vehicle type
  --vins: string # Comma separated list of 17 digit vins to search the matching cars for. Only 10 VINs allowed per request. If the request contains more than 10 VINs the first 10 VINs will be considered. Could be used as a More Like This or Similar Vehicles search for the given VINs. Ths vins parameter is an alternative to taxonomy_vins or ymmt parameters available with the search API. vins and taxonomy_vins parameters could be used to filter our cars with the exact build represented by the vins or taxonomy_vins whereas ymmt is a top level filter that does not filter cars by the build attributes like doors, drivetrain, cylinders, body type, body subtype, vehicle type etc
  --taxonomy-vins: string # Comma separated list of 10 letters excert from the 17 letter VIN. The 10 letters to be picked up from the 17 letter VIN are - first 8 letters and the 10th and 11th letter. E.g. For a VIN - 1FTFW1EF3EKE57182 the taxonomy vin would be - 1FTFW1EFEK A taxonomy VIN identified a build of a car and could be used to filter our cars of a particular build. This is an alternative to the vin or ymmt parameters to the search API.
  --ymmt: string # Comma separated list of Year, Make, Model, Trim combinations. Each combination needs to have the year,make,model, trim values separated by a pipe '|' character in the form year|make|model|trim. e.g. 2010|Audi|A5,2014|Nissan|Sentra|S 6MT,|Honda|City| You could just provide strings of the form - 'year|make||' or 'year|make|model' or '|make|model|' combinations. Individual year / make / model filters provied with the API calls will take precedence over the Year, Make, Model, Trim combinations. The Make, Model, Trim values must be valid values as per the Marketcheck Vin Decoder. If you are using a separate vin decoder then look at using the 'vins' or 'taxonomy_vins' parameter to the search api instead the year|make|model|trim combinations.
  --qp-match: string # Comma separated list of Year, Make, Model, Trim fields. For example - year,make,model,trim fields for which user wants to do an exact match
  --cylinders: string # To filter listing on their cylinders
  --transmission: string # To filter listing on their transmission
  --doors: string # Doors to filter the cars on. Valid filter values are those that our Search facets API returns for unique doors. You can pass in multiple doors values comma separated (format: string)
  --drivetrain: string # To filter listing on their drivetrain
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --base-exterior-color: string # Base exterior color to match. Valid filter values are those that our Search facets API returns for unique base exterior colors. You can pass in multiple base interior color values comma separated
  --base-interior-color: string # Base interior color to match. Valid filter values are those that our Search facets API returns for unique base interior colors. You can pass in multiple base interior color values comma separated
  --engine: string # To filter listing on their engine
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-aspiration: string # Engine Aspiration to match. Valid filter values are those that our Search facets API returns for unique Engine Aspirations. You can pass in multiple Engine aspirations values comma separated
  --engine-block: string # Engine Block to match. Valid filter values are those that our Search facets API returns for unique Engine Block. You can pass in multiple Engine Block values comma separated
  --highway-mpg-range: string # Highway mileage range for UK to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --city-mpg-range: string # City mileage range for UK to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --combined-mpg-range: string # Combined mileage range for UK to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --dom-range: string # Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-source-range: string # First seen at source date range to filter listings with the first seen at source in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-mc-range: string # First seen at MC date range to filter listings with the first seen at MC in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-source-days: string # First seen at source days range to filter listings with the first seen at source in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-mc-days: string # First seen at MC days range to filter listings with the first seen at MC in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --include-non-vin-listings: oneof<nothing, bool> # To include non vin listings. Default is false (default: false)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --country: string@country-completer-5 # To filter listing on Country in which they are listed (default: uk)
  --plot: oneof<nothing, bool> # If plot has value true results in around 25k coordinates with limited fields to plot respective graph
  --nodedup: oneof<nothing, bool> # If nodedup is set to true then API will give results without is_searchable i.e multiple listings for single vin
  --dedup: oneof<nothing, bool> # If dedup is set to true then will give results with is_searchable irrespecive of dealer_id or source
  --owned: oneof<nothing, bool> # Used in combination with dealer_id or source, when true returns the listings actually owned by dealer himself
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --msa-code: string # To filter listing on msa code in which they are listed
  --dealer-name: string # Filter listings on dealer_name
  --dealership-group-name: string # Name of the dealership group to search for (format: string)
  --trim-o: string # Filter listings on web scraped trim
  --trim-r: string # Filter trim on custom possible matches
  --dom-active-range: string # Active Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dom-180-range: string # Last 180 Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --exclude-certified: oneof<nothing, bool> # Boolean param to exclude certified cars from search results
  --fuel-type: string # To filter listing on their fuel type
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --photo-links: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links in search results, And discard those that don't have them
  --photo-links-cached: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links_cached in search results, And discard those that don't have them
  --stock-no: string # To filter listing on their stock number on lot
  --sold: oneof<nothing, bool> # sold parameter to fetch only sold listings
  --include-relevant-links: oneof<nothing, bool> # To include_relevant_links. Default is true (default: false)
  --expired: string@expired-completer # Boolean falg to either fetch only the expired listings or active ones
  --exclude-dealer-ids: string # A list of dealer ids to exclude from result (format: string)
  --exclude-sources: string # A list of sources to exclude from result (format: string)
  --in-transit: string@in-transit-completer # A boolean to filter in transit vehicles
  --seating-capacity: string # To filter on vehicle seating capacity (format: string)
  --insurance-group: string # Insurance Group
  --vrm: string # To filter on vrm (format: string)
  --num-owners: string # Number of owners. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --variant: string # To filter listing on their variant
  --postal-code: string # To filter listing on postal code around which they are listed
  --write-off-category: string # write off category (format: string)
  --fca-status: string # To filter on fca status (format: string)
  --active-inventory-date-range: string # date range to filter listings that were active within given date range. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --engine-size-range: string # Engine size range to filter listings with engine size in the given range. Range to be given in the format - min-max e.g. 1.0-2 (format: string)
  --price-change-range: string # Price change range to filter listings with price change within given price_change_range. Range to be given in the format - min-max e.g. 10-500 (format: string)
]: nothing -> record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_location_city: list<record>, car_location_county: list<record>, car_location_seller_name: list<record>, car_location_street: list<record>, car_location_zip: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, co2_emissions: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, dealership_group_name: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fca_status: list<record>, fuel_type: list<record>, in_transit: list<record>, insurance_group: list<record>, interior_color: list<record>, make: list<record>, mas_code: list<record>, model: list<record>, num_owners: list<record>, powertrain_type: list<record>, seating_capacity: list<record>, seller_name: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, vehicle_registration_mark: list<record>, vehicle_type: list<record>, vrm: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, car_location: record, carfax_1_owner: bool, carfax_clean_title: bool, co2_emissions: string, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, insurance_group: string, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, num_owners: string, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, uvc_id: string, vdp_url: string, vehicle_registration_mark: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "append_api_key" $append_api_key "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "include_lease" $include_lease "scalar") (serialize-qp "include_finance" $include_finance "scalar") (serialize-qp "lease_term" $lease_term "scalar") (serialize-qp "lease_down_payment" $lease_down_payment "scalar") (serialize-qp "lease_emp" $lease_emp "scalar") (serialize-qp "finance_loan_term" $finance_loan_term "scalar") (serialize-qp "finance_loan_apr" $finance_loan_apr "scalar") (serialize-qp "finance_emp" $finance_emp "scalar") (serialize-qp "finance_down_payment" $finance_down_payment "scalar") (serialize-qp "finance_down_payment_per" $finance_down_payment_per "scalar") (serialize-qp "car_type" $car_type "scalar") (serialize-qp "carfax_1_owner" $carfax_1_owner "scalar") (serialize-qp "carfax_clean_title" $carfax_clean_title "scalar") (serialize-qp "year_range" $year_range "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "trim" $trim "scalar") (serialize-qp "dealer_id" $dealer_id "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "body_type" $body_type "scalar") (serialize-qp "body_subtype" $body_subtype "scalar") (serialize-qp "vehicle_type" $vehicle_type "scalar") (serialize-qp "vins" $vins "scalar") (serialize-qp "taxonomy_vins" $taxonomy_vins "scalar") (serialize-qp "ymmt" $ymmt "scalar") (serialize-qp "match" $qp_match "scalar") (serialize-qp "cylinders" $cylinders "scalar") (serialize-qp "transmission" $transmission "scalar") (serialize-qp "doors" $doors "scalar") (serialize-qp "drivetrain" $drivetrain "scalar") (serialize-qp "exterior_color" $exterior_color "scalar") (serialize-qp "interior_color" $interior_color "scalar") (serialize-qp "base_exterior_color" $base_exterior_color "scalar") (serialize-qp "base_interior_color" $base_interior_color "scalar") (serialize-qp "engine" $engine "scalar") (serialize-qp "engine_size" $engine_size "scalar") (serialize-qp "engine_aspiration" $engine_aspiration "scalar") (serialize-qp "engine_block" $engine_block "scalar") (serialize-qp "highway_mpg_range" $highway_mpg_range "scalar") (serialize-qp "city_mpg_range" $city_mpg_range "scalar") (serialize-qp "combined_mpg_range" $combined_mpg_range "scalar") (serialize-qp "miles_range" $miles_range "scalar") (serialize-qp "price_range" $price_range "scalar") (serialize-qp "msrp_range" $msrp_range "scalar") (serialize-qp "dom_range" $dom_range "scalar") (serialize-qp "last_seen_range" $last_seen_range "scalar") (serialize-qp "first_seen_range" $first_seen_range "scalar") (serialize-qp "first_seen_at_source_range" $first_seen_at_source_range "scalar") (serialize-qp "first_seen_at_mc_range" $first_seen_at_mc_range "scalar") (serialize-qp "last_seen_days" $last_seen_days "scalar") (serialize-qp "first_seen_days" $first_seen_days "scalar") (serialize-qp "first_seen_at_source_days" $first_seen_at_source_days "scalar") (serialize-qp "first_seen_at_mc_days" $first_seen_at_mc_days "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "include_non_vin_listings" $include_non_vin_listings "scalar") (serialize-qp "facets" $facets "scalar") (serialize-qp "range_facets" $range_facets "scalar") (serialize-qp "facet_sort" $facet_sort "scalar") (serialize-qp "stats" $stats "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "plot" $plot "scalar") (serialize-qp "nodedup" $nodedup "scalar") (serialize-qp "dedup" $dedup "scalar") (serialize-qp "owned" $owned "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "msa_code" $msa_code "scalar") (serialize-qp "dealer_name" $dealer_name "scalar") (serialize-qp "dealership_group_name" $dealership_group_name "scalar") (serialize-qp "trim_o" $trim_o "scalar") (serialize-qp "trim_r" $trim_r "scalar") (serialize-qp "dom_active_range" $dom_active_range "scalar") (serialize-qp "dom_180_range" $dom_180_range "scalar") (serialize-qp "exclude_certified" $exclude_certified "scalar") (serialize-qp "fuel_type" $fuel_type "scalar") (serialize-qp "dealer_type" $dealer_type "scalar") (serialize-qp "photo_links" $photo_links "scalar") (serialize-qp "photo_links_cached" $photo_links_cached "scalar") (serialize-qp "stock_no" $stock_no "scalar") (serialize-qp "sold" $sold "scalar") (serialize-qp "include_relevant_links" $include_relevant_links "scalar") (serialize-qp "expired" $expired "scalar") (serialize-qp "exclude_dealer_ids" $exclude_dealer_ids "scalar") (serialize-qp "exclude_sources" $exclude_sources "scalar") (serialize-qp "in_transit" $in_transit "scalar") (serialize-qp "seating_capacity" $seating_capacity "scalar") (serialize-qp "insurance_group" $insurance_group "scalar") (serialize-qp "vrm" $vrm "scalar") (serialize-qp "num_owners" $num_owners "scalar") (serialize-qp "variant" $variant "scalar") (serialize-qp "postal_code" $postal_code "scalar") (serialize-qp "write_off_category" $write_off_category "scalar") (serialize-qp "fca_status" $fca_status "scalar") (serialize-qp "active_inventory_date_range" $active_inventory_date_range "scalar") (serialize-qp "engine_size_range" $engine_size_range "scalar") (serialize-qp "price_change_range" $price_change_range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/car/uk/recents" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "append_api_key": $append_api_key, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "zip": $zip, "include_lease": $include_lease, "include_finance": $include_finance, "lease_term": $lease_term, "lease_down_payment": $lease_down_payment, "lease_emp": $lease_emp, "finance_loan_term": $finance_loan_term, "finance_loan_apr": $finance_loan_apr, "finance_emp": $finance_emp, "finance_down_payment": $finance_down_payment, "finance_down_payment_per": $finance_down_payment_per, "car_type": $car_type, "carfax_1_owner": $carfax_1_owner, "carfax_clean_title": $carfax_clean_title, "year_range": $year_range, "year": $year, "make": $make, "model": $model, "trim": $trim, "dealer_id": $dealer_id, "vin": $vin, "source": $qp_source, "body_type": $body_type, "body_subtype": $body_subtype, "vehicle_type": $vehicle_type, "vins": $vins, "taxonomy_vins": $taxonomy_vins, "ymmt": $ymmt, "match": $qp_match, "cylinders": $cylinders, "transmission": $transmission, "doors": $doors, "drivetrain": $drivetrain, "exterior_color": $exterior_color, "interior_color": $interior_color, "base_exterior_color": $base_exterior_color, "base_interior_color": $base_interior_color, "engine": $engine, "engine_size": $engine_size, "engine_aspiration": $engine_aspiration, "engine_block": $engine_block, "highway_mpg_range": $highway_mpg_range, "city_mpg_range": $city_mpg_range, "combined_mpg_range": $combined_mpg_range, "miles_range": $miles_range, "price_range": $price_range, "msrp_range": $msrp_range, "dom_range": $dom_range, "last_seen_range": $last_seen_range, "first_seen_range": $first_seen_range, "first_seen_at_source_range": $first_seen_at_source_range, "first_seen_at_mc_range": $first_seen_at_mc_range, "last_seen_days": $last_seen_days, "first_seen_days": $first_seen_days, "first_seen_at_source_days": $first_seen_at_source_days, "first_seen_at_mc_days": $first_seen_at_mc_days, "sort_by": $sort_by, "sort_order": $sort_order, "rows": $rows, "start": $start, "include_non_vin_listings": $include_non_vin_listings, "facets": $facets, "range_facets": $range_facets, "facet_sort": $facet_sort, "stats": $stats, "country": $country, "plot": $plot, "nodedup": $nodedup, "dedup": $dedup, "owned": $owned, "state": $state, "city": $city, "msa_code": $msa_code, "dealer_name": $dealer_name, "dealership_group_name": $dealership_group_name, "trim_o": $trim_o, "trim_r": $trim_r, "dom_active_range": $dom_active_range, "dom_180_range": $dom_180_range, "exclude_certified": $exclude_certified, "fuel_type": $fuel_type, "dealer_type": $dealer_type, "photo_links": $photo_links, "photo_links_cached": $photo_links_cached, "stock_no": $stock_no, "sold": $sold, "include_relevant_links": $include_relevant_links, "expired": $expired, "exclude_dealer_ids": $exclude_dealer_ids, "exclude_sources": $exclude_sources, "in_transit": $in_transit, "seating_capacity": $seating_capacity, "insurance_group": $insurance_group, "vrm": $vrm, "num_owners": $num_owners, "variant": $variant, "postal_code": $postal_code, "write_off_category": $write_off_category, "fca_status": $fca_status, "active_inventory_date_range": $active_inventory_date_range, "engine_size_range": $engine_size_range, "price_change_range": $price_change_range} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets active heavy equipment listings for the given search criteria
#
# GET /search/heavy-equipment/active
export def "search-heavy-equipment-active get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --search-text: string # To search a substring across entire document
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --vin: string # To filter listing on their VIN
  --inventory-type: string@inventory-type-completer # To filter listing on their condition. Either used or new
  --stock-no: string # To filter listing on their stock number on lot
  --qp-source: string # To filter listing on their source
  --dealer-name: string # Filter listings on dealer_name
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --engine: string # To filter listing on their engine
  --fuel-type: string # To filter listing on their fuel type
  --transmission: string # To filter listing on their transmission
  --drivetrain: string # To filter listing on their drivetrain
  --body-type: string # To filter listing on their body type
  --category: string # To filter heavy equipments on their category
  --sub-category: string # To filter heavy equipments on their sub-category
  --hours-used-range: string # Hours used range to filter heavy equipments with the their usage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --zip: string # To filter listing on ZIP around which they are listed
  --msa-code: string # To filter listing on msa code in which they are listed
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
]: nothing -> record<facets: record, listings: table<build: record, dealer: record, dist: float, dp_url: string, exterior_color: string, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record, miles: int, msrp: int, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vin: string>, num_found: int, range_facets: record, stats: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "price_range" $price_range "scalar") (serialize-qp "miles_range" $miles_range "scalar") (serialize-qp "msrp_range" $msrp_range "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "search_text" $search_text "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "trim" $trim "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "inventory_type" $inventory_type "scalar") (serialize-qp "stock_no" $stock_no "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "dealer_name" $dealer_name "scalar") (serialize-qp "dealer_id" $dealer_id "scalar") (serialize-qp "exterior_color" $exterior_color "scalar") (serialize-qp "interior_color" $interior_color "scalar") (serialize-qp "engine" $engine "scalar") (serialize-qp "fuel_type" $fuel_type "scalar") (serialize-qp "transmission" $transmission "scalar") (serialize-qp "drivetrain" $drivetrain "scalar") (serialize-qp "body_type" $body_type "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "sub_category" $sub_category "scalar") (serialize-qp "hours_used_range" $hours_used_range "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "msa_code" $msa_code "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facets" $facets "scalar") (serialize-qp "range_facets" $range_facets "scalar") (serialize-qp "facet_sort" $facet_sort "scalar") (serialize-qp "stats" $stats "scalar") (serialize-qp "last_seen_range" $last_seen_range "scalar") (serialize-qp "first_seen_range" $first_seen_range "scalar") (serialize-qp "last_seen_days" $last_seen_days "scalar") (serialize-qp "first_seen_days" $first_seen_days "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/heavy-equipment/active" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "price_range": $price_range, "miles_range": $miles_range, "msrp_range": $msrp_range, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "search_text": $search_text, "year": $year, "make": $make, "model": $model, "trim": $trim, "vin": $vin, "inventory_type": $inventory_type, "stock_no": $stock_no, "source": $qp_source, "dealer_name": $dealer_name, "dealer_id": $dealer_id, "exterior_color": $exterior_color, "interior_color": $interior_color, "engine": $engine, "fuel_type": $fuel_type, "transmission": $transmission, "drivetrain": $drivetrain, "body_type": $body_type, "category": $category, "sub_category": $sub_category, "hours_used_range": $hours_used_range, "state": $state, "city": $city, "zip": $zip, "msa_code": $msa_code, "sort_by": $sort_by, "sort_order": $sort_order, "rows": $rows, "start": $start, "facets": $facets, "range_facets": $range_facets, "facet_sort": $facet_sort, "stats": $stats, "last_seen_range": $last_seen_range, "first_seen_range": $first_seen_range, "last_seen_days": $last_seen_days, "first_seen_days": $first_seen_days} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# API for auto-completion of inputs
#
# GET /search/heavy-equipment/auto-complete
export def "search-heavy-equipment-auto-complete get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --field: string@field-completer-1 # Field name for which you want auto-completion (format: string)
  --input: string # Input entered so far (format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --body-type: string # To filter listing on their body type
  --vehicle-type: string # To filter listing on their vehicle type
  --transmission: string # To filter listing on their transmission
  --drivetrain: string # To filter listing on their drivetrain
  --fuel-type: string # To filter listing on their fuel type
  --color: string # Color of the vehicle
  --engine: string # To filter listing on their engine
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --inventory-type: string@inventory-type-completer # To filter listing on their condition. Either used or new
  --ignore-case: oneof<nothing, bool> # Boolean variable to indicate ignore case of current input (default: true)
  --term-counts: oneof<nothing, bool> # Boolean variable to indicate wheather to include term counts as well in response (default: false)
  --sort-by: string@sort-by-completer # Sort the response, either by index or count(default) (default: index)
  --seller-type: string # seller type for autocomplete
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --facet-min-count: float # Provide minimum count value for facets (format: number, default: 1)
]: nothing -> record<terms: table<count: int, item: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "field" $field "scalar") (serialize-qp "input" $input "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "trim" $trim "scalar") (serialize-qp "body_type" $body_type "scalar") (serialize-qp "vehicle_type" $vehicle_type "scalar") (serialize-qp "transmission" $transmission "scalar") (serialize-qp "drivetrain" $drivetrain "scalar") (serialize-qp "fuel_type" $fuel_type "scalar") (serialize-qp "color" $color "scalar") (serialize-qp "engine" $engine "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "inventory_type" $inventory_type "scalar") (serialize-qp "ignore_case" $ignore_case "scalar") (serialize-qp "term_counts" $term_counts "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "seller_type" $seller_type "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "facet_min_count" $facet_min_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/heavy-equipment/auto-complete" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "field": $field, "input": $input, "year": $year, "make": $make, "model": $model, "trim": $trim, "body_type": $body_type, "vehicle_type": $vehicle_type, "transmission": $transmission, "drivetrain": $drivetrain, "fuel_type": $fuel_type, "color": $color, "engine": $engine, "state": $state, "city": $city, "inventory_type": $inventory_type, "ignore_case": $ignore_case, "term_counts": $term_counts, "sort_by": $sort_by, "seller_type": $seller_type, "radius": $radius, "zip": $zip, "facet_min_count": $facet_min_count} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets active motorcycle listings for the given search criteria
#
# GET /search/motorcycle/active
export def "search-motorcycle-active get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --search-text: string # To search a substring across entire document
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --vin: string # To filter listing on their VIN
  --taxonomy-vin: string # Taxonomy VIN of the motorcycle
  --inventory-type: string@inventory-type-completer # To filter listing on their condition. Either used or new
  --stock-no: string # To filter listing on their stock number on lot
  --qp-source: string # To filter listing on their source
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --color: string # Color of the vehicle
  --body-type: string # To filter listing on their body type
  --vehicle-type: string # To filter listing on their vehicle type
  --cylinders: string # To filter listing on their cylinders
  --drivetrain: string # To filter listing on their drivetrain
  --engine: string # To filter listing on their engine
  --fuel-type: string # To filter listing on their fuel type
  --transmission: string # To filter listing on their transmission
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --zip: string # To filter listing on ZIP around which they are listed
  --msa-code: string # To filter listing on msa code in which they are listed
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
]: nothing -> record<facets: record, listings: table<build: record, color: string, dealer: record, dist: float, dp_url: string, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record, miles: int, msrp: int, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vin: string>, num_found: int, range_facets: record, stats: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "price_range" $price_range "scalar") (serialize-qp "miles_range" $miles_range "scalar") (serialize-qp "msrp_range" $msrp_range "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "search_text" $search_text "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "trim" $trim "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "taxonomy_vin" $taxonomy_vin "scalar") (serialize-qp "inventory_type" $inventory_type "scalar") (serialize-qp "stock_no" $stock_no "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "dealer_id" $dealer_id "scalar") (serialize-qp "color" $color "scalar") (serialize-qp "body_type" $body_type "scalar") (serialize-qp "vehicle_type" $vehicle_type "scalar") (serialize-qp "cylinders" $cylinders "scalar") (serialize-qp "drivetrain" $drivetrain "scalar") (serialize-qp "engine" $engine "scalar") (serialize-qp "fuel_type" $fuel_type "scalar") (serialize-qp "transmission" $transmission "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "msa_code" $msa_code "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facets" $facets "scalar") (serialize-qp "range_facets" $range_facets "scalar") (serialize-qp "facet_sort" $facet_sort "scalar") (serialize-qp "stats" $stats "scalar") (serialize-qp "last_seen_range" $last_seen_range "scalar") (serialize-qp "first_seen_range" $first_seen_range "scalar") (serialize-qp "last_seen_days" $last_seen_days "scalar") (serialize-qp "first_seen_days" $first_seen_days "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/motorcycle/active" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "price_range": $price_range, "miles_range": $miles_range, "msrp_range": $msrp_range, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "search_text": $search_text, "year": $year, "make": $make, "model": $model, "trim": $trim, "vin": $vin, "taxonomy_vin": $taxonomy_vin, "inventory_type": $inventory_type, "stock_no": $stock_no, "source": $qp_source, "dealer_id": $dealer_id, "color": $color, "body_type": $body_type, "vehicle_type": $vehicle_type, "cylinders": $cylinders, "drivetrain": $drivetrain, "engine": $engine, "fuel_type": $fuel_type, "transmission": $transmission, "state": $state, "city": $city, "zip": $zip, "msa_code": $msa_code, "sort_by": $sort_by, "sort_order": $sort_order, "rows": $rows, "start": $start, "facets": $facets, "range_facets": $range_facets, "facet_sort": $facet_sort, "stats": $stats, "last_seen_range": $last_seen_range, "first_seen_range": $first_seen_range, "last_seen_days": $last_seen_days, "first_seen_days": $first_seen_days} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# API for auto-completion of inputs
#
# GET /search/motorcycle/auto-complete
export def "search-motorcycle-auto-complete get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --field: string@field-completer-2 # Field name for which you want auto-completion (format: string)
  --input: string # Input entered so far (format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --body-type: string # To filter listing on their body type
  --vehicle-type: string # To filter listing on their vehicle type
  --transmission: string # To filter listing on their transmission
  --drivetrain: string # To filter listing on their drivetrain
  --fuel-type: string # To filter listing on their fuel type
  --color: string # Color of the vehicle
  --engine: string # To filter listing on their engine
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --inventory-type: string@inventory-type-completer # To filter listing on their condition. Either used or new
  --ignore-case: oneof<nothing, bool> # Boolean variable to indicate ignore case of current input (default: true)
  --term-counts: oneof<nothing, bool> # Boolean variable to indicate wheather to include term counts as well in response (default: false)
  --sort-by: string@sort-by-completer # Sort the response, either by index or count(default) (default: index)
  --seller-type: string # seller type for autocomplete
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --facet-min-count: float # Provide minimum count value for facets (format: number, default: 1)
]: nothing -> record<terms: table<count: int, item: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "field" $field "scalar") (serialize-qp "input" $input "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "trim" $trim "scalar") (serialize-qp "body_type" $body_type "scalar") (serialize-qp "vehicle_type" $vehicle_type "scalar") (serialize-qp "transmission" $transmission "scalar") (serialize-qp "drivetrain" $drivetrain "scalar") (serialize-qp "fuel_type" $fuel_type "scalar") (serialize-qp "color" $color "scalar") (serialize-qp "engine" $engine "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "inventory_type" $inventory_type "scalar") (serialize-qp "ignore_case" $ignore_case "scalar") (serialize-qp "term_counts" $term_counts "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "seller_type" $seller_type "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "facet_min_count" $facet_min_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/motorcycle/auto-complete" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "field": $field, "input": $input, "year": $year, "make": $make, "model": $model, "trim": $trim, "body_type": $body_type, "vehicle_type": $vehicle_type, "transmission": $transmission, "drivetrain": $drivetrain, "fuel_type": $fuel_type, "color": $color, "engine": $engine, "state": $state, "city": $city, "inventory_type": $inventory_type, "ignore_case": $ignore_case, "term_counts": $term_counts, "sort_by": $sort_by, "seller_type": $seller_type, "radius": $radius, "zip": $zip, "facet_min_count": $facet_min_count} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets active RV listings for the given search criteria
#
# GET /search/rv/active
export def "search-rv-active get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --year-range: string # Year range to filter listings with the year in the range given. Range to be given in the format - min-max e.g. 2019-2021 (format: string)
  --search-text: string # To search a substring across entire document
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --model-o: string # To filter listings on their model orig (as described on the webpage)
  --vin: string # To filter listing on their VIN
  --inventory-type: string@inventory-type-completer # To filter listing on their condition. Either used or new
  --stock-no: string # To filter listing on their stock number on lot
  --qp-source: string # To filter listing on their source
  --dealer-name: string # Filter listings on dealer_name
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --engine: string # To filter listing on their engine
  --fuel-type: string # To filter listing on their fuel type
  --transmission: string # To filter listing on their transmission
  --class: string # Filter RV listings on class
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --zip: string # To filter listing on ZIP around which they are listed
  --msa-code: string # To filter listing on msa code in which they are listed
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --slideouts: string # Filter RV listings on slideouts
  --length-range: string # length range to filter listings with the length in the range given. Range to be given in the format - min-max e.g. 50-200 (format: string)
  --length: string # Filter RV listings on length
  --base-exterior-color: string # Base exterior color to match. Valid filter values are those that our Search facets API returns for unique base exterior colors. You can pass in multiple base interior color values comma separated
  --base-interior-color: string # Base interior color to match. Valid filter values are those that our Search facets API returns for unique base interior colors. You can pass in multiple base interior color values comma separated
  --seating-capacity: string # To filter on vehicle seating capacity (format: string)
  --fresh-water-capacity: string # To filter on fresh water capacity of vehicle
  --sleeps: string # To filter data based on sleeps (format: string)
  --cylinders: string # To filter listing on their cylinders
  --number-of-awnings: string # To filter on number_of_awnings (format: string)
  --doors: string # Doors to filter the cars on. Valid filter values are those that our Search facets API returns for unique doors. You can pass in multiple doors values comma separated (format: string)
  --gvwr: string # To filter on the maximum total weight of your vehicle
]: nothing -> record<facets: record, listings: table<build: record, dealer: record, dist: float, dp_url: string, exterior_color: string, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record, miles: int, msrp: int, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vin: string>, num_found: int, range_facets: record, stats: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "price_range" $price_range "scalar") (serialize-qp "miles_range" $miles_range "scalar") (serialize-qp "msrp_range" $msrp_range "scalar") (serialize-qp "year_range" $year_range "scalar") (serialize-qp "search_text" $search_text "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "model_o" $model_o "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "inventory_type" $inventory_type "scalar") (serialize-qp "stock_no" $stock_no "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "dealer_name" $dealer_name "scalar") (serialize-qp "dealer_id" $dealer_id "scalar") (serialize-qp "exterior_color" $exterior_color "scalar") (serialize-qp "interior_color" $interior_color "scalar") (serialize-qp "engine" $engine "scalar") (serialize-qp "fuel_type" $fuel_type "scalar") (serialize-qp "transmission" $transmission "scalar") (serialize-qp "class" $class "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "msa_code" $msa_code "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facets" $facets "scalar") (serialize-qp "range_facets" $range_facets "scalar") (serialize-qp "facet_sort" $facet_sort "scalar") (serialize-qp "stats" $stats "scalar") (serialize-qp "last_seen_range" $last_seen_range "scalar") (serialize-qp "first_seen_range" $first_seen_range "scalar") (serialize-qp "last_seen_days" $last_seen_days "scalar") (serialize-qp "first_seen_days" $first_seen_days "scalar") (serialize-qp "slideouts" $slideouts "scalar") (serialize-qp "length_range" $length_range "scalar") (serialize-qp "length" $length "scalar") (serialize-qp "base_exterior_color" $base_exterior_color "scalar") (serialize-qp "base_interior_color" $base_interior_color "scalar") (serialize-qp "seating_capacity" $seating_capacity "scalar") (serialize-qp "fresh_water_capacity" $fresh_water_capacity "scalar") (serialize-qp "sleeps" $sleeps "scalar") (serialize-qp "cylinders" $cylinders "scalar") (serialize-qp "number_of_awnings" $number_of_awnings "scalar") (serialize-qp "doors" $doors "scalar") (serialize-qp "gvwr" $gvwr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/rv/active" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "price_range": $price_range, "miles_range": $miles_range, "msrp_range": $msrp_range, "year_range": $year_range, "search_text": $search_text, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "year": $year, "make": $make, "model": $model, "model_o": $model_o, "vin": $vin, "inventory_type": $inventory_type, "stock_no": $stock_no, "source": $qp_source, "dealer_name": $dealer_name, "dealer_id": $dealer_id, "exterior_color": $exterior_color, "interior_color": $interior_color, "engine": $engine, "fuel_type": $fuel_type, "transmission": $transmission, "class": $class, "state": $state, "city": $city, "zip": $zip, "msa_code": $msa_code, "sort_by": $sort_by, "sort_order": $sort_order, "rows": $rows, "start": $start, "facets": $facets, "range_facets": $range_facets, "facet_sort": $facet_sort, "stats": $stats, "last_seen_range": $last_seen_range, "first_seen_range": $first_seen_range, "last_seen_days": $last_seen_days, "first_seen_days": $first_seen_days, "slideouts": $slideouts, "length_range": $length_range, "length": $length, "base_exterior_color": $base_exterior_color, "base_interior_color": $base_interior_color, "seating_capacity": $seating_capacity, "fresh_water_capacity": $fresh_water_capacity, "sleeps": $sleeps, "cylinders": $cylinders, "number_of_awnings": $number_of_awnings, "doors": $doors, "gvwr": $gvwr} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# API for auto-completion of inputs
#
# GET /search/rv/auto-complete
export def "search-rv-auto-complete get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --field: string@field-completer-3 # Field name for which you want auto-completion (format: string)
  --input: string # Input entered so far (format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --body-type: string # To filter listing on their body type
  --vehicle-type: string # To filter listing on their vehicle type
  --transmission: string # To filter listing on their transmission
  --drivetrain: string # To filter listing on their drivetrain
  --fuel-type: string # To filter listing on their fuel type
  --color: string # Color of the vehicle
  --engine: string # To filter listing on their engine
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --inventory-type: string@inventory-type-completer # To filter listing on their condition. Either used or new
  --ignore-case: oneof<nothing, bool> # Boolean variable to indicate ignore case of current input (default: true)
  --term-counts: oneof<nothing, bool> # Boolean variable to indicate wheather to include term counts as well in response (default: false)
  --sort-by: string@sort-by-completer # Sort the response, either by index or count(default) (default: index)
  --seller-type: string # seller type for autocomplete
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --facet-min-count: float # Provide minimum count value for facets (format: number, default: 1)
]: nothing -> record<terms: table<count: int, item: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "field" $field "scalar") (serialize-qp "input" $input "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "trim" $trim "scalar") (serialize-qp "body_type" $body_type "scalar") (serialize-qp "vehicle_type" $vehicle_type "scalar") (serialize-qp "transmission" $transmission "scalar") (serialize-qp "drivetrain" $drivetrain "scalar") (serialize-qp "fuel_type" $fuel_type "scalar") (serialize-qp "color" $color "scalar") (serialize-qp "engine" $engine "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "inventory_type" $inventory_type "scalar") (serialize-qp "ignore_case" $ignore_case "scalar") (serialize-qp "term_counts" $term_counts "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "seller_type" $seller_type "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "facet_min_count" $facet_min_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/rv/auto-complete" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "field": $field, "input": $input, "year": $year, "make": $make, "model": $model, "trim": $trim, "body_type": $body_type, "vehicle_type": $vehicle_type, "transmission": $transmission, "drivetrain": $drivetrain, "fuel_type": $fuel_type, "color": $color, "engine": $engine, "state": $state, "city": $city, "inventory_type": $inventory_type, "ignore_case": $ignore_case, "term_counts": $term_counts, "sort_by": $sort_by, "seller_type": $seller_type, "radius": $radius, "zip": $zip, "facet_min_count": $facet_min_count} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets active RV listings for the given search criteria
#
# GET /search/rv/uk/active
export def "search-rv-uk-active get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --year-range: string # Year range to filter listings with the year in the range given. Range to be given in the format - min-max e.g. 2019-2021 (format: string)
  --search-text: string # To search a substring across entire document
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --vin: string # To filter listing on their VIN
  --qp-source: string # To filter listing on their source
  --dealer-name: string # Filter listings on dealer_name
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --fuel-type: string # To filter listing on their fuel type
  --category: string # Filter RV listings on category
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --county: string # To filter listing on county in which they are listed
  --postal-code: string # To filter listing on postal code around which they are listed
  --zip: string # To filter listing on ZIP around which they are listed
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --base-exterior-color: string # Base exterior color to match. Valid filter values are those that our Search facets API returns for unique base exterior colors. You can pass in multiple base interior color values comma separated
  --base-interior-color: string # Base interior color to match. Valid filter values are those that our Search facets API returns for unique base interior colors. You can pass in multiple base interior color values comma separated
  --seating-capacity: string # To filter on vehicle seating capacity (format: string)
  --cylinders: string # To filter listing on their cylinders
  --doors: string # Doors to filter the cars on. Valid filter values are those that our Search facets API returns for unique doors. You can pass in multiple doors values comma separated (format: string)
  --mtplm: string # To filter rv on mtplm
  --sub-category: string # To filter rv on their sub-category
  --availability-status: string # To filter rv on their availability_status
  --berths: string # To filter rv on their berths
  --inventory-type: string@inventory-type-completer # To filter listing on their condition. Either used or new
  --width-range: string # width range to filter listings on width in the range given. Range to be given in the format - min-max e.g. 4-8 (format: string)
  --exterior-length-range: string # width range to filter listings on exterior_length in the range given. Range to be given in the format - min-max e.g. 4-8 (format: string)
  --interior-length-range: string # width range to filter listings on interior_length in the range given. Range to be given in the format - min-max e.g. 4-8 (format: string)
  --drive-type: string # To filter rv on their drive_type
  --steering: string # To filter rv on their steering
  --chassis: string # To filter rv on their chassis
  --transmission: string # To filter listing on their transmission
]: nothing -> record<facets: record, listings: table<availability_status: string, build: record, currency_indicator: string, dealer: record, dist: float, exterior_color: string, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record, miles: int, miles_indicator: string, mot_expires: string, motorhome_build: string, msrp: int, origin: string, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vdp_url: string, vin: string>, num_found: int, range_facets: record, stats: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "price_range" $price_range "scalar") (serialize-qp "miles_range" $miles_range "scalar") (serialize-qp "msrp_range" $msrp_range "scalar") (serialize-qp "year_range" $year_range "scalar") (serialize-qp "search_text" $search_text "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "dealer_name" $dealer_name "scalar") (serialize-qp "dealer_id" $dealer_id "scalar") (serialize-qp "exterior_color" $exterior_color "scalar") (serialize-qp "interior_color" $interior_color "scalar") (serialize-qp "engine_size" $engine_size "scalar") (serialize-qp "fuel_type" $fuel_type "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "county" $county "scalar") (serialize-qp "postal_code" $postal_code "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "facets" $facets "scalar") (serialize-qp "range_facets" $range_facets "scalar") (serialize-qp "facet_sort" $facet_sort "scalar") (serialize-qp "stats" $stats "scalar") (serialize-qp "last_seen_range" $last_seen_range "scalar") (serialize-qp "first_seen_range" $first_seen_range "scalar") (serialize-qp "last_seen_days" $last_seen_days "scalar") (serialize-qp "first_seen_days" $first_seen_days "scalar") (serialize-qp "base_exterior_color" $base_exterior_color "scalar") (serialize-qp "base_interior_color" $base_interior_color "scalar") (serialize-qp "seating_capacity" $seating_capacity "scalar") (serialize-qp "cylinders" $cylinders "scalar") (serialize-qp "doors" $doors "scalar") (serialize-qp "mtplm" $mtplm "scalar") (serialize-qp "sub_category" $sub_category "scalar") (serialize-qp "availability_status" $availability_status "scalar") (serialize-qp "berths" $berths "scalar") (serialize-qp "inventory_type" $inventory_type "scalar") (serialize-qp "width_range" $width_range "scalar") (serialize-qp "exterior_length_range" $exterior_length_range "scalar") (serialize-qp "interior_length_range" $interior_length_range "scalar") (serialize-qp "drive_type" $drive_type "scalar") (serialize-qp "steering" $steering "scalar") (serialize-qp "chassis" $chassis "scalar") (serialize-qp "transmission" $transmission "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/rv/uk/active" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "price_range": $price_range, "miles_range": $miles_range, "msrp_range": $msrp_range, "year_range": $year_range, "search_text": $search_text, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "year": $year, "make": $make, "model": $model, "vin": $vin, "source": $qp_source, "dealer_name": $dealer_name, "dealer_id": $dealer_id, "exterior_color": $exterior_color, "interior_color": $interior_color, "engine_size": $engine_size, "fuel_type": $fuel_type, "category": $category, "state": $state, "city": $city, "county": $county, "postal_code": $postal_code, "zip": $zip, "sort_by": $sort_by, "sort_order": $sort_order, "rows": $rows, "start": $start, "facets": $facets, "range_facets": $range_facets, "facet_sort": $facet_sort, "stats": $stats, "last_seen_range": $last_seen_range, "first_seen_range": $first_seen_range, "last_seen_days": $last_seen_days, "first_seen_days": $first_seen_days, "base_exterior_color": $base_exterior_color, "base_interior_color": $base_interior_color, "seating_capacity": $seating_capacity, "cylinders": $cylinders, "doors": $doors, "mtplm": $mtplm, "sub_category": $sub_category, "availability_status": $availability_status, "berths": $berths, "inventory_type": $inventory_type, "width_range": $width_range, "exterior_length_range": $exterior_length_range, "interior_length_range": $interior_length_range, "drive_type": $drive_type, "steering": $steering, "chassis": $chassis, "transmission": $transmission} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# API for auto-completion of inputs based on taxonomy
#
# GET /specs/car/auto-complete
export def "specs-car-auto-complete get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --field: string@field-completer-4 # Field name for which you want auto-completion (format: string)
  --input: string # Input entered so far (format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --body-type: string # To filter listing on their body type
  --body-subtype: string # Body subtype to filter the listings on. Valid filter values are those that our Search facets API returns for unique body subtypes. You can pass in multiple body subtype values comma separated (format: string)
  --vehicle-type: string # To filter listing on their vehicle type
  --transmission: string # To filter listing on their transmission
  --drivetrain: string # To filter listing on their drivetrain
  --fuel-type: string # To filter listing on their fuel type
  --engine: string # To filter listing on their engine
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-block: string # Engine Block to match. Valid filter values are those that our Search facets API returns for unique Engine Block. You can pass in multiple Engine Block values comma separated
  --ignore-case: oneof<nothing, bool> # Boolean variable to indicate ignore case of current input (default: true)
  --facet-min-count: float # Provide minimum count value for facets (format: number, default: 1)
]: nothing -> record<terms: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "field" $field "scalar") (serialize-qp "input" $input "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "trim" $trim "scalar") (serialize-qp "body_type" $body_type "scalar") (serialize-qp "body_subtype" $body_subtype "scalar") (serialize-qp "vehicle_type" $vehicle_type "scalar") (serialize-qp "transmission" $transmission "scalar") (serialize-qp "drivetrain" $drivetrain "scalar") (serialize-qp "fuel_type" $fuel_type "scalar") (serialize-qp "engine" $engine "scalar") (serialize-qp "engine_size" $engine_size "scalar") (serialize-qp "engine_block" $engine_block "scalar") (serialize-qp "ignore_case" $ignore_case "scalar") (serialize-qp "facet_min_count" $facet_min_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/specs/car/auto-complete" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "field": $field, "input": $input, "year": $year, "make": $make, "model": $model, "trim": $trim, "body_type": $body_type, "body_subtype": $body_subtype, "vehicle_type": $vehicle_type, "transmission": $transmission, "drivetrain": $drivetrain, "fuel_type": $fuel_type, "engine": $engine, "engine_size": $engine_size, "engine_block": $engine_block, "ignore_case": $ignore_case, "facet_min_count": $facet_min_count} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# API for getting terms from taxonomy
#
# GET /specs/car/terms
# operationId: getTaxonomyTerms
export def "specs-car-terms get-taxonomy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --field: string # Comma separated list of fields to get terms for (format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --body-type: string # To filter listing on their body type
  --body-subtype: string # Body subtype to filter the listings on. Valid filter values are those that our Search facets API returns for unique body subtypes. You can pass in multiple body subtype values comma separated (format: string)
  --vehicle-type: string # To filter listing on their vehicle type
  --transmission: string # To filter listing on their transmission
  --drivetrain: string # To filter listing on their drivetrain
  --fuel-type: string # To filter listing on their fuel type
  --engine: string # To filter listing on their engine
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-block: string # Engine Block to match. Valid filter values are those that our Search facets API returns for unique Engine Block. You can pass in multiple Engine Block values comma separated
]: nothing -> record<terms: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "field" $field "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "make" $make "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "trim" $trim "scalar") (serialize-qp "body_type" $body_type "scalar") (serialize-qp "body_subtype" $body_subtype "scalar") (serialize-qp "vehicle_type" $vehicle_type "scalar") (serialize-qp "transmission" $transmission "scalar") (serialize-qp "drivetrain" $drivetrain "scalar") (serialize-qp "fuel_type" $fuel_type "scalar") (serialize-qp "engine" $engine "scalar") (serialize-qp "engine_size" $engine_size "scalar") (serialize-qp "engine_block" $engine_block "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/specs/car/terms" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "field": $field, "year": $year, "make": $make, "model": $model, "trim": $trim, "body_type": $body_type, "body_subtype": $body_subtype, "vehicle_type": $vehicle_type, "transmission": $transmission, "drivetrain": $drivetrain, "fuel_type": $fuel_type, "engine": $engine, "engine_size": $engine_size, "engine_block": $engine_block} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Price, Miles and Days on Market stats
#
# GET /stats/car
# operationId: getDailyStats
export def "stats-car get-daily" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --country: string@country-completer-4 # Country for which the stats are to be searched (format: string, default: us)
  --car-type: string@car-type-completer-1 # Inventory type for which stats are to be searched, default is used (format: string, default: used)
  --ymm: string # Year, Make, Model of the car, Separated by pipe e.g. ymm=2015|ford|f-150 (format: string)
  --ymmt: string # Year, Make, Model, Trim of the car, Separated by pipe e.g. ymmt=2015|ford|f-150|platinum (format: string)
  --taxonomy-vin: string # Taxonomy vin for referance to find stats of similar cars (format: string)
  --vin: string # VIN that will be transformed to taxonomy_vin (format: string)
  --state: string # State level stats (format: string)
  --city-state: string # City level stats, pipe seperated like city_state=jacksonville|FL (format: string)
]: nothing -> record<dom: record<interquartile_range: float, mean: float, median: float, population_standard_deviation: float, standard_deviation: float, trimmed_mean: float, variance: float>, miles_stats: record<interquartile_range: float, mean: float, median: float, population_standard_deviation: float, standard_deviation: float, trimmed_mean: float, variance: float>, price_stats: record<interquartile_range: float, mean: float, median: float, population_standard_deviation: float, standard_deviation: float, trimmed_mean: float, variance: float>, units_for_sale: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "car_type" $car_type "scalar") (serialize-qp "ymm" $ymm "scalar") (serialize-qp "ymmt" $ymmt "scalar") (serialize-qp "taxonomy_vin" $taxonomy_vin "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "city_state" $city_state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/car" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "country": $country, "car_type": $car_type, "ymm": $ymm, "ymmt": $ymmt, "taxonomy_vin": $taxonomy_vin, "vin": $vin, "state": $state, "city_state": $city_state} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
