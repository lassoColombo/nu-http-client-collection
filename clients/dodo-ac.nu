# Auto-generated client for Nookipedia v1.5.0
# Source: https://api.apis.guru/v2/specs/dodo.ac/1.5.0/openapi.json
# Auth: --token flag or $env.NOOKIPEDIA_TOKEN

const BASE_URL = "https://api.nookipedia.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NOOKIPEDIA_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

def base-url-completer [] { ["https://api.nookipedia.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def category-completer [] { ["Accessories" "Bags" "Bottoms" "Dress-up" "Headwear" "Shoes" "Socks" "Tops" "Umbrellas"] }
def labeltheme-completer [] { ["Comfy" "Everyday" "Fairy tale" "Formal" "Goth" "Outdoorsy" "Party" "Sporty" "Theatrical" "Vacation" "Work"] }
def category-completer-1 [] { ["Housewares" "Miscellaneous" "Wall-mounted"] }
def species-completer [] { ["alligator" "anteater" "bear" "bird" "bull" "cat" "chicken" "cow" "cub" "deer" "dog" "duck" "eagle" "elephant" "frog" "goat" "gorilla" "hamster" "hippo" "horse" "kangaroo" "koala" "lion" "monkey" "mouse" "octopus" "ostrich" "penguin" "pig" "rabbit" "rhino" "sheep" "squirrel" "tiger" "wolf"] }
def personality-completer [] { ["cranky" "jock" "lazy" "normal" "peppy" "sisterly" "smug" "snooty"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "nh-art list" } } | get name | first)
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

# All New Horizons artwork
#
# GET /nh/art
export def "nh-art list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hasfake: string # When set to `true`, only artwork that has a fake will be returned. When set to `false`, only artwork without fakes will be returned.
  --excludedetails: string # When set to `true`, only artwork names are returned. Instead of an array of objects with all details, the return will be an array of strings.
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL. Note that requesting specific image sizes for long lists may result in a very long response time.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> table<art_name: string, art_style: string, authenticity: string, author: string, availability: string, buy: int, description: string, fake_image_url: string, has_fake: bool, image_url: string, length: float, name: string, sell: int, url: string, width: float, year: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hasfake" $hasfake "scalar") (serialize-qp "excludedetails" $excludedetails "scalar") (serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nh/art" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"hasfake": $hasfake, "excludedetails": $excludedetails, "thumbsize": $thumbsize} | compact), body: null}
}

# Single New Horizons artwork
#
# GET /nh/art/{artwork}
export def "nh-art get" [
  artwork: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> record<art_name: string, art_style: string, authenticity: string, author: string, availability: string, buy: int, description: string, fake_image_url: string, has_fake: bool, image_url: string, length: float, name: string, sell: int, url: string, width: float, year: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($artwork | is-empty) { error make --unspanned { msg: "path parameter 'artwork' must be non-empty" } }
  let qp = [(serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({artwork: (encode-path-segment $artwork)} | format pattern "/nh/art/{artwork}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"thumbsize": $thumbsize} | compact), body: null}
}

# All New Horizons bugs
#
# GET /nh/bugs
export def "nh-bugs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --month: string # Retrive only the bug that are available in a specific month. Value may be the month's name (`jan`, `january`), the integer representing the month (`01`, `1`), or `current` for the current month. When `current` is specified, the return body will be an object with two arrays inside, one called `north` and the other `south` containing the bug available in each respective hemisphere. Note that the current month is calculated based off the API server's time, so it may be slightly off for you at the beginning or end of the month.
  --excludedetails: string # When set to `true`, only bug names are returned. Instead of an array of objects with all details, the return will be an array of strings. This is particularly useful when used with the `month` filter, for users who want just a list of bugs in a given month but not all their respective details.
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL. Note that requesting specific image sizes for long lists may result in a very long response time.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> table<catchphrases: list<string>, image_url: string, location: string, name: string, north: record<availability_array: list, months: string, months_array: list, times_by_month: record>, number: int, rarity: string, render_url: string, sell_flick: int, sell_nook: int, south: record<availability_array: list, months: string, months_array: list, times_by_month: record>, tank_length: float, tank_width: float, total_catch: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "month" $month "scalar") (serialize-qp "excludedetails" $excludedetails "scalar") (serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nh/bugs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"month": $month, "excludedetails": $excludedetails, "thumbsize": $thumbsize} | compact), body: null}
}

# Single New Horizons bug
#
# GET /nh/bugs/{bug}
export def "nh-bugs get" [
  bug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> record<catchphrases: list<string>, image_url: string, location: string, name: string, north: record<availability_array: list<record>, months: string, months_array: list<int>, times_by_month: record<1: string, 2: string, 3: string, 4: string, 5: string, 6: string, 7: string, 8: string, 9: string, 10: string, 11: string, 12: string>>, number: int, rarity: string, render_url: string, sell_flick: int, sell_nook: int, south: record<availability_array: list<record>, months: string, months_array: list<int>, times_by_month: record<1: string, 2: string, 3: string, 4: string, 5: string, 6: string, 7: string, 8: string, 9: string, 10: string, 11: string, 12: string>>, tank_length: float, tank_width: float, total_catch: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bug | is-empty) { error make --unspanned { msg: "path parameter 'bug' must be non-empty" } }
  let qp = [(serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bug: (encode-path-segment $bug)} | format pattern "/nh/bugs/{bug}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"thumbsize": $thumbsize} | compact), body: null}
}

# All New Horizons clothing
#
# GET /nh/clothing
export def "nh-clothing list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # Specify the category of clothing to return.
  --color: list<string> # Return clothing that matches the provided colors (may specify one or two colors). Colors are used for gifting villagers.
  --style: list<string> # Return clothing that matches the provided styles (may specify one or two styles). Styles are used for gifting villagers.
  --labeltheme: string@labeltheme-completer # Return clothing that have the specified Label theme. This is used for completing the requested outfit theme for [Label](https://nookipedia.com/wiki/Label) when she visits the player's island.
  --excludedetails: string # When set to `true`, only clothing names are returned. Instead of an array of objects with all details, the return will be an array of strings.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> table<availability: list<record>, buy: list<record>, category: string, label_themes: list<string>, name: string, notes: string, seasonality: string, sell: int, styles: list<string>, unlocked: bool, url: string, variation_total: int, variations: list<record>, version_added: string, vill_equip: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category" $category "scalar") (serialize-qp "color" $color "multi") (serialize-qp "style" $style "multi") (serialize-qp "labeltheme" $labeltheme "scalar") (serialize-qp "excludedetails" $excludedetails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nh/clothing" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"category": $category, "color": $color, "style": $style, "labeltheme": $labeltheme, "excludedetails": $excludedetails} | compact), body: null}
}

# Single New Horizons clothing
#
# GET /nh/clothing/{clothing}
export def "nh-clothing get" [
  clothing: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> record<availability: table<from: string, note: string>, buy: table<currency: string, price: int>, category: string, label_themes: list<string>, name: string, notes: string, seasonality: string, sell: int, styles: list<string>, unlocked: bool, url: string, variation_total: int, variations: table<colors: list, image_url: string, variation: string>, version_added: string, vill_equip: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($clothing | is-empty) { error make --unspanned { msg: "path parameter 'clothing' must be non-empty" } }
  let qp = [(serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({clothing: (encode-path-segment $clothing)} | format pattern "/nh/clothing/{clothing}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"thumbsize": $thumbsize} | compact), body: null}
}

# All New Horizons events
#
# GET /nh/events
export def "nh-events get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Specify a specific date (in the current or next year) to retrieve events for. Accepts many date formats, such as `YYYY-MM-DD` or `Month Day, Year`, as well as `today` to retrieve the current day's events (UTC time).
  --year: string # Specify the year to retrieve events for. Must be the current or next year.
  --month: string # Specify the month to retrieve events for (accepts multiple formats, such as `Oct`, `October`, or `10`). Most likely want to use alongside `year`, otherwise events in both the current and next year are returned.
  --day: int # Specify the day of the month to retrieve events for.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> table<date: string, event: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "month" $month "scalar") (serialize-qp "day" $day "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nh/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date": $date, "year": $year, "month": $month, "day": $day} | compact), body: null}
}

# All New Horizons fish
#
# GET /nh/fish
export def "nh-fish list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --month: string # Retrive only the fish that are available in a specific month. Value may be the month's name (`jan`, `january`), the integer representing the month (`01`, `1`), or `current` for the current month. When `current` is specified, the return body will be an object with two arrays inside, one called `north` and the other `south` containing the fish available in each respective hemisphere. Note that the current month is calculated based off the API server's time, so it may be slightly off for you at the beginning or end of the month.
  --excludedetails: string # When set to `true`, only fish names are returned. Instead of an array of objects with all details, the return will be an array of strings. This is particularly useful when used with the `month` filter, for users who want just a list of fish in a given month but not all their respective details.
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL. Note that requesting specific image sizes for long lists may result in a very long response time.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> table<catchphrases: list<string>, image_url: string, location: string, name: string, north: record<availability_array: list, months: string, months_array: list, times_by_month: record>, number: int, rarity: string, render_url: string, sell_cj: int, sell_nook: int, shadow_size: string, south: record<availability_array: list, months: string, months_array: list, times_by_month: record>, tank_length: float, tank_width: float, total_catch: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "month" $month "scalar") (serialize-qp "excludedetails" $excludedetails "scalar") (serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nh/fish" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"month": $month, "excludedetails": $excludedetails, "thumbsize": $thumbsize} | compact), body: null}
}

# Single New Horizons fish
#
# GET /nh/fish/{fish}
export def "nh-fish get" [
  fish: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> record<catchphrases: list<string>, image_url: string, location: string, name: string, north: record<availability_array: list<record>, months: string, months_array: list<int>, times_by_month: record<1: string, 2: string, 3: string, 4: string, 5: string, 6: string, 7: string, 8: string, 9: string, 10: string, 11: string, 12: string>>, number: int, rarity: string, render_url: string, sell_cj: int, sell_nook: int, shadow_size: string, south: record<availability_array: list<record>, months: string, months_array: list<int>, times_by_month: record<1: string, 4: string, 5: string, 6: string, 7: string, 8: string, 9: string, 10: string, 11: string, 12: string, 2_: string, 3_: string>>, tank_length: float, tank_width: float, total_catch: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($fish | is-empty) { error make --unspanned { msg: "path parameter 'fish' must be non-empty" } }
  let qp = [(serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({fish: (encode-path-segment $fish)} | format pattern "/nh/fish/{fish}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"thumbsize": $thumbsize} | compact), body: null}
}

# All New Horizons fossil groups or individual fossil
#
# GET /nh/fossils/all
export def "nh-fossils-all list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> table<description: string, fossils: list<record>, name: string, room: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nh/fossils/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"thumbsize": $thumbsize} | compact), body: null}
}

# Single New Horizons fossil group with individual fossils
#
# GET /nh/fossils/all/{fossil}
export def "nh-fossils-all get" [
  fossil: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> record<description: string, fossils: table<colors: list, fossil_group: string, hha_base: int, image_url: string, interactable: bool, length: int, name: string, sell: int, url: string, width: int>, matched: record<name: string, type: string>, name: string, room: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($fossil | is-empty) { error make --unspanned { msg: "path parameter 'fossil' must be non-empty" } }
  let qp = [(serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({fossil: (encode-path-segment $fossil)} | format pattern "/nh/fossils/all/{fossil}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"thumbsize": $thumbsize} | compact), body: null}
}

# All New Horizons fossil groups
#
# GET /nh/fossils/groups
export def "nh-fossils-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> table<description: string, name: string, room: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nh/fossils/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"thumbsize": $thumbsize} | compact), body: null}
}

# Single New Horizons fossil group
#
# GET /nh/fossils/groups/{fossil_group}
export def "nh-fossils-groups get" [
  fossil_group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> record<description: string, name: string, room: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($fossil_group | is-empty) { error make --unspanned { msg: "path parameter 'fossil_group' must be non-empty" } }
  let qp = [(serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({fossil_group: (encode-path-segment $fossil_group)} | format pattern "/nh/fossils/groups/{fossil_group}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"thumbsize": $thumbsize} | compact), body: null}
}

# All New Horizons fossils
#
# GET /nh/fossils/individuals
export def "nh-fossils-individuals list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> table<colors: list<string>, fossil_group: string, hha_base: int, image_url: string, interactable: bool, length: int, name: string, sell: int, url: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nh/fossils/individuals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"thumbsize": $thumbsize} | compact), body: null}
}

# Single New Horizons fossil
#
# GET /nh/fossils/individuals/{fossil}
export def "nh-fossils-individuals get" [
  fossil: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> record<colors: list<string>, fossil_group: string, hha_base: int, image_url: string, interactable: bool, length: int, name: string, sell: int, url: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($fossil | is-empty) { error make --unspanned { msg: "path parameter 'fossil' must be non-empty" } }
  let qp = [(serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({fossil: (encode-path-segment $fossil)} | format pattern "/nh/fossils/individuals/{fossil}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"thumbsize": $thumbsize} | compact), body: null}
}

# All New Horizons furniture
#
# GET /nh/furniture
export def "nh-furniture list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer-1 # Specify the category of furniture to return (houswares, miscellaneous, or wall-mounted).
  --color: list<string> # Return furniture that matches the provided colors (may specify one or two colors).
  --excludedetails: string # When set to `true`, only furniture names are returned. Instead of an array of objects with all details, the return will be an array of strings.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> table<availability: list<record>, buy: list<record>, category: string, custom_body_part: string, custom_kit_type: string, custom_kits: int, custom_pattern_part: string, customizable: bool, door_decor: bool, functions: list<string>, grid_length: float, grid_width: float, height: float, hha_base: int, hha_category: string, item_series: string, item_set: string, lucky: bool, lucky_season: string, name: string, notes: string, pattern_total: int, sell: int, tag: string, themes: list<string>, unlocked: bool, url: string, variation_total: int, variations: list<record>, version_added: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category" $category "scalar") (serialize-qp "color" $color "multi") (serialize-qp "excludedetails" $excludedetails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nh/furniture" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"category": $category, "color": $color, "excludedetails": $excludedetails} | compact), body: null}
}

# Single New Horizons furniture
#
# GET /nh/furniture/{furniture}
export def "nh-furniture get" [
  furniture: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> record<availability: table<from: string, note: string>, buy: table<currency: string, price: int>, category: string, custom_body_part: string, custom_kit_type: string, custom_kits: int, custom_pattern_part: string, customizable: bool, door_decor: bool, functions: list<string>, grid_length: float, grid_width: float, height: float, hha_base: int, hha_category: string, item_series: string, item_set: string, lucky: bool, lucky_season: string, name: string, notes: string, pattern_total: int, sell: int, tag: string, themes: list<string>, unlocked: bool, url: string, variation_total: int, variations: table<colors: list, image_url: string, pattern: string, variation: string>, version_added: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($furniture | is-empty) { error make --unspanned { msg: "path parameter 'furniture' must be non-empty" } }
  let qp = [(serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({furniture: (encode-path-segment $furniture)} | format pattern "/nh/furniture/{furniture}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"thumbsize": $thumbsize} | compact), body: null}
}

# All New Horizons interior items
#
# GET /nh/interior
export def "nh-interior list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --color: list<string> # Return furniture that matches the provided colors (may specify one or two colors).
  --excludedetails: string # When set to `true`, only interior item names are returned. Instead of an array of objects with all details, the return will be an array of strings.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> table<availability: list<record>, buy: list<record>, category: string, colors: string, grid_length: float, grid_width: float, hha_base: int, hha_category: string, image_url: string, item_series: string, item_set: string, name: string, notes: string, sell: int, tag: string, themes: list<string>, unlocked: bool, url: string, version_added: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "color" $color "multi") (serialize-qp "excludedetails" $excludedetails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nh/interior" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"color": $color, "excludedetails": $excludedetails} | compact), body: null}
}

# Single New Horizons interior item
#
# GET /nh/interior/{item}
export def "nh-interior get" [
  item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --color: list<string> # Return furniture that matches the provided colors (may specify one or two colors).
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> record<availability: table<from: string, note: string>, buy: table<currency: string, price: int>, category: string, colors: string, grid_length: float, grid_width: float, hha_base: int, hha_category: string, image_url: string, item_series: string, item_set: string, name: string, notes: string, sell: int, tag: string, themes: list<string>, unlocked: bool, url: string, version_added: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($item | is-empty) { error make --unspanned { msg: "path parameter 'item' must be non-empty" } }
  let qp = [(serialize-qp "color" $color "multi") (serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({item: (encode-path-segment $item)} | format pattern "/nh/interior/{item}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"color": $color, "thumbsize": $thumbsize} | compact), body: null}
}

# Miscellaneous New Horizons items
#
# GET /nh/items
export def "nh-items list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --excludedetails: string # When set to `true`, only item names are returned. Instead of an array of objects with all details, the return will be an array of strings.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> table<availability: list<record>, buy: list<record>, edible: bool, hha_base: int, image_url: string, is_fence: bool, material_name_sort: int, material_seasonality: string, material_seasonality_sort: int, material_sort: int, material_type: string, name: string, notes: string, plant_type: string, sell: int, stack: int, unlocked: bool, url: string, version_added: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "excludedetails" $excludedetails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nh/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"excludedetails": $excludedetails} | compact), body: null}
}

# Single New Horizons miscellaneous item
#
# GET /nh/items/{item}
export def "nh-items get" [
  item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> record<availability: table<from: string, note: string>, buy: table<currency: string, price: int>, edible: bool, hha_base: int, image_url: string, is_fence: bool, material_name_sort: int, material_seasonality: string, material_seasonality_sort: int, material_sort: int, material_type: string, name: string, notes: string, plant_type: string, sell: int, stack: int, unlocked: bool, url: string, version_added: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($item | is-empty) { error make --unspanned { msg: "path parameter 'item' must be non-empty" } }
  let qp = [(serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({item: (encode-path-segment $item)} | format pattern "/nh/items/{item}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"thumbsize": $thumbsize} | compact), body: null}
}

# All New Horizons photos and posters
#
# GET /nh/photos
export def "nh-photos list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --excludedetails: string # When set to `true`, only item names are returned. Instead of an array of objects with all details, the return will be an array of strings.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> table<availability: list<record>, buy: list<record>, category: string, custom_body_part: string, custom_kits: int, customizable: bool, grid_length: float, grid_width: float, interactable: bool, name: string, sell: int, unlocked: bool, url: string, variations: list<record>, version_added: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "excludedetails" $excludedetails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nh/photos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"excludedetails": $excludedetails} | compact), body: null}
}

# Single New Horizons photo or poster
#
# GET /nh/photos/{item}
export def "nh-photos get" [
  item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> record<availability: table<from: string, note: string>, buy: table<currency: string, price: int>, category: string, custom_body_part: string, custom_kits: int, customizable: bool, grid_length: float, grid_width: float, interactable: bool, name: string, sell: int, unlocked: bool, url: string, variations: table<colors: list, image_url: string, variation: string>, version_added: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($item | is-empty) { error make --unspanned { msg: "path parameter 'item' must be non-empty" } }
  let qp = [(serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({item: (encode-path-segment $item)} | format pattern "/nh/photos/{item}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"thumbsize": $thumbsize} | compact), body: null}
}

# All New Horizons recipes
#
# GET /nh/recipes
export def "nh-recipes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --material: string # Specify a material to only get recipes that use that material. You can specify `material` up to six times (no recipe uses more than six materials).
  --excludedetails: string # When set to `true`, only recipe names are returned. Instead of an array of objects with all details, the return will be an array of strings.
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL. Note that requesting specific image sizes for long lists may result in a very long response time.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> table<availability: list<record>, buy: list<record>, image_url: string, materials: list<record>, name: string, recipes_to_unlock: int, sell: int, serial_id: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "material" $material "scalar") (serialize-qp "excludedetails" $excludedetails "scalar") (serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nh/recipes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"material": $material, "excludedetails": $excludedetails, "thumbsize": $thumbsize} | compact), body: null}
}

# Single New Horizons recipe
#
# GET /nh/recipes/{item}
export def "nh-recipes get" [
  item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> record<availability: table<from: string, note: string>, buy: table<currency: string, price: int>, image_url: string, materials: table<count: int, name: string>, name: string, recipes_to_unlock: int, sell: int, serial_id: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($item | is-empty) { error make --unspanned { msg: "path parameter 'item' must be non-empty" } }
  let qp = [(serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({item: (encode-path-segment $item)} | format pattern "/nh/recipes/{item}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"thumbsize": $thumbsize} | compact), body: null}
}

# All New Horizons sea creatures
#
# GET /nh/sea
export def "nh-sea list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --month: string # Retrive only the sea creature that are available in a specific month. Value may be the month's name (`jan`, `january`), the integer representing the month (`01`, `1`), or `current` for the current month. When `current` is specified, the return body will be an object with two arrays inside, one called `north` and the other `south` containing the sea creature available in each respective hemisphere. Note that the current month is calculated based off the API server's time, so it may be slightly off for you at the beginning or end of the month.
  --excludedetails: string # When set to `true`, only sea creature names are returned. Instead of an array of objects with all details, the return will be an array of strings. This is particularly useful when used with the `month` filter, for users who want just a list of sea creatures in a given month but not all their respective details.
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL. Note that requesting specific image sizes for long lists may result in a very long response time.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> table<catchphrases: list<string>, image_url: string, name: string, north: record<availability_array: list, months: string, months_array: list, times_by_month: record>, number: int, rarity: string, render_url: string, sell_nook: int, shadow_movement: string, shadow_size: string, south: record<availability_array: list, months: string, months_array: list, times_by_month: record>, tank_length: float, tank_width: float, total_catch: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "month" $month "scalar") (serialize-qp "excludedetails" $excludedetails "scalar") (serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nh/sea" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"month": $month, "excludedetails": $excludedetails, "thumbsize": $thumbsize} | compact), body: null}
}

# Single New Horizons sea creature
#
# GET /nh/sea/{sea_creature}
export def "nh-sea get" [
  sea_creature: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> record<catchphrases: list<string>, image_url: string, name: string, north: record<availability_array: list<record>, months: string, months_array: list<int>, times_by_month: record<1: string, 2: string, 3: string, 4: string, 5: string, 6: string, 7: string, 8: string, 9: string, 10: string, 11: string, 12: string>>, number: int, rarity: string, render_url: string, sell_nook: int, shadow_movement: string, shadow_size: string, south: record<availability_array: list<record>, months: string, months_array: list<int>, times_by_month: record<1: string, 2: string, 3: string, 4: string, 5: string, 6: string, 7: string, 8: string, 9: string, 10: string, 11: string, 12: string>>, tank_length: float, tank_width: float, total_catch: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sea_creature | is-empty) { error make --unspanned { msg: "path parameter 'sea_creature' must be non-empty" } }
  let qp = [(serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sea_creature: (encode-path-segment $sea_creature)} | format pattern "/nh/sea/{sea_creature}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"thumbsize": $thumbsize} | compact), body: null}
}

# All New Horizons tools
#
# GET /nh/tools
export def "nh-tools list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --excludedetails: string # When set to `true`, only tool names are returned. Instead of an array of objects with all details, the return will be an array of strings.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> table<availability: list<record>, buy: list<record>, custom_body_part: string, custom_kits: int, customizable: bool, hha_base: int, name: string, notes: string, sell: int, unlocked: bool, url: string, uses: int, variations: list<record>, version_added: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "excludedetails" $excludedetails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nh/tools" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"excludedetails": $excludedetails} | compact), body: null}
}

# Single New Horizons tool
#
# GET /nh/tools/{tool}
export def "nh-tools get" [
  tool: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> record<availability: table<from: string, note: string>, buy: table<currency: string, price: int>, custom_body_part: string, custom_kits: int, customizable: bool, hha_base: int, name: string, notes: string, sell: int, unlocked: bool, url: string, uses: int, variations: table<image_url: string, variation: string>, version_added: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tool | is-empty) { error make --unspanned { msg: "path parameter 'tool' must be non-empty" } }
  let qp = [(serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tool: (encode-path-segment $tool)} | format pattern "/nh/tools/{tool}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"thumbsize": $thumbsize} | compact), body: null}
}

# Villagers
#
# GET /villagers
export def "villagers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Villager name. For most names you will get back an array with one object, but note that names are not a unique identifier across the series, as there are 3 names that are shared by multiple villagers (Lulu, Petunia, Carmen). For those 3 names you will get back an array with 2 objects. How you disambiguate between these villagers is up to you.
  --species: string@species-completer # Retrieve villagers of a certain species.
  --personality: string@personality-completer # Retrieve villagers with a certain personality. For 'sisterly', note that the community often also calls it 'uchi' or 'big sister'.
  --game: list<string> # Retrieve villagers that appear in all listed games. For example, if you want only villagers that appear in both *New Horizons* and *Pocket Camp*, you would send in `?game=nh&game=pc`.
  --birthmonth: string # Retrieve villagers born in a specific month. Value may be the month's name (`jan`, `january`) or the integer representing the month (`01`, `1`).
  --birthday: string # Use with `birthmonth` to get villager(s) born on a specific day. Value should be an int, 1 through 31.
  --nhdetails: string # When set to `true`, an `nh_details` object will be included that contains *New Horizons* details about the villager. If the villager does not appear in *New Horizons*, the returned `nh_details` field will be set to null.
  --excludedetails: string # When set to `true`, only villager names are returned. Instead of an array of objects with all details, the return will be an array of strings.
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL. Note that requesting specific image sizes for long lists may result in a very long response time.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API.
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes.
]: nothing -> table<alt_name: string, appearances: list<string>, birthday_day: string, birthday_month: string, clothing: string, debut: string, gender: string, id: string, image_url: string, islander: bool, name: string, nh_details: record<catchphrase: string, clothing: string, clothing_variation: string, fav_colors: list, fav_styles: list, hobby: string, house_exterior_url: string, house_flooring: string, house_interior_url: string, house_music: string, house_music_note: string, house_wallpaper: string, icon_url: string, image_url: string, photo_url: string, quote: string, sub_personality: string>, personality: string, phrase: string, prev_phrases: list<string>, quote: string, sign: string, species: string, text_color: string, title_color: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "species" $species "scalar") (serialize-qp "personality" $personality "scalar") (serialize-qp "game" $game "multi") (serialize-qp "birthmonth" $birthmonth "scalar") (serialize-qp "birthday" $birthday "scalar") (serialize-qp "nhdetails" $nhdetails "scalar") (serialize-qp "excludedetails" $excludedetails "scalar") (serialize-qp "thumbsize" $thumbsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/villagers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-KEY": $x_api_key, "Accept-Version": $accept_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "species": $species, "personality": $personality, "game": $game, "birthmonth": $birthmonth, "birthday": $birthday, "nhdetails": $nhdetails, "excludedetails": $excludedetails, "thumbsize": $thumbsize} | compact), body: null}
}
