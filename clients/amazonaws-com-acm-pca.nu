# Auto-generated client for AWS Certificate Manager Private Certificate Authority v2017-08-22
# Source: https://api.apis.guru/v2/specs/amazonaws.com/acm-pca/2017-08-22/openapi.json
# Auth: --token flag or $env.AWS_CERTIFICATE_MANAGER_PRIVATE_CERTIFICATE_AUTHORITY_TOKEN

const BASE_URL = "http://acm-pca.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_CERTIFICATE_MANAGER_PRIVATE_CERTIFICATE_AUTHORITY_TOKEN | default "" }
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

def base-url-completer [] { ["http://acm-pca.us-east-1.amazonaws.com" "http://acm-pca.us-east-2.amazonaws.com" "http://acm-pca.us-west-1.amazonaws.com" "http://acm-pca.us-west-2.amazonaws.com" "http://acm-pca.us-gov-west-1.amazonaws.com" "http://acm-pca.us-gov-east-1.amazonaws.com" "http://acm-pca.ca-central-1.amazonaws.com" "http://acm-pca.eu-north-1.amazonaws.com" "http://acm-pca.eu-west-1.amazonaws.com" "http://acm-pca.eu-west-2.amazonaws.com" "http://acm-pca.eu-west-3.amazonaws.com" "http://acm-pca.eu-central-1.amazonaws.com" "http://acm-pca.eu-south-1.amazonaws.com" "http://acm-pca.af-south-1.amazonaws.com" "http://acm-pca.ap-northeast-1.amazonaws.com" "http://acm-pca.ap-northeast-2.amazonaws.com" "http://acm-pca.ap-northeast-3.amazonaws.com" "http://acm-pca.ap-southeast-1.amazonaws.com" "http://acm-pca.ap-southeast-2.amazonaws.com" "http://acm-pca.ap-east-1.amazonaws.com" "http://acm-pca.ap-south-1.amazonaws.com" "http://acm-pca.sa-east-1.amazonaws.com" "http://acm-pca.me-south-1.amazonaws.com" "https://acm-pca.us-east-1.amazonaws.com" "https://acm-pca.us-east-2.amazonaws.com" "https://acm-pca.us-west-1.amazonaws.com" "https://acm-pca.us-west-2.amazonaws.com" "https://acm-pca.us-gov-west-1.amazonaws.com" "https://acm-pca.us-gov-east-1.amazonaws.com" "https://acm-pca.ca-central-1.amazonaws.com" "https://acm-pca.eu-north-1.amazonaws.com" "https://acm-pca.eu-west-1.amazonaws.com" "https://acm-pca.eu-west-2.amazonaws.com" "https://acm-pca.eu-west-3.amazonaws.com" "https://acm-pca.eu-central-1.amazonaws.com" "https://acm-pca.eu-south-1.amazonaws.com" "https://acm-pca.af-south-1.amazonaws.com" "https://acm-pca.ap-northeast-1.amazonaws.com" "https://acm-pca.ap-northeast-2.amazonaws.com" "https://acm-pca.ap-northeast-3.amazonaws.com" "https://acm-pca.ap-southeast-1.amazonaws.com" "https://acm-pca.ap-southeast-2.amazonaws.com" "https://acm-pca.ap-east-1.amazonaws.com" "https://acm-pca.ap-south-1.amazonaws.com" "https://acm-pca.sa-east-1.amazonaws.com" "https://acm-pca.me-south-1.amazonaws.com" "http://acm-pca.cn-north-1.amazonaws.com.cn" "http://acm-pca.cn-northwest-1.amazonaws.com.cn" "https://acm-pca.cn-north-1.amazonaws.com.cn" "https://acm-pca.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["ACMPrivateCA.CreateCertificateAuthority"] }
def x-amz-target-completer-1 [] { ["ACMPrivateCA.CreateCertificateAuthorityAuditReport"] }
def x-amz-target-completer-2 [] { ["ACMPrivateCA.CreatePermission"] }
def x-amz-target-completer-3 [] { ["ACMPrivateCA.DeleteCertificateAuthority"] }
def x-amz-target-completer-4 [] { ["ACMPrivateCA.DeletePermission"] }
def x-amz-target-completer-5 [] { ["ACMPrivateCA.DeletePolicy"] }
def x-amz-target-completer-6 [] { ["ACMPrivateCA.DescribeCertificateAuthority"] }
def x-amz-target-completer-7 [] { ["ACMPrivateCA.DescribeCertificateAuthorityAuditReport"] }
def x-amz-target-completer-8 [] { ["ACMPrivateCA.GetCertificate"] }
def x-amz-target-completer-9 [] { ["ACMPrivateCA.GetCertificateAuthorityCertificate"] }
def x-amz-target-completer-10 [] { ["ACMPrivateCA.GetCertificateAuthorityCsr"] }
def x-amz-target-completer-11 [] { ["ACMPrivateCA.GetPolicy"] }
def x-amz-target-completer-12 [] { ["ACMPrivateCA.ImportCertificateAuthorityCertificate"] }
def x-amz-target-completer-13 [] { ["ACMPrivateCA.IssueCertificate"] }
def x-amz-target-completer-14 [] { ["ACMPrivateCA.ListCertificateAuthorities"] }
def x-amz-target-completer-15 [] { ["ACMPrivateCA.ListPermissions"] }
def x-amz-target-completer-16 [] { ["ACMPrivateCA.ListTags"] }
def x-amz-target-completer-17 [] { ["ACMPrivateCA.PutPolicy"] }
def x-amz-target-completer-18 [] { ["ACMPrivateCA.RestoreCertificateAuthority"] }
def x-amz-target-completer-19 [] { ["ACMPrivateCA.RevokeCertificate"] }
def x-amz-target-completer-20 [] { ["ACMPrivateCA.TagCertificateAuthority"] }
def x-amz-target-completer-21 [] { ["ACMPrivateCA.UntagCertificateAuthority"] }
def x-amz-target-completer-22 [] { ["ACMPrivateCA.UpdateCertificateAuthority"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api create-certificate-authority" } } | get name | first)
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

# Creates a root or subordinate private certificate authority (CA). You must specify the CA configuration, an optional configuration for Online Certificate Status Protocol (OCSP) and/or a certificate revocation list (CRL), the CA type, and an optional idempotency token to avoid accidental creation of multiple CAs. The CA configuration specifies the name of the algorithm and key size to be used to create the CA private key, the type of signing algorithm that the CA uses, and X.500 subject information. The OCSP configuration can optionally specify a custom URL for the OCSP responder. The CRL configuration specifies the CRL expiration period in days (the validity period of the CRL), the Amazon S3 bucket that will contain the CRL, and a CNAME alias for the S3 bucket that is included in certificates issued by the CA. If successful, this action returns the Amazon Resource Name (ARN) of the CA. Both Amazon Web Services Private CA and the IAM principal must have permission to write to the S3 bucket that you specify. If the IAM principal making the call does not have permission to write to the bucket, then an exception is thrown. For more information, see Access policies for CRLs in Amazon S3 (https://docs.aws.amazon.com/privateca/latest/userguide/crl-planning.html#s3-policies). Amazon Web Services Private CA assets that are stored in Amazon S3 can be protected with encryption. For more information, see Encrypting Your CRLs (https://docs.aws.amazon.com/privateca/latest/userguide/PcaCreateCa.html#crl-encryption).
#
# POST /
# operationId: CreateCertificateAuthority
export def "api create-certificate-authority" [
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
  --x-amz-target: string@x-amz-target-completer
  certificate_authority_configuration: any
  --revocation-configuration: any
  certificate_authority_type: any
  --idempotency-token: any
  --key-storage-security-standard: any
  --tags: any
  --usage-mode: any
]: any -> record<CertificateAuthorityArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CertificateAuthorityConfiguration": $certificate_authority_configuration, "RevocationConfiguration": $revocation_configuration, "CertificateAuthorityType": $certificate_authority_type, "IdempotencyToken": $idempotency_token, "KeyStorageSecurityStandard": $key_storage_security_standard, "Tags": $tags, "UsageMode": $usage_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates an audit report that lists every time that your CA private key is used. The report is saved in the Amazon S3 bucket that you specify on input. The IssueCertificate (https://docs.aws.amazon.com/privateca/latest/APIReference/API_IssueCertificate.html) and RevokeCertificate (https://docs.aws.amazon.com/privateca/latest/APIReference/API_RevokeCertificate.html) actions use the private key. Both Amazon Web Services Private CA and the IAM principal must have permission to write to the S3 bucket that you specify. If the IAM principal making the call does not have permission to write to the bucket, then an exception is thrown. For more information, see Access policies for CRLs in Amazon S3 (https://docs.aws.amazon.com/privateca/latest/userguide/crl-planning.html#s3-policies). Amazon Web Services Private CA assets that are stored in Amazon S3 can be protected with encryption. For more information, see Encrypting Your Audit Reports (https://docs.aws.amazon.com/privateca/latest/userguide/PcaAuditReport.html#audit-report-encryption). You can generate a maximum of one report every 30 minutes.
#
# POST /
# operationId: CreateCertificateAuthorityAuditReport
export def "api create-certificate-authority-audit-report" [
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
  --x-amz-target: string@x-amz-target-completer-1
  certificate_authority_arn: any
  s3_bucket_name: any
  audit_report_response_format: any
]: any -> record<AuditReportId: record, S3Key: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "S3BucketName": $s3_bucket_name, "AuditReportResponseFormat": $audit_report_response_format} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Grants one or more permissions on a private CA to the Certificate Manager (ACM) service principal (acm.amazonaws.com). These permissions allow ACM to issue and renew ACM certificates that reside in the same Amazon Web Services account as the CA. You can list current permissions with the ListPermissions (https://docs.aws.amazon.com/privateca/latest/APIReference/API_ListPermissions.html) action and revoke them with the DeletePermission (https://docs.aws.amazon.com/privateca/latest/APIReference/API_DeletePermission.html) action. About Permissions If the private CA and the certificates it issues reside in the same account, you can use CreatePermission to grant permissions for ACM to carry out automatic certificate renewals. For automatic certificate renewal to succeed, the ACM service principal needs permissions to create, retrieve, and list certificates. If the private CA and the ACM certificates reside in different accounts, then permissions cannot be used to enable automatic renewals. Instead, the ACM certificate owner must set up a resource-based policy to enable cross-account issuance and renewals. For more information, see Using a Resource Based Policy with Amazon Web Services Private CA (https://docs.aws.amazon.com/privateca/latest/userguide/pca-rbp.html).
#
# POST /
# operationId: CreatePermission
export def "api create-permission" [
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
  --x-amz-target: string@x-amz-target-completer-2
  certificate_authority_arn: any
  principal: any
  --source-account: any
  actions: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "Principal": $principal, "SourceAccount": $source_account, "Actions": $actions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a private certificate authority (CA). You must provide the Amazon Resource Name (ARN) of the private CA that you want to delete. You can find the ARN by calling the ListCertificateAuthorities (https://docs.aws.amazon.com/privateca/latest/APIReference/API_ListCertificateAuthorities.html) action. Deleting a CA will invalidate other CAs and certificates below it in your CA hierarchy. Before you can delete a CA that you have created and activated, you must disable it. To do this, call the UpdateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_UpdateCertificateAuthority.html) action and set the CertificateAuthorityStatus parameter to DISABLED. Additionally, you can delete a CA if you are waiting for it to be created (that is, the status of the CA is CREATING). You can also delete it if the CA has been created but you haven't yet imported the signed certificate into Amazon Web Services Private CA (that is, the status of the CA is PENDING_CERTIFICATE). When you successfully call DeleteCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_DeleteCertificateAuthority.html), the CA's status changes to DELETED. However, the CA won't be permanently deleted until the restoration period has passed. By default, if you do not set the PermanentDeletionTimeInDays parameter, the CA remains restorable for 30 days. You can set the parameter from 7 to 30 days. The DescribeCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_DescribeCertificateAuthority.html) action returns the time remaining in the restoration window of a private CA in the DELETED state. To restore an eligible CA, call the RestoreCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_RestoreCertificateAuthority.html) action.
#
# POST /
# operationId: DeleteCertificateAuthority
export def "api delete-certificate-authority" [
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
  --x-amz-target: string@x-amz-target-completer-3
  certificate_authority_arn: any
  --permanent-deletion-time-in-days: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "PermanentDeletionTimeInDays": $permanent_deletion_time_in_days} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Revokes permissions on a private CA granted to the Certificate Manager (ACM) service principal (acm.amazonaws.com). These permissions allow ACM to issue and renew ACM certificates that reside in the same Amazon Web Services account as the CA. If you revoke these permissions, ACM will no longer renew the affected certificates automatically. Permissions can be granted with the CreatePermission (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreatePermission.html) action and listed with the ListPermissions (https://docs.aws.amazon.com/privateca/latest/APIReference/API_ListPermissions.html) action. About Permissions If the private CA and the certificates it issues reside in the same account, you can use CreatePermission to grant permissions for ACM to carry out automatic certificate renewals. For automatic certificate renewal to succeed, the ACM service principal needs permissions to create, retrieve, and list certificates. If the private CA and the ACM certificates reside in different accounts, then permissions cannot be used to enable automatic renewals. Instead, the ACM certificate owner must set up a resource-based policy to enable cross-account issuance and renewals. For more information, see Using a Resource Based Policy with Amazon Web Services Private CA (https://docs.aws.amazon.com/privateca/latest/userguide/pca-rbp.html).
#
# POST /
# operationId: DeletePermission
export def "api delete-permission" [
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
  --x-amz-target: string@x-amz-target-completer-4
  certificate_authority_arn: any
  principal: any
  --source-account: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "Principal": $principal, "SourceAccount": $source_account} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the resource-based policy attached to a private CA. Deletion will remove any access that the policy has granted. If there is no policy attached to the private CA, this action will return successful. If you delete a policy that was applied through Amazon Web Services Resource Access Manager (RAM), the CA will be removed from all shares in which it was included. The Certificate Manager Service Linked Role that the policy supports is not affected when you delete the policy. The current policy can be shown with GetPolicy (https://docs.aws.amazon.com/privateca/latest/APIReference/API_GetPolicy.html) and updated with PutPolicy (https://docs.aws.amazon.com/privateca/latest/APIReference/API_PutPolicy.html). About Policies A policy grants access on a private CA to an Amazon Web Services customer account, to Amazon Web Services Organizations, or to an Amazon Web Services Organizations unit. Policies are under the control of a CA administrator. For more information, see Using a Resource Based Policy with Amazon Web Services Private CA (https://docs.aws.amazon.com/privateca/latest/userguide/pca-rbp.html). A policy permits a user of Certificate Manager (ACM) to issue ACM certificates signed by a CA in another account. For ACM to manage automatic renewal of these certificates, the ACM user must configure a Service Linked Role (SLR). The SLR allows the ACM service to assume the identity of the user, subject to confirmation against the Amazon Web Services Private CA policy. For more information, see Using a Service Linked Role with ACM (https://docs.aws.amazon.com/acm/latest/userguide/acm-slr.html). Updates made in Amazon Web Services Resource Manager (RAM) are reflected in policies. For more information, see Attach a Policy for Cross-Account Access (https://docs.aws.amazon.com/privateca/latest/userguide/pca-ram.html).
#
# POST /
# operationId: DeletePolicy
export def "api delete-policy" [
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
  --x-amz-target: string@x-amz-target-completer-5
  resource_arn: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"ResourceArn": $resource_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists information about your private certificate authority (CA) or one that has been shared with you. You specify the private CA on input by its ARN (Amazon Resource Name). The output contains the status of your CA. This can be any of the following: CREATING - Amazon Web Services Private CA is creating your private certificate authority. PENDING_CERTIFICATE - The certificate is pending. You must use your Amazon Web Services Private CA-hosted or on-premises root or subordinate CA to sign your private CA CSR and then import it into Amazon Web Services Private CA. ACTIVE - Your private CA is active. DISABLED - Your private CA has been disabled. EXPIRED - Your private CA certificate has expired. FAILED - Your private CA has failed. Your CA can fail because of problems such a network outage or back-end Amazon Web Services failure or other errors. A failed CA can never return to the pending state. You must create a new CA. DELETED - Your private CA is within the restoration period, after which it is permanently deleted. The length of time remaining in the CA's restoration period is also included in this action's output.
#
# POST /
# operationId: DescribeCertificateAuthority
export def "api get-certificate-authority" [
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
  --x-amz-target: string@x-amz-target-completer-6
  certificate_authority_arn: any
]: any -> record<CertificateAuthority: record<Arn: record, OwnerAccount: record, CreatedAt: record, LastStateChangeAt: record, Type: record, Serial: record, Status: record, NotBefore: record, NotAfter: record, FailureReason: record, CertificateAuthorityConfiguration: record<KeyAlgorithm: record, SigningAlgorithm: record, Subject: record, CsrExtensions: record>, RevocationConfiguration: record<CrlConfiguration: record, OcspConfiguration: record>, RestorableUntil: record, KeyStorageSecurityStandard: record, UsageMode: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists information about a specific audit report created by calling the CreateCertificateAuthorityAuditReport (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthorityAuditReport.html) action. Audit information is created every time the certificate authority (CA) private key is used. The private key is used when you call the IssueCertificate (https://docs.aws.amazon.com/privateca/latest/APIReference/API_IssueCertificate.html) action or the RevokeCertificate (https://docs.aws.amazon.com/privateca/latest/APIReference/API_RevokeCertificate.html) action.
#
# POST /
# operationId: DescribeCertificateAuthorityAuditReport
export def "api get-certificate-authority-audit-report" [
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
  --x-amz-target: string@x-amz-target-completer-7
  certificate_authority_arn: any
  audit_report_id: any
]: any -> record<AuditReportStatus: record, S3BucketName: record, S3Key: record, CreatedAt: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "AuditReportId": $audit_report_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves a certificate from your private CA or one that has been shared with you. The ARN of the certificate is returned when you call the IssueCertificate (https://docs.aws.amazon.com/privateca/latest/APIReference/API_IssueCertificate.html) action. You must specify both the ARN of your private CA and the ARN of the issued certificate when calling the GetCertificate action. You can retrieve the certificate if it is in the ISSUED state. You can call the CreateCertificateAuthorityAuditReport (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthorityAuditReport.html) action to create a report that contains information about all of the certificates issued and revoked by your private CA.
#
# POST /
# operationId: GetCertificate
export def "api get-certificate" [
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
  --x-amz-target: string@x-amz-target-completer-8
  certificate_authority_arn: any
  certificate_arn: any
]: any -> record<Certificate: record, CertificateChain: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "CertificateArn": $certificate_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves the certificate and certificate chain for your private certificate authority (CA) or one that has been shared with you. Both the certificate and the chain are base64 PEM-encoded. The chain does not include the CA certificate. Each certificate in the chain signs the one before it.
#
# POST /
# operationId: GetCertificateAuthorityCertificate
export def "api get-certificate-authority-certificate" [
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
  --x-amz-target: string@x-amz-target-completer-9
  certificate_authority_arn: any
]: any -> record<Certificate: record, CertificateChain: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves the certificate signing request (CSR) for your private certificate authority (CA). The CSR is created when you call the CreateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthority.html) action. Sign the CSR with your Amazon Web Services Private CA-hosted or on-premises root or subordinate CA. Then import the signed certificate back into Amazon Web Services Private CA by calling the ImportCertificateAuthorityCertificate (https://docs.aws.amazon.com/privateca/latest/APIReference/API_ImportCertificateAuthorityCertificate.html) action. The CSR is returned as a base64 PEM-encoded string.
#
# POST /
# operationId: GetCertificateAuthorityCsr
export def "api get-certificate-authority-csr" [
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
  --x-amz-target: string@x-amz-target-completer-10
  certificate_authority_arn: any
]: any -> record<Csr: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves the resource-based policy attached to a private CA. If either the private CA resource or the policy cannot be found, this action returns a ResourceNotFoundException. The policy can be attached or updated with PutPolicy (https://docs.aws.amazon.com/privateca/latest/APIReference/API_PutPolicy.html) and removed with DeletePolicy (https://docs.aws.amazon.com/privateca/latest/APIReference/API_DeletePolicy.html). About Policies A policy grants access on a private CA to an Amazon Web Services customer account, to Amazon Web Services Organizations, or to an Amazon Web Services Organizations unit. Policies are under the control of a CA administrator. For more information, see Using a Resource Based Policy with Amazon Web Services Private CA (https://docs.aws.amazon.com/privateca/latest/userguide/pca-rbp.html). A policy permits a user of Certificate Manager (ACM) to issue ACM certificates signed by a CA in another account. For ACM to manage automatic renewal of these certificates, the ACM user must configure a Service Linked Role (SLR). The SLR allows the ACM service to assume the identity of the user, subject to confirmation against the Amazon Web Services Private CA policy. For more information, see Using a Service Linked Role with ACM (https://docs.aws.amazon.com/acm/latest/userguide/acm-slr.html). Updates made in Amazon Web Services Resource Manager (RAM) are reflected in policies. For more information, see Attach a Policy for Cross-Account Access (https://docs.aws.amazon.com/privateca/latest/userguide/pca-ram.html).
#
# POST /
# operationId: GetPolicy
export def "api get-policy" [
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
  --x-amz-target: string@x-amz-target-completer-11
  resource_arn: any
]: any -> record<Policy: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"ResourceArn": $resource_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Imports a signed private CA certificate into Amazon Web Services Private CA. This action is used when you are using a chain of trust whose root is located outside Amazon Web Services Private CA. Before you can call this action, the following preparations must in place: In Amazon Web Services Private CA, call the CreateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthority.html) action to create the private CA that you plan to back with the imported certificate. Call the GetCertificateAuthorityCsr (https://docs.aws.amazon.com/privateca/latest/APIReference/API_GetCertificateAuthorityCsr.html) action to generate a certificate signing request (CSR). Sign the CSR using a root or intermediate CA hosted by either an on-premises PKI hierarchy or by a commercial CA. Create a certificate chain and copy the signed certificate and the certificate chain to your working directory. Amazon Web Services Private CA supports three scenarios for installing a CA certificate: Installing a certificate for a root CA hosted by Amazon Web Services Private CA. Installing a subordinate CA certificate whose parent authority is hosted by Amazon Web Services Private CA. Installing a subordinate CA certificate whose parent authority is externally hosted. The following additional requirements apply when you import a CA certificate. Only a self-signed certificate can be imported as a root CA. A self-signed certificate cannot be imported as a subordinate CA. Your certificate chain must not include the private CA certificate that you are importing. Your root CA must be the last certificate in your chain. The subordinate certificate, if any, that your root CA signed must be next to last. The subordinate certificate signed by the preceding subordinate CA must come next, and so on until your chain is built. The chain must be PEM-encoded. The maximum allowed size of a certificate is 32 KB. The maximum allowed size of a certificate chain is 2 MB. Enforcement of Critical Constraints Amazon Web Services Private CA allows the following extensions to be marked critical in the imported CA certificate or chain. Basic constraints (must be marked critical) Subject alternative names Key usage Extended key usage Authority key identifier Subject key identifier Issuer alternative name Subject directory attributes Subject information access Certificate policies Policy mappings Inhibit anyPolicy Amazon Web Services Private CA rejects the following extensions when they are marked critical in an imported CA certificate or chain. Name constraints Policy constraints CRL distribution points Authority information access Freshest CRL Any other extension
#
# POST /
# operationId: ImportCertificateAuthorityCertificate
export def "api import-certificate-authority-certificate" [
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
  --x-amz-target: string@x-amz-target-completer-12
  certificate_authority_arn: any
  certificate: any
  --certificate-chain: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "Certificate": $certificate, "CertificateChain": $certificate_chain} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Uses your private certificate authority (CA), or one that has been shared with you, to issue a client certificate. This action returns the Amazon Resource Name (ARN) of the certificate. You can retrieve the certificate by calling the GetCertificate (https://docs.aws.amazon.com/privateca/latest/APIReference/API_GetCertificate.html) action and specifying the ARN. You cannot use the ACM ListCertificateAuthorities action to retrieve the ARNs of the certificates that you issue by using Amazon Web Services Private CA.
#
# POST /
# operationId: IssueCertificate
export def "api create-issue-certificate" [
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
  --x-amz-target: string@x-amz-target-completer-13
  --api-passthrough: any
  certificate_authority_arn: any
  csr: any
  signing_algorithm: any
  --template-arn: any
  validity: any
  --validity-not-before: any
  --idempotency-token: any
]: any -> record<CertificateArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"ApiPassthrough": $api_passthrough, "CertificateAuthorityArn": $certificate_authority_arn, "Csr": $csr, "SigningAlgorithm": $signing_algorithm, "TemplateArn": $template_arn, "Validity": $validity, "ValidityNotBefore": $validity_not_before, "IdempotencyToken": $idempotency_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists the private certificate authorities that you created by using the CreateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthority.html) action.
#
# POST /
# operationId: ListCertificateAuthorities
export def "api list-certificate-authorities" [
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
  --x-amz-target: string@x-amz-target-completer-14
  --next-token-body: any #  (body field)
  --max-results-body: any #  (body field)
  --resource-owner: any
]: any -> record<CertificateAuthorities: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = {"NextToken": $next_token_body, "MaxResults": $max_results_body, "ResourceOwner": $resource_owner} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# List all permissions on a private CA, if any, granted to the Certificate Manager (ACM) service principal (acm.amazonaws.com). These permissions allow ACM to issue and renew ACM certificates that reside in the same Amazon Web Services account as the CA. Permissions can be granted with the CreatePermission (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreatePermission.html) action and revoked with the DeletePermission (https://docs.aws.amazon.com/privateca/latest/APIReference/API_DeletePermission.html) action. About Permissions If the private CA and the certificates it issues reside in the same account, you can use CreatePermission to grant permissions for ACM to carry out automatic certificate renewals. For automatic certificate renewal to succeed, the ACM service principal needs permissions to create, retrieve, and list certificates. If the private CA and the ACM certificates reside in different accounts, then permissions cannot be used to enable automatic renewals. Instead, the ACM certificate owner must set up a resource-based policy to enable cross-account issuance and renewals. For more information, see Using a Resource Based Policy with Amazon Web Services Private CA (https://docs.aws.amazon.com/privateca/latest/userguide/pca-rbp.html).
#
# POST /
# operationId: ListPermissions
export def "api list-permissions" [
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
  --x-amz-target: string@x-amz-target-completer-15
  certificate_authority_arn: any
  --next-token-body: any #  (body field)
  --max-results-body: any #  (body field)
]: any -> record<Permissions: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "NextToken": $next_token_body, "MaxResults": $max_results_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Lists the tags, if any, that are associated with your private CA or one that has been shared with you. Tags are labels that you can use to identify and organize your CAs. Each tag consists of a key and an optional value. Call the TagCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_TagCertificateAuthority.html) action to add one or more tags to your CA. Call the UntagCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_UntagCertificateAuthority.html) action to remove tags.
#
# POST /
# operationId: ListTags
export def "api list-tags" [
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
  --x-amz-target: string@x-amz-target-completer-16
  certificate_authority_arn: any
  --next-token-body: any #  (body field)
  --max-results-body: any #  (body field)
]: any -> record<Tags: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "NextToken": $next_token_body, "MaxResults": $max_results_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Attaches a resource-based policy to a private CA. A policy can also be applied by sharing a private CA through Amazon Web Services Resource Access Manager (RAM). For more information, see Attach a Policy for Cross-Account Access (https://docs.aws.amazon.com/privateca/latest/userguide/pca-ram.html). The policy can be displayed with GetPolicy (https://docs.aws.amazon.com/privateca/latest/APIReference/API_GetPolicy.html) and removed with DeletePolicy (https://docs.aws.amazon.com/privateca/latest/APIReference/API_DeletePolicy.html). About Policies A policy grants access on a private CA to an Amazon Web Services customer account, to Amazon Web Services Organizations, or to an Amazon Web Services Organizations unit. Policies are under the control of a CA administrator. For more information, see Using a Resource Based Policy with Amazon Web Services Private CA (https://docs.aws.amazon.com/privateca/latest/userguide/pca-rbp.html). A policy permits a user of Certificate Manager (ACM) to issue ACM certificates signed by a CA in another account. For ACM to manage automatic renewal of these certificates, the ACM user must configure a Service Linked Role (SLR). The SLR allows the ACM service to assume the identity of the user, subject to confirmation against the Amazon Web Services Private CA policy. For more information, see Using a Service Linked Role with ACM (https://docs.aws.amazon.com/acm/latest/userguide/acm-slr.html). Updates made in Amazon Web Services Resource Manager (RAM) are reflected in policies. For more information, see Attach a Policy for Cross-Account Access (https://docs.aws.amazon.com/privateca/latest/userguide/pca-ram.html).
#
# POST /
# operationId: PutPolicy
export def "api update-policy" [
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
  --x-amz-target: string@x-amz-target-completer-17
  resource_arn: any
  policy: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"ResourceArn": $resource_arn, "Policy": $policy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Restores a certificate authority (CA) that is in the DELETED state. You can restore a CA during the period that you defined in the PermanentDeletionTimeInDays parameter of the DeleteCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_DeleteCertificateAuthority.html) action. Currently, you can specify 7 to 30 days. If you did not specify a PermanentDeletionTimeInDays value, by default you can restore the CA at any time in a 30 day period. You can check the time remaining in the restoration period of a private CA in the DELETED state by calling the DescribeCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_DescribeCertificateAuthority.html) or ListCertificateAuthorities (https://docs.aws.amazon.com/privateca/latest/APIReference/API_ListCertificateAuthorities.html) actions. The status of a restored CA is set to its pre-deletion status when the RestoreCertificateAuthority action returns. To change its status to ACTIVE, call the UpdateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_UpdateCertificateAuthority.html) action. If the private CA was in the PENDING_CERTIFICATE state at deletion, you must use the ImportCertificateAuthorityCertificate (https://docs.aws.amazon.com/privateca/latest/APIReference/API_ImportCertificateAuthorityCertificate.html) action to import a certificate authority into the private CA before it can be activated. You cannot restore a CA after the restoration period has ended.
#
# POST /
# operationId: RestoreCertificateAuthority
export def "api create-restore-certificate-authority" [
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
  --x-amz-target: string@x-amz-target-completer-18
  certificate_authority_arn: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Revokes a certificate that was issued inside Amazon Web Services Private CA. If you enable a certificate revocation list (CRL) when you create or update your private CA, information about the revoked certificates will be included in the CRL. Amazon Web Services Private CA writes the CRL to an S3 bucket that you specify. A CRL is typically updated approximately 30 minutes after a certificate is revoked. If for any reason the CRL update fails, Amazon Web Services Private CA attempts makes further attempts every 15 minutes. With Amazon CloudWatch, you can create alarms for the metrics CRLGenerated and MisconfiguredCRLBucket. For more information, see Supported CloudWatch Metrics (https://docs.aws.amazon.com/privateca/latest/userguide/PcaCloudWatch.html). Both Amazon Web Services Private CA and the IAM principal must have permission to write to the S3 bucket that you specify. If the IAM principal making the call does not have permission to write to the bucket, then an exception is thrown. For more information, see Access policies for CRLs in Amazon S3 (https://docs.aws.amazon.com/privateca/latest/userguide/crl-planning.html#s3-policies). Amazon Web Services Private CA also writes revocation information to the audit report. For more information, see CreateCertificateAuthorityAuditReport (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthorityAuditReport.html). You cannot revoke a root CA self-signed certificate.
#
# POST /
# operationId: RevokeCertificate
export def "api delete-certificate" [
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
  --x-amz-target: string@x-amz-target-completer-19
  certificate_authority_arn: any
  certificate_serial: any
  revocation_reason: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "CertificateSerial": $certificate_serial, "RevocationReason": $revocation_reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Adds one or more tags to your private CA. Tags are labels that you can use to identify and organize your Amazon Web Services resources. Each tag consists of a key and an optional value. You specify the private CA on input by its Amazon Resource Name (ARN). You specify the tag by using a key-value pair. You can apply a tag to just one private CA if you want to identify a specific characteristic of that CA, or you can apply the same tag to multiple private CAs if you want to filter for a common relationship among those CAs. To remove one or more tags, use the UntagCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_UntagCertificateAuthority.html) action. Call the ListTags (https://docs.aws.amazon.com/privateca/latest/APIReference/API_ListTags.html) action to see what tags are associated with your CA. To attach tags to a private CA during the creation procedure, a CA administrator must first associate an inline IAM policy with the CreateCertificateAuthority action and explicitly allow tagging. For more information, see Attaching tags to a CA at the time of creation (https://docs.aws.amazon.com/privateca/latest/userguide/auth-InlinePolicies.html#policy-tag-ca).
#
# POST /
# operationId: TagCertificateAuthority
export def "api tag-certificate-authority" [
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
  --x-amz-target: string@x-amz-target-completer-20
  certificate_authority_arn: any
  tags: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Remove one or more tags from your private CA. A tag consists of a key-value pair. If you do not specify the value portion of the tag when calling this action, the tag will be removed regardless of value. If you specify a value, the tag is removed only if it is associated with the specified value. To add tags to a private CA, use the TagCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_TagCertificateAuthority.html). Call the ListTags (https://docs.aws.amazon.com/privateca/latest/APIReference/API_ListTags.html) action to see what tags are associated with your CA.
#
# POST /
# operationId: UntagCertificateAuthority
export def "api untag-certificate-authority" [
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
  --x-amz-target: string@x-amz-target-completer-21
  certificate_authority_arn: any
  tags: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates the status or configuration of a private certificate authority (CA). Your private CA must be in the ACTIVE or DISABLED state before you can update it. You can disable a private CA that is in the ACTIVE state or make a CA that is in the DISABLED state active again. Both Amazon Web Services Private CA and the IAM principal must have permission to write to the S3 bucket that you specify. If the IAM principal making the call does not have permission to write to the bucket, then an exception is thrown. For more information, see Access policies for CRLs in Amazon S3 (https://docs.aws.amazon.com/privateca/latest/userguide/crl-planning.html#s3-policies).
#
# POST /
# operationId: UpdateCertificateAuthority
export def "api update-certificate-authority" [
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
  --x-amz-target: string@x-amz-target-completer-22
  certificate_authority_arn: any
  --revocation-configuration: any
  --status: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "RevocationConfiguration": $revocation_configuration, "Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
