# Auto-generated client for Public Api vv2
# Source: https://api.apis.guru/v2/specs/combell.com/v2/openapi.json
# Auth: --token flag or $env.PUBLIC_API_TOKEN

const BASE_URL = "http://localhost/v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PUBLIC_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def asset-type-completer [] { ["dns" "domain" "linux_hosting" "mailbox" "mysql" "windows_hosting"] }
def type-completer [] { ["advanced" "basic" "none"] }
def certificate-type-completer [] { ["multi_domain" "standard" "wildcard"] }
def validation-level-completer [] { ["domain_validated" "extended_validated" "organization_validated"] }
def file-format-completer [] { ["pfx"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts list" } } | get name | first)
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

# Overview of accounts
#
# GET /accounts
# operationId: GetAccounts
export def "accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of items to skip in the resultset. (format: int32)
  --take: int # The number of items to return in the resultset. The returned count can be equal or less than this number. (format: int32)
  --asset-type: string@asset-type-completer # Filters the list, returning only accounts containing the specified asset type.
  --identifier: string # Return only accounts, matching the specified identifier. (nullable)
]: nothing -> table<id: int, identifier: string, servicepack_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "asset_type" $asset_type "scalar") (serialize-qp "identifier" $identifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take, "asset_type": $asset_type, "identifier": $identifier} | compact), body: null}
}

# Create a new account
#
# POST /accounts
# operationId: CreateAccount
export def "accounts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ftp-password: string # Ftp password for the account. Applies only if the servicepack contains hosting. Passwords have to adhere to following rules:Between 8-20 characters.Must be a mix of letters and digits.Must contain at least one digit (0-9).Must contain at least one letter (a-z).Cannot contain spaces.Cannot contain characters: * € $ & + } { ' " \
  --identifier: string # An identifier for the account. Should be a domain name for hosting accounts.
  --servicepack-id: int # The servicepack id that defines the account. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts")
  let req_body = {"ftp_password": $ftp_password, "identifier": $identifier, "servicepack_id": $servicepack_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a specific account
#
# GET /accounts/{accountId}
# operationId: GetAccount
export def "accounts get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: int # The id of the account. (format: int32)
]: nothing -> record<addons: table<id: int, name: string>, id: int, identifier: string, servicepack: record<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "account_id" $account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"account_id": $account_id} | compact), body: null}
}

# Get records
#
# GET /dns/{domainName}/records
export def "dns-records list" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The domain name.
  --skip: int # The number of items to skip in the resultset. (format: int32)
  --take: int # The number of items to return in the resultset. The returned count can be equal or less than this number. (format: int32)
  --type: string # Filters records matching the type. Most other filters only apply when this filter is specified. (nullable)
  --record-name: string # Filters records matching the record name. This filter only applies to lookups of A, CNAME, TXT, CAA, ALIAS and TLSA records. (nullable)
  --service: string # Filters records for the service. This filter only applies to lookups of SRV records. (nullable)
]: nothing -> table<content: string, id: string, port: int, priority: int, protocol: string, record_name: string, service: string, target: string, ttl: int, type: string, weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "record_name" $record_name "scalar") (serialize-qp "service" $service "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/dns/{domain_name}/records") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain_name": $domain_name, "skip": $skip, "take": $take, "type": $type, "record_name": $record_name, "service": $service} | compact), body: null}
}

# Create a record
#
# POST /dns/{domainName}/records
export def "dns-records create" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The domain name.
  --content: string # Variable data depending on the record type. A: the IPv4 address.CNAME: canonical name of an alias.MX: fully qualified domain name of a mail host.SRV: does not apply. Data for the SRV records can be found in specific properties.TXT: free form text data.CAA: format should match specific values for flag, tag and ca: "{flag} {tag} {ca}". The flag. The values 128 (critical) or 0 (non-critical) are expected, with 0 as the default.The tag. A tag specifies which actions an authorized CA can take in terms of issuing SSL/TLS certificates.The value "issue": explicitly authorizes a single certificate authority to issue a certificate (any type) for the hostname.The value "issuewild": explicitly authorizes a single certificate authority to issue a wildcard certificate (and only wildcard) for the hostname.The value "iodef": specifies a URL to which a certificate authority may report policy violations.The ca. This is the domain of the CA (Certification Authority) that has the authority to issue certificates for the domain in question. If the value is a semicolon (;), it means that no CA has the authority to issue a certificate for that domain.ALIAS: canonical name of an alias.TLSA: format should match specific values for usage, selector, matching type and data: "{usage} {selector} {matching_type} {data}" The usage. The first field after the TLSA text in the DNS RR, specifies how to verify the certificate.A value of 0 is for what is commonly called CA constraint (and PKIX-TA). The certificate provided when establishing TLS must be issued by the listed root-CA or one of its intermediate CAs, with a valid certification path to a root-CA already trusted by the application doing the verification.A value of 1 is for what is commonly called Service certificate constraint (and PKIX-EE). The certificate used must match the TLSA record exactly, and it must also pass PKIX certification path validation to a trusted root-CA.A value of 2 is for what is commonly called Trust Anchor Assertion (and DANE-TA). The certificate used has a valid certification path pointing back to the certificate mention in this record, but there is no need for it to pass the PKIX certification path validation to a trusted root-CA.A value of 3 is for what is commonly called Domain issued certificate (and DANE-EE). The services uses a self-signed certificate. It is not signed by anyone else, and is exactly this record.The selector. When connecting to the service and a certificate is received, the selector field specifies which parts of it should be checked.A value of 0 means to select the entire certificate for matching.A value of 1 means to select just the public key for certificate matching. Matching the public key is often sufficient, as this is likely to be unique.The matching type.A type of 0 means the entire information selected is present in the certificate association data.A type of 1 means to do a SHA-256 hash of the selected data.A type of 2 means to do a SHA-512 hash of the selected data.The actual data to be matched given the settings of the other fields. This is a long text string of hexadecimal data.
  --id: string # The id of the record This value is ignored for creation of new records.
  --port: int # The port for SRV records. The value MUST be a positive integer. Editing the value is not possible. You should add a new SRV record and delete the existing record. (format: int32)
  --priority: int # The priority for MX or SRV records. A lower value means more preferred. The value MUST be a positive integer less or equal to 9999. (format: int32, default: 10)
  --protocol: string # Used for the creation of SRV records. Possible options: TCP, UDP, ... Editing the value is not possible. You should add a new SRV record and delete the existing record. (default: TCP)
  --record-name: string # The name of the record. This is the host name, alias defined by the record. An empty record or '@' is equal to the domain name. Applies to A, MX, CNAME, TXT, CAA, ALIAS and TLSA records. When type is TLSA the recommended value format is port number, protocol and host: _25._tcp. Does not apply for SRV records.
  --service: string # The symbolic name of the desired service for SRV records. Editing the value is not possible. You should add a new SRV record and can delete the existing record.
  --target: string # The canonical hostname of the machine providing the service for SRV records. Editing the value is not possible. You should add a new SRV record and delete the existing record.
  --ttl: int # Time to live of the record in seconds. It defines the time frame that clients can cache the information. The value MUST be between 60 and 86400. The default value is 3600 (= 1 hour). (format: int32, default: 3600)
  --type: string # The type of the record (A, MX, CNAME, SRV, TXT, CAA, ALIAS and TLSA).
  --weight: int # The weight for SRV records with the same priority. A higher value means more preferred. (format: int32, default: 0)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/dns/{domain_name}/records") $qp)
  let req_body = {"content": $content, "id": $id, "port": $port, "priority": $priority, "protocol": $protocol, "record_name": $record_name, "service": $service, "target": $target, "ttl": $ttl, "type": $type, "weight": $weight} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name} | compact), body: $req_body}
}

# Delete a record
#
# DELETE /dns/{domainName}/records/{recordId}
export def "dns-records delete" [
  domain_name: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The domain name.
  --record-id: string # The id of the record.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  if ($record_id | is-empty) { error make --unspanned { msg: "path parameter 'recordId' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "record_id" $record_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), record_id: (encode-path-segment $record_id)} | format pattern "/dns/{domain_name}/records/{record_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain_name": $domain_name, "record_id": $record_id} | compact), body: null}
}

# Get specific record
#
# GET /dns/{domainName}/records/{recordId}
export def "dns-records get" [
  domain_name: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The domain name.
  --record-id: string # The id of the record.
]: nothing -> record<content: string, id: string, port: int, priority: int, protocol: string, record_name: string, service: string, target: string, ttl: int, type: string, weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  if ($record_id | is-empty) { error make --unspanned { msg: "path parameter 'recordId' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "record_id" $record_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), record_id: (encode-path-segment $record_id)} | format pattern "/dns/{domain_name}/records/{record_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain_name": $domain_name, "record_id": $record_id} | compact), body: null}
}

# Edit a record
#
# PUT /dns/{domainName}/records/{recordId}
export def "dns-records update" [
  domain_name: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The domain name.
  --record-id: string # The id of the record.
  --content: string # Variable data depending on the record type. A: the IPv4 address.CNAME: canonical name of an alias.MX: fully qualified domain name of a mail host.SRV: does not apply. Data for the SRV records can be found in specific properties.TXT: free form text data.CAA: format should match specific values for flag, tag and ca: "{flag} {tag} {ca}". The flag. The values 128 (critical) or 0 (non-critical) are expected, with 0 as the default.The tag. A tag specifies which actions an authorized CA can take in terms of issuing SSL/TLS certificates.The value "issue": explicitly authorizes a single certificate authority to issue a certificate (any type) for the hostname.The value "issuewild": explicitly authorizes a single certificate authority to issue a wildcard certificate (and only wildcard) for the hostname.The value "iodef": specifies a URL to which a certificate authority may report policy violations.The ca. This is the domain of the CA (Certification Authority) that has the authority to issue certificates for the domain in question. If the value is a semicolon (;), it means that no CA has the authority to issue a certificate for that domain.ALIAS: canonical name of an alias.TLSA: format should match specific values for usage, selector, matching type and data: "{usage} {selector} {matching_type} {data}" The usage. The first field after the TLSA text in the DNS RR, specifies how to verify the certificate.A value of 0 is for what is commonly called CA constraint (and PKIX-TA). The certificate provided when establishing TLS must be issued by the listed root-CA or one of its intermediate CAs, with a valid certification path to a root-CA already trusted by the application doing the verification.A value of 1 is for what is commonly called Service certificate constraint (and PKIX-EE). The certificate used must match the TLSA record exactly, and it must also pass PKIX certification path validation to a trusted root-CA.A value of 2 is for what is commonly called Trust Anchor Assertion (and DANE-TA). The certificate used has a valid certification path pointing back to the certificate mention in this record, but there is no need for it to pass the PKIX certification path validation to a trusted root-CA.A value of 3 is for what is commonly called Domain issued certificate (and DANE-EE). The services uses a self-signed certificate. It is not signed by anyone else, and is exactly this record.The selector. When connecting to the service and a certificate is received, the selector field specifies which parts of it should be checked.A value of 0 means to select the entire certificate for matching.A value of 1 means to select just the public key for certificate matching. Matching the public key is often sufficient, as this is likely to be unique.The matching type.A type of 0 means the entire information selected is present in the certificate association data.A type of 1 means to do a SHA-256 hash of the selected data.A type of 2 means to do a SHA-512 hash of the selected data.The actual data to be matched given the settings of the other fields. This is a long text string of hexadecimal data.
  --id: string # The id of the record This value is ignored for creation of new records.
  --port: int # The port for SRV records. The value MUST be a positive integer. Editing the value is not possible. You should add a new SRV record and delete the existing record. (format: int32)
  --priority: int # The priority for MX or SRV records. A lower value means more preferred. The value MUST be a positive integer less or equal to 9999. (format: int32, default: 10)
  --protocol: string # Used for the creation of SRV records. Possible options: TCP, UDP, ... Editing the value is not possible. You should add a new SRV record and delete the existing record. (default: TCP)
  --record-name: string # The name of the record. This is the host name, alias defined by the record. An empty record or '@' is equal to the domain name. Applies to A, MX, CNAME, TXT, CAA, ALIAS and TLSA records. When type is TLSA the recommended value format is port number, protocol and host: _25._tcp. Does not apply for SRV records.
  --service: string # The symbolic name of the desired service for SRV records. Editing the value is not possible. You should add a new SRV record and can delete the existing record.
  --target: string # The canonical hostname of the machine providing the service for SRV records. Editing the value is not possible. You should add a new SRV record and delete the existing record.
  --ttl: int # Time to live of the record in seconds. It defines the time frame that clients can cache the information. The value MUST be between 60 and 86400. The default value is 3600 (= 1 hour). (format: int32, default: 3600)
  --type: string # The type of the record (A, MX, CNAME, SRV, TXT, CAA, ALIAS and TLSA).
  --weight: int # The weight for SRV records with the same priority. A higher value means more preferred. (format: int32, default: 0)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  if ($record_id | is-empty) { error make --unspanned { msg: "path parameter 'recordId' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "record_id" $record_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), record_id: (encode-path-segment $record_id)} | format pattern "/dns/{domain_name}/records/{record_id}") $qp)
  let req_body = {"content": $content, "id": $id, "port": $port, "priority": $priority, "protocol": $protocol, "record_name": $record_name, "service": $service, "target": $target, "ttl": $ttl, "type": $type, "weight": $weight} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name, "record_id": $record_id} | compact), body: $req_body}
}

# Overviews of domains
#
# GET /domains
# operationId: GetDomains
export def "domains list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of items to skip in the resultset. (format: int32)
  --take: int # The number of items to return in the resultset. The returned count can be equal or less than this number. (format: int32)
]: nothing -> table<domain_name: string, expiration_date: string, will_renew: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Register a domain
#
# POST /domains/registrations
# operationId: Register
# --registrant shape: {address?: string, city?: string, company_name?: string, country_code?: string, email?: string, enterprise_number?: string, extra_fields?: list, fax?: string, first_name?: string, language_code?: string, last_name?: string, phone?: string, postal_code?: string}
export def "domains-registrations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The domain name to register. Only pass the domain part and the tld.For abc.com, abc is the domain part, com is the tld.
  --name-servers: list<string> # List of name servers. When empty, the registation will be done on default name servers.
  --registrant: record # shape: {address?: string, city?: string, company_name?: string, country_code?: string, email?: string, enterprise_number?: string, extra_fields?: list, fax?: string, first_name?: string, language_code?: string, last_name?: string, phone?: string, postal_code?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domains/registrations")
  let req_body = {"domain_name": $domain_name, "name_servers": $name_servers, "registrant": $registrant} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Transfer a domain
#
# POST /domains/transfers
# operationId: Transfer
# --registrant shape: {address?: string, city?: string, company_name?: string, country_code?: string, email?: string, enterprise_number?: string, extra_fields?: list, fax?: string, first_name?: string, language_code?: string, last_name?: string, phone?: string, postal_code?: string}
export def "domains-transfers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-code: string # Authorization code which allows the transfer to execute.
  --domain-name: string # The domain name to transfer. Only pass the domain part and the tld.For abc.com, abc is the domain part, com is the tld.
  --name-servers: list<string> # List of name servers. When empty, the transfer will be done on default name servers.
  --registrant: record # shape: {address?: string, city?: string, company_name?: string, country_code?: string, email?: string, enterprise_number?: string, extra_fields?: list, fax?: string, first_name?: string, language_code?: string, last_name?: string, phone?: string, postal_code?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domains/transfers")
  let req_body = {"auth_code": $auth_code, "domain_name": $domain_name, "name_servers": $name_servers, "registrant": $registrant} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Details of a domain
#
# GET /domains/{domainName}
# operationId: GetDomain
export def "domains get" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The domain name
]: nothing -> record<can_toggle_renew: bool, domain_name: string, expiration_date: string, name_servers: table<ip: string, name: string>, registrant: record<address: string, city: string, company_name: string, country_code: string, email: string, enterprise_number: string, fax: string, first_name: string, language_code: string, last_name: string, phone: string, postal_code: string>, will_renew: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain_name": $domain_name} | compact), body: null}
}

# Edit domain name servers
#
# PUT /domains/{domainName}/nameservers
# operationId: EditNameServers
export def "domains-nameservers update-edit-name-servers" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The domain name
  --body-domain-name: string # The domain name to register.
  --name-servers: list<string> # List of name servers.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}/nameservers") $qp)
  let req_body = {"domain_name": $body_domain_name, "name_servers": $name_servers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name} | compact), body: $req_body}
}

# Edit domain name renew state
#
# PUT /domains/{domainName}/renew
# operationId: ConfigureDomain
export def "domains-renew update-configure" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The domain name
  --will-renew: oneof<nothing, bool> # Indication of renewal.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}/renew") $qp)
  let req_body = {"will_renew": $will_renew} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name} | compact), body: $req_body}
}

# Overview of linux hostings
#
# GET /linuxhostings
# operationId: GetLinuxHostings
export def "linuxhostings get-linux-hostings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of items to skip in the resultset. (format: int32)
  --take: int # The number of items to return in the resultset. The returned count can be equal or less than this number. (format: int32)
]: nothing -> table<domain_name: string, servicepack_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/linuxhostings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Linux hosting detail
#
# GET /linuxhostings/{domainName}
# operationId: GetLinuxHosting
export def "linuxhostings get-linux-hosting" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The Linux hosting domain name.
]: nothing -> record<actual_size: int, domain_name: string, ftp_enabled: bool, ftp_username: string, ip: string, ip_type: string, max_size: int, max_webspace_size: int, mysql_database_names: list<string>, php_version: string, servicepack_id: int, sites: table<host_headers: list, http2_enabled: bool, https_redirect_enabled: bool, name: string, path: string, ssl_enabled: bool>, ssh_host: string, ssh_username: string, webspace_usage: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/linuxhostings/{domain_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain_name": $domain_name} | compact), body: null}
}

# Configure FTP
#
# PUT /linuxhostings/{domainName}/ftp/configuration
# operationId: ConfigureFtp
export def "linuxhostings-ftp-configuration update-configure" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --enabled: oneof<nothing, bool> # Enable or disable FTP.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/linuxhostings/{domain_name}/ftp/configuration") $qp)
  let req_body = {"enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name} | compact), body: $req_body}
}

# Configure PHP APCu setting
#
# PUT /linuxhostings/{domainName}/phpsettings/apcu
# operationId: ChangeApcu
export def "linuxhostings-phpsettings-apcu update-change" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name
  --apcu-size: int # The APcu size. (format: int32)
  --enabled: oneof<nothing, bool> # Enables or disables APC.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/linuxhostings/{domain_name}/phpsettings/apcu") $qp)
  let req_body = {"apcu_size": $apcu_size, "enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name} | compact), body: $req_body}
}

# Get the available PHP versions.
#
# GET /linuxhostings/{domainName}/phpsettings/availableversions
# operationId: GetAvailablePhpVersions
export def "linuxhostings-phpsettings-availableversions get-available-php-versions" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
]: nothing -> table<version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/linuxhostings/{domain_name}/phpsettings/availableversions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain_name": $domain_name} | compact), body: null}
}

# Configure PHP memory limit
#
# PUT /linuxhostings/{domainName}/phpsettings/memorylimit
# operationId: ChangePhpMemoryLimit
export def "linuxhostings-phpsettings-memorylimit update-change-php-memory-limit" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --memory-limit: int # The php memory limit (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/linuxhostings/{domain_name}/phpsettings/memorylimit") $qp)
  let req_body = {"memory_limit": $memory_limit} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name} | compact), body: $req_body}
}

# Change the Linux hosting PHP version.
#
# PUT /linuxhostings/{domainName}/phpsettings/version
# operationId: ChangePhpVersion
export def "linuxhostings-phpsettings-version version-change-php" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --version: string # Php version
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/linuxhostings/{domain_name}/phpsettings/version") $qp)
  let req_body = {"version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name} | compact), body: $req_body}
}

# Overview of scheduled tasks
#
# GET /linuxhostings/{domainName}/scheduledtasks
# operationId: GetScheduledTasks
export def "linuxhostings-scheduledtasks get-scheduled-tasks" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
]: nothing -> table<cron_expression: string, enabled: bool, id: string, script_location: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/linuxhostings/{domain_name}/scheduledtasks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain_name": $domain_name} | compact), body: null}
}

# Add a scheduled task
#
# POST /linuxhostings/{domainName}/scheduledtasks
# operationId: AddScheduledTasks
export def "linuxhostings-scheduledtasks create-scheduled-tasks" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --cron-expression: string # Cron expression of scheduled task. 5-digit expressions (*/5 * * * *) are required in the following sequence:Minute (0 - 59, also */5, */10, */15 and */30 as every 5 minutes, every 10 minutes, every quarter or every half-hour are allowed)Hour (0 - 23, also * as every hour is allowed)Day of the month (1 - 31, also * as every day is allowed)Month (1 - 12 as January to December, also * as every month is allowed)Day of the week (1 - 7 as Monday to Sunday, also * as every day is allowed)
  --enabled: oneof<nothing, bool> # Enabled.
  --id: string # The id of the scheduled task. This value is ignored for creation of new scheduled tasks.
  --script-location: string # Absolute path from this linux hosting to execute.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/linuxhostings/{domain_name}/scheduledtasks") $qp)
  let req_body = {"cron_expression": $cron_expression, "enabled": $enabled, "id": $id, "script_location": $script_location} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name} | compact), body: $req_body}
}

# Delete a scheduled task
#
# DELETE /linuxhostings/{domainName}/scheduledtasks/{scheduledTaskId}
# operationId: DeleteScheduledTask
export def "linuxhostings-scheduledtasks delete-scheduled-task" [
  domain_name: string
  scheduled_task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --scheduled-task-id: string # Id of the scheduled task.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  if ($scheduled_task_id | is-empty) { error make --unspanned { msg: "path parameter 'scheduledTaskId' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "scheduled_task_id" $scheduled_task_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), scheduled_task_id: (encode-path-segment $scheduled_task_id)} | format pattern "/linuxhostings/{domain_name}/scheduledtasks/{scheduled_task_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain_name": $domain_name, "scheduled_task_id": $scheduled_task_id} | compact), body: null}
}

# Get scheduled task detail
#
# GET /linuxhostings/{domainName}/scheduledtasks/{scheduledTaskId}
# operationId: GetScheduledTask
export def "linuxhostings-scheduledtasks get-scheduled-task" [
  domain_name: string
  scheduled_task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --scheduled-task-id: string # Id of the scheduled task.
]: nothing -> record<cron_expression: string, enabled: bool, id: string, script_location: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  if ($scheduled_task_id | is-empty) { error make --unspanned { msg: "path parameter 'scheduledTaskId' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "scheduled_task_id" $scheduled_task_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), scheduled_task_id: (encode-path-segment $scheduled_task_id)} | format pattern "/linuxhostings/{domain_name}/scheduledtasks/{scheduled_task_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain_name": $domain_name, "scheduled_task_id": $scheduled_task_id} | compact), body: null}
}

# Configure a scheduled task
#
# PUT /linuxhostings/{domainName}/scheduledtasks/{scheduledTaskId}
# operationId: ConfigureScheduledTask
export def "linuxhostings-scheduledtasks update-configure-scheduled-task" [
  domain_name: string
  scheduled_task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --scheduled-task-id: string # Id of the scheduled task.
  --cron-expression: string # Cron expression of scheduled task. 5-digit expressions (*/5 * * * *) are required in the following sequence:Minute (0 - 59, also */5, */10, */15 and */30 as every 5 minutes, every 10 minutes, every quarter or every half-hour are allowed)Hour (0 - 23, also * as every hour is allowed)Day of the month (1 - 31, also * as every day is allowed)Month (1 - 12 as January to December, also * as every month is allowed)Day of the week (1 - 7 as Monday to Sunday, also * as every day is allowed)
  --enabled: oneof<nothing, bool> # Enabled.
  --id: string # The id of the scheduled task. This value is ignored for creation of new scheduled tasks.
  --script-location: string # Absolute path from this linux hosting to execute.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  if ($scheduled_task_id | is-empty) { error make --unspanned { msg: "path parameter 'scheduledTaskId' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "scheduled_task_id" $scheduled_task_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), scheduled_task_id: (encode-path-segment $scheduled_task_id)} | format pattern "/linuxhostings/{domain_name}/scheduledtasks/{scheduled_task_id}") $qp)
  let req_body = {"cron_expression": $cron_expression, "enabled": $enabled, "id": $id, "script_location": $script_location} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name, "scheduled_task_id": $scheduled_task_id} | compact), body: $req_body}
}

# Enable/disable GZIP compression
#
# PUT /linuxhostings/{domainName}/settings/gzipcompression
# operationId: ChangeGzipCompression
export def "linuxhostings-settings-gzipcompression update-change-gzip-compression" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name
  --enabled: oneof<nothing, bool> # Enabled
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/linuxhostings/{domain_name}/settings/gzipcompression") $qp)
  let req_body = {"enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name} | compact), body: $req_body}
}

# Create a host header
#
# POST /linuxhostings/{domainName}/sites/{siteName}/hostheaders
# operationId: CreateHostHeader
export def "linuxhostings-sites-hostheaders create-host-header" [
  domain_name: string
  site_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --site-name: string # Name of the site on the linux hosting.
  --body-domain-name: string # Host header domain name (e.g. alias.be or alias.site.be).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  if ($site_name | is-empty) { error make --unspanned { msg: "path parameter 'siteName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "site_name" $site_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), site_name: (encode-path-segment $site_name)} | format pattern "/linuxhostings/{domain_name}/sites/{site_name}/hostheaders") $qp)
  let req_body = {"domain_name": $body_domain_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name, "site_name": $site_name} | compact), body: $req_body}
}

# Configure HTTP/2
#
# PUT /linuxhostings/{domainName}/sites/{siteName}/http2/configuration
# operationId: ConfigureHttp2
export def "linuxhostings-sites-http2-configuration update-configure" [
  domain_name: string
  site_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --site-name: string # Site name where HTTP/2 should be configured. For HTTP/2 to work correctly, the site must have ssl enabled.
  --enabled: oneof<nothing, bool> # Enable or disable HTTP/2.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  if ($site_name | is-empty) { error make --unspanned { msg: "path parameter 'siteName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "site_name" $site_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), site_name: (encode-path-segment $site_name)} | format pattern "/linuxhostings/{domain_name}/sites/{site_name}/http2/configuration") $qp)
  let req_body = {"enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name, "site_name": $site_name} | compact), body: $req_body}
}

# Configure SSH
#
# PUT /linuxhostings/{domainName}/ssh/configuration
# operationId: ConfigureSsh
export def "linuxhostings-ssh-configuration update-configure" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --enabled: oneof<nothing, bool> # Enable or disable SSH.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/linuxhostings/{domain_name}/ssh/configuration") $qp)
  let req_body = {"enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name} | compact), body: $req_body}
}

# Overview of SSH keys
#
# GET /linuxhostings/{domainName}/ssh/keys
# operationId: GetSshKeys
export def "linuxhostings-ssh-keys get" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
]: nothing -> table<fingerprint: string, public_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/linuxhostings/{domain_name}/ssh/keys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain_name": $domain_name} | compact), body: null}
}

# Add a SSH key
#
# POST /linuxhostings/{domainName}/ssh/keys
# operationId: AddSshKey
export def "linuxhostings-ssh-keys create" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --public-key: string # Public key
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/linuxhostings/{domain_name}/ssh/keys") $qp)
  let req_body = {"public_key": $public_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name} | compact), body: $req_body}
}

# Delete a SSH key
#
# DELETE /linuxhostings/{domainName}/ssh/keys/{fingerprint}
# operationId: DeleteSshKey
export def "linuxhostings-ssh-keys delete" [
  domain_name: string
  fingerprint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  if ($fingerprint | is-empty) { error make --unspanned { msg: "path parameter 'fingerprint' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), fingerprint: (encode-path-segment $fingerprint)} | format pattern "/linuxhostings/{domain_name}/ssh/keys/{fingerprint}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain_name": $domain_name} | compact), body: null}
}

# Configure auto redirect
#
# PUT /linuxhostings/{domainName}/sslsettings/{hostname}/autoredirect
# operationId: ChangeAutoRedirect
export def "linuxhostings-sslsettings-autoredirect update-change-auto-redirect" [
  domain_name: string
  hostname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --enabled: oneof<nothing, bool> # Enabled
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  if ($hostname | is-empty) { error make --unspanned { msg: "path parameter 'hostname' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), hostname: (encode-path-segment $hostname)} | format pattern "/linuxhostings/{domain_name}/sslsettings/{hostname}/autoredirect") $qp)
  let req_body = {"enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name} | compact), body: $req_body}
}

# Configure let's encrypt
#
# PUT /linuxhostings/{domainName}/sslsettings/{hostname}/letsencrypt
# operationId: ChangeLetsEncrypt
export def "linuxhostings-sslsettings-letsencrypt update-change-lets-encrypt" [
  domain_name: string
  hostname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --enabled: oneof<nothing, bool> # Enabled
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  if ($hostname | is-empty) { error make --unspanned { msg: "path parameter 'hostname' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), hostname: (encode-path-segment $hostname)} | format pattern "/linuxhostings/{domain_name}/sslsettings/{hostname}/letsencrypt") $qp)
  let req_body = {"enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name} | compact), body: $req_body}
}

# Create a subsite
#
# POST /linuxhostings/{domainName}/subsites
# operationId: CreateSubsite
export def "linuxhostings-subsites create" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --body-domain-name: string # Subsite domain name (e.g. alias.be or subsite.site.be).
  --path: string # Folder location for the subsite (when empty we use /subsites/site (e.g. /subsites/subsite.site.be) The path MUST pre-exist on the server. It WILL NOT be created automatically.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/linuxhostings/{domain_name}/subsites") $qp)
  let req_body = {"domain_name": $body_domain_name, "path": $path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name} | compact), body: $req_body}
}

# Delete a subsite
#
# DELETE /linuxhostings/{domainName}/subsites/{siteName}
# operationId: DeleteSubsite
export def "linuxhostings-subsites delete" [
  domain_name: string
  site_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --site-name: string # Name of the site on the linux hosting.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  if ($site_name | is-empty) { error make --unspanned { msg: "path parameter 'siteName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "site_name" $site_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), site_name: (encode-path-segment $site_name)} | format pattern "/linuxhostings/{domain_name}/subsites/{site_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain_name": $domain_name, "site_name": $site_name} | compact), body: null}
}

# Gets your mailboxes.
#
# GET /mailboxes
# operationId: GetMailboxes
export def "mailboxes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Obligated domain name for getting mailboxes. (nullable)
]: nothing -> table<actual_size: int, max_size: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mailboxes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain_name": $domain_name} | compact), body: null}
}

# Create a new mailbox.
#
# POST /mailboxes
# operationId: CreateMailbox
export def "mailboxes create-mailbox" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: int # Mail zone account id (format: int32)
  --email-address: string # E-mail address
  --password: string # The password for the mailbox. Passwords have to adhere to following rules:Between 8-20 characters.Must be a mix of letters and digits.Must contain at least one digit (0-9).Must contain at least one letter (a-z).Cannot contain spaces.Cannot contain characters: * € $ & + } { ' " \
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mailboxes")
  let req_body = {"account_id": $account_id, "email_address": $email_address, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a mailbox
#
# DELETE /mailboxes/{mailboxName}
# operationId: DeleteMailbox
export def "mailboxes delete-mailbox" [
  mailbox_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mailbox-name: string # Mailbox name.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mailbox_name | is-empty) { error make --unspanned { msg: "path parameter 'mailboxName' must be non-empty" } }
  let qp = [(serialize-qp "mailbox_name" $mailbox_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mailbox_name: (encode-path-segment $mailbox_name)} | format pattern "/mailboxes/{mailbox_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"mailbox_name": $mailbox_name} | compact), body: null}
}

# Get a specific mailbox
#
# GET /mailboxes/{mailboxName}
# operationId: GetMailbox
export def "mailboxes get-mailbox" [
  mailbox_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mailbox-name: string # Mailbox name.
]: nothing -> record<actual_size: int, auto_forward: record<copy_to_myself: bool, email_addresses: list<string>, enabled: bool>, auto_reply: record<enabled: bool, message: string, subject: string>, login: string, max_size: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mailbox_name | is-empty) { error make --unspanned { msg: "path parameter 'mailboxName' must be non-empty" } }
  let qp = [(serialize-qp "mailbox_name" $mailbox_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mailbox_name: (encode-path-segment $mailbox_name)} | format pattern "/mailboxes/{mailbox_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"mailbox_name": $mailbox_name} | compact), body: null}
}

# Configure auto-forward for mailbox
#
# PUT /mailboxes/{mailboxName}/autoforward
# operationId: ConfigureMailboxAutoForward
export def "mailboxes-autoforward update-configure-mailbox-auto-forward" [
  mailbox_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mailbox-name: string # Mailbox name.
  --copy-to-myself: oneof<nothing, bool> # Copy to myself
  --email-addresses: list<string> # E-mail addresses to which e-mails are forwarded
  --enabled: oneof<nothing, bool> # Enabled
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mailbox_name | is-empty) { error make --unspanned { msg: "path parameter 'mailboxName' must be non-empty" } }
  let qp = [(serialize-qp "mailbox_name" $mailbox_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mailbox_name: (encode-path-segment $mailbox_name)} | format pattern "/mailboxes/{mailbox_name}/autoforward") $qp)
  let req_body = {"copy_to_myself": $copy_to_myself, "email_addresses": $email_addresses, "enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"mailbox_name": $mailbox_name} | compact), body: $req_body}
}

# Configure auto-reply for mailbox
#
# PUT /mailboxes/{mailboxName}/autoreply
# operationId: ConfigureMailboxAutoReply
export def "mailboxes-autoreply update-configure-mailbox-auto-reply" [
  mailbox_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mailbox-name: string # Mailbox name.
  --enabled: oneof<nothing, bool> # Enabled
  --message: string # Message
  --subject: string # Subject
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mailbox_name | is-empty) { error make --unspanned { msg: "path parameter 'mailboxName' must be non-empty" } }
  let qp = [(serialize-qp "mailbox_name" $mailbox_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mailbox_name: (encode-path-segment $mailbox_name)} | format pattern "/mailboxes/{mailbox_name}/autoreply") $qp)
  let req_body = {"enabled": $enabled, "message": $message, "subject": $subject} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"mailbox_name": $mailbox_name} | compact), body: $req_body}
}

# Change password for mailbox
#
# PUT /mailboxes/{mailboxName}/password
# operationId: ChangeMailboxPassword
export def "mailboxes-password update-change-mailbox" [
  mailbox_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mailbox-name: string # Mailbox name.
  --password: string # The password for the database user. Passwords have to adhere to following rules:Between 8-20 characters.Must be a mix of letters and digits.Must contain at least one digit (0-9).Must contain at least one letter (a-z).Cannot contain spaces.Cannot contain characters: * € $ & + } { ' " \
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mailbox_name | is-empty) { error make --unspanned { msg: "path parameter 'mailboxName' must be non-empty" } }
  let qp = [(serialize-qp "mailbox_name" $mailbox_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mailbox_name: (encode-path-segment $mailbox_name)} | format pattern "/mailboxes/{mailbox_name}/password") $qp)
  let req_body = {"password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"mailbox_name": $mailbox_name} | compact), body: $req_body}
}

# Get the mail zone.
#
# GET /mailzones/{domainName}
# operationId: GetMailZone
export def "mailzones get-mail-zone" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Mail zone domain name.
]: nothing -> record<aliases: table<destinations: list, email_address: string>, anti_spam: record<allowed_types: list<string>, type: string>, available_accounts: table<account_id: int, size: int>, catch_all: record<email_addresses: list<string>>, enabled: bool, name: string, smtp_domains: table<enabled: bool, hostname: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/mailzones/{domain_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain_name": $domain_name} | compact), body: null}
}

# Create a new alias
#
# POST /mailzones/{domainName}/aliases
# operationId: CreateAlias
export def "mailzones-aliases create-alias" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Mail zone domain name.
  --destinations: list<string> # The alias destination e-mail addresses
  --email-address: string # The alias e-mail
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/mailzones/{domain_name}/aliases") $qp)
  let req_body = {"destinations": $destinations, "email_address": $email_address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name} | compact), body: $req_body}
}

# Delete a alias
#
# DELETE /mailzones/{domainName}/aliases/{emailAddress}
# operationId: DeleteAlias
export def "mailzones-aliases delete-alias" [
  domain_name: string
  email_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Mail zone domain name.
  --email-address: string # Alias e-mail address.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  if ($email_address | is-empty) { error make --unspanned { msg: "path parameter 'emailAddress' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "email_address" $email_address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), email_address: (encode-path-segment $email_address)} | format pattern "/mailzones/{domain_name}/aliases/{email_address}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain_name": $domain_name, "email_address": $email_address} | compact), body: null}
}

# Configure a alias
#
# PUT /mailzones/{domainName}/aliases/{emailAddress}
# operationId: ConfigureAlias
export def "mailzones-aliases update-configure-alias" [
  domain_name: string
  email_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Mail zone domain name.
  --email-address: string # Alias e-mail address.
  --destinations: list<string> # The alias destination e-mail addresses
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  if ($email_address | is-empty) { error make --unspanned { msg: "path parameter 'emailAddress' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "email_address" $email_address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), email_address: (encode-path-segment $email_address)} | format pattern "/mailzones/{domain_name}/aliases/{email_address}") $qp)
  let req_body = {"destinations": $destinations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name, "email_address": $email_address} | compact), body: $req_body}
}

# Configure anti-spam for mail zone
#
# PUT /mailzones/{domainName}/antispam
# operationId: ConfigureAntiSpam
export def "mailzones-antispam update-configure-anti-spam" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Mail zone domain name.
  --type: string@type-completer # Types of anti-spam scanning
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/mailzones/{domain_name}/antispam") $qp)
  let req_body = {"type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name} | compact), body: $req_body}
}

# Create a catch-all on the mail zone
#
# POST /mailzones/{domainName}/catchall
# operationId: CreateCatchAll
export def "mailzones-catchall create-catch-list" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Mail zone domain name.
  --email-address: string # E-mail address to which all e-mails are sent to inexistent mailboxes or aliases
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/mailzones/{domain_name}/catchall") $qp)
  let req_body = {"email_address": $email_address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name} | compact), body: $req_body}
}

# Delete a catch-all on the mail zone
#
# DELETE /mailzones/{domainName}/catchall/{emailAddress}
# operationId: DeleteCatchAll
export def "mailzones-catchall delete-catch-list" [
  domain_name: string
  email_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Mail zone domain name.
  --email-address: string # E-mail address to which all e-mails are sent to inexistent mailboxes or aliases.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  if ($email_address | is-empty) { error make --unspanned { msg: "path parameter 'emailAddress' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "email_address" $email_address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), email_address: (encode-path-segment $email_address)} | format pattern "/mailzones/{domain_name}/catchall/{email_address}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain_name": $domain_name, "email_address": $email_address} | compact), body: null}
}

# Create an extra smtp domain
#
# POST /mailzones/{domainName}/smtpdomains
# operationId: CreateSmtpDomain
export def "mailzones-smtpdomains create-smtp-domain" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Mail zone domain name.
  --hostname: string # The smtp domain name
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/mailzones/{domain_name}/smtpdomains") $qp)
  let req_body = {"hostname": $hostname} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name} | compact), body: $req_body}
}

# Delete an extra smtp domain
#
# DELETE /mailzones/{domainName}/smtpdomains/{hostname}
# operationId: DeleteSmtpDomain
export def "mailzones-smtpdomains delete-smtp-domain" [
  domain_name: string
  hostname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Mail zone domain name.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  if ($hostname | is-empty) { error make --unspanned { msg: "path parameter 'hostname' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), hostname: (encode-path-segment $hostname)} | format pattern "/mailzones/{domain_name}/smtpdomains/{hostname}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain_name": $domain_name} | compact), body: null}
}

# Configure an extra smtp domain
#
# PUT /mailzones/{domainName}/smtpdomains/{hostname}
# operationId: ConfigureSmtpDomain
export def "mailzones-smtpdomains update-configure-smtp-domain" [
  domain_name: string
  hostname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Mail zone domain name.
  --enabled: oneof<nothing, bool> # Enabled
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  if ($hostname | is-empty) { error make --unspanned { msg: "path parameter 'hostname' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), hostname: (encode-path-segment $hostname)} | format pattern "/mailzones/{domain_name}/smtpdomains/{hostname}") $qp)
  let req_body = {"enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain_name": $domain_name} | compact), body: $req_body}
}

# Overview of mysql databases
#
# GET /mysqldatabases
# operationId: GetMySqlDatabases
export def "mysqldatabases get-my-sql-databases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of items to skip in the resultset. (format: int32)
  --take: int # The number of items to return in the resultset. The returned count can be equal or less than this number. (format: int32)
]: nothing -> table<account_id: int, actual_size: int, hostname: string, max_size: int, name: string, user_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mysqldatabases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Create a new mysql database
#
# POST /mysqldatabases
# operationId: CreateMySqlDatabase
export def "mysqldatabases create-my-sql-database" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: int # The id of the account on which to create the database. (format: int32)
  --database-name: string # The name for the database. This will be prefixed during provisioning. The provided name during creation will be different from the provisioned database name.
  --password: string # The password for the database user. Passwords have to adhere to following rules:Between 8-20 characters.Must be a mix of letters and digits.Must contain at least one digit (0-9).Must contain at least one letter (a-z).Cannot contain spaces.Cannot contain characters: * € $ & + } { ' " \
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mysqldatabases")
  let req_body = {"account_id": $account_id, "database_name": $database_name, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a mysql database
#
# DELETE /mysqldatabases/{databaseName}
# operationId: DeleteDatabase
export def "mysqldatabases delete-database" [
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --database-name: string # Name of the database.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_name | is-empty) { error make --unspanned { msg: "path parameter 'databaseName' must be non-empty" } }
  let qp = [(serialize-qp "database_name" $database_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name)} | format pattern "/mysqldatabases/{database_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"database_name": $database_name} | compact), body: null}
}

# Get a specific database
#
# GET /mysqldatabases/{databaseName}
# operationId: GetMySqlDatabase
export def "mysqldatabases get-my-sql-database" [
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --database-name: string
]: nothing -> record<account_id: int, actual_size: int, hostname: string, max_size: int, name: string, user_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_name | is-empty) { error make --unspanned { msg: "path parameter 'databaseName' must be non-empty" } }
  let qp = [(serialize-qp "database_name" $database_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name)} | format pattern "/mysqldatabases/{database_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"database_name": $database_name} | compact), body: null}
}

# Overview of mysql users
#
# GET /mysqldatabases/{databaseName}/users
# operationId: GetDatabaseUsers
export def "mysqldatabases-users get-database" [
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --database-name: string # Name of the database.
]: nothing -> table<enabled: bool, name: string, rights: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_name | is-empty) { error make --unspanned { msg: "path parameter 'databaseName' must be non-empty" } }
  let qp = [(serialize-qp "database_name" $database_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name)} | format pattern "/mysqldatabases/{database_name}/users") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"database_name": $database_name} | compact), body: null}
}

# Create a new mysql user
#
# POST /mysqldatabases/{databaseName}/users
# operationId: CreateMySqlUser
export def "mysqldatabases-users create-my-sql" [
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --database-name: string # Name of the database.
  --name: string # User name User names have to adhere to following rules:Between 2-14 characters.Must be a mix of letters and/or digits.Must be lower cased.Cannot contain spaces.
  --password: string # The password for the database user. Passwords have to adhere to following rules:Between 8-20 characters.Must be a mix of letters and digits.Must contain at least one digit (0-9).Must contain at least one letter (a-z).Cannot contain spaces.Cannot contain characters: * € $ & + } { ' " \
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_name | is-empty) { error make --unspanned { msg: "path parameter 'databaseName' must be non-empty" } }
  let qp = [(serialize-qp "database_name" $database_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name)} | format pattern "/mysqldatabases/{database_name}/users") $qp)
  let req_body = {"name": $name, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"database_name": $database_name} | compact), body: $req_body}
}

# Delete a mysql user
#
# DELETE /mysqldatabases/{databaseName}/users/{userName}
# operationId: DeleteDatabaseUser
export def "mysqldatabases-users delete-database" [
  database_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --database-name: string # Name of the database.
  --user-name: string # Name of the user.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_name | is-empty) { error make --unspanned { msg: "path parameter 'databaseName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  let qp = [(serialize-qp "database_name" $database_name "scalar") (serialize-qp "user_name" $user_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), user_name: (encode-path-segment $user_name)} | format pattern "/mysqldatabases/{database_name}/users/{user_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"database_name": $database_name, "user_name": $user_name} | compact), body: null}
}

# Change password for mysql user
#
# PUT /mysqldatabases/{databaseName}/users/{userName}/password
# operationId: ChangeDatabaseUserPassword
export def "mysqldatabases-users-password update-change-database" [
  database_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --database-name: string # Name of the database.
  --user-name: string # Name of the user.
  --password: string # The password for the database user. Passwords have to adhere to following rules:Between 8-20 characters.Must be a mix of letters and digits.Must contain at least one digit (0-9).Must contain at least one letter (a-z).Cannot contain spaces.Cannot contain characters: * € $ & + } { ' " \
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_name | is-empty) { error make --unspanned { msg: "path parameter 'databaseName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  let qp = [(serialize-qp "database_name" $database_name "scalar") (serialize-qp "user_name" $user_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), user_name: (encode-path-segment $user_name)} | format pattern "/mysqldatabases/{database_name}/users/{user_name}/password") $qp)
  let req_body = {"password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"database_name": $database_name, "user_name": $user_name} | compact), body: $req_body}
}

# Enable/disable mysql user
#
# PUT /mysqldatabases/{databaseName}/users/{userName}/status
# operationId: ChangeDatabaseUserStatus
export def "mysqldatabases-users-status update-change-database" [
  database_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --database-name: string # Name of the database.
  --user-name: string # Name of the user.
  --enabled: oneof<nothing, bool> # Enabled
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_name | is-empty) { error make --unspanned { msg: "path parameter 'databaseName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  let qp = [(serialize-qp "database_name" $database_name "scalar") (serialize-qp "user_name" $user_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), user_name: (encode-path-segment $user_name)} | format pattern "/mysqldatabases/{database_name}/users/{user_name}/status") $qp)
  let req_body = {"enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"database_name": $database_name, "user_name": $user_name} | compact), body: $req_body}
}

# Detail of a provisioning job
#
# GET /provisioningjobs/{jobId}
export def "provisioningjobs get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --job-id: string # format: uuid
]: nothing -> record<completion: record<estimate: string>, id: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "job_id" $job_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/provisioningjobs/{job_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"job_id": $job_id} | compact), body: null}
}

# Overview of service packs
#
# GET /servicepacks
# operationId: Servicepacks
export def "servicepacks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/servicepacks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Overview of SSH keys
#
# GET /ssh
# operationId: GetAllSshKeys
export def "ssh get-list-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of items to skip in the resultset. (format: int32)
  --take: int # The number of items to return in the resultset. The returned count can be equal or less than this number. (format: int32)
]: nothing -> table<fingerprint: string, linux_hostings: list<string>, public_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ssh" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Overview of SSL certificate requests
#
# GET /sslcertificaterequests
# operationId: GetSslCertificateRequests
export def "sslcertificaterequests get-ssl-certificate-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of items to skip in the resultset. (format: int32)
  --take: int # The number of items to return in the resultset. The returned count can be equal or less than this number. (format: int32)
]: nothing -> table<certificate_type: string, common_name: string, id: int, order_code: string, validation_level: string, vendor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sslcertificaterequests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Add a SSL certificate request
#
# POST /sslcertificaterequests
# operationId: AddSslCertificateRequest
# --additional_validation_attributes item shape: {name?: string, value?: string}
export def "sslcertificaterequests create-ssl-certificate-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-validation-attributes: list # List of additional validation attributes for the certificate when choosing organization or extended validation. NameInfoRequiredFirstnameFirstname of the technical contactYesLastnameLastname of the technical contactYesPhonePhone of the technical contactYesEmailAddressEmail address of the technical contactYesStreetAddress street of the organizationYesNumberAddress house number of the organizationYesPostalCodeAddress postal code of the organizationYesVatCountryCodeVAT country code of the organization, ISO 3166-1 alpha-2 country codeYesOrganizationNumberBusiness number of the organizationNo — item shape: {name?: string, value?: string}
  --certificate-type: string@certificate-type-completer # The type of the certificate: Standard: Certificate for a single domain.Multi domain: Certificate for multiple (sub)domains belonging to the same owner.Wildcard: Certificate for all the subdomains.
  --csr: string # The certificate signing request data. The certificate signing request subject should contain following attributes:NameCodeFormatCommonNameCNValid domain name, for example site.be, alias.site.be or *.site.beCountryCISO 3166-1 alpha-2 country codeStateSTLocalityLOrganizationOEmailAddressEValid email address The certificate signing request should also contain all the additional aliases and domains (SAN's) for the certificate.
  --validation-level: string@validation-level-completer # The validation level of the certificate: Domain validated: Basic check of the identity of the owner of the domain name.Organization validated: Company details are verified and integrated in the certificate.Extended validated: A thorough verification of your domain name and company details.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sslcertificaterequests")
  let req_body = {"additional_validation_attributes": $additional_validation_attributes, "certificate_type": $certificate_type, "csr": $csr, "validation_level": $validation_level} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Detail of a SSL certificate request
#
# GET /sslcertificaterequests/{id}
# operationId: GetSslCertificateRequest
export def "sslcertificaterequests get-ssl-certificate-request" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<certificate_type: string, common_name: string, id: int, order_code: string, subject_alt_names: table<type: string, value: string>, validation_level: string, validations: table<auto_validated: bool, cname_validation_content: string, cname_validation_name: string, dns_name: string, email_addresses: list, file_validation_content: list, file_validation_url_http: string, file_validation_url_https: string, type: string>, vendor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sslcertificaterequests/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Verify the SSL certificate request domain validations
#
# PUT /sslcertificaterequests/{id}
# operationId: VerifySslCertificateRequestDomainValidations
export def "sslcertificaterequests verify-ssl-certificate-request-domain-validations" [
  id: int
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sslcertificaterequests/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Overview of SSL certificates
#
# GET /sslcertificates
# operationId: GetSslCertificates
export def "sslcertificates get-ssl-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of items to skip in the resultset. (format: int32)
  --take: int # The number of items to return in the resultset. The returned count can be equal or less than this number. (format: int32)
]: nothing -> table<common_name: string, expires_after: string, sha1_fingerprint: string, type: string, validation_level: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sslcertificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Detail of a SSL certificate
#
# GET /sslcertificates/{sha1Fingerprint}
# operationId: GetSslCertificate
export def "sslcertificates get-ssl-certificate" [
  sha1_fingerprint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sha1-fingerprint: string # The SHA-1 fingerprint of the certificate.
]: nothing -> record<common_name: string, expires_after: string, sha1_fingerprint: string, subject_alt_names: table<type: string, value: string>, type: string, validation_level: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sha1_fingerprint | is-empty) { error make --unspanned { msg: "path parameter 'sha1Fingerprint' must be non-empty" } }
  let qp = [(serialize-qp "sha1_fingerprint" $sha1_fingerprint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sha1_fingerprint: (encode-path-segment $sha1_fingerprint)} | format pattern "/sslcertificates/{sha1_fingerprint}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sha1_fingerprint": $sha1_fingerprint} | compact), body: null}
}

# Download a SSL certificate
#
# GET /sslcertificates/{sha1Fingerprint}/download
# operationId: DownloadCertificate
export def "sslcertificates-download download-certificate" [
  sha1_fingerprint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sha1-fingerprint: string # The SHA-1 fingerprint of the certificate.
  --file-format: string@file-format-completer # The file format of the returned file stream: PFX: Also known as PKCS #12, is a single, password protected certificate archive that contains the entire certificate chain plus the matching private key.
  --password: string # The password used to protect the certificate file.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sha1_fingerprint | is-empty) { error make --unspanned { msg: "path parameter 'sha1Fingerprint' must be non-empty" } }
  let qp = [(serialize-qp "sha1_fingerprint" $sha1_fingerprint "scalar") (serialize-qp "file_format" $file_format "scalar") (serialize-qp "password" $password "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sha1_fingerprint: (encode-path-segment $sha1_fingerprint)} | format pattern "/sslcertificates/{sha1_fingerprint}/download") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sha1_fingerprint": $sha1_fingerprint, "file_format": $file_format, "password": $password} | compact), body: null}
}

# Overview of windows hostings
#
# GET /windowshostings
# operationId: GetWindowsHostings
export def "windowshostings get-windows-hostings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of items to skip in the resultset. (format: int32)
  --take: int # The number of items to return in the resultset. The returned count can be equal or less than this number. (format: int32)
]: nothing -> table<domain_name: string, servicepack_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/windowshostings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Windows hosting detail
#
# GET /windowshostings/{domainName}
# operationId: GetWindowsHosting
export def "windowshostings get-windows-hosting" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The Windows hosting domain name.
]: nothing -> record<actual_size: int, application_pool: record<installed_net_core_runtimes: list<string>, pipeline_mode: string, runtime: string>, domain_name: string, ftp_username: string, ip: string, ip_type: string, max_size: int, mssql_database_names: list<string>, servicepack_id: int, sites: table<bindings: list, name: string, path: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/windowshostings/{domain_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain_name": $domain_name} | compact), body: null}
}
