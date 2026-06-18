# Auto-generated client for obono RKSV API v1.4.0.0
# Source: https://api.apis.guru/v2/specs/obono.at/1.4.0.0/openapi.json
# Auth: --token flag or $env.OBONO_RKSV_API_TOKEN

const BASE_URL = "http://localhost/api/v1"
const DEFAULT_AUTH = "jwt"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OBONO_RKSV_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "jwt" => { {headers: {Authorization: $"JWT ($token_val)"}, query: ""} }
    "basic-credentials" => { {headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: ""} }
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

def base-url-completer [] { ["http://localhost/api/v1"] }
def auth-scheme-completer [] { ["basic" "jwt" "basic-credentials"] }

# Completers for enum parameters
def dialect-completer [] { ["escpos" "escposlite" "star" "text"] }
def encoding-completer [] { ["base64" "raw"] }
def format-completer [] { ["beleg" "export" "uuidlist"] }
def order-completer [] { ["asc" "desc"] }
def unternehmen-id-typ-completer [] { ["gln" "steuernummer" "uid"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "auth get" } } | get name | first)
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

# Request a JWT access token using your obono username and password.
#
# GET /auth
export def "auth get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accessToken: string, registrierkasseUuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a particular `Beleg` from the "Datenerfassungsprotokoll".
#
# GET /belege/{belegUuid}
export def "belege get" [
  beleg_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Beleg_Codes: list<string>, Beleg_Typen: list<string>, Belegdaten: record<Beleg_Datum_Uhrzeit: string, Belegnummer: string, Betrag_Brutto: int, Betrag_Netto: int, Betrag_Satz_Besonders_Brutto: int, Betrag_Satz_Besonders_Netto: int, Betrag_Satz_Ermaessigt_1_Brutto: int, Betrag_Satz_Ermaessigt_1_Netto: int, Betrag_Satz_Ermaessigt_2_Brutto: int, Betrag_Satz_Ermaessigt_2_Netto: int, Betrag_Satz_Normal_Brutto: int, Betrag_Satz_Normal_Netto: int, Betrag_Satz_Null_Brutto: int, Betrag_Satz_Null_Netto: int, Externer_Beleg_Belegkreis: string, Externer_Beleg_Bezeichnung: string, Externer_Beleg_Referenz: string, Kassen_ID: string, Kunde: string, Notizen: list<string>, Posten: list<record>, Rabatte: list<record>, Storno: bool, Storno_Beleg_UUID: string, Storno_Text: string, Training: bool, Unternehmen_Adresse1: string, Unternehmen_Adresse2: string, Unternehmen_Fusszeile: string, Unternehmen_ID: string, Unternehmen_ID_Typ: string, Unternehmen_Kopfzeile: string, Unternehmen_Name: string, Unternehmen_Ort: string, Unternehmen_PLZ: string, Zahlungen: list<record>, Zertifikat_Seriennummer: string>, JWS: string, QR: string, QR_Link: string, Registrierkasse_UUID: string, Signaturerstellungseinheit_UUID: string, _href: string, _uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({beleg_uuid: (encode-path-segment $beleg_uuid)} | format pattern "/belege/{beleg_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /export/csv/registrierkassen/{registrierkasseUuid}/belege
export def "export-csv-registrierkassen-belege get" [
  registrierkasse_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --before: string # Only return results that were saved before the specified date-time string (i.e., anything that `Date.parse()` can parse).
  --after: string # Only return results that were saved after the specified date-time string (i.e., anything that `Date.parse()` can parse).
  --posten: oneof<nothing, bool> # Export `Posten` instead of `Belegdaten`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "posten" $posten "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({registrierkasse_uuid: (encode-path-segment $registrierkasse_uuid)} | format pattern "/export/csv/registrierkassen/{registrierkasse_uuid}/belege") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /export/dep131/registrierkassen/{registrierkasseUuid}/belege
export def "export-dep131-registrierkassen-belege get" [
  registrierkasse_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --before: string # Only return results that were saved before the specified date-time string (i.e., anything that `Date.parse()` can parse).
  --after: string # Only return results that were saved after the specified date-time string (i.e., anything that `Date.parse()` can parse).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({registrierkasse_uuid: (encode-path-segment $registrierkasse_uuid)} | format pattern "/export/dep131/registrierkassen/{registrierkasse_uuid}/belege") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /export/dep7/registrierkassen/{registrierkasseUuid}/belege
export def "export-dep7-registrierkassen-belege get" [
  registrierkasse_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --before: string # Only return results that were saved before the specified date-time string (i.e., anything that `Date.parse()` can parse).
  --after: string # Only return results that were saved after the specified date-time string (i.e., anything that `Date.parse()` can parse).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({registrierkasse_uuid: (encode-path-segment $registrierkasse_uuid)} | format pattern "/export/dep7/registrierkassen/{registrierkasse_uuid}/belege") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /export/gobd/registrierkassen/{registrierkasseUuid}
export def "export-gobd-registrierkassen get" [
  registrierkasse_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --before: string # Only return results that were saved before the specified date-time string (i.e., anything that `Date.parse()` can parse).
  --after: string # Only return results that were saved after the specified date-time string (i.e., anything that `Date.parse()` can parse).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({registrierkasse_uuid: (encode-path-segment $registrierkasse_uuid)} | format pattern "/export/gobd/registrierkassen/{registrierkasse_uuid}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /export/html/belege/{belegUuid}
export def "export-html-belege get" [
  beleg_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({beleg_uuid: (encode-path-segment $beleg_uuid)} | format pattern "/export/html/belege/{beleg_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /export/pdf/belege/{belegUuid}
export def "export-pdf-belege get" [
  beleg_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({beleg_uuid: (encode-path-segment $beleg_uuid)} | format pattern "/export/pdf/belege/{beleg_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /export/qr/belege/{belegUuid}
export def "export-qr-belege get" [
  beleg_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({beleg_uuid: (encode-path-segment $beleg_uuid)} | format pattern "/export/qr/belege/{beleg_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /export/thermal-print/belege/{belegUuid}
export def "export-thermal-print-belege get" [
  beleg_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qr: oneof<nothing, bool> # Should the RKSV QR code should be rendered? (default: true)
  --width: int # Number of characters per line. (default: 42)
  --dialect: string@dialect-completer # The thermal printer dialect. (default: escpos)
  --encoding: string@encoding-completer # The encoding of the binary data. (default: raw)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "qr" $qr "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "dialect" $dialect "scalar") (serialize-qp "encoding" $encoding "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({beleg_uuid: (encode-path-segment $beleg_uuid)} | format pattern "/export/thermal-print/belege/{beleg_uuid}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /export/xls/registrierkassen/{registrierkasseUuid}/belege
export def "export-xls-registrierkassen-belege get" [
  registrierkasse_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --before: string # Only return results that were saved before the specified date-time string (i.e., anything that `Date.parse()` can parse).
  --after: string # Only return results that were saved after the specified date-time string (i.e., anything that `Date.parse()` can parse).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({registrierkasse_uuid: (encode-path-segment $registrierkasse_uuid)} | format pattern "/export/xls/registrierkassen/{registrierkasse_uuid}/belege") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about a particular `Registrierkasse`.
#
# GET /registrierkassen/{registrierkasseUuid}
# operationId: getRegistrierkasse
export def "registrierkassen get-registrierkasse" [
  registrierkasse_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Benutzerschluessel: string, Kassen_ID: string, Signaturerstellungseinheit_UUID: string, _href: string, _uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({registrierkasse_uuid: (encode-path-segment $registrierkasse_uuid)} | format pattern "/registrierkassen/{registrierkasse_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generates an `Abschlussbeleg`.
#
# POST /registrierkassen/{registrierkasseUuid}/abschluss
# operationId: createAbschluss
export def "registrierkassen-abschluss create" [
  registrierkasse_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  abschluss_beginn_datum_uhrzeit: string # format: iso8601-date-time
  abschluss_ende_datum_uhrzeit: string # format: iso8601-date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({registrierkasse_uuid: (encode-path-segment $registrierkasse_uuid)} | format pattern "/registrierkassen/{registrierkasse_uuid}/abschluss"))
  let req_body = {"Abschluss-Beginn-Datum-Uhrzeit": $abschluss_beginn_datum_uhrzeit, "Abschluss-Ende-Datum-Uhrzeit": $abschluss_ende_datum_uhrzeit} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the `Beleg` collection from the "Datenerfassungsprotokoll".
#
# GET /registrierkassen/{registrierkasseUuid}/belege
# operationId: getBelege
export def "registrierkassen-belege get" [
  registrierkasse_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # Determines the format of the `Beleg` collection. (default: export)
  --order: string@order-completer # Determines the sorting order. (default: asc)
  --limit: int # Limits the number of returned results.
  --offset: int # Skips the specified number of results from the result set. (default: 0)
  --before: string # Only return results that where saved before the specified date-time string (i.e., anything that `Date.parse()` can parse).
  --after: string # Only return results that where saved after the specified date-time string (i.e., anything that `Date.parse()` can parse).
  --gte: int # Only return results that have at least a particular `Belegnummer`.
  --lte: int # Only return results that have at most a particular `Belegnummer`.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "gte" $gte "scalar") (serialize-qp "lte" $lte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({registrierkasse_uuid: (encode-path-segment $registrierkasse_uuid)} | format pattern "/registrierkassen/{registrierkasse_uuid}/belege") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a particular `Beleg` from the "Datenerfassungsprotokoll".
#
# GET /registrierkassen/{registrierkasseUuid}/belege/{belegUuid}
# operationId: getBeleg
export def "registrierkassen-belege get-beleg" [
  registrierkasse_uuid: string
  beleg_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Beleg_Codes: list<string>, Beleg_Typen: list<string>, Belegdaten: record<Beleg_Datum_Uhrzeit: string, Belegnummer: string, Betrag_Brutto: int, Betrag_Netto: int, Betrag_Satz_Besonders_Brutto: int, Betrag_Satz_Besonders_Netto: int, Betrag_Satz_Ermaessigt_1_Brutto: int, Betrag_Satz_Ermaessigt_1_Netto: int, Betrag_Satz_Ermaessigt_2_Brutto: int, Betrag_Satz_Ermaessigt_2_Netto: int, Betrag_Satz_Normal_Brutto: int, Betrag_Satz_Normal_Netto: int, Betrag_Satz_Null_Brutto: int, Betrag_Satz_Null_Netto: int, Externer_Beleg_Belegkreis: string, Externer_Beleg_Bezeichnung: string, Externer_Beleg_Referenz: string, Kassen_ID: string, Kunde: string, Notizen: list<string>, Posten: list<record>, Rabatte: list<record>, Storno: bool, Storno_Beleg_UUID: string, Storno_Text: string, Training: bool, Unternehmen_Adresse1: string, Unternehmen_Adresse2: string, Unternehmen_Fusszeile: string, Unternehmen_ID: string, Unternehmen_ID_Typ: string, Unternehmen_Kopfzeile: string, Unternehmen_Name: string, Unternehmen_Ort: string, Unternehmen_PLZ: string, Zahlungen: list<record>, Zertifikat_Seriennummer: string>, JWS: string, QR: string, QR_Link: string, Registrierkasse_UUID: string, Signaturerstellungseinheit_UUID: string, _href: string, _uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({registrierkasse_uuid: (encode-path-segment $registrierkasse_uuid), beleg_uuid: (encode-path-segment $beleg_uuid)} | format pattern "/registrierkassen/{registrierkasse_uuid}/belege/{beleg_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Signs a receipt and stores it in the "Datenerfassungsprotokoll".
#
# PUT /registrierkassen/{registrierkasseUuid}/belege/{belegUuid}
# operationId: addBeleg
# --Posten item shape: {Bezeichnung: string, BruttoBetrag: int, Externer-Beleg-Belegkreis?: string, Externer-Beleg-Bezeichnung?: string, Externer-Beleg-Referenz?: string, Menge: int, NettoBetrag: int, Satz: "NORMAL"|"ERMAESSIGT1"|"ERMAESSIGT2"|"BESONDERS"|"NULL"}
# --Rabatte item shape: {Betrag-Brutto: int, Betrag-Netto: int, Bezeichnung: string, Satz?: "NORMAL"|"ERMAESSIGT1"|"ERMAESSIGT2"|"BESONDERS"|"NULL"}
# --Zahlungen item shape: {Betrag: int, Bezeichnung: string, Referenz?: string}
export def "registrierkassen-belege create-beleg" [
  registrierkasse_uuid: string
  beleg_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --externer-beleg-belegkreis: string
  --externer-beleg-bezeichnung: string
  --externer-beleg-referenz: string
  --kunde: string
  --notizen: list<string>
  --posten: list # item shape: {Bezeichnung: string, BruttoBetrag: int, Externer-Beleg-Belegkreis?: string, Externer-Beleg-Bezeichnung?: string, Externer-Beleg-Referenz?: string, Menge: int, NettoBetrag: int, Satz: "NORMAL"|"ERMAESSIGT1"|"ERMAESSIGT2"|"BESONDERS"|"NULL"}
  --rabatte: list # item shape: {Betrag-Brutto: int, Betrag-Netto: int, Bezeichnung: string, Satz?: "NORMAL"|"ERMAESSIGT1"|"ERMAESSIGT2"|"BESONDERS"|"NULL"}
  --storno: oneof<nothing, bool> # Storno?
  --storno-beleg-uuid: string # The `Beleg-UUID` property of the `Beleg` to be cancelled (format: uuid)
  --storno-text: string
  --training: oneof<nothing, bool> # Training?
  --unternehmen-adresse1: string
  --unternehmen-adresse2: string
  --unternehmen-fusszeile: string
  --unternehmen-id: string
  --unternehmen-id-typ: string@unternehmen-id-typ-completer
  --unternehmen-kopfzeile: string
  --unternehmen-name: string
  --unternehmen-ort: string
  --unternehmen-plz: string
  --zahlungen: list # item shape: {Betrag: int, Bezeichnung: string, Referenz?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({registrierkasse_uuid: (encode-path-segment $registrierkasse_uuid), beleg_uuid: (encode-path-segment $beleg_uuid)} | format pattern "/registrierkassen/{registrierkasse_uuid}/belege/{beleg_uuid}"))
  let req_body = {"Externer-Beleg-Belegkreis": $externer_beleg_belegkreis, "Externer-Beleg-Bezeichnung": $externer_beleg_bezeichnung, "Externer-Beleg-Referenz": $externer_beleg_referenz, "Kunde": $kunde, "Notizen": $notizen, "Posten": $posten, "Rabatte": $rabatte, "Storno": $storno, "Storno-Beleg-UUID": $storno_beleg_uuid, "Storno-Text": $storno_text, "Training": $training, "Unternehmen-Adresse1": $unternehmen_adresse1, "Unternehmen-Adresse2": $unternehmen_adresse2, "Unternehmen-Fusszeile": $unternehmen_fusszeile, "Unternehmen-ID": $unternehmen_id, "Unternehmen-ID-Typ": $unternehmen_id_typ, "Unternehmen-Kopfzeile": $unternehmen_kopfzeile, "Unternehmen-Name": $unternehmen_name, "Unternehmen-Ort": $unternehmen_ort, "Unternehmen-PLZ": $unternehmen_plz, "Zahlungen": $zahlungen} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Generates a DEP file.
#
# GET /registrierkassen/{registrierkasseUuid}/dep
# operationId: getDEP
export def "registrierkassen-dep get" [
  registrierkasse_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({registrierkasse_uuid: (encode-path-segment $registrierkasse_uuid)} | format pattern "/registrierkassen/{registrierkasse_uuid}/dep"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of `Monatsbelege`.
#
# GET /registrierkassen/{registrierkasseUuid}/monatsbelege
# operationId: getMonatsbelege
export def "registrierkassen-monatsbelege get" [
  registrierkasse_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int
  --month: int
]: nothing -> table<Beleg_UUID: string, FON_Geprueft_Datum_Uhrzeit: string, FON_Geprueft_Erfolgreich: bool, Jahr: int, Monat: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "month" $month "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({registrierkasse_uuid: (encode-path-segment $registrierkasse_uuid)} | format pattern "/registrierkassen/{registrierkasse_uuid}/monatsbelege") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
