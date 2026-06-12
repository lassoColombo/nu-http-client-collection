# Auto-generated client for VisageCloud v1.1
# Source: https://api.apis.guru/v2/specs/visagecloud.com/1.1/swagger.json
# Auth: --token flag or $env.VISAGECLOUD_TOKEN

const BASE_URL = "https://visagecloud.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VISAGECLOUD_TOKEN | default "" }
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

def base-url-completer [] { ["https://visagecloud.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def algorithmVersion-completer [] { ["V1" "V2"] }
def attributeFilters-completer [] { ["AGE_GROUP_FILTER" "GENDER_FILTER" "NO_FILTER"] }
def purposes-completer [] { ["ATTRIBUTES" "FEATURES" "LANDMARKS"] }
def method-completer [] { ["INGESTION_ENDPOINT" "WEBRTC_PULL" "WEBRTC_PUSH"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "rest-v11-account-account get" } } | get name | first)
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

# Get account information by accessKey and secretKey
#
# GET /rest/v1.1/account/account
# operationId: getAccountByAccessKeyUsingGET
export def "rest-v11-account-account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # accessKey
  --secretKey: string # secretKey
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/account/account" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get billing information by accessKey and secretKey
#
# GET /rest/v1.1/account/billing
# operationId: getBillingPerAccountUsingGET
export def "rest-v11-account-billing get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # accessKey
  --secretKey: string # secretKey
  --startDateTime: string # startDateTime (format: date-time)
  --endDateTime: string # endDateTime (format: date-time)
  --dateTemplate: string # dateTemplate
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "dateTemplate" $dateTemplate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/account/billing" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change password for an account using old password
#
# POST /rest/v1.1/account/changePassword
# operationId: changePasswordUsingPOST
export def "rest-v11-account-change-password changePasswordUsingPOST" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # email
  --oldPassword: string # oldPassword
  --newPassword: string # newPassword
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "oldPassword" $oldPassword "scalar") (serialize-qp "newPassword" $newPassword "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/account/changePassword" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get account information including accessKey and secretKey by email and password
#
# POST /rest/v1.1/account/login
# operationId: loginWithEmailUsingPOST
export def "rest-v11-account-login loginWithEmailUsingPOST" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # email
  --password: string # password
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "password" $password "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/account/login" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Compare several faces identified by faceHash, without depending on mapping faces to profiles
#
# GET /rest/v1.1/analysis/compare
# operationId: compareFacesUsingGET
export def "rest-v11-analysis-compare compareFacesUsingGET" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --faceHashes: list # The IDs of the faces which you want compared, comma-separated
  --showDetails: oneof<nothing, bool> # Show details (default: false)
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "faceHashes" $faceHashes "multi") (serialize-qp "showDetails" $showDetails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/analysis/compare" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Perform detection on a given picture or picture URL
#
# POST /rest/v1.1/analysis/detection
# operationId: performAnalysisUsingPOST
export def "rest-v11-analysis-detection performAnalysisUsingPOST" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --storeAnalysisPicture: oneof<nothing, bool> # Boolean value indicating whether you want the picture of the analysis to be stored for later retrieval (default: true)
  --storeFacePictures: oneof<nothing, bool> # Boolean value indicating whether you want the faces inside the picture to be stored for later retrieval (default: true)
  --storeResult: oneof<nothing, bool> # Boolean value indicating whether you want the result of the analysis to be stored (default: true)
  --retentionTime: int # How many seconds the results should be retained in stoarage? (format: int32)
  --pictureURL: string # The URL of the picture, assuming it is served by a third party server. Server should be accesible from the Internet or through another netwoek by VisageCloud infrastructure
  --algorithmVersion: string@algorithmVersion-completer # Algorithm version (V2 is more performant but not backward compatible) (default: V2)
  --autoRotate: oneof<nothing, bool> # Auto-rotate to find flipped or rotate faces (default: false)
  --skipEXIF: oneof<nothing, bool> # Skip EXIF rotation procesing (default: false)
  --waitForPictureUpload: oneof<nothing, bool> # Waits until the picture is successfully uploaded, before returning the response back the the client (default: false)
  --filters: list # [For advanced users only] Change feature filters for robustness of feature extraction. Tweaking this parameter may affect per
  --options: string # [For advanced users only] Options for preprocessing of image.
  --picture: string # The multipart/form-data version of the image, in case a direct upload is used. At least one of picture or pictureURL must be present
]: any -> record<message: string, payload: record, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "storeAnalysisPicture" $storeAnalysisPicture "scalar") (serialize-qp "storeFacePictures" $storeFacePictures "scalar") (serialize-qp "storeResult" $storeResult "scalar") (serialize-qp "retentionTime" $retentionTime "scalar") (serialize-qp "pictureURL" $pictureURL "scalar") (serialize-qp "algorithmVersion" $algorithmVersion "scalar") (serialize-qp "autoRotate" $autoRotate "scalar") (serialize-qp "skipEXIF" $skipEXIF "scalar") (serialize-qp "waitForPictureUpload" $waitForPictureUpload "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "options" $options "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/analysis/detection" $qp)
  let body = {picture: $picture} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve the last *count* operations per current account
#
# GET /rest/v1.1/analysis/listLatest
# operationId: retriveLatestUsingGET
export def "rest-v11-analysis-list-latest retriveLatestUsingGET" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --count: int # How many records to retrieve at a time (format: int32, default: 100)
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/analysis/listLatest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Perform labeled recognition on a given picture or picture URL
#
# POST /rest/v1.1/analysis/recognition
# operationId: performRecognitionUsingPOST
export def "rest-v11-analysis-recognition performRecognitionUsingPOST" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --storeAnalysisPicture: oneof<nothing, bool> # Boolean value indicating whether you want the picture of the analysis to be stored for later retrieval (default: true)
  --storeFacePictures: oneof<nothing, bool> # Boolean value indicating whether you want the faces inside the picture to be stored for later retrieval (default: true)
  --storeResult: oneof<nothing, bool> # Boolean value indicating whether you want the result of the analysis to be stored (default: true)
  --retentionTime: int # How many seconds the results should be retained in stoarage? (format: int32)
  --collectionId: string # Uniquely identified collection that can store multiple profiles
  --labels: list # Labels associated with the given picture or picture URL
  --attributeFilters: list@attributeFilters-completer # Filters that will be applied on the recognition operation
  --pictureURL: string # The URL of the picture
  --algorithmVersion: string@algorithmVersion-completer # Algorithm version (V2 is more performant but not backward compatible) (default: V2)
  --autoRotate: oneof<nothing, bool> # Auto-rotate to find flipped or rotate faces (default: false)
  --skipEXIF rotation processing: oneof<nothing, bool> # Skip EXIF rotation procesing (default: false)
  --waitForPictureUpload: oneof<nothing, bool> # Waits until the picture is successfully uploaded, before returning the response back the the client (default: false)
  --filters: list # [For advanced users only] Change feature filters for robustness of feature extraction. Tweaking this parameter may affect per
  --options: string # [For advanced users only] Options for preprocessing of image.
  --picture: string # The picture itself
]: any -> record<message: string, payload: record, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "storeAnalysisPicture" $storeAnalysisPicture "scalar") (serialize-qp "storeFacePictures" $storeFacePictures "scalar") (serialize-qp "storeResult" $storeResult "scalar") (serialize-qp "retentionTime" $retentionTime "scalar") (serialize-qp "collectionId" $collectionId "scalar") (serialize-qp "labels" $labels "multi") (serialize-qp "attributeFilters" $attributeFilters "multi") (serialize-qp "pictureURL" $pictureURL "scalar") (serialize-qp "algorithmVersion" $algorithmVersion "scalar") (serialize-qp "autoRotate" $autoRotate "scalar") (serialize-qp "skipEXIF rotation processing" $skipEXIF rotation processing "scalar") (serialize-qp "waitForPictureUpload" $waitForPictureUpload "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "options" $options "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/analysis/recognition" $qp)
  let body = {picture: $picture} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a complete analysis object including both detection and recognition information
#
# GET /rest/v1.1/analysis/retrieve
# operationId: retrieveAnalysisUsingGET
export def "rest-v11-analysis-retrieve retrieveAnalysisUsingGET" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --analysisId: string # The ID of the analysis for which the data will be retrieved
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "analysisId" $analysisId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/analysis/retrieve" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count individuals in streams or collections
#
# POST /rest/v1.1/analytics/counting
# operationId: counterUsingPOST
export def "rest-v11-analytics-counting counterUsingPOST" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --collectionIds: list # Collection ids
  --streamIds: list # Stream Ids
  --startDateTime: string # startDateTime (format: date-time)
  --endDateTime: string # endDateTime (format: date-time)
  --visitDuration: int # visitDuration (format: int64, default: 3600000)
  --maxIterations: int # maxIterations (format: int32, default: 1)
  --maxBatchIterations: int # maxBatchIterations (format: int32, default: 1)
  --minNeighborsMergedPerIteration: int # minNeighborsMergedPerIteration (format: int32, default: 5)
  --mergingStep: float # mergingStep (format: double, default: 1)
  --shuffling: oneof<nothing, bool> # shuffling (default: false)
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "collectionIds" $collectionIds "multi") (serialize-qp "streamIds" $streamIds "multi") (serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "visitDuration" $visitDuration "scalar") (serialize-qp "maxIterations" $maxIterations "scalar") (serialize-qp "maxBatchIterations" $maxBatchIterations "scalar") (serialize-qp "minNeighborsMergedPerIteration" $minNeighborsMergedPerIteration "scalar") (serialize-qp "mergingStep" $mergingStep "scalar") (serialize-qp "shuffling" $shuffling "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/analytics/counting" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show audience (based on number of occurrences of each person) breakdown per declared attribute (age, gender).
#
# POST /rest/v1.1/analytics/presence/timeseries
# operationId: presenceTimeseriesUsingPOST
export def "rest-v11-analytics-presence-timeseries presenceTimeseriesUsingPOST" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --streamIds: list # Stream Ids
  --startDateTime: string # startDateTime (format: date-time)
  --endDateTime: string # endDateTime (format: date-time)
  --step: int # step (format: int64, default: 3600)
  --attributes: list # attributes
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "streamIds" $streamIds "multi") (serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "step" $step "scalar") (serialize-qp "attributes" $attributes "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/analytics/presence/timeseries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show presence (based on number of occurences of each face) breakdown per declared attribute (age, gender)
#
# POST /rest/v1.1/analytics/presence/total
# operationId: presenceTotalUsingPOST
export def "rest-v11-analytics-presence-total presenceTotalUsingPOST" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --streamIds: list # Stream Ids
  --startDateTime: string # startDateTime (format: date-time)
  --endDateTime: string # endDateTime (format: date-time)
  --attributes: list # attributes
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "streamIds" $streamIds "multi") (serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "attributes" $attributes "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/analytics/presence/total" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete existing classifier
#
# DELETE /rest/v1.1/classifier/svm
# operationId: removeClassiferUsingDELETE
export def "rest-v11-classifier-svm removeClassiferUsingDELETE" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --id: string # The id of the classifier that will be removed
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/classifier/svm" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get classifier full
#
# GET /rest/v1.1/classifier/svm
# operationId: getClassiferFullUsingGET
export def "rest-v11-classifier-svm get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --id: string # The id of the classifier that you want the status for
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/classifier/svm" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new SVM classifier with given name
#
# POST /rest/v1.1/classifier/svm
# operationId: addSVMClassifierUsingPOST
export def "rest-v11-classifier-svm addSVMClassifierUsingPOST" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --name: string # The name of the SVM classifier that will be created
  --collectionIds: list # Collection ids
  --preprocessor: string # Preprocessor (default: FeaturePreprocessor)
  --classificationAttributeName: string # Classification attribute name
  --considerViewPoints: oneof<nothing, bool> # Consider view point (default: false)
  --seed: int # Seed for divididing training and evaluation sets (format: int32, default: 179425537)
  --trainingRatio: float # Training ratio (format: double, default: 0.8)
  --probabilityParameter: int # Probability parameter (format: int32, default: 1)
  --gammaParameter: float # Gamma parameter (format: double, default: 0.5)
  --nuParameter: float # Nu parameter (format: double, default: 0.25)
  --cParameter: float # c parameter (format: double, default: 1)
  --svmTypeParameter: int # SVM type parameter (format: int32, default: 0)
  --kernelTypeParameter: int # Kernel type parameter (format: int32, default: 0)
  --cacheSizeParameter: float # Cache size parameter (format: double, default: 500)
  --epsParameter: float # Eps parameter (format: double, default: 0.001)
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "collectionIds" $collectionIds "multi") (serialize-qp "preprocessor" $preprocessor "scalar") (serialize-qp "classificationAttributeName" $classificationAttributeName "scalar") (serialize-qp "considerViewPoints" $considerViewPoints "scalar") (serialize-qp "seed" $seed "scalar") (serialize-qp "trainingRatio" $trainingRatio "scalar") (serialize-qp "probabilityParameter" $probabilityParameter "scalar") (serialize-qp "gammaParameter" $gammaParameter "scalar") (serialize-qp "nuParameter" $nuParameter "scalar") (serialize-qp "cParameter" $cParameter "scalar") (serialize-qp "svmTypeParameter" $svmTypeParameter "scalar") (serialize-qp "kernelTypeParameter" $kernelTypeParameter "scalar") (serialize-qp "cacheSizeParameter" $cacheSizeParameter "scalar") (serialize-qp "epsParameter" $epsParameter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/classifier/svm" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get classifer status
#
# GET /rest/v1.1/classifier/svm/status
# operationId: getClassiferStatusUsingGET
export def "rest-v11-classifier-svm-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --id: string # The id of the classifier that you want the status for
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/classifier/svm/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all collections
#
# GET /rest/v1.1/collection/
# operationId: getAllCollectionsUsingGET
export def "rest-v11-collection list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/collection/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new empty collection with given name
#
# POST /rest/v1.1/collection/
# operationId: addCollectionUsingPOST
export def "rest-v11-collection addCollectionUsingPOST" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accessKey: string # The accessKey provided by VisageCloud
  secretKey: string # The secretKey provided by VisageCloud
  name: string # The name of the collection that will be created
  --preload: oneof<nothing, bool> # Defined whether to preload collection
  --evictable: oneof<nothing, bool> # Defined whether the collection can be evicted
  --purposes: list@purposes-completer # The newly declared purposes of the collection
]: any -> record<message: string, payload: record, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/v1.1/collection/")
  let body = {accessKey: $accessKey, secretKey: $secretKey, name: $name, preload: $preload, evictable: $evictable, purposes: $purposes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve all collections
#
# GET /rest/v1.1/collection/all
# DEPRECATED
# operationId: getAllCollections2UsingGET
@deprecated
export def "rest-v11-collection-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/collection/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete existing collection with associated profiles and faces.
#
# DELETE /rest/v1.1/collection/collection
# DEPRECATED
# operationId: deleteCollection2UsingDELETE
@deprecated
export def "rest-v11-collection-collection delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey provided by VisageCloud
  --collectionId: string # The id of the collection that will be removed
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "collectionId" $collectionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/collection/collection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve existing collection content
#
# GET /rest/v1.1/collection/collection
# DEPRECATED
# operationId: getCollection2UsingGET
@deprecated
export def "rest-v11-collection-collection get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --collectionId: string # The id of the collection for which the data will be retrieved
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "collectionId" $collectionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/collection/collection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new empty collection with given name
#
# POST /rest/v1.1/collection/collection
# DEPRECATED
# operationId: addCollection2UsingPOST
@deprecated
export def "rest-v11-collection-collection addCollection2UsingPOST" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --collectionName: string # The name of the collection that will be created
  --preload: oneof<nothing, bool> # Defined whether to preload collection (default: false)
  --evictable: oneof<nothing, bool> # Defined whether the collection can be evicted (default: true)
  --purposes: list@purposes-completer # The newly declared purposes of the collection
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "collectionName" $collectionName "scalar") (serialize-qp "preload" $preload "scalar") (serialize-qp "evictable" $evictable "scalar") (serialize-qp "purposes" $purposes "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/collection/collection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve collection content for data analysis.
#
# GET /rest/v1.1/collection/export/csv
# operationId: exportCSVUsingGET
export def "rest-v11-collection-export-csv exportCSVUsingGET" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --collectionId: string # The id of the collection for which the data will be retrieved
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "collectionId" $collectionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/collection/export/csv" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change purpose of existing collection
#
# PUT /rest/v1.1/collection/purpose
# DEPRECATED
# operationId: repurposeCollectionUsingPUT
@deprecated
export def "rest-v11-collection-purpose repurposeCollectionUsingPUT" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey provided by VisageCloud
  --collectionId: string # The id of the collection for which the data will be retrieved
  --purposes: list@purposes-completer # The newly declared purposes of the collection
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "collectionId" $collectionId "scalar") (serialize-qp "purposes" $purposes "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/collection/purpose" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete existing collection with associated profiles and faces.
#
# DELETE /rest/v1.1/collection/{id}
# operationId: deleteCollectionUsingDELETE
export def "rest-v11-collection delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey provided by VisageCloud
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/v1.1/collection/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve existing collection content
#
# GET /rest/v1.1/collection/{id}
# operationId: getCollectionUsingGET
export def "rest-v11-collection get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/v1.1/collection/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing collection with a given id
#
# PATCH /rest/v1.1/collection/{id}
# operationId: updateCollectionUsingPATCH
export def "rest-v11-collection updateCollectionUsingPATCH" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey provided by VisageCloud
  --name: string # The name of the collection that will be updated
  --purposes: list@purposes-completer # The newly declared purposes of the collection
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "purposes" $purposes "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/v1.1/collection/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing collection with a given id
#
# POST /rest/v1.1/collection/{id}
# DEPRECATED
# operationId: updateCollection2UsingPOST
@deprecated
export def "rest-v11-collection updateCollection2UsingPOST" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey provided by VisageCloud
  --name: string # The name of the collection that will be updated
  --purposes: list@purposes-completer # The newly declared purposes of the collection
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "purposes" $purposes "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/v1.1/collection/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all the profiles associated to a collection
#
# GET /rest/v1.1/collection/{id}/profile
# operationId: getAllCollectionProfilesUsingGET
export def "rest-v11-collection-profile get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/v1.1/collection/($id)/profile" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes classification attributes from a profile
#
# DELETE /rest/v1.1/profile/classificationAttributes
# DEPRECATED
# operationId: removeClassificationAttributesFromProfileUsingDELETE
@deprecated
export def "rest-v11-profile-classification-attributes removeClassificationAttributesFromProfileUsingDELETE" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey provided by VisageCloud
  --profileId: string # The profile associated with the classification attributes
  --collectionId: string # The collection that contains the profile
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "profileId" $profileId "scalar") (serialize-qp "collectionId" $collectionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/profile/classificationAttributes" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets classification attributes from a profile
#
# GET /rest/v1.1/profile/classificationAttributes
# DEPRECATED
# operationId: getClassificationAttributesFromProfileUsingGET
@deprecated
export def "rest-v11-profile-classification-attributes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --profileId: string # The profile associated with the classification attributes
  --collectionId: string # The collection that contains the profile
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "profileId" $profileId "scalar") (serialize-qp "collectionId" $collectionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/profile/classificationAttributes" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Maps classification attributes to a profile
#
# PUT /rest/v1.1/profile/classificationAttributes
# DEPRECATED
# operationId: mapClassificationAttributesToProfileUsingPUT
@deprecated
export def "rest-v11-profile-classification-attributes mapClassificationAttributesToProfileUsingPUT" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey provided by VisageCloud
  --profileId: string # The profile associated with the classification attributes
  --collectionId: string # The collection that contains the profile
  --classificationAttributes: string # Comma separated key:value classification attributes
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "profileId" $profileId "scalar") (serialize-qp "collectionId" $collectionId "scalar") (serialize-qp "classificationAttributes" $classificationAttributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/profile/classificationAttributes" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the enrollment status of a profile: information on whether it is suitable for authentication.
#
# GET /rest/v1.1/profile/enrollmentStatus
# operationId: getProfileEnrollmentStatusUsingGET
export def "rest-v11-profile-enrollment-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --profileId: string # The profile that contains the faces
  --collectionId: string # The collection that contains the profile
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "profileId" $profileId "scalar") (serialize-qp "collectionId" $collectionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/profile/enrollmentStatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes (unmaps) a list of faces, identified by faceHashes, from a profile, identified by profileId
#
# DELETE /rest/v1.1/profile/map
# operationId: removeFacesFromProfileUsingDELETE
export def "rest-v11-profile-map removeFacesFromProfileUsingDELETE" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey provided by VisageCloud
  --faceHashes: string # Comma separated face hashes, that will be removed from a profile
  --profileId: string # The profile that contains the face
  --collectionId: string # The collection that contains the profile
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "faceHashes" $faceHashes "scalar") (serialize-qp "profileId" $profileId "scalar") (serialize-qp "collectionId" $collectionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/profile/map" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all the faceHashes associated to a profile
#
# GET /rest/v1.1/profile/map
# operationId: getFacesFromProfileUsingGET
export def "rest-v11-profile-map get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --profileId: string # The profile that contains the faces
  --collectionId: string # The collection that contains the profile
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "profileId" $profileId "scalar") (serialize-qp "collectionId" $collectionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/profile/map" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds (maps) a list of faces, identified by faceHashes, to a profile, identified by profileId
#
# POST /rest/v1.1/profile/map
# operationId: mapFacesToProfileUsingPOST
export def "rest-v11-profile-map mapFacesToProfileUsingPOST" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey provided by VisageCloud
  --faceHashes: string # Comma separated face hashes, that will be associated to a profile
  --profileId: string # The profile that will store the face
  --collectionId: string # The collection that contains the profile
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "faceHashes" $faceHashes "scalar") (serialize-qp "profileId" $profileId "scalar") (serialize-qp "collectionId" $collectionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/profile/map" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a profile and unmaps all its faces
#
# DELETE /rest/v1.1/profile/profile
# DEPRECATED
# operationId: deleteProfile2UsingDELETE
@deprecated
export def "rest-v11-profile-profile delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey provided by VisageCloud
  --collectionId: string # Uniquely identified collection that can store multiple profiles
  --profileId: string # The profile id (provide this if you don't have the externalId
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "collectionId" $collectionId "scalar") (serialize-qp "profileId" $profileId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/profile/profile" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new profile with no faces associated to it (empty profile)
#
# POST /rest/v1.1/profile/profile
# operationId: addProfileUsingPOST
export def "rest-v11-profile-profile addProfileUsingPOST" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey provided by VisageCloud
  --collectionId: string # Uniquely identified collection that can store multiple profiles
  --externalId: string # External reference to additional information you don’t want to share with VisageCloud
  --screenName: string # Human-readable label for the profile
  --labels: list # Allows you to do finer filtering in face recognition
  --classificationAttributes: string # Comma separated key:value classification attributes
  --details: string # Comma separated key:value details of profile
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "collectionId" $collectionId "scalar") (serialize-qp "externalId" $externalId "scalar") (serialize-qp "screenName" $screenName "scalar") (serialize-qp "labels" $labels "multi") (serialize-qp "classificationAttributes" $classificationAttributes "scalar") (serialize-qp "details" $details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/profile/profile" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a profile and unmaps all its faces
#
# DELETE /rest/v1.1/profile/{id}
# operationId: deleteProfileUsingDELETE
export def "rest-v11-profile delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey provided by VisageCloud
  --collectionId: string # Uniquely identified collection that can store multiple profiles
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "collectionId" $collectionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/v1.1/profile/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a profile
#
# GET /rest/v1.1/profile/{id}
# operationId: getProfileUsingGET
export def "rest-v11-profile get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --collectionId: string # Uniquely identified collection that can store multiple profiles
  --withFaces: string # Retrieves the profile with all its associated faces (default: false)
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "collectionId" $collectionId "scalar") (serialize-qp "withFaces" $withFaces "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/v1.1/profile/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing profile with a given id
#
# PATCH /rest/v1.1/profile/{id}
# operationId: updateProfileUsingPATCH
export def "rest-v11-profile updateProfileUsingPATCH" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --collectionId: string # Uniquely identified collection that can store multiple profiles
  --externalId: string # External reference to additional information you don’t want to share with VisageCloud
  --screenName: string # Human-readable label for the profile
  --labels: list # Allows you to do finer filtering in face recognition
  --classificationAttributes: string # Comma separated key:value classification attributes
  --details: string # Comma separated key:value details of profile
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "collectionId" $collectionId "scalar") (serialize-qp "externalId" $externalId "scalar") (serialize-qp "screenName" $screenName "scalar") (serialize-qp "labels" $labels "multi") (serialize-qp "classificationAttributes" $classificationAttributes "scalar") (serialize-qp "details" $details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/v1.1/profile/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show status of all streams from account
#
# GET /rest/v1.1/stream/all
# operationId: streamsByAccountUsingGET
export def "rest-v11-stream-all streamsByAccountUsingGET" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/stream/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get last N recognized individuals from stream
#
# GET /rest/v1.1/stream/attendance
# operationId: getLastNAttedanceUsingGET
export def "rest-v11-stream-attendance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --streamIds: list # The id of the stream for which the frames will be retrieved
  --count: int # How many frames to retrieve at a time (format: int32, default: 10)
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "streamIds" $streamIds "multi") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/stream/attendance" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cleanup frames older than specified timeframe
#
# PATCH /rest/v1.1/stream/cleanup
# operationId: cleanupStreamUsingPATCH
export def "rest-v11-stream-cleanup cleanupStreamUsingPATCH" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey provided by VisageCloud
  --streamId: string # The id of the stream that will be stopped
  --interval: int # Frames older than interval (seconds) will be cleaned up (format: int32)
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "streamId" $streamId "scalar") (serialize-qp "interval" $interval "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/stream/cleanup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get individual frame image
#
# GET /rest/v1.1/stream/frameImage
# operationId: getFrameImageUsingGET
export def "rest-v11-stream-frame-image get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --streamId: string # The id of the stream for which the frames will be retrieved
  --timestamp: int # Timestamp of frame to retrieve (format: int64)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "streamId" $streamId "scalar") (serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/stream/frameImage" $qp)
  let accept_val = "image/jpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get last processed N frames from stream
#
# GET /rest/v1.1/stream/frames
# operationId: getLastNFramesUsingGET
export def "rest-v11-stream-frames get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey or readOnlyKey provided by VisageCloud
  --streamId: string # The id of the stream for which the frames will be retrieved
  --count: int # How many frames to retrieve at a time (format: int32, default: 10)
  --collectionId: string # The collection id you want to run recognition against
  --labels: list # Labels associated with the given picture or picture URL
  --attributeFilters: list@attributeFilters-completer # Filters that will be applied on the recognition operation
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "streamId" $streamId "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "collectionId" $collectionId "scalar") (serialize-qp "labels" $labels "multi") (serialize-qp "attributeFilters" $attributeFilters "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/stream/frames" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start existing stream
#
# PATCH /rest/v1.1/stream/start
# operationId: startStreamUsingPATCH
export def "rest-v11-stream-start startStreamUsingPATCH" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey provided by VisageCloud
  --streamId: string # The id of the stream that will be started
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "streamId" $streamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/stream/start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stop existing stream
#
# PATCH /rest/v1.1/stream/stop
# operationId: stopStreamUsingPATCH
export def "rest-v11-stream-stop stopStreamUsingPATCH" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey provided by VisageCloud
  --streamId: string # The id of the stream that will be stopped
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "streamId" $streamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/stream/stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new stream with given name
#
# POST /rest/v1.1/stream/stream
# operationId: addStreamUsingPOST
export def "rest-v11-stream-stream addStreamUsingPOST" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey provided by VisageCloud
  --name: string # The name of the stream that will be created
  --qp-url: string # The url of the stream
  --method: string@method-completer # Streaming method (default: WEBRTC_PUSH)
  --username: string # Username
  --password: string # Password
  --skipFramesWithNoFaces: oneof<nothing, bool> # Boolean value indicating whether you want the original picture to be stored for later retrieval (default: true)
  --retentionTime: int # Number of seconds for frames to be kept. Default is 605000s (7 days) (format: int32, default: 605000)
  --storeOriginalFrames: oneof<nothing, bool> # Boolean value indicating whether you want the original picture to be stored for later retrieval (default: false)
  --storeAttendanceFaces: oneof<nothing, bool> # Boolean value indicating whether you want to store permanently store faces clippings of the recognized faces (default: false)
  --storeAttendanceFrames: oneof<nothing, bool> # Boolean value indicating whether you want to store permanently store frames with a recognized face in them (default: false)
  --isActive: oneof<nothing, bool> # Boolean value indicating whether the stream is currently active or not (default: false)
  --associatedCollections: list # List of collection ids which will be used to measure attendance
  --attributes: string # Attributes of the stream
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "url" $qp_url "scalar") (serialize-qp "method" $method "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "skipFramesWithNoFaces" $skipFramesWithNoFaces "scalar") (serialize-qp "retentionTime" $retentionTime "scalar") (serialize-qp "storeOriginalFrames" $storeOriginalFrames "scalar") (serialize-qp "storeAttendanceFaces" $storeAttendanceFaces "scalar") (serialize-qp "storeAttendanceFrames" $storeAttendanceFrames "scalar") (serialize-qp "isActive" $isActive "scalar") (serialize-qp "associatedCollections" $associatedCollections "multi") (serialize-qp "attributes" $attributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/stream/stream" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete existing stream
#
# DELETE /rest/v1.1/stream/{id}
# operationId: removeStreamUsingDELETE
export def "rest-v11-stream removeStreamUsingDELETE" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey provided by VisageCloud
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/v1.1/stream/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an existing stream with a given ID
#
# GET /rest/v1.1/stream/{streamId}
# operationId: getStreamUsingGET
export def "rest-v11-stream get" [
  streamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey provided by VisageCloud
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/v1.1/stream/($streamId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing stream with a given ID
#
# PATCH /rest/v1.1/stream/{streamId}
# operationId: updateStreamUsingPATCH
export def "rest-v11-stream updateStreamUsingPATCH" [
  streamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessKey: string # The accessKey provided by VisageCloud
  --secretKey: string # The secretKey provided by VisageCloud
  --name: string # The name of the stream that will be updated
  --qp-url: string # The url of the stream
  --method: string@method-completer # Streaming method
  --username: string # Username
  --password: string # Password
  --skipFramesWithNoFaces: oneof<nothing, bool> # Boolean value indicating whether you want the original picture to be stored for later retrieval
  --retentionTime: int # Number of seconds for frames to be kept (format: int32)
  --storeOriginalFrames: oneof<nothing, bool> # Boolean value indicating whether you want the original picture to be stored for later retrieval
  --storeAttendanceFaces: oneof<nothing, bool> # Boolean value indicating whether you want to store permanently store faces clippings of the recognized faces
  --storeAttendanceFrames: oneof<nothing, bool> # Boolean value indicating whether you want to store permanently store frames with a recognized face in them
  --isActive: oneof<nothing, bool> # Boolean value indicating whether the stream is currently active or not
  --associatedCollections: list # List of collection ids which will be used to measure attendance
  --attributes: string # Attributes of the stream
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $accessKey "scalar") (serialize-qp "secretKey" $secretKey "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "url" $qp_url "scalar") (serialize-qp "method" $method "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "skipFramesWithNoFaces" $skipFramesWithNoFaces "scalar") (serialize-qp "retentionTime" $retentionTime "scalar") (serialize-qp "storeOriginalFrames" $storeOriginalFrames "scalar") (serialize-qp "storeAttendanceFaces" $storeAttendanceFaces "scalar") (serialize-qp "storeAttendanceFrames" $storeAttendanceFrames "scalar") (serialize-qp "isActive" $isActive "scalar") (serialize-qp "associatedCollections" $associatedCollections "multi") (serialize-qp "attributes" $attributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/v1.1/stream/($streamId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
