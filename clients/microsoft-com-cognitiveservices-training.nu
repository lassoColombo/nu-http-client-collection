# Auto-generated client for Custom Vision Training Client v3.2
# Source: https://api.apis.guru/v2/specs/microsoft.com/cognitiveservices-Training/3.2/openapi.json
# Auth: --token flag or $env.CUSTOM_VISION_TRAINING_CLIENT_TOKEN

const BASE_URL = "https://southcentralus.api.cognitive.microsoft.com/customvision/v3.2/training"
const DEFAULT_AUTH = "training-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CUSTOM_VISION_TRAINING_CLIENT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "training-key" => { {headers: {Training-Key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://southcentralus.api.cognitive.microsoft.com/customvision/v3.2/training" "none/customvision/v3.2/training"] }
def auth-scheme-completer [] { ["training-key"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/xml"] }
def classificationType-completer [] { ["Multiclass" "Multilabel"] }
def status-completer [] { ["Failed" "Importing" "Succeeded"] }
def sortBy-completer [] { ["UncertaintyAscending" "UncertaintyDescending"] }
def orderBy-completer [] { ["Newest" "Oldest"] }
def platform-completer [] { ["CoreML" "DockerFile" "ONNX" "TensorFlow" "VAIDK"] }
def flavor-completer [] { ["ARM" "Linux" "ONNX10" "ONNX12" "TensorFlowLite" "TensorFlowNormal" "Windows"] }
def orderBy-completer-1 [] { ["Newest" "Oldest" "Suggested"] }
def type-completer [] { ["Negative" "Regular"] }
def trainingType-completer [] { ["Advanced" "Regular"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "domains GetDomains" } } | get name | first)
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

# Get a list of the available domains.
#
# GET /domains
# operationId: GetDomains
export def "domains GetDomains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<enabled: bool, exportable: bool, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domains")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information about a specific domain.
#
# GET /domains/{domainId}
# operationId: GetDomain
export def "domains GetDomain" [
  domainId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<enabled: bool, exportable: bool, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domains/($domainId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get your projects.
#
# GET /projects
# operationId: GetProjects
export def "projects GetProjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<created: string, description: string, drModeEnabled: bool, id: string, lastModified: string, name: string, settings: record<classificationType: string, detectionParameters: string, domainId: string, imageProcessingSettings: record, targetExportPlatforms: list, useNegativeSet: bool>, status: string, thumbnailUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a project.
#
# POST /projects
# operationId: CreateProject
export def "projects CreateProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # Name of the project.
  --description: string # The description of the project.
  --domainId: string # The id of the domain to use for this project. Defaults to General. (format: uuid)
  --classificationType: string@classificationType-completer # The type of classifier to create for this project.
  --targetExportPlatforms: list # List of platforms the trained model is intending exporting to.
]: nothing -> record<created: string, description: string, drModeEnabled: bool, id: string, lastModified: string, name: string, settings: record<classificationType: string, detectionParameters: string, domainId: string, imageProcessingSettings: record<augmentationMethods: record>, targetExportPlatforms: list<string>, useNegativeSet: bool>, status: string, thumbnailUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "domainId" $domainId "scalar") (serialize-qp "classificationType" $classificationType "scalar") (serialize-qp "targetExportPlatforms" $targetExportPlatforms "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Imports a project.
#
# POST /projects/import
# operationId: ImportProject
export def "projects-import ImportProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-token: string # Token generated from the export project call.
]: nothing -> record<created: string, description: string, drModeEnabled: bool, id: string, lastModified: string, name: string, settings: record<classificationType: string, detectionParameters: string, domainId: string, imageProcessingSettings: record<augmentationMethods: record>, targetExportPlatforms: list<string>, useNegativeSet: bool>, status: string, thumbnailUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects/import" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a specific project.
#
# DELETE /projects/{projectId}
# operationId: DeleteProject
export def "projects DeleteProject" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific project.
#
# GET /projects/{projectId}
# operationId: GetProject
export def "projects GetProject" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<created: string, description: string, drModeEnabled: bool, id: string, lastModified: string, name: string, settings: record<classificationType: string, detectionParameters: string, domainId: string, imageProcessingSettings: record<augmentationMethods: record>, targetExportPlatforms: list<string>, useNegativeSet: bool>, status: string, thumbnailUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a specific project.
#
# PATCH /projects/{projectId}
# operationId: UpdateProject
# --settings shape: {classificationType?: "Multiclass"|"Multilabel", domainId?: string, imageProcessingSettings?: record, targetExportPlatforms?: list}
export def "projects UpdateProject" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Gets or sets the description of the project. (nullable)
  name: string # Gets or sets the name of the project.
  settings: record # Represents settings associated with a project. — shape: {classificationType?: "Multiclass"|"Multilabel", domainId?: string, imageProcessingSettings?: record, targetExportPlatforms?: list}
  --status: string@status-completer # Gets the status of the project.
]: any -> record<created: string, description: string, drModeEnabled: bool, id: string, lastModified: string, name: string, settings: record<classificationType: string, detectionParameters: string, domainId: string, imageProcessingSettings: record<augmentationMethods: record>, targetExportPlatforms: list<string>, useNegativeSet: bool>, status: string, thumbnailUri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)")
  let body = {description: $description, name: $name, settings: $settings, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Exports a project.
#
# GET /projects/{projectId}/export
# operationId: ExportProject
export def "projects-export ExportProject" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<estimatedImportTimeInMS: int, imageCount: int, iterationCount: int, regionCount: int, tagCount: int, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/export")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete images from the set of training images.
#
# DELETE /projects/{projectId}/images
# operationId: DeleteImages
export def "projects-images DeleteImages" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --imageIds: list # Ids of the images to be deleted. Limited to 256 images per batch.
  --allImages: oneof<nothing, bool> # Flag to specify delete all images, specify this flag or a list of images. Using this flag will return a 202 response to indicate the images are being deleted.
  --allIterations: oneof<nothing, bool> # Removes these images from all iterations, not just the current workspace. Using this flag will return a 202 response to indicate the images are being deleted.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "imageIds" $imageIds "csv") (serialize-qp "allImages" $allImages "scalar") (serialize-qp "allIterations" $allIterations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/images" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add the provided images to the set of training images.
#
# POST /projects/{projectId}/images
# operationId: CreateImagesFromData
export def "projects-images CreateImagesFromData" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --tagIds: list # The tags ids with which to tag each image. Limited to 20.
  imageData: string # Binary image data. Supported formats are JPEG, GIF, PNG, and BMP. Supports images up to 6MB. (format: binary)
]: any -> record<images: table<image: record, sourceUrl: string, status: string>, isBatchSuccessful: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tagIds" $tagIds "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/images" $qp)
  let body = {imageData: $imageData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Add the provided batch of images to the set of training images.
#
# POST /projects/{projectId}/images/files
# operationId: CreateImagesFromFiles
# --images item shape: {contents?: string, name?: string, regions?: list, tagIds?: list}
export def "projects-images-files CreateImagesFromFiles" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --images: list # item shape: {contents?: string, name?: string, regions?: list, tagIds?: list}
  --tagIds: list
]: any -> record<images: table<image: record, sourceUrl: string, status: string>, isBatchSuccessful: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/images/files")
  let body = {images: $images, tagIds: $tagIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get images by id for a given project iteration.
#
# GET /projects/{projectId}/images/id
# operationId: GetImagesByIds
export def "projects-images-id GetImagesByIds" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --imageIds: list # The list of image ids to retrieve. Limited to 256.
  --iterationId: string # The iteration id. Defaults to workspace. (format: uuid)
]: nothing -> table<created: string, height: int, id: string, originalImageUri: string, regions: list<record>, resizedImageUri: string, tags: list<record>, thumbnailUri: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "imageIds" $imageIds "csv") (serialize-qp "iterationId" $iterationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/images/id" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add the specified predicted images to the set of training images.
#
# POST /projects/{projectId}/images/predictions
# operationId: CreateImagesFromPredictions
# --images item shape: {id?: string, regions?: list, tagIds?: list}
export def "projects-images-predictions CreateImagesFromPredictions" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --images: list # item shape: {id?: string, regions?: list, tagIds?: list}
  --tagIds: list
]: any -> record<images: table<image: record, sourceUrl: string, status: string>, isBatchSuccessful: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/images/predictions")
  let body = {images: $images, tagIds: $tagIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a set of image regions.
#
# DELETE /projects/{projectId}/images/regions
# operationId: DeleteImageRegions
export def "projects-images-regions DeleteImageRegions" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --regionIds: list # Regions to delete. Limited to 64.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "regionIds" $regionIds "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/images/regions" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a set of image regions.
#
# POST /projects/{projectId}/images/regions
# operationId: CreateImageRegions
# --regions item shape: {height: float, imageId: string, left: float, tagId: string, top: float, width: float}
export def "projects-images-regions CreateImageRegions" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --regions: list # item shape: {height: float, imageId: string, left: float, tagId: string, top: float, width: float}
]: any -> record<created: table<created: string, height: float, imageId: string, left: float, regionId: string, tagId: string, tagName: string, top: float, width: float>, duplicated: table<height: float, imageId: string, left: float, tagId: string, top: float, width: float>, exceeded: table<height: float, imageId: string, left: float, tagId: string, top: float, width: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/images/regions")
  let body = {regions: $regions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get untagged images whose suggested tags match given tags. Returns empty array if no images are found.
#
# POST /projects/{projectId}/images/suggested
# operationId: QuerySuggestedImages
export def "projects-images-suggested QuerySuggestedImages" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --iterationId: string # IterationId to use for the suggested tags and regions. (format: uuid)
  --continuation: string # Continuation Id for database pagination. Initially null but later used to paginate.
  --maxCount: int # Maximum number of results you want to be returned in the response. (format: int32)
  --session: string # SessionId for database query. Initially set to null but later used to paginate.
  --sortBy: string@sortBy-completer # OrderBy. Ordering mechanism for your results.
  --tagIds: list # Existing TagIds in project to filter suggested tags on.
  --threshold: float # Confidence threshold to filter suggested tags on. (format: double)
]: any -> record<results: table<created: string, domain: string, height: int, id: string, iteration: string, originalImageUri: string, predictionUncertainty: float, predictions: list, project: string, resizedImageUri: string, thumbnailUri: string, width: int>, token: record<continuation: string, maxCount: int, session: string, sortBy: string, tagIds: list<string>, threshold: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iterationId" $iterationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/images/suggested" $qp)
  let body = {continuation: $continuation, maxCount: $maxCount, session: $session, sortBy: $sortBy, tagIds: $tagIds, threshold: $threshold} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get count of images whose suggested tags match given tags and their probabilities are greater than or equal to the given threshold. Returns count as 0 if none found.
#
# POST /projects/{projectId}/images/suggested/count
# operationId: QuerySuggestedImageCount
export def "projects-images-suggested-count QuerySuggestedImageCount" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --iterationId: string # IterationId to use for the suggested tags and regions. (format: uuid)
  --tagIds: list # Existing TagIds in project to get suggested tags count for.
  --threshold: float # Confidence threshold to filter suggested tags on. (format: double)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iterationId" $iterationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/images/suggested/count" $qp)
  let body = {tagIds: $tagIds, threshold: $threshold} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get tagged images for a given project iteration.
#
# GET /projects/{projectId}/images/tagged
# operationId: GetTaggedImages
export def "projects-images-tagged GetTaggedImages" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --iterationId: string # The iteration id. Defaults to workspace. (format: uuid)
  --tagIds: list # A list of tags ids to filter the images. Defaults to all tagged images when null. Limited to 20.
  --orderBy: string@orderBy-completer # The ordering. Defaults to newest.
  --take: int # Maximum number of images to return. Defaults to 50, limited to 256. (format: int32, default: 50)
  --skip: int # Number of images to skip before beginning the image batch. Defaults to 0. (format: int32, default: 0)
]: nothing -> table<created: string, height: int, id: string, originalImageUri: string, regions: list<record>, resizedImageUri: string, tags: list<record>, thumbnailUri: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iterationId" $iterationId "scalar") (serialize-qp "tagIds" $tagIds "csv") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/images/tagged" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the number of images tagged with the provided {tagIds}.
#
# GET /projects/{projectId}/images/tagged/count
# operationId: GetTaggedImageCount
export def "projects-images-tagged-count GetTaggedImageCount" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --iterationId: string # The iteration id. Defaults to workspace. (format: uuid)
  --tagIds: list # A list of tags ids to filter the images to count. Defaults to all tags when null.
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iterationId" $iterationId "scalar") (serialize-qp "tagIds" $tagIds "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/images/tagged/count" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a set of tags from a set of images.
#
# DELETE /projects/{projectId}/images/tags
# operationId: DeleteImageTags
export def "projects-images-tags DeleteImageTags" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --imageIds: list # Image ids. Limited to 64 images.
  --tagIds: list # Tags to be deleted from the specified images. Limited to 20 tags.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "imageIds" $imageIds "csv") (serialize-qp "tagIds" $tagIds "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/images/tags" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Associate a set of images with a set of tags.
#
# POST /projects/{projectId}/images/tags
# operationId: CreateImageTags
# --tags item shape: {imageId?: string, tagId?: string}
export def "projects-images-tags CreateImageTags" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --tags: list # Image Tag entries to include in this batch. — item shape: {imageId?: string, tagId?: string}
]: any -> record<created: table<imageId: string, tagId: string>, duplicated: table<imageId: string, tagId: string>, exceeded: table<imageId: string, tagId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/images/tags")
  let body = {tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get untagged images for a given project iteration.
#
# GET /projects/{projectId}/images/untagged
# operationId: GetUntaggedImages
export def "projects-images-untagged GetUntaggedImages" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --iterationId: string # The iteration id. Defaults to workspace. (format: uuid)
  --orderBy: string@orderBy-completer # The ordering. Defaults to newest.
  --take: int # Maximum number of images to return. Defaults to 50, limited to 256. (format: int32, default: 50)
  --skip: int # Number of images to skip before beginning the image batch. Defaults to 0. (format: int32, default: 0)
]: nothing -> table<created: string, height: int, id: string, originalImageUri: string, regions: list<record>, resizedImageUri: string, tags: list<record>, thumbnailUri: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iterationId" $iterationId "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/images/untagged" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the number of untagged images.
#
# GET /projects/{projectId}/images/untagged/count
# operationId: GetUntaggedImageCount
export def "projects-images-untagged-count GetUntaggedImageCount" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --iterationId: string # The iteration id. Defaults to workspace. (format: uuid)
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iterationId" $iterationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/images/untagged/count" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add the provided images urls to the set of training images.
#
# POST /projects/{projectId}/images/urls
# operationId: CreateImagesFromUrls
# --images item shape: {regions?: list, tagIds?: list, url: string}
export def "projects-images-urls CreateImagesFromUrls" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --images: list # item shape: {regions?: list, tagIds?: list, url: string}
  --tagIds: list
]: any -> record<images: table<image: record, sourceUrl: string, status: string>, isBatchSuccessful: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/images/urls")
  let body = {images: $images, tagIds: $tagIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get region proposals for an image. Returns empty array if no proposals are found.
#
# POST /projects/{projectId}/images/{imageId}/regionproposals
# operationId: GetImageRegionProposals
export def "projects-images-regionproposals GetImageRegionProposals" [
  projectId: string
  imageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<imageId: string, projectId: string, proposals: table<boundingBox: record, confidence: float>> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/images/($imageId)/regionproposals")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get iterations for the project.
#
# GET /projects/{projectId}/iterations
# operationId: GetIterations
export def "projects-iterations GetIterations" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<classificationType: string, created: string, domainId: string, exportable: bool, exportableTo: list<string>, id: string, lastModified: string, name: string, originalPublishResourceId: string, projectId: string, publishName: string, reservedBudgetInHours: int, status: string, trainedAt: string, trainingTimeInMinutes: int, trainingType: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/iterations")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a specific iteration of a project.
#
# DELETE /projects/{projectId}/iterations/{iterationId}
# operationId: DeleteIteration
export def "projects-iterations DeleteIteration" [
  projectId: string
  iterationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/iterations/($iterationId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific iteration.
#
# GET /projects/{projectId}/iterations/{iterationId}
# operationId: GetIteration
export def "projects-iterations GetIteration" [
  projectId: string
  iterationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<classificationType: string, created: string, domainId: string, exportable: bool, exportableTo: list<string>, id: string, lastModified: string, name: string, originalPublishResourceId: string, projectId: string, publishName: string, reservedBudgetInHours: int, status: string, trainedAt: string, trainingTimeInMinutes: int, trainingType: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/iterations/($iterationId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a specific iteration.
#
# PATCH /projects/{projectId}/iterations/{iterationId}
# operationId: UpdateIteration
export def "projects-iterations UpdateIteration" [
  projectId: string
  iterationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string # Gets or sets the name of the iteration.
]: any -> record<classificationType: string, created: string, domainId: string, exportable: bool, exportableTo: list<string>, id: string, lastModified: string, name: string, originalPublishResourceId: string, projectId: string, publishName: string, reservedBudgetInHours: int, status: string, trainedAt: string, trainingTimeInMinutes: int, trainingType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/iterations/($iterationId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the list of exports for a specific iteration.
#
# GET /projects/{projectId}/iterations/{iterationId}/export
# operationId: GetExports
export def "projects-iterations-export GetExports" [
  projectId: string
  iterationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<downloadUri: string, flavor: string, newerVersionAvailable: bool, platform: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/iterations/($iterationId)/export")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export a trained iteration.
#
# POST /projects/{projectId}/iterations/{iterationId}/export
# operationId: ExportIteration
export def "projects-iterations-export ExportIteration" [
  projectId: string
  iterationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --platform: string@platform-completer # The target platform.
  --flavor: string@flavor-completer # The flavor of the target platform.
]: nothing -> record<downloadUri: string, flavor: string, newerVersionAvailable: bool, platform: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar") (serialize-qp "flavor" $flavor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/iterations/($iterationId)/export" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get detailed performance information about an iteration.
#
# GET /projects/{projectId}/iterations/{iterationId}/performance
# operationId: GetIterationPerformance
export def "projects-iterations-performance GetIterationPerformance" [
  projectId: string
  iterationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --threshold: float # The threshold used to determine true predictions. (format: float)
  --overlapThreshold: float # If applicable, the bounding box overlap threshold used to determine true predictions. (format: float)
]: nothing -> record<averagePrecision: float, perTagPerformance: table<averagePrecision: float, id: string, name: string, precision: float, precisionStdDeviation: float, recall: float, recallStdDeviation: float>, precision: float, precisionStdDeviation: float, recall: float, recallStdDeviation: float> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "threshold" $threshold "scalar") (serialize-qp "overlapThreshold" $overlapThreshold "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/iterations/($iterationId)/performance" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get image with its prediction for a given project iteration.
#
# GET /projects/{projectId}/iterations/{iterationId}/performance/images
# operationId: GetImagePerformances
export def "projects-iterations-performance-images GetImagePerformances" [
  projectId: string
  iterationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --tagIds: list # A list of tags ids to filter the images. Defaults to all tagged images when null. Limited to 20.
  --orderBy: string@orderBy-completer # The ordering. Defaults to newest.
  --take: int # Maximum number of images to return. Defaults to 50, limited to 256. (format: int32, default: 50)
  --skip: int # Number of images to skip before beginning the image batch. Defaults to 0. (format: int32, default: 0)
]: nothing -> table<created: string, height: int, id: string, imageUri: string, predictions: list<record>, regions: list<record>, tags: list<record>, thumbnailUri: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tagIds" $tagIds "csv") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/iterations/($iterationId)/performance/images" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the number of images tagged with the provided {tagIds} that have prediction results from training for the provided iteration {iterationId}.
#
# GET /projects/{projectId}/iterations/{iterationId}/performance/images/count
# operationId: GetImagePerformanceCount
export def "projects-iterations-performance-images-count GetImagePerformanceCount" [
  projectId: string
  iterationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --tagIds: list # A list of tags ids to filter the images to count. Defaults to all tags when null.
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tagIds" $tagIds "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/iterations/($iterationId)/performance/images/count" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unpublish a specific iteration.
#
# DELETE /projects/{projectId}/iterations/{iterationId}/publish
# operationId: UnpublishIteration
export def "projects-iterations-publish UnpublishIteration" [
  projectId: string
  iterationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/iterations/($iterationId)/publish")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Publish a specific iteration.
#
# POST /projects/{projectId}/iterations/{iterationId}/publish
# operationId: PublishIteration
export def "projects-iterations-publish PublishIteration" [
  projectId: string
  iterationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --publishName: string # The name to give the published iteration.
  --predictionId: string # The id of the prediction resource to publish to.
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "publishName" $publishName "scalar") (serialize-qp "predictionId" $predictionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/iterations/($iterationId)/publish" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a set of predicted images and their associated prediction results.
#
# DELETE /projects/{projectId}/predictions
# operationId: DeletePrediction
export def "projects-predictions DeletePrediction" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list # The prediction ids. Limited to 64.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/predictions" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get images that were sent to your prediction endpoint.
#
# POST /projects/{projectId}/predictions/query
# operationId: QueryPredictions
# --tags item shape: {id?: string, maxThreshold?: float, minThreshold?: float}
export def "projects-predictions-query QueryPredictions" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --application: string
  --continuation: string
  --endTime: string # nullable, format: date-time
  --iterationId: string # nullable, format: uuid
  --maxCount: int # format: int32
  --orderBy: string@orderBy-completer-1
  --session: string
  --startTime: string # nullable, format: date-time
  --tags: list # item shape: {id?: string, maxThreshold?: float, minThreshold?: float}
]: any -> record<results: table<created: string, domain: string, id: string, iteration: string, originalImageUri: string, predictions: list, project: string, resizedImageUri: string, thumbnailUri: string>, token: record<application: string, continuation: string, endTime: string, iterationId: string, maxCount: int, orderBy: string, session: string, startTime: string, tags: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/predictions/query")
  let body = {application: $application, continuation: $continuation, endTime: $endTime, iterationId: $iterationId, maxCount: $maxCount, orderBy: $orderBy, session: $session, startTime: $startTime, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Quick test an image.
#
# POST /projects/{projectId}/quicktest/image
# operationId: QuickTestImage
export def "projects-quicktest-image QuickTestImage" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --iterationId: string # Optional. Specifies the id of a particular iteration to evaluate against.             The default iteration for the project will be used when not specified. (format: uuid)
  --store: oneof<nothing, bool> # Optional. Specifies whether or not to store the result of this prediction. The default is true, to store. (default: true)
  imageData: string # Binary image data. Supported formats are JPEG, GIF, PNG, and BMP. Supports images up to 6MB. (format: binary)
]: any -> record<created: string, id: string, iteration: string, predictions: table<boundingBox: record, probability: float, tagId: string, tagName: string>, project: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iterationId" $iterationId "scalar") (serialize-qp "store" $store "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/quicktest/image" $qp)
  let body = {imageData: $imageData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Quick test an image url.
#
# POST /projects/{projectId}/quicktest/url
# operationId: QuickTestImageUrl
export def "projects-quicktest-url QuickTestImageUrl" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --iterationId: string # Optional. Specifies the id of a particular iteration to evaluate against.             The default iteration for the project will be used when not specified. (format: uuid)
  --store: oneof<nothing, bool> # Optional. Specifies whether or not to store the result of this prediction. The default is true, to store. (default: true)
  --body-url: string # Url of the image.
]: any -> record<created: string, id: string, iteration: string, predictions: table<boundingBox: record, probability: float, tagId: string, tagName: string>, project: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iterationId" $iterationId "scalar") (serialize-qp "store" $store "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/quicktest/url" $qp)
  let body = {url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the tags for a given project and iteration.
#
# GET /projects/{projectId}/tags
# operationId: GetTags
export def "projects-tags GetTags" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --iterationId: string # The iteration id. Defaults to workspace. (format: uuid)
]: nothing -> table<description: string, id: string, imageCount: int, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iterationId" $iterationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/tags" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a tag for the project.
#
# POST /projects/{projectId}/tags
# operationId: CreateTag
export def "projects-tags CreateTag" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # The tag name.
  --description: string # Optional description for the tag.
  --type: string@type-completer # Optional type for the tag.
]: nothing -> record<description: string, id: string, imageCount: int, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/tags" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a tag from the project.
#
# DELETE /projects/{projectId}/tags/{tagId}
# operationId: DeleteTag
export def "projects-tags DeleteTag" [
  projectId: string
  tagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/tags/($tagId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information about a specific tag.
#
# GET /projects/{projectId}/tags/{tagId}
# operationId: GetTag
export def "projects-tags GetTag" [
  projectId: string
  tagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --iterationId: string # The iteration to retrieve this tag from. Optional, defaults to current training set. (format: uuid)
]: nothing -> record<description: string, id: string, imageCount: int, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iterationId" $iterationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/tags/($tagId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a tag.
#
# PATCH /projects/{projectId}/tags/{tagId}
# operationId: UpdateTag
export def "projects-tags UpdateTag" [
  projectId: string
  tagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Gets or sets the description of the tag. (nullable)
  name: string # Gets or sets the name of the tag.
  type: string@type-completer # Gets or sets the type of the tag.
]: any -> record<description: string, id: string, imageCount: int, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/tags/($tagId)")
  let body = {description: $description, name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Suggest tags and regions for an array/batch of untagged images. Returns empty array if no tags are found.
#
# POST /projects/{projectId}/tagsandregions/suggestions
# operationId: SuggestTagsAndRegions
export def "projects-tagsandregions-suggestions SuggestTagsAndRegions" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --iterationId: string # IterationId to use for tag and region suggestion. (format: uuid)
  --imageIds: list # Array of image ids tag suggestion are needed for. Use GetUntaggedImages API to get imageIds.
]: nothing -> table<created: string, id: string, iteration: string, predictionUncertainty: float, predictions: list<record>, project: string> {
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iterationId" $iterationId "scalar") (serialize-qp "imageIds" $imageIds "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/tagsandregions/suggestions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Queues project for training.
#
# POST /projects/{projectId}/train
# operationId: TrainProject
export def "projects-train TrainProject" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --trainingType: string@trainingType-completer # The type of training to use to train the project (default: Regular).
  --reservedBudgetInHours: int # The number of hours reserved as budget for training (if applicable). (format: int32, default: 0)
  --forceTrain: oneof<nothing, bool> # Whether to force train even if dataset and configuration does not change (default: false). (default: false)
  --notificationEmailAddress: string # The email address to send notification to when training finishes (default: null).
  --selectedTags: list # List of tags selected for this training session, other tags in the project will be ignored.
]: any -> record<classificationType: string, created: string, domainId: string, exportable: bool, exportableTo: list<string>, id: string, lastModified: string, name: string, originalPublishResourceId: string, projectId: string, publishName: string, reservedBudgetInHours: int, status: string, trainedAt: string, trainingTimeInMinutes: int, trainingType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "training-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "trainingType" $trainingType "scalar") (serialize-qp "reservedBudgetInHours" $reservedBudgetInHours "scalar") (serialize-qp "forceTrain" $forceTrain "scalar") (serialize-qp "notificationEmailAddress" $notificationEmailAddress "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/train" $qp)
  let body = {selectedTags: $selectedTags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
