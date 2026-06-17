# Auto-generated client for LinQR v2.0
# Source: https://api.apis.guru/v2/specs/linqr.app/2.0/openapi.json
# Auth: --token flag or $env.LINQR_TOKEN

const BASE_URL = "https://run.byvalue.org"
const DEFAULT_AUTH = "byvalue-token"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LINQR_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "byvalue-token" => { {headers: {Byvalue-Token: $token_val}, query: ""} }
    "x-rapidapi-key" => { {headers: {X-RapidAPI-Key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://run.byvalue.org" "https://qrcode3.p.rapidapi.com"] }
def auth-scheme-completer [] { ["byvalue-token" "x-rapidapi-key"] }

# Completers for enum parameters
def accept-completer [] { ["application/gzip" "application/zip"] }
def accept-completer-1 [] { ["application/pdf" "application/postscript" "image/jpeg" "image/png" "image/svg+xml" "image/webp"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "batch-qrcode post" } } | get name | first)
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
export def "batch-qrcode post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  items: list # `items` property allows you to specify an array of QR Codes to generate. The elements of the array must be valid objects analogous to those required for single code generation. — item shape: {data: any, image?: any, output?: any, size?: any, style?: any}
  --output: any # `output` property allows you to specify the name and extension (type) of the file returned by the API (default: {filename: qrcodes, format: zip})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "byvalue-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/batch/qrcode")
  let body = {"items": $items, "output": $output} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/gzip")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created: string, id: string, size: int, source: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/images")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload image
#
# POST /images
# operationId: imageUpload_images_post
export def "images post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  image: string # Binary file to be uploaded into LinQR storage. Maximum single file size is 1MiB (1,048,576 bytes). (format: binary)
]: any -> record<created: string, id: string, size: int, source: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/images")
  let body = {"image": $image} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/images/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List image
#
# GET /images/{id}
# operationId: imageList_images__id__get
export def "images get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, id: string, size: int, source: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/images/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Arbitrary data type QR Code
#
# POST /qrcode
# operationId: dispatcher_qrcode_post
export def "qrcode post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  data: any # `data` property allows you to specify the data stored in the QR Code.
  --image: any # `image` property allows you to set parameters of a custom image (e.g. your company logo, icon etc.) placed in the center of the generated QR Code.
  --output: any # `output` property allows you to specify the name and extension (type) of the file returned by the API (default: {filename: qrcode, format: svg})
  --size: any # `size` property allows you to set the values that define the sizes of the generated QR Code. (default: {error_correction: M, quiet_zone: 4, width: 200})
  --style: any # `style` property allows you to select the appearance parameters of the modules and eyes of the generated QR Code.  All color specifications can be defined via: * CSS3 name: `Black`, `azure`, ... * hex value: `0x000`, `#FFFFFF`, `7fffd4`, ... * RGB/RGBA strings: `rgb(255, 255, 255)`, `rgba(255, 255, 255, 0.5)`, ... * HSL strings: `hsl(270, 60%, 70%)`, `hsl(270, 60%, 70%, .5)`, ...  Color values can be obtained from any online color picker like <a href="https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Colors/Color_picker_tool" rel="noopener noreferrer" target="_blank" >developer.mozilla.org</a>. (default: {background: {}, inner_eye: {shape: default}, module: {color: black, shape: default}, outer_eye: {shape: default}})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "byvalue-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/qrcode")
  let body = {"data": $data, "image": $image, "output": $output, "size": $size, "style": $style} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Contact QR Code
#
# POST /qrcode/contact
# operationId: dispatcher_qrcode_contact_post
export def "qrcode-contact post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  data: any # `data` property allows you to specify personal information stored as electronic business card in the QR Code. The number and type of supported properties may depend on the QR Code reader software support.
  --image: any # `image` property allows you to set parameters of a custom image (e.g. your company logo, icon etc.) placed in the center of the generated QR Code.
  --output: any # `output` property allows you to specify the name and extension (type) of the file returned by the API (default: {filename: qrcode, format: svg})
  --size: any # `size` property allows you to set the values that define the sizes of the generated QR Code. (default: {error_correction: M, quiet_zone: 4, width: 200})
  --style: any # `style` property allows you to select the appearance parameters of the modules and eyes of the generated QR Code.  All color specifications can be defined via: * CSS3 name: `Black`, `azure`, ... * hex value: `0x000`, `#FFFFFF`, `7fffd4`, ... * RGB/RGBA strings: `rgb(255, 255, 255)`, `rgba(255, 255, 255, 0.5)`, ... * HSL strings: `hsl(270, 60%, 70%)`, `hsl(270, 60%, 70%, .5)`, ...  Color values can be obtained from any online color picker like <a href="https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Colors/Color_picker_tool" rel="noopener noreferrer" target="_blank" >developer.mozilla.org</a>. (default: {background: {}, inner_eye: {shape: default}, module: {color: black, shape: default}, outer_eye: {shape: default}})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "byvalue-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/qrcode/contact")
  let body = {"data": $data, "image": $image, "output": $output, "size": $size, "style": $style} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cryptocurrency payment QR Code
#
# POST /qrcode/crypto
# operationId: dispatcher_qrcode_crypto_post
export def "qrcode-crypto post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  data: any # `data` property allows you to specify cryptocurrency payment parameters.
  --image: any # `image` property allows you to set parameters of a custom image (e.g. your company logo, icon etc.) placed in the center of the generated QR Code.
  --output: any # `output` property allows you to specify the name and extension (type) of the file returned by the API (default: {filename: qrcode, format: svg})
  --size: any # `size` property allows you to set the values that define the sizes of the generated QR Code. (default: {error_correction: M, quiet_zone: 4, width: 200})
  --style: any # `style` property allows you to select the appearance parameters of the modules and eyes of the generated QR Code.  All color specifications can be defined via: * CSS3 name: `Black`, `azure`, ... * hex value: `0x000`, `#FFFFFF`, `7fffd4`, ... * RGB/RGBA strings: `rgb(255, 255, 255)`, `rgba(255, 255, 255, 0.5)`, ... * HSL strings: `hsl(270, 60%, 70%)`, `hsl(270, 60%, 70%, .5)`, ...  Color values can be obtained from any online color picker like <a href="https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Colors/Color_picker_tool" rel="noopener noreferrer" target="_blank" >developer.mozilla.org</a>. (default: {background: {}, inner_eye: {shape: default}, module: {color: black, shape: default}, outer_eye: {shape: default}})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "byvalue-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/qrcode/crypto")
  let body = {"data": $data, "image": $image, "output": $output, "size": $size, "style": $style} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Email QR Code
#
# POST /qrcode/email
# operationId: dispatcher_qrcode_email_post
export def "qrcode-email post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  data: any # `data` property allows you to specify the e-mail template stored in the QR Code.
  --image: any # `image` property allows you to set parameters of a custom image (e.g. your company logo, icon etc.) placed in the center of the generated QR Code.
  --output: any # `output` property allows you to specify the name and extension (type) of the file returned by the API (default: {filename: qrcode, format: svg})
  --size: any # `size` property allows you to set the values that define the sizes of the generated QR Code. (default: {error_correction: M, quiet_zone: 4, width: 200})
  --style: any # `style` property allows you to select the appearance parameters of the modules and eyes of the generated QR Code.  All color specifications can be defined via: * CSS3 name: `Black`, `azure`, ... * hex value: `0x000`, `#FFFFFF`, `7fffd4`, ... * RGB/RGBA strings: `rgb(255, 255, 255)`, `rgba(255, 255, 255, 0.5)`, ... * HSL strings: `hsl(270, 60%, 70%)`, `hsl(270, 60%, 70%, .5)`, ...  Color values can be obtained from any online color picker like <a href="https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Colors/Color_picker_tool" rel="noopener noreferrer" target="_blank" >developer.mozilla.org</a>. (default: {background: {}, inner_eye: {shape: default}, module: {color: black, shape: default}, outer_eye: {shape: default}})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "byvalue-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/qrcode/email")
  let body = {"data": $data, "image": $image, "output": $output, "size": $size, "style": $style} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Geolocation QR Code
#
# POST /qrcode/geo
# operationId: dispatcher_qrcode_geo_post
export def "qrcode-geo post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  data: any # `data` property allows you to specify geographic location (map pin).
  --image: any # `image` property allows you to set parameters of a custom image (e.g. your company logo, icon etc.) placed in the center of the generated QR Code.
  --output: any # `output` property allows you to specify the name and extension (type) of the file returned by the API (default: {filename: qrcode, format: svg})
  --size: any # `size` property allows you to set the values that define the sizes of the generated QR Code. (default: {error_correction: M, quiet_zone: 4, width: 200})
  --style: any # `style` property allows you to select the appearance parameters of the modules and eyes of the generated QR Code.  All color specifications can be defined via: * CSS3 name: `Black`, `azure`, ... * hex value: `0x000`, `#FFFFFF`, `7fffd4`, ... * RGB/RGBA strings: `rgb(255, 255, 255)`, `rgba(255, 255, 255, 0.5)`, ... * HSL strings: `hsl(270, 60%, 70%)`, `hsl(270, 60%, 70%, .5)`, ...  Color values can be obtained from any online color picker like <a href="https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Colors/Color_picker_tool" rel="noopener noreferrer" target="_blank" >developer.mozilla.org</a>. (default: {background: {}, inner_eye: {shape: default}, module: {color: black, shape: default}, outer_eye: {shape: default}})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "byvalue-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/qrcode/geo")
  let body = {"data": $data, "image": $image, "output": $output, "size": $size, "style": $style} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Telephone QR Code
#
# POST /qrcode/phone
# operationId: dispatcher_qrcode_phone_post
export def "qrcode-phone post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  data: any # `data` property allows you to specify telephone number called.
  --image: any # `image` property allows you to set parameters of a custom image (e.g. your company logo, icon etc.) placed in the center of the generated QR Code.
  --output: any # `output` property allows you to specify the name and extension (type) of the file returned by the API (default: {filename: qrcode, format: svg})
  --size: any # `size` property allows you to set the values that define the sizes of the generated QR Code. (default: {error_correction: M, quiet_zone: 4, width: 200})
  --style: any # `style` property allows you to select the appearance parameters of the modules and eyes of the generated QR Code.  All color specifications can be defined via: * CSS3 name: `Black`, `azure`, ... * hex value: `0x000`, `#FFFFFF`, `7fffd4`, ... * RGB/RGBA strings: `rgb(255, 255, 255)`, `rgba(255, 255, 255, 0.5)`, ... * HSL strings: `hsl(270, 60%, 70%)`, `hsl(270, 60%, 70%, .5)`, ...  Color values can be obtained from any online color picker like <a href="https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Colors/Color_picker_tool" rel="noopener noreferrer" target="_blank" >developer.mozilla.org</a>. (default: {background: {}, inner_eye: {shape: default}, module: {color: black, shape: default}, outer_eye: {shape: default}})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "byvalue-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/qrcode/phone")
  let body = {"data": $data, "image": $image, "output": $output, "size": $size, "style": $style} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# SMS QR Code
#
# POST /qrcode/sms
# operationId: dispatcher_qrcode_sms_post
export def "qrcode-sms post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  data: any # `data` property allows you to specify SMS template.
  --image: any # `image` property allows you to set parameters of a custom image (e.g. your company logo, icon etc.) placed in the center of the generated QR Code.
  --output: any # `output` property allows you to specify the name and extension (type) of the file returned by the API (default: {filename: qrcode, format: svg})
  --size: any # `size` property allows you to set the values that define the sizes of the generated QR Code. (default: {error_correction: M, quiet_zone: 4, width: 200})
  --style: any # `style` property allows you to select the appearance parameters of the modules and eyes of the generated QR Code.  All color specifications can be defined via: * CSS3 name: `Black`, `azure`, ... * hex value: `0x000`, `#FFFFFF`, `7fffd4`, ... * RGB/RGBA strings: `rgb(255, 255, 255)`, `rgba(255, 255, 255, 0.5)`, ... * HSL strings: `hsl(270, 60%, 70%)`, `hsl(270, 60%, 70%, .5)`, ...  Color values can be obtained from any online color picker like <a href="https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Colors/Color_picker_tool" rel="noopener noreferrer" target="_blank" >developer.mozilla.org</a>. (default: {background: {}, inner_eye: {shape: default}, module: {color: black, shape: default}, outer_eye: {shape: default}})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "byvalue-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/qrcode/sms")
  let body = {"data": $data, "image": $image, "output": $output, "size": $size, "style": $style} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Text QR Code
#
# POST /qrcode/text
# operationId: dispatcher_qrcode_text_post
export def "qrcode-text post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  data: any # `data` property allows you to specify the text stored in the QR Code.
  --image: any # `image` property allows you to set parameters of a custom image (e.g. your company logo, icon etc.) placed in the center of the generated QR Code.
  --output: any # `output` property allows you to specify the name and extension (type) of the file returned by the API (default: {filename: qrcode, format: svg})
  --size: any # `size` property allows you to set the values that define the sizes of the generated QR Code. (default: {error_correction: M, quiet_zone: 4, width: 200})
  --style: any # `style` property allows you to select the appearance parameters of the modules and eyes of the generated QR Code.  All color specifications can be defined via: * CSS3 name: `Black`, `azure`, ... * hex value: `0x000`, `#FFFFFF`, `7fffd4`, ... * RGB/RGBA strings: `rgb(255, 255, 255)`, `rgba(255, 255, 255, 0.5)`, ... * HSL strings: `hsl(270, 60%, 70%)`, `hsl(270, 60%, 70%, .5)`, ...  Color values can be obtained from any online color picker like <a href="https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Colors/Color_picker_tool" rel="noopener noreferrer" target="_blank" >developer.mozilla.org</a>. (default: {background: {}, inner_eye: {shape: default}, module: {color: black, shape: default}, outer_eye: {shape: default}})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "byvalue-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/qrcode/text")
  let body = {"data": $data, "image": $image, "output": $output, "size": $size, "style": $style} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# WiFi QR Code
#
# POST /qrcode/wifi
# operationId: dispatcher_qrcode_wifi_post
export def "qrcode-wifi post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  data: any # `data` property allows you to specify specify the WiFi access point credentials stored in the QR Code.
  --image: any # `image` property allows you to set parameters of a custom image (e.g. your company logo, icon etc.) placed in the center of the generated QR Code.
  --output: any # `output` property allows you to specify the name and extension (type) of the file returned by the API (default: {filename: qrcode, format: svg})
  --size: any # `size` property allows you to set the values that define the sizes of the generated QR Code. (default: {error_correction: M, quiet_zone: 4, width: 200})
  --style: any # `style` property allows you to select the appearance parameters of the modules and eyes of the generated QR Code.  All color specifications can be defined via: * CSS3 name: `Black`, `azure`, ... * hex value: `0x000`, `#FFFFFF`, `7fffd4`, ... * RGB/RGBA strings: `rgb(255, 255, 255)`, `rgba(255, 255, 255, 0.5)`, ... * HSL strings: `hsl(270, 60%, 70%)`, `hsl(270, 60%, 70%, .5)`, ...  Color values can be obtained from any online color picker like <a href="https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Colors/Color_picker_tool" rel="noopener noreferrer" target="_blank" >developer.mozilla.org</a>. (default: {background: {}, inner_eye: {shape: default}, module: {color: black, shape: default}, outer_eye: {shape: default}})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "byvalue-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/qrcode/wifi")
  let body = {"data": $data, "image": $image, "output": $output, "size": $size, "style": $style} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
