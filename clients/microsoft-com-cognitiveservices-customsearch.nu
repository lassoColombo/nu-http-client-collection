# Auto-generated client for Custom Search Client v1.0
# Source: https://api.apis.guru/v2/specs/microsoft.com/cognitiveservices-CustomSearch/1.0/swagger.json
# Auth: --token flag or $env.CUSTOM_SEARCH_CLIENT_TOKEN

const BASE_URL = "{Endpoint}/bingcustomsearch/v7.0"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CUSTOM_SEARCH_CLIENT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "ocp-apim-subscription-key" => { {scheme: $scheme, headers: {Ocp-Apim-Subscription-Key: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["{Endpoint}/bingcustomsearch/v7.0"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key"] }

# Completers for enum parameters
def safe-search-completer [] { ["Moderate" "Off" "Strict"] }
def text-format-completer [] { ["Html" "Raw"] }
def x-bing-apis-sdk-completer [] { ["true"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "search list-custom-instance" } } | get name | first)
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

# The Custom Search API lets you send a search query to Bing and get back web pages found in your custom view of the web.
#
# GET /search
# operationId: CustomInstance_Search
export def "search list-custom-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-config: string # The identifier for the custom search configuration
  --cc: string # A 2-character country code of the country where the results come from. This API supports only the United States market. If you specify this query parameter, it must be set to us. If you set this parameter, you must also specify the Accept-Language header. Bing uses the first supported language it finds from the languages list, and combine that language with the country code that you specify to determine the market to return results for. If the languages list does not include a supported language, Bing finds the closest language and market that supports the request, or it may use an aggregated or default market for the results instead of a specified one. You should use this query parameter and the Accept-Language query parameter only if you specify multiple languages; otherwise, you should use the mkt and setLang query parameters. This parameter and the mkt query parameter are mutually exclusive—do not specify both.
  --count: int # The number of search results to return in the response. The default is 10 and the maximum value is 50. The actual number delivered may be less than requested.Use this parameter along with the offset parameter to page results.For example, if your user interface displays 10 search results per page, set count to 10 and offset to 0 to get the first page of results. For each subsequent page, increment offset by 10 (for example, 0, 10, 20). It is possible for multiple pages to include some overlap in results. (format: int32)
  --mkt: string # The market where the results come from. Typically, mkt is the country where the user is making the request from. However, it could be a different country if the user is not located in a country where Bing delivers results. The market must be in the form -. For example, en-US. The string is case insensitive. If known, you are encouraged to always specify the market. Specifying the market helps Bing route the request and return an appropriate and optimal response. If you specify a market that is not listed in Market Codes, Bing uses a best fit market code based on an internal mapping that is subject to change. This parameter and the cc query parameter are mutually exclusive—do not specify both. (default: en-us)
  --offset: int # The zero-based offset that indicates the number of search results to skip before returning results. The default is 0. The offset should be less than (totalEstimatedMatches - count). Use this parameter along with the count parameter to page results. For example, if your user interface displays 10 search results per page, set count to 10 and offset to 0 to get the first page of results. For each subsequent page, increment offset by 10 (for example, 0, 10, 20). it is possible for multiple pages to include some overlap in results. (format: int32)
  --q: string # The user's search query term. The term may not be empty. The term may contain Bing Advanced Operators. For example, to limit results to a specific domain, use the site: operator.
  --safe-search: string@safe-search-completer # A filter used to filter adult content. Off: Return webpages with adult text, images, or videos. Moderate: Return webpages with adult text, but not adult images or videos. Strict: Do not return webpages with adult text, images, or videos. The default is Moderate. If the request comes from a market that Bing's adult policy requires that safeSearch is set to Strict, Bing ignores the safeSearch value and uses Strict. If you use the site: query operator, there is the chance that the response may contain adult content regardless of what the safeSearch query parameter is set to. Use site: only if you are aware of the content on the site and your scenario supports the possibility of adult content.
  --set-lang: string # The language to use for user interface strings. Specify the language using the ISO 639-1 2-letter language code. For example, the language code for English is EN. The default is EN (English). Although optional, you should always specify the language. Typically, you set setLang to the same language specified by mkt unless the user wants the user interface strings displayed in a different language. This parameter and the Accept-Language header are mutually exclusive; do not specify both. A user interface string is a string that's used as a label in a user interface. There are few user interface strings in the JSON response objects. Also, any links to Bing.com properties in the response objects apply the specified language.
  --text-decorations: oneof<nothing, bool> # A Boolean value that determines whether display strings should contain decoration markers such as hit highlighting characters. If true, the strings may include markers. The default is false. To specify whether to use Unicode characters or HTML tags as the markers, see the textFormat query parameter.
  --text-format: string@text-format-completer # The type of markers to use for text decorations (see the textDecorations query parameter). Possible values are Raw—Use Unicode characters to mark content that needs special formatting. The Unicode characters are in the range E000 through E019. For example, Bing uses E000 and E001 to mark the beginning and end of query terms for hit highlighting. HTML—Use HTML tags to mark content that needs special formatting. For example, use tags to highlight query terms in display strings. The default is Raw. For display strings that contain escapable HTML characters such as <, >, and &, if textFormat is set to HTML, Bing escapes the characters as appropriate (for example, < is escaped to <).
  --x-bing-apis-sdk: string@x-bing-apis-sdk-completer # Activate swagger compliance
  --hdr-accept: string # The default media type is application/json. To specify that the response use [JSON-LD](http://json-ld.org/), set the Accept header to application/ld+json.
  --accept-language: string # A comma-delimited list of one or more languages to use for user interface strings. The list is in decreasing order of preference. For additional information, including expected format, see [RFC2616](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html). This header and the setLang query parameter are mutually exclusive; do not specify both. If you set this header, you must also specify the cc query parameter. Bing will use the first supported language it finds from the list, and combine that language with the cc parameter value to determine the market to return results for. If the list does not include a supported language, Bing will find the closest language and market that supports the request, and may use an aggregated or default market for the results instead of a specified one. You should use this header and the cc query parameter only if you specify multiple languages; otherwise, you should use the mkt and setLang query parameters. A user interface string is a string that's used as a label in a user interface. There are very few user interface strings in the JSON response objects. Any links in the response objects to Bing.com properties will apply the specified language.
  --user-agent: string # The user agent originating the request. Bing uses the user agent to provide mobile users with an optimized experience. Although optional, you are strongly encouraged to always specify this header. The user-agent should be the same string that any commonly used browser would send. For information about user agents, see [RFC 2616](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html).
  --x-ms-edge-client-id: string # Bing uses this header to provide users with consistent behavior across Bing API calls. Bing often flights new features and improvements, and it uses the client ID as a key for assigning traffic on different flights. If you do not use the same client ID for a user across multiple requests, then Bing may assign the user to multiple conflicting flights. Being assigned to multiple conflicting flights can lead to an inconsistent user experience. For example, if the second request has a different flight assignment than the first, the experience may be unexpected. Also, Bing can use the client ID to tailor web results to that client ID’s search history, providing a richer experience for the user. Bing also uses this header to help improve result rankings by analyzing the activity generated by a client ID. The relevance improvements help with better quality of results delivered by Bing APIs and in turn enables higher click-through rates for the API consumer. IMPORTANT: Although optional, you should consider this header required. Persisting the client ID across multiple requests for the same end user and device combination enables 1) the API consumer to receive a consistent user experience, and 2) higher click-through rates via better quality of results from the Bing APIs. Each user that uses your application on the device must have a unique, Bing generated client ID. If you do not include this header in the request, Bing generates an ID and returns it in the X-MSEdge-ClientID response header. The only time that you should NOT include this header in a request is the first time the user uses your app on that device. Use the client ID for each Bing API request that your app makes for this user on the device. Persist the client ID. To persist the ID in a browser app, use a persistent HTTP cookie to ensure the ID is used across all sessions. Do not use a session cookie. For other apps such as mobile apps, use the device's persistent storage to persist the ID. The next time the user uses your app on that device, get the client ID that you persisted. Bing responses may or may not include this header. If the response includes this header, capture the client ID and use it for all subsequent Bing requests for the user on that device. If you include the X-MSEdge-ClientID, you must not include cookies in the request.
  --x-ms-edge-client-ip: string # The IPv4 or IPv6 address of the client device. The IP address is used to discover the user's location. Bing uses the location information to determine safe search behavior. Although optional, you are encouraged to always specify this header and the X-Search-Location header. Do not obfuscate the address (for example, by changing the last octet to 0). Obfuscating the address results in the location not being anywhere near the device's actual location, which may result in Bing serving erroneous results.
  --x-search-location: string # A semicolon-delimited list of key/value pairs that describe the client's geographical location. Bing uses the location information to determine safe search behavior and to return relevant local content. Specify the key/value pair as :. The following are the keys that you use to specify the user's location. lat (required): The latitude of the client's location, in degrees. The latitude must be greater than or equal to -90.0 and less than or equal to +90.0. Negative values indicate southern latitudes and positive values indicate northern latitudes. long (required): The longitude of the client's location, in degrees. The longitude must be greater than or equal to -180.0 and less than or equal to +180.0. Negative values indicate western longitudes and positive values indicate eastern longitudes. re (required): The radius, in meters, which specifies the horizontal accuracy of the coordinates. Pass the value returned by the device's location service. Typical values might be 22m for GPS/Wi-Fi, 380m for cell tower triangulation, and 18,000m for reverse IP lookup. ts (optional): The UTC UNIX timestamp of when the client was at the location. (The UNIX timestamp is the number of seconds since January 1, 1970.) head (optional): The client's relative heading or direction of travel. Specify the direction of travel as degrees from 0 through 360, counting clockwise relative to true north. Specify this key only if the sp key is nonzero. sp (optional): The horizontal velocity (speed), in meters per second, that the client device is traveling. alt (optional): The altitude of the client device, in meters. are (optional): The radius, in meters, that specifies the vertical accuracy of the coordinates. Specify this key only if you specify the alt key. Although many of the keys are optional, the more information that you provide, the more accurate the location results are. Although optional, you are encouraged to always specify the user's geographical location. Providing the location is especially important if the client's IP address does not accurately reflect the user's physical location (for example, if the client uses VPN). For optimal results, you should include this header and the X-MSEdge-ClientIP header, but at a minimum, you should include this header.
]: nothing -> record<queryContext: record<adultIntent: bool, alterationOverrideQuery: string, alteredQuery: string, originalQuery: string>, webPages: record<someResultsRemoved: bool, value: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customConfig" $custom_config "scalar") (serialize-qp "cc" $cc "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "mkt" $mkt "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "safeSearch" $safe_search "scalar") (serialize-qp "setLang" $set_lang "scalar") (serialize-qp "textDecorations" $text_decorations "scalar") (serialize-qp "textFormat" $text_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-BingApis-SDK": $x_bing_apis_sdk, "Accept": $hdr_accept, "Accept-Language": $accept_language, "User-Agent": $user_agent, "X-MSEdge-ClientID": $x_ms_edge_client_id, "X-MSEdge-ClientIP": $x_ms_edge_client_ip, "X-Search-Location": $x_search_location} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"customConfig": $custom_config, "cc": $cc, "count": $count, "mkt": $mkt, "offset": $offset, "q": $q, "safeSearch": $safe_search, "setLang": $set_lang, "textDecorations": $text_decorations, "textFormat": $text_format} | compact), body: null}
}
