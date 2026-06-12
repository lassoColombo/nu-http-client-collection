# Auto-generated client for Einstein Vision and Einstein Language v2.0.1
# Source: https://api.apis.guru/v2/specs/salesforce.local/einstein/2.0.1/openapi.json
# Auth: --token flag or $env.EINSTEIN_VISION_AND_EINSTEIN_LANGUAGE_TOKEN

const BASE_URL = "http://salesforce.local"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o EINSTEIN_VISION_AND_EINSTEIN_LANGUAGE_TOKEN | default "" }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def base-url-completer [] { ["http://salesforce.local"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["text-intent" "text-sentiment"] }
def source-completer [] { ["all" "feedback" "upload"] }
def grant-type-completer [] { ["refresh_token" "urn:ietf:params:oauth:grant-type:jwt-bearer"] }
def type-completer-1 [] { ["image" "image-multi-label"] }
def type-completer-2 [] { ["image" "image-detection" "image-multi-label"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "apiusage get" } } | get name | first)
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

# Get API Isage
#
# GET /v2/apiusage
# operationId: getApiUsagePlansV2
export def "apiusage get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<endsAt: string, id: string, licenseId: string, object: string, organizationId: string, planData: list, predictionsMax: int, predictionsUsed: int, startsAt: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/apiusage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Datasets
#
# GET /v2/language/datasets
# operationId: listDatasets
export def "language-datasets listDatasets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: string # Index of the dataset from which you want to start paging (default: 0)
  --count: string # Number of datsets to return. Maximum valid value is 25. If you specify a number greater than 25, the call returns 25 datasets. (default: 25)
  --global: oneof<nothing, bool> # If true, returns all global datasets. Global datasets are public datasets that Salesforce provides. (default: false)
]: nothing -> record<data: table<available: bool, createdAt: string, id: int, labelSummary: record, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "global" $global "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/language/datasets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Dataset From a File Asynchronously
#
# POST /v2/language/datasets/upload
# operationId: uploadDatasetAsync
export def "language-datasets-upload uploadDatasetAsync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: string # Path to the .csv, .tsv, or .json file on the local drive (FilePart).
  --name: string # Name of the dataset. Optional. If this parameter is omitted, the dataset name is derived from the file name. (e.g. weather)
  --path: string # URL of the .csv, .tsv, or .json file.
  --type: string@type-completer # Type of dataset data.
]: any -> record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/language/datasets/upload")
  let body = {data: $data, name: $name, path: $path, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Create a Dataset From a File Synchronously
#
# POST /v2/language/datasets/upload/sync
# operationId: uploadDatasetSync
export def "language-datasets-upload-sync uploadDatasetSync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: string # Path to the .csv, .tsv, or .json file on the local drive (FilePart).
  --name: string # Name of the dataset. Optional. If this parameter is omitted, the dataset name is derived from the file name. (e.g. weather)
  --path: string # URL of the .csv, .tsv, or .json file.
  --type: string@type-completer # Type of dataset data.
]: any -> record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/language/datasets/upload/sync")
  let body = {data: $data, name: $name, path: $path, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete a Dataset
#
# DELETE /v2/language/datasets/{datasetId}
# operationId: deleteDataset
export def "language-datasets delete" [
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/language/datasets/($datasetId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Dataset
#
# GET /v2/language/datasets/{datasetId}
# operationId: getDataset
export def "language-datasets get" [
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/language/datasets/($datasetId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Examples
#
# GET /v2/language/datasets/{datasetId}/examples
# operationId: getExamples
export def "language-datasets-examples get" [
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: string # Index of the example from which you want to start paging. (default: 0)
  --count: string # Number of examples to return. (default: 100)
  --qp-source: string@source-completer # return examples that were created in the dataset as feedback
]: nothing -> record<data: table<createdAt: string, id: int, label: record, location: string, name: string, object: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/language/datasets/($datasetId)/examples" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Models
#
# GET /v2/language/datasets/{datasetId}/models
# operationId: getTrainedModels
export def "language-datasets-models get" [
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: string # Index of the model from which you want to start paging. (default: 0)
  --count: string # Number of models to return. (default: 100)
]: nothing -> record<data: table<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, failureMsg: string, language: string, modelId: string, modelType: string, name: string, object: string, progress: float, status: string, updatedAt: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/language/datasets/($datasetId)/models" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Examples From a File
#
# PUT /v2/language/datasets/{datasetId}/upload
# operationId: updateDatasetAsync
export def "language-datasets-upload updateDatasetAsync" [
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: string # Path to the .csv, .tsv, or .json file on a local drive. 
  --type: string # URL of the .csv, .tsv, or .json file.
]: any -> record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/language/datasets/($datasetId)/upload")
  let body = {data: $data, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get Deletion Status
#
# GET /v2/language/deletion/{id}
# operationId: get
export def "language-deletion get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/language/deletion/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Examples for Label
#
# GET /v2/language/examples
# operationId: getExamplesByLabel
export def "language-examples get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --labelId: string # Label Id (e.g. SomeLabelId)
  --offset: string # Index of the example from which you want to start paging. (default: 0)
  --count: string # Number of examples to return. (default: 100)
]: nothing -> record<data: table<createdAt: string, id: int, label: record, location: string, name: string, object: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "labelId" $labelId "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/language/examples" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Feedback Example
#
# POST /v2/language/feedback
# operationId: provideFeedback
export def "language-feedback provideFeedback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --document: string # Intent or sentiment string to add to the dataset.
  --expectedLabel: string # Correct label for the example. Must be a label that exists in the dataset.
  --modelId: string # ID of the model that misclassified the image. The feedback example is added to the dataset associated with this model.
  --name: string # Name of the example. Optional. Maximum length is 180 characters. (e.g. feedback-2)
]: any -> record<createdAt: string, id: int, label: record<datasetId: int, id: int, name: string, numExamples: int>, location: string, name: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/language/feedback")
  let body = {document: $document, expectedLabel: $expectedLabel, modelId: $modelId, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Prediction for Intent
#
# POST /v2/language/intent
# operationId: intentMultipart
export def "language-intent intentMultipart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  document: string # Text for which you want to return an intent prediction. (e.g. I can't tell you how much fun it was)
  modelId: string # ID of the model that makes the prediction. The model must have been created from a dataset with a type of text-sentiment. (e.g. WJH4YCA7YX4PCWVNCYNWYHBMY4)
  --numResults: int # Number of probabilities to return.  (format: int32, e.g. 3)
  --sampleId: string # String that you can pass in to tag the prediction. Optional. Can be any value, and is returned in the response.
]: any -> record<object: string, probabilities: table<label: string, probability: float>, sampleId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/language/intent")
  let body = {document: $document, modelId: $modelId, numResults: $numResults, sampleId: $sampleId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Model
#
# DELETE /v2/language/models/{modelId}
# operationId: deleteModel
export def "language-models delete" [
  modelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/language/models/($modelId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Model Metrics
#
# GET /v2/language/models/{modelId}
# operationId: getTrainedModelMetrics
export def "language-models get" [
  modelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<algorithm: string, createdAt: string, id: string, language: string, metricsData: record, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/language/models/($modelId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Model Learning Curve
#
# GET /v2/language/models/{modelId}/lc
# operationId: getTrainedModelLearningCurve
export def "language-models-lc get" [
  modelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: string # Index of the epoch from which you want to start paging (default: 0)
  --count: string # Number of epoch to return. Maximum valid value is 25. (default: 25)
]: nothing -> record<data: table<epoch: record, epochResults: record, metricsData: record, object: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/language/models/($modelId)/lc" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrain a Dataset
#
# POST /v2/language/retrain
# operationId: retrain
# --trainParams shape: {trainSplitRatio?: float, withFeedback?: bool, withGlobalDatasetId?: int}
export def "language-retrain retrain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --algorithm: string # Algorithm used for train (e.g. intent)
  --epochs: int # Number of training iterations for the neural network. Optional. (format: int32, e.g. 20)
  --learningRate: float # N/A for intent or sentiment models. (format: float, e.g. 0.0001)
  --modelId: string # ID of the model to be updated from the training. (e.g. 7JXCXTRXTMNLJCEF2DR5CJ46QU)
  --trainParams: record # JSON that contains parameters that specify how the model is created — shape: {trainSplitRatio?: float, withFeedback?: bool, withGlobalDatasetId?: int}
]: any -> record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/language/retrain")
  let body = {algorithm: $algorithm, epochs: $epochs, learningRate: $learningRate, modelId: $modelId, trainParams: $trainParams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Prediction for Sentiment
#
# POST /v2/language/sentiment
# operationId: sentimentMultipart
export def "language-sentiment sentimentMultipart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  document: string # Text for which you want to return a sentiment prediction. (e.g. I can't tell you how much fun it was)
  modelId: string # ID of the model that makes the prediction. The model must have been created from a dataset with a type of text-sentiment. (e.g. WJH4YCA7YX4PCWVNCYNWYHBMY4)
  --numResults: int # Number of probabilities to return.  (format: int32, e.g. 3)
  --sampleId: string # String that you can pass in to tag the prediction. Optional. Can be any value, and is returned in the response.
]: any -> record<object: string, probabilities: table<label: string, probability: float>, sampleId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/language/sentiment")
  let body = {document: $document, modelId: $modelId, numResults: $numResults, sampleId: $sampleId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Train a Dataset
#
# POST /v2/language/train
# operationId: train
# --trainParams shape: {trainSplitRatio?: float, withFeedback?: bool, withGlobalDatasetId?: int}
export def "language-train train" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --algorithm: string # Algorithm used for train (e.g. intent)
  --datasetId: int # ID of the dataset to train. (format: int64, e.g. 57)
  --epochs: int # Number of training iterations for the neural network. Optional. (format: int32, e.g. 20)
  --learningRate: float # N/A for intent or sentiment models. (format: double)
  --name: string # Name of the model. Maximum length is 180 characters.
  --trainParams: record # JSON that contains parameters that specify how the model is created — shape: {trainSplitRatio?: float, withFeedback?: bool, withGlobalDatasetId?: int}
]: any -> record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/language/train")
  let body = {algorithm: $algorithm, datasetId: $datasetId, epochs: $epochs, learningRate: $learningRate, name: $name, trainParams: $trainParams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get Training Status
#
# GET /v2/language/train/{modelId}
# operationId: getTrainStatusAndProgress
export def "language-train get" [
  modelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/language/train/($modelId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate an OAuth Token
#
# POST /v2/oauth2/token
# Docs: https://metamind.readme.io/docs/generate-an-oauth-access-token — authentication guid
# operationId: generateTokenV2
export def "oauth2-token generateTokenV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --assertion: string # encrypted payload to identify yourself (e.g. SOME_ASSERTION_STRING)
  --grant-type: string@grant-type-completer # specify the authentication method desired (e.g. urn:ietf:params:oauth:grant-type:jwt-bearer)
  --refresh-token: string # The refresh token you created previously. (e.g. SomeRefreshToken)
  --scope: string # set to `offline` to generate a refresh token (e.g. offline)
  --valid-for: int # Number of seconds until the access token expires. Default is 60 seconds. Maximum value is 30 days (format: int32, default: 60, e.g. 120)
]: any -> record<access_token: string, expires_in: string, refresh_token: string, token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/oauth2/token")
  let body = {assertion: $assertion, grant_type: $grant_type, refresh_token: $refresh_token, scope: $scope, valid_for: $valid_for} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a Refresh Token
#
# DELETE /v2/oauth2/tokens/{token}
# operationId: revokeRefreshTokenV2
export def "oauth2-tokens revokeRefreshTokenV2" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/oauth2/tokens/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Feedback Examples From a Zip File
#
# PUT /v2/vision/bulkfeedback
# operationId: updateDatasetAsync_1
export def "vision-bulkfeedback updateDatasetAsync-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: string # Local .zip file to upload. The maximum .zip file size you can upload from a local drive is 50 MB.
  --modelId: string # ID of the model that misclassified the images. The feedback examples are added to the dataset associated with this model.
]: any -> record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vision/bulkfeedback")
  let body = {data: $data, modelId: $modelId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get All Datasets
#
# GET /v2/vision/datasets
# operationId: listDatasets_1
export def "vision-datasets listDatasets-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: string # Index of the dataset from which you want to start paging (default: 0)
  --count: string # Number of datsets to return. Maximum valid value is 25. If you specify a number greater than 25, the call returns 25 datasets. (default: 25)
  --global: oneof<nothing, bool> # If true, returns all global datasets. Global datasets are public datasets that Salesforce provides. (default: false)
]: nothing -> record<data: table<available: bool, createdAt: string, id: int, labelSummary: record, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "global" $global "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/vision/datasets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Dataset
#
# POST /v2/vision/datasets
# operationId: createDataset
export def "vision-datasets createDataset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --labels: string # Optional comma-separated list of labels. If specified, creates the labels in the dataset. Maximum number of labels per dataset is 250. (e.g. beach,mountain)
  --name: string # Name of the dataset. Maximum length is 180 characters. (e.g. Beach and Mountain)
  --type: string@type-completer-1 # Type of dataset data
]: any -> record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vision/datasets")
  let body = {labels: $labels, name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Create a Dataset From a Zip File Asynchronously
#
# POST /v2/vision/datasets/upload
# operationId: uploadDatasetAsync_1
export def "vision-datasets-upload uploadDatasetAsync-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: string # Path to the .zip file on the local drive (FilePart).
  --name: string # Name of the dataset. Optional. If this parameter is omitted, the dataset name is derived from the .zip file name. (e.g. mountainvsbeach)
  --path: string # URL of the .zip file.
  --type: string@type-completer-2 # Type of dataset data.
]: any -> record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vision/datasets/upload")
  let body = {data: $data, name: $name, path: $path, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Create a Dataset From a Zip File Synchronously
#
# POST /v2/vision/datasets/upload/sync
# operationId: uploadDatasetSync_1
export def "vision-datasets-upload-sync uploadDatasetSync-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: string # Path to the .zip file on the local drive (FilePart).
  --name: string # Name of the dataset. Optional. If this parameter is omitted, the dataset name is derived from the .zip file name. (e.g. mountainvsbeach)
  --path: string # URL of the .zip file.
  --type: string@type-completer-2 # Type of dataset data.
]: any -> record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vision/datasets/upload/sync")
  let body = {data: $data, name: $name, path: $path, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete a Dataset
#
# DELETE /v2/vision/datasets/{datasetId}
# operationId: deleteDataset_1
export def "vision-datasets delete-by-datasetId" [
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/vision/datasets/($datasetId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Dataset
#
# GET /v2/vision/datasets/{datasetId}
# operationId: getDataset_1
export def "vision-datasets get-by-datasetId" [
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/vision/datasets/($datasetId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Examples
#
# GET /v2/vision/datasets/{datasetId}/examples
# operationId: getExamples_1
export def "vision-datasets-examples get-by-datasetId" [
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: string # Index of the example from which you want to start paging. (default: 0)
  --count: string # Number of examples to return. (default: 100)
  --qp-source: string@source-completer # return examples that were created in the dataset as feedback
]: nothing -> record<data: table<createdAt: string, id: int, label: record, location: string, name: string, object: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/vision/datasets/($datasetId)/examples" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Example
#
# POST /v2/vision/datasets/{datasetId}/examples
# operationId: addExample
export def "vision-datasets-examples addExample" [
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: string # Location of the local image file to upload.
  --labelId: int # ID of the label to add to the example. (format: int64, e.g. 42)
  --name: string # Name of the example. Maximum length is 180 characters.
]: any -> record<createdAt: string, id: int, label: record<datasetId: int, id: int, name: string, numExamples: int>, location: string, name: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/vision/datasets/($datasetId)/examples")
  let body = {data: $data, labelId: $labelId, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get All Models
#
# GET /v2/vision/datasets/{datasetId}/models
# operationId: getTrainedModels_1
export def "vision-datasets-models get-by-datasetId" [
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: string # Index of the model from which you want to start paging. (default: 0)
  --count: string # Number of models to return. (default: 100)
]: nothing -> record<data: table<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, failureMsg: string, language: string, modelId: string, modelType: string, name: string, object: string, progress: float, status: string, updatedAt: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/vision/datasets/($datasetId)/models" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Examples From a Zip File
#
# PUT /v2/vision/datasets/{datasetId}/upload
# operationId: updateDatasetAsync_2
export def "vision-datasets-upload updateDatasetAsync-by-datasetId" [
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: string # Location of the local image file to upload.
  --path: string # URL of the .zip file.
]: any -> record<available: bool, createdAt: string, id: int, labelSummary: record<labels: list<record>>, language: string, name: string, numOfDuplicates: int, object: string, statusMsg: string, totalExamples: int, totalLabels: int, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/vision/datasets/($datasetId)/upload")
  let body = {data: $data, path: $path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get Deletion Status
#
# GET /v2/vision/deletion/{id}
# operationId: get_1
export def "vision-deletion get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/vision/deletion/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Detection with Image File
#
# POST /v2/vision/detect
# operationId: detectMultipart
export def "vision-detect detectMultipart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  modelId: string # ID of the model that makes the detection. (e.g. YCQ4ZACEPJFGXZNRA6ERF3GL5E)
  --sampleBase64Content: string # The image contained in a base64 string. (e.g. SomeBase64EncodedImage)
  --sampleId: string # String that you can pass in to tag the prediction. Optional. Can be any value, and is returned in the response.
  --sampleLocation: string # URL of the image file.
]: any -> record<object: string, probabilities: table<boundingBox: record, label: string, probability: float>, sampleId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vision/detect")
  let body = {modelId: $modelId, sampleBase64Content: $sampleBase64Content, sampleId: $sampleId, sampleLocation: $sampleLocation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get All Examples for Label
#
# GET /v2/vision/examples
# operationId: getExamplesByLabel_1
export def "vision-examples get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --labelId: string # Label Id (e.g. SomeLabelId)
  --offset: string # Index of the example from which you want to start paging. (default: 0)
  --count: string # Number of examples to return. (default: 100)
]: nothing -> record<data: table<createdAt: string, id: int, label: record, location: string, name: string, object: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "labelId" $labelId "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/vision/examples" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Feedback Example
#
# POST /v2/vision/feedback
# operationId: provideFeedback_1
export def "vision-feedback provideFeedback-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: string # Local image file to upload.
  --expectedLabel: string # Correct label for the example. Must be a label that exists in the dataset.
  --modelId: string # ID of the model that misclassified the image. The feedback example is added to the dataset associated with this model.
  --name: string # Name of the example. Optional. Maximum length is 180 characters. (e.g. feedback-1)
]: any -> record<createdAt: string, id: int, label: record<datasetId: int, id: int, name: string, numExamples: int>, location: string, name: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vision/feedback")
  let body = {data: $data, expectedLabel: $expectedLabel, modelId: $modelId, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete a Model
#
# DELETE /v2/vision/models/{modelId}
# operationId: deleteModel_1
export def "vision-models delete-by-modelId" [
  modelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deletedObjectId: string, id: string, message: string, object: string, organizationId: string, progress: float, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/vision/models/($modelId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Model Metrics
#
# GET /v2/vision/models/{modelId}
# operationId: getTrainedModelMetrics_1
export def "vision-models get-by-modelId" [
  modelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<algorithm: string, createdAt: string, id: string, language: string, metricsData: record, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/vision/models/($modelId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Model Learning Curve
#
# GET /v2/vision/models/{modelId}/lc
# operationId: getTrainedModelLearningCurve_1
export def "vision-models-lc get-by-modelId" [
  modelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: string # Index of the epoch from which you want to start paging (default: 0)
  --count: string # Number of epoch to return. Maximum valid value is 25. (default: 25)
]: nothing -> record<data: table<epoch: record, epochResults: record, metricsData: record, object: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/vision/models/($modelId)/lc" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Detect Text
#
# POST /v2/vision/ocr
# operationId: ocrMultipart
export def "vision-ocr ocrMultipart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --modelId: string # ID of the model that makes the prediction. Valid values are OCRModel and tabulatev2. (e.g. WJH4YCA7YX4PCWVNCYNWYHBMY4)
  --sampleContent: string # Binary content of image file uploaded as multipart/form-data. Optional. (format: binary)
  --sampleId: string # String that you can pass in to tag the prediction. Optional. Can be any value, and is returned in the response.
  --sampleLocation: string # URL of the image file. Use this parameter when sending in a file from a web location. Optional.
  --task: string # Optional. Designates the type of data in the image. Default is text. Valid values: contact, table, and text. (default: text, e.g. table)
]: any -> record<object: string, probabilities: table<attributes: record, boundingBox: record, label: string, probability: float>, sampleId: string, task: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vision/ocr")
  let body = {modelId: $modelId, sampleContent: $sampleContent, sampleId: $sampleId, sampleLocation: $sampleLocation, task: $task} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Make Prediction
#
# POST /v2/vision/predict
# operationId: predictMultipart
export def "vision-predict predictMultipart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  modelId: string # ID of the model that makes the prediction. (e.g. WJH4YCA7YX4PCWVNCYNWYHBMY4)
  --numResults: int # Number of probabilities to return. (format: int32, e.g. 3)
  --sampleBase64Content: string # The image contained in a base64 string. (e.g. SomeBase64EncodedImage)
  --sampleId: string # String that you can pass in to tag the prediction. Optional. Can be any value, and is returned in the response.
  --sampleLocation: string # URL of the image file.
]: any -> record<object: string, probabilities: table<label: string, probability: float>, sampleId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vision/predict")
  let body = {modelId: $modelId, numResults: $numResults, sampleBase64Content: $sampleBase64Content, sampleId: $sampleId, sampleLocation: $sampleLocation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrain a Dataset
#
# POST /v2/vision/retrain
# operationId: retrain_1
# --trainParams shape: {trainSplitRatio?: float, withFeedback?: bool, withGlobalDatasetId?: int}
export def "vision-retrain retrain-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --algorithm: string # Specifies the algorithm used to train the dataset. Optional. Use this parameter only when training a dataset with a type of image-detection. Valid values are object-detection-v1 and retail-execution. (e.g. object-detection)
  --epochs: int # Number of training iterations for the neural network. Optional. (format: int32, e.g. 20)
  --learningRate: float # Specifies how much the gradient affects the optimization of the model at each time step. Optional. (format: float, e.g. 0.0001)
  --modelId: string # ID of the model to be updated from the training. (e.g. 7JXCXTRXTMNLJCEF2DR5CJ46QU)
  --trainParams: record # JSON that contains parameters that specify how the model is created — shape: {trainSplitRatio?: float, withFeedback?: bool, withGlobalDatasetId?: int}
]: any -> record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vision/retrain")
  let body = {algorithm: $algorithm, epochs: $epochs, learningRate: $learningRate, modelId: $modelId, trainParams: $trainParams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Train a Dataset
#
# POST /v2/vision/train
# operationId: train_1
# --trainParams shape: {trainSplitRatio?: float, withFeedback?: bool, withGlobalDatasetId?: int}
export def "vision-train train-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --algorithm: string # Specifies the algorithm used to train the dataset. Optional. Use this parameter only when training a dataset with a type of image-detection. Valid values are object-detection-v1 and retail-execution. (e.g. object-detection)
  --datasetId: int # ID of the dataset to train. (format: int64, e.g. 57)
  --epochs: int # Number of training iterations for the neural network. Optional. (format: int32, e.g. 20)
  --learningRate: float # Specifies how much the gradient affects the optimization of the model at each time step. Optional. (format: double, e.g. 0.0001)
  --name: string # Name of the model. Maximum length is 180 characters.
  --trainParams: record # JSON that contains parameters that specify how the model is created — shape: {trainSplitRatio?: float, withFeedback?: bool, withGlobalDatasetId?: int}
]: any -> record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vision/train")
  let body = {algorithm: $algorithm, datasetId: $datasetId, epochs: $epochs, learningRate: $learningRate, name: $name, trainParams: $trainParams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get Training Status
#
# GET /v2/vision/train/{modelId}
# operationId: getTrainStatusAndProgress_1
export def "vision-train get-by-modelId" [
  modelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<algorithm: string, createdAt: string, datasetId: int, datasetVersionId: int, epochs: int, failureMsg: string, language: string, learningRate: float, modelId: string, modelType: string, name: string, object: string, progress: float, queuePosition: int, status: string, trainParams: string, trainStats: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/vision/train/($modelId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
