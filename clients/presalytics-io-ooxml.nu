# Auto-generated client for OOXML Automation v0.1.0
# Source: https://api.apis.guru/v2/specs/presalytics.io/ooxml/0.1.0/openapi.json
# Auth: --token flag or $env.OOXML_AUTOMATION_TOKEN

const BASE_URL = "https://api.presalytics.io/ooxml-automation"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OOXML_AUTOMATION_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk (issue 11.B).
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://api.presalytics.io/ooxml-automation"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json" "text/plain"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "charts-axes get" } } | get name | first)
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

# Axes: Get by Id
#
# GET /Charts/Axes/{id}
# operationId: chart_axes_get_id
export def "charts-axes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<axisDataTypeId: int, chartsId: string, id: string, ooxmlId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Charts/Axes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# AxisDataTypes: List All Possible Types
#
# GET /Charts/AxisDataTypes
# operationId: chart_axisdatatypes_get
export def "charts-axis-data-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, id: string, name: string, ooxmlName: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Charts/AxisDataTypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# AxisDataTypes: Get By Type Id
#
# GET /Charts/AxisDataTypes/TypeId/{type_id}
# operationId: chart_axisdatatypes_typeid_get_type_id
export def "charts-axis-data-types-type-id get-axisdatatypes-typeid" [
  type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string, ooxmlName: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type_id: (encode-path-segment $type_id)} | format pattern "/Charts/AxisDataTypes/TypeId/{type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# AxisDataTypes: Get by Id
#
# GET /Charts/AxisDataTypes/{id}
# operationId: chart_axisdatatypes_get_id
export def "charts-axis-data-types get-axisdatatypes" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string, ooxmlName: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Charts/AxisDataTypes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# ChartData: Get by Id
#
# GET /Charts/ChartData/{id}
# operationId: chart_chartdata_get_id
export def "charts-chart-data get-chartdata" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<chartId: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Charts/ChartData/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Charts: Get Chart Data
#
# GET /Charts/ChartUpdate/{id}
# operationId: charts_charts_chartupdate_get_id
export def "charts-chart-update get-chartupdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<categoryNames: list<string>, chartId: string, dataPoints: list<list<float>>, seriesNames: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Charts/ChartUpdate/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Charts: Update Chart Data
#
# PUT /Charts/ChartUpdate/{id}
# operationId: charts_charts_chartupdate_put_id
export def "charts-chart-update update-chartupdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-names: list<string> # nullable
  --chart-id: string # format: uuid
  --data-points: list # nullable
  --series-names: list<string> # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Charts/ChartUpdate/{id}"))
  let req_body = {"categoryNames": $category_names, "chartId": $chart_id, "dataPoints": $data_points, "seriesNames": $series_names} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Charts: Get Dependent Objects Tree
#
# GET /Charts/ChildObjects/{id}
# operationId: charts_charts_childobjects_get_id
export def "charts-child-objects get-childobjects" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Charts/ChildObjects/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# ColumnCollections: Get by Id
#
# GET /Charts/ColumnCollections/{id}
# operationId: chart_columncollections_get_id
export def "charts-column-collections get-columncollections" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<chartDataId: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Charts/ColumnCollections/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Columns: Get by Id
#
# GET /Charts/Columns/{id}
# operationId: chart_columns_get_id
export def "charts-columns get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<axisId: string, columnCollectionId: string, id: string, index: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Charts/Columns/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# DataPoints: Get by Id
#
# GET /Charts/DataPoints/{id}
# operationId: chart_datapoints_get_id
export def "charts-data-points get-datapoints" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<chartDataId: string, columnId: string, id: string, rowId: string, value: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Charts/DataPoints/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Charts: Get Details
#
# GET /Charts/Details/{id}
# operationId: charts_charts_details_get_id
export def "charts-details get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<axes: table<axisDataTypeId: int, chart: any, chartsId: string, dateCreated: string, dateModified: string, id: string, ooxmlId: int, titleTextContainer: record, userCreated: string, userModified: string>, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, chartData: record<chart: any, chartId: string, columnCollection: record<chartData: any, chartDataId: string, columns: list, dateCreated: string, dateModified: string, id: string, userCreated: string, userModified: string>, dataPoints: list<record>, dateCreated: string, dateModified: string, id: string, rowCollection: record<axis: record, axisId: string, chartData: any, chartDataId: string, dateCreated: string, dateModified: string, id: string, nameFormatType: int, rows: list, userCreated: string, userModified: string>, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, id: string, name: string, packageUri: string, parentGraphic: record<chart: any, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: record<childGroupElements: list, connector: record, dateCreated: string, dateModified: string, graphic: any, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record, shapeTree: record, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, fileExtension: string, graphicsId: string, id: string, imageFileBlobUrl: string, imageFill: record, imageFillsId: string, name: string, packageUri: string, parentGraphic: any, userCreated: string, userModified: string>, smartArt: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, graphicsId: string, id: string, name: string, packageUri: string, parentGraphic: any, svgBlobUrl: string, userCreated: string, userModified: string>, table: record<baseElementBlobUrl: string, cells: list, changedBaseElementBlobUrl: string, columns: list, dateCreated: string, dateModified: string, hasStylePart: bool, id: string, name: string, packageUri: string, parentGraphic: any, parentGraphicId: string, rows: list, stylePartOuterXml: string, svgBlobUrl: string, userCreated: string, userModified: string>, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, parentGraphicId: string, svgBlobUrl: string, titleTextContainer: record<axis: record<axisDataTypeId: int, chart: any, chartsId: string, dateCreated: string, dateModified: string, id: string, ooxmlId: int, titleTextContainer: any, userCreated: string, userModified: string>, axisId: string, chart: any, chartId: string, dateCreated: string, dateModified: string, id: string, outerXml: string, paragraphs: list<record>, parentShape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: any, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, shapeId: string, tableCell: record<border: record, column: record, columnId: string, columnSpan: int, dateCreated: string, dateModified: string, fillMap: record, id: string, isMergedHorozontal: bool, isMergedVertical: bool, row: record, rowId: string, rowSpan: int, textContainer: any, userCreated: string, userModified: string>, tableCellId: string, userCreated: string, userModified: string>, userCreated: string, userModified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Charts/Details/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Charts: Get Underlying Xml
#
# GET /Charts/OpenOfficeXml/{id}
# operationId: charts_charts_openofficexml_get_id_updated
export def "charts-open-office-xml get-openofficexml-updated" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated: oneof<nothing, bool> # Indicates whether API should return the orginal uploaded xml (false) or the actively updated version (true, default) (default: true)
]: nothing -> record<id: string, openOfficeXml: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updated" $updated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Charts/OpenOfficeXml/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Charts: Modify Underlying Xml
#
# PUT /Charts/OpenOfficeXml/{id}
# operationId: charts_charts_openofficexml_put_id
export def "charts-open-office-xml update-openofficexml" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string # nullable, format: uuid
  --open-office-xml: string # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Charts/OpenOfficeXml/{id}"))
  let req_body = {"id": $body_id, "openOfficeXml": $open_office_xml, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# PlotType: List All Possible Types
#
# GET /Charts/PlotType
# operationId: chart_plottype_get
export def "charts-plot-type list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, plotQualifedAssy: string, plotTypeName: string, rowColTypeId: int, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Charts/PlotType")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# PlotType: Get By Type Id
#
# GET /Charts/PlotType/TypeId/{type_id}
# operationId: chart_plottype_typeid_get_type_id
export def "charts-plot-type-type-id get-plottype-typeid" [
  type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, plotQualifedAssy: string, plotTypeName: string, rowColTypeId: int, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type_id: (encode-path-segment $type_id)} | format pattern "/Charts/PlotType/TypeId/{type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# PlotType: Get by Id
#
# GET /Charts/PlotType/{id}
# operationId: chart_plottype_get_id
export def "charts-plot-type get-plottype" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, plotQualifedAssy: string, plotTypeName: string, rowColTypeId: int, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Charts/PlotType/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# RowCol: List All Possible Types
#
# GET /Charts/RowCol
# operationId: chart_rowcol_get
export def "charts-row-col list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<colName: string, colQualifiedAssy: string, id: string, rowName: string, rowQualifedAssy: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Charts/RowCol")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# RowCol: Get By Type Id
#
# GET /Charts/RowCol/TypeId/{type_id}
# operationId: chart_rowcol_typeid_get_type_id
export def "charts-row-col-type-id get-rowcol-typeid" [
  type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<colName: string, colQualifiedAssy: string, id: string, rowName: string, rowQualifedAssy: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type_id: (encode-path-segment $type_id)} | format pattern "/Charts/RowCol/TypeId/{type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# RowCol: Get by Id
#
# GET /Charts/RowCol/{id}
# operationId: chart_rowcol_get_id
export def "charts-row-col get-rowcol" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<colName: string, colQualifiedAssy: string, id: string, rowName: string, rowQualifedAssy: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Charts/RowCol/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# RowCollections: Get by Id
#
# GET /Charts/RowCollections/{id}
# operationId: chart_rowcollections_get_id
export def "charts-row-collections get-rowcollections" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<axisId: string, chartDataId: string, id: string, nameFormatType: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Charts/RowCollections/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# RowNameFormatTypes: List All Possible Types
#
# GET /Charts/RowNameFormatTypes
# operationId: chart_rownameformattypes_get
export def "charts-row-name-format-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<formatCode: string, id: string, powerToolsId: int, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Charts/RowNameFormatTypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# RowNameFormatTypes: Get By Type Id
#
# GET /Charts/RowNameFormatTypes/TypeId/{type_id}
# operationId: chart_rownameformattypes_typeid_get_type_id
export def "charts-row-name-format-types-type-id get-rownameformattypes-typeid" [
  type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<formatCode: string, id: string, powerToolsId: int, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type_id: (encode-path-segment $type_id)} | format pattern "/Charts/RowNameFormatTypes/TypeId/{type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# RowNameFormatTypes: Get by Id
#
# GET /Charts/RowNameFormatTypes/{id}
# operationId: chart_rownameformattypes_get_id
export def "charts-row-name-format-types get-rownameformattypes" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<formatCode: string, id: string, powerToolsId: int, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Charts/RowNameFormatTypes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Rows: Get by Id
#
# GET /Charts/Rows/{id}
# operationId: chart_rows_get_id
export def "charts-rows get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, index: int, name: string, rowNameCollectionId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Charts/Rows/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Charts: Get Svg file
#
# GET /Charts/Svg/{id}
# operationId: charts_charts_svg_get_id_use_cache
export def "charts-svg get-use-cache" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --use-cache: oneof<nothing, bool> # Indicates whether API should retrieve content from a cache if aviable (true, default), or force an update (false) (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "use_cache" $use_cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Charts/Svg/{id}") $qp)
  let accept_val = "image/svg+xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Charts: Get by Id
#
# GET /Charts/{id}
# operationId: charts_charts_get_id
export def "charts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, id: string, name: string, packageUri: string, parentGraphicId: string, svgBlobUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Charts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Get Dependent Objects Tree
#
# GET /ConnectionShapes/ChildObjects/{id}
# operationId: slides_connectionshapes_childobjects_get_id
export def "connection-shapes-child-objects get-slides-connectionshapes-childobjects" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ConnectionShapes/ChildObjects/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Get Details
#
# GET /ConnectionShapes/Details/{id}
# operationId: slides_connectionshapes_details_get_id
export def "connection-shapes-details get-slides-connectionshapes" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record<connectorId: string, dateCreated: string, dateModified: string, effectAttributes: list<record>, effectMap: record<dateCreated: string, dateModified: string, effect: any, id: string, intensityId: int, theme: record, themeId: string, userCreated: string, userModified: string>, effectMapId: string, id: string, name: string, parentConnector: any, parentShape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: any, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, shapeId: string, userCreated: string, userModified: string>, endConnectionIdx: int, endConnectionShape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record<connectorId: string, dateCreated: string, dateModified: string, effectAttributes: list, effectMap: record, effectMapId: string, id: string, name: string, parentConnector: any, parentShape: any, shapeId: string, userCreated: string, userModified: string>, fillMap: record<connector: any, connectorId: string, dateCreated: string, dateModified: string, effectAttribute: record, effectAttributeId: string, fillTypeId: int, gradientFill: record, id: string, imageFill: record, shape: any, shapeId: string, solidFill: record, tableCell: record, tableCellId: string, themeBackgroundFill: record, themeBackgroundFillId: string, themeFill: record, themeFillId: string, userCreated: string, userModified: string>, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record<childGroupElements: list, connector: any, dateCreated: string, dateModified: string, graphic: record, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: any, shapeTree: record, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record<bLtoTRBorder: record, bLtoTRBorderId: string, bottomBorder: record, bottomBorderId: string, connectorId: string, dashTypeId: int, dateCreated: string, dateModified: string, headEndHeightId: int, headEndTypeId: int, headEndWidthId: int, id: string, leftBorder: record, leftBorderId: string, lineColorSolidFill: record, lineMap: record, lineMapId: string, parentConnector: any, parentShape: any, rightBorder: record, rightBorderId: string, shapeId: string, tLtoBRBorder: record, tLtoBRBorderId: string, tailEndHeightId: int, tailEndTypeId: int, tailEndWidthId: int, topBorder: record, topBorderId: string, userCreated: string, userModified: string, weight: int>, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record<axis: record, axisId: string, chart: record, chartId: string, dateCreated: string, dateModified: string, id: string, outerXml: string, paragraphs: list, parentShape: any, shapeId: string, tableCell: record, tableCellId: string, userCreated: string, userModified: string>, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, endConnectionShapeId: string, fillMap: record<connector: any, connectorId: string, dateCreated: string, dateModified: string, effectAttribute: record<attributesJson: string, dateCreated: string, dateModified: string, effect: record, effectId: string, effectTypeId: int, fillMap: any, id: string, userCreated: string, userModified: string>, effectAttributeId: string, fillTypeId: int, gradientFill: record<angle: int, dateCreated: string, dateModified: string, fillMap: any, fillMapId: string, gradientStops: list, id: string, isPath: bool, pathType: string, rotateWithShape: bool, userCreated: string, userModified: string>, id: string, imageFill: record<compressionState: string, dateCreated: string, dateModified: string, dpi: int, effectsJson: string, fillMap: any, fillMapId: string, id: string, picture: record, rotateWithShape: bool, sourceRectangle: string, stretch: bool, tile: string, userCreated: string, userModified: string>, shape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, fillMap: any, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, shapeId: string, solidFill: record<colorTransformations: record, colorTypeId: int, dateCreated: string, dateModified: string, fillMapId: string, hexValue: string, id: string, isUserColor: bool, parentFillMap: any, parentGradientStop: record, parentGradientStopId: string, parentLine: record, parentLineId: string, parentText: record, parentTextId: string, userCreated: string, userModified: string>, tableCell: record<border: record, column: record, columnId: string, columnSpan: int, dateCreated: string, dateModified: string, fillMap: any, id: string, isMergedHorozontal: bool, isMergedVertical: bool, row: record, rowId: string, rowSpan: int, textContainer: record, userCreated: string, userModified: string>, tableCellId: string, themeBackgroundFill: record<dateCreated: string, dateModified: string, fillMap: any, id: string, intensityId: int, theme: record, themeId: string, userCreated: string, userModified: string>, themeBackgroundFillId: string, themeFill: record<dateCreated: string, dateModified: string, fillMap: any, id: string, intensityId: int, theme: record, themeId: string, userCreated: string, userModified: string>, themeFillId: string, userCreated: string, userModified: string>, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record<childGroupElements: list<any>, connector: any, dateCreated: string, dateModified: string, graphic: record<chart: record, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: any, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: record, smartArt: record, table: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, group: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: any, groupElementId: string, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: any, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, shapeTree: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: any, groupElementId: string, groupElements: list, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, slide: record, slideId: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, shapeTreeId: string, typeInfo: record<dateCreated: string, dateModified: string, description: string, id: string, name: string, typeId: int, userCreated: string, userModified: string>, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record<bLtoTRBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, bLtoTRBorderId: string, bottomBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, bottomBorderId: string, connectorId: string, dashTypeId: int, dateCreated: string, dateModified: string, headEndHeightId: int, headEndTypeId: int, headEndWidthId: int, id: string, leftBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, leftBorderId: string, lineColorSolidFill: record<colorTransformations: record, colorTypeId: int, dateCreated: string, dateModified: string, fillMapId: string, hexValue: string, id: string, isUserColor: bool, parentFillMap: record, parentGradientStop: record, parentGradientStopId: string, parentLine: any, parentLineId: string, parentText: record, parentTextId: string, userCreated: string, userModified: string>, lineMap: record<dateCreated: string, dateModified: string, id: string, intensityId: int, line: any, theme: record, themeId: string, userCreated: string, userModified: string>, lineMapId: string, parentConnector: any, parentShape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: any, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, rightBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, rightBorderId: string, shapeId: string, tLtoBRBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, tLtoBRBorderId: string, tailEndHeightId: int, tailEndTypeId: int, tailEndWidthId: int, topBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, topBorderId: string, userCreated: string, userModified: string, weight: int>, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record<connectorId: string, dateCreated: string, dateModified: string, effectAttributes: list, effectMap: record, effectMapId: string, id: string, name: string, parentConnector: any, parentShape: any, shapeId: string, userCreated: string, userModified: string>, fillMap: record<connector: any, connectorId: string, dateCreated: string, dateModified: string, effectAttribute: record, effectAttributeId: string, fillTypeId: int, gradientFill: record, id: string, imageFill: record, shape: any, shapeId: string, solidFill: record, tableCell: record, tableCellId: string, themeBackgroundFill: record, themeBackgroundFillId: string, themeFill: record, themeFillId: string, userCreated: string, userModified: string>, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record<childGroupElements: list, connector: any, dateCreated: string, dateModified: string, graphic: record, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: any, shapeTree: record, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record<bLtoTRBorder: record, bLtoTRBorderId: string, bottomBorder: record, bottomBorderId: string, connectorId: string, dashTypeId: int, dateCreated: string, dateModified: string, headEndHeightId: int, headEndTypeId: int, headEndWidthId: int, id: string, leftBorder: record, leftBorderId: string, lineColorSolidFill: record, lineMap: record, lineMapId: string, parentConnector: any, parentShape: any, rightBorder: record, rightBorderId: string, shapeId: string, tLtoBRBorder: record, tLtoBRBorderId: string, tailEndHeightId: int, tailEndTypeId: int, tailEndWidthId: int, topBorder: record, topBorderId: string, userCreated: string, userModified: string, weight: int>, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record<axis: record, axisId: string, chart: record, chartId: string, dateCreated: string, dateModified: string, id: string, outerXml: string, paragraphs: list, parentShape: any, shapeId: string, tableCell: record, tableCellId: string, userCreated: string, userModified: string>, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, startConnectionShapeId: string, svgBlobUrl: string, userCreated: string, userModified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ConnectionShapes/Details/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Get Underlying Xml
#
# GET /ConnectionShapes/OpenOfficeXml/{id}
# operationId: slides_connectionshapes_openofficexml_get_id_updated
export def "connection-shapes-open-office-xml get-slides-connectionshapes-openofficexml-updated" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated: oneof<nothing, bool> # Indicates whether API should return the orginal uploaded xml (false) or the actively updated version (true, default) (default: true)
]: nothing -> record<id: string, openOfficeXml: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updated" $updated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ConnectionShapes/OpenOfficeXml/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Modify Underlying Xml
#
# PUT /ConnectionShapes/OpenOfficeXml/{id}
# operationId: slides_connectionshapes_openofficexml_put_id
export def "connection-shapes-open-office-xml update-slides-connectionshapes-openofficexml" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string # nullable, format: uuid
  --open-office-xml: string # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ConnectionShapes/OpenOfficeXml/{id}"))
  let req_body = {"id": $body_id, "openOfficeXml": $open_office_xml, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Slides: Get Svg file
#
# GET /ConnectionShapes/Svg/{id}
# operationId: slides_connectionshapes_svg_get_id_use_cache
export def "connection-shapes-svg get-slides-connectionshapes-use-cache" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --use-cache: oneof<nothing, bool> # Indicates whether API should retrieve content from a cache if aviable (true, default), or force an update (false) (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "use_cache" $use_cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ConnectionShapes/Svg/{id}") $qp)
  let accept_val = "image/svg+xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# ConnectionShapes: Get by Id
#
# GET /ConnectionShapes/{id}
# operationId: slides_connectionshapes_get_id
export def "connection-shapes get-slides-connectionshapes" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, endConnectionIdx: int, endConnectionShapeId: string, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShapeId: string, svgBlobUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ConnectionShapes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Documents: Upload
#
# POST /Documents
# operationId: documents_post
export def "documents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  file: string # The file to upload. Must be of type .pptx, ppt (format: binary)
  story_id: string # The story_id of the document being uploaded. (format: uuid)
]: any -> table<baseElementBlobUrl: string, blobLocation: string, changedBaseElementBlobUrl: string, documentTypeId: int, filename: string, id: string, name: string, ownerGuid: string, packageUri: string, storyId: string, tableStylesXmlBlobUrl: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Documents")
  let req_body = {"file": $file, "storyId": $story_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# DocumentsController: Get Dependent Objects Tree
#
# GET /Documents/ChildObjects/{id}
# operationId: documents_childobjects_get_id
export def "documents-child-objects get-childobjects" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Documents/ChildObjects/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Documents: Clone an existing Ooxml Document to new Parent Story
#
# POST /Documents/Clone/{id}
# operationId: documents_clone_post_id
export def "documents-clone create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body-id: string # format: uuid
  --story-id: string # format: uuid
]: any -> record<baseElementBlobUrl: string, blobLocation: string, changedBaseElementBlobUrl: string, documentTypeId: int, filename: string, id: string, name: string, ownerGuid: string, packageUri: string, storyId: string, tableStylesXmlBlobUrl: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Documents/Clone/{id}"))
  let req_body = {"id": $body_id, "storyId": $story_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# DocumentType: List All Possible Types
#
# GET /Documents/DocumentType
# operationId: documents_documenttype_get
export def "documents-document-type list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, fileExtension: string, id: string, mimeType: string, name: string, ooxmlPackageType: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Documents/DocumentType")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# DocumentType: Get By Type Id
#
# GET /Documents/DocumentType/TypeId/{type_id}
# operationId: documents_documenttype_typeid_get_type_id
export def "documents-document-type-type-id get-documenttype-typeid" [
  type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, fileExtension: string, id: string, mimeType: string, name: string, ooxmlPackageType: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type_id: (encode-path-segment $type_id)} | format pattern "/Documents/DocumentType/TypeId/{type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# DocumentType: Get by Id
#
# GET /Documents/DocumentType/{id}
# operationId: documents_documenttype_get_id
export def "documents-document-type get-documenttype" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, fileExtension: string, id: string, mimeType: string, name: string, ooxmlPackageType: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Documents/DocumentType/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Documents: Download
#
# GET /Documents/Download/{id}
# operationId: documents_download_get_id_orginal
export def "documents-download get-orginal" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --orginal: oneof<nothing, bool> # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orginal" $orginal "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Documents/Download/{id}") $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Documents: Delete by Id
#
# DELETE /Documents/{id}
# operationId: documents_delete_id
export def "documents delete" [
  id: string
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Documents/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Documents: Get by Id
#
# GET /Documents/{id}
# operationId: documents_get_id
export def "documents get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<baseElementBlobUrl: string, blobLocation: string, changedBaseElementBlobUrl: string, documentTypeId: int, filename: string, id: string, name: string, ownerGuid: string, packageUri: string, storyId: string, tableStylesXmlBlobUrl: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Documents/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Get Dependent Objects Tree
#
# GET /Groups/ChildObjects/{id}
# operationId: slides_groups_childobjects_get_id
export def "groups-child-objects get-slides-childobjects" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Groups/ChildObjects/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Get Details
#
# GET /Groups/Details/{id}
# operationId: slides_groups_details_get_id
export def "groups-details get-slides" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: record<childGroupElements: list<any>, connector: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, endConnectionIdx: int, endConnectionShape: record, endConnectionShapeId: string, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: any, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShape: record, startConnectionShapeId: string, svgBlobUrl: string, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, graphic: record<chart: record, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: any, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: record, smartArt: record, table: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, group: any, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: any, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, shapeTree: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: any, groupElementId: string, groupElements: list, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, slide: record, slideId: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, shapeTreeId: string, typeInfo: record<dateCreated: string, dateModified: string, description: string, id: string, name: string, typeId: int, userCreated: string, userModified: string>, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementId: string, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Groups/Details/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Get Underlying Xml
#
# GET /Groups/OpenOfficeXml/{id}
# operationId: slides_groups_openofficexml_get_id_updated
export def "groups-open-office-xml get-slides-openofficexml-updated" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated: oneof<nothing, bool> # Indicates whether API should return the orginal uploaded xml (false) or the actively updated version (true, default) (default: true)
]: nothing -> record<id: string, openOfficeXml: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updated" $updated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Groups/OpenOfficeXml/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Modify Underlying Xml
#
# PUT /Groups/OpenOfficeXml/{id}
# operationId: slides_groups_openofficexml_put_id
export def "groups-open-office-xml update-slides-openofficexml" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string # nullable, format: uuid
  --open-office-xml: string # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Groups/OpenOfficeXml/{id}"))
  let req_body = {"id": $body_id, "openOfficeXml": $open_office_xml, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Slides: Get Svg file
#
# GET /Groups/Svg/{id}
# operationId: slides_groups_svg_get_id_use_cache
export def "groups-svg get-slides-use-cache" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --use-cache: oneof<nothing, bool> # Indicates whether API should retrieve content from a cache if aviable (true, default), or force an update (false) (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "use_cache" $use_cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Groups/Svg/{id}") $qp)
  let accept_val = "image/svg+xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Groups: Get by Id
#
# GET /Groups/{id}
# operationId: slides_groups_get_id
export def "groups get-slides" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, groupElementId: string, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, svgBlobUrl: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Groups/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Shared: Get Dependent Objects Tree
#
# GET /Images/ChildObjects/{id}
# operationId: shared_images_childobjects_get_id
export def "images-child-objects get-shared-childobjects" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Images/ChildObjects/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Shared: Get Details
#
# GET /Images/Details/{id}
# operationId: shared_images_details_get_id
export def "images-details get-shared" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, fileExtension: string, graphicsId: string, id: string, imageFileBlobUrl: string, imageFill: record<compressionState: string, dateCreated: string, dateModified: string, dpi: int, effectsJson: string, fillMap: record<connector: record, connectorId: string, dateCreated: string, dateModified: string, effectAttribute: record, effectAttributeId: string, fillTypeId: int, gradientFill: record, id: string, imageFill: any, shape: record, shapeId: string, solidFill: record, tableCell: record, tableCellId: string, themeBackgroundFill: record, themeBackgroundFillId: string, themeFill: record, themeFillId: string, userCreated: string, userModified: string>, fillMapId: string, id: string, picture: any, rotateWithShape: bool, sourceRectangle: string, stretch: bool, tile: string, userCreated: string, userModified: string>, imageFillsId: string, name: string, packageUri: string, parentGraphic: record<chart: record<axes: list, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, chartData: record, dateCreated: string, dateModified: string, id: string, name: string, packageUri: string, parentGraphic: any, parentGraphicId: string, svgBlobUrl: string, titleTextContainer: record, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: record<childGroupElements: list, connector: record, dateCreated: string, dateModified: string, graphic: any, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record, shapeTree: record, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: any, smartArt: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, graphicsId: string, id: string, name: string, packageUri: string, parentGraphic: any, svgBlobUrl: string, userCreated: string, userModified: string>, table: record<baseElementBlobUrl: string, cells: list, changedBaseElementBlobUrl: string, columns: list, dateCreated: string, dateModified: string, hasStylePart: bool, id: string, name: string, packageUri: string, parentGraphic: any, parentGraphicId: string, rows: list, stylePartOuterXml: string, svgBlobUrl: string, userCreated: string, userModified: string>, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, userCreated: string, userModified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Images/Details/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Image: Download Image
#
# PUT /Images/GetImage/{Id}
# operationId: shared_images_getimage_put_id
export def "images-get-image update-shared-getimage" [
  id: string
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Images/GetImage/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Shared: Get Underlying Xml
#
# GET /Images/OpenOfficeXml/{id}
# operationId: shared_images_openofficexml_get_id_updated
export def "images-open-office-xml get-shared-openofficexml-updated" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated: oneof<nothing, bool> # Indicates whether API should return the orginal uploaded xml (false) or the actively updated version (true, default) (default: true)
]: nothing -> record<id: string, openOfficeXml: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updated" $updated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Images/OpenOfficeXml/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Shared: Modify Underlying Xml
#
# PUT /Images/OpenOfficeXml/{id}
# operationId: shared_images_openofficexml_put_id
export def "images-open-office-xml update-shared-openofficexml" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string # nullable, format: uuid
  --open-office-xml: string # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Images/OpenOfficeXml/{id}"))
  let req_body = {"id": $body_id, "openOfficeXml": $open_office_xml, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Shared: Get Svg file
#
# GET /Images/Svg/{id}
# operationId: shared_images_svg_get_id_use_cache
export def "images-svg get-shared-use-cache" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --use-cache: oneof<nothing, bool> # Indicates whether API should retrieve content from a cache if aviable (true, default), or force an update (false) (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "use_cache" $use_cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Images/Svg/{id}") $qp)
  let accept_val = "image/svg+xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Images: Get by Id
#
# GET /Images/{id}
# operationId: shared_images_get_id
export def "images get-shared" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, fileExtension: string, graphicsId: string, id: string, imageFileBlobUrl: string, imageFillsId: string, name: string, packageUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Images/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Get Dependent Objects Tree
#
# GET /ShapeTrees/ChildObjects/{id}
# operationId: slides_shapetrees_childobjects_get_id
export def "shape-trees-child-objects get-slides-shapetrees-childobjects" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ShapeTrees/ChildObjects/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Get Details
#
# GET /ShapeTrees/Details/{id}
# operationId: slides_shapetrees_details_get_id
export def "shape-trees-details get-slides-shapetrees" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: record<childGroupElements: list<any>, connector: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, endConnectionIdx: int, endConnectionShape: record, endConnectionShapeId: string, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: any, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShape: record, startConnectionShapeId: string, svgBlobUrl: string, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, graphic: record<chart: record, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: any, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: record, smartArt: record, table: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, group: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: any, groupElementId: string, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: any, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, shapeTree: any, shapeTreeId: string, typeInfo: record<dateCreated: string, dateModified: string, description: string, id: string, name: string, typeId: int, userCreated: string, userModified: string>, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementId: string, groupElements: table<childGroupElements: list, connector: record, dateCreated: string, dateModified: string, graphic: record, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record, shapeTree: any, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, slide: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, document: record<baseElementBlobUrl: string, blobLocation: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, documentTypeId: int, filename: string, id: string, name: string, ownerGuid: string, packageUri: string, slides: list, storyId: string, tableStylesXmlBlobUrl: string, title: string, userCreated: string, userModified: string>, documentId: string, id: string, name: string, number: int, ooxmlId: int, packageUri: string, shapeTree: any, slideDocumentUrl: string, slideMaster: record<colorMap: record, dateCreated: string, dateModified: string, id: string, parentSlide: any, slideId: string, userCreated: string, userModified: string>, svgBlobUrl: string, theme: record<backgroundFills: list, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, colors: record, customColors: list, dateCreated: string, dateModified: string, effectMaps: list, fills: list, fonts: record, id: string, lineMaps: list, name: string, packageUri: string, slide: any, slideId: string, userCreated: string, userModified: string>, userCreated: string, userModified: string>, slideId: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ShapeTrees/Details/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Get Underlying Xml
#
# GET /ShapeTrees/OpenOfficeXml/{id}
# operationId: slides_shapetrees_openofficexml_get_id_updated
export def "shape-trees-open-office-xml get-slides-shapetrees-openofficexml-updated" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated: oneof<nothing, bool> # Indicates whether API should return the orginal uploaded xml (false) or the actively updated version (true, default) (default: true)
]: nothing -> record<id: string, openOfficeXml: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updated" $updated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ShapeTrees/OpenOfficeXml/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Modify Underlying Xml
#
# PUT /ShapeTrees/OpenOfficeXml/{id}
# operationId: slides_shapetrees_openofficexml_put_id
export def "shape-trees-open-office-xml update-slides-shapetrees-openofficexml" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string # nullable, format: uuid
  --open-office-xml: string # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ShapeTrees/OpenOfficeXml/{id}"))
  let req_body = {"id": $body_id, "openOfficeXml": $open_office_xml, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Slides: Get Svg file
#
# GET /ShapeTrees/Svg/{id}
# operationId: slides_shapetrees_svg_get_id_use_cache
export def "shape-trees-svg get-slides-shapetrees-use-cache" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --use-cache: oneof<nothing, bool> # Indicates whether API should retrieve content from a cache if aviable (true, default), or force an update (false) (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "use_cache" $use_cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ShapeTrees/Svg/{id}") $qp)
  let accept_val = "image/svg+xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# ShapeTrees: Get by Id
#
# GET /ShapeTrees/{id}
# operationId: slides_shapetrees_get_id
export def "shape-trees get-slides-shapetrees" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, groupElementId: string, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, slideId: string, svgBlobUrl: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ShapeTrees/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Get Dependent Objects Tree
#
# GET /Shapes/ChildObjects/{id}
# operationId: slides_shapes_childobjects_get_id
export def "shapes-child-objects get-slides-childobjects" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shapes/ChildObjects/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Get Details
#
# GET /Shapes/Details/{id}
# operationId: slides_shapes_details_get_id
export def "shapes-details get-slides" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record<connectorId: string, dateCreated: string, dateModified: string, effectAttributes: list<record>, effectMap: record<dateCreated: string, dateModified: string, effect: any, id: string, intensityId: int, theme: record, themeId: string, userCreated: string, userModified: string>, effectMapId: string, id: string, name: string, parentConnector: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: any, endConnectionIdx: int, endConnectionShape: any, endConnectionShapeId: string, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShape: any, startConnectionShapeId: string, svgBlobUrl: string, userCreated: string, userModified: string>, parentShape: any, shapeId: string, userCreated: string, userModified: string>, fillMap: record<connector: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, endConnectionIdx: int, endConnectionShape: any, endConnectionShapeId: string, fillMap: any, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShape: any, startConnectionShapeId: string, svgBlobUrl: string, userCreated: string, userModified: string>, connectorId: string, dateCreated: string, dateModified: string, effectAttribute: record<attributesJson: string, dateCreated: string, dateModified: string, effect: record, effectId: string, effectTypeId: int, fillMap: any, id: string, userCreated: string, userModified: string>, effectAttributeId: string, fillTypeId: int, gradientFill: record<angle: int, dateCreated: string, dateModified: string, fillMap: any, fillMapId: string, gradientStops: list, id: string, isPath: bool, pathType: string, rotateWithShape: bool, userCreated: string, userModified: string>, id: string, imageFill: record<compressionState: string, dateCreated: string, dateModified: string, dpi: int, effectsJson: string, fillMap: any, fillMapId: string, id: string, picture: record, rotateWithShape: bool, sourceRectangle: string, stretch: bool, tile: string, userCreated: string, userModified: string>, shape: any, shapeId: string, solidFill: record<colorTransformations: record, colorTypeId: int, dateCreated: string, dateModified: string, fillMapId: string, hexValue: string, id: string, isUserColor: bool, parentFillMap: any, parentGradientStop: record, parentGradientStopId: string, parentLine: record, parentLineId: string, parentText: record, parentTextId: string, userCreated: string, userModified: string>, tableCell: record<border: record, column: record, columnId: string, columnSpan: int, dateCreated: string, dateModified: string, fillMap: any, id: string, isMergedHorozontal: bool, isMergedVertical: bool, row: record, rowId: string, rowSpan: int, textContainer: record, userCreated: string, userModified: string>, tableCellId: string, themeBackgroundFill: record<dateCreated: string, dateModified: string, fillMap: any, id: string, intensityId: int, theme: record, themeId: string, userCreated: string, userModified: string>, themeBackgroundFillId: string, themeFill: record<dateCreated: string, dateModified: string, fillMap: any, id: string, intensityId: int, theme: record, themeId: string, userCreated: string, userModified: string>, themeFillId: string, userCreated: string, userModified: string>, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record<childGroupElements: list<any>, connector: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, endConnectionIdx: int, endConnectionShape: any, endConnectionShapeId: string, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: any, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShape: any, startConnectionShapeId: string, svgBlobUrl: string, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, graphic: record<chart: record, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: any, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: record, smartArt: record, table: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, group: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: any, groupElementId: string, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: any, shapeTree: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: any, groupElementId: string, groupElements: list, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, slide: record, slideId: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, shapeTreeId: string, typeInfo: record<dateCreated: string, dateModified: string, description: string, id: string, name: string, typeId: int, userCreated: string, userModified: string>, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record<bLtoTRBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, bLtoTRBorderId: string, bottomBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, bottomBorderId: string, connectorId: string, dashTypeId: int, dateCreated: string, dateModified: string, headEndHeightId: int, headEndTypeId: int, headEndWidthId: int, id: string, leftBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, leftBorderId: string, lineColorSolidFill: record<colorTransformations: record, colorTypeId: int, dateCreated: string, dateModified: string, fillMapId: string, hexValue: string, id: string, isUserColor: bool, parentFillMap: record, parentGradientStop: record, parentGradientStopId: string, parentLine: any, parentLineId: string, parentText: record, parentTextId: string, userCreated: string, userModified: string>, lineMap: record<dateCreated: string, dateModified: string, id: string, intensityId: int, line: any, theme: record, themeId: string, userCreated: string, userModified: string>, lineMapId: string, parentConnector: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, endConnectionIdx: int, endConnectionShape: any, endConnectionShapeId: string, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: any, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShape: any, startConnectionShapeId: string, svgBlobUrl: string, userCreated: string, userModified: string>, parentShape: any, rightBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, rightBorderId: string, shapeId: string, tLtoBRBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, tLtoBRBorderId: string, tailEndHeightId: int, tailEndTypeId: int, tailEndWidthId: int, topBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, topBorderId: string, userCreated: string, userModified: string, weight: int>, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record<axis: record<axisDataTypeId: int, chart: record, chartsId: string, dateCreated: string, dateModified: string, id: string, ooxmlId: int, titleTextContainer: any, userCreated: string, userModified: string>, axisId: string, chart: record<axes: list, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, chartData: record, dateCreated: string, dateModified: string, id: string, name: string, packageUri: string, parentGraphic: record, parentGraphicId: string, svgBlobUrl: string, titleTextContainer: any, userCreated: string, userModified: string>, chartId: string, dateCreated: string, dateModified: string, id: string, outerXml: string, paragraphs: list<record>, parentShape: any, shapeId: string, tableCell: record<border: record, column: record, columnId: string, columnSpan: int, dateCreated: string, dateModified: string, fillMap: record, id: string, isMergedHorozontal: bool, isMergedVertical: bool, row: record, rowId: string, rowSpan: int, textContainer: any, userCreated: string, userModified: string>, tableCellId: string, userCreated: string, userModified: string>, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shapes/Details/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Get Underlying Xml
#
# GET /Shapes/OpenOfficeXml/{id}
# operationId: slides_shapes_openofficexml_get_id_updated
export def "shapes-open-office-xml get-slides-openofficexml-updated" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated: oneof<nothing, bool> # Indicates whether API should return the orginal uploaded xml (false) or the actively updated version (true, default) (default: true)
]: nothing -> record<id: string, openOfficeXml: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updated" $updated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shapes/OpenOfficeXml/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Modify Underlying Xml
#
# PUT /Shapes/OpenOfficeXml/{id}
# operationId: slides_shapes_openofficexml_put_id
export def "shapes-open-office-xml update-slides-openofficexml" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string # nullable, format: uuid
  --open-office-xml: string # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shapes/OpenOfficeXml/{id}"))
  let req_body = {"id": $body_id, "openOfficeXml": $open_office_xml, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Slides: Get Svg file
#
# GET /Shapes/Svg/{id}
# operationId: slides_shapes_svg_get_id_use_cache
export def "shapes-svg get-slides-use-cache" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --use-cache: oneof<nothing, bool> # Indicates whether API should retrieve content from a cache if aviable (true, default), or force an update (false) (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "use_cache" $use_cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shapes/Svg/{id}") $qp)
  let accept_val = "image/svg+xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Shapes: Get by Id
#
# GET /Shapes/{id}
# operationId: slides_shapes_get_id
export def "shapes get-slides" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, width: int, xOffset: int, yOffset: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shapes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# ColorTransformationAttributes: Get by Id
#
# GET /Shared/ColorTransformationAttributes/{id}
# operationId: shared_colortransformationattributes_get_id
export def "shared-color-transformation-attributes get-colortransformationattributes" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<colorTransformationsId: string, id: string, name: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shared/ColorTransformationAttributes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# ColorTransformations: Get by Id
#
# GET /Shared/ColorTransformations/{id}
# operationId: shared_colortransformations_get_id
export def "shared-color-transformations get-colortransformations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, solidFillsId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shared/ColorTransformations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# ColorTypes: List All Possible Types
#
# GET /Shared/ColorTypes
# operationId: shared_colortypes_get
export def "shared-color-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<colorSchemeIndexValueEnum: int, description: string, id: string, name: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Shared/ColorTypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# ColorTypes: Get By Type Id
#
# GET /Shared/ColorTypes/TypeId/{type_id}
# operationId: shared_colortypes_typeid_get_type_id
export def "shared-color-types-type-id get-colortypes-typeid" [
  type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<colorSchemeIndexValueEnum: int, description: string, id: string, name: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type_id: (encode-path-segment $type_id)} | format pattern "/Shared/ColorTypes/TypeId/{type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# ColorTypes: Get by Id
#
# GET /Shared/ColorTypes/{id}
# operationId: shared_colortypes_get_id
export def "shared-color-types get-colortypes" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<colorSchemeIndexValueEnum: int, description: string, id: string, name: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shared/ColorTypes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# DashTypes: List All Possible Types
#
# GET /Shared/DashTypes
# operationId: shared_dashtypes_get
export def "shared-dash-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, id: string, name: string, serializedAs: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Shared/DashTypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# DashTypes: Get By Type Id
#
# GET /Shared/DashTypes/TypeId/{type_id}
# operationId: shared_dashtypes_typeid_get_type_id
export def "shared-dash-types-type-id get-dashtypes-typeid" [
  type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string, serializedAs: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type_id: (encode-path-segment $type_id)} | format pattern "/Shared/DashTypes/TypeId/{type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# DashTypes: Get by Id
#
# GET /Shared/DashTypes/{id}
# operationId: shared_dashtypes_get_id
export def "shared-dash-types get-dashtypes" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string, serializedAs: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shared/DashTypes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# EffectAttributes: Get by Id
#
# GET /Shared/EffectAttributes/{id}
# operationId: shared_effectattributes_get_id
export def "shared-effect-attributes get-effectattributes" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attributesJson: string, effectId: string, effectTypeId: int, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shared/EffectAttributes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# EffectTypes: List All Possible Types
#
# GET /Shared/EffectTypes
# operationId: shared_effecttypes_get
export def "shared-effect-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, id: string, name: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Shared/EffectTypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# EffectTypes: Get By Type Id
#
# GET /Shared/EffectTypes/TypeId/{type_id}
# operationId: shared_effecttypes_typeid_get_type_id
export def "shared-effect-types-type-id get-effecttypes-typeid" [
  type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type_id: (encode-path-segment $type_id)} | format pattern "/Shared/EffectTypes/TypeId/{type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# EffectTypes: Get by Id
#
# GET /Shared/EffectTypes/{id}
# operationId: shared_effecttypes_get_id
export def "shared-effect-types get-effecttypes" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shared/EffectTypes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Effects: Get by Id
#
# GET /Shared/Effects/{id}
# operationId: shared_effects_get_id
export def "shared-effects get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<connectorId: string, effectMapId: string, id: string, name: string, shapeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shared/Effects/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# FillMap: Get by Id
#
# GET /Shared/FillMap/{id}
# operationId: shared_fillmap_get_id
export def "shared-fill-map get-fillmap" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<connectorId: string, effectAttributeId: string, fillTypeId: int, id: string, shapeId: string, tableCellId: string, themeBackgroundFillId: string, themeFillId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shared/FillMap/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# FillTypes: List All Possible Types
#
# GET /Shared/FillTypes
# operationId: shared_filltypes_get
export def "shared-fill-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, id: string, name: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Shared/FillTypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# FillTypes: Get By Type Id
#
# GET /Shared/FillTypes/TypeId/{type_id}
# operationId: shared_filltypes_typeid_get_type_id
export def "shared-fill-types-type-id get-filltypes-typeid" [
  type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type_id: (encode-path-segment $type_id)} | format pattern "/Shared/FillTypes/TypeId/{type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# FillTypes: Get by Id
#
# GET /Shared/FillTypes/{id}
# operationId: shared_filltypes_get_id
export def "shared-fill-types get-filltypes" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shared/FillTypes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GradientFills: Get by Id
#
# GET /Shared/GradientFills/{id}
# operationId: shared_gradientfills_get_id
export def "shared-gradient-fills get-gradientfills" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<angle: int, fillMapId: string, id: string, isPath: bool, pathType: string, rotateWithShape: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shared/GradientFills/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GradientStops: Get by Id
#
# GET /Shared/GradientStops/{id}
# operationId: shared_gradientstops_get_id
export def "shared-gradient-stops get-gradientstops" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<gradientFillsId: string, id: string, position: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shared/GradientStops/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# ImageFills: Get by Id
#
# GET /Shared/ImageFills/{id}
# operationId: shared_imagefills_get_id
export def "shared-image-fills get-imagefills" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<compressionState: string, dpi: int, effectsJson: string, fillMapId: string, id: string, rotateWithShape: bool, sourceRectangle: string, stretch: bool, tile: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shared/ImageFills/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# LineEndSizes: List All Possible Types
#
# GET /Shared/LineEndSizes
# operationId: shared_lineendsizes_get
export def "shared-line-end-sizes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, id: string, name: string, serializedAs: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Shared/LineEndSizes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# LineEndSizes: Get By Type Id
#
# GET /Shared/LineEndSizes/TypeId/{type_id}
# operationId: shared_lineendsizes_typeid_get_type_id
export def "shared-line-end-sizes-type-id get-lineendsizes-typeid" [
  type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string, serializedAs: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type_id: (encode-path-segment $type_id)} | format pattern "/Shared/LineEndSizes/TypeId/{type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# LineEndSizes: Get by Id
#
# GET /Shared/LineEndSizes/{id}
# operationId: shared_lineendsizes_get_id
export def "shared-line-end-sizes get-lineendsizes" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string, serializedAs: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shared/LineEndSizes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# LineEndTypes: List All Possible Types
#
# GET /Shared/LineEndTypes
# operationId: shared_lineendtypes_get
export def "shared-line-end-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, id: string, name: string, serializedAs: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Shared/LineEndTypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# LineEndTypes: Get By Type Id
#
# GET /Shared/LineEndTypes/TypeId/{type_id}
# operationId: shared_lineendtypes_typeid_get_type_id
export def "shared-line-end-types-type-id get-lineendtypes-typeid" [
  type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string, serializedAs: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type_id: (encode-path-segment $type_id)} | format pattern "/Shared/LineEndTypes/TypeId/{type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# LineEndTypes: Get by Id
#
# GET /Shared/LineEndTypes/{id}
# operationId: shared_lineendtypes_get_id
export def "shared-line-end-types get-lineendtypes" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string, serializedAs: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shared/LineEndTypes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lines: Get by Id
#
# GET /Shared/Lines/{id}
# operationId: shared_lines_get_id
export def "shared-lines get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bLtoTRBorderId: string, bottomBorderId: string, connectorId: string, dashTypeId: int, headEndHeightId: int, headEndTypeId: int, headEndWidthId: int, id: string, leftBorderId: string, lineMapId: string, rightBorderId: string, shapeId: string, tLtoBRBorderId: string, tailEndHeightId: int, tailEndTypeId: int, tailEndWidthId: int, topBorderId: string, weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shared/Lines/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Paragraph: Get by Id
#
# GET /Shared/Paragraph/{id}
# operationId: shared_paragraph_get_id
export def "shared-paragraph get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, number: int, textContainerId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shared/Paragraph/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# SolidFills: Get by Id
#
# GET /Shared/SolidFills/{id}
# operationId: shared_solidfills_get_id
export def "shared-solid-fills get-solidfills" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<colorTypeId: int, fillMapId: string, hexValue: string, id: string, isUserColor: bool, parentGradientStopId: string, parentLineId: string, parentTextId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shared/SolidFills/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Text: Get by Id
#
# GET /Shared/Text/{id}
# operationId: shared_text_get_id
export def "shared-text get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<colorSolidFillsId: string, font: string, fontSize: int, id: string, isBold: bool, isItalic: bool, isThemeFont: bool, isUnderline: bool, paragraphId: string, rawText: string, sequence: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shared/Text/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# TextContainer: Get by Id
#
# GET /Shared/TextContainer/{id}
# operationId: shared_textcontainer_get_id
export def "shared-text-container get-textcontainer" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<axisId: string, chartId: string, id: string, outerXml: string, shapeId: string, tableCellId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Shared/TextContainer/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Get Dependent Objects Tree
#
# GET /Slides/ChildObjects/{id}
# operationId: slides_slides_childobjects_get_id
export def "slides-child-objects get-childobjects" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Slides/ChildObjects/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# ColorMaps: Get by Id
#
# GET /Slides/ColorMaps/{id}
# operationId: slides_colormaps_get_id
export def "slides-color-maps get-colormaps" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accent1: int, accent2: int, accent3: int, accent4: int, accent5: int, accent6: int, background1: int, background2: int, followedHyperlink: int, hyperlink: int, id: string, slideMasterId: string, text1: int, text2: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Slides/ColorMaps/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Get Details
#
# GET /Slides/Details/{id}
# operationId: slides_slides_details_get_id
export def "slides-details get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, document: record<baseElementBlobUrl: string, blobLocation: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, documentTypeId: int, filename: string, id: string, name: string, ownerGuid: string, packageUri: string, slides: list<any>, storyId: string, tableStylesXmlBlobUrl: string, title: string, userCreated: string, userModified: string>, documentId: string, id: string, name: string, number: int, ooxmlId: int, packageUri: string, shapeTree: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: record<childGroupElements: list, connector: record, dateCreated: string, dateModified: string, graphic: record, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record, shapeTree: any, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementId: string, groupElements: list<record>, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, slide: any, slideId: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, slideDocumentUrl: string, slideMaster: record<colorMap: record<accent1: int, accent2: int, accent3: int, accent4: int, accent5: int, accent6: int, background1: int, background2: int, dateCreated: string, dateModified: string, followedHyperlink: int, hyperlink: int, id: string, slideMaster: any, slideMasterId: string, text1: int, text2: int, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, id: string, parentSlide: any, slideId: string, userCreated: string, userModified: string>, svgBlobUrl: string, theme: record<backgroundFills: list<record>, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, colors: record<accent1: string, accent2: string, accent3: string, accent4: string, accent5: string, accent6: string, dark1: string, dark2: string, dateCreated: string, dateModified: string, followedHyperlink: string, hyperlink: string, id: string, light1: string, light2: string, name: string, theme: any, themeId: string, userCreated: string, userModified: string>, customColors: list<record>, dateCreated: string, dateModified: string, effectMaps: list<record>, fills: list<record>, fonts: record<bodyFont: string, dateCreated: string, dateModified: string, headingFont: string, id: string, theme: any, themeId: string, userCreated: string, userModified: string>, id: string, lineMaps: list<record>, name: string, packageUri: string, slide: any, slideId: string, userCreated: string, userModified: string>, userCreated: string, userModified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Slides/Details/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GraphicTypes: List All Possible Types
#
# GET /Slides/GraphicTypes
# operationId: slides_graphictypes_get
export def "slides-graphic-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, id: string, name: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Slides/GraphicTypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GraphicTypes: Get By Type Id
#
# GET /Slides/GraphicTypes/TypeId/{type_id}
# operationId: slides_graphictypes_typeid_get_type_id
export def "slides-graphic-types-type-id get-graphictypes-typeid" [
  type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type_id: (encode-path-segment $type_id)} | format pattern "/Slides/GraphicTypes/TypeId/{type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GraphicTypes: Get by Id
#
# GET /Slides/GraphicTypes/{id}
# operationId: slides_graphictypes_get_id
export def "slides-graphic-types get-graphictypes" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Slides/GraphicTypes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Graphics: Get by Id
#
# GET /Slides/Graphics/{id}
# operationId: slides_graphics_get_id
export def "slides-graphics get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<graphicTypeId: int, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, width: int, xOffset: int, yOffset: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Slides/Graphics/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GroupElementTypes: List All Possible Types
#
# GET /Slides/GroupElementTypes
# operationId: slides_groupelementtypes_get
export def "slides-group-element-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, id: string, name: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Slides/GroupElementTypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GroupElementTypes: Get By Type Id
#
# GET /Slides/GroupElementTypes/TypeId/{type_id}
# operationId: slides_groupelementtypes_typeid_get_type_id
export def "slides-group-element-types-type-id get-groupelementtypes-typeid" [
  type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type_id: (encode-path-segment $type_id)} | format pattern "/Slides/GroupElementTypes/TypeId/{type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GroupElementTypes: Get by Id
#
# GET /Slides/GroupElementTypes/{id}
# operationId: slides_groupelementtypes_get_id
export def "slides-group-element-types get-groupelementtypes" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Slides/GroupElementTypes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GroupElements: Get by Id
#
# GET /Slides/GroupElements/{id}
# operationId: slides_groupelements_get_id
export def "slides-group-elements get-groupelements" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElementId: string, shapeTreeId: string, ultimateParentShapeTreeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Slides/GroupElements/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Get Underlying Xml
#
# GET /Slides/OpenOfficeXml/{id}
# operationId: slides_slides_openofficexml_get_id_updated
export def "slides-open-office-xml get-openofficexml-updated" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated: oneof<nothing, bool> # Indicates whether API should return the orginal uploaded xml (false) or the actively updated version (true, default) (default: true)
]: nothing -> record<id: string, openOfficeXml: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updated" $updated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Slides/OpenOfficeXml/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Modify Underlying Xml
#
# PUT /Slides/OpenOfficeXml/{id}
# operationId: slides_slides_openofficexml_put_id
export def "slides-open-office-xml update-openofficexml" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string # nullable, format: uuid
  --open-office-xml: string # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Slides/OpenOfficeXml/{id}"))
  let req_body = {"id": $body_id, "openOfficeXml": $open_office_xml, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# SlideMasters: Get by Id
#
# GET /Slides/SlideMasters/{id}
# operationId: slides_slidemasters_get_id
export def "slides-slide-masters get-slidemasters" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, slideId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Slides/SlideMasters/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Get Svg file
#
# GET /Slides/Svg/{id}
# operationId: slides_slides_svg_get_id_use_cache
export def "slides-svg get-use-cache" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --use-cache: oneof<nothing, bool> # Indicates whether API should retrieve content from a cache if aviable (true, default), or force an update (false) (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "use_cache" $use_cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Slides/Svg/{id}") $qp)
  let accept_val = "image/svg+xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Get by Id
#
# GET /Slides/{id}
# operationId: slides_slides_get_id
export def "slides get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, documentId: string, id: string, name: string, number: int, ooxmlId: int, packageUri: string, slideDocumentUrl: string, svgBlobUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Slides/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Get Dependent Objects Tree
#
# GET /SmartArts/ChildObjects/{id}
# operationId: slides_smartarts_childobjects_get_id
export def "smart-arts-child-objects get-slides-smartarts-childobjects" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/SmartArts/ChildObjects/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Get Details
#
# GET /SmartArts/Details/{id}
# operationId: slides_smartarts_details_get_id
export def "smart-arts-details get-slides-smartarts" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, graphicsId: string, id: string, name: string, packageUri: string, parentGraphic: record<chart: record<axes: list, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, chartData: record, dateCreated: string, dateModified: string, id: string, name: string, packageUri: string, parentGraphic: any, parentGraphicId: string, svgBlobUrl: string, titleTextContainer: record, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: record<childGroupElements: list, connector: record, dateCreated: string, dateModified: string, graphic: any, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record, shapeTree: record, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, fileExtension: string, graphicsId: string, id: string, imageFileBlobUrl: string, imageFill: record, imageFillsId: string, name: string, packageUri: string, parentGraphic: any, userCreated: string, userModified: string>, smartArt: any, table: record<baseElementBlobUrl: string, cells: list, changedBaseElementBlobUrl: string, columns: list, dateCreated: string, dateModified: string, hasStylePart: bool, id: string, name: string, packageUri: string, parentGraphic: any, parentGraphicId: string, rows: list, stylePartOuterXml: string, svgBlobUrl: string, userCreated: string, userModified: string>, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, svgBlobUrl: string, userCreated: string, userModified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/SmartArts/Details/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Get Underlying Xml
#
# GET /SmartArts/OpenOfficeXml/{id}
# operationId: slides_smartarts_openofficexml_get_id_updated
export def "smart-arts-open-office-xml get-slides-smartarts-openofficexml-updated" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated: oneof<nothing, bool> # Indicates whether API should return the orginal uploaded xml (false) or the actively updated version (true, default) (default: true)
]: nothing -> record<id: string, openOfficeXml: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updated" $updated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/SmartArts/OpenOfficeXml/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Slides: Modify Underlying Xml
#
# PUT /SmartArts/OpenOfficeXml/{id}
# operationId: slides_smartarts_openofficexml_put_id
export def "smart-arts-open-office-xml update-slides-smartarts-openofficexml" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string # nullable, format: uuid
  --open-office-xml: string # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/SmartArts/OpenOfficeXml/{id}"))
  let req_body = {"id": $body_id, "openOfficeXml": $open_office_xml, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Slides: Get Svg file
#
# GET /SmartArts/Svg/{id}
# operationId: slides_smartarts_svg_get_id_use_cache
export def "smart-arts-svg get-slides-smartarts-use-cache" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --use-cache: oneof<nothing, bool> # Indicates whether API should retrieve content from a cache if aviable (true, default), or force an update (false) (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "use_cache" $use_cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/SmartArts/Svg/{id}") $qp)
  let accept_val = "image/svg+xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# SmartArts: Get by Id
#
# GET /SmartArts/{id}
# operationId: slides_smartarts_get_id
export def "smart-arts get-slides-smartarts" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, graphicsId: string, id: string, name: string, packageUri: string, svgBlobUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/SmartArts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Borders: Get by Id
#
# GET /Tables/Borders/{id}
# operationId: tables_borders_get_id
export def "tables-borders get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cellId: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Tables/Borders/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Cells: Get by Id
#
# GET /Tables/Cells/{id}
# operationId: tables_cells_get_id
export def "tables-cells get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<columnId: string, columnSpan: int, id: string, isMergedHorozontal: bool, isMergedVertical: bool, rowId: string, rowSpan: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Tables/Cells/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Tables: Get Dependent Objects Tree
#
# GET /Tables/ChildObjects/{id}
# operationId: tables_tables_childobjects_get_id
export def "tables-child-objects get-childobjects" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Tables/ChildObjects/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Columns: Get by Id
#
# GET /Tables/Columns/{id}
# operationId: tables_columns_get_id
export def "tables-columns get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, index: int, tableId: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Tables/Columns/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Tables: Get Details
#
# GET /Tables/Details/{id}
# operationId: tables_tables_details_get_id
export def "tables-details get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<baseElementBlobUrl: string, cells: table<border: record, column: record, columnId: string, columnSpan: int, dateCreated: string, dateModified: string, fillMap: record, id: string, isMergedHorozontal: bool, isMergedVertical: bool, row: record, rowId: string, rowSpan: int, textContainer: record, userCreated: string, userModified: string>, changedBaseElementBlobUrl: string, columns: table<cells: list, dateCreated: string, dateModified: string, id: string, index: int, table: any, tableId: string, userCreated: string, userModified: string, width: int>, dateCreated: string, dateModified: string, hasStylePart: bool, id: string, name: string, packageUri: string, parentGraphic: record<chart: record<axes: list, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, chartData: record, dateCreated: string, dateModified: string, id: string, name: string, packageUri: string, parentGraphic: any, parentGraphicId: string, svgBlobUrl: string, titleTextContainer: record, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: record<childGroupElements: list, connector: record, dateCreated: string, dateModified: string, graphic: any, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record, shapeTree: record, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, fileExtension: string, graphicsId: string, id: string, imageFileBlobUrl: string, imageFill: record, imageFillsId: string, name: string, packageUri: string, parentGraphic: any, userCreated: string, userModified: string>, smartArt: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, graphicsId: string, id: string, name: string, packageUri: string, parentGraphic: any, svgBlobUrl: string, userCreated: string, userModified: string>, table: any, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, parentGraphicId: string, rows: table<cells: list, dateCreated: string, dateModified: string, height: int, id: string, index: int, table: any, tableId: string, userCreated: string, userModified: string>, stylePartOuterXml: string, svgBlobUrl: string, userCreated: string, userModified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Tables/Details/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Tables: Get Underlying Xml
#
# GET /Tables/OpenOfficeXml/{id}
# operationId: tables_tables_openofficexml_get_id_updated
export def "tables-open-office-xml get-openofficexml-updated" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated: oneof<nothing, bool> # Indicates whether API should return the orginal uploaded xml (false) or the actively updated version (true, default) (default: true)
]: nothing -> record<id: string, openOfficeXml: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updated" $updated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Tables/OpenOfficeXml/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Tables: Modify Underlying Xml
#
# PUT /Tables/OpenOfficeXml/{id}
# operationId: tables_tables_openofficexml_put_id
export def "tables-open-office-xml update-openofficexml" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string # nullable, format: uuid
  --open-office-xml: string # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Tables/OpenOfficeXml/{id}"))
  let req_body = {"id": $body_id, "openOfficeXml": $open_office_xml, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Rows: Get by Id
#
# GET /Tables/Rows/{id}
# operationId: tables_rows_get_id
export def "tables-rows get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<height: int, id: string, index: int, tableId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Tables/Rows/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Tables: Get Svg file
#
# GET /Tables/Svg/{id}
# operationId: tables_tables_svg_get_id_use_cache
export def "tables-svg get-use-cache" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --use-cache: oneof<nothing, bool> # Indicates whether API should retrieve content from a cache if aviable (true, default), or force an update (false) (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "use_cache" $use_cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Tables/Svg/{id}") $qp)
  let accept_val = "image/svg+xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Table: Get Table Data
#
# GET /Tables/TableUpdate/{id}
# operationId: tables_tables_tableupdate_get_id
export def "tables-table-update get-tableupdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tableData: list<list<string>>, tableId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Tables/TableUpdate/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Tables: Update Table Data
#
# PUT /Tables/TableUpdate/{id}
# operationId: tables_tables_tableupdate_put_id
export def "tables-table-update update-tableupdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --table-data: list # nullable
  --table-id: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Tables/TableUpdate/{id}"))
  let req_body = {"tableData": $table_data, "tableId": $table_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Tables: Get by Id
#
# GET /Tables/{id}
# operationId: tables_tables_get_id
export def "tables get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, hasStylePart: bool, id: string, name: string, packageUri: string, parentGraphicId: string, stylePartOuterXml: string, svgBlobUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Tables/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# BackgroundFills: Get by Id
#
# GET /Themes/BackgroundFills/{id}
# operationId: themes_backgroundfills_get_id
export def "themes-background-fills get-backgroundfills" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, intensityId: int, themeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Themes/BackgroundFills/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Theme: Get Dependent Objects Tree
#
# GET /Themes/ChildObjects/{id}
# operationId: theme_themes_childobjects_get_id
export def "themes-child-objects get-childobjects" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Themes/ChildObjects/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Colors: Get by Id
#
# GET /Themes/Colors/{id}
# operationId: themes_colors_get_id
export def "themes-colors get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accent1: string, accent2: string, accent3: string, accent4: string, accent5: string, accent6: string, dark1: string, dark2: string, followedHyperlink: string, hyperlink: string, id: string, light1: string, light2: string, name: string, themeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Themes/Colors/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# CustomColors: Get by Id
#
# GET /Themes/CustomColors/{id}
# operationId: themes_customcolors_get_id
export def "themes-custom-colors get-customcolors" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<hexValue: string, id: string, name: string, themeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Themes/CustomColors/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Theme: Get Details
#
# GET /Themes/Details/{id}
# operationId: theme_themes_details_get_id
export def "themes-details get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<backgroundFills: table<dateCreated: string, dateModified: string, fillMap: record, id: string, intensityId: int, theme: any, themeId: string, userCreated: string, userModified: string>, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, colors: record<accent1: string, accent2: string, accent3: string, accent4: string, accent5: string, accent6: string, dark1: string, dark2: string, dateCreated: string, dateModified: string, followedHyperlink: string, hyperlink: string, id: string, light1: string, light2: string, name: string, theme: any, themeId: string, userCreated: string, userModified: string>, customColors: table<dateCreated: string, dateModified: string, hexValue: string, id: string, name: string, theme: any, themeId: string, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, effectMaps: table<dateCreated: string, dateModified: string, effect: record, id: string, intensityId: int, theme: any, themeId: string, userCreated: string, userModified: string>, fills: table<dateCreated: string, dateModified: string, fillMap: record, id: string, intensityId: int, theme: any, themeId: string, userCreated: string, userModified: string>, fonts: record<bodyFont: string, dateCreated: string, dateModified: string, headingFont: string, id: string, theme: any, themeId: string, userCreated: string, userModified: string>, id: string, lineMaps: table<dateCreated: string, dateModified: string, id: string, intensityId: int, line: record, theme: any, themeId: string, userCreated: string, userModified: string>, name: string, packageUri: string, slide: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, document: record<baseElementBlobUrl: string, blobLocation: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, documentTypeId: int, filename: string, id: string, name: string, ownerGuid: string, packageUri: string, slides: list, storyId: string, tableStylesXmlBlobUrl: string, title: string, userCreated: string, userModified: string>, documentId: string, id: string, name: string, number: int, ooxmlId: int, packageUri: string, shapeTree: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: record, groupElementId: string, groupElements: list, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, slide: any, slideId: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, slideDocumentUrl: string, slideMaster: record<colorMap: record, dateCreated: string, dateModified: string, id: string, parentSlide: any, slideId: string, userCreated: string, userModified: string>, svgBlobUrl: string, theme: any, userCreated: string, userModified: string>, slideId: string, userCreated: string, userModified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Themes/Details/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# EffectMap: Get by Id
#
# GET /Themes/EffectMap/{id}
# operationId: themes_effectmap_get_id
export def "themes-effect-map get-effectmap" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, intensityId: int, themeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Themes/EffectMap/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Fills: Get by Id
#
# GET /Themes/Fills/{id}
# operationId: themes_fills_get_id
export def "themes-fills get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, intensityId: int, themeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Themes/Fills/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Fonts: Get by Id
#
# GET /Themes/Fonts/{id}
# operationId: themes_fonts_get_id
export def "themes-fonts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bodyFont: string, headingFont: string, id: string, themeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Themes/Fonts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Intensity: List All Possible Types
#
# GET /Themes/Intensity
# operationId: themes_intensity_get
export def "themes-intensity list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, id: string, name: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Themes/Intensity")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Intensity: Get By Type Id
#
# GET /Themes/Intensity/TypeId/{type_id}
# operationId: themes_intensity_typeid_get_type_id
export def "themes-intensity-type-id get-typeid" [
  type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type_id: (encode-path-segment $type_id)} | format pattern "/Themes/Intensity/TypeId/{type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Intensity: Get by Id
#
# GET /Themes/Intensity/{id}
# operationId: themes_intensity_get_id
export def "themes-intensity get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Themes/Intensity/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# LineMap: Get by Id
#
# GET /Themes/LineMap/{id}
# operationId: themes_linemap_get_id
export def "themes-line-map get-linemap" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, intensityId: int, themeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Themes/LineMap/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Theme: Get Underlying Xml
#
# GET /Themes/OpenOfficeXml/{id}
# operationId: theme_themes_openofficexml_get_id_updated
export def "themes-open-office-xml get-openofficexml-updated" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated: oneof<nothing, bool> # Indicates whether API should return the orginal uploaded xml (false) or the actively updated version (true, default) (default: true)
]: nothing -> record<id: string, openOfficeXml: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updated" $updated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Themes/OpenOfficeXml/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Theme: Modify Underlying Xml
#
# PUT /Themes/OpenOfficeXml/{id}
# operationId: theme_themes_openofficexml_put_id
export def "themes-open-office-xml update-openofficexml" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string # nullable, format: uuid
  --open-office-xml: string # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Themes/OpenOfficeXml/{id}"))
  let req_body = {"id": $body_id, "openOfficeXml": $open_office_xml, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Theme: Get Svg file
#
# GET /Themes/Svg/{id}
# operationId: theme_themes_svg_get_id_use_cache
export def "themes-svg get-use-cache" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --use-cache: oneof<nothing, bool> # Indicates whether API should retrieve content from a cache if aviable (true, default), or force an update (false) (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "use_cache" $use_cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Themes/Svg/{id}") $qp)
  let accept_val = "image/svg+xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Themes: Get by Id
#
# GET /Themes/{id}
# operationId: theme_themes_get_id
export def "themes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, id: string, name: string, packageUri: string, slideId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Themes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
