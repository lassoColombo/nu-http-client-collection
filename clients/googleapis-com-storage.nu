# Auto-generated client for Cloud Storage JSON API vv1
# Source: https://api.apis.guru/v2/specs/googleapis.com/storage/v1/openapi.json
# Auth: --token flag or $env.CLOUD_STORAGE_JSON_API_TOKEN

const BASE_URL = "https://storage.googleapis.com/storage/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CLOUD_STORAGE_JSON_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://storage.googleapis.com/storage/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["json"] }
def projection-completer [] { ["full" "noAcl"] }
def predefined-acl-completer [] { ["authenticatedRead" "private" "projectPrivate" "publicRead" "publicReadWrite"] }
def predefined-default-object-acl-completer [] { ["authenticatedRead" "bucketOwnerFullControl" "bucketOwnerRead" "private" "projectPrivate" "publicRead"] }
def predefined-acl-completer-1 [] { ["authenticatedRead" "bucketOwnerFullControl" "bucketOwnerRead" "private" "projectPrivate" "publicRead"] }
def destination-predefined-acl-completer [] { ["authenticatedRead" "bucketOwnerFullControl" "bucketOwnerRead" "private" "projectPrivate" "publicRead"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "b storagebucketslist" } } | get name | first)
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

# Retrieves a list of buckets for a given project.
#
# GET /b
# operationId: storage.buckets.list
export def "b storagebucketslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --project: string # A valid API project identifier.
  --max-results: int # Maximum number of buckets to return in a single response. The service will use this parameter or 1,000 items, whichever is smaller.
  --page-token: string # A previously-returned page token representing part of the larger set of results to view.
  --prefix: string # Filter results to buckets whose names begin with this prefix.
  --projection: string@projection-completer # Set of properties to return. Defaults to noAcl.
  --user-project: string # The project to be billed for this request.
]: nothing -> record<items: table<acl: list, autoclass: record, billing: record, cors: list, customPlacementConfig: record, defaultEventBasedHold: bool, defaultObjectAcl: list, encryption: record, etag: string, iamConfiguration: record, id: string, kind: string, labels: record, lifecycle: record, location: string, locationType: string, logging: record, metageneration: string, name: string, owner: record, projectNumber: string, retentionPolicy: record, rpo: string, satisfiesPZS: bool, selfLink: string, storageClass: string, timeCreated: string, updated: string, versioning: record, website: record>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/b" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new bucket.
#
# POST /b
# operationId: storage.buckets.insert
# --acl item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, id?: string, kind?: string, projectTeam?: record, role?: string, selfLink?: string}
# --autoclass shape: {enabled?: bool, toggleTime?: string}
# --billing shape: {requesterPays?: bool}
# --cors item shape: {maxAgeSeconds?: int, method?: list, origin?: list, responseHeader?: list}
# --customPlacementConfig shape: {dataLocations?: list}
# --defaultObjectAcl item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, generation?: string, id?: string, kind?: string, object?: string, projectTeam?: record, role?: string, selfLink?: string}
# --encryption shape: {defaultKmsKeyName?: string}
# --iamConfiguration shape: {bucketPolicyOnly?: record, publicAccessPrevention?: string, uniformBucketLevelAccess?: record}
# --lifecycle shape: {rule?: list}
# --logging shape: {logBucket?: string, logObjectPrefix?: string}
# --owner shape: {entity?: string, entityId?: string}
# --retentionPolicy shape: {effectiveTime?: string, isLocked?: bool, retentionPeriod?: string}
# --versioning shape: {enabled?: bool}
# --website shape: {mainPageSuffix?: string, notFoundPage?: string}
export def "b storagebucketsinsert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --project: string # A valid API project identifier.
  --predefined-acl: string@predefined-acl-completer # Apply a predefined set of access controls to this bucket.
  --predefined-default-object-acl: string@predefined-default-object-acl-completer # Apply a predefined set of default object access controls to this bucket.
  --projection: string@projection-completer # Set of properties to return. Defaults to noAcl, unless the bucket resource specifies acl or defaultObjectAcl properties, when it defaults to full.
  --user-project: string # The project to be billed for this request.
  --acl: list # Access controls on the bucket. — item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, id?: string, kind?: string, projectTeam?: record, role?: string, selfLink?: string}
  --autoclass: record # The bucket's Autoclass configuration. — shape: {enabled?: bool, toggleTime?: string}
  --billing: record # The bucket's billing configuration. — shape: {requesterPays?: bool}
  --cors: list # The bucket's Cross-Origin Resource Sharing (CORS) configuration. — item shape: {maxAgeSeconds?: int, method?: list, origin?: list, responseHeader?: list}
  --custom-placement-config: record # The bucket's custom placement configuration for Custom Dual Regions. — shape: {dataLocations?: list}
  --default-event-based-hold: oneof<nothing, bool> # The default value for event-based hold on newly created objects in this bucket. Event-based hold is a way to retain objects indefinitely until an event occurs, signified by the hold's release. After being released, such objects will be subject to bucket-level retention (if any). One sample use case of this flag is for banks to hold loan documents for at least 3 years after loan is paid in full. Here, bucket-level retention is 3 years and the event is loan being paid in full. In this example, these objects will be held intact for any number of years until the event has occurred (event-based hold on the object is released) and then 3 more years after that. That means retention duration of the objects begins from the moment event-based hold transitioned from true to false. Objects under event-based hold cannot be deleted, overwritten or archived until the hold is removed.
  --default-object-acl: list # Default access controls to apply to new objects when no ACL is provided. — item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, generation?: string, id?: string, kind?: string, object?: string, projectTeam?: record, role?: string, selfLink?: string}
  --encryption: record # Encryption configuration for a bucket. — shape: {defaultKmsKeyName?: string}
  --etag: string # HTTP 1.1 Entity tag for the bucket.
  --iam-configuration: record # The bucket's IAM configuration. — shape: {bucketPolicyOnly?: record, publicAccessPrevention?: string, uniformBucketLevelAccess?: record}
  --id: string # The ID of the bucket. For buckets, the id and name properties are the same.
  --kind: string # The kind of item this is. For buckets, this is always storage#bucket. (default: storage#bucket)
  --labels: record # User-provided labels, in key/value pairs.
  --lifecycle: record # The bucket's lifecycle configuration. See lifecycle management for more information. — shape: {rule?: list}
  --location: string # The location of the bucket. Object data for objects in the bucket resides in physical storage within this region. Defaults to US. See the developer's guide for the authoritative list.
  --location-type: string # The type of the bucket location.
  --logging: record # The bucket's logging configuration, which defines the destination bucket and optional name prefix for the current bucket's logs. — shape: {logBucket?: string, logObjectPrefix?: string}
  --metageneration: string # The metadata generation of this bucket. (format: int64)
  --name: string # The name of the bucket.
  --owner: record # The owner of the bucket. This is always the project team's owner group. — shape: {entity?: string, entityId?: string}
  --project-number: string # The project number of the project the bucket belongs to. (format: uint64)
  --retention-policy: record # The bucket's retention policy. The retention policy enforces a minimum retention time for all objects contained in the bucket, based on their creation time. Any attempt to overwrite or delete objects younger than the retention period will result in a PERMISSION_DENIED error. An unlocked retention policy can be modified or removed from the bucket via a storage.buckets.update operation. A locked retention policy cannot be removed or shortened in duration for the lifetime of the bucket. Attempting to remove or decrease period of a locked retention policy will result in a PERMISSION_DENIED error. — shape: {effectiveTime?: string, isLocked?: bool, retentionPeriod?: string}
  --rpo: string # The Recovery Point Objective (RPO) of this bucket. Set to ASYNC_TURBO to turn on Turbo Replication on a bucket.
  --satisfies-pzs: oneof<nothing, bool> # Reserved for future use.
  --self-link: string # The URI of this bucket.
  --storage-class: string # The bucket's default storage class, used whenever no storageClass is specified for a newly-created object. This defines how objects in the bucket are stored and determines the SLA and the cost of storage. Values include MULTI_REGIONAL, REGIONAL, STANDARD, NEARLINE, COLDLINE, ARCHIVE, and DURABLE_REDUCED_AVAILABILITY. If this value is not specified when the bucket is created, it will default to STANDARD. For more information, see storage classes.
  --time-created: string # The creation time of the bucket in RFC 3339 format. (format: date-time)
  --updated: string # The modification time of the bucket in RFC 3339 format. (format: date-time)
  --versioning: record # The bucket's versioning configuration. — shape: {enabled?: bool}
  --website: record # The bucket's website configuration, controlling how the service behaves when accessing bucket contents as a web site. See the Static Website Examples for more information. — shape: {mainPageSuffix?: string, notFoundPage?: string}
]: any -> record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record, role: string, selfLink: string>, autoclass: record<enabled: bool, toggleTime: string>, billing: record<requesterPays: bool>, cors: table<maxAgeSeconds: int, method: list, origin: list, responseHeader: list>, customPlacementConfig: record<dataLocations: list<string>>, defaultEventBasedHold: bool, defaultObjectAcl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, encryption: record<defaultKmsKeyName: string>, etag: string, iamConfiguration: record<bucketPolicyOnly: record<enabled: bool, lockedTime: string>, publicAccessPrevention: string, uniformBucketLevelAccess: record<enabled: bool, lockedTime: string>>, id: string, kind: string, labels: record, lifecycle: record<rule: list<record>>, location: string, locationType: string, logging: record<logBucket: string, logObjectPrefix: string>, metageneration: string, name: string, owner: record<entity: string, entityId: string>, projectNumber: string, retentionPolicy: record<effectiveTime: string, isLocked: bool, retentionPeriod: string>, rpo: string, satisfiesPZS: bool, selfLink: string, storageClass: string, timeCreated: string, updated: string, versioning: record<enabled: bool>, website: record<mainPageSuffix: string, notFoundPage: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "predefinedAcl" $predefined_acl "scalar") (serialize-qp "predefinedDefaultObjectAcl" $predefined_default_object_acl "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/b" $qp)
  let body = {"acl": $acl, "autoclass": $autoclass, "billing": $billing, "cors": $cors, "customPlacementConfig": $custom_placement_config, "defaultEventBasedHold": $default_event_based_hold, "defaultObjectAcl": $default_object_acl, "encryption": $encryption, "etag": $etag, "iamConfiguration": $iam_configuration, "id": $id, "kind": $kind, "labels": $labels, "lifecycle": $lifecycle, "location": $location, "locationType": $location_type, "logging": $logging, "metageneration": $metageneration, "name": $name, "owner": $owner, "projectNumber": $project_number, "retentionPolicy": $retention_policy, "rpo": $rpo, "satisfiesPZS": $satisfies_pzs, "selfLink": $self_link, "storageClass": $storage_class, "timeCreated": $time_created, "updated": $updated, "versioning": $versioning, "website": $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Permanently deletes an empty bucket.
#
# DELETE /b/{bucket}
# operationId: storage.buckets.delete
export def "b storagebucketsdelete" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --if-metageneration-match: string # If set, only deletes the bucket if its metageneration matches this value.
  --if-metageneration-not-match: string # If set, only deletes the bucket if its metageneration does not match this value.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "ifMetagenerationMatch" $if_metageneration_match "scalar") (serialize-qp "ifMetagenerationNotMatch" $if_metageneration_not_match "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket} | format pattern "/b/{bucket}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns metadata for the specified bucket.
#
# GET /b/{bucket}
# operationId: storage.buckets.get
export def "b storagebucketsget" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --if-metageneration-match: string # Makes the return of the bucket metadata conditional on whether the bucket's current metageneration matches the given value.
  --if-metageneration-not-match: string # Makes the return of the bucket metadata conditional on whether the bucket's current metageneration does not match the given value.
  --projection: string@projection-completer # Set of properties to return. Defaults to noAcl.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record, role: string, selfLink: string>, autoclass: record<enabled: bool, toggleTime: string>, billing: record<requesterPays: bool>, cors: table<maxAgeSeconds: int, method: list, origin: list, responseHeader: list>, customPlacementConfig: record<dataLocations: list<string>>, defaultEventBasedHold: bool, defaultObjectAcl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, encryption: record<defaultKmsKeyName: string>, etag: string, iamConfiguration: record<bucketPolicyOnly: record<enabled: bool, lockedTime: string>, publicAccessPrevention: string, uniformBucketLevelAccess: record<enabled: bool, lockedTime: string>>, id: string, kind: string, labels: record, lifecycle: record<rule: list<record>>, location: string, locationType: string, logging: record<logBucket: string, logObjectPrefix: string>, metageneration: string, name: string, owner: record<entity: string, entityId: string>, projectNumber: string, retentionPolicy: record<effectiveTime: string, isLocked: bool, retentionPeriod: string>, rpo: string, satisfiesPZS: bool, selfLink: string, storageClass: string, timeCreated: string, updated: string, versioning: record<enabled: bool>, website: record<mainPageSuffix: string, notFoundPage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "ifMetagenerationMatch" $if_metageneration_match "scalar") (serialize-qp "ifMetagenerationNotMatch" $if_metageneration_not_match "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket} | format pattern "/b/{bucket}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patches a bucket. Changes to the bucket will be readable immediately after writing, but configuration changes may take time to propagate.
#
# PATCH /b/{bucket}
# operationId: storage.buckets.patch
# --acl item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, id?: string, kind?: string, projectTeam?: record, role?: string, selfLink?: string}
# --autoclass shape: {enabled?: bool, toggleTime?: string}
# --billing shape: {requesterPays?: bool}
# --cors item shape: {maxAgeSeconds?: int, method?: list, origin?: list, responseHeader?: list}
# --customPlacementConfig shape: {dataLocations?: list}
# --defaultObjectAcl item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, generation?: string, id?: string, kind?: string, object?: string, projectTeam?: record, role?: string, selfLink?: string}
# --encryption shape: {defaultKmsKeyName?: string}
# --iamConfiguration shape: {bucketPolicyOnly?: record, publicAccessPrevention?: string, uniformBucketLevelAccess?: record}
# --lifecycle shape: {rule?: list}
# --logging shape: {logBucket?: string, logObjectPrefix?: string}
# --owner shape: {entity?: string, entityId?: string}
# --retentionPolicy shape: {effectiveTime?: string, isLocked?: bool, retentionPeriod?: string}
# --versioning shape: {enabled?: bool}
# --website shape: {mainPageSuffix?: string, notFoundPage?: string}
export def "b storagebucketspatch" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --if-metageneration-match: string # Makes the return of the bucket metadata conditional on whether the bucket's current metageneration matches the given value.
  --if-metageneration-not-match: string # Makes the return of the bucket metadata conditional on whether the bucket's current metageneration does not match the given value.
  --predefined-acl: string@predefined-acl-completer # Apply a predefined set of access controls to this bucket.
  --predefined-default-object-acl: string@predefined-default-object-acl-completer # Apply a predefined set of default object access controls to this bucket.
  --projection: string@projection-completer # Set of properties to return. Defaults to full.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --acl: list # Access controls on the bucket. — item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, id?: string, kind?: string, projectTeam?: record, role?: string, selfLink?: string}
  --autoclass: record # The bucket's Autoclass configuration. — shape: {enabled?: bool, toggleTime?: string}
  --billing: record # The bucket's billing configuration. — shape: {requesterPays?: bool}
  --cors: list # The bucket's Cross-Origin Resource Sharing (CORS) configuration. — item shape: {maxAgeSeconds?: int, method?: list, origin?: list, responseHeader?: list}
  --custom-placement-config: record # The bucket's custom placement configuration for Custom Dual Regions. — shape: {dataLocations?: list}
  --default-event-based-hold: oneof<nothing, bool> # The default value for event-based hold on newly created objects in this bucket. Event-based hold is a way to retain objects indefinitely until an event occurs, signified by the hold's release. After being released, such objects will be subject to bucket-level retention (if any). One sample use case of this flag is for banks to hold loan documents for at least 3 years after loan is paid in full. Here, bucket-level retention is 3 years and the event is loan being paid in full. In this example, these objects will be held intact for any number of years until the event has occurred (event-based hold on the object is released) and then 3 more years after that. That means retention duration of the objects begins from the moment event-based hold transitioned from true to false. Objects under event-based hold cannot be deleted, overwritten or archived until the hold is removed.
  --default-object-acl: list # Default access controls to apply to new objects when no ACL is provided. — item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, generation?: string, id?: string, kind?: string, object?: string, projectTeam?: record, role?: string, selfLink?: string}
  --encryption: record # Encryption configuration for a bucket. — shape: {defaultKmsKeyName?: string}
  --etag: string # HTTP 1.1 Entity tag for the bucket.
  --iam-configuration: record # The bucket's IAM configuration. — shape: {bucketPolicyOnly?: record, publicAccessPrevention?: string, uniformBucketLevelAccess?: record}
  --id: string # The ID of the bucket. For buckets, the id and name properties are the same.
  --kind: string # The kind of item this is. For buckets, this is always storage#bucket. (default: storage#bucket)
  --labels: record # User-provided labels, in key/value pairs.
  --lifecycle: record # The bucket's lifecycle configuration. See lifecycle management for more information. — shape: {rule?: list}
  --location: string # The location of the bucket. Object data for objects in the bucket resides in physical storage within this region. Defaults to US. See the developer's guide for the authoritative list.
  --location-type: string # The type of the bucket location.
  --logging: record # The bucket's logging configuration, which defines the destination bucket and optional name prefix for the current bucket's logs. — shape: {logBucket?: string, logObjectPrefix?: string}
  --metageneration: string # The metadata generation of this bucket. (format: int64)
  --name: string # The name of the bucket.
  --owner: record # The owner of the bucket. This is always the project team's owner group. — shape: {entity?: string, entityId?: string}
  --project-number: string # The project number of the project the bucket belongs to. (format: uint64)
  --retention-policy: record # The bucket's retention policy. The retention policy enforces a minimum retention time for all objects contained in the bucket, based on their creation time. Any attempt to overwrite or delete objects younger than the retention period will result in a PERMISSION_DENIED error. An unlocked retention policy can be modified or removed from the bucket via a storage.buckets.update operation. A locked retention policy cannot be removed or shortened in duration for the lifetime of the bucket. Attempting to remove or decrease period of a locked retention policy will result in a PERMISSION_DENIED error. — shape: {effectiveTime?: string, isLocked?: bool, retentionPeriod?: string}
  --rpo: string # The Recovery Point Objective (RPO) of this bucket. Set to ASYNC_TURBO to turn on Turbo Replication on a bucket.
  --satisfies-pzs: oneof<nothing, bool> # Reserved for future use.
  --self-link: string # The URI of this bucket.
  --storage-class: string # The bucket's default storage class, used whenever no storageClass is specified for a newly-created object. This defines how objects in the bucket are stored and determines the SLA and the cost of storage. Values include MULTI_REGIONAL, REGIONAL, STANDARD, NEARLINE, COLDLINE, ARCHIVE, and DURABLE_REDUCED_AVAILABILITY. If this value is not specified when the bucket is created, it will default to STANDARD. For more information, see storage classes.
  --time-created: string # The creation time of the bucket in RFC 3339 format. (format: date-time)
  --updated: string # The modification time of the bucket in RFC 3339 format. (format: date-time)
  --versioning: record # The bucket's versioning configuration. — shape: {enabled?: bool}
  --website: record # The bucket's website configuration, controlling how the service behaves when accessing bucket contents as a web site. See the Static Website Examples for more information. — shape: {mainPageSuffix?: string, notFoundPage?: string}
]: any -> record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record, role: string, selfLink: string>, autoclass: record<enabled: bool, toggleTime: string>, billing: record<requesterPays: bool>, cors: table<maxAgeSeconds: int, method: list, origin: list, responseHeader: list>, customPlacementConfig: record<dataLocations: list<string>>, defaultEventBasedHold: bool, defaultObjectAcl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, encryption: record<defaultKmsKeyName: string>, etag: string, iamConfiguration: record<bucketPolicyOnly: record<enabled: bool, lockedTime: string>, publicAccessPrevention: string, uniformBucketLevelAccess: record<enabled: bool, lockedTime: string>>, id: string, kind: string, labels: record, lifecycle: record<rule: list<record>>, location: string, locationType: string, logging: record<logBucket: string, logObjectPrefix: string>, metageneration: string, name: string, owner: record<entity: string, entityId: string>, projectNumber: string, retentionPolicy: record<effectiveTime: string, isLocked: bool, retentionPeriod: string>, rpo: string, satisfiesPZS: bool, selfLink: string, storageClass: string, timeCreated: string, updated: string, versioning: record<enabled: bool>, website: record<mainPageSuffix: string, notFoundPage: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "ifMetagenerationMatch" $if_metageneration_match "scalar") (serialize-qp "ifMetagenerationNotMatch" $if_metageneration_not_match "scalar") (serialize-qp "predefinedAcl" $predefined_acl "scalar") (serialize-qp "predefinedDefaultObjectAcl" $predefined_default_object_acl "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket} | format pattern "/b/{bucket}") $qp)
  let body = {"acl": $acl, "autoclass": $autoclass, "billing": $billing, "cors": $cors, "customPlacementConfig": $custom_placement_config, "defaultEventBasedHold": $default_event_based_hold, "defaultObjectAcl": $default_object_acl, "encryption": $encryption, "etag": $etag, "iamConfiguration": $iam_configuration, "id": $id, "kind": $kind, "labels": $labels, "lifecycle": $lifecycle, "location": $location, "locationType": $location_type, "logging": $logging, "metageneration": $metageneration, "name": $name, "owner": $owner, "projectNumber": $project_number, "retentionPolicy": $retention_policy, "rpo": $rpo, "satisfiesPZS": $satisfies_pzs, "selfLink": $self_link, "storageClass": $storage_class, "timeCreated": $time_created, "updated": $updated, "versioning": $versioning, "website": $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a bucket. Changes to the bucket will be readable immediately after writing, but configuration changes may take time to propagate.
#
# PUT /b/{bucket}
# operationId: storage.buckets.update
# --acl item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, id?: string, kind?: string, projectTeam?: record, role?: string, selfLink?: string}
# --autoclass shape: {enabled?: bool, toggleTime?: string}
# --billing shape: {requesterPays?: bool}
# --cors item shape: {maxAgeSeconds?: int, method?: list, origin?: list, responseHeader?: list}
# --customPlacementConfig shape: {dataLocations?: list}
# --defaultObjectAcl item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, generation?: string, id?: string, kind?: string, object?: string, projectTeam?: record, role?: string, selfLink?: string}
# --encryption shape: {defaultKmsKeyName?: string}
# --iamConfiguration shape: {bucketPolicyOnly?: record, publicAccessPrevention?: string, uniformBucketLevelAccess?: record}
# --lifecycle shape: {rule?: list}
# --logging shape: {logBucket?: string, logObjectPrefix?: string}
# --owner shape: {entity?: string, entityId?: string}
# --retentionPolicy shape: {effectiveTime?: string, isLocked?: bool, retentionPeriod?: string}
# --versioning shape: {enabled?: bool}
# --website shape: {mainPageSuffix?: string, notFoundPage?: string}
export def "b storagebucketsupdate" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --if-metageneration-match: string # Makes the return of the bucket metadata conditional on whether the bucket's current metageneration matches the given value.
  --if-metageneration-not-match: string # Makes the return of the bucket metadata conditional on whether the bucket's current metageneration does not match the given value.
  --predefined-acl: string@predefined-acl-completer # Apply a predefined set of access controls to this bucket.
  --predefined-default-object-acl: string@predefined-default-object-acl-completer # Apply a predefined set of default object access controls to this bucket.
  --projection: string@projection-completer # Set of properties to return. Defaults to full.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --acl: list # Access controls on the bucket. — item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, id?: string, kind?: string, projectTeam?: record, role?: string, selfLink?: string}
  --autoclass: record # The bucket's Autoclass configuration. — shape: {enabled?: bool, toggleTime?: string}
  --billing: record # The bucket's billing configuration. — shape: {requesterPays?: bool}
  --cors: list # The bucket's Cross-Origin Resource Sharing (CORS) configuration. — item shape: {maxAgeSeconds?: int, method?: list, origin?: list, responseHeader?: list}
  --custom-placement-config: record # The bucket's custom placement configuration for Custom Dual Regions. — shape: {dataLocations?: list}
  --default-event-based-hold: oneof<nothing, bool> # The default value for event-based hold on newly created objects in this bucket. Event-based hold is a way to retain objects indefinitely until an event occurs, signified by the hold's release. After being released, such objects will be subject to bucket-level retention (if any). One sample use case of this flag is for banks to hold loan documents for at least 3 years after loan is paid in full. Here, bucket-level retention is 3 years and the event is loan being paid in full. In this example, these objects will be held intact for any number of years until the event has occurred (event-based hold on the object is released) and then 3 more years after that. That means retention duration of the objects begins from the moment event-based hold transitioned from true to false. Objects under event-based hold cannot be deleted, overwritten or archived until the hold is removed.
  --default-object-acl: list # Default access controls to apply to new objects when no ACL is provided. — item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, generation?: string, id?: string, kind?: string, object?: string, projectTeam?: record, role?: string, selfLink?: string}
  --encryption: record # Encryption configuration for a bucket. — shape: {defaultKmsKeyName?: string}
  --etag: string # HTTP 1.1 Entity tag for the bucket.
  --iam-configuration: record # The bucket's IAM configuration. — shape: {bucketPolicyOnly?: record, publicAccessPrevention?: string, uniformBucketLevelAccess?: record}
  --id: string # The ID of the bucket. For buckets, the id and name properties are the same.
  --kind: string # The kind of item this is. For buckets, this is always storage#bucket. (default: storage#bucket)
  --labels: record # User-provided labels, in key/value pairs.
  --lifecycle: record # The bucket's lifecycle configuration. See lifecycle management for more information. — shape: {rule?: list}
  --location: string # The location of the bucket. Object data for objects in the bucket resides in physical storage within this region. Defaults to US. See the developer's guide for the authoritative list.
  --location-type: string # The type of the bucket location.
  --logging: record # The bucket's logging configuration, which defines the destination bucket and optional name prefix for the current bucket's logs. — shape: {logBucket?: string, logObjectPrefix?: string}
  --metageneration: string # The metadata generation of this bucket. (format: int64)
  --name: string # The name of the bucket.
  --owner: record # The owner of the bucket. This is always the project team's owner group. — shape: {entity?: string, entityId?: string}
  --project-number: string # The project number of the project the bucket belongs to. (format: uint64)
  --retention-policy: record # The bucket's retention policy. The retention policy enforces a minimum retention time for all objects contained in the bucket, based on their creation time. Any attempt to overwrite or delete objects younger than the retention period will result in a PERMISSION_DENIED error. An unlocked retention policy can be modified or removed from the bucket via a storage.buckets.update operation. A locked retention policy cannot be removed or shortened in duration for the lifetime of the bucket. Attempting to remove or decrease period of a locked retention policy will result in a PERMISSION_DENIED error. — shape: {effectiveTime?: string, isLocked?: bool, retentionPeriod?: string}
  --rpo: string # The Recovery Point Objective (RPO) of this bucket. Set to ASYNC_TURBO to turn on Turbo Replication on a bucket.
  --satisfies-pzs: oneof<nothing, bool> # Reserved for future use.
  --self-link: string # The URI of this bucket.
  --storage-class: string # The bucket's default storage class, used whenever no storageClass is specified for a newly-created object. This defines how objects in the bucket are stored and determines the SLA and the cost of storage. Values include MULTI_REGIONAL, REGIONAL, STANDARD, NEARLINE, COLDLINE, ARCHIVE, and DURABLE_REDUCED_AVAILABILITY. If this value is not specified when the bucket is created, it will default to STANDARD. For more information, see storage classes.
  --time-created: string # The creation time of the bucket in RFC 3339 format. (format: date-time)
  --updated: string # The modification time of the bucket in RFC 3339 format. (format: date-time)
  --versioning: record # The bucket's versioning configuration. — shape: {enabled?: bool}
  --website: record # The bucket's website configuration, controlling how the service behaves when accessing bucket contents as a web site. See the Static Website Examples for more information. — shape: {mainPageSuffix?: string, notFoundPage?: string}
]: any -> record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record, role: string, selfLink: string>, autoclass: record<enabled: bool, toggleTime: string>, billing: record<requesterPays: bool>, cors: table<maxAgeSeconds: int, method: list, origin: list, responseHeader: list>, customPlacementConfig: record<dataLocations: list<string>>, defaultEventBasedHold: bool, defaultObjectAcl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, encryption: record<defaultKmsKeyName: string>, etag: string, iamConfiguration: record<bucketPolicyOnly: record<enabled: bool, lockedTime: string>, publicAccessPrevention: string, uniformBucketLevelAccess: record<enabled: bool, lockedTime: string>>, id: string, kind: string, labels: record, lifecycle: record<rule: list<record>>, location: string, locationType: string, logging: record<logBucket: string, logObjectPrefix: string>, metageneration: string, name: string, owner: record<entity: string, entityId: string>, projectNumber: string, retentionPolicy: record<effectiveTime: string, isLocked: bool, retentionPeriod: string>, rpo: string, satisfiesPZS: bool, selfLink: string, storageClass: string, timeCreated: string, updated: string, versioning: record<enabled: bool>, website: record<mainPageSuffix: string, notFoundPage: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "ifMetagenerationMatch" $if_metageneration_match "scalar") (serialize-qp "ifMetagenerationNotMatch" $if_metageneration_not_match "scalar") (serialize-qp "predefinedAcl" $predefined_acl "scalar") (serialize-qp "predefinedDefaultObjectAcl" $predefined_default_object_acl "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket} | format pattern "/b/{bucket}") $qp)
  let body = {"acl": $acl, "autoclass": $autoclass, "billing": $billing, "cors": $cors, "customPlacementConfig": $custom_placement_config, "defaultEventBasedHold": $default_event_based_hold, "defaultObjectAcl": $default_object_acl, "encryption": $encryption, "etag": $etag, "iamConfiguration": $iam_configuration, "id": $id, "kind": $kind, "labels": $labels, "lifecycle": $lifecycle, "location": $location, "locationType": $location_type, "logging": $logging, "metageneration": $metageneration, "name": $name, "owner": $owner, "projectNumber": $project_number, "retentionPolicy": $retention_policy, "rpo": $rpo, "satisfiesPZS": $satisfies_pzs, "selfLink": $self_link, "storageClass": $storage_class, "timeCreated": $time_created, "updated": $updated, "versioning": $versioning, "website": $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves ACL entries on the specified bucket.
#
# GET /b/{bucket}/acl
# operationId: storage.bucketAccessControls.list
export def "b-acl storagebucketAccessControlslist" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> record<items: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record, role: string, selfLink: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket} | format pattern "/b/{bucket}/acl") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new ACL entry on the specified bucket.
#
# POST /b/{bucket}/acl
# operationId: storage.bucketAccessControls.insert
# --projectTeam shape: {projectNumber?: string, team?: string}
export def "b-acl storagebucketAccessControlsinsert" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --body-bucket: string # The name of the bucket.
  --domain: string # The domain associated with the entity, if any.
  --email: string # The email address associated with the entity, if any.
  --entity: string # The entity holding the permission, in one of the following forms:  - user-userId  - user-email  - group-groupId  - group-email  - domain-domain  - project-team-projectId  - allUsers  - allAuthenticatedUsers Examples:  - The user liz@example.com would be user-liz@example.com.  - The group example@googlegroups.com would be group-example@googlegroups.com.  - To refer to all members of the Google Apps for Business domain example.com, the entity would be domain-example.com.
  --entity-id: string # The ID for the entity, if any.
  --etag: string # HTTP 1.1 Entity tag for the access-control entry.
  --id: string # The ID of the access-control entry.
  --kind: string # The kind of item this is. For bucket access control entries, this is always storage#bucketAccessControl. (default: storage#bucketAccessControl)
  --project-team: record # The project team associated with the entity, if any. — shape: {projectNumber?: string, team?: string}
  --role: string # The access permission for the entity.
  --self-link: string # The link to this access-control entry.
]: any -> record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket} | format pattern "/b/{bucket}/acl") $qp)
  let body = {"bucket": $body_bucket, "domain": $domain, "email": $email, "entity": $entity, "entityId": $entity_id, "etag": $etag, "id": $id, "kind": $kind, "projectTeam": $project_team, "role": $role, "selfLink": $self_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Permanently deletes the ACL entry for the specified entity on the specified bucket.
#
# DELETE /b/{bucket}/acl/{entity}
# operationId: storage.bucketAccessControls.delete
export def "b-acl storagebucketAccessControlsdelete" [
  bucket: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, entity: $entity} | format pattern "/b/{bucket}/acl/{entity}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the ACL entry for the specified entity on the specified bucket.
#
# GET /b/{bucket}/acl/{entity}
# operationId: storage.bucketAccessControls.get
export def "b-acl storagebucketAccessControlsget" [
  bucket: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, entity: $entity} | format pattern "/b/{bucket}/acl/{entity}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patches an ACL entry on the specified bucket.
#
# PATCH /b/{bucket}/acl/{entity}
# operationId: storage.bucketAccessControls.patch
# --projectTeam shape: {projectNumber?: string, team?: string}
export def "b-acl storagebucketAccessControlspatch" [
  bucket: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --body-bucket: string # The name of the bucket.
  --domain: string # The domain associated with the entity, if any.
  --email: string # The email address associated with the entity, if any.
  --body-entity: string # The entity holding the permission, in one of the following forms:  - user-userId  - user-email  - group-groupId  - group-email  - domain-domain  - project-team-projectId  - allUsers  - allAuthenticatedUsers Examples:  - The user liz@example.com would be user-liz@example.com.  - The group example@googlegroups.com would be group-example@googlegroups.com.  - To refer to all members of the Google Apps for Business domain example.com, the entity would be domain-example.com.
  --entity-id: string # The ID for the entity, if any.
  --etag: string # HTTP 1.1 Entity tag for the access-control entry.
  --id: string # The ID of the access-control entry.
  --kind: string # The kind of item this is. For bucket access control entries, this is always storage#bucketAccessControl. (default: storage#bucketAccessControl)
  --project-team: record # The project team associated with the entity, if any. — shape: {projectNumber?: string, team?: string}
  --role: string # The access permission for the entity.
  --self-link: string # The link to this access-control entry.
]: any -> record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, entity: $entity} | format pattern "/b/{bucket}/acl/{entity}") $qp)
  let body = {"bucket": $body_bucket, "domain": $domain, "email": $email, "entity": $body_entity, "entityId": $entity_id, "etag": $etag, "id": $id, "kind": $kind, "projectTeam": $project_team, "role": $role, "selfLink": $self_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates an ACL entry on the specified bucket.
#
# PUT /b/{bucket}/acl/{entity}
# operationId: storage.bucketAccessControls.update
# --projectTeam shape: {projectNumber?: string, team?: string}
export def "b-acl storagebucketAccessControlsupdate" [
  bucket: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --body-bucket: string # The name of the bucket.
  --domain: string # The domain associated with the entity, if any.
  --email: string # The email address associated with the entity, if any.
  --body-entity: string # The entity holding the permission, in one of the following forms:  - user-userId  - user-email  - group-groupId  - group-email  - domain-domain  - project-team-projectId  - allUsers  - allAuthenticatedUsers Examples:  - The user liz@example.com would be user-liz@example.com.  - The group example@googlegroups.com would be group-example@googlegroups.com.  - To refer to all members of the Google Apps for Business domain example.com, the entity would be domain-example.com.
  --entity-id: string # The ID for the entity, if any.
  --etag: string # HTTP 1.1 Entity tag for the access-control entry.
  --id: string # The ID of the access-control entry.
  --kind: string # The kind of item this is. For bucket access control entries, this is always storage#bucketAccessControl. (default: storage#bucketAccessControl)
  --project-team: record # The project team associated with the entity, if any. — shape: {projectNumber?: string, team?: string}
  --role: string # The access permission for the entity.
  --self-link: string # The link to this access-control entry.
]: any -> record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, entity: $entity} | format pattern "/b/{bucket}/acl/{entity}") $qp)
  let body = {"bucket": $body_bucket, "domain": $domain, "email": $email, "entity": $body_entity, "entityId": $entity_id, "etag": $etag, "id": $id, "kind": $kind, "projectTeam": $project_team, "role": $role, "selfLink": $self_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves default object ACL entries on the specified bucket.
#
# GET /b/{bucket}/defaultObjectAcl
# operationId: storage.defaultObjectAccessControls.list
export def "b-default-object-acl storagedefaultObjectAccessControlslist" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --if-metageneration-match: string # If present, only return default ACL listing if the bucket's current metageneration matches this value.
  --if-metageneration-not-match: string # If present, only return default ACL listing if the bucket's current metageneration does not match the given value.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> record<items: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "ifMetagenerationMatch" $if_metageneration_match "scalar") (serialize-qp "ifMetagenerationNotMatch" $if_metageneration_not_match "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket} | format pattern "/b/{bucket}/defaultObjectAcl") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new default object ACL entry on the specified bucket.
#
# POST /b/{bucket}/defaultObjectAcl
# operationId: storage.defaultObjectAccessControls.insert
# --projectTeam shape: {projectNumber?: string, team?: string}
export def "b-default-object-acl storagedefaultObjectAccessControlsinsert" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --body-bucket: string # The name of the bucket.
  --domain: string # The domain associated with the entity, if any.
  --email: string # The email address associated with the entity, if any.
  --entity: string # The entity holding the permission, in one of the following forms:  - user-userId  - user-email  - group-groupId  - group-email  - domain-domain  - project-team-projectId  - allUsers  - allAuthenticatedUsers Examples:  - The user liz@example.com would be user-liz@example.com.  - The group example@googlegroups.com would be group-example@googlegroups.com.  - To refer to all members of the Google Apps for Business domain example.com, the entity would be domain-example.com.
  --entity-id: string # The ID for the entity, if any.
  --etag: string # HTTP 1.1 Entity tag for the access-control entry.
  --generation: string # The content generation of the object, if applied to an object. (format: int64)
  --id: string # The ID of the access-control entry.
  --kind: string # The kind of item this is. For object access control entries, this is always storage#objectAccessControl. (default: storage#objectAccessControl)
  --object: string # The name of the object, if applied to an object.
  --project-team: record # The project team associated with the entity, if any. — shape: {projectNumber?: string, team?: string}
  --role: string # The access permission for the entity.
  --self-link: string # The link to this access-control entry.
]: any -> record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket} | format pattern "/b/{bucket}/defaultObjectAcl") $qp)
  let body = {"bucket": $body_bucket, "domain": $domain, "email": $email, "entity": $entity, "entityId": $entity_id, "etag": $etag, "generation": $generation, "id": $id, "kind": $kind, "object": $object, "projectTeam": $project_team, "role": $role, "selfLink": $self_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Permanently deletes the default object ACL entry for the specified entity on the specified bucket.
#
# DELETE /b/{bucket}/defaultObjectAcl/{entity}
# operationId: storage.defaultObjectAccessControls.delete
export def "b-default-object-acl storagedefaultObjectAccessControlsdelete" [
  bucket: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, entity: $entity} | format pattern "/b/{bucket}/defaultObjectAcl/{entity}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the default object ACL entry for the specified entity on the specified bucket.
#
# GET /b/{bucket}/defaultObjectAcl/{entity}
# operationId: storage.defaultObjectAccessControls.get
export def "b-default-object-acl storagedefaultObjectAccessControlsget" [
  bucket: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, entity: $entity} | format pattern "/b/{bucket}/defaultObjectAcl/{entity}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patches a default object ACL entry on the specified bucket.
#
# PATCH /b/{bucket}/defaultObjectAcl/{entity}
# operationId: storage.defaultObjectAccessControls.patch
# --projectTeam shape: {projectNumber?: string, team?: string}
export def "b-default-object-acl storagedefaultObjectAccessControlspatch" [
  bucket: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --body-bucket: string # The name of the bucket.
  --domain: string # The domain associated with the entity, if any.
  --email: string # The email address associated with the entity, if any.
  --body-entity: string # The entity holding the permission, in one of the following forms:  - user-userId  - user-email  - group-groupId  - group-email  - domain-domain  - project-team-projectId  - allUsers  - allAuthenticatedUsers Examples:  - The user liz@example.com would be user-liz@example.com.  - The group example@googlegroups.com would be group-example@googlegroups.com.  - To refer to all members of the Google Apps for Business domain example.com, the entity would be domain-example.com.
  --entity-id: string # The ID for the entity, if any.
  --etag: string # HTTP 1.1 Entity tag for the access-control entry.
  --generation: string # The content generation of the object, if applied to an object. (format: int64)
  --id: string # The ID of the access-control entry.
  --kind: string # The kind of item this is. For object access control entries, this is always storage#objectAccessControl. (default: storage#objectAccessControl)
  --object: string # The name of the object, if applied to an object.
  --project-team: record # The project team associated with the entity, if any. — shape: {projectNumber?: string, team?: string}
  --role: string # The access permission for the entity.
  --self-link: string # The link to this access-control entry.
]: any -> record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, entity: $entity} | format pattern "/b/{bucket}/defaultObjectAcl/{entity}") $qp)
  let body = {"bucket": $body_bucket, "domain": $domain, "email": $email, "entity": $body_entity, "entityId": $entity_id, "etag": $etag, "generation": $generation, "id": $id, "kind": $kind, "object": $object, "projectTeam": $project_team, "role": $role, "selfLink": $self_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a default object ACL entry on the specified bucket.
#
# PUT /b/{bucket}/defaultObjectAcl/{entity}
# operationId: storage.defaultObjectAccessControls.update
# --projectTeam shape: {projectNumber?: string, team?: string}
export def "b-default-object-acl storagedefaultObjectAccessControlsupdate" [
  bucket: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --body-bucket: string # The name of the bucket.
  --domain: string # The domain associated with the entity, if any.
  --email: string # The email address associated with the entity, if any.
  --body-entity: string # The entity holding the permission, in one of the following forms:  - user-userId  - user-email  - group-groupId  - group-email  - domain-domain  - project-team-projectId  - allUsers  - allAuthenticatedUsers Examples:  - The user liz@example.com would be user-liz@example.com.  - The group example@googlegroups.com would be group-example@googlegroups.com.  - To refer to all members of the Google Apps for Business domain example.com, the entity would be domain-example.com.
  --entity-id: string # The ID for the entity, if any.
  --etag: string # HTTP 1.1 Entity tag for the access-control entry.
  --generation: string # The content generation of the object, if applied to an object. (format: int64)
  --id: string # The ID of the access-control entry.
  --kind: string # The kind of item this is. For object access control entries, this is always storage#objectAccessControl. (default: storage#objectAccessControl)
  --object: string # The name of the object, if applied to an object.
  --project-team: record # The project team associated with the entity, if any. — shape: {projectNumber?: string, team?: string}
  --role: string # The access permission for the entity.
  --self-link: string # The link to this access-control entry.
]: any -> record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, entity: $entity} | format pattern "/b/{bucket}/defaultObjectAcl/{entity}") $qp)
  let body = {"bucket": $body_bucket, "domain": $domain, "email": $email, "entity": $body_entity, "entityId": $entity_id, "etag": $etag, "generation": $generation, "id": $id, "kind": $kind, "object": $object, "projectTeam": $project_team, "role": $role, "selfLink": $self_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns an IAM policy for the specified bucket.
#
# GET /b/{bucket}/iam
# operationId: storage.buckets.getIamPolicy
export def "b-iam storagebucketsgetIamPolicy" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --options-requested-policy-version: int # The IAM policy format version to be returned. If the optionsRequestedPolicyVersion is for an older version that doesn't support part of the requested IAM policy, the request fails.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> record<bindings: table<condition: record, members: list, role: string>, etag: string, kind: string, resourceId: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "optionsRequestedPolicyVersion" $options_requested_policy_version "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket} | format pattern "/b/{bucket}/iam") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an IAM policy for the specified bucket.
#
# PUT /b/{bucket}/iam
# operationId: storage.buckets.setIamPolicy
# --bindings item shape: {condition?: record, members?: list, role?: string}
export def "b-iam storagebucketssetIamPolicy" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --bindings: list # An association between a role, which comes with a set of permissions, and members who may assume that role. — item shape: {condition?: record, members?: list, role?: string}
  --etag: string # HTTP 1.1  Entity tag for the policy. (format: byte)
  --kind: string # The kind of item this is. For policies, this is always storage#policy. This field is ignored on input. (default: storage#policy)
  --resource-id: string # The ID of the resource to which this policy belongs. Will be of the form projects/_/buckets/bucket for buckets, and projects/_/buckets/bucket/objects/object for objects. A specific generation may be specified by appending #generationNumber to the end of the object name, e.g. projects/_/buckets/my-bucket/objects/data.txt#17. The current generation can be denoted with #0. This field is ignored on input.
  --version: int # The IAM policy format version. (format: int32)
]: any -> record<bindings: table<condition: record, members: list, role: string>, etag: string, kind: string, resourceId: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket} | format pattern "/b/{bucket}/iam") $qp)
  let body = {"bindings": $bindings, "etag": $etag, "kind": $kind, "resourceId": $resource_id, "version": $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Tests a set of permissions on the given bucket to see which, if any, are held by the caller.
#
# GET /b/{bucket}/iam/testPermissions
# operationId: storage.buckets.testIamPermissions
export def "b-iam-test-permissions storagebucketstestIamPermissions" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --permissions: list # Permissions to test.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> record<kind: string, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "permissions" $permissions "multi") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket} | format pattern "/b/{bucket}/iam/testPermissions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Locks retention policy on a bucket.
#
# POST /b/{bucket}/lockRetentionPolicy
# operationId: storage.buckets.lockRetentionPolicy
export def "b-lock-retention-policy storagebucketslockRetentionPolicy" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --if-metageneration-match: string # Makes the operation conditional on whether bucket's current metageneration matches the given value.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record, role: string, selfLink: string>, autoclass: record<enabled: bool, toggleTime: string>, billing: record<requesterPays: bool>, cors: table<maxAgeSeconds: int, method: list, origin: list, responseHeader: list>, customPlacementConfig: record<dataLocations: list<string>>, defaultEventBasedHold: bool, defaultObjectAcl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, encryption: record<defaultKmsKeyName: string>, etag: string, iamConfiguration: record<bucketPolicyOnly: record<enabled: bool, lockedTime: string>, publicAccessPrevention: string, uniformBucketLevelAccess: record<enabled: bool, lockedTime: string>>, id: string, kind: string, labels: record, lifecycle: record<rule: list<record>>, location: string, locationType: string, logging: record<logBucket: string, logObjectPrefix: string>, metageneration: string, name: string, owner: record<entity: string, entityId: string>, projectNumber: string, retentionPolicy: record<effectiveTime: string, isLocked: bool, retentionPeriod: string>, rpo: string, satisfiesPZS: bool, selfLink: string, storageClass: string, timeCreated: string, updated: string, versioning: record<enabled: bool>, website: record<mainPageSuffix: string, notFoundPage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "ifMetagenerationMatch" $if_metageneration_match "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket} | format pattern "/b/{bucket}/lockRetentionPolicy") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of notification subscriptions for a given bucket.
#
# GET /b/{bucket}/notificationConfigs
# operationId: storage.notifications.list
export def "b-notification-configs storagenotificationslist" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> record<items: table<custom_attributes: record, etag: string, event_types: list, id: string, kind: string, object_name_prefix: string, payload_format: string, selfLink: string, topic: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket} | format pattern "/b/{bucket}/notificationConfigs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a notification subscription for a given bucket.
#
# POST /b/{bucket}/notificationConfigs
# operationId: storage.notifications.insert
export def "b-notification-configs storagenotificationsinsert" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --custom-attributes: record # An optional list of additional attributes to attach to each Cloud PubSub message published for this notification subscription.
  --etag: string # HTTP 1.1 Entity tag for this subscription notification.
  --event-types: list # If present, only send notifications about listed event types. If empty, sent notifications for all event types.
  --id: string # The ID of the notification.
  --kind: string # The kind of item this is. For notifications, this is always storage#notification. (default: storage#notification)
  --object-name-prefix: string # If present, only apply this notification configuration to object names that begin with this prefix.
  --payload-format: string # The desired content of the Payload. (default: JSON_API_V1)
  --self-link: string # The canonical URL of this notification.
  --topic: string # The Cloud PubSub topic to which this subscription publishes. Formatted as: '//pubsub.googleapis.com/projects/{project-identifier}/topics/{my-topic}'
]: any -> record<custom_attributes: record, etag: string, event_types: list<string>, id: string, kind: string, object_name_prefix: string, payload_format: string, selfLink: string, topic: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket} | format pattern "/b/{bucket}/notificationConfigs") $qp)
  let body = {"custom_attributes": $custom_attributes, "etag": $etag, "event_types": $event_types, "id": $id, "kind": $kind, "object_name_prefix": $object_name_prefix, "payload_format": $payload_format, "selfLink": $self_link, "topic": $topic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Permanently deletes a notification subscription.
#
# DELETE /b/{bucket}/notificationConfigs/{notification}
# operationId: storage.notifications.delete
export def "b-notification-configs storagenotificationsdelete" [
  bucket: string
  notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, notification: $notification} | format pattern "/b/{bucket}/notificationConfigs/{notification}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View a notification configuration.
#
# GET /b/{bucket}/notificationConfigs/{notification}
# operationId: storage.notifications.get
export def "b-notification-configs storagenotificationsget" [
  bucket: string
  notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> record<custom_attributes: record, etag: string, event_types: list<string>, id: string, kind: string, object_name_prefix: string, payload_format: string, selfLink: string, topic: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, notification: $notification} | format pattern "/b/{bucket}/notificationConfigs/{notification}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of objects matching the criteria.
#
# GET /b/{bucket}/o
# operationId: storage.objects.list
export def "b-o storageobjectslist" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --delimiter: string # Returns results in a directory-like mode. items will contain only objects whose names, aside from the prefix, do not contain delimiter. Objects whose names, aside from the prefix, contain delimiter will have their name, truncated after the delimiter, returned in prefixes. Duplicate prefixes are omitted.
  --end-offset: string # Filter results to objects whose names are lexicographically before endOffset. If startOffset is also set, the objects listed will have names between startOffset (inclusive) and endOffset (exclusive).
  --include-trailing-delimiter: oneof<nothing, bool> # If true, objects that end in exactly one instance of delimiter will have their metadata included in items in addition to prefixes.
  --match-glob: string # Filter results to objects and prefixes that match this glob pattern.
  --max-results: int # Maximum number of items plus prefixes to return in a single page of responses. As duplicate prefixes are omitted, fewer total results may be returned than requested. The service will use this parameter or 1,000 items, whichever is smaller.
  --page-token: string # A previously-returned page token representing part of the larger set of results to view.
  --prefix: string # Filter results to objects whose names begin with this prefix.
  --projection: string@projection-completer # Set of properties to return. Defaults to noAcl.
  --start-offset: string # Filter results to objects whose names are lexicographically equal to or after startOffset. If endOffset is also set, the objects listed will have names between startOffset (inclusive) and endOffset (exclusive).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --versions: oneof<nothing, bool> # If true, lists all versions of an object as distinct results. The default is false. For more information, see Object Versioning.
]: nothing -> record<items: table<acl: list, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string>, kind: string, nextPageToken: string, prefixes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "delimiter" $delimiter "scalar") (serialize-qp "endOffset" $end_offset "scalar") (serialize-qp "includeTrailingDelimiter" $include_trailing_delimiter "scalar") (serialize-qp "matchGlob" $match_glob "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "startOffset" $start_offset "scalar") (serialize-qp "userProject" $user_project "scalar") (serialize-qp "versions" $versions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket} | format pattern "/b/{bucket}/o") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stores a new object and metadata.
#
# POST /b/{bucket}/o
# operationId: storage.objects.insert
export def "b-o storageobjectsinsert" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --content-encoding: string # If set, sets the contentEncoding property of the final object to this value. Setting this parameter is equivalent to setting the contentEncoding metadata property. This can be useful when uploading an object with uploadType=media to indicate the encoding of the content being uploaded.
  --if-generation-match: string # Makes the operation conditional on whether the object's current generation matches the given value. Setting to 0 makes the operation succeed only if there are no live versions of the object.
  --if-generation-not-match: string # Makes the operation conditional on whether the object's current generation does not match the given value. If no live object exists, the precondition fails. Setting to 0 makes the operation succeed only if there is a live version of the object.
  --if-metageneration-match: string # Makes the operation conditional on whether the object's current metageneration matches the given value.
  --if-metageneration-not-match: string # Makes the operation conditional on whether the object's current metageneration does not match the given value.
  --kms-key-name: string # Resource name of the Cloud KMS key, of the form projects/my-project/locations/global/keyRings/my-kr/cryptoKeys/my-key, that will be used to encrypt the object. Overrides the object metadata's kms_key_name value, if any.
  --name: string # Name of the object. Required when the object metadata is not otherwise provided. Overrides the object metadata's name value, if any. For information about how to URL encode object names to be path safe, see Encoding URI Path Parts.
  --predefined-acl: string@predefined-acl-completer-1 # Apply a predefined set of access controls to this object.
  --projection: string@projection-completer # Set of properties to return. Defaults to noAcl, unless the object resource specifies the acl property, when it defaults to full.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --body: record
]: any -> record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record<encryptionAlgorithm: string, keySha256: string>, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record<entity: string, entityId: string>, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "contentEncoding" $content_encoding "scalar") (serialize-qp "ifGenerationMatch" $if_generation_match "scalar") (serialize-qp "ifGenerationNotMatch" $if_generation_not_match "scalar") (serialize-qp "ifMetagenerationMatch" $if_metageneration_match "scalar") (serialize-qp "ifMetagenerationNotMatch" $if_metageneration_not_match "scalar") (serialize-qp "kmsKeyName" $kms_key_name "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "predefinedAcl" $predefined_acl "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket} | format pattern "/b/{bucket}/o") $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Watch for changes on all objects in a bucket.
#
# POST /b/{bucket}/o/watch
# operationId: storage.objects.watchAll
export def "b-o-watch storageobjectswatchAll" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --delimiter: string # Returns results in a directory-like mode. items will contain only objects whose names, aside from the prefix, do not contain delimiter. Objects whose names, aside from the prefix, contain delimiter will have their name, truncated after the delimiter, returned in prefixes. Duplicate prefixes are omitted.
  --end-offset: string # Filter results to objects whose names are lexicographically before endOffset. If startOffset is also set, the objects listed will have names between startOffset (inclusive) and endOffset (exclusive).
  --include-trailing-delimiter: oneof<nothing, bool> # If true, objects that end in exactly one instance of delimiter will have their metadata included in items in addition to prefixes.
  --max-results: int # Maximum number of items plus prefixes to return in a single page of responses. As duplicate prefixes are omitted, fewer total results may be returned than requested. The service will use this parameter or 1,000 items, whichever is smaller.
  --page-token: string # A previously-returned page token representing part of the larger set of results to view.
  --prefix: string # Filter results to objects whose names begin with this prefix.
  --projection: string@projection-completer # Set of properties to return. Defaults to noAcl.
  --start-offset: string # Filter results to objects whose names are lexicographically equal to or after startOffset. If endOffset is also set, the objects listed will have names between startOffset (inclusive) and endOffset (exclusive).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --versions: oneof<nothing, bool> # If true, lists all versions of an object as distinct results. The default is false. For more information, see Object Versioning.
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is "api#channel". (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional.
  --type: string # The type of delivery mechanism used for this channel.
]: any -> record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "delimiter" $delimiter "scalar") (serialize-qp "endOffset" $end_offset "scalar") (serialize-qp "includeTrailingDelimiter" $include_trailing_delimiter "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "startOffset" $start_offset "scalar") (serialize-qp "userProject" $user_project "scalar") (serialize-qp "versions" $versions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket} | format pattern "/b/{bucket}/o/watch") $qp)
  let body = {"address": $address, "expiration": $expiration, "id": $id, "kind": $kind, "params": $params, "payload": $payload, "resourceId": $resource_id, "resourceUri": $resource_uri, "token": $body_token, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an object and its metadata. Deletions are permanent if versioning is not enabled for the bucket, or if the generation parameter is used.
#
# DELETE /b/{bucket}/o/{object}
# operationId: storage.objects.delete
export def "b-o storageobjectsdelete" [
  bucket: string
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, permanently deletes a specific revision of this object (as opposed to the latest version, the default).
  --if-generation-match: string # Makes the operation conditional on whether the object's current generation matches the given value. Setting to 0 makes the operation succeed only if there are no live versions of the object.
  --if-generation-not-match: string # Makes the operation conditional on whether the object's current generation does not match the given value. If no live object exists, the precondition fails. Setting to 0 makes the operation succeed only if there is a live version of the object.
  --if-metageneration-match: string # Makes the operation conditional on whether the object's current metageneration matches the given value.
  --if-metageneration-not-match: string # Makes the operation conditional on whether the object's current metageneration does not match the given value.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "ifGenerationMatch" $if_generation_match "scalar") (serialize-qp "ifGenerationNotMatch" $if_generation_not_match "scalar") (serialize-qp "ifMetagenerationMatch" $if_metageneration_match "scalar") (serialize-qp "ifMetagenerationNotMatch" $if_metageneration_not_match "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, object: $object} | format pattern "/b/{bucket}/o/{object}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves an object or its metadata.
#
# GET /b/{bucket}/o/{object}
# operationId: storage.objects.get
export def "b-o storageobjectsget" [
  bucket: string
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --if-generation-match: string # Makes the operation conditional on whether the object's current generation matches the given value. Setting to 0 makes the operation succeed only if there are no live versions of the object.
  --if-generation-not-match: string # Makes the operation conditional on whether the object's current generation does not match the given value. If no live object exists, the precondition fails. Setting to 0 makes the operation succeed only if there is a live version of the object.
  --if-metageneration-match: string # Makes the operation conditional on whether the object's current metageneration matches the given value.
  --if-metageneration-not-match: string # Makes the operation conditional on whether the object's current metageneration does not match the given value.
  --projection: string@projection-completer # Set of properties to return. Defaults to noAcl.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record<encryptionAlgorithm: string, keySha256: string>, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record<entity: string, entityId: string>, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "ifGenerationMatch" $if_generation_match "scalar") (serialize-qp "ifGenerationNotMatch" $if_generation_not_match "scalar") (serialize-qp "ifMetagenerationMatch" $if_metageneration_match "scalar") (serialize-qp "ifMetagenerationNotMatch" $if_metageneration_not_match "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, object: $object} | format pattern "/b/{bucket}/o/{object}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patches an object's metadata.
#
# PATCH /b/{bucket}/o/{object}
# operationId: storage.objects.patch
# --acl item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, generation?: string, id?: string, kind?: string, object?: string, projectTeam?: record, role?: string, selfLink?: string}
# --customerEncryption shape: {encryptionAlgorithm?: string, keySha256?: string}
# --owner shape: {entity?: string, entityId?: string}
export def "b-o storageobjectspatch" [
  bucket: string
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --if-generation-match: string # Makes the operation conditional on whether the object's current generation matches the given value. Setting to 0 makes the operation succeed only if there are no live versions of the object.
  --if-generation-not-match: string # Makes the operation conditional on whether the object's current generation does not match the given value. If no live object exists, the precondition fails. Setting to 0 makes the operation succeed only if there is a live version of the object.
  --if-metageneration-match: string # Makes the operation conditional on whether the object's current metageneration matches the given value.
  --if-metageneration-not-match: string # Makes the operation conditional on whether the object's current metageneration does not match the given value.
  --predefined-acl: string@predefined-acl-completer-1 # Apply a predefined set of access controls to this object.
  --projection: string@projection-completer # Set of properties to return. Defaults to full.
  --user-project: string # The project to be billed for this request, for Requester Pays buckets.
  --acl: list # Access controls on the object. — item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, generation?: string, id?: string, kind?: string, object?: string, projectTeam?: record, role?: string, selfLink?: string}
  --body-bucket: string # The name of the bucket containing this object.
  --cache-control: string # Cache-Control directive for the object data. If omitted, and the object is accessible to all anonymous users, the default will be public, max-age=3600.
  --component-count: int # Number of underlying components that make up this object. Components are accumulated by compose operations. (format: int32)
  --content-disposition: string # Content-Disposition of the object data.
  --content-encoding: string # Content-Encoding of the object data.
  --content-language: string # Content-Language of the object data.
  --content-type: string # Content-Type of the object data. If an object is stored without a Content-Type, it is served as application/octet-stream.
  --crc32c: string # CRC32c checksum, as described in RFC 4960, Appendix B; encoded using base64 in big-endian byte order. For more information about using the CRC32c checksum, see Hashes and ETags: Best Practices.
  --custom-time: string # A timestamp in RFC 3339 format specified by the user for an object. (format: date-time)
  --customer-encryption: record # Metadata of customer-supplied encryption key, if the object is encrypted by such a key. — shape: {encryptionAlgorithm?: string, keySha256?: string}
  --etag: string # HTTP 1.1 Entity tag for the object.
  --event-based-hold: oneof<nothing, bool> # Whether an object is under event-based hold. Event-based hold is a way to retain objects until an event occurs, which is signified by the hold's release (i.e. this value is set to false). After being released (set to false), such objects will be subject to bucket-level retention (if any). One sample use case of this flag is for banks to hold loan documents for at least 3 years after loan is paid in full. Here, bucket-level retention is 3 years and the event is the loan being paid in full. In this example, these objects will be held intact for any number of years until the event has occurred (event-based hold on the object is released) and then 3 more years after that. That means retention duration of the objects begins from the moment event-based hold transitioned from true to false.
  --generation: string # The content generation of this object. Used for object versioning. (format: int64)
  --id: string # The ID of the object, including the bucket name, object name, and generation number.
  --kind: string # The kind of item this is. For objects, this is always storage#object. (default: storage#object)
  --kms-key-name: string # Not currently supported. Specifying the parameter causes the request to fail with status code 400 - Bad Request.
  --md5-hash: string # MD5 hash of the data; encoded using base64. For more information about using the MD5 hash, see Hashes and ETags: Best Practices.
  --media-link: string # Media download link.
  --metadata: record # User-provided metadata, in key/value pairs.
  --metageneration: string # The version of the metadata for this object at this generation. Used for preconditions and for detecting changes in metadata. A metageneration number is only meaningful in the context of a particular generation of a particular object. (format: int64)
  --name: string # The name of the object. Required if not specified by URL parameter.
  --owner: record # The owner of the object. This will always be the uploader of the object. — shape: {entity?: string, entityId?: string}
  --retention-expiration-time: string # A server-determined value that specifies the earliest time that the object's retention period expires. This value is in RFC 3339 format. Note 1: This field is not provided for objects with an active event-based hold, since retention expiration is unknown until the hold is removed. Note 2: This value can be provided even when temporary hold is set (so that the user can reason about policy without having to first unset the temporary hold). (format: date-time)
  --self-link: string # The link to this object.
  --size: string # Content-Length of the data in bytes. (format: uint64)
  --storage-class: string # Storage class of the object.
  --temporary-hold: oneof<nothing, bool> # Whether an object is under temporary hold. While this flag is set to true, the object is protected against deletion and overwrites. A common use case of this flag is regulatory investigations where objects need to be retained while the investigation is ongoing. Note that unlike event-based hold, temporary hold does not impact retention expiration time of an object.
  --time-created: string # The creation time of the object in RFC 3339 format. (format: date-time)
  --time-deleted: string # The deletion time of the object in RFC 3339 format. Will be returned if and only if this version of the object has been deleted. (format: date-time)
  --time-storage-class-updated: string # The time at which the object's storage class was last changed. When the object is initially created, it will be set to timeCreated. (format: date-time)
  --updated: string # The modification time of the object metadata in RFC 3339 format. Set initially to object creation time and then updated whenever any metadata of the object changes. This includes changes made by a requester, such as modifying custom metadata, as well as changes made by Cloud Storage on behalf of a requester, such as changing the storage class based on an Object Lifecycle Configuration. (format: date-time)
]: any -> record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record<encryptionAlgorithm: string, keySha256: string>, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record<entity: string, entityId: string>, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "ifGenerationMatch" $if_generation_match "scalar") (serialize-qp "ifGenerationNotMatch" $if_generation_not_match "scalar") (serialize-qp "ifMetagenerationMatch" $if_metageneration_match "scalar") (serialize-qp "ifMetagenerationNotMatch" $if_metageneration_not_match "scalar") (serialize-qp "predefinedAcl" $predefined_acl "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, object: $object} | format pattern "/b/{bucket}/o/{object}") $qp)
  let body = {"acl": $acl, "bucket": $body_bucket, "cacheControl": $cache_control, "componentCount": $component_count, "contentDisposition": $content_disposition, "contentEncoding": $content_encoding, "contentLanguage": $content_language, "contentType": $content_type, "crc32c": $crc32c, "customTime": $custom_time, "customerEncryption": $customer_encryption, "etag": $etag, "eventBasedHold": $event_based_hold, "generation": $generation, "id": $id, "kind": $kind, "kmsKeyName": $kms_key_name, "md5Hash": $md5_hash, "mediaLink": $media_link, "metadata": $metadata, "metageneration": $metageneration, "name": $name, "owner": $owner, "retentionExpirationTime": $retention_expiration_time, "selfLink": $self_link, "size": $size, "storageClass": $storage_class, "temporaryHold": $temporary_hold, "timeCreated": $time_created, "timeDeleted": $time_deleted, "timeStorageClassUpdated": $time_storage_class_updated, "updated": $updated} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates an object's metadata.
#
# PUT /b/{bucket}/o/{object}
# operationId: storage.objects.update
# --acl item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, generation?: string, id?: string, kind?: string, object?: string, projectTeam?: record, role?: string, selfLink?: string}
# --customerEncryption shape: {encryptionAlgorithm?: string, keySha256?: string}
# --owner shape: {entity?: string, entityId?: string}
export def "b-o storageobjectsupdate" [
  bucket: string
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --if-generation-match: string # Makes the operation conditional on whether the object's current generation matches the given value. Setting to 0 makes the operation succeed only if there are no live versions of the object.
  --if-generation-not-match: string # Makes the operation conditional on whether the object's current generation does not match the given value. If no live object exists, the precondition fails. Setting to 0 makes the operation succeed only if there is a live version of the object.
  --if-metageneration-match: string # Makes the operation conditional on whether the object's current metageneration matches the given value.
  --if-metageneration-not-match: string # Makes the operation conditional on whether the object's current metageneration does not match the given value.
  --predefined-acl: string@predefined-acl-completer-1 # Apply a predefined set of access controls to this object.
  --projection: string@projection-completer # Set of properties to return. Defaults to full.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --acl: list # Access controls on the object. — item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, generation?: string, id?: string, kind?: string, object?: string, projectTeam?: record, role?: string, selfLink?: string}
  --body-bucket: string # The name of the bucket containing this object.
  --cache-control: string # Cache-Control directive for the object data. If omitted, and the object is accessible to all anonymous users, the default will be public, max-age=3600.
  --component-count: int # Number of underlying components that make up this object. Components are accumulated by compose operations. (format: int32)
  --content-disposition: string # Content-Disposition of the object data.
  --content-encoding: string # Content-Encoding of the object data.
  --content-language: string # Content-Language of the object data.
  --content-type: string # Content-Type of the object data. If an object is stored without a Content-Type, it is served as application/octet-stream.
  --crc32c: string # CRC32c checksum, as described in RFC 4960, Appendix B; encoded using base64 in big-endian byte order. For more information about using the CRC32c checksum, see Hashes and ETags: Best Practices.
  --custom-time: string # A timestamp in RFC 3339 format specified by the user for an object. (format: date-time)
  --customer-encryption: record # Metadata of customer-supplied encryption key, if the object is encrypted by such a key. — shape: {encryptionAlgorithm?: string, keySha256?: string}
  --etag: string # HTTP 1.1 Entity tag for the object.
  --event-based-hold: oneof<nothing, bool> # Whether an object is under event-based hold. Event-based hold is a way to retain objects until an event occurs, which is signified by the hold's release (i.e. this value is set to false). After being released (set to false), such objects will be subject to bucket-level retention (if any). One sample use case of this flag is for banks to hold loan documents for at least 3 years after loan is paid in full. Here, bucket-level retention is 3 years and the event is the loan being paid in full. In this example, these objects will be held intact for any number of years until the event has occurred (event-based hold on the object is released) and then 3 more years after that. That means retention duration of the objects begins from the moment event-based hold transitioned from true to false.
  --generation: string # The content generation of this object. Used for object versioning. (format: int64)
  --id: string # The ID of the object, including the bucket name, object name, and generation number.
  --kind: string # The kind of item this is. For objects, this is always storage#object. (default: storage#object)
  --kms-key-name: string # Not currently supported. Specifying the parameter causes the request to fail with status code 400 - Bad Request.
  --md5-hash: string # MD5 hash of the data; encoded using base64. For more information about using the MD5 hash, see Hashes and ETags: Best Practices.
  --media-link: string # Media download link.
  --metadata: record # User-provided metadata, in key/value pairs.
  --metageneration: string # The version of the metadata for this object at this generation. Used for preconditions and for detecting changes in metadata. A metageneration number is only meaningful in the context of a particular generation of a particular object. (format: int64)
  --name: string # The name of the object. Required if not specified by URL parameter.
  --owner: record # The owner of the object. This will always be the uploader of the object. — shape: {entity?: string, entityId?: string}
  --retention-expiration-time: string # A server-determined value that specifies the earliest time that the object's retention period expires. This value is in RFC 3339 format. Note 1: This field is not provided for objects with an active event-based hold, since retention expiration is unknown until the hold is removed. Note 2: This value can be provided even when temporary hold is set (so that the user can reason about policy without having to first unset the temporary hold). (format: date-time)
  --self-link: string # The link to this object.
  --size: string # Content-Length of the data in bytes. (format: uint64)
  --storage-class: string # Storage class of the object.
  --temporary-hold: oneof<nothing, bool> # Whether an object is under temporary hold. While this flag is set to true, the object is protected against deletion and overwrites. A common use case of this flag is regulatory investigations where objects need to be retained while the investigation is ongoing. Note that unlike event-based hold, temporary hold does not impact retention expiration time of an object.
  --time-created: string # The creation time of the object in RFC 3339 format. (format: date-time)
  --time-deleted: string # The deletion time of the object in RFC 3339 format. Will be returned if and only if this version of the object has been deleted. (format: date-time)
  --time-storage-class-updated: string # The time at which the object's storage class was last changed. When the object is initially created, it will be set to timeCreated. (format: date-time)
  --updated: string # The modification time of the object metadata in RFC 3339 format. Set initially to object creation time and then updated whenever any metadata of the object changes. This includes changes made by a requester, such as modifying custom metadata, as well as changes made by Cloud Storage on behalf of a requester, such as changing the storage class based on an Object Lifecycle Configuration. (format: date-time)
]: any -> record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record<encryptionAlgorithm: string, keySha256: string>, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record<entity: string, entityId: string>, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "ifGenerationMatch" $if_generation_match "scalar") (serialize-qp "ifGenerationNotMatch" $if_generation_not_match "scalar") (serialize-qp "ifMetagenerationMatch" $if_metageneration_match "scalar") (serialize-qp "ifMetagenerationNotMatch" $if_metageneration_not_match "scalar") (serialize-qp "predefinedAcl" $predefined_acl "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, object: $object} | format pattern "/b/{bucket}/o/{object}") $qp)
  let body = {"acl": $acl, "bucket": $body_bucket, "cacheControl": $cache_control, "componentCount": $component_count, "contentDisposition": $content_disposition, "contentEncoding": $content_encoding, "contentLanguage": $content_language, "contentType": $content_type, "crc32c": $crc32c, "customTime": $custom_time, "customerEncryption": $customer_encryption, "etag": $etag, "eventBasedHold": $event_based_hold, "generation": $generation, "id": $id, "kind": $kind, "kmsKeyName": $kms_key_name, "md5Hash": $md5_hash, "mediaLink": $media_link, "metadata": $metadata, "metageneration": $metageneration, "name": $name, "owner": $owner, "retentionExpirationTime": $retention_expiration_time, "selfLink": $self_link, "size": $size, "storageClass": $storage_class, "temporaryHold": $temporary_hold, "timeCreated": $time_created, "timeDeleted": $time_deleted, "timeStorageClassUpdated": $time_storage_class_updated, "updated": $updated} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves ACL entries on the specified object.
#
# GET /b/{bucket}/o/{object}/acl
# operationId: storage.objectAccessControls.list
export def "b-o-acl storageobjectAccessControlslist" [
  bucket: string
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> record<items: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, object: $object} | format pattern "/b/{bucket}/o/{object}/acl") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new ACL entry on the specified object.
#
# POST /b/{bucket}/o/{object}/acl
# operationId: storage.objectAccessControls.insert
# --projectTeam shape: {projectNumber?: string, team?: string}
export def "b-o-acl storageobjectAccessControlsinsert" [
  bucket: string
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --body-bucket: string # The name of the bucket.
  --domain: string # The domain associated with the entity, if any.
  --email: string # The email address associated with the entity, if any.
  --entity: string # The entity holding the permission, in one of the following forms:  - user-userId  - user-email  - group-groupId  - group-email  - domain-domain  - project-team-projectId  - allUsers  - allAuthenticatedUsers Examples:  - The user liz@example.com would be user-liz@example.com.  - The group example@googlegroups.com would be group-example@googlegroups.com.  - To refer to all members of the Google Apps for Business domain example.com, the entity would be domain-example.com.
  --entity-id: string # The ID for the entity, if any.
  --etag: string # HTTP 1.1 Entity tag for the access-control entry.
  --generation: string # The content generation of the object, if applied to an object. (format: int64)
  --id: string # The ID of the access-control entry.
  --kind: string # The kind of item this is. For object access control entries, this is always storage#objectAccessControl. (default: storage#objectAccessControl)
  --body-object: string # The name of the object, if applied to an object.
  --project-team: record # The project team associated with the entity, if any. — shape: {projectNumber?: string, team?: string}
  --role: string # The access permission for the entity.
  --self-link: string # The link to this access-control entry.
]: any -> record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, object: $object} | format pattern "/b/{bucket}/o/{object}/acl") $qp)
  let body = {"bucket": $body_bucket, "domain": $domain, "email": $email, "entity": $entity, "entityId": $entity_id, "etag": $etag, "generation": $generation, "id": $id, "kind": $kind, "object": $body_object, "projectTeam": $project_team, "role": $role, "selfLink": $self_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Permanently deletes the ACL entry for the specified entity on the specified object.
#
# DELETE /b/{bucket}/o/{object}/acl/{entity}
# operationId: storage.objectAccessControls.delete
export def "b-o-acl storageobjectAccessControlsdelete" [
  bucket: string
  object: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, object: $object, entity: $entity} | format pattern "/b/{bucket}/o/{object}/acl/{entity}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the ACL entry for the specified entity on the specified object.
#
# GET /b/{bucket}/o/{object}/acl/{entity}
# operationId: storage.objectAccessControls.get
export def "b-o-acl storageobjectAccessControlsget" [
  bucket: string
  object: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, object: $object, entity: $entity} | format pattern "/b/{bucket}/o/{object}/acl/{entity}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patches an ACL entry on the specified object.
#
# PATCH /b/{bucket}/o/{object}/acl/{entity}
# operationId: storage.objectAccessControls.patch
# --projectTeam shape: {projectNumber?: string, team?: string}
export def "b-o-acl storageobjectAccessControlspatch" [
  bucket: string
  object: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --body-bucket: string # The name of the bucket.
  --domain: string # The domain associated with the entity, if any.
  --email: string # The email address associated with the entity, if any.
  --body-entity: string # The entity holding the permission, in one of the following forms:  - user-userId  - user-email  - group-groupId  - group-email  - domain-domain  - project-team-projectId  - allUsers  - allAuthenticatedUsers Examples:  - The user liz@example.com would be user-liz@example.com.  - The group example@googlegroups.com would be group-example@googlegroups.com.  - To refer to all members of the Google Apps for Business domain example.com, the entity would be domain-example.com.
  --entity-id: string # The ID for the entity, if any.
  --etag: string # HTTP 1.1 Entity tag for the access-control entry.
  --generation: string # The content generation of the object, if applied to an object. (format: int64)
  --id: string # The ID of the access-control entry.
  --kind: string # The kind of item this is. For object access control entries, this is always storage#objectAccessControl. (default: storage#objectAccessControl)
  --body-object: string # The name of the object, if applied to an object.
  --project-team: record # The project team associated with the entity, if any. — shape: {projectNumber?: string, team?: string}
  --role: string # The access permission for the entity.
  --self-link: string # The link to this access-control entry.
]: any -> record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, object: $object, entity: $entity} | format pattern "/b/{bucket}/o/{object}/acl/{entity}") $qp)
  let body = {"bucket": $body_bucket, "domain": $domain, "email": $email, "entity": $body_entity, "entityId": $entity_id, "etag": $etag, "generation": $generation, "id": $id, "kind": $kind, "object": $body_object, "projectTeam": $project_team, "role": $role, "selfLink": $self_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates an ACL entry on the specified object.
#
# PUT /b/{bucket}/o/{object}/acl/{entity}
# operationId: storage.objectAccessControls.update
# --projectTeam shape: {projectNumber?: string, team?: string}
export def "b-o-acl storageobjectAccessControlsupdate" [
  bucket: string
  object: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --body-bucket: string # The name of the bucket.
  --domain: string # The domain associated with the entity, if any.
  --email: string # The email address associated with the entity, if any.
  --body-entity: string # The entity holding the permission, in one of the following forms:  - user-userId  - user-email  - group-groupId  - group-email  - domain-domain  - project-team-projectId  - allUsers  - allAuthenticatedUsers Examples:  - The user liz@example.com would be user-liz@example.com.  - The group example@googlegroups.com would be group-example@googlegroups.com.  - To refer to all members of the Google Apps for Business domain example.com, the entity would be domain-example.com.
  --entity-id: string # The ID for the entity, if any.
  --etag: string # HTTP 1.1 Entity tag for the access-control entry.
  --generation: string # The content generation of the object, if applied to an object. (format: int64)
  --id: string # The ID of the access-control entry.
  --kind: string # The kind of item this is. For object access control entries, this is always storage#objectAccessControl. (default: storage#objectAccessControl)
  --body-object: string # The name of the object, if applied to an object.
  --project-team: record # The project team associated with the entity, if any. — shape: {projectNumber?: string, team?: string}
  --role: string # The access permission for the entity.
  --self-link: string # The link to this access-control entry.
]: any -> record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, object: $object, entity: $entity} | format pattern "/b/{bucket}/o/{object}/acl/{entity}") $qp)
  let body = {"bucket": $body_bucket, "domain": $domain, "email": $email, "entity": $body_entity, "entityId": $entity_id, "etag": $etag, "generation": $generation, "id": $id, "kind": $kind, "object": $body_object, "projectTeam": $project_team, "role": $role, "selfLink": $self_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns an IAM policy for the specified object.
#
# GET /b/{bucket}/o/{object}/iam
# operationId: storage.objects.getIamPolicy
export def "b-o-iam storageobjectsgetIamPolicy" [
  bucket: string
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> record<bindings: table<condition: record, members: list, role: string>, etag: string, kind: string, resourceId: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, object: $object} | format pattern "/b/{bucket}/o/{object}/iam") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an IAM policy for the specified object.
#
# PUT /b/{bucket}/o/{object}/iam
# operationId: storage.objects.setIamPolicy
# --bindings item shape: {condition?: record, members?: list, role?: string}
export def "b-o-iam storageobjectssetIamPolicy" [
  bucket: string
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --bindings: list # An association between a role, which comes with a set of permissions, and members who may assume that role. — item shape: {condition?: record, members?: list, role?: string}
  --etag: string # HTTP 1.1  Entity tag for the policy. (format: byte)
  --kind: string # The kind of item this is. For policies, this is always storage#policy. This field is ignored on input. (default: storage#policy)
  --resource-id: string # The ID of the resource to which this policy belongs. Will be of the form projects/_/buckets/bucket for buckets, and projects/_/buckets/bucket/objects/object for objects. A specific generation may be specified by appending #generationNumber to the end of the object name, e.g. projects/_/buckets/my-bucket/objects/data.txt#17. The current generation can be denoted with #0. This field is ignored on input.
  --version: int # The IAM policy format version. (format: int32)
]: any -> record<bindings: table<condition: record, members: list, role: string>, etag: string, kind: string, resourceId: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, object: $object} | format pattern "/b/{bucket}/o/{object}/iam") $qp)
  let body = {"bindings": $bindings, "etag": $etag, "kind": $kind, "resourceId": $resource_id, "version": $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Tests a set of permissions on the given object to see which, if any, are held by the caller.
#
# GET /b/{bucket}/o/{object}/iam/testPermissions
# operationId: storage.objects.testIamPermissions
export def "b-o-iam-test-permissions storageobjectstestIamPermissions" [
  bucket: string
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --permissions: list # Permissions to test.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> record<kind: string, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "permissions" $permissions "multi") (serialize-qp "generation" $generation "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket: $bucket, object: $object} | format pattern "/b/{bucket}/o/{object}/iam/testPermissions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Concatenates a list of existing objects into a new object in the same bucket.
#
# POST /b/{destinationBucket}/o/{destinationObject}/compose
# operationId: storage.objects.compose
# --destination shape: {acl?: list, bucket?: string, cacheControl?: string, componentCount?: int, contentDisposition?: string, contentEncoding?: string, contentLanguage?: string, contentType?: string, crc32c?: string, customTime?: string, customerEncryption?: record, etag?: string, eventBasedHold?: bool, generation?: string, id?: string, kind?: string, kmsKeyName?: string, md5Hash?: string, mediaLink?: string, metadata?: record, metageneration?: string, name?: string, owner?: record, retentionExpirationTime?: string, selfLink?: string, size?: string, storageClass?: string, temporaryHold?: bool, timeCreated?: string, timeDeleted?: string, timeStorageClassUpdated?: string, updated?: string}
# --sourceObjects item shape: {generation?: string, name?: string, objectPreconditions?: record}
export def "b-o-compose storageobjectscompose" [
  destination_bucket: string
  destination_object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --destination-predefined-acl: string@destination-predefined-acl-completer # Apply a predefined set of access controls to the destination object.
  --if-generation-match: string # Makes the operation conditional on whether the object's current generation matches the given value. Setting to 0 makes the operation succeed only if there are no live versions of the object.
  --if-metageneration-match: string # Makes the operation conditional on whether the object's current metageneration matches the given value.
  --kms-key-name: string # Resource name of the Cloud KMS key, of the form projects/my-project/locations/global/keyRings/my-kr/cryptoKeys/my-key, that will be used to encrypt the object. Overrides the object metadata's kms_key_name value, if any.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --destination: record # An object. — shape: {acl?: list, bucket?: string, cacheControl?: string, componentCount?: int, contentDisposition?: string, contentEncoding?: string, contentLanguage?: string, contentType?: string, crc32c?: string, customTime?: string, customerEncryption?: record, etag?: string, eventBasedHold?: bool, generation?: string, id?: string, kind?: string, kmsKeyName?: string, md5Hash?: string, mediaLink?: string, metadata?: record, metageneration?: string, name?: string, owner?: record, retentionExpirationTime?: string, selfLink?: string, size?: string, storageClass?: string, temporaryHold?: bool, timeCreated?: string, timeDeleted?: string, timeStorageClassUpdated?: string, updated?: string}
  --kind: string # The kind of item this is. (default: storage#composeRequest)
  --source-objects: list # The list of source objects that will be concatenated into a single object. — item shape: {generation?: string, name?: string, objectPreconditions?: record}
]: any -> record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record<encryptionAlgorithm: string, keySha256: string>, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record<entity: string, entityId: string>, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "destinationPredefinedAcl" $destination_predefined_acl "scalar") (serialize-qp "ifGenerationMatch" $if_generation_match "scalar") (serialize-qp "ifMetagenerationMatch" $if_metageneration_match "scalar") (serialize-qp "kmsKeyName" $kms_key_name "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({destination_bucket: $destination_bucket, destination_object: $destination_object} | format pattern "/b/{destination_bucket}/o/{destination_object}/compose") $qp)
  let body = {"destination": $destination, "kind": $kind, "sourceObjects": $source_objects} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Copies a source object to a destination object. Optionally overrides metadata.
#
# POST /b/{sourceBucket}/o/{sourceObject}/copyTo/b/{destinationBucket}/o/{destinationObject}
# operationId: storage.objects.copy
# --acl item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, generation?: string, id?: string, kind?: string, object?: string, projectTeam?: record, role?: string, selfLink?: string}
# --customerEncryption shape: {encryptionAlgorithm?: string, keySha256?: string}
# --owner shape: {entity?: string, entityId?: string}
export def "b-o-copy-to-b-o storageobjectscopy" [
  source_bucket: string
  source_object: string
  destination_bucket: string
  destination_object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --destination-kms-key-name: string # Resource name of the Cloud KMS key, of the form projects/my-project/locations/global/keyRings/my-kr/cryptoKeys/my-key, that will be used to encrypt the object. Overrides the object metadata's kms_key_name value, if any.
  --destination-predefined-acl: string@destination-predefined-acl-completer # Apply a predefined set of access controls to the destination object.
  --if-generation-match: string # Makes the operation conditional on whether the destination object's current generation matches the given value. Setting to 0 makes the operation succeed only if there are no live versions of the object.
  --if-generation-not-match: string # Makes the operation conditional on whether the destination object's current generation does not match the given value. If no live object exists, the precondition fails. Setting to 0 makes the operation succeed only if there is a live version of the object.
  --if-metageneration-match: string # Makes the operation conditional on whether the destination object's current metageneration matches the given value.
  --if-metageneration-not-match: string # Makes the operation conditional on whether the destination object's current metageneration does not match the given value.
  --if-source-generation-match: string # Makes the operation conditional on whether the source object's current generation matches the given value.
  --if-source-generation-not-match: string # Makes the operation conditional on whether the source object's current generation does not match the given value.
  --if-source-metageneration-match: string # Makes the operation conditional on whether the source object's current metageneration matches the given value.
  --if-source-metageneration-not-match: string # Makes the operation conditional on whether the source object's current metageneration does not match the given value.
  --projection: string@projection-completer # Set of properties to return. Defaults to noAcl, unless the object resource specifies the acl property, when it defaults to full.
  --source-generation: string # If present, selects a specific revision of the source object (as opposed to the latest version, the default).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --acl: list # Access controls on the object. — item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, generation?: string, id?: string, kind?: string, object?: string, projectTeam?: record, role?: string, selfLink?: string}
  --bucket: string # The name of the bucket containing this object.
  --cache-control: string # Cache-Control directive for the object data. If omitted, and the object is accessible to all anonymous users, the default will be public, max-age=3600.
  --component-count: int # Number of underlying components that make up this object. Components are accumulated by compose operations. (format: int32)
  --content-disposition: string # Content-Disposition of the object data.
  --content-encoding: string # Content-Encoding of the object data.
  --content-language: string # Content-Language of the object data.
  --content-type: string # Content-Type of the object data. If an object is stored without a Content-Type, it is served as application/octet-stream.
  --crc32c: string # CRC32c checksum, as described in RFC 4960, Appendix B; encoded using base64 in big-endian byte order. For more information about using the CRC32c checksum, see Hashes and ETags: Best Practices.
  --custom-time: string # A timestamp in RFC 3339 format specified by the user for an object. (format: date-time)
  --customer-encryption: record # Metadata of customer-supplied encryption key, if the object is encrypted by such a key. — shape: {encryptionAlgorithm?: string, keySha256?: string}
  --etag: string # HTTP 1.1 Entity tag for the object.
  --event-based-hold: oneof<nothing, bool> # Whether an object is under event-based hold. Event-based hold is a way to retain objects until an event occurs, which is signified by the hold's release (i.e. this value is set to false). After being released (set to false), such objects will be subject to bucket-level retention (if any). One sample use case of this flag is for banks to hold loan documents for at least 3 years after loan is paid in full. Here, bucket-level retention is 3 years and the event is the loan being paid in full. In this example, these objects will be held intact for any number of years until the event has occurred (event-based hold on the object is released) and then 3 more years after that. That means retention duration of the objects begins from the moment event-based hold transitioned from true to false.
  --generation: string # The content generation of this object. Used for object versioning. (format: int64)
  --id: string # The ID of the object, including the bucket name, object name, and generation number.
  --kind: string # The kind of item this is. For objects, this is always storage#object. (default: storage#object)
  --kms-key-name: string # Not currently supported. Specifying the parameter causes the request to fail with status code 400 - Bad Request.
  --md5-hash: string # MD5 hash of the data; encoded using base64. For more information about using the MD5 hash, see Hashes and ETags: Best Practices.
  --media-link: string # Media download link.
  --metadata: record # User-provided metadata, in key/value pairs.
  --metageneration: string # The version of the metadata for this object at this generation. Used for preconditions and for detecting changes in metadata. A metageneration number is only meaningful in the context of a particular generation of a particular object. (format: int64)
  --name: string # The name of the object. Required if not specified by URL parameter.
  --owner: record # The owner of the object. This will always be the uploader of the object. — shape: {entity?: string, entityId?: string}
  --retention-expiration-time: string # A server-determined value that specifies the earliest time that the object's retention period expires. This value is in RFC 3339 format. Note 1: This field is not provided for objects with an active event-based hold, since retention expiration is unknown until the hold is removed. Note 2: This value can be provided even when temporary hold is set (so that the user can reason about policy without having to first unset the temporary hold). (format: date-time)
  --self-link: string # The link to this object.
  --size: string # Content-Length of the data in bytes. (format: uint64)
  --storage-class: string # Storage class of the object.
  --temporary-hold: oneof<nothing, bool> # Whether an object is under temporary hold. While this flag is set to true, the object is protected against deletion and overwrites. A common use case of this flag is regulatory investigations where objects need to be retained while the investigation is ongoing. Note that unlike event-based hold, temporary hold does not impact retention expiration time of an object.
  --time-created: string # The creation time of the object in RFC 3339 format. (format: date-time)
  --time-deleted: string # The deletion time of the object in RFC 3339 format. Will be returned if and only if this version of the object has been deleted. (format: date-time)
  --time-storage-class-updated: string # The time at which the object's storage class was last changed. When the object is initially created, it will be set to timeCreated. (format: date-time)
  --updated: string # The modification time of the object metadata in RFC 3339 format. Set initially to object creation time and then updated whenever any metadata of the object changes. This includes changes made by a requester, such as modifying custom metadata, as well as changes made by Cloud Storage on behalf of a requester, such as changing the storage class based on an Object Lifecycle Configuration. (format: date-time)
]: any -> record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record<encryptionAlgorithm: string, keySha256: string>, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record<entity: string, entityId: string>, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "destinationKmsKeyName" $destination_kms_key_name "scalar") (serialize-qp "destinationPredefinedAcl" $destination_predefined_acl "scalar") (serialize-qp "ifGenerationMatch" $if_generation_match "scalar") (serialize-qp "ifGenerationNotMatch" $if_generation_not_match "scalar") (serialize-qp "ifMetagenerationMatch" $if_metageneration_match "scalar") (serialize-qp "ifMetagenerationNotMatch" $if_metageneration_not_match "scalar") (serialize-qp "ifSourceGenerationMatch" $if_source_generation_match "scalar") (serialize-qp "ifSourceGenerationNotMatch" $if_source_generation_not_match "scalar") (serialize-qp "ifSourceMetagenerationMatch" $if_source_metageneration_match "scalar") (serialize-qp "ifSourceMetagenerationNotMatch" $if_source_metageneration_not_match "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "sourceGeneration" $source_generation "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({source_bucket: $source_bucket, source_object: $source_object, destination_bucket: $destination_bucket, destination_object: $destination_object} | format pattern "/b/{source_bucket}/o/{source_object}/copyTo/b/{destination_bucket}/o/{destination_object}") $qp)
  let body = {"acl": $acl, "bucket": $bucket, "cacheControl": $cache_control, "componentCount": $component_count, "contentDisposition": $content_disposition, "contentEncoding": $content_encoding, "contentLanguage": $content_language, "contentType": $content_type, "crc32c": $crc32c, "customTime": $custom_time, "customerEncryption": $customer_encryption, "etag": $etag, "eventBasedHold": $event_based_hold, "generation": $generation, "id": $id, "kind": $kind, "kmsKeyName": $kms_key_name, "md5Hash": $md5_hash, "mediaLink": $media_link, "metadata": $metadata, "metageneration": $metageneration, "name": $name, "owner": $owner, "retentionExpirationTime": $retention_expiration_time, "selfLink": $self_link, "size": $size, "storageClass": $storage_class, "temporaryHold": $temporary_hold, "timeCreated": $time_created, "timeDeleted": $time_deleted, "timeStorageClassUpdated": $time_storage_class_updated, "updated": $updated} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Rewrites a source object to a destination object. Optionally overrides metadata.
#
# POST /b/{sourceBucket}/o/{sourceObject}/rewriteTo/b/{destinationBucket}/o/{destinationObject}
# operationId: storage.objects.rewrite
# --acl item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, generation?: string, id?: string, kind?: string, object?: string, projectTeam?: record, role?: string, selfLink?: string}
# --customerEncryption shape: {encryptionAlgorithm?: string, keySha256?: string}
# --owner shape: {entity?: string, entityId?: string}
export def "b-o-rewrite-to-b-o storageobjectsrewrite" [
  source_bucket: string
  source_object: string
  destination_bucket: string
  destination_object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --destination-kms-key-name: string # Resource name of the Cloud KMS key, of the form projects/my-project/locations/global/keyRings/my-kr/cryptoKeys/my-key, that will be used to encrypt the object. Overrides the object metadata's kms_key_name value, if any.
  --destination-predefined-acl: string@destination-predefined-acl-completer # Apply a predefined set of access controls to the destination object.
  --if-generation-match: string # Makes the operation conditional on whether the object's current generation matches the given value. Setting to 0 makes the operation succeed only if there are no live versions of the object.
  --if-generation-not-match: string # Makes the operation conditional on whether the object's current generation does not match the given value. If no live object exists, the precondition fails. Setting to 0 makes the operation succeed only if there is a live version of the object.
  --if-metageneration-match: string # Makes the operation conditional on whether the destination object's current metageneration matches the given value.
  --if-metageneration-not-match: string # Makes the operation conditional on whether the destination object's current metageneration does not match the given value.
  --if-source-generation-match: string # Makes the operation conditional on whether the source object's current generation matches the given value.
  --if-source-generation-not-match: string # Makes the operation conditional on whether the source object's current generation does not match the given value.
  --if-source-metageneration-match: string # Makes the operation conditional on whether the source object's current metageneration matches the given value.
  --if-source-metageneration-not-match: string # Makes the operation conditional on whether the source object's current metageneration does not match the given value.
  --max-bytes-rewritten-per-call: string # The maximum number of bytes that will be rewritten per rewrite request. Most callers shouldn't need to specify this parameter - it is primarily in place to support testing. If specified the value must be an integral multiple of 1 MiB (1048576). Also, this only applies to requests where the source and destination span locations and/or storage classes. Finally, this value must not change across rewrite calls else you'll get an error that the rewriteToken is invalid.
  --projection: string@projection-completer # Set of properties to return. Defaults to noAcl, unless the object resource specifies the acl property, when it defaults to full.
  --rewrite-token: string # Include this field (from the previous rewrite response) on each rewrite request after the first one, until the rewrite response 'done' flag is true. Calls that provide a rewriteToken can omit all other request fields, but if included those fields must match the values provided in the first rewrite request.
  --source-generation: string # If present, selects a specific revision of the source object (as opposed to the latest version, the default).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --acl: list # Access controls on the object. — item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, generation?: string, id?: string, kind?: string, object?: string, projectTeam?: record, role?: string, selfLink?: string}
  --bucket: string # The name of the bucket containing this object.
  --cache-control: string # Cache-Control directive for the object data. If omitted, and the object is accessible to all anonymous users, the default will be public, max-age=3600.
  --component-count: int # Number of underlying components that make up this object. Components are accumulated by compose operations. (format: int32)
  --content-disposition: string # Content-Disposition of the object data.
  --content-encoding: string # Content-Encoding of the object data.
  --content-language: string # Content-Language of the object data.
  --content-type: string # Content-Type of the object data. If an object is stored without a Content-Type, it is served as application/octet-stream.
  --crc32c: string # CRC32c checksum, as described in RFC 4960, Appendix B; encoded using base64 in big-endian byte order. For more information about using the CRC32c checksum, see Hashes and ETags: Best Practices.
  --custom-time: string # A timestamp in RFC 3339 format specified by the user for an object. (format: date-time)
  --customer-encryption: record # Metadata of customer-supplied encryption key, if the object is encrypted by such a key. — shape: {encryptionAlgorithm?: string, keySha256?: string}
  --etag: string # HTTP 1.1 Entity tag for the object.
  --event-based-hold: oneof<nothing, bool> # Whether an object is under event-based hold. Event-based hold is a way to retain objects until an event occurs, which is signified by the hold's release (i.e. this value is set to false). After being released (set to false), such objects will be subject to bucket-level retention (if any). One sample use case of this flag is for banks to hold loan documents for at least 3 years after loan is paid in full. Here, bucket-level retention is 3 years and the event is the loan being paid in full. In this example, these objects will be held intact for any number of years until the event has occurred (event-based hold on the object is released) and then 3 more years after that. That means retention duration of the objects begins from the moment event-based hold transitioned from true to false.
  --generation: string # The content generation of this object. Used for object versioning. (format: int64)
  --id: string # The ID of the object, including the bucket name, object name, and generation number.
  --kind: string # The kind of item this is. For objects, this is always storage#object. (default: storage#object)
  --kms-key-name: string # Not currently supported. Specifying the parameter causes the request to fail with status code 400 - Bad Request.
  --md5-hash: string # MD5 hash of the data; encoded using base64. For more information about using the MD5 hash, see Hashes and ETags: Best Practices.
  --media-link: string # Media download link.
  --metadata: record # User-provided metadata, in key/value pairs.
  --metageneration: string # The version of the metadata for this object at this generation. Used for preconditions and for detecting changes in metadata. A metageneration number is only meaningful in the context of a particular generation of a particular object. (format: int64)
  --name: string # The name of the object. Required if not specified by URL parameter.
  --owner: record # The owner of the object. This will always be the uploader of the object. — shape: {entity?: string, entityId?: string}
  --retention-expiration-time: string # A server-determined value that specifies the earliest time that the object's retention period expires. This value is in RFC 3339 format. Note 1: This field is not provided for objects with an active event-based hold, since retention expiration is unknown until the hold is removed. Note 2: This value can be provided even when temporary hold is set (so that the user can reason about policy without having to first unset the temporary hold). (format: date-time)
  --self-link: string # The link to this object.
  --size: string # Content-Length of the data in bytes. (format: uint64)
  --storage-class: string # Storage class of the object.
  --temporary-hold: oneof<nothing, bool> # Whether an object is under temporary hold. While this flag is set to true, the object is protected against deletion and overwrites. A common use case of this flag is regulatory investigations where objects need to be retained while the investigation is ongoing. Note that unlike event-based hold, temporary hold does not impact retention expiration time of an object.
  --time-created: string # The creation time of the object in RFC 3339 format. (format: date-time)
  --time-deleted: string # The deletion time of the object in RFC 3339 format. Will be returned if and only if this version of the object has been deleted. (format: date-time)
  --time-storage-class-updated: string # The time at which the object's storage class was last changed. When the object is initially created, it will be set to timeCreated. (format: date-time)
  --updated: string # The modification time of the object metadata in RFC 3339 format. Set initially to object creation time and then updated whenever any metadata of the object changes. This includes changes made by a requester, such as modifying custom metadata, as well as changes made by Cloud Storage on behalf of a requester, such as changing the storage class based on an Object Lifecycle Configuration. (format: date-time)
]: any -> record<done: bool, kind: string, objectSize: string, resource: record<acl: list<record>, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record<encryptionAlgorithm: string, keySha256: string>, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record<entity: string, entityId: string>, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string>, rewriteToken: string, totalBytesRewritten: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "destinationKmsKeyName" $destination_kms_key_name "scalar") (serialize-qp "destinationPredefinedAcl" $destination_predefined_acl "scalar") (serialize-qp "ifGenerationMatch" $if_generation_match "scalar") (serialize-qp "ifGenerationNotMatch" $if_generation_not_match "scalar") (serialize-qp "ifMetagenerationMatch" $if_metageneration_match "scalar") (serialize-qp "ifMetagenerationNotMatch" $if_metageneration_not_match "scalar") (serialize-qp "ifSourceGenerationMatch" $if_source_generation_match "scalar") (serialize-qp "ifSourceGenerationNotMatch" $if_source_generation_not_match "scalar") (serialize-qp "ifSourceMetagenerationMatch" $if_source_metageneration_match "scalar") (serialize-qp "ifSourceMetagenerationNotMatch" $if_source_metageneration_not_match "scalar") (serialize-qp "maxBytesRewrittenPerCall" $max_bytes_rewritten_per_call "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "rewriteToken" $rewrite_token "scalar") (serialize-qp "sourceGeneration" $source_generation "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({source_bucket: $source_bucket, source_object: $source_object, destination_bucket: $destination_bucket, destination_object: $destination_object} | format pattern "/b/{source_bucket}/o/{source_object}/rewriteTo/b/{destination_bucket}/o/{destination_object}") $qp)
  let body = {"acl": $acl, "bucket": $bucket, "cacheControl": $cache_control, "componentCount": $component_count, "contentDisposition": $content_disposition, "contentEncoding": $content_encoding, "contentLanguage": $content_language, "contentType": $content_type, "crc32c": $crc32c, "customTime": $custom_time, "customerEncryption": $customer_encryption, "etag": $etag, "eventBasedHold": $event_based_hold, "generation": $generation, "id": $id, "kind": $kind, "kmsKeyName": $kms_key_name, "md5Hash": $md5_hash, "mediaLink": $media_link, "metadata": $metadata, "metageneration": $metageneration, "name": $name, "owner": $owner, "retentionExpirationTime": $retention_expiration_time, "selfLink": $self_link, "size": $size, "storageClass": $storage_class, "temporaryHold": $temporary_hold, "timeCreated": $time_created, "timeDeleted": $time_deleted, "timeStorageClassUpdated": $time_storage_class_updated, "updated": $updated} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Stop watching resources through this channel
#
# POST /channels/stop
# operationId: storage.channels.stop
export def "channels-stop storagechannelsstop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is "api#channel". (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional.
  --type: string # The type of delivery mechanism used for this channel.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels/stop" $qp)
  let body = {"address": $address, "expiration": $expiration, "id": $id, "kind": $kind, "params": $params, "payload": $payload, "resourceId": $resource_id, "resourceUri": $resource_uri, "token": $body_token, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a list of HMAC keys matching the criteria.
#
# GET /projects/{projectId}/hmacKeys
# operationId: storage.projects.hmacKeys.list
export def "projects-hmac-keys storageprojectshmacKeyslist" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # Maximum number of items to return in a single page of responses. The service uses this parameter or 250 items, whichever is smaller. The max number of items per page will also be limited by the number of distinct service accounts in the response. If the number of service accounts in a single response is too high, the page will truncated and a next page token will be returned.
  --page-token: string # A previously-returned page token representing part of the larger set of results to view.
  --service-account-email: string # If present, only keys for the given service account are returned.
  --show-deleted-keys: oneof<nothing, bool> # Whether or not to show keys in the DELETED state.
  --user-project: string # The project to be billed for this request.
]: nothing -> record<items: table<accessId: string, etag: string, id: string, kind: string, projectId: string, selfLink: string, serviceAccountEmail: string, state: string, timeCreated: string, updated: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "serviceAccountEmail" $service_account_email "scalar") (serialize-qp "showDeletedKeys" $show_deleted_keys "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: $project_id} | format pattern "/projects/{project_id}/hmacKeys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new HMAC key for the specified service account.
#
# POST /projects/{projectId}/hmacKeys
# operationId: storage.projects.hmacKeys.create
export def "projects-hmac-keys storageprojectshmacKeyscreate" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --service-account-email: string # Email address of the service account.
  --user-project: string # The project to be billed for this request.
]: nothing -> record<kind: string, metadata: record<accessId: string, etag: string, id: string, kind: string, projectId: string, selfLink: string, serviceAccountEmail: string, state: string, timeCreated: string, updated: string>, secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "serviceAccountEmail" $service_account_email "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: $project_id} | format pattern "/projects/{project_id}/hmacKeys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an HMAC key.
#
# DELETE /projects/{projectId}/hmacKeys/{accessId}
# operationId: storage.projects.hmacKeys.delete
export def "projects-hmac-keys storageprojectshmacKeysdelete" [
  project_id: string
  access_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: $project_id, access_id: $access_id} | format pattern "/projects/{project_id}/hmacKeys/{access_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves an HMAC key's metadata
#
# GET /projects/{projectId}/hmacKeys/{accessId}
# operationId: storage.projects.hmacKeys.get
export def "projects-hmac-keys storageprojectshmacKeysget" [
  project_id: string
  access_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request.
]: nothing -> record<accessId: string, etag: string, id: string, kind: string, projectId: string, selfLink: string, serviceAccountEmail: string, state: string, timeCreated: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: $project_id, access_id: $access_id} | format pattern "/projects/{project_id}/hmacKeys/{access_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the state of an HMAC key. See the HMAC Key resource descriptor for valid states.
#
# PUT /projects/{projectId}/hmacKeys/{accessId}
# operationId: storage.projects.hmacKeys.update
export def "projects-hmac-keys storageprojectshmacKeysupdate" [
  project_id: string
  access_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request.
  --body-access-id: string # The ID of the HMAC Key.
  --etag: string # HTTP 1.1 Entity tag for the HMAC key.
  --id: string # The ID of the HMAC key, including the Project ID and the Access ID.
  --kind: string # The kind of item this is. For HMAC Key metadata, this is always storage#hmacKeyMetadata. (default: storage#hmacKeyMetadata)
  --body-project-id: string # Project ID owning the service account to which the key authenticates.
  --self-link: string # The link to this resource.
  --service-account-email: string # The email address of the key's associated service account.
  --state: string # The state of the key. Can be one of ACTIVE, INACTIVE, or DELETED.
  --time-created: string # The creation time of the HMAC key in RFC 3339 format. (format: date-time)
  --updated: string # The last modification time of the HMAC key metadata in RFC 3339 format. (format: date-time)
]: any -> record<accessId: string, etag: string, id: string, kind: string, projectId: string, selfLink: string, serviceAccountEmail: string, state: string, timeCreated: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: $project_id, access_id: $access_id} | format pattern "/projects/{project_id}/hmacKeys/{access_id}") $qp)
  let body = {"accessId": $body_access_id, "etag": $etag, "id": $id, "kind": $kind, "projectId": $body_project_id, "selfLink": $self_link, "serviceAccountEmail": $service_account_email, "state": $state, "timeCreated": $time_created, "updated": $updated} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the email address of this project's Google Cloud Storage service account.
#
# GET /projects/{projectId}/serviceAccount
# operationId: storage.projects.serviceAccount.get
export def "projects-service-account storageprojectsserviceAccountget" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request.
]: nothing -> record<email_address: string, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "userProject" $user_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: $project_id} | format pattern "/projects/{project_id}/serviceAccount") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
