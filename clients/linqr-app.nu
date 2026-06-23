# Auto-generated client for LinQR v2.0
# Source: https://api.apis.guru/v2/specs/linqr.app/2.0/openapi.json
# Auth: --token flag or $env.LINQR_TOKEN

const BASE_URL = "https://run.byvalue.org"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LINQR_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "byvalue-token" => { {scheme: $scheme, headers: {Byvalue-Token: $token_val}, query: "", location: "header"} }
    "x-rapidapi-key" => { {scheme: $scheme, headers: {X-RapidAPI-Key: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://run.byvalue.org" "https://qrcode3.p.rapidapi.com"] }
def auth-scheme-completer [] { ["byvalue-token" "x-rapidapi-key"] }

# Completers for enum parameters
def accept-completer [] { ["application/gzip" "application/zip"] }
def accept-completer-1 [] { ["application/pdf" "application/postscript" "image/jpeg" "image/png" "image/svg+xml" "image/webp"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "batch-qrcode create-qr-code" } } | get name | first)
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

# QR Code Batch
#
# POST /batch/qrcode
# operationId: qrCodeBatch_batch_qrcode_post
# --items item shape: {data: any, image?: any, output?: any, size?: any, style?: any}
export def "batch-qrcode create-qr-code" [
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
  items: list # `items` property allows you to specify an array of QR Codes to generate. The elements of the array must be valid objects analogous to those required for single code generation. — item shape: {data: any, image?: any, output?: any, size?: any, style?: any}
  --output: any # `output` property allows you to specify the name and extension (type) of the file returned by the API (default: {filename: qrcodes, format: zip})
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "byvalue-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/batch/qrcode")
  let req_body = {"items": $items, "output": $output} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/gzip")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List all images
#
# GET /images
# operationId: imageListAll_images_get
export def "images list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created: string, id: string, size: int, source: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/images")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Upload image
#
# POST /images
# operationId: imageUpload_images_post
export def "images upload-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  image: string # Binary file to be uploaded into LinQR storage. Maximum single file size is 1MiB (1,048,576 bytes). (format: binary)
]: any -> record<created: string, id: string, size: int, source: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/images")
  let req_body = {"image": $image} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["image"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Delete image
#
# DELETE /images/{id}
# operationId: imageDelete_images__id__delete
export def "images delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/images/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List image
#
# GET /images/{id}
# operationId: imageList_images__id__get
export def "images list-get" [
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
]: nothing -> record<created: string, id: string, size: int, source: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/images/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Arbitrary data type QR Code
#
# POST /qrcode
# operationId: dispatcher_qrcode_post
export def "qrcode create-dispatcher" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  data: any # `data` property allows you to specify the data stored in the QR Code.
  --image: any # `image` property allows you to set parameters of a custom image (e.g. your company logo, icon etc.) placed in the center of the generated QR Code.
  --output: any # `output` property allows you to specify the name and extension (type) of the file returned by the API (default: {filename: qrcode, format: svg})
  --size: any # `size` property allows you to set the values that define the sizes of the generated QR Code. (default: {error_correction: M, quiet_zone: 4, width: 200})
  --style: any # `style` property allows you to select the appearance parameters of the modules and eyes of the generated QR Code. All color specifications can be defined via: * CSS3 name: `Black`, `azure`, ... * hex value: `0x000`, `#FFFFFF`, `7fffd4`, ... * RGB/RGBA strings: `rgb(255, 255, 255)`, `rgba(255, 255, 255, 0.5)`, ... * HSL strings: `hsl(270, 60%, 70%)`, `hsl(270, 60%, 70%, .5)`, ... Color values can be obtained from any online color picker like developer.mozilla.org (https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Colors/Color_picker_tool). (default: {background: {}, inner_eye: {shape: default}, module: {color: black, shape: default}, outer_eye: {shape: default}})
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "byvalue-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/qrcode")
  let req_body = {"data": $data, "image": $image, "output": $output, "size": $size, "style": $style} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Contact QR Code
#
# POST /qrcode/contact
# operationId: dispatcher_qrcode_contact_post
export def "qrcode-contact create-dispatcher" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  data: any # `data` property allows you to specify personal information stored as electronic business card in the QR Code. The number and type of supported properties may depend on the QR Code reader software support.
  --image: any # `image` property allows you to set parameters of a custom image (e.g. your company logo, icon etc.) placed in the center of the generated QR Code.
  --output: any # `output` property allows you to specify the name and extension (type) of the file returned by the API (default: {filename: qrcode, format: svg})
  --size: any # `size` property allows you to set the values that define the sizes of the generated QR Code. (default: {error_correction: M, quiet_zone: 4, width: 200})
  --style: any # `style` property allows you to select the appearance parameters of the modules and eyes of the generated QR Code. All color specifications can be defined via: * CSS3 name: `Black`, `azure`, ... * hex value: `0x000`, `#FFFFFF`, `7fffd4`, ... * RGB/RGBA strings: `rgb(255, 255, 255)`, `rgba(255, 255, 255, 0.5)`, ... * HSL strings: `hsl(270, 60%, 70%)`, `hsl(270, 60%, 70%, .5)`, ... Color values can be obtained from any online color picker like developer.mozilla.org (https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Colors/Color_picker_tool). (default: {background: {}, inner_eye: {shape: default}, module: {color: black, shape: default}, outer_eye: {shape: default}})
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "byvalue-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/qrcode/contact")
  let req_body = {"data": $data, "image": $image, "output": $output, "size": $size, "style": $style} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Cryptocurrency payment QR Code
#
# POST /qrcode/crypto
# operationId: dispatcher_qrcode_crypto_post
export def "qrcode-crypto create-dispatcher" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  data: any # `data` property allows you to specify cryptocurrency payment parameters.
  --image: any # `image` property allows you to set parameters of a custom image (e.g. your company logo, icon etc.) placed in the center of the generated QR Code.
  --output: any # `output` property allows you to specify the name and extension (type) of the file returned by the API (default: {filename: qrcode, format: svg})
  --size: any # `size` property allows you to set the values that define the sizes of the generated QR Code. (default: {error_correction: M, quiet_zone: 4, width: 200})
  --style: any # `style` property allows you to select the appearance parameters of the modules and eyes of the generated QR Code. All color specifications can be defined via: * CSS3 name: `Black`, `azure`, ... * hex value: `0x000`, `#FFFFFF`, `7fffd4`, ... * RGB/RGBA strings: `rgb(255, 255, 255)`, `rgba(255, 255, 255, 0.5)`, ... * HSL strings: `hsl(270, 60%, 70%)`, `hsl(270, 60%, 70%, .5)`, ... Color values can be obtained from any online color picker like developer.mozilla.org (https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Colors/Color_picker_tool). (default: {background: {}, inner_eye: {shape: default}, module: {color: black, shape: default}, outer_eye: {shape: default}})
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "byvalue-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/qrcode/crypto")
  let req_body = {"data": $data, "image": $image, "output": $output, "size": $size, "style": $style} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Email QR Code
#
# POST /qrcode/email
# operationId: dispatcher_qrcode_email_post
export def "qrcode-email create-dispatcher" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  data: any # `data` property allows you to specify the e-mail template stored in the QR Code.
  --image: any # `image` property allows you to set parameters of a custom image (e.g. your company logo, icon etc.) placed in the center of the generated QR Code.
  --output: any # `output` property allows you to specify the name and extension (type) of the file returned by the API (default: {filename: qrcode, format: svg})
  --size: any # `size` property allows you to set the values that define the sizes of the generated QR Code. (default: {error_correction: M, quiet_zone: 4, width: 200})
  --style: any # `style` property allows you to select the appearance parameters of the modules and eyes of the generated QR Code. All color specifications can be defined via: * CSS3 name: `Black`, `azure`, ... * hex value: `0x000`, `#FFFFFF`, `7fffd4`, ... * RGB/RGBA strings: `rgb(255, 255, 255)`, `rgba(255, 255, 255, 0.5)`, ... * HSL strings: `hsl(270, 60%, 70%)`, `hsl(270, 60%, 70%, .5)`, ... Color values can be obtained from any online color picker like developer.mozilla.org (https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Colors/Color_picker_tool). (default: {background: {}, inner_eye: {shape: default}, module: {color: black, shape: default}, outer_eye: {shape: default}})
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "byvalue-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/qrcode/email")
  let req_body = {"data": $data, "image": $image, "output": $output, "size": $size, "style": $style} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Geolocation QR Code
#
# POST /qrcode/geo
# operationId: dispatcher_qrcode_geo_post
export def "qrcode-geo create-dispatcher" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  data: any # `data` property allows you to specify geographic location (map pin).
  --image: any # `image` property allows you to set parameters of a custom image (e.g. your company logo, icon etc.) placed in the center of the generated QR Code.
  --output: any # `output` property allows you to specify the name and extension (type) of the file returned by the API (default: {filename: qrcode, format: svg})
  --size: any # `size` property allows you to set the values that define the sizes of the generated QR Code. (default: {error_correction: M, quiet_zone: 4, width: 200})
  --style: any # `style` property allows you to select the appearance parameters of the modules and eyes of the generated QR Code. All color specifications can be defined via: * CSS3 name: `Black`, `azure`, ... * hex value: `0x000`, `#FFFFFF`, `7fffd4`, ... * RGB/RGBA strings: `rgb(255, 255, 255)`, `rgba(255, 255, 255, 0.5)`, ... * HSL strings: `hsl(270, 60%, 70%)`, `hsl(270, 60%, 70%, .5)`, ... Color values can be obtained from any online color picker like developer.mozilla.org (https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Colors/Color_picker_tool). (default: {background: {}, inner_eye: {shape: default}, module: {color: black, shape: default}, outer_eye: {shape: default}})
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "byvalue-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/qrcode/geo")
  let req_body = {"data": $data, "image": $image, "output": $output, "size": $size, "style": $style} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Telephone QR Code
#
# POST /qrcode/phone
# operationId: dispatcher_qrcode_phone_post
export def "qrcode-phone create-dispatcher" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  data: any # `data` property allows you to specify telephone number called.
  --image: any # `image` property allows you to set parameters of a custom image (e.g. your company logo, icon etc.) placed in the center of the generated QR Code.
  --output: any # `output` property allows you to specify the name and extension (type) of the file returned by the API (default: {filename: qrcode, format: svg})
  --size: any # `size` property allows you to set the values that define the sizes of the generated QR Code. (default: {error_correction: M, quiet_zone: 4, width: 200})
  --style: any # `style` property allows you to select the appearance parameters of the modules and eyes of the generated QR Code. All color specifications can be defined via: * CSS3 name: `Black`, `azure`, ... * hex value: `0x000`, `#FFFFFF`, `7fffd4`, ... * RGB/RGBA strings: `rgb(255, 255, 255)`, `rgba(255, 255, 255, 0.5)`, ... * HSL strings: `hsl(270, 60%, 70%)`, `hsl(270, 60%, 70%, .5)`, ... Color values can be obtained from any online color picker like developer.mozilla.org (https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Colors/Color_picker_tool). (default: {background: {}, inner_eye: {shape: default}, module: {color: black, shape: default}, outer_eye: {shape: default}})
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "byvalue-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/qrcode/phone")
  let req_body = {"data": $data, "image": $image, "output": $output, "size": $size, "style": $style} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# SMS QR Code
#
# POST /qrcode/sms
# operationId: dispatcher_qrcode_sms_post
export def "qrcode-sms create-dispatcher" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  data: any # `data` property allows you to specify SMS template.
  --image: any # `image` property allows you to set parameters of a custom image (e.g. your company logo, icon etc.) placed in the center of the generated QR Code.
  --output: any # `output` property allows you to specify the name and extension (type) of the file returned by the API (default: {filename: qrcode, format: svg})
  --size: any # `size` property allows you to set the values that define the sizes of the generated QR Code. (default: {error_correction: M, quiet_zone: 4, width: 200})
  --style: any # `style` property allows you to select the appearance parameters of the modules and eyes of the generated QR Code. All color specifications can be defined via: * CSS3 name: `Black`, `azure`, ... * hex value: `0x000`, `#FFFFFF`, `7fffd4`, ... * RGB/RGBA strings: `rgb(255, 255, 255)`, `rgba(255, 255, 255, 0.5)`, ... * HSL strings: `hsl(270, 60%, 70%)`, `hsl(270, 60%, 70%, .5)`, ... Color values can be obtained from any online color picker like developer.mozilla.org (https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Colors/Color_picker_tool). (default: {background: {}, inner_eye: {shape: default}, module: {color: black, shape: default}, outer_eye: {shape: default}})
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "byvalue-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/qrcode/sms")
  let req_body = {"data": $data, "image": $image, "output": $output, "size": $size, "style": $style} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Text QR Code
#
# POST /qrcode/text
# operationId: dispatcher_qrcode_text_post
export def "qrcode-text create-dispatcher" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  data: any # `data` property allows you to specify the text stored in the QR Code.
  --image: any # `image` property allows you to set parameters of a custom image (e.g. your company logo, icon etc.) placed in the center of the generated QR Code.
  --output: any # `output` property allows you to specify the name and extension (type) of the file returned by the API (default: {filename: qrcode, format: svg})
  --size: any # `size` property allows you to set the values that define the sizes of the generated QR Code. (default: {error_correction: M, quiet_zone: 4, width: 200})
  --style: any # `style` property allows you to select the appearance parameters of the modules and eyes of the generated QR Code. All color specifications can be defined via: * CSS3 name: `Black`, `azure`, ... * hex value: `0x000`, `#FFFFFF`, `7fffd4`, ... * RGB/RGBA strings: `rgb(255, 255, 255)`, `rgba(255, 255, 255, 0.5)`, ... * HSL strings: `hsl(270, 60%, 70%)`, `hsl(270, 60%, 70%, .5)`, ... Color values can be obtained from any online color picker like developer.mozilla.org (https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Colors/Color_picker_tool). (default: {background: {}, inner_eye: {shape: default}, module: {color: black, shape: default}, outer_eye: {shape: default}})
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "byvalue-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/qrcode/text")
  let req_body = {"data": $data, "image": $image, "output": $output, "size": $size, "style": $style} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# WiFi QR Code
#
# POST /qrcode/wifi
# operationId: dispatcher_qrcode_wifi_post
export def "qrcode-wifi create-dispatcher" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  data: any # `data` property allows you to specify specify the WiFi access point credentials stored in the QR Code.
  --image: any # `image` property allows you to set parameters of a custom image (e.g. your company logo, icon etc.) placed in the center of the generated QR Code.
  --output: any # `output` property allows you to specify the name and extension (type) of the file returned by the API (default: {filename: qrcode, format: svg})
  --size: any # `size` property allows you to set the values that define the sizes of the generated QR Code. (default: {error_correction: M, quiet_zone: 4, width: 200})
  --style: any # `style` property allows you to select the appearance parameters of the modules and eyes of the generated QR Code. All color specifications can be defined via: * CSS3 name: `Black`, `azure`, ... * hex value: `0x000`, `#FFFFFF`, `7fffd4`, ... * RGB/RGBA strings: `rgb(255, 255, 255)`, `rgba(255, 255, 255, 0.5)`, ... * HSL strings: `hsl(270, 60%, 70%)`, `hsl(270, 60%, 70%, .5)`, ... Color values can be obtained from any online color picker like developer.mozilla.org (https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Colors/Color_picker_tool). (default: {background: {}, inner_eye: {shape: default}, module: {color: black, shape: default}, outer_eye: {shape: default}})
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "byvalue-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/qrcode/wifi")
  let req_body = {"data": $data, "image": $image, "output": $output, "size": $size, "style": $style} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
