# Auto-generated client for PhantAuth v1.0.0
# Source: https://api.apis.guru/v2/specs/phantauth.net/1.0.0/openapi.json
# Auth: --token flag or $env.PHANTAUTH_TOKEN

const BASE_URL = "https://phantauth.net"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o PHANTAUTH_TOKEN | default "" }
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

def base-url-completer [] { ["https://phantauth.net"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "client create" } } | get name | first)
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

# Create a Client Selfie
#
# POST /client
export def "client create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # URL of the Client's JSON representation.
  client_id: string # OAuth 2.0 client identifier string.
  --client-name: string # Human-readable string name of the client to be presented to the end-user during authorization.
  --client-secret: string # OAuth 2.0 client secret string.
  --client-uri: string # URL string of a web page providing information about the client.
  --contacts: list # Array of strings representing ways to contact people responsible for this client, typically email addresses.
  --grant-types: list # Array of OAuth 2.0 grant type strings that the client can use at the token endpoint.
  --jwks: list # Client's JSON Web Key Set [RFC7517] document value, which contains the client's public keys. The value of this field MUST be a JSON object containing a valid JWK Set.
  --jwks-uri: string # URL string referencing the client's JSON Web Key (JWK) Set [RFC7517] document, which contains the client's public keys.
  --logo-email: string # An email address used to generate a gravatar.com logo_uri.
  --logo-uri: string # URL string that references a logo for the client.
  --policy-uri: string # URL string that points to a human-readable privacy policy document that describes how the deployment organization collects, uses, retains, and discloses personal data.
  --redirect-uris: list # Array of redirection URI strings for use in redirect-based flows such as the authorization code and implicit flows.
  --response-types: list # Array of the OAuth 2.0 response type strings that the client can use at the authorization endpoint.
  --scope: string # String containing a space-separated list of scope values (as described in Section 3.3 of OAuth 2.0 [RFC6749]) that the client can use when requesting access tokens.
  --software-id: string # A unique identifier string (e.g., a Universally Unique Identifier (UUID)) assigned by the client developer or software publisher used by registration endpoints to identify the client software to be dynamically registered.
  --software-version: string # A version identifier string for the client software identified by software_id.
  --token-endpoint-auth-method: string # String indicator of the requested authentication method for the token endpoint.
  --tos-uri: string # URL string that points to a human-readable terms of service document for the client that describes a contractual relationship between the end-user and the client that the end-user accepts when authorizing the client.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/client" $auth.query)
  let req_body = {"@id": $id, "client_id": $client_id, "client_name": $client_name, "client_secret": $client_secret, "client_uri": $client_uri, "contacts": $contacts, "grant_types": $grant_types, "jwks": $jwks, "jwks_uri": $jwks_uri, "logo_email": $logo_email, "logo_uri": $logo_uri, "policy_uri": $policy_uri, "redirect_uris": $redirect_uris, "response_types": $response_types, "scope": $scope, "software_id": $software_id, "software_version": $software_version, "token_endpoint_auth_method": $token_endpoint_auth_method, "tos_uri": $tos_uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get a Client
#
# GET /client/{client_id}
export def "client get" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_id: string, client_id: string, client_name: string, client_secret: string, client_uri: string, contacts: list<any>, grant_types: list<any>, jwks: list<any>, jwks_uri: string, logo_email: string, logo_uri: string, policy_uri: string, redirect_uris: list<any>, response_types: list<any>, scope: string, software_id: string, software_version: string, token_endpoint_auth_method: string, tos_uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($client_id | is-empty) { error make --unspanned { msg: "path parameter 'client_id' must be non-empty" } }
  let full_url = (build-url $base ({client_id: (encode-path-segment $client_id)} | format pattern "/client/{client_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a Client Token
#
# GET /client/{client_id}/token/{kind}
export def "client-token get" [
  client_id: string
  kind: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($client_id | is-empty) { error make --unspanned { msg: "path parameter 'client_id' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  let full_url = (build-url $base ({client_id: (encode-path-segment $client_id), kind: (encode-path-segment $kind)} | format pattern "/client/{client_id}/token/{kind}") $auth.query)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a Domain
#
# GET /domain/{domainname}
export def "domain get" [
  domainname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_id: string, logo: string, members: list<any>, name: string, profile: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domainname | is-empty) { error make --unspanned { msg: "path parameter 'domainname' must be non-empty" } }
  let full_url = (build-url $base ({domainname: (encode-path-segment $domainname)} | format pattern "/domain/{domainname}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a Fleet
#
# GET /fleet/{fleetname}
export def "fleet get" [
  fleetname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_id: string, logo: string, logo_email: string, members: list<any>, name: string, profile: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($fleetname | is-empty) { error make --unspanned { msg: "path parameter 'fleetname' must be non-empty" } }
  let full_url = (build-url $base ({fleetname: (encode-path-segment $fleetname)} | format pattern "/fleet/{fleetname}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a Team
#
# GET /team/{teamname}
export def "team get" [
  teamname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_id: string, logo: string, logo_email: string, members: list<any>, name: string, profile: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($teamname | is-empty) { error make --unspanned { msg: "path parameter 'teamname' must be non-empty" } }
  let full_url = (build-url $base ({teamname: (encode-path-segment $teamname)} | format pattern "/team/{teamname}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a Tenant
#
# GET /tenant/{tenantname}
export def "tenant get" [
  tenantname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_id: string, about: string, attribution: string, depot: string, depots: list<any>, domain: bool, factories: list<any>, factory: string, favicon: string, issuer: string, logo: string, name: string, script: string, sheet: string, sub: string, subtenant: bool, summary: string, template: string, theme: string, userinfo: string, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tenantname | is-empty) { error make --unspanned { msg: "path parameter 'tenantname' must be non-empty" } }
  let full_url = (build-url $base ({tenantname: (encode-path-segment $tenantname)} | format pattern "/tenant/{tenantname}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a User Selfie
#
# POST /user
# --address shape: {country?: string, formatted?: string, locality?: string, postal_code?: string, region?: string, street_address?: string}
export def "user create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The URL of the user's JSON representation.
  --address: record # The user's preferred postal address. — shape: {country?: string, formatted?: string, locality?: string, postal_code?: string, region?: string, street_address?: string}
  --birthdate: string # The user's birthday, represented as an ISO 8601:2004 [ISO8601‑2004] YYYY-MM-DD format.
  --email: string # The user's preferred email address.
  --email-verified: oneof<nothing, bool> # True if the user's e-mail address has been verified; otherwise false.
  --family-name: string # The user's surname(s) or last name(s).
  --gender: string # The enduser's gender. Possible values are: female, male, and unknown.
  --given-name: string # The user's given name(s) or first name(s).
  --locale: string # The user's locale, represented as a BCP47 [RFC5646] language tag. It is an ISO 639-1 Alpha-2 language code in lowercase and an ISO 3166-1 Alpha-2 country code in uppercase letters, separated by a dash.
  --me: string # The simplified URL of the user's profile page.
  --middle-name: string # The user's middle name(s).
  --name: string # The user's full name in displayable form, including all name parts, possibly including titles and suffixes, ordered according to the enduser's locale and preferences.
  --nickname: string # A casual name of the User that may or may not be the same as the given_name.
  --password: string # The user's generated password.
  --phone-number: string # The user's preferred telephone number.
  --phone-number-verified: oneof<nothing, bool> # True if the enduser's phone number has been verified; otherwise false.
  --picture: string # The URL of the user's profile picture.
  --preferred-username: string # A shorthand name by which the user wishes to be referred to at the Relying Party.
  --profile: string # The URL of the user's profile page.
  sub: string # Subject - User identifier at the issuer.
  --uid: string # The user's simplified, shortened identifier at the Issuer.
  --updated-at: float # The time when the User's information was last updated. Its value is a JSON number representing the number of seconds from 1970-01-01T0:0:0Z as measured in UTC until the date/time.
  --webmail: string # The URL of user's mailbox in a webmail application.
  --website: string # The URL of the user's webpage or blog.
  --zoneinfo: string # A string from the zoneinfo time zone database representing the user's time zone. For example, Europe/Paris or America/Los_Angeles.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user" $auth.query)
  let req_body = {"@id": $id, "address": $address, "birthdate": $birthdate, "email": $email, "email_verified": $email_verified, "family_name": $family_name, "gender": $gender, "given_name": $given_name, "locale": $locale, "me": $me, "middle_name": $middle_name, "name": $name, "nickname": $nickname, "password": $password, "phone_number": $phone_number, "phone_number_verified": $phone_number_verified, "picture": $picture, "preferred_username": $preferred_username, "profile": $profile, "sub": $sub, "uid": $uid, "updated_at": $updated_at, "webmail": $webmail, "website": $website, "zoneinfo": $zoneinfo} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get a User
#
# GET /user/{username}
export def "user get" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_id: string, address: record<country: string, formatted: string, locality: string, postal_code: string, region: string, street_address: string>, birthdate: string, email: string, email_verified: bool, family_name: string, gender: string, given_name: string, locale: string, me: string, middle_name: string, name: string, nickname: string, password: string, phone_number: string, phone_number_verified: bool, picture: string, preferred_username: string, profile: string, sub: string, uid: string, updated_at: float, webmail: string, website: string, zoneinfo: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/user/{username}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a User Token
#
# GET /user/{username}/token/{kind}
export def "user-token get" [
  username: string
  kind: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string # OpenID Connect scope
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  let qp = [(serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), kind: (encode-path-segment $kind)} | format pattern "/user/{username}/token/{kind}") $qp $auth.query)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"scope": $scope} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
