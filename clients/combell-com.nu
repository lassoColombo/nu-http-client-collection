# Auto-generated client for Public Api vv2
# Source: https://api.apis.guru/v2/specs/combell.com/v2/openapi.json
# Auth: --token flag or $env.PUBLIC_API_TOKEN

const BASE_URL = "http://localhost/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PUBLIC_API_TOKEN | default "" }
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
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --ftp-password: string # Ftp password for the account.<br /> Applies only if the servicepack contains hosting.<br /> Passwords have to adhere to following rules:<br /><ul><li>Between 8-20 characters.</li><li>Must be a mix of letters and digits.</li><li>Must contain at least one digit (0-9).</li><li>Must contain at least one letter (a-z).</li><li>Cannot contain spaces.</li><li>Cannot contain characters: * € $ & + } { ' " \ </li></ul>
  --identifier: string # An identifier for the account.<br /> Should be a domain name for hosting accounts.
  --servicepack-id: int # The servicepack id that defines the account. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts")
  let body = {"ftp_password": $ftp_password, "identifier": $identifier, "servicepack_id": $servicepack_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: int # The id of the account. (format: int32)
]: nothing -> record<addons: table<id: int, name: string>, id: int, identifier: string, servicepack: record<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account_id" $account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: $account_id} | format pattern "/accounts/{account_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "record_name" $record_name "scalar") (serialize-qp "service" $service "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/dns/{domain_name}/records") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a record
#
# POST /dns/{domainName}/records
export def "dns-records post" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The domain name.
  --content: string # Variable data depending on the record type. <ul><li>A: the IPv4 address.</li><li>CNAME: canonical name of an alias.</li><li>MX: fully qualified domain name of a mail host.</li><li>SRV: does not apply. Data for the SRV records can be found in specific properties.</li><li>TXT: free form text data.</li><li>CAA: format should match specific values for flag, tag and ca: "{flag} {tag} {ca}".         <ul><li>The flag. The values 128 (critical) or 0 (non-critical) are expected, with 0 as the default.</li><li>The tag. A tag specifies which actions an authorized CA can take in terms of issuing SSL/TLS certificates.<br /><ul><li>The value "issue": explicitly authorizes a single certificate authority to issue a certificate (any type) for the hostname.</li><li>The value "issuewild": explicitly authorizes a single certificate authority to issue a wildcard certificate (and only wildcard) for the hostname.</li><li>The value "iodef": specifies a URL to which a certificate authority may report policy violations.</li></ul></li><li>The ca. This is the domain of the CA (Certification Authority) that has the authority to issue certificates for the domain in question. If the value is a semicolon (;), it means that no CA has the authority to issue a certificate for that domain.</li></ul></li><li>ALIAS: canonical name of an alias.</li><li>TLSA: format should match specific values for usage, selector, matching type and data: "{usage} {selector} {matching_type} {data}"         <ul><li>The usage. The first field after the TLSA text in the DNS RR, specifies how to verify the certificate.<br /><ul><li>A value of 0 is for what is commonly called CA constraint (and PKIX-TA). The certificate provided when establishing TLS must be issued by the listed root-CA or one of its intermediate CAs, with a valid certification path to a root-CA already trusted by the application doing the verification.</li><li>A value of 1 is for what is commonly called Service certificate constraint (and PKIX-EE). The certificate used must match the TLSA record exactly, and it must also pass PKIX certification path validation to a trusted root-CA.</li><li>A value of 2 is for what is commonly called Trust Anchor Assertion (and DANE-TA). The certificate used has a valid certification path pointing back to the certificate mention in this record, but there is no need for it to pass the PKIX certification path validation to a trusted root-CA.</li><li>A value of 3 is for what is commonly called Domain issued certificate (and DANE-EE). The services uses a self-signed certificate. It is not signed by anyone else, and is exactly this record.</li></ul></li><li>The selector. When connecting to the service and a certificate is received, the selector field specifies which parts of it should be checked.<br /><ul><li>A value of 0 means to select the entire certificate for matching.</li><li>A value of 1 means to select just the public key for certificate matching. Matching the public key is often sufficient, as this is likely to be unique.</li></ul></li><li>The matching type.<br /><ul><li>A type of 0 means the entire information selected is present in the certificate association data.</li><li>A type of 1 means to do a SHA-256 hash of the selected data.</li><li>A type of 2 means to do a SHA-512 hash of the selected data.</li></ul></li><li>The actual data to be matched given the settings of the other fields. This is a long text string of hexadecimal data.</li></ul></li></ul>
  --id: string # The id of the record This value is ignored for creation of new records.
  --port: int # The port for SRV records.<br /> The value MUST be a positive integer.<br /> Editing the value is not possible. You should add a new SRV record and delete the existing record. (format: int32)
  --priority: int # The priority for MX or SRV records.<br /> A lower value means more preferred.<br /> The value MUST be a positive integer less or equal to 9999. (format: int32, default: 10)
  --protocol: string # Used for the creation of SRV records. Possible options: TCP, UDP, ...<br /> Editing the value is not possible. You should add a new SRV record and delete the existing record. (default: TCP)
  --record-name: string # The name of the record.<br /> This is the host name, alias defined by the record.<br /> An empty record or '@' is equal to the domain name.<br /> Applies to A, MX, CNAME, TXT, CAA, ALIAS and TLSA records.<br /> When type is TLSA the recommended value format is port number, protocol and host: _25._tcp.<br /> Does not apply for SRV records.
  --service: string # The symbolic name of the desired service for SRV records.<br /> Editing the value is not possible. You should add a new SRV record and can delete the existing record.
  --target: string # The canonical hostname of the machine providing the service for SRV records.<br /> Editing the value is not possible. You should add a new SRV record and delete the existing record.
  --ttl: int # Time to live of the record in seconds.<br /> It defines the time frame that clients can cache the information.<br /> The value MUST be between 60 and 86400. The default value is 3600 (= 1 hour). (format: int32, default: 3600)
  --type: string # The type of the record (A, MX, CNAME, SRV, TXT, CAA, ALIAS and TLSA).
  --weight: int # The weight for SRV records with the same priority.<br /> A higher value means more preferred. (format: int32, default: 0)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/dns/{domain_name}/records") $qp)
  let body = {"content": $content, "id": $id, "port": $port, "priority": $priority, "protocol": $protocol, "record_name": $record_name, "service": $service, "target": $target, "ttl": $ttl, "type": $type, "weight": $weight} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The domain name.
  --record-id: string # The id of the record.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "record_id" $record_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name, record_id: $record_id} | format pattern "/dns/{domain_name}/records/{record_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The domain name.
  --record-id: string # The id of the record.
]: nothing -> record<content: string, id: string, port: int, priority: int, protocol: string, record_name: string, service: string, target: string, ttl: int, type: string, weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "record_id" $record_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name, record_id: $record_id} | format pattern "/dns/{domain_name}/records/{record_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a record
#
# PUT /dns/{domainName}/records/{recordId}
export def "dns-records put" [
  domain_name: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The domain name.
  --record-id: string # The id of the record.
  --content: string # Variable data depending on the record type. <ul><li>A: the IPv4 address.</li><li>CNAME: canonical name of an alias.</li><li>MX: fully qualified domain name of a mail host.</li><li>SRV: does not apply. Data for the SRV records can be found in specific properties.</li><li>TXT: free form text data.</li><li>CAA: format should match specific values for flag, tag and ca: "{flag} {tag} {ca}".         <ul><li>The flag. The values 128 (critical) or 0 (non-critical) are expected, with 0 as the default.</li><li>The tag. A tag specifies which actions an authorized CA can take in terms of issuing SSL/TLS certificates.<br /><ul><li>The value "issue": explicitly authorizes a single certificate authority to issue a certificate (any type) for the hostname.</li><li>The value "issuewild": explicitly authorizes a single certificate authority to issue a wildcard certificate (and only wildcard) for the hostname.</li><li>The value "iodef": specifies a URL to which a certificate authority may report policy violations.</li></ul></li><li>The ca. This is the domain of the CA (Certification Authority) that has the authority to issue certificates for the domain in question. If the value is a semicolon (;), it means that no CA has the authority to issue a certificate for that domain.</li></ul></li><li>ALIAS: canonical name of an alias.</li><li>TLSA: format should match specific values for usage, selector, matching type and data: "{usage} {selector} {matching_type} {data}"         <ul><li>The usage. The first field after the TLSA text in the DNS RR, specifies how to verify the certificate.<br /><ul><li>A value of 0 is for what is commonly called CA constraint (and PKIX-TA). The certificate provided when establishing TLS must be issued by the listed root-CA or one of its intermediate CAs, with a valid certification path to a root-CA already trusted by the application doing the verification.</li><li>A value of 1 is for what is commonly called Service certificate constraint (and PKIX-EE). The certificate used must match the TLSA record exactly, and it must also pass PKIX certification path validation to a trusted root-CA.</li><li>A value of 2 is for what is commonly called Trust Anchor Assertion (and DANE-TA). The certificate used has a valid certification path pointing back to the certificate mention in this record, but there is no need for it to pass the PKIX certification path validation to a trusted root-CA.</li><li>A value of 3 is for what is commonly called Domain issued certificate (and DANE-EE). The services uses a self-signed certificate. It is not signed by anyone else, and is exactly this record.</li></ul></li><li>The selector. When connecting to the service and a certificate is received, the selector field specifies which parts of it should be checked.<br /><ul><li>A value of 0 means to select the entire certificate for matching.</li><li>A value of 1 means to select just the public key for certificate matching. Matching the public key is often sufficient, as this is likely to be unique.</li></ul></li><li>The matching type.<br /><ul><li>A type of 0 means the entire information selected is present in the certificate association data.</li><li>A type of 1 means to do a SHA-256 hash of the selected data.</li><li>A type of 2 means to do a SHA-512 hash of the selected data.</li></ul></li><li>The actual data to be matched given the settings of the other fields. This is a long text string of hexadecimal data.</li></ul></li></ul>
  --id: string # The id of the record This value is ignored for creation of new records.
  --port: int # The port for SRV records.<br /> The value MUST be a positive integer.<br /> Editing the value is not possible. You should add a new SRV record and delete the existing record. (format: int32)
  --priority: int # The priority for MX or SRV records.<br /> A lower value means more preferred.<br /> The value MUST be a positive integer less or equal to 9999. (format: int32, default: 10)
  --protocol: string # Used for the creation of SRV records. Possible options: TCP, UDP, ...<br /> Editing the value is not possible. You should add a new SRV record and delete the existing record. (default: TCP)
  --record-name: string # The name of the record.<br /> This is the host name, alias defined by the record.<br /> An empty record or '@' is equal to the domain name.<br /> Applies to A, MX, CNAME, TXT, CAA, ALIAS and TLSA records.<br /> When type is TLSA the recommended value format is port number, protocol and host: _25._tcp.<br /> Does not apply for SRV records.
  --service: string # The symbolic name of the desired service for SRV records.<br /> Editing the value is not possible. You should add a new SRV record and can delete the existing record.
  --target: string # The canonical hostname of the machine providing the service for SRV records.<br /> Editing the value is not possible. You should add a new SRV record and delete the existing record.
  --ttl: int # Time to live of the record in seconds.<br /> It defines the time frame that clients can cache the information.<br /> The value MUST be between 60 and 86400. The default value is 3600 (= 1 hour). (format: int32, default: 3600)
  --type: string # The type of the record (A, MX, CNAME, SRV, TXT, CAA, ALIAS and TLSA).
  --weight: int # The weight for SRV records with the same priority.<br /> A higher value means more preferred. (format: int32, default: 0)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "record_id" $record_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name, record_id: $record_id} | format pattern "/dns/{domain_name}/records/{record_id}") $qp)
  let body = {"content": $content, "id": $id, "port": $port, "priority": $priority, "protocol": $protocol, "record_name": $record_name, "service": $service, "target": $target, "ttl": $ttl, "type": $type, "weight": $weight} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The domain name to register.<br /> Only pass the domain part and the tld.<br /><i>For abc.com, abc is the domain part, com is the tld.</i>
  --name-servers: list # List of name servers. When empty, the registation will be done on default name servers.
  --registrant: record # shape: {address?: string, city?: string, company_name?: string, country_code?: string, email?: string, enterprise_number?: string, extra_fields?: list, fax?: string, first_name?: string, language_code?: string, last_name?: string, phone?: string, postal_code?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domains/registrations")
  let body = {"domain_name": $domain_name, "name_servers": $name_servers, "registrant": $registrant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Transfer a domain
#
# POST /domains/transfers
# operationId: Transfer
# --registrant shape: {address?: string, city?: string, company_name?: string, country_code?: string, email?: string, enterprise_number?: string, extra_fields?: list, fax?: string, first_name?: string, language_code?: string, last_name?: string, phone?: string, postal_code?: string}
export def "domains-transfers post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-code: string # Authorization code which allows the transfer to execute.
  --domain-name: string # The domain name to transfer.<br /> Only pass the domain part and the tld.<br /><i>For abc.com, abc is the domain part, com is the tld.</i>
  --name-servers: list # List of name servers. When empty, the transfer will be done on default name servers.
  --registrant: record # shape: {address?: string, city?: string, company_name?: string, country_code?: string, email?: string, enterprise_number?: string, extra_fields?: list, fax?: string, first_name?: string, language_code?: string, last_name?: string, phone?: string, postal_code?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domains/transfers")
  let body = {"auth_code": $auth_code, "domain_name": $domain_name, "name_servers": $name_servers, "registrant": $registrant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The domain name
]: nothing -> record<can_toggle_renew: bool, domain_name: string, expiration_date: string, name_servers: table<ip: string, name: string>, registrant: record<address: string, city: string, company_name: string, country_code: string, email: string, enterprise_number: string, fax: string, first_name: string, language_code: string, last_name: string, phone: string, postal_code: string>, will_renew: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/domains/{domain_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit domain name servers
#
# PUT /domains/{domainName}/nameservers
# operationId: EditNameServers
export def "domains-nameservers put" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The domain name
  --body-domain-name: string # The domain name to register.
  --name-servers: list # List of name servers.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/domains/{domain_name}/nameservers") $qp)
  let body = {"domain_name": $body_domain_name, "name_servers": $name_servers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Edit domain name renew state
#
# PUT /domains/{domainName}/renew
# operationId: ConfigureDomain
export def "domains-renew put" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The domain name
  --will-renew: oneof<nothing, bool> # Indication of renewal.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/domains/{domain_name}/renew") $qp)
  let body = {"will_renew": $will_renew} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Overview of linux hostings
#
# GET /linuxhostings
# operationId: GetLinuxHostings
export def "linuxhostings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Linux hosting detail
#
# GET /linuxhostings/{domainName}
# operationId: GetLinuxHosting
export def "linuxhostings get" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The Linux hosting domain name.
]: nothing -> record<actual_size: int, domain_name: string, ftp_enabled: bool, ftp_username: string, ip: string, ip_type: string, max_size: int, max_webspace_size: int, mysql_database_names: list<string>, php_version: string, servicepack_id: int, sites: table<host_headers: list, http2_enabled: bool, https_redirect_enabled: bool, name: string, path: string, ssl_enabled: bool>, ssh_host: string, ssh_username: string, webspace_usage: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/linuxhostings/{domain_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure FTP
#
# PUT /linuxhostings/{domainName}/ftp/configuration
# operationId: ConfigureFtp
export def "linuxhostings-ftp-configuration put" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --enabled: oneof<nothing, bool> # Enable or disable FTP.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/linuxhostings/{domain_name}/ftp/configuration") $qp)
  let body = {"enabled": $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Configure PHP APCu setting
#
# PUT /linuxhostings/{domainName}/phpsettings/apcu
# operationId: ChangeApcu
export def "linuxhostings-phpsettings-apcu put" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name
  --apcu-size: int # The APcu size. (format: int32)
  --enabled: oneof<nothing, bool> # Enables or disables APC.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/linuxhostings/{domain_name}/phpsettings/apcu") $qp)
  let body = {"apcu_size": $apcu_size, "enabled": $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
]: nothing -> table<version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/linuxhostings/{domain_name}/phpsettings/availableversions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure PHP memory limit
#
# PUT /linuxhostings/{domainName}/phpsettings/memorylimit
# operationId: ChangePhpMemoryLimit
export def "linuxhostings-phpsettings-memorylimit put" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --memory-limit: int # The php memory limit (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/linuxhostings/{domain_name}/phpsettings/memorylimit") $qp)
  let body = {"memory_limit": $memory_limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Change the Linux hosting PHP version.
#
# PUT /linuxhostings/{domainName}/phpsettings/version
# operationId: ChangePhpVersion
export def "linuxhostings-phpsettings-version put" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --version: string # Php version
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/linuxhostings/{domain_name}/phpsettings/version") $qp)
  let body = {"version": $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Overview of scheduled tasks
#
# GET /linuxhostings/{domainName}/scheduledtasks
# operationId: GetScheduledTasks
export def "linuxhostings-scheduledtasks list" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
]: nothing -> table<cron_expression: string, enabled: bool, id: string, script_location: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/linuxhostings/{domain_name}/scheduledtasks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a scheduled task
#
# POST /linuxhostings/{domainName}/scheduledtasks
# operationId: AddScheduledTasks
export def "linuxhostings-scheduledtasks create" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --cron-expression: string # Cron expression of scheduled task.<br /> 5-digit expressions (*/5 * * * *) are required in the following sequence:<br /><ul><li>Minute (0 - 59, also */5, */10, */15 and */30 as every 5 minutes, every 10 minutes, every quarter or every half-hour are allowed)</li><li>Hour (0 - 23, also * as every hour is allowed)</li><li>Day of the month (1 - 31, also * as every day is allowed)</li><li>Month (1 - 12 as January to December, also * as every month is allowed)</li><li>Day of the week (1 - 7 as Monday to Sunday, also * as every day is allowed)</li></ul>
  --enabled: oneof<nothing, bool> # Enabled.
  --id: string # The id of the scheduled task.<br /> This value is ignored for creation of new scheduled tasks.
  --script-location: string # Absolute path from this linux hosting to execute.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/linuxhostings/{domain_name}/scheduledtasks") $qp)
  let body = {"cron_expression": $cron_expression, "enabled": $enabled, "id": $id, "script_location": $script_location} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a scheduled task
#
# DELETE /linuxhostings/{domainName}/scheduledtasks/{scheduledTaskId}
# operationId: DeleteScheduledTask
export def "linuxhostings-scheduledtasks delete" [
  domain_name: string
  scheduled_task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --scheduled-task-id: string # Id of the scheduled task.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "scheduled_task_id" $scheduled_task_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name, scheduled_task_id: $scheduled_task_id} | format pattern "/linuxhostings/{domain_name}/scheduledtasks/{scheduled_task_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get scheduled task detail
#
# GET /linuxhostings/{domainName}/scheduledtasks/{scheduledTaskId}
# operationId: GetScheduledTask
export def "linuxhostings-scheduledtasks get" [
  domain_name: string
  scheduled_task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --scheduled-task-id: string # Id of the scheduled task.
]: nothing -> record<cron_expression: string, enabled: bool, id: string, script_location: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "scheduled_task_id" $scheduled_task_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name, scheduled_task_id: $scheduled_task_id} | format pattern "/linuxhostings/{domain_name}/scheduledtasks/{scheduled_task_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure a scheduled task
#
# PUT /linuxhostings/{domainName}/scheduledtasks/{scheduledTaskId}
# operationId: ConfigureScheduledTask
export def "linuxhostings-scheduledtasks put" [
  domain_name: string
  scheduled_task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --scheduled-task-id: string # Id of the scheduled task.
  --cron-expression: string # Cron expression of scheduled task.<br /> 5-digit expressions (*/5 * * * *) are required in the following sequence:<br /><ul><li>Minute (0 - 59, also */5, */10, */15 and */30 as every 5 minutes, every 10 minutes, every quarter or every half-hour are allowed)</li><li>Hour (0 - 23, also * as every hour is allowed)</li><li>Day of the month (1 - 31, also * as every day is allowed)</li><li>Month (1 - 12 as January to December, also * as every month is allowed)</li><li>Day of the week (1 - 7 as Monday to Sunday, also * as every day is allowed)</li></ul>
  --enabled: oneof<nothing, bool> # Enabled.
  --id: string # The id of the scheduled task.<br /> This value is ignored for creation of new scheduled tasks.
  --script-location: string # Absolute path from this linux hosting to execute.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "scheduled_task_id" $scheduled_task_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name, scheduled_task_id: $scheduled_task_id} | format pattern "/linuxhostings/{domain_name}/scheduledtasks/{scheduled_task_id}") $qp)
  let body = {"cron_expression": $cron_expression, "enabled": $enabled, "id": $id, "script_location": $script_location} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Enable/disable GZIP compression
#
# PUT /linuxhostings/{domainName}/settings/gzipcompression
# operationId: ChangeGzipCompression
export def "linuxhostings-settings-gzipcompression put" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name
  --enabled: oneof<nothing, bool> # Enabled
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/linuxhostings/{domain_name}/settings/gzipcompression") $qp)
  let body = {"enabled": $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a host header
#
# POST /linuxhostings/{domainName}/sites/{siteName}/hostheaders
# operationId: CreateHostHeader
export def "linuxhostings-sites-hostheaders create" [
  domain_name: string
  site_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --site-name: string # Name of the site on the linux hosting.
  --body-domain-name: string # Host header domain name (e.g. alias.be or alias.site.be).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "site_name" $site_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name, site_name: $site_name} | format pattern "/linuxhostings/{domain_name}/sites/{site_name}/hostheaders") $qp)
  let body = {"domain_name": $body_domain_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Configure HTTP/2
#
# PUT /linuxhostings/{domainName}/sites/{siteName}/http2/configuration
# operationId: ConfigureHttp2
export def "linuxhostings-sites-http2-configuration put" [
  domain_name: string
  site_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --site-name: string # Site name where HTTP/2 should be configured.<br /> For HTTP/2 to work correctly, the site must have ssl enabled.
  --enabled: oneof<nothing, bool> # Enable or disable HTTP/2.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "site_name" $site_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name, site_name: $site_name} | format pattern "/linuxhostings/{domain_name}/sites/{site_name}/http2/configuration") $qp)
  let body = {"enabled": $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Configure SSH
#
# PUT /linuxhostings/{domainName}/ssh/configuration
# operationId: ConfigureSsh
export def "linuxhostings-ssh-configuration put" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --enabled: oneof<nothing, bool> # Enable or disable SSH.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/linuxhostings/{domain_name}/ssh/configuration") $qp)
  let body = {"enabled": $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
]: nothing -> table<fingerprint: string, public_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/linuxhostings/{domain_name}/ssh/keys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --public-key: string # Public key
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/linuxhostings/{domain_name}/ssh/keys") $qp)
  let body = {"public_key": $public_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name, fingerprint: $fingerprint} | format pattern "/linuxhostings/{domain_name}/ssh/keys/{fingerprint}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure auto redirect
#
# PUT /linuxhostings/{domainName}/sslsettings/{hostname}/autoredirect
# operationId: ChangeAutoRedirect
export def "linuxhostings-sslsettings-autoredirect put" [
  domain_name: string
  hostname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --enabled: oneof<nothing, bool> # Enabled
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name, hostname: $hostname} | format pattern "/linuxhostings/{domain_name}/sslsettings/{hostname}/autoredirect") $qp)
  let body = {"enabled": $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Configure let's encrypt
#
# PUT /linuxhostings/{domainName}/sslsettings/{hostname}/letsencrypt
# operationId: ChangeLetsEncrypt
export def "linuxhostings-sslsettings-letsencrypt put" [
  domain_name: string
  hostname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --enabled: oneof<nothing, bool> # Enabled
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name, hostname: $hostname} | format pattern "/linuxhostings/{domain_name}/sslsettings/{hostname}/letsencrypt") $qp)
  let body = {"enabled": $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --body-domain-name: string # Subsite domain name (e.g. alias.be or subsite.site.be).
  --path: string # Folder location for the subsite (when empty we use /subsites/site (e.g. /subsites/subsite.site.be)<br /> The path MUST pre-exist on the server. It WILL NOT be created automatically.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/linuxhostings/{domain_name}/subsites") $qp)
  let body = {"domain_name": $body_domain_name, "path": $path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Linux hosting domain name.
  --site-name: string # Name of the site on the linux hosting.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "site_name" $site_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name, site_name: $site_name} | format pattern "/linuxhostings/{domain_name}/subsites/{site_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Obligated domain name for getting mailboxes. (nullable)
]: nothing -> table<actual_size: int, max_size: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mailboxes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: int # Mail zone account id (format: int32)
  --email-address: string # E-mail address
  --password: string # The password for the mailbox.<br /> Passwords have to adhere to following rules:<br /><ul><li>Between 8-20 characters.</li><li>Must be a mix of letters and digits.</li><li>Must contain at least one digit (0-9).</li><li>Must contain at least one letter (a-z).</li><li>Cannot contain spaces.</li><li>Cannot contain characters: * € $ & + } { ' " \ </li></ul>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mailboxes")
  let body = {"account_id": $account_id, "email_address": $email_address, "password": $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --mailbox-name: string # Mailbox name.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mailbox_name" $mailbox_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mailbox_name: $mailbox_name} | format pattern "/mailboxes/{mailbox_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --mailbox-name: string # Mailbox name.
]: nothing -> record<actual_size: int, auto_forward: record<copy_to_myself: bool, email_addresses: list<string>, enabled: bool>, auto_reply: record<enabled: bool, message: string, subject: string>, login: string, max_size: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mailbox_name" $mailbox_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mailbox_name: $mailbox_name} | format pattern "/mailboxes/{mailbox_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure auto-forward for mailbox
#
# PUT /mailboxes/{mailboxName}/autoforward
# operationId: ConfigureMailboxAutoForward
export def "mailboxes-autoforward put" [
  mailbox_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mailbox-name: string # Mailbox name.
  --copy-to-myself: oneof<nothing, bool> # Copy to myself
  --email-addresses: list # E-mail addresses to which e-mails are forwarded
  --enabled: oneof<nothing, bool> # Enabled
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mailbox_name" $mailbox_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mailbox_name: $mailbox_name} | format pattern "/mailboxes/{mailbox_name}/autoforward") $qp)
  let body = {"copy_to_myself": $copy_to_myself, "email_addresses": $email_addresses, "enabled": $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Configure auto-reply for mailbox
#
# PUT /mailboxes/{mailboxName}/autoreply
# operationId: ConfigureMailboxAutoReply
export def "mailboxes-autoreply put" [
  mailbox_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mailbox-name: string # Mailbox name.
  --enabled: oneof<nothing, bool> # Enabled
  --message: string # Message
  --subject: string # Subject
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mailbox_name" $mailbox_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mailbox_name: $mailbox_name} | format pattern "/mailboxes/{mailbox_name}/autoreply") $qp)
  let body = {"enabled": $enabled, "message": $message, "subject": $subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Change password for mailbox
#
# PUT /mailboxes/{mailboxName}/password
# operationId: ChangeMailboxPassword
export def "mailboxes-password put" [
  mailbox_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mailbox-name: string # Mailbox name.
  --password: string # The password for the database user.<br /> Passwords have to adhere to following rules:<br /><ul><li>Between 8-20 characters.</li><li>Must be a mix of letters and digits.</li><li>Must contain at least one digit (0-9).</li><li>Must contain at least one letter (a-z).</li><li>Cannot contain spaces.</li><li>Cannot contain characters: * € $ & + } { ' " \ </li></ul>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mailbox_name" $mailbox_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mailbox_name: $mailbox_name} | format pattern "/mailboxes/{mailbox_name}/password") $qp)
  let body = {"password": $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the mail zone.
#
# GET /mailzones/{domainName}
# operationId: GetMailZone
export def "mailzones get" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Mail zone domain name.
]: nothing -> record<aliases: table<destinations: list, email_address: string>, anti_spam: record<allowed_types: list<string>, type: string>, available_accounts: table<account_id: int, size: int>, catch_all: record<email_addresses: list<string>>, enabled: bool, name: string, smtp_domains: table<enabled: bool, hostname: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/mailzones/{domain_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Mail zone domain name.
  --destinations: list # The alias destination e-mail addresses
  --email-address: string # The alias e-mail
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/mailzones/{domain_name}/aliases") $qp)
  let body = {"destinations": $destinations, "email_address": $email_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Mail zone domain name.
  --email-address: string # Alias e-mail address.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "email_address" $email_address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name, email_address: $email_address} | format pattern "/mailzones/{domain_name}/aliases/{email_address}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure a alias
#
# PUT /mailzones/{domainName}/aliases/{emailAddress}
# operationId: ConfigureAlias
export def "mailzones-aliases put" [
  domain_name: string
  email_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Mail zone domain name.
  --email-address: string # Alias e-mail address.
  --destinations: list # The alias destination e-mail addresses
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "email_address" $email_address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name, email_address: $email_address} | format pattern "/mailzones/{domain_name}/aliases/{email_address}") $qp)
  let body = {"destinations": $destinations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Configure anti-spam for mail zone
#
# PUT /mailzones/{domainName}/antispam
# operationId: ConfigureAntiSpam
export def "mailzones-antispam put" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Mail zone domain name.
  --type: string@type-completer # Types of anti-spam scanning
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/mailzones/{domain_name}/antispam") $qp)
  let body = {"type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a catch-all on the mail zone
#
# POST /mailzones/{domainName}/catchall
# operationId: CreateCatchAll
export def "mailzones-catchall create" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Mail zone domain name.
  --email-address: string # E-mail address to which all e-mails are sent to inexistent mailboxes or aliases
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/mailzones/{domain_name}/catchall") $qp)
  let body = {"email_address": $email_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a catch-all on the mail zone
#
# DELETE /mailzones/{domainName}/catchall/{emailAddress}
# operationId: DeleteCatchAll
export def "mailzones-catchall delete" [
  domain_name: string
  email_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Mail zone domain name.
  --email-address: string # E-mail address to which all e-mails are sent to inexistent mailboxes or aliases.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar") (serialize-qp "email_address" $email_address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name, email_address: $email_address} | format pattern "/mailzones/{domain_name}/catchall/{email_address}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an extra smtp domain
#
# POST /mailzones/{domainName}/smtpdomains
# operationId: CreateSmtpDomain
export def "mailzones-smtpdomains create" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Mail zone domain name.
  --hostname: string # The smtp domain name
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/mailzones/{domain_name}/smtpdomains") $qp)
  let body = {"hostname": $hostname} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an extra smtp domain
#
# DELETE /mailzones/{domainName}/smtpdomains/{hostname}
# operationId: DeleteSmtpDomain
export def "mailzones-smtpdomains delete" [
  domain_name: string
  hostname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Mail zone domain name.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name, hostname: $hostname} | format pattern "/mailzones/{domain_name}/smtpdomains/{hostname}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure an extra smtp domain
#
# PUT /mailzones/{domainName}/smtpdomains/{hostname}
# operationId: ConfigureSmtpDomain
export def "mailzones-smtpdomains put" [
  domain_name: string
  hostname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Mail zone domain name.
  --enabled: oneof<nothing, bool> # Enabled
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name, hostname: $hostname} | format pattern "/mailzones/{domain_name}/smtpdomains/{hostname}") $qp)
  let body = {"enabled": $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: int # The id of the account on which to create the database. (format: int32)
  --database-name: string # The name for the database. This will be prefixed during provisioning. The provided name during creation will be different from the provisioned database name.
  --password: string # The password for the database user.<br /> Passwords have to adhere to following rules:<br /><ul><li>Between 8-20 characters.</li><li>Must be a mix of letters and digits.</li><li>Must contain at least one digit (0-9).</li><li>Must contain at least one letter (a-z).</li><li>Cannot contain spaces.</li><li>Cannot contain characters: * € $ & + } { ' " \ </li></ul>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mysqldatabases")
  let body = {"account_id": $account_id, "database_name": $database_name, "password": $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --database-name: string # Name of the database.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "database_name" $database_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: $database_name} | format pattern "/mysqldatabases/{database_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --database-name: string
]: nothing -> record<account_id: int, actual_size: int, hostname: string, max_size: int, name: string, user_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "database_name" $database_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: $database_name} | format pattern "/mysqldatabases/{database_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --database-name: string # Name of the database.
]: nothing -> table<enabled: bool, name: string, rights: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "database_name" $database_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: $database_name} | format pattern "/mysqldatabases/{database_name}/users") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --database-name: string # Name of the database.
  --name: string # User name<br /> User names have to adhere to following rules:<br /><ul><li>Between 2-14 characters.</li><li>Must be a mix of letters and/or digits.</li><li>Must be lower cased.</li><li>Cannot contain spaces.</li></ul>
  --password: string # The password for the database user.<br /> Passwords have to adhere to following rules:<br /><ul><li>Between 8-20 characters.</li><li>Must be a mix of letters and digits.</li><li>Must contain at least one digit (0-9).</li><li>Must contain at least one letter (a-z).</li><li>Cannot contain spaces.</li><li>Cannot contain characters: * € $ & + } { ' " \ </li></ul>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "database_name" $database_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: $database_name} | format pattern "/mysqldatabases/{database_name}/users") $qp)
  let body = {"name": $name, "password": $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --database-name: string # Name of the database.
  --user-name: string # Name of the user.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "database_name" $database_name "scalar") (serialize-qp "user_name" $user_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: $database_name, user_name: $user_name} | format pattern "/mysqldatabases/{database_name}/users/{user_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change password for mysql user
#
# PUT /mysqldatabases/{databaseName}/users/{userName}/password
# operationId: ChangeDatabaseUserPassword
export def "mysqldatabases-users-password put" [
  database_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --database-name: string # Name of the database.
  --user-name: string # Name of the user.
  --password: string # The password for the database user.<br /> Passwords have to adhere to following rules:<br /><ul><li>Between 8-20 characters.</li><li>Must be a mix of letters and digits.</li><li>Must contain at least one digit (0-9).</li><li>Must contain at least one letter (a-z).</li><li>Cannot contain spaces.</li><li>Cannot contain characters: * € $ & + } { ' " \ </li></ul>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "database_name" $database_name "scalar") (serialize-qp "user_name" $user_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: $database_name, user_name: $user_name} | format pattern "/mysqldatabases/{database_name}/users/{user_name}/password") $qp)
  let body = {"password": $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Enable/disable mysql user
#
# PUT /mysqldatabases/{databaseName}/users/{userName}/status
# operationId: ChangeDatabaseUserStatus
export def "mysqldatabases-users-status put" [
  database_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --database-name: string # Name of the database.
  --user-name: string # Name of the user.
  --enabled: oneof<nothing, bool> # Enabled
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "database_name" $database_name "scalar") (serialize-qp "user_name" $user_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: $database_name, user_name: $user_name} | format pattern "/mysqldatabases/{database_name}/users/{user_name}/status") $qp)
  let body = {"enabled": $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --job-id: string # format: uuid
]: nothing -> record<completion: record<estimate: string>, id: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "job_id" $job_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/provisioningjobs/{job_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/servicepacks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Overview of SSH keys
#
# GET /ssh
# operationId: GetAllSshKeys
export def "ssh get-all-ssh-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-validation-attributes: list # List of additional validation attributes for the certificate when choosing organization or extended validation. <table><tr><th>Name</th><th>Info</th><th>Required</th></tr><tr><td>Firstname</td><td>Firstname of the technical contact</td><td>Yes</td></tr><tr><td>Lastname</td><td>Lastname of the technical contact</td><td>Yes</td></tr><tr><td>Phone</td><td>Phone of the technical contact</td><td>Yes</td></tr><tr><td>EmailAddress</td><td>Email address of the technical contact</td><td>Yes</td></tr><tr><td>Street</td><td>Address street of the organization</td><td>Yes</td></tr><tr><td>Number</td><td>Address house number of the organization</td><td>Yes</td></tr><tr><td>PostalCode</td><td>Address postal code of the organization</td><td>Yes</td></tr><tr><td>VatCountryCode</td><td>VAT country code of the organization, ISO 3166-1 alpha-2 country code</td><td>Yes</td></tr><tr><td>OrganizationNumber</td><td>Business number of the organization</td><td>No</td></tr></table> — item shape: {name?: string, value?: string}
  --certificate-type: string@certificate-type-completer # The type of the certificate: <ul><li>Standard: Certificate for a single domain.</li><li>Multi domain: Certificate for multiple (sub)domains belonging to the same owner.</li><li>Wildcard: Certificate for all the subdomains.</li></ul>
  --csr: string # The certificate signing request data.<br /> The certificate signing request subject should contain following attributes:<br /><table><tr><th>Name</th><th>Code</th><th>Format</th></tr><tr><td>CommonName</td><td>CN</td><td>Valid domain name, for example site.be, alias.site.be or *.site.be</td></tr><tr><td>Country</td><td>C</td><td>ISO 3166-1 alpha-2 country code</td></tr><tr><td>State</td><td>ST</td><td></td></tr><tr><td>Locality</td><td>L</td><td></td></tr><tr><td>Organization</td><td>O</td><td></td></tr><tr><td>EmailAddress</td><td>E</td><td>Valid email address</td></tr></table> The certificate signing request should also contain all the additional aliases and domains (SAN's) for the certificate.
  --validation-level: string@validation-level-completer # The validation level of the certificate: <ul><li>Domain validated: Basic check of the identity of the owner of the domain name.</li><li>Organization validated: Company details are verified and integrated in the certificate.</li><li>Extended validated: A thorough verification of your domain name and company details.</li></ul>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sslcertificaterequests")
  let body = {"additional_validation_attributes": $additional_validation_attributes, "certificate_type": $certificate_type, "csr": $csr, "validation_level": $validation_level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<certificate_type: string, common_name: string, id: int, order_code: string, subject_alt_names: table<type: string, value: string>, validation_level: string, validations: table<auto_validated: bool, cname_validation_content: string, cname_validation_name: string, dns_name: string, email_addresses: list, file_validation_content: list, file_validation_url_http: string, file_validation_url_https: string, type: string>, vendor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/sslcertificaterequests/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/sslcertificaterequests/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Overview of SSL certificates
#
# GET /sslcertificates
# operationId: GetSslCertificates
export def "sslcertificates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detail of a SSL certificate
#
# GET /sslcertificates/{sha1Fingerprint}
# operationId: GetSslCertificate
export def "sslcertificates get" [
  sha1_fingerprint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sha1-fingerprint: string # The SHA-1 fingerprint of the certificate.
]: nothing -> record<common_name: string, expires_after: string, sha1_fingerprint: string, subject_alt_names: table<type: string, value: string>, type: string, validation_level: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sha1_fingerprint" $sha1_fingerprint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sha1_fingerprint: $sha1_fingerprint} | format pattern "/sslcertificates/{sha1_fingerprint}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --sha1-fingerprint: string # The SHA-1 fingerprint of the certificate.
  --file-format: string@file-format-completer # The file format of the returned file stream: <ul><li>PFX: Also known as PKCS #12, is a single, password protected certificate archive that contains the entire certificate chain plus the matching private key.</li></ul>
  --password: string # The password used to protect the certificate file.<br />
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sha1_fingerprint" $sha1_fingerprint "scalar") (serialize-qp "file_format" $file_format "scalar") (serialize-qp "password" $password "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sha1_fingerprint: $sha1_fingerprint} | format pattern "/sslcertificates/{sha1_fingerprint}/download") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The Windows hosting domain name.
]: nothing -> record<actual_size: int, application_pool: record<installed_net_core_runtimes: list<string>, pipeline_mode: string, runtime: string>, domain_name: string, ftp_username: string, ip: string, ip_type: string, max_size: int, mssql_database_names: list<string>, servicepack_id: int, sites: table<bindings: list, name: string, path: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_name" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: $domain_name} | format pattern "/windowshostings/{domain_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
