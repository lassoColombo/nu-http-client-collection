# Auto-generated client for ocrapi vv1
# Source: https://api.apis.guru/v2/specs/cloudmersive.com/ocr/v1/openapi.json
# Auth: --token flag or $env.OCRAPI_TOKEN

const BASE_URL = "https://api.cloudmersive.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o OCRAPI_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "apikey" => { {scheme: $scheme, headers: {Apikey: $token_val}, query: "", location: "header"} }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
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

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body}.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk.
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

def base-url-completer [] { ["https://api.cloudmersive.com"] }
def auth-scheme-completer [] { ["apikey"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "ocr-image-to-lines-with-location create" } } | get name | first)
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

# Convert a scanned image into words with location
#
# POST /ocr/image/to/lines-with-location
# operationId: ImageOcr_ImageLinesWithLocation
export def "ocr-image-to-lines-with-location create" [
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
  --language: string # Optional, language of the input document, default is English (ENG). Possible values are ENG (English), ARA (Arabic), ZHO (Chinese - Simplified), ZHO-HANT (Chinese - Traditional), ASM (Assamese), AFR (Afrikaans), AMH (Amharic), AZE (Azerbaijani), AZE-CYRL (Azerbaijani - Cyrillic), BEL (Belarusian), BEN (Bengali), BOD (Tibetan), BOS (Bosnian), BUL (Bulgarian), CAT (Catalan; Valencian), CEB (Cebuano), CES (Czech), CHR (Cherokee), CYM (Welsh), DAN (Danish), DEU (German), DZO (Dzongkha), ELL (Greek), ENM (Archaic/Middle English), EPO (Esperanto), EST (Estonian), EUS (Basque), FAS (Persian), FIN (Finnish), FRA (French), FRK (Frankish), FRM (Middle-French), GLE (Irish), GLG (Galician), GRC (Ancient Greek), HAT (Hatian), HEB (Hebrew), HIN (Hindi), HRV (Croatian), HUN (Hungarian), IKU (Inuktitut), IND (Indonesian), ISL (Icelandic), ITA (Italian), ITA-OLD (Old - Italian), JAV (Javanese), JPN (Japanese), KAN (Kannada), KAT (Georgian), KAT-OLD (Old-Georgian), KAZ (Kazakh), KHM (Central Khmer), KIR (Kirghiz), KOR (Korean), KUR (Kurdish), LAO (Lao), LAT (Latin), LAV (Latvian), LIT (Lithuanian), MAL (Malayalam), MAR (Marathi), MKD (Macedonian), MLT (Maltese), MSA (Malay), MYA (Burmese), NEP (Nepali), NLD (Dutch), NOR (Norwegian), ORI (Oriya), PAN (Panjabi), POL (Polish), POR (Portuguese), PUS (Pushto), RON (Romanian), RUS (Russian), SAN (Sanskrit), SIN (Sinhala), SLK (Slovak), SLV (Slovenian), SPA (Spanish), SPA-OLD (Old Spanish), SQI (Albanian), SRP (Serbian), SRP-LAT (Latin Serbian), SWA (Swahili), SWE (Swedish), SYR (Syriac), TAM (Tamil), TEL (Telugu), TGK (Tajik), TGL (Tagalog), THA (Thai), TIR (Tigrinya), TUR (Turkish), UIG (Uighur), UKR (Ukrainian), URD (Urdu), UZB (Uzbek), UZB-CYR (Cyrillic Uzbek), VIE (Vietnamese), YID (Yiddish)
  --preprocessing: string # Optional, preprocessing mode, default is 'Auto'. Possible values are None (no preprocessing of the image), and Auto (automatic image enhancement of the image before OCR is applied; this is recommended).
  image_file: string # Image file to perform OCR on. Common file formats such as PNG, JPEG are supported. (format: binary)
]: any -> record<Lines: table<LineText: string, Words: list>, Successful: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ocr/image/to/lines-with-location" $auth.query)
  let req_body = {"imageFile": $image_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"language": $language, "preprocessing": $preprocessing} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["imageFile"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Convert a scanned image into words with location
#
# POST /ocr/image/to/words-with-location
# operationId: ImageOcr_ImageWordsWithLocation
export def "ocr-image-to-words-with-location create" [
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
  --language: string # Optional, language of the input document, default is English (ENG). Possible values are ENG (English), ARA (Arabic), ZHO (Chinese - Simplified), ZHO-HANT (Chinese - Traditional), ASM (Assamese), AFR (Afrikaans), AMH (Amharic), AZE (Azerbaijani), AZE-CYRL (Azerbaijani - Cyrillic), BEL (Belarusian), BEN (Bengali), BOD (Tibetan), BOS (Bosnian), BUL (Bulgarian), CAT (Catalan; Valencian), CEB (Cebuano), CES (Czech), CHR (Cherokee), CYM (Welsh), DAN (Danish), DEU (German), DZO (Dzongkha), ELL (Greek), ENM (Archaic/Middle English), EPO (Esperanto), EST (Estonian), EUS (Basque), FAS (Persian), FIN (Finnish), FRA (French), FRK (Frankish), FRM (Middle-French), GLE (Irish), GLG (Galician), GRC (Ancient Greek), HAT (Hatian), HEB (Hebrew), HIN (Hindi), HRV (Croatian), HUN (Hungarian), IKU (Inuktitut), IND (Indonesian), ISL (Icelandic), ITA (Italian), ITA-OLD (Old - Italian), JAV (Javanese), JPN (Japanese), KAN (Kannada), KAT (Georgian), KAT-OLD (Old-Georgian), KAZ (Kazakh), KHM (Central Khmer), KIR (Kirghiz), KOR (Korean), KUR (Kurdish), LAO (Lao), LAT (Latin), LAV (Latvian), LIT (Lithuanian), MAL (Malayalam), MAR (Marathi), MKD (Macedonian), MLT (Maltese), MSA (Malay), MYA (Burmese), NEP (Nepali), NLD (Dutch), NOR (Norwegian), ORI (Oriya), PAN (Panjabi), POL (Polish), POR (Portuguese), PUS (Pushto), RON (Romanian), RUS (Russian), SAN (Sanskrit), SIN (Sinhala), SLK (Slovak), SLV (Slovenian), SPA (Spanish), SPA-OLD (Old Spanish), SQI (Albanian), SRP (Serbian), SRP-LAT (Latin Serbian), SWA (Swahili), SWE (Swedish), SYR (Syriac), TAM (Tamil), TEL (Telugu), TGK (Tajik), TGL (Tagalog), THA (Thai), TIR (Tigrinya), TUR (Turkish), UIG (Uighur), UKR (Ukrainian), URD (Urdu), UZB (Uzbek), UZB-CYR (Cyrillic Uzbek), VIE (Vietnamese), YID (Yiddish)
  --preprocessing: string # Optional, preprocessing mode, default is 'Auto'. Possible values are None (no preprocessing of the image), and Auto (automatic image enhancement of the image before OCR is applied; this is recommended).
  image_file: string # Image file to perform OCR on. Common file formats such as PNG, JPEG are supported. (format: binary)
]: any -> record<Successful: bool, Words: table<BlockNumber: int, ConfidenceLevel: float, Height: int, LineNumber: int, PageNumber: int, ParagraphNumber: int, Width: int, WordNumber: int, WordText: string, XLeft: int, YTop: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ocr/image/to/words-with-location" $auth.query)
  let req_body = {"imageFile": $image_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"language": $language, "preprocessing": $preprocessing} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["imageFile"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Convert a scanned image into text
#
# POST /ocr/image/toText
# operationId: ImageOcr_Post
export def "ocr-image-to-text create" [
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
  --recognition-mode: string # Optional; possible values are 'Basic' which provides basic recognition and is not resillient to page rotation, skew or low quality images uses 1-2 API calls; 'Normal' which provides highly fault tolerant OCR recognition uses 26-30 API calls; and 'Advanced' which provides the highest quality and most fault-tolerant recognition uses 28-30 API calls. Default recognition mode is 'Advanced'
  --language: string # Optional, language of the input document, default is English (ENG). Possible values are ENG (English), ARA (Arabic), ZHO (Chinese - Simplified), ZHO-HANT (Chinese - Traditional), ASM (Assamese), AFR (Afrikaans), AMH (Amharic), AZE (Azerbaijani), AZE-CYRL (Azerbaijani - Cyrillic), BEL (Belarusian), BEN (Bengali), BOD (Tibetan), BOS (Bosnian), BUL (Bulgarian), CAT (Catalan; Valencian), CEB (Cebuano), CES (Czech), CHR (Cherokee), CYM (Welsh), DAN (Danish), DEU (German), DZO (Dzongkha), ELL (Greek), ENM (Archaic/Middle English), EPO (Esperanto), EST (Estonian), EUS (Basque), FAS (Persian), FIN (Finnish), FRA (French), FRK (Frankish), FRM (Middle-French), GLE (Irish), GLG (Galician), GRC (Ancient Greek), HAT (Hatian), HEB (Hebrew), HIN (Hindi), HRV (Croatian), HUN (Hungarian), IKU (Inuktitut), IND (Indonesian), ISL (Icelandic), ITA (Italian), ITA-OLD (Old - Italian), JAV (Javanese), JPN (Japanese), KAN (Kannada), KAT (Georgian), KAT-OLD (Old-Georgian), KAZ (Kazakh), KHM (Central Khmer), KIR (Kirghiz), KOR (Korean), KUR (Kurdish), LAO (Lao), LAT (Latin), LAV (Latvian), LIT (Lithuanian), MAL (Malayalam), MAR (Marathi), MKD (Macedonian), MLT (Maltese), MSA (Malay), MYA (Burmese), NEP (Nepali), NLD (Dutch), NOR (Norwegian), ORI (Oriya), PAN (Panjabi), POL (Polish), POR (Portuguese), PUS (Pushto), RON (Romanian), RUS (Russian), SAN (Sanskrit), SIN (Sinhala), SLK (Slovak), SLV (Slovenian), SPA (Spanish), SPA-OLD (Old Spanish), SQI (Albanian), SRP (Serbian), SRP-LAT (Latin Serbian), SWA (Swahili), SWE (Swedish), SYR (Syriac), TAM (Tamil), TEL (Telugu), TGK (Tajik), TGL (Tagalog), THA (Thai), TIR (Tigrinya), TUR (Turkish), UIG (Uighur), UKR (Ukrainian), URD (Urdu), UZB (Uzbek), UZB-CYR (Cyrillic Uzbek), VIE (Vietnamese), YID (Yiddish)
  --preprocessing: string # Optional, preprocessing mode, default is 'Auto'. Possible values are None (no preprocessing of the image), and Auto (automatic image enhancement of the image before OCR is applied; this is recommended).
  image_file: string # Image file to perform OCR on. Common file formats such as PNG, JPEG are supported. (format: binary)
]: any -> record<MeanConfidenceLevel: float, TextResult: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ocr/image/toText" $auth.query)
  let req_body = {"imageFile": $image_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"recognitionMode": $recognition_mode, "language": $language, "preprocessing": $preprocessing} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["imageFile"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Convert a PDF into text lines with location
#
# POST /ocr/pdf/to/lines-with-location
# operationId: PdfOcr_PdfToLinesWithLocation
export def "ocr-pdf-to-lines-with-location create" [
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
  --language: string # Optional, language of the input document, default is English (ENG). Possible values are ENG (English), ARA (Arabic), ZHO (Chinese - Simplified), ZHO-HANT (Chinese - Traditional), ASM (Assamese), AFR (Afrikaans), AMH (Amharic), AZE (Azerbaijani), AZE-CYRL (Azerbaijani - Cyrillic), BEL (Belarusian), BEN (Bengali), BOD (Tibetan), BOS (Bosnian), BUL (Bulgarian), CAT (Catalan; Valencian), CEB (Cebuano), CES (Czech), CHR (Cherokee), CYM (Welsh), DAN (Danish), DEU (German), DZO (Dzongkha), ELL (Greek), ENM (Archaic/Middle English), EPO (Esperanto), EST (Estonian), EUS (Basque), FAS (Persian), FIN (Finnish), FRA (French), FRK (Frankish), FRM (Middle-French), GLE (Irish), GLG (Galician), GRC (Ancient Greek), HAT (Hatian), HEB (Hebrew), HIN (Hindi), HRV (Croatian), HUN (Hungarian), IKU (Inuktitut), IND (Indonesian), ISL (Icelandic), ITA (Italian), ITA-OLD (Old - Italian), JAV (Javanese), JPN (Japanese), KAN (Kannada), KAT (Georgian), KAT-OLD (Old-Georgian), KAZ (Kazakh), KHM (Central Khmer), KIR (Kirghiz), KOR (Korean), KUR (Kurdish), LAO (Lao), LAT (Latin), LAV (Latvian), LIT (Lithuanian), MAL (Malayalam), MAR (Marathi), MKD (Macedonian), MLT (Maltese), MSA (Malay), MYA (Burmese), NEP (Nepali), NLD (Dutch), NOR (Norwegian), ORI (Oriya), PAN (Panjabi), POL (Polish), POR (Portuguese), PUS (Pushto), RON (Romanian), RUS (Russian), SAN (Sanskrit), SIN (Sinhala), SLK (Slovak), SLV (Slovenian), SPA (Spanish), SPA-OLD (Old Spanish), SQI (Albanian), SRP (Serbian), SRP-LAT (Latin Serbian), SWA (Swahili), SWE (Swedish), SYR (Syriac), TAM (Tamil), TEL (Telugu), TGK (Tajik), TGL (Tagalog), THA (Thai), TIR (Tigrinya), TUR (Turkish), UIG (Uighur), UKR (Ukrainian), URD (Urdu), UZB (Uzbek), UZB-CYR (Cyrillic Uzbek), VIE (Vietnamese), YID (Yiddish)
  --preprocessing: string # Optional, preprocessing mode, default is 'Auto'. Possible values are None (no preprocessing of the image), and Auto (automatic image enhancement of the image before OCR is applied; this is recommended).
  image_file: string # PDF file to perform OCR on. (format: binary)
]: any -> record<OcrPages: table<Lines: list, PageNumber: int, Successful: bool>, Successful: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ocr/pdf/to/lines-with-location" $auth.query)
  let req_body = {"imageFile": $image_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"language": $language, "preprocessing": $preprocessing} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["imageFile"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Convert a PDF into words with location
#
# POST /ocr/pdf/to/words-with-location
# operationId: PdfOcr_PdfToWordsWithLocation
export def "ocr-pdf-to-words-with-location create" [
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
  --language: string # Optional, language of the input document, default is English (ENG). Possible values are ENG (English), ARA (Arabic), ZHO (Chinese - Simplified), ZHO-HANT (Chinese - Traditional), ASM (Assamese), AFR (Afrikaans), AMH (Amharic), AZE (Azerbaijani), AZE-CYRL (Azerbaijani - Cyrillic), BEL (Belarusian), BEN (Bengali), BOD (Tibetan), BOS (Bosnian), BUL (Bulgarian), CAT (Catalan; Valencian), CEB (Cebuano), CES (Czech), CHR (Cherokee), CYM (Welsh), DAN (Danish), DEU (German), DZO (Dzongkha), ELL (Greek), ENM (Archaic/Middle English), EPO (Esperanto), EST (Estonian), EUS (Basque), FAS (Persian), FIN (Finnish), FRA (French), FRK (Frankish), FRM (Middle-French), GLE (Irish), GLG (Galician), GRC (Ancient Greek), HAT (Hatian), HEB (Hebrew), HIN (Hindi), HRV (Croatian), HUN (Hungarian), IKU (Inuktitut), IND (Indonesian), ISL (Icelandic), ITA (Italian), ITA-OLD (Old - Italian), JAV (Javanese), JPN (Japanese), KAN (Kannada), KAT (Georgian), KAT-OLD (Old-Georgian), KAZ (Kazakh), KHM (Central Khmer), KIR (Kirghiz), KOR (Korean), KUR (Kurdish), LAO (Lao), LAT (Latin), LAV (Latvian), LIT (Lithuanian), MAL (Malayalam), MAR (Marathi), MKD (Macedonian), MLT (Maltese), MSA (Malay), MYA (Burmese), NEP (Nepali), NLD (Dutch), NOR (Norwegian), ORI (Oriya), PAN (Panjabi), POL (Polish), POR (Portuguese), PUS (Pushto), RON (Romanian), RUS (Russian), SAN (Sanskrit), SIN (Sinhala), SLK (Slovak), SLV (Slovenian), SPA (Spanish), SPA-OLD (Old Spanish), SQI (Albanian), SRP (Serbian), SRP-LAT (Latin Serbian), SWA (Swahili), SWE (Swedish), SYR (Syriac), TAM (Tamil), TEL (Telugu), TGK (Tajik), TGL (Tagalog), THA (Thai), TIR (Tigrinya), TUR (Turkish), UIG (Uighur), UKR (Ukrainian), URD (Urdu), UZB (Uzbek), UZB-CYR (Cyrillic Uzbek), VIE (Vietnamese), YID (Yiddish)
  --preprocessing: string # Optional, preprocessing mode, default is 'Auto'. Possible values are None (no preprocessing of the image), and Auto (automatic image enhancement of the image before OCR is applied; this is recommended).
  image_file: string # PDF file to perform OCR on. (format: binary)
]: any -> record<OcrPages: table<PageNumber: int, Successful: bool, Words: list>, Successful: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ocr/pdf/to/words-with-location" $auth.query)
  let req_body = {"imageFile": $image_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"language": $language, "preprocessing": $preprocessing} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["imageFile"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Converts an uploaded PDF file into text via Optical Character Recognition.
#
# POST /ocr/pdf/toText
# operationId: PdfOcr_Post
export def "ocr-pdf-to-text create" [
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
  --recognition-mode: string # Optional; possible values are 'Basic' which provides basic recognition and is not resillient to page rotation, skew or low quality images uses 1-2 API calls per page; 'Normal' which provides highly fault tolerant OCR recognition uses 26-30 API calls per page; and 'Advanced' which provides the highest quality and most fault-tolerant recognition uses 28-30 API calls per page. Default recognition mode is 'Basic'
  --language: string # Optional, language of the input document, default is English (ENG). Possible values are ENG (English), ARA (Arabic), ZHO (Chinese - Simplified), ZHO-HANT (Chinese - Traditional), ASM (Assamese), AFR (Afrikaans), AMH (Amharic), AZE (Azerbaijani), AZE-CYRL (Azerbaijani - Cyrillic), BEL (Belarusian), BEN (Bengali), BOD (Tibetan), BOS (Bosnian), BUL (Bulgarian), CAT (Catalan; Valencian), CEB (Cebuano), CES (Czech), CHR (Cherokee), CYM (Welsh), DAN (Danish), DEU (German), DZO (Dzongkha), ELL (Greek), ENM (Archaic/Middle English), EPO (Esperanto), EST (Estonian), EUS (Basque), FAS (Persian), FIN (Finnish), FRA (French), FRK (Frankish), FRM (Middle-French), GLE (Irish), GLG (Galician), GRC (Ancient Greek), HAT (Hatian), HEB (Hebrew), HIN (Hindi), HRV (Croatian), HUN (Hungarian), IKU (Inuktitut), IND (Indonesian), ISL (Icelandic), ITA (Italian), ITA-OLD (Old - Italian), JAV (Javanese), JPN (Japanese), KAN (Kannada), KAT (Georgian), KAT-OLD (Old-Georgian), KAZ (Kazakh), KHM (Central Khmer), KIR (Kirghiz), KOR (Korean), KUR (Kurdish), LAO (Lao), LAT (Latin), LAV (Latvian), LIT (Lithuanian), MAL (Malayalam), MAR (Marathi), MKD (Macedonian), MLT (Maltese), MSA (Malay), MYA (Burmese), NEP (Nepali), NLD (Dutch), NOR (Norwegian), ORI (Oriya), PAN (Panjabi), POL (Polish), POR (Portuguese), PUS (Pushto), RON (Romanian), RUS (Russian), SAN (Sanskrit), SIN (Sinhala), SLK (Slovak), SLV (Slovenian), SPA (Spanish), SPA-OLD (Old Spanish), SQI (Albanian), SRP (Serbian), SRP-LAT (Latin Serbian), SWA (Swahili), SWE (Swedish), SYR (Syriac), TAM (Tamil), TEL (Telugu), TGK (Tajik), TGL (Tagalog), THA (Thai), TIR (Tigrinya), TUR (Turkish), UIG (Uighur), UKR (Ukrainian), URD (Urdu), UZB (Uzbek), UZB-CYR (Cyrillic Uzbek), VIE (Vietnamese), YID (Yiddish)
  --preprocessing: string # Optional, preprocessing mode, default is 'Auto'. Possible values are None (no preprocessing of the image), and Auto (automatic image enhancement of the image before OCR is applied; this is recommended).
  image_file: string # PDF file to perform OCR on. (format: binary)
]: any -> record<OcrPages: table<MeanConfidenceLevel: float, PageNumber: int, TextResult: string>, Successful: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ocr/pdf/toText" $auth.query)
  let req_body = {"imageFile": $image_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"recognitionMode": $recognition_mode, "language": $language, "preprocessing": $preprocessing} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["imageFile"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Recognize a photo of a business card, extract key business information
#
# POST /ocr/photo/recognize/business-card
# operationId: ImageOcr_PhotoRecognizeBusinessCard
export def "ocr-photo-recognize-business-card create-image" [
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
  image_file: string # Image file to perform OCR on. Common file formats such as PNG, JPEG are supported. (format: binary)
]: any -> record<AddressString: string, BusinessName: string, EmailAddress: string, PersonName: string, PersonTitle: string, PhoneNumber: string, Successful: bool, Timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ocr/photo/recognize/business-card" $auth.query)
  let req_body = {"imageFile": $image_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["imageFile"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Recognize a photo of a form, extract key fields and business information
#
# POST /ocr/photo/recognize/form
# operationId: ImageOcr_PhotoRecognizeForm
export def "ocr-photo-recognize-form create-image" [
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
  --form-template-definition: record # Form field definitions
  --recognition-mode: string # Optional, enable advanced recognition mode by specifying 'Advanced', enable handwriting recognition by specifying 'EnableHandwriting'. Default is disabled.
  --preprocessing: string # Optional, preprocessing mode, default is 'Auto'. Possible values are None (no preprocessing of the image), and Auto (automatic image enhancement of the image - including automatic unrotation of the image - before OCR is applied; this is recommended). Set this to 'None' if you do not want to use automatic image unrotation and enhancement.
  --diagnostics: string # Optional, diagnostics mode, default is 'false'. Possible values are 'true' (will set DiagnosticImage to a diagnostic PNG image in the result), and 'false' (no diagnostics are enabled; this is recommended for best performance).
  --language: string # Optional, language of the input document, default is English (ENG). Possible values are ENG (English), ARA (Arabic), ZHO (Chinese - Simplified), ZHO-HANT (Chinese - Traditional), ASM (Assamese), AFR (Afrikaans), AMH (Amharic), AZE (Azerbaijani), AZE-CYRL (Azerbaijani - Cyrillic), BEL (Belarusian), BEN (Bengali), BOD (Tibetan), BOS (Bosnian), BUL (Bulgarian), CAT (Catalan; Valencian), CEB (Cebuano), CES (Czech), CHR (Cherokee), CYM (Welsh), DAN (Danish), DEU (German), DZO (Dzongkha), ELL (Greek), ENM (Archaic/Middle English), EPO (Esperanto), EST (Estonian), EUS (Basque), FAS (Persian), FIN (Finnish), FRA (French), FRK (Frankish), FRM (Middle-French), GLE (Irish), GLG (Galician), GRC (Ancient Greek), HAT (Hatian), HEB (Hebrew), HIN (Hindi), HRV (Croatian), HUN (Hungarian), IKU (Inuktitut), IND (Indonesian), ISL (Icelandic), ITA (Italian), ITA-OLD (Old - Italian), JAV (Javanese), JPN (Japanese), KAN (Kannada), KAT (Georgian), KAT-OLD (Old-Georgian), KAZ (Kazakh), KHM (Central Khmer), KIR (Kirghiz), KOR (Korean), KUR (Kurdish), LAO (Lao), LAT (Latin), LAV (Latvian), LIT (Lithuanian), MAL (Malayalam), MAR (Marathi), MKD (Macedonian), MLT (Maltese), MSA (Malay), MYA (Burmese), NEP (Nepali), NLD (Dutch), NOR (Norwegian), ORI (Oriya), PAN (Panjabi), POL (Polish), POR (Portuguese), PUS (Pushto), RON (Romanian), RUS (Russian), SAN (Sanskrit), SIN (Sinhala), SLK (Slovak), SLV (Slovenian), SPA (Spanish), SPA-OLD (Old Spanish), SQI (Albanian), SRP (Serbian), SRP-LAT (Latin Serbian), SWA (Swahili), SWE (Swedish), SYR (Syriac), TAM (Tamil), TEL (Telugu), TGK (Tajik), TGL (Tagalog), THA (Thai), TIR (Tigrinya), TUR (Turkish), UIG (Uighur), UKR (Ukrainian), URD (Urdu), UZB (Uzbek), UZB-CYR (Cyrillic Uzbek), VIE (Vietnamese), YID (Yiddish)
  image_file: string # Image file to perform OCR on. Common file formats such as PNG, JPEG are supported. (format: binary)
]: any -> record<BestMatchFormSettingName: string, Diagnostics: list<string>, FieldValueExtractionResult: table<FieldValues: list, TargetField: record>, Successful: bool, TableValueExtractionResults: table<TableDefinition: record, TableRowsResult: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ocr/photo/recognize/form" $auth.query)
  let req_body = {"imageFile": $image_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"formTemplateDefinition": $form_template_definition, "recognitionMode": $recognition_mode, "preprocessing": $preprocessing, "diagnostics": $diagnostics, "language": $language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["imageFile"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Recognize a photo of a form, extract key fields using stored templates
#
# POST /ocr/photo/recognize/form/advanced
# operationId: ImageOcr_PhotoRecognizeFormAdvanced
export def "ocr-photo-recognize-form-advanced create-image" [
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
  --bucket-id: string # Bucket ID of the Configuration Bucket storing the form templates
  --bucket-secret-key: string # Bucket Secret Key of the Configuration Bucket storing the form templates
  --recognition-mode: string # Optional, enable advanced recognition mode by specifying 'Advanced', enable handwriting recognition by specifying 'EnableHandwriting'. Default is disabled.
  --preprocessing: string # Optional, preprocessing mode, default is 'Auto'. Possible values are None (no preprocessing of the image), and Auto (automatic image enhancement of the image - including automatic unrotation of the image - before OCR is applied; this is recommended). Set this to 'None' if you do not want to use automatic image unrotation and enhancement.
  --diagnostics: string # Optional, diagnostics mode, default is 'false'. Possible values are 'true' (will set DiagnosticImage to a diagnostic PNG image in the result), and 'false' (no diagnostics are enabled; this is recommended for best performance).
  image_file: string # Image file to perform OCR on. Common file formats such as PNG, JPEG are supported. (format: binary)
]: any -> record<BestMatchFormSettingName: string, Diagnostics: list<string>, FieldValueExtractionResult: table<FieldValues: list, TargetField: record>, Successful: bool, TableValueExtractionResults: table<TableDefinition: record, TableRowsResult: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ocr/photo/recognize/form/advanced" $auth.query)
  let req_body = {"imageFile": $image_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"bucketID": $bucket_id, "bucketSecretKey": $bucket_secret_key, "recognitionMode": $recognition_mode, "preprocessing": $preprocessing, "diagnostics": $diagnostics} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["imageFile"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Recognize a photo of a receipt, extract key business information
#
# POST /ocr/photo/recognize/receipt
# operationId: ImageOcr_PhotoRecognizeReceipt
export def "ocr-photo-recognize-receipt create-image" [
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
  --recognition-mode: string # Optional, enable advanced recognition mode by specifying 'Advanced', enable handwriting recognition by specifying 'EnableHandwriting'. Default is disabled.
  --language: string # Optional, language of the input document, default is English (ENG). Possible values are ENG (English), ARA (Arabic), ZHO (Chinese - Simplified), ZHO-HANT (Chinese - Traditional), ASM (Assamese), AFR (Afrikaans), AMH (Amharic), AZE (Azerbaijani), AZE-CYRL (Azerbaijani - Cyrillic), BEL (Belarusian), BEN (Bengali), BOD (Tibetan), BOS (Bosnian), BUL (Bulgarian), CAT (Catalan; Valencian), CEB (Cebuano), CES (Czech), CHR (Cherokee), CYM (Welsh), DAN (Danish), DEU (German), DZO (Dzongkha), ELL (Greek), ENM (Archaic/Middle English), EPO (Esperanto), EST (Estonian), EUS (Basque), FAS (Persian), FIN (Finnish), FRA (French), FRK (Frankish), FRM (Middle-French), GLE (Irish), GLG (Galician), GRC (Ancient Greek), HAT (Hatian), HEB (Hebrew), HIN (Hindi), HRV (Croatian), HUN (Hungarian), IKU (Inuktitut), IND (Indonesian), ISL (Icelandic), ITA (Italian), ITA-OLD (Old - Italian), JAV (Javanese), JPN (Japanese), KAN (Kannada), KAT (Georgian), KAT-OLD (Old-Georgian), KAZ (Kazakh), KHM (Central Khmer), KIR (Kirghiz), KOR (Korean), KUR (Kurdish), LAO (Lao), LAT (Latin), LAV (Latvian), LIT (Lithuanian), MAL (Malayalam), MAR (Marathi), MKD (Macedonian), MLT (Maltese), MSA (Malay), MYA (Burmese), NEP (Nepali), NLD (Dutch), NOR (Norwegian), ORI (Oriya), PAN (Panjabi), POL (Polish), POR (Portuguese), PUS (Pushto), RON (Romanian), RUS (Russian), SAN (Sanskrit), SIN (Sinhala), SLK (Slovak), SLV (Slovenian), SPA (Spanish), SPA-OLD (Old Spanish), SQI (Albanian), SRP (Serbian), SRP-LAT (Latin Serbian), SWA (Swahili), SWE (Swedish), SYR (Syriac), TAM (Tamil), TEL (Telugu), TGK (Tajik), TGL (Tagalog), THA (Thai), TIR (Tigrinya), TUR (Turkish), UIG (Uighur), UKR (Ukrainian), URD (Urdu), UZB (Uzbek), UZB-CYR (Cyrillic Uzbek), VIE (Vietnamese), YID (Yiddish)
  --preprocessing: string # Optional, preprocessing mode, default is 'None'. Possible values are None (no preprocessing of the image), and 'Advanced' (automatic image enhancement of the image before OCR is applied; this is recommended and needed to handle rotated receipts).
  image_file: string # Image file to perform OCR on. Common file formats such as PNG, JPEG are supported. (format: binary)
]: any -> record<AddressString: string, BusinessName: string, BusinessWebsite: string, PhoneNumber: string, ReceiptItems: table<ItemDescription: string, ItemPrice: float>, ReceiptSubTotal: float, ReceiptTotal: float, Successful: bool, Timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ocr/photo/recognize/receipt" $auth.query)
  let req_body = {"imageFile": $image_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"recognitionMode": $recognition_mode, "language": $language, "preprocessing": $preprocessing} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["imageFile"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Convert a photo of a document or receipt into words with location
#
# POST /ocr/photo/to/words-with-location
# operationId: ImageOcr_PhotoWordsWithLocation
export def "ocr-photo-to-words-with-location create-image" [
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
  --recognition-mode: string # Optional; possible values are 'Normal' which provides highly fault tolerant OCR recognition uses 26-30 API calls; and 'Advanced' which provides the highest quality and most fault-tolerant recognition uses 28-30 API calls. Default recognition mode is 'Advanced'
  --language: string # Optional, language of the input document, default is English (ENG). Possible values are ENG (English), ARA (Arabic), ZHO (Chinese - Simplified), ZHO-HANT (Chinese - Traditional), ASM (Assamese), AFR (Afrikaans), AMH (Amharic), AZE (Azerbaijani), AZE-CYRL (Azerbaijani - Cyrillic), BEL (Belarusian), BEN (Bengali), BOD (Tibetan), BOS (Bosnian), BUL (Bulgarian), CAT (Catalan; Valencian), CEB (Cebuano), CES (Czech), CHR (Cherokee), CYM (Welsh), DAN (Danish), DEU (German), DZO (Dzongkha), ELL (Greek), ENM (Archaic/Middle English), EPO (Esperanto), EST (Estonian), EUS (Basque), FAS (Persian), FIN (Finnish), FRA (French), FRK (Frankish), FRM (Middle-French), GLE (Irish), GLG (Galician), GRC (Ancient Greek), HAT (Hatian), HEB (Hebrew), HIN (Hindi), HRV (Croatian), HUN (Hungarian), IKU (Inuktitut), IND (Indonesian), ISL (Icelandic), ITA (Italian), ITA-OLD (Old - Italian), JAV (Javanese), JPN (Japanese), KAN (Kannada), KAT (Georgian), KAT-OLD (Old-Georgian), KAZ (Kazakh), KHM (Central Khmer), KIR (Kirghiz), KOR (Korean), KUR (Kurdish), LAO (Lao), LAT (Latin), LAV (Latvian), LIT (Lithuanian), MAL (Malayalam), MAR (Marathi), MKD (Macedonian), MLT (Maltese), MSA (Malay), MYA (Burmese), NEP (Nepali), NLD (Dutch), NOR (Norwegian), ORI (Oriya), PAN (Panjabi), POL (Polish), POR (Portuguese), PUS (Pushto), RON (Romanian), RUS (Russian), SAN (Sanskrit), SIN (Sinhala), SLK (Slovak), SLV (Slovenian), SPA (Spanish), SPA-OLD (Old Spanish), SQI (Albanian), SRP (Serbian), SRP-LAT (Latin Serbian), SWA (Swahili), SWE (Swedish), SYR (Syriac), TAM (Tamil), TEL (Telugu), TGK (Tajik), TGL (Tagalog), THA (Thai), TIR (Tigrinya), TUR (Turkish), UIG (Uighur), UKR (Ukrainian), URD (Urdu), UZB (Uzbek), UZB-CYR (Cyrillic Uzbek), VIE (Vietnamese), YID (Yiddish)
  --preprocessing: string # Optional, preprocessing mode, default is 'Auto'. Possible values are None (no preprocessing of the image), and Auto (automatic image enhancement of the image before OCR is applied; this is recommended).
  --diagnostics: string # Optional, diagnostics mode, default is 'false'. Possible values are 'true' (will set DiagnosticImage to a diagnostic PNG image in the result), and 'false' (no diagnostics are enabled; this is recommended for best performance).
  image_file: string # Image file to perform OCR on. Common file formats such as PNG, JPEG are supported. (format: binary)
]: any -> record<DiagnosticImage: string, Successful: bool, TextElements: table<BoundingPoints: list, ConfidenceLevel: float, Height: int, Text: string, Width: int, XLeft: int, YTop: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ocr/photo/to/words-with-location" $auth.query)
  let req_body = {"imageFile": $image_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"recognitionMode": $recognition_mode, "language": $language, "preprocessing": $preprocessing, "diagnostics": $diagnostics} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["imageFile"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Convert a photo of a document into text
#
# POST /ocr/photo/toText
# operationId: ImageOcr_PhotoToText
export def "ocr-photo-to-text create-image" [
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
  --recognition-mode: string # Optional; possible values are 'Basic' which provides basic recognition and is not resillient to page rotation, skew or low quality images uses 1-2 API calls; 'Normal' which provides highly fault tolerant OCR recognition uses 26-30 API calls; and 'Advanced' which provides the highest quality and most fault-tolerant recognition uses 28-30 API calls. Default recognition mode is 'Advanced'
  --language: string # Optional, language of the input document, default is English (ENG). Possible values are ENG (English), ARA (Arabic), ZHO (Chinese - Simplified), ZHO-HANT (Chinese - Traditional), ASM (Assamese), AFR (Afrikaans), AMH (Amharic), AZE (Azerbaijani), AZE-CYRL (Azerbaijani - Cyrillic), BEL (Belarusian), BEN (Bengali), BOD (Tibetan), BOS (Bosnian), BUL (Bulgarian), CAT (Catalan; Valencian), CEB (Cebuano), CES (Czech), CHR (Cherokee), CYM (Welsh), DAN (Danish), DEU (German), DZO (Dzongkha), ELL (Greek), ENM (Archaic/Middle English), EPO (Esperanto), EST (Estonian), EUS (Basque), FAS (Persian), FIN (Finnish), FRA (French), FRK (Frankish), FRM (Middle-French), GLE (Irish), GLG (Galician), GRC (Ancient Greek), HAT (Hatian), HEB (Hebrew), HIN (Hindi), HRV (Croatian), HUN (Hungarian), IKU (Inuktitut), IND (Indonesian), ISL (Icelandic), ITA (Italian), ITA-OLD (Old - Italian), JAV (Javanese), JPN (Japanese), KAN (Kannada), KAT (Georgian), KAT-OLD (Old-Georgian), KAZ (Kazakh), KHM (Central Khmer), KIR (Kirghiz), KOR (Korean), KUR (Kurdish), LAO (Lao), LAT (Latin), LAV (Latvian), LIT (Lithuanian), MAL (Malayalam), MAR (Marathi), MKD (Macedonian), MLT (Maltese), MSA (Malay), MYA (Burmese), NEP (Nepali), NLD (Dutch), NOR (Norwegian), ORI (Oriya), PAN (Panjabi), POL (Polish), POR (Portuguese), PUS (Pushto), RON (Romanian), RUS (Russian), SAN (Sanskrit), SIN (Sinhala), SLK (Slovak), SLV (Slovenian), SPA (Spanish), SPA-OLD (Old Spanish), SQI (Albanian), SRP (Serbian), SRP-LAT (Latin Serbian), SWA (Swahili), SWE (Swedish), SYR (Syriac), TAM (Tamil), TEL (Telugu), TGK (Tajik), TGL (Tagalog), THA (Thai), TIR (Tigrinya), TUR (Turkish), UIG (Uighur), UKR (Ukrainian), URD (Urdu), UZB (Uzbek), UZB-CYR (Cyrillic Uzbek), VIE (Vietnamese), YID (Yiddish)
  image_file: string # Image file to perform OCR on. Common file formats such as PNG, JPEG are supported. (format: binary)
]: any -> record<MeanConfidenceLevel: float, TextResult: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ocr/photo/toText" $auth.query)
  let req_body = {"imageFile": $image_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"recognitionMode": $recognition_mode, "language": $language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["imageFile"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Convert an image of text into a binarized (light and dark) view
#
# POST /ocr/preprocessing/image/binarize
# operationId: Preprocessing_Binarize
export def "ocr-preprocessing-image-binarize create" [
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
  image_file: string # Image file to perform OCR on. Common file formats such as PNG, JPEG are supported. (format: binary)
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ocr/preprocessing/image/binarize" $auth.query)
  let req_body = {"imageFile": $image_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["imageFile"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Convert an image of text into a binary (light and dark) view with ML
#
# POST /ocr/preprocessing/image/binarize/advanced
# operationId: Preprocessing_BinarizeAdvanced
export def "ocr-preprocessing-image-binarize-advanced create" [
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
  image_file: string # Image file to perform OCR on. Common file formats such as PNG, JPEG are supported. (format: binary)
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ocr/preprocessing/image/binarize/advanced" $auth.query)
  let req_body = {"imageFile": $image_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["imageFile"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Get the angle of the page / document / receipt
#
# POST /ocr/preprocessing/image/get-page-angle
# operationId: Preprocessing_GetPageAngle
export def "ocr-preprocessing-image-get-page-angle get" [
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
  image_file: string # Image file to perform OCR on. Common file formats such as PNG, JPEG are supported. (format: binary)
]: any -> record<Angle: float, Successful: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ocr/preprocessing/image/get-page-angle" $auth.query)
  let req_body = {"imageFile": $image_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["imageFile"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Detect and unrotate a document image
#
# POST /ocr/preprocessing/image/unrotate
# operationId: Preprocessing_Unrotate
export def "ocr-preprocessing-image-unrotate create" [
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
  image_file: string # Image file to perform OCR on. Common file formats such as PNG, JPEG are supported. (format: binary)
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ocr/preprocessing/image/unrotate" $auth.query)
  let req_body = {"imageFile": $image_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["imageFile"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Detect and unrotate a document image (advanced)
#
# POST /ocr/preprocessing/image/unrotate/advanced
# operationId: Preprocessing_UnrotateAdvanced
export def "ocr-preprocessing-image-unrotate-advanced create" [
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
  image_file: string # Image file to perform OCR on. Common file formats such as PNG, JPEG are supported. (format: binary)
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ocr/preprocessing/image/unrotate/advanced" $auth.query)
  let req_body = {"imageFile": $image_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["imageFile"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Detect and unskew a photo of a document
#
# POST /ocr/preprocessing/image/unskew
# operationId: Preprocessing_Unskew
export def "ocr-preprocessing-image-unskew create" [
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
  image_file: string # Image file to perform OCR on. Common file formats such as PNG, JPEG are supported. (format: binary)
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ocr/preprocessing/image/unskew" $auth.query)
  let req_body = {"imageFile": $image_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["imageFile"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Convert a photo of a receipt into a CSV file containing structured information from the receipt
#
# POST /ocr/receipts/photo/to/csv
# DEPRECATED
# operationId: Receipts_PhotoToCSV
@deprecated
export def "ocr-receipts-photo-to-csv create" [
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
  image_file: string # Image file to perform OCR on. Common file formats such as PNG, JPEG are supported. (format: binary)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ocr/receipts/photo/to/csv" $auth.query)
  let req_body = {"imageFile": $image_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["imageFile"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}
