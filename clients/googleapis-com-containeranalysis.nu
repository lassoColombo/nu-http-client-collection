# Auto-generated client for Container Analysis API vv1beta1
# Source: https://api.apis.guru/v2/specs/googleapis.com/containeranalysis/v1beta1/openapi.json
# Auth: --token flag or $env.CONTAINER_ANALYSIS_API_TOKEN

const BASE_URL = "https://containeranalysis.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CONTAINER_ANALYSIS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://containeranalysis.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def kind-completer [] { ["ATTESTATION" "BUILD" "DEPLOYMENT" "DISCOVERY" "IMAGE" "INTOTO" "NOTE_KIND_UNSPECIFIED" "PACKAGE" "SBOM" "SBOM_REFERENCE" "SPDX_FILE" "SPDX_PACKAGE" "SPDX_RELATIONSHIP" "VULNERABILITY" "VULNERABILITY_ASSESSMENT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v1beta1 containeranalysisprojectsoccurrencesdelete" } } | get name | first)
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

# Deletes the specified occurrence. For example, use this method to delete an occurrence when the occurrence is no longer applicable for the given resource.
#
# DELETE /v1beta1/{name}
# operationId: containeranalysis.projects.occurrences.delete
export def "v1beta1 containeranalysisprojectsoccurrencesdelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified occurrence.
#
# GET /v1beta1/{name}
# operationId: containeranalysis.projects.occurrences.get
export def "v1beta1 containeranalysisprojectsoccurrencesget" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<attestation: record<attestation: record<genericSignedAttestation: record, pgpSignedAttestation: record>>, build: record<provenance: record<buildOptions: record, builderVersion: string, builtArtifacts: list, commands: list, createTime: string, creator: string, endTime: string, id: string, logsUri: string, projectId: string, sourceProvenance: record, startTime: string, triggerId: string>, provenanceBytes: string>, createTime: string, deployment: record<deployment: record<address: string, config: string, deployTime: string, platform: string, resourceUri: list, undeployTime: string, userEmail: string>>, derivedImage: record<derivedImage: record<baseResourceUrl: string, distance: int, fingerprint: record, layerInfo: list>>, discovered: record<discovered: record<analysisCompleted: record, analysisError: list, analysisStatus: string, analysisStatusError: record, continuousAnalysis: string, lastAnalysisTime: string>>, envelope: record<payload: string, payloadType: string, signatures: list<record>>, installation: record<installation: record<architecture: string, cpeUri: string, license: record, location: list, name: string, packageType: string, version: record>>, intoto: record<signatures: list<record>, signed: record<byproducts: record, command: list, environment: record, materials: list, products: list>>, kind: string, name: string, noteName: string, remediation: string, resource: record<contentHash: record<type: string, value: string>, name: string, uri: string>, sbom: record<createTime: string, creatorComment: string, creators: list<string>, documentComment: string, externalDocumentRefs: list<string>, id: string, licenseListVersion: string, namespace: string, title: string>, sbomReference: record<payload: record<_type: string, predicate: record, predicateType: string, subject: list>, payloadType: string, signatures: list<record>>, spdxFile: record<attributions: list<string>, comment: string, contributors: list<string>, copyright: string, filesLicenseInfo: list<string>, id: string, licenseConcluded: record<comments: string, expression: string>, notice: string>, spdxPackage: record<comment: string, filename: string, homePage: string, id: string, licenseConcluded: record<comments: string, expression: string>, packageType: string, sourceInfo: string, summaryDescription: string, title: string, version: string>, spdxRelationship: record<comment: string, source: string, target: string, type: string>, updateTime: string, vulnerability: record<cvssScore: float, cvssV2: record<attackComplexity: string, attackVector: string, authentication: string, availabilityImpact: string, baseScore: float, confidentialityImpact: string, exploitabilityScore: float, impactScore: float, integrityImpact: string, privilegesRequired: string, scope: string, userInteraction: string>, cvssV3: record<attackComplexity: string, attackVector: string, authentication: string, availabilityImpact: string, baseScore: float, confidentialityImpact: string, exploitabilityScore: float, impactScore: float, integrityImpact: string, privilegesRequired: string, scope: string, userInteraction: string>, cvssVersion: string, effectiveSeverity: string, longDescription: string, packageIssue: list<record>, relatedUrls: list<record>, severity: string, shortDescription: string, type: string, vexAssessment: record<cve: string, impacts: list, justification: record, noteName: string, relatedUris: list, remediations: list, state: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the specified occurrence.
#
# PATCH /v1beta1/{name}
# operationId: containeranalysis.projects.occurrences.patch
# --attestation shape: {attestation?: record}
# --build shape: {provenance?: record, provenanceBytes?: string}
# --deployment shape: {deployment?: record}
# --derivedImage shape: {derivedImage?: record}
# --discovered shape: {discovered?: record}
# --envelope shape: {payload?: string, payloadType?: string, signatures?: list}
# --installation shape: {installation?: record}
# --intoto shape: {signatures?: list, signed?: record}
# --resource shape: {contentHash?: record, name?: string, uri?: string}
# --sbom shape: {createTime?: string, creatorComment?: string, creators?: list, documentComment?: string, externalDocumentRefs?: list, id?: string, licenseListVersion?: string, namespace?: string, title?: string}
# --sbomReference shape: {payload?: record, payloadType?: string, signatures?: list}
# --spdxFile shape: {attributions?: list, comment?: string, contributors?: list, copyright?: string, filesLicenseInfo?: list, id?: string, licenseConcluded?: record, notice?: string}
# --spdxPackage shape: {comment?: string, filename?: string, id?: string, licenseConcluded?: record, sourceInfo?: string}
# --spdxRelationship shape: {comment?: string, source?: string, target?: string}
# --vulnerability shape: {cvssScore?: float, cvssV2?: record, cvssV3?: record, cvssVersion?: "CVSS_VERSION_UNSPECIFIED"|"CVSS_VERSION_2"|"CVSS_VERSION_3", effectiveSeverity?: "SEVERITY_UNSPECIFIED"|"MINIMAL"|"LOW"|"MEDIUM"|"HIGH"|"CRITICAL", longDescription?: string, packageIssue?: list, relatedUrls?: list, severity?: "SEVERITY_UNSPECIFIED"|"MINIMAL"|"LOW"|"MEDIUM"|"HIGH"|"CRITICAL", shortDescription?: string, type?: string, vexAssessment?: record}
export def "v1beta1 containeranalysisprojectsoccurrencespatch" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --updateMask: string # The fields to update.
  --attestation: record # Details of an attestation occurrence. — shape: {attestation?: record}
  --build: record # Details of a build occurrence. — shape: {provenance?: record, provenanceBytes?: string}
  --createTime: string # Output only. The time this occurrence was created. (format: google-datetime)
  --deployment: record # Details of a deployment occurrence. — shape: {deployment?: record}
  --derivedImage: record # Details of an image occurrence. — shape: {derivedImage?: record}
  --discovered: record # Details of a discovery occurrence. — shape: {discovered?: record}
  --envelope: record # MUST match https://github.com/secure-systems-lab/dsse/blob/master/envelope.proto. An authenticated message of arbitrary type. — shape: {payload?: string, payloadType?: string, signatures?: list}
  --installation: record # Details of a package occurrence. — shape: {installation?: record}
  --intoto: record # This corresponds to a signed in-toto link - it is made up of one or more signatures and the in-toto link itself. This is used for occurrences of a Grafeas in-toto note. — shape: {signatures?: list, signed?: record}
  --kind: string@kind-completer # Output only. This explicitly denotes which of the occurrence details are specified. This field can be used as a filter in list requests.
  --body-name: string # Output only. The name of the occurrence in the form of `projects/[PROJECT_ID]/occurrences/[OCCURRENCE_ID]`.
  --noteName: string # Required. Immutable. The analysis note associated with this occurrence, in the form of `projects/[PROVIDER_ID]/notes/[NOTE_ID]`. This field can be used as a filter in list requests.
  --remediation: string # A description of actions that can be taken to remedy the note.
  --resource: record # An entity that can have metadata. For example, a Docker image. — shape: {contentHash?: record, name?: string, uri?: string}
  --sbom: record # DocumentOccurrence represents an SPDX Document Creation Information section: https://spdx.github.io/spdx-spec/v2.3/document-creation-information/ — shape: {createTime?: string, creatorComment?: string, creators?: list, documentComment?: string, externalDocumentRefs?: list, id?: string, licenseListVersion?: string, namespace?: string, title?: string}
  --sbomReference: record # The occurrence representing an SBOM reference as applied to a specific resource. The occurrence follows the DSSE specification. See https://github.com/secure-systems-lab/dsse/blob/master/envelope.md for more details. — shape: {payload?: record, payloadType?: string, signatures?: list}
  --spdxFile: record # FileOccurrence represents an SPDX File Information section: https://spdx.github.io/spdx-spec/4-file-information/ — shape: {attributions?: list, comment?: string, contributors?: list, copyright?: string, filesLicenseInfo?: list, id?: string, licenseConcluded?: record, notice?: string}
  --spdxPackage: record # PackageInfoOccurrence represents an SPDX Package Information section: https://spdx.github.io/spdx-spec/3-package-information/ — shape: {comment?: string, filename?: string, id?: string, licenseConcluded?: record, sourceInfo?: string}
  --spdxRelationship: record # RelationshipOccurrence represents an SPDX Relationship section: https://spdx.github.io/spdx-spec/7-relationships-between-SPDX-elements/ — shape: {comment?: string, source?: string, target?: string}
  --updateTime: string # Output only. The time this occurrence was last updated. (format: google-datetime)
  --vulnerability: record # Details of a vulnerability Occurrence. — shape: {cvssScore?: float, cvssV2?: record, cvssV3?: record, cvssVersion?: "CVSS_VERSION_UNSPECIFIED"|"CVSS_VERSION_2"|"CVSS_VERSION_3", effectiveSeverity?: "SEVERITY_UNSPECIFIED"|"MINIMAL"|"LOW"|"MEDIUM"|"HIGH"|"CRITICAL", longDescription?: string, packageIssue?: list, relatedUrls?: list, severity?: "SEVERITY_UNSPECIFIED"|"MINIMAL"|"LOW"|"MEDIUM"|"HIGH"|"CRITICAL", shortDescription?: string, type?: string, vexAssessment?: record}
]: any -> record<attestation: record<attestation: record<genericSignedAttestation: record, pgpSignedAttestation: record>>, build: record<provenance: record<buildOptions: record, builderVersion: string, builtArtifacts: list, commands: list, createTime: string, creator: string, endTime: string, id: string, logsUri: string, projectId: string, sourceProvenance: record, startTime: string, triggerId: string>, provenanceBytes: string>, createTime: string, deployment: record<deployment: record<address: string, config: string, deployTime: string, platform: string, resourceUri: list, undeployTime: string, userEmail: string>>, derivedImage: record<derivedImage: record<baseResourceUrl: string, distance: int, fingerprint: record, layerInfo: list>>, discovered: record<discovered: record<analysisCompleted: record, analysisError: list, analysisStatus: string, analysisStatusError: record, continuousAnalysis: string, lastAnalysisTime: string>>, envelope: record<payload: string, payloadType: string, signatures: list<record>>, installation: record<installation: record<architecture: string, cpeUri: string, license: record, location: list, name: string, packageType: string, version: record>>, intoto: record<signatures: list<record>, signed: record<byproducts: record, command: list, environment: record, materials: list, products: list>>, kind: string, name: string, noteName: string, remediation: string, resource: record<contentHash: record<type: string, value: string>, name: string, uri: string>, sbom: record<createTime: string, creatorComment: string, creators: list<string>, documentComment: string, externalDocumentRefs: list<string>, id: string, licenseListVersion: string, namespace: string, title: string>, sbomReference: record<payload: record<_type: string, predicate: record, predicateType: string, subject: list>, payloadType: string, signatures: list<record>>, spdxFile: record<attributions: list<string>, comment: string, contributors: list<string>, copyright: string, filesLicenseInfo: list<string>, id: string, licenseConcluded: record<comments: string, expression: string>, notice: string>, spdxPackage: record<comment: string, filename: string, homePage: string, id: string, licenseConcluded: record<comments: string, expression: string>, packageType: string, sourceInfo: string, summaryDescription: string, title: string, version: string>, spdxRelationship: record<comment: string, source: string, target: string, type: string>, updateTime: string, vulnerability: record<cvssScore: float, cvssV2: record<attackComplexity: string, attackVector: string, authentication: string, availabilityImpact: string, baseScore: float, confidentialityImpact: string, exploitabilityScore: float, impactScore: float, integrityImpact: string, privilegesRequired: string, scope: string, userInteraction: string>, cvssV3: record<attackComplexity: string, attackVector: string, authentication: string, availabilityImpact: string, baseScore: float, confidentialityImpact: string, exploitabilityScore: float, impactScore: float, integrityImpact: string, privilegesRequired: string, scope: string, userInteraction: string>, cvssVersion: string, effectiveSeverity: string, longDescription: string, packageIssue: list<record>, relatedUrls: list<record>, severity: string, shortDescription: string, type: string, vexAssessment: record<cve: string, impacts: list, justification: record, noteName: string, relatedUris: list, remediations: list, state: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "updateMask" $updateMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($name)" $qp)
  let body = {attestation: $attestation, build: $build, createTime: $createTime, deployment: $deployment, derivedImage: $derivedImage, discovered: $discovered, envelope: $envelope, installation: $installation, intoto: $intoto, kind: $kind, name: $body_name, noteName: $noteName, remediation: $remediation, resource: $resource, sbom: $sbom, sbomReference: $sbomReference, spdxFile: $spdxFile, spdxPackage: $spdxPackage, spdxRelationship: $spdxRelationship, updateTime: $updateTime, vulnerability: $vulnerability} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the note attached to the specified occurrence. Consumer projects can use this method to get a note that belongs to a provider project.
#
# GET /v1beta1/{name}/notes
# operationId: containeranalysis.projects.occurrences.getNotes
export def "v1beta1-notes containeranalysisprojectsoccurrencesgetNotes" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<attestationAuthority: record<hint: record<humanReadableName: string>>, baseImage: record<fingerprint: record<v1Name: string, v2Blob: list, v2Name: string>, resourceUrl: string>, build: record<builderVersion: string, signature: record<keyId: string, keyType: string, publicKey: string, signature: string>>, createTime: string, deployable: record<resourceUri: list<string>>, discovery: record<analysisKind: string>, expirationTime: string, intoto: record<expectedCommand: list<string>, expectedMaterials: list<record>, expectedProducts: list<record>, signingKeys: list<record>, stepName: string, threshold: string>, kind: string, longDescription: string, name: string, package: record<architecture: string, cpeUri: string, description: string, digest: list<record>, distribution: list<record>, license: record<comments: string, expression: string>, maintainer: string, name: string, packageType: string, url: string, version: record<epoch: int, inclusive: bool, kind: string, name: string, revision: string>>, relatedNoteNames: list<string>, relatedUrl: table<label: string, url: string>, sbom: record<dataLicence: string, spdxVersion: string>, sbomReference: record<format: string, version: string>, shortDescription: string, spdxFile: record<checksum: list<string>, fileType: string, title: string>, spdxPackage: record<analyzed: bool, attribution: string, checksum: string, copyright: string, detailedDescription: string, downloadLocation: string, externalRefs: list<record>, filesLicenseInfo: list<string>, homePage: string, licenseDeclared: record<comments: string, expression: string>, originator: string, packageType: string, summaryDescription: string, supplier: string, title: string, verificationCode: string, version: string>, spdxRelationship: record<type: string>, updateTime: string, vulnerability: record<cvssScore: float, cvssV2: record<attackComplexity: string, attackVector: string, authentication: string, availabilityImpact: string, baseScore: float, confidentialityImpact: string, exploitabilityScore: float, impactScore: float, integrityImpact: string, privilegesRequired: string, scope: string, userInteraction: string>, cvssV3: record<attackComplexity: string, attackVector: string, availabilityImpact: string, baseScore: float, confidentialityImpact: string, exploitabilityScore: float, impactScore: float, integrityImpact: string, privilegesRequired: string, scope: string, userInteraction: string>, cvssVersion: string, cwe: list<string>, details: list<record>, severity: string, sourceUpdateTime: string, windowsDetails: list<record>>, vulnerabilityAssessment: record<assessment: record<cve: string, impacts: list, justification: record, longDescription: string, relatedUris: list, remediations: list, shortDescription: string, state: string>, languageCode: string, longDescription: string, product: record<genericUri: string, id: string, name: string>, publisher: record<issuingAuthority: string, name: string, publisherNamespace: string>, shortDescription: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($name)/notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists occurrences referencing the specified note. Provider projects can use this method to get all occurrences across consumer projects referencing the specified note.
#
# GET /v1beta1/{name}/occurrences
# operationId: containeranalysis.projects.notes.occurrences.list
export def "v1beta1-occurrences containeranalysisprojectsnotesoccurrenceslist" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # The filter expression.
  --pageSize: int # Number of occurrences to return in the list.
  --pageToken: string # Token to provide to skip to a particular spot in the list.
]: nothing -> record<nextPageToken: string, occurrences: table<attestation: record, build: record, createTime: string, deployment: record, derivedImage: record, discovered: record, envelope: record, installation: record, intoto: record, kind: string, name: string, noteName: string, remediation: string, resource: record, sbom: record, sbomReference: record, spdxFile: record, spdxPackage: record, spdxRelationship: record, updateTime: string, vulnerability: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($name)/occurrences" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists notes for the specified project.
#
# GET /v1beta1/{parent}/notes
# operationId: containeranalysis.projects.notes.list
export def "v1beta1-notes containeranalysisprojectsnoteslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # The filter expression.
  --pageSize: int # Number of notes to return in the list. Must be positive. Max allowed page size is 1000. If not specified, page size defaults to 20.
  --pageToken: string # Token to provide to skip to a particular spot in the list.
]: nothing -> record<nextPageToken: string, notes: table<attestationAuthority: record, baseImage: record, build: record, createTime: string, deployable: record, discovery: record, expirationTime: string, intoto: record, kind: string, longDescription: string, name: string, package: record, relatedNoteNames: list, relatedUrl: list, sbom: record, sbomReference: record, shortDescription: string, spdxFile: record, spdxPackage: record, spdxRelationship: record, updateTime: string, vulnerability: record, vulnerabilityAssessment: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new note.
#
# POST /v1beta1/{parent}/notes
# operationId: containeranalysis.projects.notes.create
# --attestationAuthority shape: {hint?: record}
# --baseImage shape: {fingerprint?: record, resourceUrl?: string}
# --build shape: {builderVersion?: string, signature?: record}
# --deployable shape: {resourceUri?: list}
# --discovery shape: {analysisKind?: "NOTE_KIND_UNSPECIFIED"|"VULNERABILITY"|"BUILD"|"IMAGE"|"PACKAGE"|"DEPLOYMENT"|"DISCOVERY"|"ATTESTATION"|"INTOTO"|"SBOM"|"SPDX_PACKAGE"|"SPDX_FILE"|"SPDX_RELATIONSHIP"|"VULNERABILITY_ASSESSMENT"|"SBOM_REFERENCE"}
# --intoto shape: {expectedCommand?: list, expectedMaterials?: list, expectedProducts?: list, signingKeys?: list, stepName?: string, threshold?: string}
# --package shape: {architecture?: "ARCHITECTURE_UNSPECIFIED"|"X86"|"X64", cpeUri?: string, description?: string, digest?: list, distribution?: list, license?: record, maintainer?: string, name?: string, packageType?: string, url?: string, version?: record}
# --relatedUrl item shape: {label?: string, url?: string}
# --sbom shape: {dataLicence?: string, spdxVersion?: string}
# --sbomReference shape: {format?: string, version?: string}
# --spdxFile shape: {checksum?: list, fileType?: "FILE_TYPE_UNSPECIFIED"|"SOURCE"|"BINARY"|"ARCHIVE"|"APPLICATION"|"AUDIO"|"IMAGE"|"TEXT"|"VIDEO"|"DOCUMENTATION"|"SPDX"|"OTHER", title?: string}
# --spdxPackage shape: {analyzed?: bool, attribution?: string, checksum?: string, copyright?: string, detailedDescription?: string, downloadLocation?: string, externalRefs?: list, filesLicenseInfo?: list, homePage?: string, licenseDeclared?: record, originator?: string, packageType?: string, summaryDescription?: string, supplier?: string, title?: string, verificationCode?: string, version?: string}
# --spdxRelationship shape: {type?: "RELATIONSHIP_TYPE_UNSPECIFIED"|"DESCRIBES"|"DESCRIBED_BY"|"CONTAINS"|"CONTAINED_BY"|"DEPENDS_ON"|"DEPENDENCY_OF"|"DEPENDENCY_MANIFEST_OF"|"BUILD_DEPENDENCY_OF"|"DEV_DEPENDENCY_OF"|"OPTIONAL_DEPENDENCY_OF"|"PROVIDED_DEPENDENCY_OF"|"TEST_DEPENDENCY_OF"|"RUNTIME_DEPENDENCY_OF"|"EXAMPLE_OF"|"GENERATES"|"GENERATED_FROM"|"ANCESTOR_OF"|"DESCENDANT_OF"|"VARIANT_OF"|"DISTRIBUTION_ARTIFACT"|"PATCH_FOR"|"PATCH_APPLIED"|"COPY_OF"|"FILE_ADDED"|"FILE_DELETED"|"FILE_MODIFIED"|"EXPANDED_FROM_ARCHIVE"|"DYNAMIC_LINK"|"STATIC_LINK"|"DATA_FILE_OF"|"TEST_CASE_OF"|"BUILD_TOOL_OF"|"DEV_TOOL_OF"|"TEST_OF"|"TEST_TOOL_OF"|"DOCUMENTATION_OF"|"OPTIONAL_COMPONENT_OF"|"METAFILE_OF"|"PACKAGE_OF"|"AMENDS"|"PREREQUISITE_FOR"|"HAS_PREREQUISITE"|"OTHER"}
# --vulnerability shape: {cvssScore?: float, cvssV2?: record, cvssV3?: record, cvssVersion?: "CVSS_VERSION_UNSPECIFIED"|"CVSS_VERSION_2"|"CVSS_VERSION_3", cwe?: list, details?: list, severity?: "SEVERITY_UNSPECIFIED"|"MINIMAL"|"LOW"|"MEDIUM"|"HIGH"|"CRITICAL", sourceUpdateTime?: string, windowsDetails?: list}
# --vulnerabilityAssessment shape: {assessment?: record, languageCode?: string, longDescription?: string, product?: record, publisher?: record, shortDescription?: string, title?: string}
export def "v1beta1-notes containeranalysisprojectsnotescreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --noteId: string # Required. The ID to use for this note.
  --attestationAuthority: record # Note kind that represents a logical attestation "role" or "authority". For example, an organization might have one `Authority` for "QA" and one for "build". This note is intended to act strictly as a grouping mechanism for the attached occurrences (Attestations). This grouping mechanism also provides a security boundary, since IAM ACLs gate the ability for a principle to attach an occurrence to a given note. It also provides a single point of lookup to find all attached attestation occurrences, even if they don't all live in the same project. — shape: {hint?: record}
  --baseImage: record # Basis describes the base image portion (Note) of the DockerImage relationship. Linked occurrences are derived from this or an equivalent image via: FROM Or an equivalent reference, e.g. a tag of the resource_url. — shape: {fingerprint?: record, resourceUrl?: string}
  --build: record # Note holding the version of the provider's builder and the signature of the provenance message in the build details occurrence. — shape: {builderVersion?: string, signature?: record}
  --createTime: string # Output only. The time this note was created. This field can be used as a filter in list requests. (format: google-datetime)
  --deployable: record # An artifact that can be deployed in some runtime. — shape: {resourceUri?: list}
  --discovery: record # A note that indicates a type of analysis a provider would perform. This note exists in a provider's project. A `Discovery` occurrence is created in a consumer's project at the start of analysis. — shape: {analysisKind?: "NOTE_KIND_UNSPECIFIED"|"VULNERABILITY"|"BUILD"|"IMAGE"|"PACKAGE"|"DEPLOYMENT"|"DISCOVERY"|"ATTESTATION"|"INTOTO"|"SBOM"|"SPDX_PACKAGE"|"SPDX_FILE"|"SPDX_RELATIONSHIP"|"VULNERABILITY_ASSESSMENT"|"SBOM_REFERENCE"}
  --expirationTime: string # Time of expiration for this note. Empty if note does not expire. (format: google-datetime)
  --intoto: record # This contains the fields corresponding to the definition of a software supply chain step in an in-toto layout. This information goes into a Grafeas note. — shape: {expectedCommand?: list, expectedMaterials?: list, expectedProducts?: list, signingKeys?: list, stepName?: string, threshold?: string}
  --kind: string@kind-completer # Output only. The type of analysis. This field can be used as a filter in list requests.
  --longDescription: string # A detailed description of this note.
  --name: string # Output only. The name of the note in the form of `projects/[PROVIDER_ID]/notes/[NOTE_ID]`.
  --package: record # Package represents a particular package version. — shape: {architecture?: "ARCHITECTURE_UNSPECIFIED"|"X86"|"X64", cpeUri?: string, description?: string, digest?: list, distribution?: list, license?: record, maintainer?: string, name?: string, packageType?: string, url?: string, version?: record}
  --relatedNoteNames: list # Other notes related to this note.
  --relatedUrl: list # URLs associated with this note. — item shape: {label?: string, url?: string}
  --sbom: record # DocumentNote represents an SPDX Document Creation Information section: https://spdx.github.io/spdx-spec/v2.3/document-creation-information/ — shape: {dataLicence?: string, spdxVersion?: string}
  --sbomReference: record # The note representing an SBOM reference. — shape: {format?: string, version?: string}
  --shortDescription: string # A one sentence description of this note.
  --spdxFile: record # FileNote represents an SPDX File Information section: https://spdx.github.io/spdx-spec/4-file-information/ — shape: {checksum?: list, fileType?: "FILE_TYPE_UNSPECIFIED"|"SOURCE"|"BINARY"|"ARCHIVE"|"APPLICATION"|"AUDIO"|"IMAGE"|"TEXT"|"VIDEO"|"DOCUMENTATION"|"SPDX"|"OTHER", title?: string}
  --spdxPackage: record # PackageInfoNote represents an SPDX Package Information section: https://spdx.github.io/spdx-spec/3-package-information/ — shape: {analyzed?: bool, attribution?: string, checksum?: string, copyright?: string, detailedDescription?: string, downloadLocation?: string, externalRefs?: list, filesLicenseInfo?: list, homePage?: string, licenseDeclared?: record, originator?: string, packageType?: string, summaryDescription?: string, supplier?: string, title?: string, verificationCode?: string, version?: string}
  --spdxRelationship: record # RelationshipNote represents an SPDX Relationship section: https://spdx.github.io/spdx-spec/7-relationships-between-SPDX-elements/ — shape: {type?: "RELATIONSHIP_TYPE_UNSPECIFIED"|"DESCRIBES"|"DESCRIBED_BY"|"CONTAINS"|"CONTAINED_BY"|"DEPENDS_ON"|"DEPENDENCY_OF"|"DEPENDENCY_MANIFEST_OF"|"BUILD_DEPENDENCY_OF"|"DEV_DEPENDENCY_OF"|"OPTIONAL_DEPENDENCY_OF"|"PROVIDED_DEPENDENCY_OF"|"TEST_DEPENDENCY_OF"|"RUNTIME_DEPENDENCY_OF"|"EXAMPLE_OF"|"GENERATES"|"GENERATED_FROM"|"ANCESTOR_OF"|"DESCENDANT_OF"|"VARIANT_OF"|"DISTRIBUTION_ARTIFACT"|"PATCH_FOR"|"PATCH_APPLIED"|"COPY_OF"|"FILE_ADDED"|"FILE_DELETED"|"FILE_MODIFIED"|"EXPANDED_FROM_ARCHIVE"|"DYNAMIC_LINK"|"STATIC_LINK"|"DATA_FILE_OF"|"TEST_CASE_OF"|"BUILD_TOOL_OF"|"DEV_TOOL_OF"|"TEST_OF"|"TEST_TOOL_OF"|"DOCUMENTATION_OF"|"OPTIONAL_COMPONENT_OF"|"METAFILE_OF"|"PACKAGE_OF"|"AMENDS"|"PREREQUISITE_FOR"|"HAS_PREREQUISITE"|"OTHER"}
  --updateTime: string # Output only. The time this note was last updated. This field can be used as a filter in list requests. (format: google-datetime)
  --vulnerability: record # Vulnerability provides metadata about a security vulnerability in a Note. — shape: {cvssScore?: float, cvssV2?: record, cvssV3?: record, cvssVersion?: "CVSS_VERSION_UNSPECIFIED"|"CVSS_VERSION_2"|"CVSS_VERSION_3", cwe?: list, details?: list, severity?: "SEVERITY_UNSPECIFIED"|"MINIMAL"|"LOW"|"MEDIUM"|"HIGH"|"CRITICAL", sourceUpdateTime?: string, windowsDetails?: list}
  --vulnerabilityAssessment: record # A single VulnerabilityAssessmentNote represents one particular product's vulnerability assessment for one CVE. — shape: {assessment?: record, languageCode?: string, longDescription?: string, product?: record, publisher?: record, shortDescription?: string, title?: string}
]: any -> record<attestationAuthority: record<hint: record<humanReadableName: string>>, baseImage: record<fingerprint: record<v1Name: string, v2Blob: list, v2Name: string>, resourceUrl: string>, build: record<builderVersion: string, signature: record<keyId: string, keyType: string, publicKey: string, signature: string>>, createTime: string, deployable: record<resourceUri: list<string>>, discovery: record<analysisKind: string>, expirationTime: string, intoto: record<expectedCommand: list<string>, expectedMaterials: list<record>, expectedProducts: list<record>, signingKeys: list<record>, stepName: string, threshold: string>, kind: string, longDescription: string, name: string, package: record<architecture: string, cpeUri: string, description: string, digest: list<record>, distribution: list<record>, license: record<comments: string, expression: string>, maintainer: string, name: string, packageType: string, url: string, version: record<epoch: int, inclusive: bool, kind: string, name: string, revision: string>>, relatedNoteNames: list<string>, relatedUrl: table<label: string, url: string>, sbom: record<dataLicence: string, spdxVersion: string>, sbomReference: record<format: string, version: string>, shortDescription: string, spdxFile: record<checksum: list<string>, fileType: string, title: string>, spdxPackage: record<analyzed: bool, attribution: string, checksum: string, copyright: string, detailedDescription: string, downloadLocation: string, externalRefs: list<record>, filesLicenseInfo: list<string>, homePage: string, licenseDeclared: record<comments: string, expression: string>, originator: string, packageType: string, summaryDescription: string, supplier: string, title: string, verificationCode: string, version: string>, spdxRelationship: record<type: string>, updateTime: string, vulnerability: record<cvssScore: float, cvssV2: record<attackComplexity: string, attackVector: string, authentication: string, availabilityImpact: string, baseScore: float, confidentialityImpact: string, exploitabilityScore: float, impactScore: float, integrityImpact: string, privilegesRequired: string, scope: string, userInteraction: string>, cvssV3: record<attackComplexity: string, attackVector: string, availabilityImpact: string, baseScore: float, confidentialityImpact: string, exploitabilityScore: float, impactScore: float, integrityImpact: string, privilegesRequired: string, scope: string, userInteraction: string>, cvssVersion: string, cwe: list<string>, details: list<record>, severity: string, sourceUpdateTime: string, windowsDetails: list<record>>, vulnerabilityAssessment: record<assessment: record<cve: string, impacts: list, justification: record, longDescription: string, relatedUris: list, remediations: list, shortDescription: string, state: string>, languageCode: string, longDescription: string, product: record<genericUri: string, id: string, name: string>, publisher: record<issuingAuthority: string, name: string, publisherNamespace: string>, shortDescription: string, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "noteId" $noteId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/notes" $qp)
  let body = {attestationAuthority: $attestationAuthority, baseImage: $baseImage, build: $build, createTime: $createTime, deployable: $deployable, discovery: $discovery, expirationTime: $expirationTime, intoto: $intoto, kind: $kind, longDescription: $longDescription, name: $name, package: $package, relatedNoteNames: $relatedNoteNames, relatedUrl: $relatedUrl, sbom: $sbom, sbomReference: $sbomReference, shortDescription: $shortDescription, spdxFile: $spdxFile, spdxPackage: $spdxPackage, spdxRelationship: $spdxRelationship, updateTime: $updateTime, vulnerability: $vulnerability, vulnerabilityAssessment: $vulnerabilityAssessment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates new notes in batch.
#
# POST /v1beta1/{parent}/notes:batchCreate
# operationId: containeranalysis.projects.notes.batchCreate
export def "v1beta1-notes-batch-create containeranalysisprojectsnotesbatchCreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --notes: record # Required. The notes to create, the key is expected to be the note ID. Max allowed length is 1000.
]: any -> record<notes: table<attestationAuthority: record, baseImage: record, build: record, createTime: string, deployable: record, discovery: record, expirationTime: string, intoto: record, kind: string, longDescription: string, name: string, package: record, relatedNoteNames: list, relatedUrl: list, sbom: record, sbomReference: record, shortDescription: string, spdxFile: record, spdxPackage: record, spdxRelationship: record, updateTime: string, vulnerability: record, vulnerabilityAssessment: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/notes:batchCreate" $qp)
  let body = {notes: $notes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists occurrences for the specified project.
#
# GET /v1beta1/{parent}/occurrences
# operationId: containeranalysis.projects.occurrences.list
export def "v1beta1-occurrences containeranalysisprojectsoccurrenceslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # The filter expression.
  --pageSize: int # Number of occurrences to return in the list. Must be positive. Max allowed page size is 1000. If not specified, page size defaults to 20.
  --pageToken: string # Token to provide to skip to a particular spot in the list.
]: nothing -> record<nextPageToken: string, occurrences: table<attestation: record, build: record, createTime: string, deployment: record, derivedImage: record, discovered: record, envelope: record, installation: record, intoto: record, kind: string, name: string, noteName: string, remediation: string, resource: record, sbom: record, sbomReference: record, spdxFile: record, spdxPackage: record, spdxRelationship: record, updateTime: string, vulnerability: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/occurrences" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new occurrence.
#
# POST /v1beta1/{parent}/occurrences
# operationId: containeranalysis.projects.occurrences.create
# --attestation shape: {attestation?: record}
# --build shape: {provenance?: record, provenanceBytes?: string}
# --deployment shape: {deployment?: record}
# --derivedImage shape: {derivedImage?: record}
# --discovered shape: {discovered?: record}
# --envelope shape: {payload?: string, payloadType?: string, signatures?: list}
# --installation shape: {installation?: record}
# --intoto shape: {signatures?: list, signed?: record}
# --resource shape: {contentHash?: record, name?: string, uri?: string}
# --sbom shape: {createTime?: string, creatorComment?: string, creators?: list, documentComment?: string, externalDocumentRefs?: list, id?: string, licenseListVersion?: string, namespace?: string, title?: string}
# --sbomReference shape: {payload?: record, payloadType?: string, signatures?: list}
# --spdxFile shape: {attributions?: list, comment?: string, contributors?: list, copyright?: string, filesLicenseInfo?: list, id?: string, licenseConcluded?: record, notice?: string}
# --spdxPackage shape: {comment?: string, filename?: string, id?: string, licenseConcluded?: record, sourceInfo?: string}
# --spdxRelationship shape: {comment?: string, source?: string, target?: string}
# --vulnerability shape: {cvssScore?: float, cvssV2?: record, cvssV3?: record, cvssVersion?: "CVSS_VERSION_UNSPECIFIED"|"CVSS_VERSION_2"|"CVSS_VERSION_3", effectiveSeverity?: "SEVERITY_UNSPECIFIED"|"MINIMAL"|"LOW"|"MEDIUM"|"HIGH"|"CRITICAL", longDescription?: string, packageIssue?: list, relatedUrls?: list, severity?: "SEVERITY_UNSPECIFIED"|"MINIMAL"|"LOW"|"MEDIUM"|"HIGH"|"CRITICAL", shortDescription?: string, type?: string, vexAssessment?: record}
export def "v1beta1-occurrences containeranalysisprojectsoccurrencescreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --attestation: record # Details of an attestation occurrence. — shape: {attestation?: record}
  --build: record # Details of a build occurrence. — shape: {provenance?: record, provenanceBytes?: string}
  --createTime: string # Output only. The time this occurrence was created. (format: google-datetime)
  --deployment: record # Details of a deployment occurrence. — shape: {deployment?: record}
  --derivedImage: record # Details of an image occurrence. — shape: {derivedImage?: record}
  --discovered: record # Details of a discovery occurrence. — shape: {discovered?: record}
  --envelope: record # MUST match https://github.com/secure-systems-lab/dsse/blob/master/envelope.proto. An authenticated message of arbitrary type. — shape: {payload?: string, payloadType?: string, signatures?: list}
  --installation: record # Details of a package occurrence. — shape: {installation?: record}
  --intoto: record # This corresponds to a signed in-toto link - it is made up of one or more signatures and the in-toto link itself. This is used for occurrences of a Grafeas in-toto note. — shape: {signatures?: list, signed?: record}
  --kind: string@kind-completer # Output only. This explicitly denotes which of the occurrence details are specified. This field can be used as a filter in list requests.
  --name: string # Output only. The name of the occurrence in the form of `projects/[PROJECT_ID]/occurrences/[OCCURRENCE_ID]`.
  --noteName: string # Required. Immutable. The analysis note associated with this occurrence, in the form of `projects/[PROVIDER_ID]/notes/[NOTE_ID]`. This field can be used as a filter in list requests.
  --remediation: string # A description of actions that can be taken to remedy the note.
  --resource: record # An entity that can have metadata. For example, a Docker image. — shape: {contentHash?: record, name?: string, uri?: string}
  --sbom: record # DocumentOccurrence represents an SPDX Document Creation Information section: https://spdx.github.io/spdx-spec/v2.3/document-creation-information/ — shape: {createTime?: string, creatorComment?: string, creators?: list, documentComment?: string, externalDocumentRefs?: list, id?: string, licenseListVersion?: string, namespace?: string, title?: string}
  --sbomReference: record # The occurrence representing an SBOM reference as applied to a specific resource. The occurrence follows the DSSE specification. See https://github.com/secure-systems-lab/dsse/blob/master/envelope.md for more details. — shape: {payload?: record, payloadType?: string, signatures?: list}
  --spdxFile: record # FileOccurrence represents an SPDX File Information section: https://spdx.github.io/spdx-spec/4-file-information/ — shape: {attributions?: list, comment?: string, contributors?: list, copyright?: string, filesLicenseInfo?: list, id?: string, licenseConcluded?: record, notice?: string}
  --spdxPackage: record # PackageInfoOccurrence represents an SPDX Package Information section: https://spdx.github.io/spdx-spec/3-package-information/ — shape: {comment?: string, filename?: string, id?: string, licenseConcluded?: record, sourceInfo?: string}
  --spdxRelationship: record # RelationshipOccurrence represents an SPDX Relationship section: https://spdx.github.io/spdx-spec/7-relationships-between-SPDX-elements/ — shape: {comment?: string, source?: string, target?: string}
  --updateTime: string # Output only. The time this occurrence was last updated. (format: google-datetime)
  --vulnerability: record # Details of a vulnerability Occurrence. — shape: {cvssScore?: float, cvssV2?: record, cvssV3?: record, cvssVersion?: "CVSS_VERSION_UNSPECIFIED"|"CVSS_VERSION_2"|"CVSS_VERSION_3", effectiveSeverity?: "SEVERITY_UNSPECIFIED"|"MINIMAL"|"LOW"|"MEDIUM"|"HIGH"|"CRITICAL", longDescription?: string, packageIssue?: list, relatedUrls?: list, severity?: "SEVERITY_UNSPECIFIED"|"MINIMAL"|"LOW"|"MEDIUM"|"HIGH"|"CRITICAL", shortDescription?: string, type?: string, vexAssessment?: record}
]: any -> record<attestation: record<attestation: record<genericSignedAttestation: record, pgpSignedAttestation: record>>, build: record<provenance: record<buildOptions: record, builderVersion: string, builtArtifacts: list, commands: list, createTime: string, creator: string, endTime: string, id: string, logsUri: string, projectId: string, sourceProvenance: record, startTime: string, triggerId: string>, provenanceBytes: string>, createTime: string, deployment: record<deployment: record<address: string, config: string, deployTime: string, platform: string, resourceUri: list, undeployTime: string, userEmail: string>>, derivedImage: record<derivedImage: record<baseResourceUrl: string, distance: int, fingerprint: record, layerInfo: list>>, discovered: record<discovered: record<analysisCompleted: record, analysisError: list, analysisStatus: string, analysisStatusError: record, continuousAnalysis: string, lastAnalysisTime: string>>, envelope: record<payload: string, payloadType: string, signatures: list<record>>, installation: record<installation: record<architecture: string, cpeUri: string, license: record, location: list, name: string, packageType: string, version: record>>, intoto: record<signatures: list<record>, signed: record<byproducts: record, command: list, environment: record, materials: list, products: list>>, kind: string, name: string, noteName: string, remediation: string, resource: record<contentHash: record<type: string, value: string>, name: string, uri: string>, sbom: record<createTime: string, creatorComment: string, creators: list<string>, documentComment: string, externalDocumentRefs: list<string>, id: string, licenseListVersion: string, namespace: string, title: string>, sbomReference: record<payload: record<_type: string, predicate: record, predicateType: string, subject: list>, payloadType: string, signatures: list<record>>, spdxFile: record<attributions: list<string>, comment: string, contributors: list<string>, copyright: string, filesLicenseInfo: list<string>, id: string, licenseConcluded: record<comments: string, expression: string>, notice: string>, spdxPackage: record<comment: string, filename: string, homePage: string, id: string, licenseConcluded: record<comments: string, expression: string>, packageType: string, sourceInfo: string, summaryDescription: string, title: string, version: string>, spdxRelationship: record<comment: string, source: string, target: string, type: string>, updateTime: string, vulnerability: record<cvssScore: float, cvssV2: record<attackComplexity: string, attackVector: string, authentication: string, availabilityImpact: string, baseScore: float, confidentialityImpact: string, exploitabilityScore: float, impactScore: float, integrityImpact: string, privilegesRequired: string, scope: string, userInteraction: string>, cvssV3: record<attackComplexity: string, attackVector: string, authentication: string, availabilityImpact: string, baseScore: float, confidentialityImpact: string, exploitabilityScore: float, impactScore: float, integrityImpact: string, privilegesRequired: string, scope: string, userInteraction: string>, cvssVersion: string, effectiveSeverity: string, longDescription: string, packageIssue: list<record>, relatedUrls: list<record>, severity: string, shortDescription: string, type: string, vexAssessment: record<cve: string, impacts: list, justification: record, noteName: string, relatedUris: list, remediations: list, state: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/occurrences" $qp)
  let body = {attestation: $attestation, build: $build, createTime: $createTime, deployment: $deployment, derivedImage: $derivedImage, discovered: $discovered, envelope: $envelope, installation: $installation, intoto: $intoto, kind: $kind, name: $name, noteName: $noteName, remediation: $remediation, resource: $resource, sbom: $sbom, sbomReference: $sbomReference, spdxFile: $spdxFile, spdxPackage: $spdxPackage, spdxRelationship: $spdxRelationship, updateTime: $updateTime, vulnerability: $vulnerability} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates new occurrences in batch.
#
# POST /v1beta1/{parent}/occurrences:batchCreate
# operationId: containeranalysis.projects.occurrences.batchCreate
# --occurrences item shape: {attestation?: record, build?: record, createTime?: string, deployment?: record, derivedImage?: record, discovered?: record, envelope?: record, installation?: record, intoto?: record, kind?: "NOTE_KIND_UNSPECIFIED"|"VULNERABILITY"|"BUILD"|"IMAGE"|"PACKAGE"|"DEPLOYMENT"|"DISCOVERY"|"ATTESTATION"|"INTOTO"|"SBOM"|"SPDX_PACKAGE"|"SPDX_FILE"|"SPDX_RELATIONSHIP"|"VULNERABILITY_ASSESSMENT"|"SBOM_REFERENCE", name?: string, noteName?: string, remediation?: string, resource?: record, sbom?: record, sbomReference?: record, spdxFile?: record, spdxPackage?: record, spdxRelationship?: record, updateTime?: string, vulnerability?: record}
export def "v1beta1-occurrences-batch-create containeranalysisprojectsoccurrencesbatchCreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --occurrences: list # Required. The occurrences to create. Max allowed length is 1000. — item shape: {attestation?: record, build?: record, createTime?: string, deployment?: record, derivedImage?: record, discovered?: record, envelope?: record, installation?: record, intoto?: record, kind?: "NOTE_KIND_UNSPECIFIED"|"VULNERABILITY"|"BUILD"|"IMAGE"|"PACKAGE"|"DEPLOYMENT"|"DISCOVERY"|"ATTESTATION"|"INTOTO"|"SBOM"|"SPDX_PACKAGE"|"SPDX_FILE"|"SPDX_RELATIONSHIP"|"VULNERABILITY_ASSESSMENT"|"SBOM_REFERENCE", name?: string, noteName?: string, remediation?: string, resource?: record, sbom?: record, sbomReference?: record, spdxFile?: record, spdxPackage?: record, spdxRelationship?: record, updateTime?: string, vulnerability?: record}
]: any -> record<occurrences: table<attestation: record, build: record, createTime: string, deployment: record, derivedImage: record, discovered: record, envelope: record, installation: record, intoto: record, kind: string, name: string, noteName: string, remediation: string, resource: record, sbom: record, sbomReference: record, spdxFile: record, spdxPackage: record, spdxRelationship: record, updateTime: string, vulnerability: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/occurrences:batchCreate" $qp)
  let body = {occurrences: $occurrences} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a summary of the number and severity of occurrences.
#
# GET /v1beta1/{parent}/occurrences:vulnerabilitySummary
# operationId: containeranalysis.projects.occurrences.getVulnerabilitySummary
export def "v1beta1-occurrences-vulnerability-summary containeranalysisprojectsoccurrencesgetVulnerabilitySummary" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # The filter expression.
]: nothing -> record<counts: table<fixableCount: string, resource: record, severity: string, totalCount: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/occurrences:vulnerabilitySummary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the access control policy for a note or an occurrence resource. Requires `containeranalysis.notes.setIamPolicy` or `containeranalysis.occurrences.setIamPolicy` permission if the resource is a note or occurrence, respectively. The resource takes the format `projects/[PROJECT_ID]/notes/[NOTE_ID]` for notes and `projects/[PROJECT_ID]/occurrences/[OCCURRENCE_ID]` for occurrences.
#
# POST /v1beta1/{resource}:getIamPolicy
# operationId: containeranalysis.projects.occurrences.getIamPolicy
# --options shape: {requestedPolicyVersion?: int}
export def "v1beta1 containeranalysisprojectsoccurrencesgetIamPolicy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --options: record # Encapsulates settings provided to GetIamPolicy. — shape: {requestedPolicyVersion?: int}
]: any -> record<bindings: table<condition: record, members: list, role: string>, etag: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($resource):getIamPolicy" $qp)
  let body = {options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sets the access control policy on the specified note or occurrence. Requires `containeranalysis.notes.setIamPolicy` or `containeranalysis.occurrences.setIamPolicy` permission if the resource is a note or an occurrence, respectively. The resource takes the format `projects/[PROJECT_ID]/notes/[NOTE_ID]` for notes and `projects/[PROJECT_ID]/occurrences/[OCCURRENCE_ID]` for occurrences.
#
# POST /v1beta1/{resource}:setIamPolicy
# operationId: containeranalysis.projects.occurrences.setIamPolicy
# --policy shape: {bindings?: list, etag?: string, version?: int}
export def "v1beta1 containeranalysisprojectsoccurrencessetIamPolicy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --policy: record # An Identity and Access Management (IAM) policy, which specifies access controls for Google Cloud resources. A `Policy` is a collection of `bindings`. A `binding` binds one or more `members`, or principals, to a single `role`. Principals can be user accounts, service accounts, Google groups, and domains (such as G Suite). A `role` is a named list of permissions; each `role` can be an IAM predefined role or a user-created custom role. For some types of Google Cloud resources, a `binding` can also specify a `condition`, which is a logical expression that allows access to a resource only if the expression evaluates to `true`. A condition can add constraints based on attributes of the request, the resource, or both. To learn which resources support conditions in their IAM policies, see the [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies). **JSON example:** { "bindings": [ { "role": "roles/resourcemanager.organizationAdmin", "members": [ "user:mike@example.com", "group:admins@example.com", "domain:google.com", "serviceAccount:my-project-id@appspot.gserviceaccount.com" ] }, { "role": "roles/resourcemanager.organizationViewer", "members": [ "user:eve@example.com" ], "condition": { "title": "expirable access", "description": "Does not grant access after Sep 2020", "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')", } } ], "etag": "BwWWja0YfJA=", "version": 3 } **YAML example:** bindings: - members: - user:mike@example.com - group:admins@example.com - domain:google.com - serviceAccount:my-project-id@appspot.gserviceaccount.com role: roles/resourcemanager.organizationAdmin - members: - user:eve@example.com role: roles/resourcemanager.organizationViewer condition: title: expirable access description: Does not grant access after Sep 2020 expression: request.time < timestamp('2020-10-01T00:00:00.000Z') etag: BwWWja0YfJA= version: 3 For a description of IAM and its features, see the [IAM documentation](https://cloud.google.com/iam/docs/). — shape: {bindings?: list, etag?: string, version?: int}
]: any -> record<bindings: table<condition: record, members: list, role: string>, etag: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($resource):setIamPolicy" $qp)
  let body = {policy: $policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the permissions that a caller has on the specified note or occurrence. Requires list permission on the project (for example, `containeranalysis.notes.list`). The resource takes the format `projects/[PROJECT_ID]/notes/[NOTE_ID]` for notes and `projects/[PROJECT_ID]/occurrences/[OCCURRENCE_ID]` for occurrences.
#
# POST /v1beta1/{resource}:testIamPermissions
# operationId: containeranalysis.projects.occurrences.testIamPermissions
export def "v1beta1 containeranalysisprojectsoccurrencestestIamPermissions" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --permissions: list # The set of permissions to check for the `resource`. Permissions with wildcards (such as `*` or `storage.*`) are not allowed. For more information see [IAM Overview](https://cloud.google.com/iam/docs/overview#permissions).
]: any -> record<permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($resource):testIamPermissions" $qp)
  let body = {permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
