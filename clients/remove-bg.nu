# Auto-generated client for Background Removal API v1.0.0
# Source: https://api.apis.guru/v2/specs/remove.bg/1.0.0/openapi.json
# Auth: --token flag or $env.BACKGROUND_REMOVAL_API_TOKEN

const BASE_URL = "https://api.remove.bg/v1.0"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BACKGROUND_REMOVAL_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {X-API-Key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.remove.bg/v1.0"] }
def auth-scheme-completer [] { ["x-api-key"] }

# Completers for enum parameters
def channels-completer [] { ["alpha" "rgba"] }
def format-completer [] { ["auto" "jpg" "png" "zip"] }
def size-completer [] { ["auto" "full" "preview"] }
def type-completer [] { ["auto" "car" "person" "product"] }
def type-level-completer [] { ["1" "2" "latest" "none"] }
def accept-completer [] { ["application/json" "image/*"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account get" } } | get name | first)
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

# Fetch credit balance and free API calls.
#
# GET /account
export def "account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit an image to the remove.bg Improvement program * Contribute an image that remove.bg is currently not able to remove the background from properly * Help us make remove.bg better * Get better results for similiar images in the future  Notes:   * By submitting images through the API you agree to the <a target="_blank" rel="noopener" href="/ipc">Improvement Program Conditions</a>   * File size: up to 12MB   * up to 100 files per day. <br> Higher Rate Limits are available for Enterprise customers <a href="/support/contact?subject=Improvement+Program+Rate+Limit">upon request</a>.  Requires either an API Key to be provided in the `X-API-Key` request header or an OAuth 2.0 access token to be provided in the `Authorization` request header.  Please note that submissions are used on a best-effort basis and the extent of expected improvement varies depending on many factors, including the number of provided images, their complexity and visual similarity. Improvements usually take several weeks to become effective.
#
# POST /improve
export def "improve post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-file-b64: string # Source image file (base64-encoded string). (If this parameter is present, the other image source parameters must be empty.) (e.g. )
  --image-filename: string # Filename of the image, if not provided it will be autodetected form the submitted data. (e.g. car.jpg)
  --image-url: string # Source image URL. (If this parameter is present, the other image source parameters must be empty.) (e.g. https://www.remove.bg/example-hd.jpg)
  --tag: string # Images with the same tag are grouped together. (e.g. batch_1_2020)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/improve")
  let body = {"image_file_b64": $image_file_b64, "image_filename": $image_filename, "image_url": $image_url, "tag": $tag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove the background of an image
#
# POST /removebg
export def "removebg post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --add-shadow: oneof<nothing, bool> # Whether to add an artificial shadow to the result (default: false). NOTE: Adding shadows is currently only supported for car photos. Other subjects are returned without shadow, even if set to true (this might change in the future).  (default: false)
  --bg-color: string # Adds a solid color background. Can be a hex color code (e.g. 81d4fa, fff) or a color name (e.g. green). For semi-transparency, 4-/8-digit hex codes are also supported (e.g. 81d4fa77). (If this parameter is present, the other bg_ parameters must be empty.)  (e.g. )
  --bg-image-url: string # Adds a background image from a URL. The image is centered and resized to fill the canvas while preserving the aspect ratio, unless it already has the exact same dimensions as the foreground image. (If this parameter is present, the other bg_ parameters must be empty.) (e.g. )
  --channels: string@channels-completer # Request either the finalized image ("rgba", default) or an alpha mask ("alpha"). Note: Since remove.bg also applies RGB color corrections on edges, using only the alpha mask often leads to a lower final image quality. Therefore "rgba" is recommended.  (default: rgba)
  --crop: oneof<nothing, bool> # Whether to crop off all empty regions (default: false). Note that cropping has no effect on the amount of charged credits.  (default: false)
  --crop-margin: string # Adds a margin around the cropped subject (default: 0). Can be an absolute value (e.g. "30px") or relative to the subject size (e.g. "10%"). Can be a single value (all sides), two values (top/bottom and left/right) or four values (top, right, bottom, left). This parameter only has an effect when "crop=true". The maximum margin that can be added on each side is 50% of the subject dimensions or 500 pixels.  (default: 0)
  --format: string@format-completer # Result image format: "auto" = Use PNG format if transparent regions exist, otherwise use JPG format (default), "png" = PNG format with alpha transparency, "jpg" = JPG format, no transparency, "zip" = ZIP format, contains color image and alpha matte image, supports transparency (recommended).  (default: auto)
  --image-file-b64: string # Source image file (base64-encoded string). (If this parameter is present, the other image source parameters must be empty.) (e.g. )
  --image-url: string # Source image URL. (If this parameter is present, the other image source parameters must be empty.) (e.g. https://www.remove.bg/example-hd.jpg)
  --position: string # Positions the subject within the image canvas. Can be "original" (default unless "scale" is given), "center" (default when "scale" is given) or a value from "0%" to "100%" (both horizontal and vertical) or two values (horizontal, vertical).  (default: original)
  --roi: string # Region of interest: Only contents of this rectangular region can be detected as foreground. Everything outside is considered background and will be removed. The rectangle is defined as two x/y coordinates in the format "x1 y1 x2 y2". The coordinates can be in absolute pixels (suffix 'px') or relative to the width/height of the image (suffix '%'). By default, the whole image is the region of interest ("0% 0% 100% 100%").  (default: 0% 0% 100% 100%)
  --scale: string # Scales the subject relative to the total image size. Can be any value from "10%" to "100%", or "original" (default). Scaling the subject implies "position=center" (unless specified otherwise).  (default: original)
  --semitransparency: oneof<nothing, bool> # Whether to have semi-transparent regions in the result (default: true). NOTE: Semitransparency is currently only supported for car windows (this might change in the future). Other objects are returned without semitransparency, even if set to true.  (default: true)
  --size: string@size-completer # Maximum output image resolution: "preview" (default) = Resize image to 0.25 megapixels (e.g. 625×400 pixels) – 0.25 credits per image, "full" = Use original image resolution, up to 25 megapixels (e.g. 6250x4000) with formats ZIP or JPG, or up to 10 megapixels (e.g. 4000x2500) with PNG – 1 credit per image), "auto" = Use highest available resolution (based on image size and available credits).  For backwards-compatibility this parameter also accepts the values "medium" (up to 1.5 megapixels) and "hd" (up to 4 megapixels) for 1 credit per image. The value "full" is also available under the name "4k" and the value "preview" is aliased as "small" and "regular".  (default: preview)
  --type: string@type-completer # Foreground type: "auto" = Automatically detect kind of foreground, "person" = Use person(s) as foreground, "product" = Use product(s) as foreground. "car" = Use car as foreground,  (default: auto)
  --type-level: string@type-level-completer # Classification level of the detected foreground type: "none" = No classification (X-Type Header won't bet set on the response) "1" = Use coarse classification classes: [person, product, animal, car, other] "2" = Use more specific classification classes: [person, product, animal, car, car_interior, car_part, transportation, graphics, other] "latest" = Always use the latest classification classes available  (default: 1)
]: any -> record<data: record<foreground_height: int, foreground_left: int, foreground_top: int, foreground_width: int, result_b64: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/removebg")
  let body = {"add_shadow": $add_shadow, "bg_color": $bg_color, "bg_image_url": $bg_image_url, "channels": $channels, "crop": $crop, "crop_margin": $crop_margin, "format": $format, "image_file_b64": $image_file_b64, "image_url": $image_url, "position": $position, "roi": $roi, "scale": $scale, "semitransparency": $semitransparency, "size": $size, "type": $type, "type_level": $type_level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
