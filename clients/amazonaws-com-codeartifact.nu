# Auto-generated client for CodeArtifact v2018-09-22
# Source: https://api.apis.guru/v2/specs/amazonaws.com/codeartifact/2018-09-22/openapi.json
# Auth: --token flag or $env.CODEARTIFACT_TOKEN

const BASE_URL = "http://codeartifact.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CODEARTIFACT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["http://codeartifact.us-east-1.amazonaws.com" "http://codeartifact.us-east-2.amazonaws.com" "http://codeartifact.us-west-1.amazonaws.com" "http://codeartifact.us-west-2.amazonaws.com" "http://codeartifact.us-gov-west-1.amazonaws.com" "http://codeartifact.us-gov-east-1.amazonaws.com" "http://codeartifact.ca-central-1.amazonaws.com" "http://codeartifact.eu-north-1.amazonaws.com" "http://codeartifact.eu-west-1.amazonaws.com" "http://codeartifact.eu-west-2.amazonaws.com" "http://codeartifact.eu-west-3.amazonaws.com" "http://codeartifact.eu-central-1.amazonaws.com" "http://codeartifact.eu-south-1.amazonaws.com" "http://codeartifact.af-south-1.amazonaws.com" "http://codeartifact.ap-northeast-1.amazonaws.com" "http://codeartifact.ap-northeast-2.amazonaws.com" "http://codeartifact.ap-northeast-3.amazonaws.com" "http://codeartifact.ap-southeast-1.amazonaws.com" "http://codeartifact.ap-southeast-2.amazonaws.com" "http://codeartifact.ap-east-1.amazonaws.com" "http://codeartifact.ap-south-1.amazonaws.com" "http://codeartifact.sa-east-1.amazonaws.com" "http://codeartifact.me-south-1.amazonaws.com" "https://codeartifact.us-east-1.amazonaws.com" "https://codeartifact.us-east-2.amazonaws.com" "https://codeartifact.us-west-1.amazonaws.com" "https://codeartifact.us-west-2.amazonaws.com" "https://codeartifact.us-gov-west-1.amazonaws.com" "https://codeartifact.us-gov-east-1.amazonaws.com" "https://codeartifact.ca-central-1.amazonaws.com" "https://codeartifact.eu-north-1.amazonaws.com" "https://codeartifact.eu-west-1.amazonaws.com" "https://codeartifact.eu-west-2.amazonaws.com" "https://codeartifact.eu-west-3.amazonaws.com" "https://codeartifact.eu-central-1.amazonaws.com" "https://codeartifact.eu-south-1.amazonaws.com" "https://codeartifact.af-south-1.amazonaws.com" "https://codeartifact.ap-northeast-1.amazonaws.com" "https://codeartifact.ap-northeast-2.amazonaws.com" "https://codeartifact.ap-northeast-3.amazonaws.com" "https://codeartifact.ap-southeast-1.amazonaws.com" "https://codeartifact.ap-southeast-2.amazonaws.com" "https://codeartifact.ap-east-1.amazonaws.com" "https://codeartifact.ap-south-1.amazonaws.com" "https://codeartifact.sa-east-1.amazonaws.com" "https://codeartifact.me-south-1.amazonaws.com" "http://codeartifact.cn-north-1.amazonaws.com.cn" "http://codeartifact.cn-northwest-1.amazonaws.com.cn" "https://codeartifact.cn-north-1.amazonaws.com.cn" "https://codeartifact.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def format-completer [] { ["generic" "maven" "npm" "nuget" "pypi"] }
def expected-status-completer [] { ["Archived" "Deleted" "Disposed" "Published" "Unfinished" "Unlisted"] }
def status-completer [] { ["Archived" "Deleted" "Disposed" "Published" "Unfinished" "Unlisted"] }
def sort-by-completer [] { ["PUBLISHED_TIME"] }
def origin-type-completer [] { ["EXTERNAL" "INTERNAL" "UNKNOWN"] }
def publish-completer [] { ["ALLOW" "BLOCK"] }
def upstream-completer [] { ["ALLOW" "BLOCK"] }
def target-status-completer [] { ["Archived" "Deleted" "Disposed" "Published" "Unfinished" "Unlisted"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "repository-external-connection create-associate" } } | get name | first)
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

# Adds an existing external connection to a repository. One external connection is allowed per repository. A repository can have one or more upstream repositories, or an external connection.
#
# POST /v1/repository/external-connection
# operationId: AssociateExternalConnection
export def "repository-external-connection create-associate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository to which the external connection is added.
  --external-connection: string # The name of the external connection to add to the repository. The following values are supported: public:npmjs - for the npm public repository. public:nuget-org - for the NuGet Gallery. public:pypi - for the Python Package Index. public:maven-central - for Maven Central. public:maven-googleandroid - for the Google Android repository. public:maven-gradleplugins - for the Gradle plugins repository. public:maven-commonsware - for the CommonsWare Android repository. public:maven-clojars - for the Clojars repository.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<repository: record<name: record, administratorAccount: record, domainName: record, domainOwner: record, arn: record, description: record, upstreams: record, externalConnections: record, createdTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar") (serialize-qp "external-connection" $external_connection "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/repository/external-connection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository, "external-connection": $external_connection} | compact), body: null}
}

# Removes an existing external connection from a repository.
#
# DELETE /v1/repository/external-connection
# operationId: DisassociateExternalConnection
export def "repository-external-connection delete-disassociate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository from which to remove the external repository.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository from which the external connection will be removed.
  --external-connection: string # The name of the external connection to be removed from the repository.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<repository: record<name: record, administratorAccount: record, domainName: record, domainOwner: record, arn: record, description: record, upstreams: record, externalConnections: record, createdTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar") (serialize-qp "external-connection" $external_connection "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/repository/external-connection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository, "external-connection": $external_connection} | compact), body: null}
}

# Copies package versions from one repository to another repository in the same domain. You must specify versions or versionRevisions. You cannot specify both.
#
# POST /v1/package/versions/copy
# operationId: CopyPackageVersions
export def "package-versions-copy copy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the source and destination repositories.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --source-repository: string # The name of the repository that contains the package versions to be copied.
  --destination-repository: string # The name of the repository into which package versions are copied.
  --format: string@format-completer # The format of the package versions to be copied.
  --namespace: string # The namespace of the package versions to be copied. The package version component that specifies its namespace depends on its type. For example: The namespace of a Maven package version is its groupId. The namespace is required when copying Maven package versions. The namespace of an npm package version is its scope. Python and NuGet package versions do not contain a corresponding component, package versions of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the package that contains the versions to be copied.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --versions: list<string> # The versions of the package to be copied. You must specify versions or versionRevisions. You cannot specify both.
  --version-revisions: record # A list of key-value pairs. The keys are package versions and the values are package version revisions. A CopyPackageVersion operation succeeds if the specified versions in the source repository match the specified package version revision. You must specify versions or versionRevisions. You cannot specify both.
  --allow-overwrite: oneof<nothing, bool> # Set to true to overwrite a package version that already exists in the destination repository. If set to false and the package version already exists in the destination repository, the package version is returned in the failedVersions field of the response with an ALREADY_EXISTS error code.
  --include-from-upstream: oneof<nothing, bool> # Set to true to copy packages from repositories that are upstream from the source repository to the destination repository. The default setting is false. For more information, see Working with upstream repositories (https://docs.aws.amazon.com/codeartifact/latest/ug/repos-upstream.html).
]: any -> record<successfulVersions: record, failedVersions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "source-repository" $source_repository "scalar") (serialize-qp "destination-repository" $destination_repository "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "package" $package "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/package/versions/copy" $qp)
  let req_body = {"versions": $versions, "versionRevisions": $version_revisions, "allowOverwrite": $allow_overwrite, "includeFromUpstream": $include_from_upstream} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain": $domain, "domain-owner": $domain_owner, "source-repository": $source_repository, "destination-repository": $destination_repository, "format": $format, "namespace": $namespace, "package": $package} | compact), body: $req_body}
}

# Creates a domain. CodeArtifact domains make it easier to manage multiple repositories across an organization. You can use a domain to apply permissions across many repositories owned by different Amazon Web Services accounts. An asset is stored only once in a domain, even if it's in multiple repositories. Although you can have multiple domains, we recommend a single production domain that contains all published artifacts so that your development teams can find and share packages. You can use a second pre-production domain to test changes to the production domain configuration.
#
# POST /v1/domain
# operationId: CreateDomain
# --tags item shape: {key: any, value: any}
export def "domain create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain to create. All domain names in an Amazon Web Services Region that are in the same Amazon Web Services account must be unique. The domain name is used as the prefix in DNS hostnames. Do not use sensitive information in a domain name because it is publicly discoverable.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --encryption-key: string # The encryption key for the domain. This is used to encrypt content stored in a domain. An encryption key can be a key ID, a key Amazon Resource Name (ARN), a key alias, or a key alias ARN. To specify an encryptionKey, your IAM role must have kms:DescribeKey and kms:CreateGrant permissions on the encryption key that is used. For more information, see DescribeKey (https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestSyntax) in the Key Management Service API Reference and Key Management Service API Permissions Reference (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) in the Key Management Service Developer Guide. CodeArtifact supports only symmetric CMKs. Do not associate an asymmetric CMK with your domain. For more information, see Using symmetric and asymmetric keys (https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html) in the Key Management Service Developer Guide.
  --tags: list # One or more tag key-value pairs for the domain. — item shape: {key: any, value: any}
]: any -> record<domain: record<name: record, owner: record, arn: record, status: record, createdTime: record, encryptionKey: record, repositoryCount: record, assetSizeBytes: record, s3BucketArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/domain" $qp)
  let req_body = {"encryptionKey": $encryption_key, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain": $domain} | compact), body: $req_body}
}

# Deletes a domain. You cannot delete a domain that contains repositories. If you want to delete a domain with repositories, first delete its repositories.
#
# DELETE /v1/domain
# operationId: DeleteDomain
export def "domain delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain to delete.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<domain: record<name: record, owner: record, arn: record, status: record, createdTime: record, encryptionKey: record, repositoryCount: record, assetSizeBytes: record, s3BucketArn: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/domain" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "domain-owner": $domain_owner} | compact), body: null}
}

# Returns a DomainDescription (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_DomainDescription.html) object that contains information about the requested domain.
#
# GET /v1/domain
# operationId: DescribeDomain
export def "domain get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # A string that specifies the name of the requested domain.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<domain: record<name: record, owner: record, arn: record, status: record, createdTime: record, encryptionKey: record, repositoryCount: record, assetSizeBytes: record, s3BucketArn: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/domain" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "domain-owner": $domain_owner} | compact), body: null}
}

# Creates a repository.
#
# POST /v1/repository
# operationId: CreateRepository
# --upstreams item shape: {repositoryName: any}
# --tags item shape: {key: any, value: any}
export def "repository create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the created repository.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository to create.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # A description of the created repository.
  --upstreams: list # A list of upstream repositories to associate with the repository. The order of the upstream repositories in the list determines their priority order when CodeArtifact looks for a requested package version. For more information, see Working with upstream repositories (https://docs.aws.amazon.com/codeartifact/latest/ug/repos-upstream.html). — item shape: {repositoryName: any}
  --tags: list # One or more tag key-value pairs for the repository. — item shape: {key: any, value: any}
]: any -> record<repository: record<name: record, administratorAccount: record, domainName: record, domainOwner: record, arn: record, description: record, upstreams: record, externalConnections: record, createdTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/repository" $qp)
  let req_body = {"description": $description, "upstreams": $upstreams, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository} | compact), body: $req_body}
}

# Deletes a repository.
#
# DELETE /v1/repository
# operationId: DeleteRepository
export def "repository delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository to delete.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository to delete.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<repository: record<name: record, administratorAccount: record, domainName: record, domainOwner: record, arn: record, description: record, upstreams: record, externalConnections: record, createdTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/repository" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository} | compact), body: null}
}

# Returns a RepositoryDescription object that contains detailed information about the requested repository.
#
# GET /v1/repository
# operationId: DescribeRepository
export def "repository get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository to describe.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # A string that specifies the name of the requested repository.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<repository: record<name: record, administratorAccount: record, domainName: record, domainOwner: record, arn: record, description: record, upstreams: record, externalConnections: record, createdTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/repository" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository} | compact), body: null}
}

# Update the properties of a repository.
#
# PUT /v1/repository
# operationId: UpdateRepository
# --upstreams item shape: {repositoryName: any}
export def "repository update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain associated with the repository to update.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository to update.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # An updated repository description.
  --upstreams: list # A list of upstream repositories to associate with the repository. The order of the upstream repositories in the list determines their priority order when CodeArtifact looks for a requested package version. For more information, see Working with upstream repositories (https://docs.aws.amazon.com/codeartifact/latest/ug/repos-upstream.html). — item shape: {repositoryName: any}
]: any -> record<repository: record<name: record, administratorAccount: record, domainName: record, domainOwner: record, arn: record, description: record, upstreams: record, externalConnections: record, createdTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/repository" $qp)
  let req_body = {"description": $description, "upstreams": $upstreams} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository} | compact), body: $req_body}
}

# Deletes the resource policy set on a domain.
#
# DELETE /v1/domain/permissions/policy
# operationId: DeleteDomainPermissionsPolicy
export def "domain-permissions-policy delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain associated with the resource policy to be deleted.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --policy-revision: string # The current revision of the resource policy to be deleted. This revision is used for optimistic locking, which prevents others from overwriting your changes to the domain's resource policy.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<policy: record<resourceArn: record, revision: record, document: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "policy-revision" $policy_revision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/domain/permissions/policy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "domain-owner": $domain_owner, "policy-revision": $policy_revision} | compact), body: null}
}

# Returns the resource policy attached to the specified domain. The policy is a resource-based policy, not an identity-based policy. For more information, see Identity-based policies and resource-based policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_identity-vs-resource.html) in the IAM User Guide.
#
# GET /v1/domain/permissions/policy
# operationId: GetDomainPermissionsPolicy
export def "domain-permissions-policy get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain to which the resource policy is attached.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<policy: record<resourceArn: record, revision: record, document: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/domain/permissions/policy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "domain-owner": $domain_owner} | compact), body: null}
}

# Deletes a package and all associated package versions. A deleted package cannot be restored. To delete one or more package versions, use the DeletePackageVersions (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_DeletePackageVersions.html) API.
#
# DELETE /v1/package
# operationId: DeletePackage
export def "package delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the package to delete.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that contains the package to delete.
  --format: string@format-completer # The format of the requested package to delete.
  --namespace: string # The namespace of the package to delete. The package component that specifies its namespace depends on its type. For example: The namespace of a Maven package is its groupId. The namespace is required when deleting Maven package versions. The namespace of an npm package is its scope. Python and NuGet packages do not contain corresponding components, packages of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the package to delete.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<deletedPackage: record<format: record, namespace: record, package: record, originConfiguration: record<restrictions: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "package" $package "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/package" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository, "format": $format, "namespace": $namespace, "package": $package} | compact), body: null}
}

# Returns a PackageDescription (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_PackageDescription.html) object that contains information about the requested package.
#
# GET /v1/package
# operationId: DescribePackage
export def "package get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository that contains the package.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that contains the requested package.
  --format: string@format-completer # A format that specifies the type of the requested package.
  --namespace: string # The namespace of the requested package. The package component that specifies its namespace depends on its type. For example: The namespace of a Maven package is its groupId. The namespace is required when requesting Maven packages. The namespace of an npm package is its scope. Python and NuGet packages do not contain a corresponding component, packages of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the requested package.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<package: record<format: record, namespace: record, name: record, originConfiguration: record<restrictions: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "package" $package "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/package" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository, "format": $format, "namespace": $namespace, "package": $package} | compact), body: null}
}

# Sets the package origin configuration for a package. The package origin configuration determines how new versions of a package can be added to a repository. You can allow or block direct publishing of new package versions, or ingestion and retaining of new package versions from an external connection or upstream source. For more information about package origin controls and configuration, see Editing package origin controls (https://docs.aws.amazon.com/codeartifact/latest/ug/package-origin-controls.html) in the CodeArtifact User Guide. PutPackageOriginConfiguration can be called on a package that doesn't yet exist in the repository. When called on a package that does not exist, a package is created in the repository with no versions and the requested restrictions are set on the package. This can be used to preemptively block ingesting or retaining any versions from external connections or upstream repositories, or to block publishing any versions of the package into the repository before connecting any package managers or publishers to the repository.
#
# POST /v1/package
# operationId: PutPackageOriginConfiguration
# --restrictions shape: {publish?: any, upstream?: any}
export def "package update-origin-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository that contains the package.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that contains the package.
  --format: string@format-completer # A format that specifies the type of the package to be updated.
  --namespace: string # The namespace of the package to be updated. The package component that specifies its namespace depends on its type. For example: The namespace of a Maven package is its groupId. The namespace of an npm package is its scope. Python and NuGet packages do not contain a corresponding component, packages of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the package to be updated.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  restrictions: record # Details about the origin restrictions set on the package. The package origin restrictions determine how new versions of a package can be added to a specific repository. — shape: {publish?: any, upstream?: any}
]: any -> record<originConfiguration: record<restrictions: record<publish: record, upstream: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "package" $package "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/package" $qp)
  let req_body = {"restrictions": $restrictions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository, "format": $format, "namespace": $namespace, "package": $package} | compact), body: $req_body}
}

# Deletes one or more versions of a package. A deleted package version cannot be restored in your repository. If you want to remove a package version from your repository and be able to restore it later, set its status to Archived. Archived packages cannot be downloaded from a repository and don't show up with list package APIs (for example, ListPackageVersions (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_ListPackageVersions.html)), but you can restore them using UpdatePackageVersionsStatus (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_UpdatePackageVersionsStatus.html).
#
# POST /v1/package/versions/delete
# operationId: DeletePackageVersions
export def "package-versions-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the package to delete.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that contains the package versions to delete.
  --format: string@format-completer # The format of the package versions to delete.
  --namespace: string # The namespace of the package versions to be deleted. The package version component that specifies its namespace depends on its type. For example: The namespace of a Maven package version is its groupId. The namespace is required when deleting Maven package versions. The namespace of an npm package version is its scope. Python and NuGet package versions do not contain a corresponding component, package versions of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the package with the versions to delete.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  versions: list<string> # An array of strings that specify the versions of the package to delete.
  --expected-status: string@expected-status-completer # The expected status of the package version to delete.
]: any -> record<successfulVersions: record, failedVersions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "package" $package "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/package/versions/delete" $qp)
  let req_body = {"versions": $versions, "expectedStatus": $expected_status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository, "format": $format, "namespace": $namespace, "package": $package} | compact), body: $req_body}
}

# Deletes the resource policy that is set on a repository. After a resource policy is deleted, the permissions allowed and denied by the deleted policy are removed. The effect of deleting a resource policy might not be immediate. Use DeleteRepositoryPermissionsPolicy with caution. After a policy is deleted, Amazon Web Services users, roles, and accounts lose permissions to perform the repository actions granted by the deleted policy.
#
# DELETE /v1/repository/permissions/policies
# operationId: DeleteRepositoryPermissionsPolicy
export def "repository-permissions-policies delete-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository associated with the resource policy to be deleted.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that is associated with the resource policy to be deleted
  --policy-revision: string # The revision of the repository's resource policy to be deleted. This revision is used for optimistic locking, which prevents others from accidentally overwriting your changes to the repository's resource policy.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<policy: record<resourceArn: record, revision: record, document: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar") (serialize-qp "policy-revision" $policy_revision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/repository/permissions/policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository, "policy-revision": $policy_revision} | compact), body: null}
}

# Returns a PackageVersionDescription (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_PackageVersionDescription.html) object that contains information about the requested package version.
#
# GET /v1/package/version
# operationId: DescribePackageVersion
export def "package-version get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository that contains the package version.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that contains the package version.
  --format: string@format-completer # A format that specifies the type of the requested package version.
  --namespace: string # The namespace of the requested package version. The package version component that specifies its namespace depends on its type. For example: The namespace of a Maven package version is its groupId. The namespace of an npm package version is its scope. Python and NuGet package versions do not contain a corresponding component, package versions of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the requested package version.
  --version: string # A string that contains the package version (for example, 3.5.2).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<packageVersion: record<format: record, namespace: record, packageName: record, displayName: record, version: record, summary: record, homePage: record, sourceCodeRepository: record, publishedTime: record, licenses: record, revision: record, status: record, origin: record<domainEntryPoint: record, originType: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "package" $package "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/package/version" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository, "format": $format, "namespace": $namespace, "package": $package, "version": $version} | compact), body: null}
}

# Deletes the assets in package versions and sets the package versions' status to Disposed. A disposed package version cannot be restored in your repository because its assets are deleted. To view all disposed package versions in a repository, use ListPackageVersions (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_ListPackageVersions.html) and set the status (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_ListPackageVersions.html#API_ListPackageVersions_RequestSyntax) parameter to Disposed. To view information about a disposed package version, use DescribePackageVersion (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_DescribePackageVersion.html).
#
# POST /v1/package/versions/dispose
# operationId: DisposePackageVersions
export def "package-versions-dispose create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository you want to dispose.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that contains the package versions you want to dispose.
  --format: string@format-completer # A format that specifies the type of package versions you want to dispose.
  --namespace: string # The namespace of the package versions to be disposed. The package version component that specifies its namespace depends on its type. For example: The namespace of a Maven package version is its groupId. The namespace of an npm package version is its scope. Python and NuGet package versions do not contain a corresponding component, package versions of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the package with the versions you want to dispose.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  versions: list<string> # The versions of the package you want to dispose.
  --version-revisions: record # The revisions of the package versions you want to dispose.
  --expected-status: string@expected-status-completer # The expected status of the package version to dispose.
]: any -> record<successfulVersions: record, failedVersions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "package" $package "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/package/versions/dispose" $qp)
  let req_body = {"versions": $versions, "versionRevisions": $version_revisions, "expectedStatus": $expected_status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository, "format": $format, "namespace": $namespace, "package": $package} | compact), body: $req_body}
}

# Generates a temporary authorization token for accessing repositories in the domain. This API requires the codeartifact:GetAuthorizationToken and sts:GetServiceBearerToken permissions. For more information about authorization tokens, see CodeArtifact authentication and tokens (https://docs.aws.amazon.com/codeartifact/latest/ug/tokens-authentication.html). CodeArtifact authorization tokens are valid for a period of 12 hours when created with the login command. You can call login periodically to refresh the token. When you create an authorization token with the GetAuthorizationToken API, you can set a custom authorization period, up to a maximum of 12 hours, with the durationSeconds parameter. The authorization period begins after login or GetAuthorizationToken is called. If login or GetAuthorizationToken is called while assuming a role, the token lifetime is independent of the maximum session duration of the role. For example, if you call sts assume-role and specify a session duration of 15 minutes, then generate a CodeArtifact authorization token, the token will be valid for the full authorization period even though this is longer than the 15-minute session duration. See Using IAM Roles (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html) for more information on controlling session duration.
#
# POST /v1/authorization-token
# operationId: GetAuthorizationToken
export def "authorization-token get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that is in scope for the generated authorization token.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --duration: int # The time, in seconds, that the generated authorization token is valid. Valid values are 0 and any number between 900 (15 minutes) and 43200 (12 hours). A value of 0 will set the expiration of the authorization token to the same expiration of the user's role's temporary credentials.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<authorizationToken: record, expiration: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "duration" $duration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/authorization-token" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "domain-owner": $domain_owner, "duration": $duration} | compact), body: null}
}

# Returns an asset (or file) that is in a package. For example, for a Maven package version, use GetPackageVersionAsset to download a JAR file, a POM file, or any other assets in the package version.
#
# GET /v1/package/version/asset
# operationId: GetPackageVersionAsset
export def "package-version-asset get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository that contains the package version with the requested asset.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The repository that contains the package version with the requested asset.
  --format: string@format-completer # A format that specifies the type of the package version with the requested asset file.
  --namespace: string # The namespace of the package version with the requested asset file. The package version component that specifies its namespace depends on its type. For example: The namespace of a Maven package version is its groupId. The namespace of an npm package version is its scope. Python and NuGet package versions do not contain a corresponding component, package versions of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the package that contains the requested asset.
  --version: string # A string that contains the package version (for example, 3.5.2).
  --asset: string # The name of the requested asset.
  --revision: string # The name of the package version revision that contains the requested asset.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<asset: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "package" $package "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "asset" $asset "scalar") (serialize-qp "revision" $revision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/package/version/asset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository, "format": $format, "namespace": $namespace, "package": $package, "version": $version, "asset": $asset, "revision": $revision} | compact), body: null}
}

# Gets the readme file or descriptive text for a package version. The returned text might contain formatting. For example, it might contain formatting for Markdown or reStructuredText.
#
# GET /v1/package/version/readme
# operationId: GetPackageVersionReadme
export def "package-version-readme get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository that contains the package version with the requested readme file.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The repository that contains the package with the requested readme file.
  --format: string@format-completer # A format that specifies the type of the package version with the requested readme file.
  --namespace: string # The namespace of the package version with the requested readme file. The package version component that specifies its namespace depends on its type. For example: The namespace of an npm package version is its scope. Python and NuGet package versions do not contain a corresponding component, package versions of those formats do not have a namespace.
  --package: string # The name of the package version that contains the requested readme file.
  --version: string # A string that contains the package version (for example, 3.5.2).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<format: record, namespace: record, package: record, version: record, versionRevision: record, readme: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "package" $package "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/package/version/readme" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository, "format": $format, "namespace": $namespace, "package": $package, "version": $version} | compact), body: null}
}

# Returns the endpoint of a repository for a specific package format. A repository has one endpoint for each package format: maven npm nuget pypi
#
# GET /v1/repository/endpoint
# operationId: GetRepositoryEndpoint
export def "repository-endpoint get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain that contains the repository. It does not include dashes or spaces.
  --repository: string # The name of the repository.
  --format: string@format-completer # Returns which endpoint of a repository to return. A repository has one endpoint for each package format.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<repositoryEndpoint: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/repository/endpoint" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository, "format": $format} | compact), body: null}
}

# Returns the resource policy that is set on a repository.
#
# GET /v1/repository/permissions/policy
# operationId: GetRepositoryPermissionsPolicy
export def "repository-permissions-policy get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain containing the repository whose associated resource policy is to be retrieved.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository whose associated resource policy is to be retrieved.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<policy: record<resourceArn: record, revision: record, document: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/repository/permissions/policy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository} | compact), body: null}
}

# Sets the resource policy on a repository that specifies permissions to access it. When you call PutRepositoryPermissionsPolicy, the resource policy on the repository is ignored when evaluting permissions. This ensures that the owner of a repository cannot lock themselves out of the repository, which would prevent them from being able to update the resource policy.
#
# PUT /v1/repository/permissions/policy
# operationId: PutRepositoryPermissionsPolicy
export def "repository-permissions-policy update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain containing the repository to set the resource policy on.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository to set the resource policy on.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --policy-revision: string # Sets the revision of the resource policy that specifies permissions to access the repository. This revision is used for optimistic locking, which prevents others from overwriting your changes to the repository's resource policy.
  policy_document: string # A valid displayable JSON Aspen policy string to be set as the access control resource policy on the provided repository.
]: any -> record<policy: record<resourceArn: record, revision: record, document: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/repository/permissions/policy" $qp)
  let req_body = {"policyRevision": $policy_revision, "policyDocument": $policy_document} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository} | compact), body: $req_body}
}

# Returns a list of DomainSummary (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_PackageVersionDescription.html) objects for all domains owned by the Amazon Web Services account that makes this call. Each returned DomainSummary object contains information about a domain.
#
# POST /v1/domains
# operationId: ListDomains
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
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --max-results-body: int # The maximum number of results to return per page. (body field)
  --next-token-body: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (body field)
]: any -> record<domains: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/domains" $qp)
  let req_body = {"maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: $req_body}
}

# Returns a list of AssetSummary (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_AssetSummary.html) objects for assets in a package version.
#
# POST /v1/package/version/assets
# operationId: ListPackageVersionAssets
export def "package-version-assets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository associated with the package version assets.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that contains the package that contains the requested package version assets.
  --format: string@format-completer # The format of the package that contains the requested package version assets.
  --namespace: string # The namespace of the package version that contains the requested package version assets. The package version component that specifies its namespace depends on its type. For example: The namespace of a Maven package version is its groupId. The namespace of an npm package version is its scope. Python and NuGet package versions do not contain a corresponding component, package versions of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the package that contains the requested package version assets.
  --version: string # A string that contains the package version (for example, 3.5.2).
  --max-results: int # The maximum number of results to return per page.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<format: record, namespace: record, package: record, version: record, versionRevision: record, nextToken: record, assets: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "package" $package "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "maxResults" $max_results_2 "scalar") (serialize-qp "nextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/package/version/assets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository, "format": $format, "namespace": $namespace, "package": $package, "version": $version, "max-results": $max_results, "next-token": $next_token, "maxResults": $max_results_2, "nextToken": $next_token_2} | compact), body: null}
}

# Returns the direct dependencies for a package version. The dependencies are returned as PackageDependency (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_PackageDependency.html) objects. CodeArtifact extracts the dependencies for a package version from the metadata file for the package format (for example, the package.json file for npm packages and the pom.xml file for Maven). Any package version dependencies that are not listed in the configuration file are not returned.
#
# POST /v1/package/version/dependencies
# operationId: ListPackageVersionDependencies
export def "package-version-dependencies list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository that contains the requested package version dependencies.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that contains the requested package version.
  --format: string@format-completer # The format of the package with the requested dependencies.
  --namespace: string # The namespace of the package version with the requested dependencies. The package version component that specifies its namespace depends on its type. For example: The namespace of a Maven package version is its groupId. The namespace of an npm package version is its scope. Python and NuGet package versions do not contain a corresponding component, package versions of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the package versions' package.
  --version: string # A string that contains the package version (for example, 3.5.2).
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<format: record, namespace: record, package: record, version: record, versionRevision: record, nextToken: record, dependencies: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "package" $package "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "next-token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/package/version/dependencies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository, "format": $format, "namespace": $namespace, "package": $package, "version": $version, "next-token": $next_token} | compact), body: null}
}

# Returns a list of PackageVersionSummary (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_PackageVersionSummary.html) objects for package versions in a repository that match the request parameters. Package versions of all statuses will be returned by default when calling list-package-versions with no --status parameter.
#
# POST /v1/package/versions
# operationId: ListPackageVersions
export def "package-versions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository that contains the requested package versions.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that contains the requested package versions.
  --format: string@format-completer # The format of the package versions you want to list.
  --namespace: string # The namespace of the package that contains the requested package versions. The package component that specifies its namespace depends on its type. For example: The namespace of a Maven package is its groupId. The namespace of an npm package is its scope. Python and NuGet packages do not contain a corresponding component, packages of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the package for which you want to request package versions.
  --status: string@status-completer # A string that filters the requested package versions by status.
  --sort-by: string@sort-by-completer # How to sort the requested list of package versions.
  --max-results: int # The maximum number of results to return per page.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --origin-type: string@origin-type-completer # The originType used to filter package versions. Only package versions with the provided originType will be returned.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<defaultDisplayVersion: record, format: record, namespace: record, package: record, versions: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "package" $package "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "originType" $origin_type "scalar") (serialize-qp "maxResults" $max_results_2 "scalar") (serialize-qp "nextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/package/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository, "format": $format, "namespace": $namespace, "package": $package, "status": $status, "sortBy": $sort_by, "max-results": $max_results, "next-token": $next_token, "originType": $origin_type, "maxResults": $max_results_2, "nextToken": $next_token_2} | compact), body: null}
}

# Returns a list of PackageSummary (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_PackageSummary.html) objects for packages in a repository that match the request parameters.
#
# POST /v1/packages
# operationId: ListPackages
export def "packages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository that contains the requested packages.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that contains the requested packages.
  --format: string@format-completer # The format used to filter requested packages. Only packages from the provided format will be returned.
  --namespace: string # The namespace prefix used to filter requested packages. Only packages with a namespace that starts with the provided string value are returned. Note that although this option is called --namespace and not --namespace-prefix, it has prefix-matching behavior. Each package format uses namespace as follows: The namespace of a Maven package is its groupId. The namespace of an npm package is its scope. Python and NuGet packages do not contain a corresponding component, packages of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package-prefix: string # A prefix used to filter requested packages. Only packages with names that start with packagePrefix are returned.
  --max-results: int # The maximum number of results to return per page.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --publish: string@publish-completer # The value of the Publish package origin control restriction used to filter requested packages. Only packages with the provided restriction are returned. For more information, see PackageOriginRestrictions (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_PackageOriginRestrictions.html).
  --upstream: string@upstream-completer # The value of the Upstream package origin control restriction used to filter requested packages. Only packages with the provided restriction are returned. For more information, see PackageOriginRestrictions (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_PackageOriginRestrictions.html).
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<packages: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "package-prefix" $package_prefix "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "publish" $publish "scalar") (serialize-qp "upstream" $upstream "scalar") (serialize-qp "maxResults" $max_results_2 "scalar") (serialize-qp "nextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/packages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository, "format": $format, "namespace": $namespace, "package-prefix": $package_prefix, "max-results": $max_results, "next-token": $next_token, "publish": $publish, "upstream": $upstream, "maxResults": $max_results_2, "nextToken": $next_token_2} | compact), body: null}
}

# Returns a list of RepositorySummary (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_RepositorySummary.html) objects. Each RepositorySummary contains information about a repository in the specified Amazon Web Services account and that matches the input parameters.
#
# POST /v1/repositories
# operationId: ListRepositories
export def "repositories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --repository-prefix: string # A prefix used to filter returned repositories. Only repositories with names that start with repositoryPrefix are returned.
  --max-results: int # The maximum number of results to return per page.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<repositories: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "repository-prefix" $repository_prefix "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "maxResults" $max_results_2 "scalar") (serialize-qp "nextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/repositories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"repository-prefix": $repository_prefix, "max-results": $max_results, "next-token": $next_token, "maxResults": $max_results_2, "nextToken": $next_token_2} | compact), body: null}
}

# Returns a list of RepositorySummary (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_RepositorySummary.html) objects. Each RepositorySummary contains information about a repository in the specified domain and that matches the input parameters.
#
# POST /v1/domain/repositories
# operationId: ListRepositoriesInDomain
export def "domain-repositories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the returned list of repositories.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --administrator-account: string # Filter the list of repositories to only include those that are managed by the Amazon Web Services account ID.
  --repository-prefix: string # A prefix used to filter returned repositories. Only repositories with names that start with repositoryPrefix are returned.
  --max-results: int # The maximum number of results to return per page.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<repositories: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "administrator-account" $administrator_account "scalar") (serialize-qp "repository-prefix" $repository_prefix "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "maxResults" $max_results_2 "scalar") (serialize-qp "nextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/domain/repositories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "domain-owner": $domain_owner, "administrator-account": $administrator_account, "repository-prefix": $repository_prefix, "max-results": $max_results, "next-token": $next_token, "maxResults": $max_results_2, "nextToken": $next_token_2} | compact), body: null}
}

# Gets information about Amazon Web Services tags for a specified Amazon Resource Name (ARN) in CodeArtifact.
#
# POST /v1/tags
# operationId: ListTagsForResource
export def "tags list-for-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-arn: string # The Amazon Resource Name (ARN) of the resource to get tags for.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceArn" $resource_arn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"resourceArn": $resource_arn} | compact), body: null}
}

# Creates a new package version containing one or more assets (or files). The unfinished flag can be used to keep the package version in the Unfinished state until all of its assets have been uploaded (see Package version status (https://docs.aws.amazon.com/codeartifact/latest/ug/packages-overview.html#package-version-status.html#package-version-status) in the CodeArtifact user guide). To set the package version’s status to Published, omit the unfinished flag when uploading the final asset, or set the status using UpdatePackageVersionStatus (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_UpdatePackageVersionsStatus.html). Once a package version’s status is set to Published, it cannot change back to Unfinished. Only generic packages can be published using this API. For more information, see Using generic packages (https://docs.aws.amazon.com/codeartifact/latest/ug/using-generic.html) in the CodeArtifact User Guide.
#
# POST /v1/package/version/publish
# operationId: PublishPackageVersion
export def "package-version-publish publish" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository that contains the package version to publish.
  --domain-owner: string # The 12-digit account number of the AWS account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that the package version will be published to.
  --format: string@format-completer # A format that specifies the type of the package version with the requested asset file.
  --namespace: string # The namespace of the package version to publish.
  --package: string # The name of the package version to publish.
  --version: string # The package version to publish (for example, 3.5.2).
  --asset: string # The name of the asset to publish. Asset names can include Unicode letters and numbers, and the following special characters: ~ ! @ ^ & ( ) - ` _ + [ ] { } ; , . `
  --unfinished: oneof<nothing, bool> # Specifies whether the package version should remain in the unfinished state. If omitted, the package version status will be set to Published (see Package version status (https://docs.aws.amazon.com/codeartifact/latest/ug/packages-overview.html#package-version-status) in the CodeArtifact User Guide). Valid values: unfinished
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-content-sha256-2: string # The SHA256 hash of the assetContent to publish. This value must be calculated by the caller and provided with the request (see Publishing a generic package (https://docs.aws.amazon.com/codeartifact/latest/ug/using-generic.html#publishing-generic-packages) in the CodeArtifact User Guide). This value is used as an integrity check to verify that the assetContent has not changed after it was originally sent. (disambiguated-2)
  asset_content: string # The content of the asset to publish.
]: any -> record<format: record, namespace: record, package: record, version: record, versionRevision: record, status: record, asset: record<name: record, size: record, hashes: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "package" $package "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "asset" $asset "scalar") (serialize-qp "unfinished" $unfinished "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/package/version/publish" $qp)
  let req_body = {"assetContent": $asset_content} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-content-sha256": $x_amz_content_sha256_2} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository, "format": $format, "namespace": $namespace, "package": $package, "version": $version, "asset": $asset, "unfinished": $unfinished} | compact), body: $req_body}
}

# Sets a resource policy on a domain that specifies permissions to access it. When you call PutDomainPermissionsPolicy, the resource policy on the domain is ignored when evaluting permissions. This ensures that the owner of a domain cannot lock themselves out of the domain, which would prevent them from being able to update the resource policy.
#
# PUT /v1/domain/permissions/policy
# operationId: PutDomainPermissionsPolicy
export def "domain-permissions-policy update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  domain: string # The name of the domain on which to set the resource policy.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --policy-revision: string # The current revision of the resource policy to be set. This revision is used for optimistic locking, which prevents others from overwriting your changes to the domain's resource policy.
  policy_document: string # A valid displayable JSON Aspen policy string to be set as the access control resource policy on the provided domain.
]: any -> record<policy: record<resourceArn: record, revision: record, document: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/domain/permissions/policy")
  let req_body = {"domain": $domain, "domainOwner": $domain_owner, "policyRevision": $policy_revision, "policyDocument": $policy_document} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Adds or updates tags for a resource in CodeArtifact.
#
# POST /v1/tag
# operationId: TagResource
# --tags item shape: {key: any, value: any}
export def "tag tag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-arn: string # The Amazon Resource Name (ARN) of the resource that you want to add or update tags for.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tags: list # The tags you want to modify or add to the resource. — item shape: {key: any, value: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceArn" $resource_arn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/tag" $qp)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"resourceArn": $resource_arn} | compact), body: $req_body}
}

# Removes tags from a resource in CodeArtifact.
#
# POST /v1/untag
# operationId: UntagResource
export def "untag untag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-arn: string # The Amazon Resource Name (ARN) of the resource that you want to remove tags from.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tag_keys: list<string> # The tag key for each tag that you want to remove from the resource.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceArn" $resource_arn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/untag" $qp)
  let req_body = {"tagKeys": $tag_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"resourceArn": $resource_arn} | compact), body: $req_body}
}

# Updates the status of one or more versions of a package. Using UpdatePackageVersionsStatus, you can update the status of package versions to Archived, Published, or Unlisted. To set the status of a package version to Disposed, use DisposePackageVersions (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_DisposePackageVersions.html).
#
# POST /v1/package/versions/update_status
# operationId: UpdatePackageVersionsStatus
export def "package-versions-update-status update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository that contains the package versions with a status to be updated.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The repository that contains the package versions with the status you want to update.
  --format: string@format-completer # A format that specifies the type of the package with the statuses to update.
  --namespace: string # The namespace of the package version to be updated. The package version component that specifies its namespace depends on its type. For example: The namespace of a Maven package version is its groupId. The namespace of an npm package version is its scope. Python and NuGet package versions do not contain a corresponding component, package versions of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the package with the version statuses to update.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  versions: list<string> # An array of strings that specify the versions of the package with the statuses to update.
  --version-revisions: record # A map of package versions and package version revisions. The map key is the package version (for example, 3.5.2), and the map value is the package version revision.
  --expected-status: string@expected-status-completer # The package version’s expected status before it is updated. If expectedStatus is provided, the package version's status is updated only if its status at the time UpdatePackageVersionsStatus is called matches expectedStatus.
  target_status: string@target-status-completer # The status you want to change the package version status to.
]: any -> record<successfulVersions: record, failedVersions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "domain-owner" $domain_owner "scalar") (serialize-qp "repository" $repository "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "package" $package "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/package/versions/update_status" $qp)
  let req_body = {"versions": $versions, "versionRevisions": $version_revisions, "expectedStatus": $expected_status, "targetStatus": $target_status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"domain": $domain, "domain-owner": $domain_owner, "repository": $repository, "format": $format, "namespace": $namespace, "package": $package} | compact), body: $req_body}
}
