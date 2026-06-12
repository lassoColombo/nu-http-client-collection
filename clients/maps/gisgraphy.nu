# Auto-generated client for Gisgraphy webservices v4.0.0
# Source: https://api.apis.guru/v2/specs/gisgraphy.com/4.0.0/swagger.json
# Auth: --token flag or $env.GISGRAPHY_WEBSERVICES_TOKEN

const BASE_URL = "http://free.gisgraphy.com"
const DEFAULT_AUTH = "query-api_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GISGRAPHY_WEBSERVICES_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-api_key" => { {headers: {}, query: $"api_key=($token_val)"} }
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

def base-url-completer [] { ["http://free.gisgraphy.com" "https://free.gisgraphy.com"] }
def auth-scheme-completer [] { ["query-api_key"] }

# Completers for enum parameters
def format-completer [] { ["JSON" "PHP" "PYTHON" "RUBY" "XML" "YAML"] }
def accept-completer [] { ["application/json" "application/php" "application/python" "application/ruby" "application/xml" "application/yaml"] }
def style-completer [] { ["FULL" "LONG" "MEDIUM" "SHORT"] }
def format-completer-1 [] { ["ATOM" "GEORSS" "JSON" "PHP" "PYTHON" "RUBY" "XML" "YAML"] }
def accept-completer-1 [] { ["application/json" "application/php" "application/python" "application/ruby" "application/xml" "application/yaml" "text/plain"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "addressparser-parse addressparsing" } } | get name | first)
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

# split a raw address into several parts
#
# GET /addressparser/parse
# operationId: addressparsing
export def "addressparser-parse addressparsing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --address: string # A postal address.
  --country: string # The ISO 3166 Alpha 2 code of the country.
  --format: string@format-completer # The output format. (default: XML)
  --callback: string # The callback method name (optional), use to wrap the content into a (alphanumeric) Javascript method. Works only for script output formats (JSON, PHP, Ruby, Python)
  --indent: oneof<nothing, bool> # indents the results.Default to false. Possible values are true or false (or on when used with the rest service. If you use a checkbox in a web form, to indent the results, the value will be 'on' or 'off', so for a simple use : the value of indent can be 'true' or 'on' (default: false)
  --standardize: oneof<nothing, bool> # Whether the address should be standardized after parsing, the value will be 'on' or 'off', so for a simple use : the value of indent can be 'true' or 'on' (default: false)
  --geocode: oneof<nothing, bool> # UNUSED YET. Whether the address should be geocoded after parsing, the value will be 'on' or 'off', so for a simple use : the value of indent can be 'true' or 'on' (default: false)
]: nothing -> record<QTime: int, message: string, numFound: int, parsedAddress: record<POBox: string, POBoxAgency: string, POBoxInfo: string, adm1NameAlternatesLocalized: record, adm2NameAlternatesLocalized: record, block: string, city: string, citySubdivision: string, civicNumberSuffix: string, confidence: string, country: string, countryNameAlternatesLocalized: record, countrycode: string, dependentLocality: string, distance: float, district: string, extraInfo: string, floor: string, geocodinglevel: string, houseNumber: string, houseNumberInfo: string, id: int, lat: float, lng: float, lote: string, name: string, nameAlternatesLocalized: record, postDirection: string, postDirectionIntersection: string, postTown: string, preDirection: string, preDirectionIntersection: string, prefecture: string, quadrant: string, quarter: string, recipientName: string, sector: string, state: string, streetName: string, streetNameIntersection: string, streetType: string, streetTypeIntersection: string, suiteNumber: string, suiteType: string, ward: string, zipCode: string>, result: table<POBox: string, POBoxAgency: string, POBoxInfo: string, adm1NameAlternatesLocalized: record, adm2NameAlternatesLocalized: record, block: string, city: string, citySubdivision: string, civicNumberSuffix: string, confidence: string, country: string, countryNameAlternatesLocalized: record, countrycode: string, dependentLocality: string, distance: float, district: string, extraInfo: string, floor: string, geocodinglevel: string, houseNumber: string, houseNumberInfo: string, id: int, lat: float, lng: float, lote: string, name: string, nameAlternatesLocalized: record, postDirection: string, postDirectionIntersection: string, postTown: string, preDirection: string, preDirectionIntersection: string, prefecture: string, quadrant: string, quarter: string, recipientName: string, sector: string, state: string, streetName: string, streetNameIntersection: string, streetType: string, streetTypeIntersection: string, suiteNumber: string, suiteType: string, ward: string, zipCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "address" $address "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "indent" $indent "scalar") (serialize-qp "standardize" $standardize "scalar") (serialize-qp "geocode" $geocode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/addressparser/parse" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# search for places by text around a GPS point
#
# GET /fulltext/search
# operationId: fulltxtsearch
export def "fulltext-search fulltxtsearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --q: string # The searched text : The text for the query can be a zip code, a string or one or more strings
  --allwordsrequired: oneof<nothing, bool> # Whether the fulltext engine should considers all the words specified as required. Defaults to false (since v 4.0). possible values are true|false (or 'on' when used with the rest service) (default: false)
  --spellchecking: string # The spellchecking (optional) : whether some suggestions should be provided if no results are found
  --lat: float # The latitude (north-south) for the location point to search around. The value is a floating number, between -90 and +90. It uses GPS coordinates (format: double)
  --lng: float # TThe longitude (east-West) for the location point to search around. The value is a floating number between -180 and +180. It uses GPS coordinates. (format: double)
  --radius: float # distance from the location point in meters we'd like to search around. The value is a number > 0 if it is not specify or incorrect. (format: double, default: 10000)
  --suggest: oneof<nothing, bool> # If this parameter is set then it will search in part of the names of the street, place,.... It allow you to do auto completion auto suggestion. See the Gisgraphy leaflet plugin for more details. The JSON format will be forced if this parameter is true. See auto completion / suggestions engine for more details (default: false)
  --style: string@style-completer # The output style verbosity (optional) : Determines the output verbosity. 4 styles are available (default: MEDIUM)
  --country: string # limit the search to the specified ISO 3166 country code. Default : search in all countries
  --lang: string # The language code (optional) : The iso 639 Alpha2 or alpha3 Language Code. Some properties such as the AlternateName AdmNames and countryname belong to a certain language code. The language parameter can limit the output of those fields to a certain language (it only apply when style parameter='style') : If the language code does not exists or is not specified, properties with all the languages are retrieved If it exists, the properties with the specified language code, are retrieved
  --format: string@format-completer-1 # The output format. (default: XML)
  --qp-from: int # The first pagination index. Numbered from 1. If the number is < 1 or not specified, it will be set to the default value : 1 (format: int32, default: 1)
  --qp-to: int # The last pagination index. if < 1 or not specified, it will be set to startindex + 10. Max = 10 (can be changed) (format: int32, default: 10)
  --callback: string # The callback method name (optional), use to wrap the content into a (alphanumeric) Javascript method. Works only for script output formats (JSON, PHP, Ruby, Python)
  --indent: oneof<nothing, bool> # indents the results.Default to false. Possible values are true or false (or on when used with the rest service. If you use a checkbox in a web form, to indent the results, the value will be 'on' or 'off', so for a simple use : the value of indent can be 'true' or 'on' (default: false)
]: nothing -> record<QTime: int, maxScore: float, message: string, numFound: int, result: table<adm1_code: string, adm1_name: string, adm1_names_alternate: list, adm2_code: string, adm2_name: string, adm2_names_alternate: list, adm3_code: string, adm3_name: string, adm4_code: string, adm4_name: string, amenity: string, area: float, capital_name: string, continent: string, country_code: string, country_flag_url: string, country_name: string, country_names_alternate: list, currency_code: string, currency_name: string, elevation: int, feature_class: string, feature_code: string, feature_id: int, fips_code: string, fully_qualified_address: string, fully_qualified_name: string, google_map_url: string, gtopo30: int, house_numbers: list, is_in: string, is_in_adm: string, is_in_place: string, is_in_zip: list, isoalpha2_country_code: string, isoalpha3_country_code: string, lat: float, length: float, level: int, lng: float, municipality: bool, name: string, name_alternates: list, name_ascii: string, one_way: bool, openstreetmap_id: int, openstreetmap_map_url: string, phone_prefix: string, placetype: string, population: int, postal_code_mask: string, postal_code_regex: string, score: float, spoken_languages: list, street_type: string, timezone: string, tld: string, yahoo_map_url: string, zipcodes: list>, resultsSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "allwordsrequired" $allwordsrequired "scalar") (serialize-qp "spellchecking" $spellchecking "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "suggest" $suggest "scalar") (serialize-qp "style" $style "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "indent" $indent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fulltext/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Geocode an address
#
# GET /geocoding/geocode
# operationId: geocode
export def "geocoding-geocode geocode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --address: string # A postal address, structured or not, a street, a city, a postal code, a country, or a combination.
  --country: string # The country where the place/address is. It is used to determine the postal address format and to improve performance. It will probably be optional in next version to ease the usability. The value must be the ISO 3166 Alpha 2 code of the country.
  --postal: string # Whether the given address is a postal address. default to false. In other words, if the address follow the specification or if it is a well-formed address as it was written on an envelope. This parameter will enable the parsing of the address by the address parser before geocoding, this way, the relevance will be better because because if parsing is successful, we will know the meaning of each word. Note that you can also specify each field if you already know them.
  --format: string@format-completer # The output format. (default: XML)
  --qp-from: int # The first pagination index. Numbered from 1. If the number is < 1 or not specified, it will be set to the default value : 1 (format: int32, default: 1)
  --qp-to: int # The last pagination index. if < 1 or not specified, it will be set to startindex + 10. Max = 10 (can be changed) (format: int32, default: 10)
  --callback: string # The callback method name (optional), use to wrap the content into a (alphanumeric) Javascript method. Works only for script output formats (JSON, PHP, Ruby, Python)
  --indent: oneof<nothing, bool> # indents the results. Possible values are true or false (or on when used with the rest service. If you use a checkbox in a web form, to indent the results, the value will be 'on' or 'off', so for a simple use : the value of indent can be 'true' or 'on' (default: false)
]: nothing -> record<QTime: int, message: string, numFound: int, parsedAddress: record<POBox: string, POBoxAgency: string, POBoxInfo: string, adm1NameAlternatesLocalized: record, adm2NameAlternatesLocalized: record, block: string, city: string, citySubdivision: string, civicNumberSuffix: string, confidence: string, country: string, countryNameAlternatesLocalized: record, countrycode: string, dependentLocality: string, distance: float, district: string, extraInfo: string, floor: string, geocodinglevel: string, houseNumber: string, houseNumberInfo: string, id: int, lat: float, lng: float, lote: string, name: string, nameAlternatesLocalized: record, postDirection: string, postDirectionIntersection: string, postTown: string, preDirection: string, preDirectionIntersection: string, prefecture: string, quadrant: string, quarter: string, recipientName: string, sector: string, state: string, streetName: string, streetNameIntersection: string, streetType: string, streetTypeIntersection: string, suiteNumber: string, suiteType: string, ward: string, zipCode: string>, result: table<POBox: string, POBoxAgency: string, POBoxInfo: string, adm1NameAlternatesLocalized: record, adm2NameAlternatesLocalized: record, block: string, city: string, citySubdivision: string, civicNumberSuffix: string, confidence: string, country: string, countryNameAlternatesLocalized: record, countrycode: string, dependentLocality: string, distance: float, district: string, extraInfo: string, floor: string, geocodinglevel: string, houseNumber: string, houseNumberInfo: string, id: int, lat: float, lng: float, lote: string, name: string, nameAlternatesLocalized: record, postDirection: string, postDirectionIntersection: string, postTown: string, preDirection: string, preDirectionIntersection: string, prefecture: string, quadrant: string, quarter: string, recipientName: string, sector: string, state: string, streetName: string, streetNameIntersection: string, streetType: string, streetTypeIntersection: string, suiteNumber: string, suiteType: string, ward: string, zipCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "address" $address "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "postal" $postal "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "indent" $indent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geocoding/geocode" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Geocode an address
#
# GET /geoloc/search
# operationId: geoloc
export def "geoloc-search geoloc" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --lat: float # The latitude (north-south) for the location point to search around. The value is a floating number, between -90 and +90. It uses GPS coordinates (format: double)
  --lng: float # TThe longitude (east-West) for the location point to search around. The value is a floating number between -180 and +180. It uses GPS coordinates. (format: double)
  --radius: float # distance from the location point in meters we'd like to search around. The value is a number > 0 if it is not specify or incorrect. (format: double, default: 10000)
  --distance: oneof<nothing, bool> # Whether (or not) we want the distance field to be output. This option is useful to improve the performance if we don't care about the distance (e.g : we search for name). Of course, the results won't be sorted by distance. If you use a checkbox in a form to indent the results, the value will be 'on' or 'off', so to simplify the use : the value for the web service can be 'true' or 'on' (default: true)
  --placetype: string # filter search for a given placetype
  --format: string@format-completer # The output format. (default: XML)
  --qp-from: int # The first pagination index. Numbered from 1. If the number is < 1 or not specified, it will be set to the default value : 1 (format: int32, default: 1)
  --qp-to: int # The last pagination index. if < 1 or not specified, it will be set to startindex + 10. Max = 10 (can be changed) (format: int32, default: 10)
  --callback: string # The callback method name (optional), use to wrap the content into a (alphanumeric) Javascript method. Works only for script output formats (JSON, PHP, Ruby, Python)
  --indent: oneof<nothing, bool> # indents the results.Default to false. Possible values are true or false (or on when used with the rest service. If you use a checkbox in a web form, to indent the results, the value will be 'on' or 'off', so for a simple use : the value of indent can be 'true' or 'on' (default: false)
]: nothing -> record<QTime: int, error: string, numFound: int, result: table<adm1Code: string, adm1Name: string, adm2Code: string, adm2Name: string, adm3Code: string, adm3Name: string, adm4Code: string, adm4Name: string, adm5Code: string, adm5Name: string, amenity: string, area: float, asciiName: string, capitalName: string, continent: string, countryCode: string, country_flag_url: string, currencyCode: string, currencyName: string, distance: float, elevation: int, equivalentFipsCode: string, featureClass: string, featureCode: string, featureId: int, fipsCode: string, fullyQualifiedAddress: string, google_map_url: string, gtopo30: int, isIn: string, isInAdm: string, isInPlace: string, isInZip: string, iso3166Alpha2Code: string, iso3166Alpha3Code: string, iso3166NumericCode: string, lat: float, length: float, level: int, lng: float, name: string, oneWay: bool, openstreetmapId: int, openstreetmap_map_url: string, phonePrefix: string, placeType: string, population: int, postalCodeMask: string, postalCodeRegex: string, streetType: string, timezone: string, tld: string, yahoo_map_url: string, zipCodes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "distance" $distance "scalar") (serialize-qp "placetype" $placetype "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "indent" $indent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geoloc/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reverse geocode an address
#
# GET /reversegeocoding/reversegeocode
# operationId: reversegeocode
export def "reversegeocoding-reversegeocode reversegeocode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --lat: float # The latitude (north-south) for the location point to search around. The value is a floating number, between -90 and +90. It uses GPS coordinates (format: double)
  --lng: float # TThe longitude (east-West) for the location point to search around. The value is a floating number between -180 and +180. It uses GPS coordinates. (format: double)
  --format: string@format-completer # The output format. (default: XML)
  --qp-from: int # The first pagination index. Numbered from 1. If the number is < 1 or not specified, it will be set to the default value : 1 (format: int32, default: 1)
  --qp-to: int # The last pagination index. if < 1 or not specified, it will be set to startindex + 10. Max = 10 (can be changed) (format: int32, default: 10)
  --callback: string # The callback method name (optional), use to wrap the content into a (alphanumeric) Javascript method. Works only for script output formats (JSON, PHP, Ruby, Python)
  --indent: oneof<nothing, bool> # indents the results. Possible values are true or false (or on when used with the rest service. If you use a checkbox in a web form, to indent the results, the value will be 'on' or 'off', so for a simple use : the value of indent can be 'true' or 'on' (default: false)
]: nothing -> record<QTime: int, message: string, numFound: int, parsedAddress: record<POBox: string, POBoxAgency: string, POBoxInfo: string, adm1NameAlternatesLocalized: record, adm2NameAlternatesLocalized: record, block: string, city: string, citySubdivision: string, civicNumberSuffix: string, confidence: string, country: string, countryNameAlternatesLocalized: record, countrycode: string, dependentLocality: string, distance: float, district: string, extraInfo: string, floor: string, geocodinglevel: string, houseNumber: string, houseNumberInfo: string, id: int, lat: float, lng: float, lote: string, name: string, nameAlternatesLocalized: record, postDirection: string, postDirectionIntersection: string, postTown: string, preDirection: string, preDirectionIntersection: string, prefecture: string, quadrant: string, quarter: string, recipientName: string, sector: string, state: string, streetName: string, streetNameIntersection: string, streetType: string, streetTypeIntersection: string, suiteNumber: string, suiteType: string, ward: string, zipCode: string>, result: table<POBox: string, POBoxAgency: string, POBoxInfo: string, adm1NameAlternatesLocalized: record, adm2NameAlternatesLocalized: record, block: string, city: string, citySubdivision: string, civicNumberSuffix: string, confidence: string, country: string, countryNameAlternatesLocalized: record, countrycode: string, dependentLocality: string, distance: float, district: string, extraInfo: string, floor: string, geocodinglevel: string, houseNumber: string, houseNumberInfo: string, id: int, lat: float, lng: float, lote: string, name: string, nameAlternatesLocalized: record, postDirection: string, postDirectionIntersection: string, postTown: string, preDirection: string, preDirectionIntersection: string, prefecture: string, quadrant: string, quarter: string, recipientName: string, sector: string, state: string, streetName: string, streetNameIntersection: string, streetType: string, streetTypeIntersection: string, suiteNumber: string, suiteType: string, ward: string, zipCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "indent" $indent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reversegeocoding/reversegeocode" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Geocode an address
#
# GET /street/find
# operationId: streetsearch
export def "street-find streetsearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --lat: float # The latitude (north-south) for the location point to search around. The value is a floating number, between -90 and +90. It uses GPS coordinates (format: double)
  --lng: float # TThe longitude (east-West) for the location point to search around. The value is a floating number between -180 and +180. It uses GPS coordinates. (format: double)
  --radius: float # distance from the location point in meters we'd like to search around. The value is a number > 0 if it is not specify or incorrect. (format: double, default: 10000)
  --oneway: oneof<nothing, bool> # whether the street should be a oneWay street (optional) : limit the search to the street that are one way street. If you use a checkbox in a form to indent the results, the value will be 'on' or 'off', so to simplify the use : the value for the web service can be 'true' or 'on' (default: false)
  --distance: oneof<nothing, bool> # Whether (or not) we want the distance field to be output. This option is useful to improve the performance if we don't care about the distance (e.g : we search for name). Of course, the results won't be sorted by distance. If you use a checkbox in a form to indent the results, the value will be 'on' or 'off', so to simplify the use : the value for the web service can be 'true' or 'on' (default: true)
  --streettype: string # filter search with a stret type
  --format: string@format-completer # The output format. (default: XML)
  --qp-from: int # The first pagination index. Numbered from 1. If the number is < 1 or not specified, it will be set to the default value : 1 (format: int32, default: 1)
  --qp-to: int # The last pagination index. if < 1 or not specified, it will be set to startindex + 10. Max = 10 (can be changed) (format: int32, default: 10)
  --callback: string # The callback method name (optional), use to wrap the content into a (alphanumeric) Javascript method. Works only for script output formats (JSON, PHP, Ruby, Python)
  --indent: oneof<nothing, bool> # indents the results. Possible values are true or false (or on when used with the rest service. If you use a checkbox in a web form, to indent the results, the value will be 'on' or 'off', so for a simple use : the value of indent can be 'true' or 'on' (default: false)
]: nothing -> record<QTime: int, error: string, numFound: int, result: table<countryCode: string, distance: float, fullyQualifiedAddress: string, gid: int, isIn: string, isInAdm: string, isInPlace: string, isInZip: string, lat: float, length: float, lng: float, name: string, oneWay: bool, openstreetmapId: int, streetType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "oneway" $oneway "scalar") (serialize-qp "distance" $distance "scalar") (serialize-qp "streettype" $streettype "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "indent" $indent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/street/find" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
