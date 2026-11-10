# Auto-generated client for AWS Certificate Manager Private Certificate Authority v2017-08-22
# Source: https://api.apis.guru/v2/specs/amazonaws.com/acm-pca/2017-08-22/openapi.json
# Auth: --token flag or $env.AWS_CERTIFICATE_MANAGER_PRIVATE_CERTIFICATE_AUTHORITY_TOKEN

const BASE_URL = "http://acm-pca.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_CERTIFICATE_MANAGER_PRIVATE_CERTIFICATE_AUTHORITY_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
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

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, as with `merge`,
# except for `Cookie`. A request carries all its cookies in one header
# (RFC 6265 §5.4), so both sides' cookie strings are kept, joined with `; `.
# A plain `merge` would let a cookie param drop a cookie-located auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let cookie = ([$base.Cookie? $extra.Cookie?] | where {|c| $c | is-not-empty } | str join "; ")
  let merged = ($base | merge $extra | reject -o Cookie)
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://acm-pca.us-east-1.amazonaws.com" "http://acm-pca.us-east-2.amazonaws.com" "http://acm-pca.us-west-1.amazonaws.com" "http://acm-pca.us-west-2.amazonaws.com" "http://acm-pca.us-gov-west-1.amazonaws.com" "http://acm-pca.us-gov-east-1.amazonaws.com" "http://acm-pca.ca-central-1.amazonaws.com" "http://acm-pca.eu-north-1.amazonaws.com" "http://acm-pca.eu-west-1.amazonaws.com" "http://acm-pca.eu-west-2.amazonaws.com" "http://acm-pca.eu-west-3.amazonaws.com" "http://acm-pca.eu-central-1.amazonaws.com" "http://acm-pca.eu-south-1.amazonaws.com" "http://acm-pca.af-south-1.amazonaws.com" "http://acm-pca.ap-northeast-1.amazonaws.com" "http://acm-pca.ap-northeast-2.amazonaws.com" "http://acm-pca.ap-northeast-3.amazonaws.com" "http://acm-pca.ap-southeast-1.amazonaws.com" "http://acm-pca.ap-southeast-2.amazonaws.com" "http://acm-pca.ap-east-1.amazonaws.com" "http://acm-pca.ap-south-1.amazonaws.com" "http://acm-pca.sa-east-1.amazonaws.com" "http://acm-pca.me-south-1.amazonaws.com" "https://acm-pca.us-east-1.amazonaws.com" "https://acm-pca.us-east-2.amazonaws.com" "https://acm-pca.us-west-1.amazonaws.com" "https://acm-pca.us-west-2.amazonaws.com" "https://acm-pca.us-gov-west-1.amazonaws.com" "https://acm-pca.us-gov-east-1.amazonaws.com" "https://acm-pca.ca-central-1.amazonaws.com" "https://acm-pca.eu-north-1.amazonaws.com" "https://acm-pca.eu-west-1.amazonaws.com" "https://acm-pca.eu-west-2.amazonaws.com" "https://acm-pca.eu-west-3.amazonaws.com" "https://acm-pca.eu-central-1.amazonaws.com" "https://acm-pca.eu-south-1.amazonaws.com" "https://acm-pca.af-south-1.amazonaws.com" "https://acm-pca.ap-northeast-1.amazonaws.com" "https://acm-pca.ap-northeast-2.amazonaws.com" "https://acm-pca.ap-northeast-3.amazonaws.com" "https://acm-pca.ap-southeast-1.amazonaws.com" "https://acm-pca.ap-southeast-2.amazonaws.com" "https://acm-pca.ap-east-1.amazonaws.com" "https://acm-pca.ap-south-1.amazonaws.com" "https://acm-pca.sa-east-1.amazonaws.com" "https://acm-pca.me-south-1.amazonaws.com" "http://acm-pca.cn-north-1.amazonaws.com.cn" "http://acm-pca.cn-northwest-1.amazonaws.com.cn" "https://acm-pca.cn-north-1.amazonaws.com.cn" "https://acm-pca.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def certificate-authority-type-completer [] { ["ROOT" "SUBORDINATE"] }
def key-storage-security-standard-completer [] { ["FIPS_140_2_LEVEL_2_OR_HIGHER" "FIPS_140_2_LEVEL_3_OR_HIGHER"] }
def usage-mode-completer [] { ["GENERAL_PURPOSE" "SHORT_LIVED_CERTIFICATE"] }
def x-amz-target-completer [] { ["ACMPrivateCA.CreateCertificateAuthority"] }
def audit-report-response-format-completer [] { ["CSV" "JSON"] }
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
def signing-algorithm-completer [] { ["SHA256WITHECDSA" "SHA256WITHRSA" "SHA384WITHECDSA" "SHA384WITHRSA" "SHA512WITHECDSA" "SHA512WITHRSA"] }
def x-amz-target-completer-13 [] { ["ACMPrivateCA.IssueCertificate"] }
def resource-owner-completer [] { ["OTHER_ACCOUNTS" "SELF"] }
def x-amz-target-completer-14 [] { ["ACMPrivateCA.ListCertificateAuthorities"] }
def x-amz-target-completer-15 [] { ["ACMPrivateCA.ListPermissions"] }
def x-amz-target-completer-16 [] { ["ACMPrivateCA.ListTags"] }
def x-amz-target-completer-17 [] { ["ACMPrivateCA.PutPolicy"] }
def x-amz-target-completer-18 [] { ["ACMPrivateCA.RestoreCertificateAuthority"] }
def revocation-reason-completer [] { ["AFFILIATION_CHANGED" "A_A_COMPROMISE" "CERTIFICATE_AUTHORITY_COMPROMISE" "CESSATION_OF_OPERATION" "KEY_COMPROMISE" "PRIVILEGE_WITHDRAWN" "SUPERSEDED" "UNSPECIFIED"] }
def x-amz-target-completer-19 [] { ["ACMPrivateCA.RevokeCertificate"] }
def x-amz-target-completer-20 [] { ["ACMPrivateCA.TagCertificateAuthority"] }
def x-amz-target-completer-21 [] { ["ACMPrivateCA.UntagCertificateAuthority"] }
def status-completer [] { ["ACTIVE" "CREATING" "DELETED" "DISABLED" "EXPIRED" "FAILED" "PENDING_CERTIFICATE"] }
def x-amz-target-completer-22 [] { ["ACMPrivateCA.UpdateCertificateAuthority"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-certificate-authority" "create-certificate-authority-audit-report" "create-permission" "delete-certificate-authority" "delete-permission" "delete-policy" "describe-certificate-authority" "describe-certificate-authority-audit-report" "get-certificate" "get-certificate-authority-certificate" "get-certificate-authority-csr" "get-policy" "import-certificate-authority-certificate" "issue-certificate" "list-certificate-authorities" "list-permissions" "list-tags" "put-policy" "restore-certificate-authority" "revoke-certificate" "tag-certificate-authority" "untag-certificate-authority" "update-certificate-authority" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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
export def "create-certificate-authority" [
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
  --x-amz-target: string@x-amz-target-completer # required
  certificate_authority_configuration: record # Contains configuration information for your private certificate authority (CA). This includes information about the class of public key algorithm and the key pair that your private CA creates when it issues a certificate. It also includes the signature algorithm that it uses when issuing certificates, and its X.500 distinguished name. You must specify this information when you call the CreateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthority.html) action. — shape: {KeyAlgorithm: "RSA_2048"|"RSA_4096"|"EC_prime256v1"|"EC_secp384r1", SigningAlgorithm: "SHA256WITHECDSA"|"SHA384WITHECDSA"|"SHA512WITHECDSA"|"SHA256WITHRSA"|"SHA384WITHRSA"|"SHA512WITHRSA", Subject: record, CsrExtensions?: record}
  --revocation-configuration: record # Certificate revocation information used by the CreateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthority.html) and UpdateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_UpdateCertificateAuthority.html) actions. Your private certificate authority (CA) can configure Online Certificate Status Protocol (OCSP) support and/or maintain a certificate revocation list (CRL). OCSP returns validation information about certificates as requested by clients, and a CRL contains an updated list of certificates revoked by your CA. For more information, see RevokeCertificate (https://docs.aws.amazon.com/privateca/latest/APIReference/API_RevokeCertificate.html) and Setting up a certificate revocation method (https://docs.aws.amazon.com/privateca/latest/userguide/revocation-setup.html) in the Amazon Web Services Private Certificate Authority User Guide. — shape: {CrlConfiguration?: record, OcspConfiguration?: record}
  certificate_authority_type: string@certificate-authority-type-completer # The type of the certificate authority.
  --idempotency-token: string # Custom string that can be used to distinguish between calls to the CreateCertificateAuthority action. Idempotency tokens for CreateCertificateAuthority time out after five minutes. Therefore, if you call CreateCertificateAuthority multiple times with the same idempotency token within five minutes, Amazon Web Services Private CA recognizes that you are requesting only certificate authority and will issue only one. If you change the idempotency token for each call, Amazon Web Services Private CA recognizes that you are requesting multiple certificate authorities.
  --key-storage-security-standard: string@key-storage-security-standard-completer # Specifies a cryptographic key management compliance standard used for handling CA keys. Default: FIPS_140_2_LEVEL_3_OR_HIGHER Note: FIPS_140_2_LEVEL_3_OR_HIGHER is not supported in the following Regions: ap-northeast-3 ap-southeast-3 When creating a CA in these Regions, you must provide FIPS_140_2_LEVEL_2_OR_HIGHER as the argument for KeyStorageSecurityStandard. Failure to do this results in an InvalidArgsException with the message, "A certificate authority cannot be created in this region with the specified security standard."
  --tags: list # Key-value pairs that will be attached to the new private CA. You can associate up to 50 tags with a private CA. For information using tags with IAM to manage permissions, see Controlling Access Using IAM Tags (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_iam-tags.html). — item shape: {Key: string, Value?: string}
  --usage-mode: string@usage-mode-completer # Specifies whether the CA issues general-purpose certificates that typically require a revocation mechanism, or short-lived certificates that may optionally omit revocation because they expire quickly. Short-lived certificate validity is limited to seven days. The default value is GENERAL_PURPOSE.
]: any -> oneof<record<CertificateAuthorityArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.CreateCertificateAuthority")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CertificateAuthorityConfiguration": $certificate_authority_configuration, "RevocationConfiguration": $revocation_configuration, "CertificateAuthorityType": $certificate_authority_type, "IdempotencyToken": $idempotency_token, "KeyStorageSecurityStandard": $key_storage_security_standard, "Tags": $tags, "UsageMode": $usage_mode} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Creates an audit report that lists every time that your CA private key is used. The report is saved in the Amazon S3 bucket that you specify on input. The IssueCertificate (https://docs.aws.amazon.com/privateca/latest/APIReference/API_IssueCertificate.html) and RevokeCertificate (https://docs.aws.amazon.com/privateca/latest/APIReference/API_RevokeCertificate.html) actions use the private key. Both Amazon Web Services Private CA and the IAM principal must have permission to write to the S3 bucket that you specify. If the IAM principal making the call does not have permission to write to the bucket, then an exception is thrown. For more information, see Access policies for CRLs in Amazon S3 (https://docs.aws.amazon.com/privateca/latest/userguide/crl-planning.html#s3-policies). Amazon Web Services Private CA assets that are stored in Amazon S3 can be protected with encryption. For more information, see Encrypting Your Audit Reports (https://docs.aws.amazon.com/privateca/latest/userguide/PcaAuditReport.html#audit-report-encryption). You can generate a maximum of one report every 30 minutes.
#
# POST /
# operationId: CreateCertificateAuthorityAuditReport
export def "create-certificate-authority-audit-report" [
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
  --x-amz-target: string@x-amz-target-completer-1 # required
  certificate_authority_arn: string # The Amazon Resource Name (ARN) of the CA to be audited. This is of the form: arn:aws:acm-pca:region:account:certificate-authority/12345678-1234-1234-1234-123456789012 .
  s3_bucket_name: string # The name of the S3 bucket that will contain the audit report.
  audit_report_response_format: string@audit-report-response-format-completer # The format in which to create the report. This can be either JSON or CSV.
]: any -> oneof<record<AuditReportId: string, S3Key: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.CreateCertificateAuthorityAuditReport")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "S3BucketName": $s3_bucket_name, "AuditReportResponseFormat": $audit_report_response_format} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Grants one or more permissions on a private CA to the Certificate Manager (ACM) service principal (acm.amazonaws.com). These permissions allow ACM to issue and renew ACM certificates that reside in the same Amazon Web Services account as the CA. You can list current permissions with the ListPermissions (https://docs.aws.amazon.com/privateca/latest/APIReference/API_ListPermissions.html) action and revoke them with the DeletePermission (https://docs.aws.amazon.com/privateca/latest/APIReference/API_DeletePermission.html) action. About Permissions If the private CA and the certificates it issues reside in the same account, you can use CreatePermission to grant permissions for ACM to carry out automatic certificate renewals. For automatic certificate renewal to succeed, the ACM service principal needs permissions to create, retrieve, and list certificates. If the private CA and the ACM certificates reside in different accounts, then permissions cannot be used to enable automatic renewals. Instead, the ACM certificate owner must set up a resource-based policy to enable cross-account issuance and renewals. For more information, see Using a Resource Based Policy with Amazon Web Services Private CA (https://docs.aws.amazon.com/privateca/latest/userguide/pca-rbp.html).
#
# POST /
# operationId: CreatePermission
export def "create-permission" [
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
  --x-amz-target: string@x-amz-target-completer-2 # required
  certificate_authority_arn: string # The Amazon Resource Name (ARN) of the CA that grants the permissions. You can find the ARN by calling the ListCertificateAuthorities (https://docs.aws.amazon.com/privateca/latest/APIReference/API_ListCertificateAuthorities.html) action. This must have the following form: arn:aws:acm-pca:region:account:certificate-authority/12345678-1234-1234-1234-123456789012 .
  principal: string # The Amazon Web Services service or identity that receives the permission. At this time, the only valid principal is acm.amazonaws.com.
  --source-account: string # The ID of the calling account.
  actions: list<string> # The actions that the specified Amazon Web Services service principal can use. These include IssueCertificate, GetCertificate, and ListPermissions.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.CreatePermission")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "Principal": $principal, "SourceAccount": $source_account, "Actions": $actions} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Deletes a private certificate authority (CA). You must provide the Amazon Resource Name (ARN) of the private CA that you want to delete. You can find the ARN by calling the ListCertificateAuthorities (https://docs.aws.amazon.com/privateca/latest/APIReference/API_ListCertificateAuthorities.html) action. Deleting a CA will invalidate other CAs and certificates below it in your CA hierarchy. Before you can delete a CA that you have created and activated, you must disable it. To do this, call the UpdateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_UpdateCertificateAuthority.html) action and set the CertificateAuthorityStatus parameter to DISABLED. Additionally, you can delete a CA if you are waiting for it to be created (that is, the status of the CA is CREATING). You can also delete it if the CA has been created but you haven't yet imported the signed certificate into Amazon Web Services Private CA (that is, the status of the CA is PENDING_CERTIFICATE). When you successfully call DeleteCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_DeleteCertificateAuthority.html), the CA's status changes to DELETED. However, the CA won't be permanently deleted until the restoration period has passed. By default, if you do not set the PermanentDeletionTimeInDays parameter, the CA remains restorable for 30 days. You can set the parameter from 7 to 30 days. The DescribeCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_DescribeCertificateAuthority.html) action returns the time remaining in the restoration window of a private CA in the DELETED state. To restore an eligible CA, call the RestoreCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_RestoreCertificateAuthority.html) action.
#
# POST /
# operationId: DeleteCertificateAuthority
export def "delete-certificate-authority" [
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
  --x-amz-target: string@x-amz-target-completer-3 # required
  certificate_authority_arn: string # The Amazon Resource Name (ARN) that was returned when you called CreateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthority.html). This must have the following form: arn:aws:acm-pca:region:account:certificate-authority/12345678-1234-1234-1234-123456789012 .
  --permanent-deletion-time-in-days: int # The number of days to make a CA restorable after it has been deleted. This can be anywhere from 7 to 30 days, with 30 being the default.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.DeleteCertificateAuthority")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "PermanentDeletionTimeInDays": $permanent_deletion_time_in_days} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Revokes permissions on a private CA granted to the Certificate Manager (ACM) service principal (acm.amazonaws.com). These permissions allow ACM to issue and renew ACM certificates that reside in the same Amazon Web Services account as the CA. If you revoke these permissions, ACM will no longer renew the affected certificates automatically. Permissions can be granted with the CreatePermission (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreatePermission.html) action and listed with the ListPermissions (https://docs.aws.amazon.com/privateca/latest/APIReference/API_ListPermissions.html) action. About Permissions If the private CA and the certificates it issues reside in the same account, you can use CreatePermission to grant permissions for ACM to carry out automatic certificate renewals. For automatic certificate renewal to succeed, the ACM service principal needs permissions to create, retrieve, and list certificates. If the private CA and the ACM certificates reside in different accounts, then permissions cannot be used to enable automatic renewals. Instead, the ACM certificate owner must set up a resource-based policy to enable cross-account issuance and renewals. For more information, see Using a Resource Based Policy with Amazon Web Services Private CA (https://docs.aws.amazon.com/privateca/latest/userguide/pca-rbp.html).
#
# POST /
# operationId: DeletePermission
export def "delete-permission" [
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
  --x-amz-target: string@x-amz-target-completer-4 # required
  certificate_authority_arn: string # The Amazon Resource Number (ARN) of the private CA that issued the permissions. You can find the CA's ARN by calling the ListCertificateAuthorities (https://docs.aws.amazon.com/privateca/latest/APIReference/API_ListCertificateAuthorities.html) action. This must have the following form: arn:aws:acm-pca:region:account:certificate-authority/12345678-1234-1234-1234-123456789012 .
  principal: string # The Amazon Web Services service or identity that will have its CA permissions revoked. At this time, the only valid service principal is acm.amazonaws.com
  --source-account: string # The Amazon Web Services account that calls this action.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.DeletePermission")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "Principal": $principal, "SourceAccount": $source_account} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Deletes the resource-based policy attached to a private CA. Deletion will remove any access that the policy has granted. If there is no policy attached to the private CA, this action will return successful. If you delete a policy that was applied through Amazon Web Services Resource Access Manager (RAM), the CA will be removed from all shares in which it was included. The Certificate Manager Service Linked Role that the policy supports is not affected when you delete the policy. The current policy can be shown with GetPolicy (https://docs.aws.amazon.com/privateca/latest/APIReference/API_GetPolicy.html) and updated with PutPolicy (https://docs.aws.amazon.com/privateca/latest/APIReference/API_PutPolicy.html). About Policies A policy grants access on a private CA to an Amazon Web Services customer account, to Amazon Web Services Organizations, or to an Amazon Web Services Organizations unit. Policies are under the control of a CA administrator. For more information, see Using a Resource Based Policy with Amazon Web Services Private CA (https://docs.aws.amazon.com/privateca/latest/userguide/pca-rbp.html). A policy permits a user of Certificate Manager (ACM) to issue ACM certificates signed by a CA in another account. For ACM to manage automatic renewal of these certificates, the ACM user must configure a Service Linked Role (SLR). The SLR allows the ACM service to assume the identity of the user, subject to confirmation against the Amazon Web Services Private CA policy. For more information, see Using a Service Linked Role with ACM (https://docs.aws.amazon.com/acm/latest/userguide/acm-slr.html). Updates made in Amazon Web Services Resource Manager (RAM) are reflected in policies. For more information, see Attach a Policy for Cross-Account Access (https://docs.aws.amazon.com/privateca/latest/userguide/pca-ram.html).
#
# POST /
# operationId: DeletePolicy
export def "delete-policy" [
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
  --x-amz-target: string@x-amz-target-completer-5 # required
  resource_arn: string # The Amazon Resource Number (ARN) of the private CA that will have its policy deleted. You can find the CA's ARN by calling the ListCertificateAuthorities (https://docs.aws.amazon.com/privateca/latest/APIReference/API_ListCertificateAuthorities.html) action. The ARN value must have the form arn:aws:acm-pca:region:account:certificate-authority/01234567-89ab-cdef-0123-0123456789ab.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.DeletePolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Lists information about your private certificate authority (CA) or one that has been shared with you. You specify the private CA on input by its ARN (Amazon Resource Name). The output contains the status of your CA. This can be any of the following: CREATING - Amazon Web Services Private CA is creating your private certificate authority. PENDING_CERTIFICATE - The certificate is pending. You must use your Amazon Web Services Private CA-hosted or on-premises root or subordinate CA to sign your private CA CSR and then import it into Amazon Web Services Private CA. ACTIVE - Your private CA is active. DISABLED - Your private CA has been disabled. EXPIRED - Your private CA certificate has expired. FAILED - Your private CA has failed. Your CA can fail because of problems such a network outage or back-end Amazon Web Services failure or other errors. A failed CA can never return to the pending state. You must create a new CA. DELETED - Your private CA is within the restoration period, after which it is permanently deleted. The length of time remaining in the CA's restoration period is also included in this action's output.
#
# POST /
# operationId: DescribeCertificateAuthority
export def "describe-certificate-authority" [
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
  --x-amz-target: string@x-amz-target-completer-6 # required
  certificate_authority_arn: string # The Amazon Resource Name (ARN) that was returned when you called CreateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthority.html). This must be of the form: arn:aws:acm-pca:region:account:certificate-authority/12345678-1234-1234-1234-123456789012 .
]: any -> oneof<record<CertificateAuthority: record<Arn: string, OwnerAccount: string, CreatedAt: string, LastStateChangeAt: string, Type: string, Serial: string, Status: string, NotBefore: string, NotAfter: string, FailureReason: string, CertificateAuthorityConfiguration: record<KeyAlgorithm: string, SigningAlgorithm: string, Subject: record, CsrExtensions: record>, RevocationConfiguration: record<CrlConfiguration: record, OcspConfiguration: record>, RestorableUntil: string, KeyStorageSecurityStandard: string, UsageMode: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.DescribeCertificateAuthority")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Lists information about a specific audit report created by calling the CreateCertificateAuthorityAuditReport (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthorityAuditReport.html) action. Audit information is created every time the certificate authority (CA) private key is used. The private key is used when you call the IssueCertificate (https://docs.aws.amazon.com/privateca/latest/APIReference/API_IssueCertificate.html) action or the RevokeCertificate (https://docs.aws.amazon.com/privateca/latest/APIReference/API_RevokeCertificate.html) action.
#
# POST /
# operationId: DescribeCertificateAuthorityAuditReport
export def "describe-certificate-authority-audit-report" [
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
  --x-amz-target: string@x-amz-target-completer-7 # required
  certificate_authority_arn: string # The Amazon Resource Name (ARN) of the private CA. This must be of the form: arn:aws:acm-pca:region:account:certificate-authority/12345678-1234-1234-1234-123456789012 .
  audit_report_id: string # The report ID returned by calling the CreateCertificateAuthorityAuditReport (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthorityAuditReport.html) action.
]: any -> oneof<record<AuditReportStatus: string, S3BucketName: string, S3Key: string, CreatedAt: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.DescribeCertificateAuthorityAuditReport")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "AuditReportId": $audit_report_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Retrieves a certificate from your private CA or one that has been shared with you. The ARN of the certificate is returned when you call the IssueCertificate (https://docs.aws.amazon.com/privateca/latest/APIReference/API_IssueCertificate.html) action. You must specify both the ARN of your private CA and the ARN of the issued certificate when calling the GetCertificate action. You can retrieve the certificate if it is in the ISSUED state. You can call the CreateCertificateAuthorityAuditReport (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthorityAuditReport.html) action to create a report that contains information about all of the certificates issued and revoked by your private CA.
#
# POST /
# operationId: GetCertificate
export def "get-certificate" [
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
  --x-amz-target: string@x-amz-target-completer-8 # required
  certificate_authority_arn: string # The Amazon Resource Name (ARN) that was returned when you called CreateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthority.html). This must be of the form: arn:aws:acm-pca:region:account:certificate-authority/12345678-1234-1234-1234-123456789012 .
  certificate_arn: string # The ARN of the issued certificate. The ARN contains the certificate serial number and must be in the following form: arn:aws:acm-pca:region:account:certificate-authority/12345678-1234-1234-1234-123456789012/certificate/286535153982981100925020015808220737245
]: any -> oneof<record<Certificate: string, CertificateChain: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.GetCertificate")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "CertificateArn": $certificate_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Retrieves the certificate and certificate chain for your private certificate authority (CA) or one that has been shared with you. Both the certificate and the chain are base64 PEM-encoded. The chain does not include the CA certificate. Each certificate in the chain signs the one before it.
#
# POST /
# operationId: GetCertificateAuthorityCertificate
export def "get-certificate-authority-certificate" [
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
  --x-amz-target: string@x-amz-target-completer-9 # required
  certificate_authority_arn: string # The Amazon Resource Name (ARN) of your private CA. This is of the form: arn:aws:acm-pca:region:account:certificate-authority/12345678-1234-1234-1234-123456789012 .
]: any -> oneof<record<Certificate: string, CertificateChain: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.GetCertificateAuthorityCertificate")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Retrieves the certificate signing request (CSR) for your private certificate authority (CA). The CSR is created when you call the CreateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthority.html) action. Sign the CSR with your Amazon Web Services Private CA-hosted or on-premises root or subordinate CA. Then import the signed certificate back into Amazon Web Services Private CA by calling the ImportCertificateAuthorityCertificate (https://docs.aws.amazon.com/privateca/latest/APIReference/API_ImportCertificateAuthorityCertificate.html) action. The CSR is returned as a base64 PEM-encoded string.
#
# POST /
# operationId: GetCertificateAuthorityCsr
export def "get-certificate-authority-csr" [
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
  --x-amz-target: string@x-amz-target-completer-10 # required
  certificate_authority_arn: string # The Amazon Resource Name (ARN) that was returned when you called the CreateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthority.html) action. This must be of the form: arn:aws:acm-pca:region:account:certificate-authority/12345678-1234-1234-1234-123456789012
]: any -> oneof<record<Csr: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.GetCertificateAuthorityCsr")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Retrieves the resource-based policy attached to a private CA. If either the private CA resource or the policy cannot be found, this action returns a ResourceNotFoundException. The policy can be attached or updated with PutPolicy (https://docs.aws.amazon.com/privateca/latest/APIReference/API_PutPolicy.html) and removed with DeletePolicy (https://docs.aws.amazon.com/privateca/latest/APIReference/API_DeletePolicy.html). About Policies A policy grants access on a private CA to an Amazon Web Services customer account, to Amazon Web Services Organizations, or to an Amazon Web Services Organizations unit. Policies are under the control of a CA administrator. For more information, see Using a Resource Based Policy with Amazon Web Services Private CA (https://docs.aws.amazon.com/privateca/latest/userguide/pca-rbp.html). A policy permits a user of Certificate Manager (ACM) to issue ACM certificates signed by a CA in another account. For ACM to manage automatic renewal of these certificates, the ACM user must configure a Service Linked Role (SLR). The SLR allows the ACM service to assume the identity of the user, subject to confirmation against the Amazon Web Services Private CA policy. For more information, see Using a Service Linked Role with ACM (https://docs.aws.amazon.com/acm/latest/userguide/acm-slr.html). Updates made in Amazon Web Services Resource Manager (RAM) are reflected in policies. For more information, see Attach a Policy for Cross-Account Access (https://docs.aws.amazon.com/privateca/latest/userguide/pca-ram.html).
#
# POST /
# operationId: GetPolicy
export def "get-policy" [
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
  --x-amz-target: string@x-amz-target-completer-11 # required
  resource_arn: string # The Amazon Resource Number (ARN) of the private CA that will have its policy retrieved. You can find the CA's ARN by calling the ListCertificateAuthorities action.
]: any -> oneof<record<Policy: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.GetPolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Imports a signed private CA certificate into Amazon Web Services Private CA. This action is used when you are using a chain of trust whose root is located outside Amazon Web Services Private CA. Before you can call this action, the following preparations must in place: In Amazon Web Services Private CA, call the CreateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthority.html) action to create the private CA that you plan to back with the imported certificate. Call the GetCertificateAuthorityCsr (https://docs.aws.amazon.com/privateca/latest/APIReference/API_GetCertificateAuthorityCsr.html) action to generate a certificate signing request (CSR). Sign the CSR using a root or intermediate CA hosted by either an on-premises PKI hierarchy or by a commercial CA. Create a certificate chain and copy the signed certificate and the certificate chain to your working directory. Amazon Web Services Private CA supports three scenarios for installing a CA certificate: Installing a certificate for a root CA hosted by Amazon Web Services Private CA. Installing a subordinate CA certificate whose parent authority is hosted by Amazon Web Services Private CA. Installing a subordinate CA certificate whose parent authority is externally hosted. The following additional requirements apply when you import a CA certificate. Only a self-signed certificate can be imported as a root CA. A self-signed certificate cannot be imported as a subordinate CA. Your certificate chain must not include the private CA certificate that you are importing. Your root CA must be the last certificate in your chain. The subordinate certificate, if any, that your root CA signed must be next to last. The subordinate certificate signed by the preceding subordinate CA must come next, and so on until your chain is built. The chain must be PEM-encoded. The maximum allowed size of a certificate is 32 KB. The maximum allowed size of a certificate chain is 2 MB. Enforcement of Critical Constraints Amazon Web Services Private CA allows the following extensions to be marked critical in the imported CA certificate or chain. Basic constraints (must be marked critical) Subject alternative names Key usage Extended key usage Authority key identifier Subject key identifier Issuer alternative name Subject directory attributes Subject information access Certificate policies Policy mappings Inhibit anyPolicy Amazon Web Services Private CA rejects the following extensions when they are marked critical in an imported CA certificate or chain. Name constraints Policy constraints CRL distribution points Authority information access Freshest CRL Any other extension
#
# POST /
# operationId: ImportCertificateAuthorityCertificate
export def "import-certificate-authority-certificate" [
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
  --x-amz-target: string@x-amz-target-completer-12 # required
  certificate_authority_arn: string # The Amazon Resource Name (ARN) that was returned when you called CreateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthority.html). This must be of the form: arn:aws:acm-pca:region:account:certificate-authority/12345678-1234-1234-1234-123456789012
  certificate: string # The PEM-encoded certificate for a private CA. This may be a self-signed certificate in the case of a root CA, or it may be signed by another CA that you control.
  --certificate-chain: string # A PEM-encoded file that contains all of your certificates, other than the certificate you're importing, chaining up to your root CA. Your Amazon Web Services Private CA-hosted or on-premises root certificate is the last in the chain, and each certificate in the chain signs the one preceding. This parameter must be supplied when you import a subordinate CA. When you import a root CA, there is no chain.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.ImportCertificateAuthorityCertificate")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "Certificate": $certificate, "CertificateChain": $certificate_chain} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Uses your private certificate authority (CA), or one that has been shared with you, to issue a client certificate. This action returns the Amazon Resource Name (ARN) of the certificate. You can retrieve the certificate by calling the GetCertificate (https://docs.aws.amazon.com/privateca/latest/APIReference/API_GetCertificate.html) action and specifying the ARN. You cannot use the ACM ListCertificateAuthorities action to retrieve the ARNs of the certificates that you issue by using Amazon Web Services Private CA.
#
# POST /
# operationId: IssueCertificate
export def "issue-certificate" [
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
  --x-amz-target: string@x-amz-target-completer-13 # required
  --api-passthrough: record # Contains X.509 certificate information to be placed in an issued certificate. An APIPassthrough or APICSRPassthrough template variant must be selected, or else this parameter is ignored. If conflicting or duplicate certificate information is supplied from other sources, Amazon Web Services Private CA applies order of operation rules (https://docs.aws.amazon.com/privateca/latest/userguide/UsingTemplates.html#template-order-of-operations) to determine what information is used. — shape: {Extensions?: record, Subject?: record}
  certificate_authority_arn: string # The Amazon Resource Name (ARN) that was returned when you called CreateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthority.html). This must be of the form: arn:aws:acm-pca:region:account:certificate-authority/12345678-1234-1234-1234-123456789012
  csr: string # The certificate signing request (CSR) for the certificate you want to issue. As an example, you can use the following OpenSSL command to create the CSR and a 2048 bit RSA private key. openssl req -new -newkey rsa:2048 -days 365 -keyout private/test_cert_priv_key.pem -out csr/test_cert_.csr If you have a configuration file, you can then use the following OpenSSL command. The usr_cert block in the configuration file contains your X509 version 3 extensions. openssl req -new -config openssl_rsa.cnf -extensions usr_cert -newkey rsa:2048 -days 365 -keyout private/test_cert_priv_key.pem -out csr/test_cert_.csr Note: A CSR must provide either a subject name or a subject alternative name or the request will be rejected.
  signing_algorithm: string@signing-algorithm-completer # The name of the algorithm that will be used to sign the certificate to be issued. This parameter should not be confused with the SigningAlgorithm parameter used to sign a CSR in the CreateCertificateAuthority action. The specified signing algorithm family (RSA or ECDSA) much match the algorithm family of the CA's secret key.
  --template-arn: string # Specifies a custom configuration template to use when issuing a certificate. If this parameter is not provided, Amazon Web Services Private CA defaults to the EndEntityCertificate/V1 template. For CA certificates, you should choose the shortest path length that meets your needs. The path length is indicated by the PathLenN portion of the ARN, where N is the CA depth (https://docs.aws.amazon.com/privateca/latest/userguide/PcaTerms.html#terms-cadepth). Note: The CA depth configured on a subordinate CA certificate must not exceed the limit set by its parents in the CA hierarchy. For a list of TemplateArn values supported by Amazon Web Services Private CA, see Understanding Certificate Templates (https://docs.aws.amazon.com/privateca/latest/userguide/UsingTemplates.html).
  validity: record # Validity specifies the period of time during which a certificate is valid. Validity can be expressed as an explicit date and time when the validity of a certificate starts or expires, or as a span of time after issuance, stated in days, months, or years. For more information, see Validity (https://tools.ietf.org/html/rfc5280#section-4.1.2.5) in RFC 5280. Amazon Web Services Private CA API consumes the Validity data type differently in two distinct parameters of the IssueCertificate action. The required parameter IssueCertificate:Validity specifies the end of a certificate's validity period. The optional parameter IssueCertificate:ValidityNotBefore specifies a customized starting time for the validity period. — shape: {Value: int, Type: "END_DATE"|"ABSOLUTE"|"DAYS"|"MONTHS"|"YEARS"}
  --validity-not-before: record # Validity specifies the period of time during which a certificate is valid. Validity can be expressed as an explicit date and time when the validity of a certificate starts or expires, or as a span of time after issuance, stated in days, months, or years. For more information, see Validity (https://tools.ietf.org/html/rfc5280#section-4.1.2.5) in RFC 5280. Amazon Web Services Private CA API consumes the Validity data type differently in two distinct parameters of the IssueCertificate action. The required parameter IssueCertificate:Validity specifies the end of a certificate's validity period. The optional parameter IssueCertificate:ValidityNotBefore specifies a customized starting time for the validity period. — shape: {Value: int, Type: "END_DATE"|"ABSOLUTE"|"DAYS"|"MONTHS"|"YEARS"}
  --idempotency-token: string # Alphanumeric string that can be used to distinguish between calls to the IssueCertificate action. Idempotency tokens for IssueCertificate time out after one minute. Therefore, if you call IssueCertificate multiple times with the same idempotency token within one minute, Amazon Web Services Private CA recognizes that you are requesting only one certificate and will issue only one. If you change the idempotency token for each call, Amazon Web Services Private CA recognizes that you are requesting multiple certificates.
]: any -> oneof<record<CertificateArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.IssueCertificate")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApiPassthrough": $api_passthrough, "CertificateAuthorityArn": $certificate_authority_arn, "Csr": $csr, "SigningAlgorithm": $signing_algorithm, "TemplateArn": $template_arn, "Validity": $validity, "ValidityNotBefore": $validity_not_before, "IdempotencyToken": $idempotency_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Lists the private certificate authorities that you created by using the CreateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthority.html) action.
#
# POST /
# operationId: ListCertificateAuthorities
export def "list-certificate-authorities" [
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
  --x-amz-target: string@x-amz-target-completer-14 # required
  --body-next-token: string # Use this parameter when paginating results in a subsequent request after you receive a response with truncated results. Set it to the value of the NextToken parameter from the response you just received. (spec name: NextToken)
  --body-max-results: int # Use this parameter when paginating results to specify the maximum number of items to return in the response on each page. If additional items exist beyond the number you specify, the NextToken element is sent in the response. Use this NextToken value in a subsequent request to retrieve additional items. (spec name: MaxResults)
  --resource-owner: string@resource-owner-completer # Use this parameter to filter the returned set of certificate authorities based on their owner. The default is SELF.
]: any -> oneof<record<CertificateAuthorities: table<Arn: string, OwnerAccount: string, CreatedAt: string, LastStateChangeAt: string, Type: string, Serial: string, Status: string, NotBefore: string, NotAfter: string, FailureReason: string, CertificateAuthorityConfiguration: record, RevocationConfiguration: record, RestorableUntil: string, KeyStorageSecurityStandard: string, UsageMode: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.ListCertificateAuthorities")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"NextToken": $body_next_token, "MaxResults": $body_max_results, "ResourceOwner": $resource_owner} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List all permissions on a private CA, if any, granted to the Certificate Manager (ACM) service principal (acm.amazonaws.com). These permissions allow ACM to issue and renew ACM certificates that reside in the same Amazon Web Services account as the CA. Permissions can be granted with the CreatePermission (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreatePermission.html) action and revoked with the DeletePermission (https://docs.aws.amazon.com/privateca/latest/APIReference/API_DeletePermission.html) action. About Permissions If the private CA and the certificates it issues reside in the same account, you can use CreatePermission to grant permissions for ACM to carry out automatic certificate renewals. For automatic certificate renewal to succeed, the ACM service principal needs permissions to create, retrieve, and list certificates. If the private CA and the ACM certificates reside in different accounts, then permissions cannot be used to enable automatic renewals. Instead, the ACM certificate owner must set up a resource-based policy to enable cross-account issuance and renewals. For more information, see Using a Resource Based Policy with Amazon Web Services Private CA (https://docs.aws.amazon.com/privateca/latest/userguide/pca-rbp.html).
#
# POST /
# operationId: ListPermissions
export def "list-permissions" [
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
  --x-amz-target: string@x-amz-target-completer-15 # required
  certificate_authority_arn: string # The Amazon Resource Number (ARN) of the private CA to inspect. You can find the ARN by calling the ListCertificateAuthorities (https://docs.aws.amazon.com/privateca/latest/APIReference/API_ListCertificateAuthorities.html) action. This must be of the form: arn:aws:acm-pca:region:account:certificate-authority/12345678-1234-1234-1234-123456789012 You can get a private CA's ARN by running the ListCertificateAuthorities (https://docs.aws.amazon.com/privateca/latest/APIReference/API_ListCertificateAuthorities.html) action.
  --body-next-token: string # When paginating results, use this parameter in a subsequent request after you receive a response with truncated results. Set it to the value of NextToken from the response you just received. (spec name: NextToken)
  --body-max-results: int # When paginating results, use this parameter to specify the maximum number of items to return in the response. If additional items exist beyond the number you specify, the NextToken element is sent in the response. Use this NextToken value in a subsequent request to retrieve additional items. (spec name: MaxResults)
]: any -> oneof<record<Permissions: table<CertificateAuthorityArn: string, CreatedAt: string, Principal: string, SourceAccount: string, Actions: list, Policy: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.ListPermissions")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "NextToken": $body_next_token, "MaxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the tags, if any, that are associated with your private CA or one that has been shared with you. Tags are labels that you can use to identify and organize your CAs. Each tag consists of a key and an optional value. Call the TagCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_TagCertificateAuthority.html) action to add one or more tags to your CA. Call the UntagCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_UntagCertificateAuthority.html) action to remove tags.
#
# POST /
# operationId: ListTags
export def "list-tags" [
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
  --x-amz-target: string@x-amz-target-completer-16 # required
  certificate_authority_arn: string # The Amazon Resource Name (ARN) that was returned when you called the CreateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthority.html) action. This must be of the form: arn:aws:acm-pca:region:account:certificate-authority/12345678-1234-1234-1234-123456789012
  --body-next-token: string # Use this parameter when paginating results in a subsequent request after you receive a response with truncated results. Set it to the value of NextToken from the response you just received. (spec name: NextToken)
  --body-max-results: int # Use this parameter when paginating results to specify the maximum number of items to return in the response. If additional items exist beyond the number you specify, the NextToken element is sent in the response. Use this NextToken value in a subsequent request to retrieve additional items. (spec name: MaxResults)
]: any -> oneof<record<Tags: table<Key: string, Value: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.ListTags")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "NextToken": $body_next_token, "MaxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Attaches a resource-based policy to a private CA. A policy can also be applied by sharing a private CA through Amazon Web Services Resource Access Manager (RAM). For more information, see Attach a Policy for Cross-Account Access (https://docs.aws.amazon.com/privateca/latest/userguide/pca-ram.html). The policy can be displayed with GetPolicy (https://docs.aws.amazon.com/privateca/latest/APIReference/API_GetPolicy.html) and removed with DeletePolicy (https://docs.aws.amazon.com/privateca/latest/APIReference/API_DeletePolicy.html). About Policies A policy grants access on a private CA to an Amazon Web Services customer account, to Amazon Web Services Organizations, or to an Amazon Web Services Organizations unit. Policies are under the control of a CA administrator. For more information, see Using a Resource Based Policy with Amazon Web Services Private CA (https://docs.aws.amazon.com/privateca/latest/userguide/pca-rbp.html). A policy permits a user of Certificate Manager (ACM) to issue ACM certificates signed by a CA in another account. For ACM to manage automatic renewal of these certificates, the ACM user must configure a Service Linked Role (SLR). The SLR allows the ACM service to assume the identity of the user, subject to confirmation against the Amazon Web Services Private CA policy. For more information, see Using a Service Linked Role with ACM (https://docs.aws.amazon.com/acm/latest/userguide/acm-slr.html). Updates made in Amazon Web Services Resource Manager (RAM) are reflected in policies. For more information, see Attach a Policy for Cross-Account Access (https://docs.aws.amazon.com/privateca/latest/userguide/pca-ram.html).
#
# POST /
# operationId: PutPolicy
export def "put-policy" [
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
  --x-amz-target: string@x-amz-target-completer-17 # required
  resource_arn: string # The Amazon Resource Number (ARN) of the private CA to associate with the policy. The ARN of the CA can be found by calling the ListCertificateAuthorities (https://docs.aws.amazon.com/privateca/latest/APIReference/API_ListCertificateAuthorities.html) action.
  policy: string # The path and file name of a JSON-formatted IAM policy to attach to the specified private CA resource. If this policy does not contain all required statements or if it includes any statement that is not allowed, the PutPolicy action returns an InvalidPolicyException. For information about IAM policy and statement structure, see Overview of JSON Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#access_policies-json).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.PutPolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "Policy": $policy} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Restores a certificate authority (CA) that is in the DELETED state. You can restore a CA during the period that you defined in the PermanentDeletionTimeInDays parameter of the DeleteCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_DeleteCertificateAuthority.html) action. Currently, you can specify 7 to 30 days. If you did not specify a PermanentDeletionTimeInDays value, by default you can restore the CA at any time in a 30 day period. You can check the time remaining in the restoration period of a private CA in the DELETED state by calling the DescribeCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_DescribeCertificateAuthority.html) or ListCertificateAuthorities (https://docs.aws.amazon.com/privateca/latest/APIReference/API_ListCertificateAuthorities.html) actions. The status of a restored CA is set to its pre-deletion status when the RestoreCertificateAuthority action returns. To change its status to ACTIVE, call the UpdateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_UpdateCertificateAuthority.html) action. If the private CA was in the PENDING_CERTIFICATE state at deletion, you must use the ImportCertificateAuthorityCertificate (https://docs.aws.amazon.com/privateca/latest/APIReference/API_ImportCertificateAuthorityCertificate.html) action to import a certificate authority into the private CA before it can be activated. You cannot restore a CA after the restoration period has ended.
#
# POST /
# operationId: RestoreCertificateAuthority
export def "restore-certificate-authority" [
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
  --x-amz-target: string@x-amz-target-completer-18 # required
  certificate_authority_arn: string # The Amazon Resource Name (ARN) that was returned when you called the CreateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthority.html) action. This must be of the form: arn:aws:acm-pca:region:account:certificate-authority/12345678-1234-1234-1234-123456789012
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.RestoreCertificateAuthority")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Revokes a certificate that was issued inside Amazon Web Services Private CA. If you enable a certificate revocation list (CRL) when you create or update your private CA, information about the revoked certificates will be included in the CRL. Amazon Web Services Private CA writes the CRL to an S3 bucket that you specify. A CRL is typically updated approximately 30 minutes after a certificate is revoked. If for any reason the CRL update fails, Amazon Web Services Private CA attempts makes further attempts every 15 minutes. With Amazon CloudWatch, you can create alarms for the metrics CRLGenerated and MisconfiguredCRLBucket. For more information, see Supported CloudWatch Metrics (https://docs.aws.amazon.com/privateca/latest/userguide/PcaCloudWatch.html). Both Amazon Web Services Private CA and the IAM principal must have permission to write to the S3 bucket that you specify. If the IAM principal making the call does not have permission to write to the bucket, then an exception is thrown. For more information, see Access policies for CRLs in Amazon S3 (https://docs.aws.amazon.com/privateca/latest/userguide/crl-planning.html#s3-policies). Amazon Web Services Private CA also writes revocation information to the audit report. For more information, see CreateCertificateAuthorityAuditReport (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthorityAuditReport.html). You cannot revoke a root CA self-signed certificate.
#
# POST /
# operationId: RevokeCertificate
export def "revoke-certificate" [
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
  --x-amz-target: string@x-amz-target-completer-19 # required
  certificate_authority_arn: string # Amazon Resource Name (ARN) of the private CA that issued the certificate to be revoked. This must be of the form: arn:aws:acm-pca:region:account:certificate-authority/12345678-1234-1234-1234-123456789012
  certificate_serial: string # Serial number of the certificate to be revoked. This must be in hexadecimal format. You can retrieve the serial number by calling GetCertificate (https://docs.aws.amazon.com/privateca/latest/APIReference/API_GetCertificate.html) with the Amazon Resource Name (ARN) of the certificate you want and the ARN of your private CA. The GetCertificate action retrieves the certificate in the PEM format. You can use the following OpenSSL command to list the certificate in text format and copy the hexadecimal serial number. openssl x509 -in file_path -text -noout You can also copy the serial number from the console or use the DescribeCertificate (https://docs.aws.amazon.com/acm/latest/APIReference/API_DescribeCertificate.html) action in the Certificate Manager API Reference.
  revocation_reason: string@revocation-reason-completer # Specifies why you revoked the certificate.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.RevokeCertificate")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "CertificateSerial": $certificate_serial, "RevocationReason": $revocation_reason} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Adds one or more tags to your private CA. Tags are labels that you can use to identify and organize your Amazon Web Services resources. Each tag consists of a key and an optional value. You specify the private CA on input by its Amazon Resource Name (ARN). You specify the tag by using a key-value pair. You can apply a tag to just one private CA if you want to identify a specific characteristic of that CA, or you can apply the same tag to multiple private CAs if you want to filter for a common relationship among those CAs. To remove one or more tags, use the UntagCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_UntagCertificateAuthority.html) action. Call the ListTags (https://docs.aws.amazon.com/privateca/latest/APIReference/API_ListTags.html) action to see what tags are associated with your CA. To attach tags to a private CA during the creation procedure, a CA administrator must first associate an inline IAM policy with the CreateCertificateAuthority action and explicitly allow tagging. For more information, see Attaching tags to a CA at the time of creation (https://docs.aws.amazon.com/privateca/latest/userguide/auth-InlinePolicies.html#policy-tag-ca).
#
# POST /
# operationId: TagCertificateAuthority
export def "tag-certificate-authority" [
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
  --x-amz-target: string@x-amz-target-completer-20 # required
  certificate_authority_arn: string # The Amazon Resource Name (ARN) that was returned when you called CreateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthority.html). This must be of the form: arn:aws:acm-pca:region:account:certificate-authority/12345678-1234-1234-1234-123456789012
  tags: list # List of tags to be associated with the CA. — item shape: {Key: string, Value?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.TagCertificateAuthority")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "Tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Remove one or more tags from your private CA. A tag consists of a key-value pair. If you do not specify the value portion of the tag when calling this action, the tag will be removed regardless of value. If you specify a value, the tag is removed only if it is associated with the specified value. To add tags to a private CA, use the TagCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_TagCertificateAuthority.html). Call the ListTags (https://docs.aws.amazon.com/privateca/latest/APIReference/API_ListTags.html) action to see what tags are associated with your CA.
#
# POST /
# operationId: UntagCertificateAuthority
export def "untag-certificate-authority" [
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
  --x-amz-target: string@x-amz-target-completer-21 # required
  certificate_authority_arn: string # The Amazon Resource Name (ARN) that was returned when you called CreateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthority.html). This must be of the form: arn:aws:acm-pca:region:account:certificate-authority/12345678-1234-1234-1234-123456789012
  tags: list # List of tags to be removed from the CA. — item shape: {Key: string, Value?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.UntagCertificateAuthority")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "Tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Updates the status or configuration of a private certificate authority (CA). Your private CA must be in the ACTIVE or DISABLED state before you can update it. You can disable a private CA that is in the ACTIVE state or make a CA that is in the DISABLED state active again. Both Amazon Web Services Private CA and the IAM principal must have permission to write to the S3 bucket that you specify. If the IAM principal making the call does not have permission to write to the bucket, then an exception is thrown. For more information, see Access policies for CRLs in Amazon S3 (https://docs.aws.amazon.com/privateca/latest/userguide/crl-planning.html#s3-policies).
#
# POST /
# operationId: UpdateCertificateAuthority
export def "update-certificate-authority" [
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
  --x-amz-target: string@x-amz-target-completer-22 # required
  certificate_authority_arn: string # Amazon Resource Name (ARN) of the private CA that issued the certificate to be revoked. This must be of the form: arn:aws:acm-pca:region:account:certificate-authority/12345678-1234-1234-1234-123456789012
  --revocation-configuration: record # Certificate revocation information used by the CreateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_CreateCertificateAuthority.html) and UpdateCertificateAuthority (https://docs.aws.amazon.com/privateca/latest/APIReference/API_UpdateCertificateAuthority.html) actions. Your private certificate authority (CA) can configure Online Certificate Status Protocol (OCSP) support and/or maintain a certificate revocation list (CRL). OCSP returns validation information about certificates as requested by clients, and a CRL contains an updated list of certificates revoked by your CA. For more information, see RevokeCertificate (https://docs.aws.amazon.com/privateca/latest/APIReference/API_RevokeCertificate.html) and Setting up a certificate revocation method (https://docs.aws.amazon.com/privateca/latest/userguide/revocation-setup.html) in the Amazon Web Services Private Certificate Authority User Guide. — shape: {CrlConfiguration?: record, OcspConfiguration?: record}
  --status: string@status-completer # Status of your private CA.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ACMPrivateCA.UpdateCertificateAuthority")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CertificateAuthorityArn": $certificate_authority_arn, "RevocationConfiguration": $revocation_configuration, "Status": $status} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
