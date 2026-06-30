# Auto-generated client for Face Client v1.0
# Source: https://api.apis.guru/v2/specs/azure.com/cognitiveservices-Face/1.0/swagger.json
# Auth: --token flag or $env.FACE_CLIENT_TOKEN

const BASE_URL = "{Endpoint}/face/v1.0"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o FACE_CLIENT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "ocp-apim-subscription-key" => { {scheme: $scheme, headers: {Ocp-Apim-Subscription-Key: $token_val}, query: "", location: "header"} }
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

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["{Endpoint}/face/v1.0"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key"] }

# Completers for enum parameters
def recognition-model-completer [] { ["recognition_01" "recognition_02"] }
def detection-model-completer [] { ["detection_01" "detection_02"] }
def mode-completer [] { ["matchFace" "matchPerson"] }
def type-completer [] { ["FaceList" "LargeFaceList" "LargePersonGroup" "PersonGroup"] }
def mode-completer-1 [] { ["CreateNew"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "detect create-face-with-url" } } | get name | first)
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

# Detect human faces in an image, return face rectangles, and optionally with faceIds, landmarks, and attributes. * No image will be stored. Only the extracted face feature will be stored on server. The faceId is an identifier of the face feature and will be used in [Face - Identify](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395239), [Face - Verify](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523a), and [Face - Find Similar](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395237). The stored face feature(s) will expire and be deleted 24 hours after the original detection call. * Optional parameters include faceId, landmarks, and attributes. Attributes include age, gender, headPose, smile, facialHair, glasses, emotion, hair, makeup, occlusion, accessories, blur, exposure and noise. Some of the results returned for specific attributes may not be highly accurate. * JPEG, PNG, GIF (the first frame), and BMP format are supported. The allowed image file size is from 1KB to 6MB. * Up to 100 faces can be returned for an image. Faces are ranked by face rectangle size from large to small. * For optimal results when querying [Face - Identify](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395239), [Face - Verify](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523a), and [Face - Find Similar](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395237) ('returnFaceId' is true), please use faces that are: frontal, clear, and with a minimum size of 200x200 pixels (100 pixels between eyes). * The minimum detectable face size is 36x36 pixels in an image no larger than 1920x1080 pixels. Images with dimensions higher than 1920x1080 pixels will need a proportionally larger minimum face size. * Different 'detectionModel' values can be provided. To use and compare different detection models, please refer to [How to specify a detection model](https://docs.microsoft.com/en-us/azure/cognitive-services/face/face-api-how-to-topics/specify-detection-model) | Model | Recommended use-case(s) | | ---------- | -------- | | 'detection_01': | The default detection model for [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236). Recommend for near frontal face detection. For scenarios with exceptionally large angle (head-pose) faces, occluded faces or wrong image orientation, the faces in such cases may not be detected. | | 'detection_02': | Detection model released in 2019 May with improved accuracy especially on small, side and blurry faces. | * Different 'recognitionModel' values are provided. If follow-up operations like Verify, Identify, Find Similar are needed, please specify the recognition model with 'recognitionModel' parameter. The default value for 'recognitionModel' is 'recognition_01', if latest model needed, please explicitly specify the model you need in this parameter. Once specified, the detected faceIds will be associated with the specified recognition model. More details, please refer to [How to specify a recognition model](https://docs.microsoft.com/en-us/azure/cognitive-services/face/face-api-how-to-topics/specify-recognition-model) | Model | Recommended use-case(s) | | ---------- | -------- | | 'recognition_01': | The default recognition model for [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236). All those faceIds created before 2019 March are bonded with this recognition model. | | 'recognition_02': | Recognition model released in 2019 March. 'recognition_02' is recommended since its overall accuracy is improved compared with 'recognition_01'. |
#
# POST /detect
# operationId: Face_DetectWithUrl
export def "detect create-face-with-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-face-id: oneof<nothing, bool> # A value indicating whether the operation should return faceIds of detected faces. (default: true)
  --return-face-landmarks: oneof<nothing, bool> # A value indicating whether the operation should return landmarks of the detected faces. (default: false)
  --return-face-attributes: list<string> # Analyze and return the one or more specified face attributes in the comma-separated string like "returnFaceAttributes=age,gender". Supported face attributes include age, gender, headPose, smile, facialHair, glasses and emotion. Note that each face attribute analysis has additional computational and time cost.
  --recognition-model: string@recognition-model-completer # Name of recognition model. Recognition model is used when the face features are extracted and associated with detected faceIds, (Large)FaceList or (Large)PersonGroup. A recognition model name can be provided when performing Face - Detect or (Large)FaceList - Create or (Large)PersonGroup - Create. The default value is 'recognition_01', if latest model needed, please explicitly specify the model you need. (default: recognition_01)
  --return-recognition-model: oneof<nothing, bool> # A value indicating whether the operation should return 'recognitionModel' in response. (default: false)
  --detection-model: string@detection-model-completer # Name of detection model. Detection model is used to detect faces in the submitted image. A detection model name can be provided when performing Face - Detect or (Large)FaceList - Add Face or (Large)PersonGroup - Add Face. The default value is 'detection_01', if another model is needed, please explicitly specify it. (default: detection_01)
  url: string # Publicly reachable URL of an image
]: any -> table<faceAttributes: record<accessories: list, age: float, blur: record, emotion: record, exposure: record, facialHair: record, gender: string, glasses: string, hair: record, headPose: record, makeup: record, noise: record, occlusion: record, smile: float>, faceId: string, faceLandmarks: record<eyeLeftBottom: record, eyeLeftInner: record, eyeLeftOuter: record, eyeLeftTop: record, eyeRightBottom: record, eyeRightInner: record, eyeRightOuter: record, eyeRightTop: record, eyebrowLeftInner: record, eyebrowLeftOuter: record, eyebrowRightInner: record, eyebrowRightOuter: record, mouthLeft: record, mouthRight: record, noseLeftAlarOutTip: record, noseLeftAlarTop: record, noseRightAlarOutTip: record, noseRightAlarTop: record, noseRootLeft: record, noseRootRight: record, noseTip: record, pupilLeft: record, pupilRight: record, underLipBottom: record, underLipTop: record, upperLipBottom: record, upperLipTop: record>, faceRectangle: record<height: int, left: int, top: int, width: int>, recognitionModel: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "returnFaceId" $return_face_id "scalar") (serialize-qp "returnFaceLandmarks" $return_face_landmarks "scalar") (serialize-qp "returnFaceAttributes" $return_face_attributes "csv") (serialize-qp "recognitionModel" $recognition_model "scalar") (serialize-qp "returnRecognitionModel" $return_recognition_model "scalar") (serialize-qp "detectionModel" $detection_model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/detect" $qp $auth.query)
  let req_body = {"url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"returnFaceId": $return_face_id, "returnFaceLandmarks": $return_face_landmarks, "returnFaceAttributes": $return_face_attributes, "recognitionModel": $recognition_model, "returnRecognitionModel": $return_recognition_model, "detectionModel": $detection_model} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List face lists’ faceListId, name, userData and recognitionModel. To get face information inside faceList use [FaceList - Get](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039524c)
#
# GET /facelists
# operationId: FaceList_List
export def "facelists list-face" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-recognition-model: oneof<nothing, bool> # A value indicating whether the operation should return 'recognitionModel' in response. (default: false)
]: nothing -> table<faceListId: string, persistedFaces: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "returnRecognitionModel" $return_recognition_model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/facelists" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"returnRecognitionModel": $return_recognition_model} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a specified face list.
#
# DELETE /facelists/{faceListId}
# operationId: FaceList_Delete
export def "facelists list-face-delete" [
  face_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($face_list_id | is-empty) { error make --unspanned { msg: "path parameter 'faceListId' must be non-empty" } }
  let full_url = (build-url $base ({face_list_id: (encode-path-segment $face_list_id)} | format pattern "/facelists/{face_list_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve a face list’s faceListId, name, userData, recognitionModel and faces in the face list.
#
# GET /facelists/{faceListId}
# operationId: FaceList_Get
export def "facelists list-face-get" [
  face_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-recognition-model: oneof<nothing, bool> # A value indicating whether the operation should return 'recognitionModel' in response. (default: false)
]: nothing -> record<faceListId: string, persistedFaces: table<persistedFaceId: string, userData: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($face_list_id | is-empty) { error make --unspanned { msg: "path parameter 'faceListId' must be non-empty" } }
  let qp = [(serialize-qp "returnRecognitionModel" $return_recognition_model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({face_list_id: (encode-path-segment $face_list_id)} | format pattern "/facelists/{face_list_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"returnRecognitionModel": $return_recognition_model} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update information of a face list.
#
# PATCH /facelists/{faceListId}
# operationId: FaceList_Update
export def "facelists list-face-update" [
  face_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($face_list_id | is-empty) { error make --unspanned { msg: "path parameter 'faceListId' must be non-empty" } }
  let full_url = (build-url $base ({face_list_id: (encode-path-segment $face_list_id)} | format pattern "/facelists/{face_list_id}") $auth.query)
  let req_body = {"name": $name, "userData": $user_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create an empty face list with user-specified faceListId, name, an optional userData and recognitionModel. Up to 64 face lists are allowed in one subscription. Face list is a list of faces, up to 1,000 faces, and used by [Face - Find Similar](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395237). After creation, user should use [FaceList - Add Face](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395250) to import the faces. No image will be stored. Only the extracted face features are stored on server until [FaceList - Delete](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039524f) is called. Find Similar is used for scenario like finding celebrity-like faces, similar face filtering, or as a light way face identification. But if the actual use is to identify person, please use [PersonGroup](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395244) / [LargePersonGroup](/docs/services/563879b61984550e40cbbe8d/operations/599acdee6ac60f11b48b5a9d) and [Face - Identify](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395239). Please consider [LargeFaceList](/docs/services/563879b61984550e40cbbe8d/operations/5a157b68d2de3616c086f2cc) when the face number is large. It can support up to 1,000,000 faces. 'recognitionModel' should be specified to associate with this face list. The default value for 'recognitionModel' is 'recognition_01', if the latest model needed, please explicitly specify the model you need in this parameter. New faces that are added to an existing face list will use the recognition model that's already associated with the collection. Existing face features in a face list can't be updated to features extracted by another version of recognition model. * 'recognition_01': The default recognition model for [FaceList- Create](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039524b). All those face lists created before 2019 March are bonded with this recognition model. * 'recognition_02': Recognition model released in 2019 March. 'recognition_02' is recommended since its overall accuracy is improved compared with 'recognition_01'.
#
# PUT /facelists/{faceListId}
# operationId: FaceList_Create
export def "facelists list-face-create" [
  face_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recognition-model: string@recognition-model-completer # Name of recognition model. Recognition model is used when the face features are extracted and associated with detected faceIds, (Large)FaceList or (Large)PersonGroup. A recognition model name can be provided when performing Face - Detect or (Large)FaceList - Create or (Large)PersonGroup - Create. The default value is 'recognition_01', if latest model needed, please explicitly specify the model you need. (default: recognition_01)
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($face_list_id | is-empty) { error make --unspanned { msg: "path parameter 'faceListId' must be non-empty" } }
  let full_url = (build-url $base ({face_list_id: (encode-path-segment $face_list_id)} | format pattern "/facelists/{face_list_id}") $auth.query)
  let req_body = {"recognitionModel": $recognition_model, "name": $name, "userData": $user_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Add a face to a specified face list, up to 1,000 faces. To deal with an image contains multiple faces, input face can be specified as an image with a targetFace rectangle. It returns a persistedFaceId representing the added face. No image will be stored. Only the extracted face feature will be stored on server until [FaceList - Delete Face](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395251) or [FaceList - Delete](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039524f) is called. Note persistedFaceId is different from faceId generated by [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236). * Higher face image quality means better detection and recognition precision. Please consider high-quality faces: frontal, clear, and face size is 200x200 pixels (100 pixels between eyes) or bigger. * JPEG, PNG, GIF (the first frame), and BMP format are supported. The allowed image file size is from 1KB to 6MB. * "targetFace" rectangle should contain one face. Zero or multiple faces will be regarded as an error. If the provided "targetFace" rectangle is not returned from [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236), there’s no guarantee to detect and add the face successfully. * Out of detectable face size (36x36 - 4096x4096 pixels), large head-pose, or large occlusions will cause failures. * Adding/deleting faces to/from a same face list are processed sequentially and to/from different face lists are in parallel. * The minimum detectable face size is 36x36 pixels in an image no larger than 1920x1080 pixels. Images with dimensions higher than 1920x1080 pixels will need a proportionally larger minimum face size. * Different 'detectionModel' values can be provided. To use and compare different detection models, please refer to [How to specify a detection model](https://docs.microsoft.com/en-us/azure/cognitive-services/face/face-api-how-to-topics/specify-detection-model) | Model | Recommended use-case(s) | | ---------- | -------- | | 'detection_01': | The default detection model for [FaceList - Add Face](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395250). Recommend for near frontal face detection. For scenarios with exceptionally large angle (head-pose) faces, occluded faces or wrong image orientation, the faces in such cases may not be detected. | | 'detection_02': | Detection model released in 2019 May with improved accuracy especially on small, side and blurry faces. |
#
# POST /facelists/{faceListId}/persistedfaces
# operationId: FaceList_AddFaceFromUrl
export def "facelists-persistedfaces list-face-create-face-from-url" [
  face_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-data: string # User-specified data about the face for any purpose. The maximum length is 1KB.
  --target-face: list<int> # A face rectangle to specify the target face to be added to a person in the format of "targetFace=left,top,width,height". E.g. "targetFace=10,10,100,100". If there is more than one face in the image, targetFace is required to specify which face to add. No targetFace means there is only one face detected in the entire image.
  --detection-model: string@detection-model-completer # Name of detection model. Detection model is used to detect faces in the submitted image. A detection model name can be provided when performing Face - Detect or (Large)FaceList - Add Face or (Large)PersonGroup - Add Face. The default value is 'detection_01', if another model is needed, please explicitly specify it. (default: detection_01)
  url: string # Publicly reachable URL of an image
]: any -> record<persistedFaceId: string, userData: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($face_list_id | is-empty) { error make --unspanned { msg: "path parameter 'faceListId' must be non-empty" } }
  let qp = [(serialize-qp "userData" $user_data "scalar") (serialize-qp "targetFace" $target_face "csv") (serialize-qp "detectionModel" $detection_model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({face_list_id: (encode-path-segment $face_list_id)} | format pattern "/facelists/{face_list_id}/persistedfaces") $qp $auth.query)
  let req_body = {"url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"userData": $user_data, "targetFace": $target_face, "detectionModel": $detection_model} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete a face from a face list by specified faceListId and persistedFaceId. Adding/deleting faces to/from a same face list are processed sequentially and to/from different face lists are in parallel.
#
# DELETE /facelists/{faceListId}/persistedfaces/{persistedFaceId}
# operationId: FaceList_DeleteFace
export def "facelists-persistedfaces list-face-delete-face" [
  face_list_id: string
  persisted_face_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($face_list_id | is-empty) { error make --unspanned { msg: "path parameter 'faceListId' must be non-empty" } }
  if ($persisted_face_id | is-empty) { error make --unspanned { msg: "path parameter 'persistedFaceId' must be non-empty" } }
  let full_url = (build-url $base ({face_list_id: (encode-path-segment $face_list_id), persisted_face_id: (encode-path-segment $persisted_face_id)} | format pattern "/facelists/{face_list_id}/persistedfaces/{persisted_face_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Given query face's faceId, to search the similar-looking faces from a faceId array, a face list or a large face list. faceId array contains the faces created by [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236), which will expire 24 hours after creation. A "faceListId" is created by [FaceList - Create](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039524b) containing persistedFaceIds that will not expire. And a "largeFaceListId" is created by [LargeFaceList - Create](/docs/services/563879b61984550e40cbbe8d/operations/5a157b68d2de3616c086f2cc) containing persistedFaceIds that will also not expire. Depending on the input the returned similar faces list contains faceIds or persistedFaceIds ranked by similarity. Find similar has two working modes, "matchPerson" and "matchFace". "matchPerson" is the default mode that it tries to find faces of the same person as possible by using internal same-person thresholds. It is useful to find a known person's other photos. Note that an empty list will be returned if no faces pass the internal thresholds. "matchFace" mode ignores same-person thresholds and returns ranked similar faces anyway, even the similarity is low. It can be used in the cases like searching celebrity-looking faces. The 'recognitionModel' associated with the query face's faceId should be the same as the 'recognitionModel' used by the target faceId array, face list or large face list.
#
# POST /findsimilars
# operationId: Face_FindSimilar
export def "findsimilars find-face-similar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  face_id: string # FaceId of the query face. User needs to call Face - Detect first to get a valid faceId. Note that this faceId is not persisted and will expire 24 hours after the detection call (format: uuid)
  --face-ids: list<string> # An array of candidate faceIds. All of them are created by Face - Detect and the faceIds will expire 24 hours after the detection call. The number of faceIds is limited to 1000. Parameter faceListId, largeFaceListId and faceIds should not be provided at the same time.
  --face-list-id: string # An existing user-specified unique candidate face list, created in Face List - Create a Face List. Face list contains a set of persistedFaceIds which are persisted and will never expire. Parameter faceListId, largeFaceListId and faceIds should not be provided at the same time.
  --large-face-list-id: string # An existing user-specified unique candidate large face list, created in LargeFaceList - Create. Large face list contains a set of persistedFaceIds which are persisted and will never expire. Parameter faceListId, largeFaceListId and faceIds should not be provided at the same time.
  --max-num-of-candidates-returned: int # The number of top similar faces returned. The valid range is [1, 1000]. (default: 20)
  --mode: string@mode-completer # Similar face searching mode. It can be "matchPerson" or "matchFace". (default: matchPerson)
]: any -> table<confidence: float, faceId: string, persistedFaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/findsimilars" $auth.query)
  let req_body = {"faceId": $face_id, "faceIds": $face_ids, "faceListId": $face_list_id, "largeFaceListId": $large_face_list_id, "maxNumOfCandidatesReturned": $max_num_of_candidates_returned, "mode": $mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Divide candidate faces into groups based on face similarity. * The output is one or more disjointed face groups and a messyGroup. A face group contains faces that have similar looking, often of the same person. Face groups are ranked by group size, i.e. number of faces. Notice that faces belonging to a same person might be split into several groups in the result. * MessyGroup is a special face group containing faces that cannot find any similar counterpart face from original faces. The messyGroup will not appear in the result if all faces found their counterparts. * Group API needs at least 2 candidate faces and 1000 at most. We suggest to try [Face - Verify](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523a) when you only have 2 candidate faces. * The 'recognitionModel' associated with the query faces' faceIds should be the same.
#
# POST /group
# operationId: Face_Group
export def "group create-face" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  face_ids: list<string> # Array of candidate faceId created by Face - Detect. The maximum is 1000 faces
]: any -> record<groups: list<list<string>>, messyGroup: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/group" $auth.query)
  let req_body = {"faceIds": $face_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# 1-to-many identification to find the closest matches of the specific query person face from a person group or large person group. For each face in the faceIds array, Face Identify will compute similarities between the query face and all the faces in the person group (given by personGroupId) or large person group (given by largePersonGroupId), and return candidate person(s) for that face ranked by similarity confidence. The person group/large person group should be trained to make it ready for identification. See more in [PersonGroup - Train](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395249) and [LargePersonGroup - Train](/docs/services/563879b61984550e40cbbe8d/operations/599ae2d16ac60f11b48b5aa4). Remarks: * The algorithm allows more than one face to be identified independently at the same request, but no more than 10 faces. * Each person in the person group/large person group could have more than one face, but no more than 248 faces. * Higher face image quality means better identification precision. Please consider high-quality faces: frontal, clear, and face size is 200x200 pixels (100 pixels between eyes) or bigger. * Number of candidates returned is restricted by maxNumOfCandidatesReturned and confidenceThreshold. If no person is identified, the returned candidates will be an empty array. * Try [Face - Find Similar](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395237) when you need to find similar faces from a face list/large face list instead of a person group/large person group. * The 'recognitionModel' associated with the query faces' faceIds should be the same as the 'recognitionModel' used by the target person group or large person group.
#
# POST /identify
# operationId: Face_Identify
export def "identify create-face" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --confidence-threshold: float # A number ranging from 0 to 1 indicating a level of confidence associated with a property.
  face_ids: list<string> # Array of query faces faceIds, created by the Face - Detect. Each of the faces are identified independently. The valid number of faceIds is between [1, 10].
  --large-person-group-id: string # LargePersonGroupId of the target large person group, created by LargePersonGroup - Create. Parameter personGroupId and largePersonGroupId should not be provided at the same time.
  --max-num-of-candidates-returned: int # The range of maxNumOfCandidatesReturned is between 1 and 5 (default is 1). (default: 1)
  --person-group-id: string # PersonGroupId of the target person group, created by PersonGroup - Create. Parameter personGroupId and largePersonGroupId should not be provided at the same time.
]: any -> table<candidates: list<record>, faceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/identify" $auth.query)
  let req_body = {"confidenceThreshold": $confidence_threshold, "faceIds": $face_ids, "largePersonGroupId": $large_person_group_id, "maxNumOfCandidatesReturned": $max_num_of_candidates_returned, "personGroupId": $person_group_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List large face lists’ information of largeFaceListId, name, userData and recognitionModel. To get face information inside largeFaceList use [LargeFaceList Face - Get](/docs/services/563879b61984550e40cbbe8d/operations/5a158cf2d2de3616c086f2d5) * Large face lists are stored in alphabetical order of largeFaceListId. * "start" parameter (string, optional) is a user-provided largeFaceListId value that returned entries have larger ids by string comparison. "start" set to empty to indicate return from the first item. * "top" parameter (int, optional) specifies the number of entries to return. A maximal of 1000 entries can be returned in one call. To fetch more, you can specify "start" with the last returned entry’s Id of the current call. For example, total 5 large person lists: "list1", ..., "list5". "start=&top=" will return all 5 lists. "start=&top=2" will return "list1", "list2". "start=list2&top=3" will return "list3", "list4", "list5".
#
# GET /largefacelists
# operationId: LargeFaceList_List
export def "largefacelists list-large-face" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-recognition-model: oneof<nothing, bool> # A value indicating whether the operation should return 'recognitionModel' in response. (default: false)
]: nothing -> table<largeFaceListId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "returnRecognitionModel" $return_recognition_model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/largefacelists" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"returnRecognitionModel": $return_recognition_model} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a specified large face list.
#
# DELETE /largefacelists/{largeFaceListId}
# operationId: LargeFaceList_Delete
export def "largefacelists list-large-face-delete" [
  large_face_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_face_list_id | is-empty) { error make --unspanned { msg: "path parameter 'largeFaceListId' must be non-empty" } }
  let full_url = (build-url $base ({large_face_list_id: (encode-path-segment $large_face_list_id)} | format pattern "/largefacelists/{large_face_list_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve a large face list’s largeFaceListId, name, userData and recognitionModel.
#
# GET /largefacelists/{largeFaceListId}
# operationId: LargeFaceList_Get
export def "largefacelists list-large-face-get" [
  large_face_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-recognition-model: oneof<nothing, bool> # A value indicating whether the operation should return 'recognitionModel' in response. (default: false)
]: nothing -> record<largeFaceListId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_face_list_id | is-empty) { error make --unspanned { msg: "path parameter 'largeFaceListId' must be non-empty" } }
  let qp = [(serialize-qp "returnRecognitionModel" $return_recognition_model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({large_face_list_id: (encode-path-segment $large_face_list_id)} | format pattern "/largefacelists/{large_face_list_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"returnRecognitionModel": $return_recognition_model} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update information of a large face list.
#
# PATCH /largefacelists/{largeFaceListId}
# operationId: LargeFaceList_Update
export def "largefacelists list-large-face-update" [
  large_face_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_face_list_id | is-empty) { error make --unspanned { msg: "path parameter 'largeFaceListId' must be non-empty" } }
  let full_url = (build-url $base ({large_face_list_id: (encode-path-segment $large_face_list_id)} | format pattern "/largefacelists/{large_face_list_id}") $auth.query)
  let req_body = {"name": $name, "userData": $user_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create an empty large face list with user-specified largeFaceListId, name, an optional userData and recognitionModel. Large face list is a list of faces, up to 1,000,000 faces, and used by [Face - Find Similar](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395237). After creation, user should use [LargeFaceList Face - Add](/docs/services/563879b61984550e40cbbe8d/operations/5a158c10d2de3616c086f2d3) to import the faces and [LargeFaceList - Train](/docs/services/563879b61984550e40cbbe8d/operations/5a158422d2de3616c086f2d1) to make it ready for [Face - Find Similar](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395237). No image will be stored. Only the extracted face features are stored on server until [LargeFaceList - Delete](/docs/services/563879b61984550e40cbbe8d/operations/5a1580d5d2de3616c086f2cd) is called. Find Similar is used for scenario like finding celebrity-like faces, similar face filtering, or as a light way face identification. But if the actual use is to identify person, please use [PersonGroup](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395244) / [LargePersonGroup](/docs/services/563879b61984550e40cbbe8d/operations/599acdee6ac60f11b48b5a9d) and [Face - Identify](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395239). 'recognitionModel' should be specified to associate with this large face list. The default value for 'recognitionModel' is 'recognition_01', if the latest model needed, please explicitly specify the model you need in this parameter. New faces that are added to an existing large face list will use the recognition model that's already associated with the collection. Existing face features in a large face list can't be updated to features extracted by another version of recognition model. * 'recognition_01': The default recognition model for [LargeFaceList- Create](/docs/services/563879b61984550e40cbbe8d/operations/5a157b68d2de3616c086f2cc). All those large face lists created before 2019 March are bonded with this recognition model. * 'recognition_02': Recognition model released in 2019 March. 'recognition_02' is recommended since its overall accuracy is improved compared with 'recognition_01'. Large face list quota: * Free-tier subscription quota: 64 large face lists. * S0-tier subscription quota: 1,000,000 large face lists.
#
# PUT /largefacelists/{largeFaceListId}
# operationId: LargeFaceList_Create
export def "largefacelists list-large-face-create" [
  large_face_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recognition-model: string@recognition-model-completer # Name of recognition model. Recognition model is used when the face features are extracted and associated with detected faceIds, (Large)FaceList or (Large)PersonGroup. A recognition model name can be provided when performing Face - Detect or (Large)FaceList - Create or (Large)PersonGroup - Create. The default value is 'recognition_01', if latest model needed, please explicitly specify the model you need. (default: recognition_01)
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_face_list_id | is-empty) { error make --unspanned { msg: "path parameter 'largeFaceListId' must be non-empty" } }
  let full_url = (build-url $base ({large_face_list_id: (encode-path-segment $large_face_list_id)} | format pattern "/largefacelists/{large_face_list_id}") $auth.query)
  let req_body = {"recognitionModel": $recognition_model, "name": $name, "userData": $user_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# List all faces in a large face list, and retrieve face information (including userData and persistedFaceIds of registered faces of the face).
#
# GET /largefacelists/{largeFaceListId}/persistedfaces
# operationId: LargeFaceList_ListFaces
export def "largefacelists-persistedfaces list-large-face-faces" [
  large_face_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Starting face id to return (used to list a range of faces).
  --top: int # Number of faces to return starting with the face id indicated by the 'start' parameter.
]: nothing -> table<persistedFaceId: string, userData: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_face_list_id | is-empty) { error make --unspanned { msg: "path parameter 'largeFaceListId' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({large_face_list_id: (encode-path-segment $large_face_list_id)} | format pattern "/largefacelists/{large_face_list_id}/persistedfaces") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start": $start, "top": $top} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a face to a specified large face list, up to 1,000,000 faces. To deal with an image contains multiple faces, input face can be specified as an image with a targetFace rectangle. It returns a persistedFaceId representing the added face. No image will be stored. Only the extracted face feature will be stored on server until [LargeFaceList Face - Delete](/docs/services/563879b61984550e40cbbe8d/operations/5a158c8ad2de3616c086f2d4) or [LargeFaceList - Delete](/docs/services/563879b61984550e40cbbe8d/operations/5a1580d5d2de3616c086f2cd) is called. Note persistedFaceId is different from faceId generated by [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236). * Higher face image quality means better recognition precision. Please consider high-quality faces: frontal, clear, and face size is 200x200 pixels (100 pixels between eyes) or bigger. * JPEG, PNG, GIF (the first frame), and BMP format are supported. The allowed image file size is from 1KB to 6MB. * "targetFace" rectangle should contain one face. Zero or multiple faces will be regarded as an error. If the provided "targetFace" rectangle is not returned from [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236), there’s no guarantee to detect and add the face successfully. * Out of detectable face size (36x36 - 4096x4096 pixels), large head-pose, or large occlusions will cause failures. * Adding/deleting faces to/from a same face list are processed sequentially and to/from different face lists are in parallel. * The minimum detectable face size is 36x36 pixels in an image no larger than 1920x1080 pixels. Images with dimensions higher than 1920x1080 pixels will need a proportionally larger minimum face size. * Different 'detectionModel' values can be provided. To use and compare different detection models, please refer to [How to specify a detection model](https://docs.microsoft.com/en-us/azure/cognitive-services/face/face-api-how-to-topics/specify-detection-model) | Model | Recommended use-case(s) | | ---------- | -------- | | 'detection_01': | The default detection model for [LargeFaceList - Add Face](/docs/services/563879b61984550e40cbbe8d/operations/5a158c10d2de3616c086f2d3). Recommend for near frontal face detection. For scenarios with exceptionally large angle (head-pose) faces, occluded faces or wrong image orientation, the faces in such cases may not be detected. | | 'detection_02': | Detection model released in 2019 May with improved accuracy especially on small, side and blurry faces. | Quota: * Free-tier subscription quota: 1,000 faces per large face list. * S0-tier subscription quota: 1,000,000 faces per large face list.
#
# POST /largefacelists/{largeFaceListId}/persistedfaces
# operationId: LargeFaceList_AddFaceFromUrl
export def "largefacelists-persistedfaces list-large-face-create-face-from-url" [
  large_face_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-data: string # User-specified data about the face for any purpose. The maximum length is 1KB.
  --target-face: list<int> # A face rectangle to specify the target face to be added to a person in the format of "targetFace=left,top,width,height". E.g. "targetFace=10,10,100,100". If there is more than one face in the image, targetFace is required to specify which face to add. No targetFace means there is only one face detected in the entire image.
  --detection-model: string@detection-model-completer # Name of detection model. Detection model is used to detect faces in the submitted image. A detection model name can be provided when performing Face - Detect or (Large)FaceList - Add Face or (Large)PersonGroup - Add Face. The default value is 'detection_01', if another model is needed, please explicitly specify it. (default: detection_01)
  url: string # Publicly reachable URL of an image
]: any -> record<persistedFaceId: string, userData: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_face_list_id | is-empty) { error make --unspanned { msg: "path parameter 'largeFaceListId' must be non-empty" } }
  let qp = [(serialize-qp "userData" $user_data "scalar") (serialize-qp "targetFace" $target_face "csv") (serialize-qp "detectionModel" $detection_model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({large_face_list_id: (encode-path-segment $large_face_list_id)} | format pattern "/largefacelists/{large_face_list_id}/persistedfaces") $qp $auth.query)
  let req_body = {"url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"userData": $user_data, "targetFace": $target_face, "detectionModel": $detection_model} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete a face from a large face list by specified largeFaceListId and persistedFaceId. Adding/deleting faces to/from a same large face list are processed sequentially and to/from different large face lists are in parallel.
#
# DELETE /largefacelists/{largeFaceListId}/persistedfaces/{persistedFaceId}
# operationId: LargeFaceList_DeleteFace
export def "largefacelists-persistedfaces list-large-face-delete-face" [
  large_face_list_id: string
  persisted_face_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_face_list_id | is-empty) { error make --unspanned { msg: "path parameter 'largeFaceListId' must be non-empty" } }
  if ($persisted_face_id | is-empty) { error make --unspanned { msg: "path parameter 'persistedFaceId' must be non-empty" } }
  let full_url = (build-url $base ({large_face_list_id: (encode-path-segment $large_face_list_id), persisted_face_id: (encode-path-segment $persisted_face_id)} | format pattern "/largefacelists/{large_face_list_id}/persistedfaces/{persisted_face_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve information about a persisted face (specified by persistedFaceId and its belonging largeFaceListId).
#
# GET /largefacelists/{largeFaceListId}/persistedfaces/{persistedFaceId}
# operationId: LargeFaceList_GetFace
export def "largefacelists-persistedfaces list-large-face-get-face" [
  large_face_list_id: string
  persisted_face_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<persistedFaceId: string, userData: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_face_list_id | is-empty) { error make --unspanned { msg: "path parameter 'largeFaceListId' must be non-empty" } }
  if ($persisted_face_id | is-empty) { error make --unspanned { msg: "path parameter 'persistedFaceId' must be non-empty" } }
  let full_url = (build-url $base ({large_face_list_id: (encode-path-segment $large_face_list_id), persisted_face_id: (encode-path-segment $persisted_face_id)} | format pattern "/largefacelists/{large_face_list_id}/persistedfaces/{persisted_face_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a persisted face's userData field.
#
# PATCH /largefacelists/{largeFaceListId}/persistedfaces/{persistedFaceId}
# operationId: LargeFaceList_UpdateFace
export def "largefacelists-persistedfaces list-large-face-update-face" [
  large_face_list_id: string
  persisted_face_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-data: string # User-provided data attached to the face. The size limit is 1KB.
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_face_list_id | is-empty) { error make --unspanned { msg: "path parameter 'largeFaceListId' must be non-empty" } }
  if ($persisted_face_id | is-empty) { error make --unspanned { msg: "path parameter 'persistedFaceId' must be non-empty" } }
  let full_url = (build-url $base ({large_face_list_id: (encode-path-segment $large_face_list_id), persisted_face_id: (encode-path-segment $persisted_face_id)} | format pattern "/largefacelists/{large_face_list_id}/persistedfaces/{persisted_face_id}") $auth.query)
  let req_body = {"userData": $user_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Queue a large face list training task, the training task may not be started immediately.
#
# POST /largefacelists/{largeFaceListId}/train
# operationId: LargeFaceList_Train
export def "largefacelists-train list-large-face" [
  large_face_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_face_list_id | is-empty) { error make --unspanned { msg: "path parameter 'largeFaceListId' must be non-empty" } }
  let full_url = (build-url $base ({large_face_list_id: (encode-path-segment $large_face_list_id)} | format pattern "/largefacelists/{large_face_list_id}/train") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [202]
}

# Retrieve the training status of a large face list (completed or ongoing).
#
# GET /largefacelists/{largeFaceListId}/training
# operationId: LargeFaceList_GetTrainingStatus
export def "largefacelists-training list-large-face-get-status" [
  large_face_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdDateTime: string, lastActionDateTime: string, lastSuccessfulTrainingDateTime: string, message: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_face_list_id | is-empty) { error make --unspanned { msg: "path parameter 'largeFaceListId' must be non-empty" } }
  let full_url = (build-url $base ({large_face_list_id: (encode-path-segment $large_face_list_id)} | format pattern "/largefacelists/{large_face_list_id}/training") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List all existing large person groups’ largePersonGroupId, name, userData and recognitionModel. * Large person groups are stored in alphabetical order of largePersonGroupId. * "start" parameter (string, optional) is a user-provided largePersonGroupId value that returned entries have larger ids by string comparison. "start" set to empty to indicate return from the first item. * "top" parameter (int, optional) specifies the number of entries to return. A maximal of 1000 entries can be returned in one call. To fetch more, you can specify "start" with the last returned entry’s Id of the current call. For example, total 5 large person groups: "group1", ..., "group5". "start=&top=" will return all 5 groups. "start=&top=2" will return "group1", "group2". "start=group2&top=3" will return "group3", "group4", "group5".
#
# GET /largepersongroups
# operationId: LargePersonGroup_List
export def "largepersongroups list-large-person-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # List large person groups from the least largePersonGroupId greater than the "start".
  --top: int # The number of large person groups to list. (default: 1000)
  --return-recognition-model: oneof<nothing, bool> # A value indicating whether the operation should return 'recognitionModel' in response. (default: false)
]: nothing -> table<largePersonGroupId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "returnRecognitionModel" $return_recognition_model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/largepersongroups" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start": $start, "top": $top, "returnRecognitionModel": $return_recognition_model} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete an existing large person group. Persisted face features of all people in the large person group will also be deleted.
#
# DELETE /largepersongroups/{largePersonGroupId}
# operationId: LargePersonGroup_Delete
export def "largepersongroups delete-large-person-group" [
  large_person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'largePersonGroupId' must be non-empty" } }
  let full_url = (build-url $base ({large_person_group_id: (encode-path-segment $large_person_group_id)} | format pattern "/largepersongroups/{large_person_group_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve the information of a large person group, including its name, userData and recognitionModel. This API returns large person group information only, use [LargePersonGroup Person - List](/docs/services/563879b61984550e40cbbe8d/operations/599adda06ac60f11b48b5aa1) instead to retrieve person information under the large person group.
#
# GET /largepersongroups/{largePersonGroupId}
# operationId: LargePersonGroup_Get
export def "largepersongroups get-large-person-group" [
  large_person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-recognition-model: oneof<nothing, bool> # A value indicating whether the operation should return 'recognitionModel' in response. (default: false)
]: nothing -> record<largePersonGroupId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'largePersonGroupId' must be non-empty" } }
  let qp = [(serialize-qp "returnRecognitionModel" $return_recognition_model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({large_person_group_id: (encode-path-segment $large_person_group_id)} | format pattern "/largepersongroups/{large_person_group_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"returnRecognitionModel": $return_recognition_model} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update an existing large person group's display name and userData. The properties which does not appear in request body will not be updated.
#
# PATCH /largepersongroups/{largePersonGroupId}
# operationId: LargePersonGroup_Update
export def "largepersongroups update-large-person-group" [
  large_person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'largePersonGroupId' must be non-empty" } }
  let full_url = (build-url $base ({large_person_group_id: (encode-path-segment $large_person_group_id)} | format pattern "/largepersongroups/{large_person_group_id}") $auth.query)
  let req_body = {"name": $name, "userData": $user_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create a new large person group with user-specified largePersonGroupId, name, an optional userData and recognitionModel. A large person group is the container of the uploaded person data, including face recognition feature, and up to 1,000,000 people. After creation, use [LargePersonGroup Person - Create](/docs/services/563879b61984550e40cbbe8d/operations/599adcba3a7b9412a4d53f40) to add person into the group, and call [LargePersonGroup - Train](/docs/services/563879b61984550e40cbbe8d/operations/599ae2d16ac60f11b48b5aa4) to get this group ready for [Face - Identify](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395239). No image will be stored. Only the person's extracted face features and userData will be stored on server until [LargePersonGroup Person - Delete](/docs/services/563879b61984550e40cbbe8d/operations/599ade5c6ac60f11b48b5aa2) or [LargePersonGroup - Delete](/docs/services/563879b61984550e40cbbe8d/operations/599adc216ac60f11b48b5a9f) is called. 'recognitionModel' should be specified to associate with this large person group. The default value for 'recognitionModel' is 'recognition_01', if the latest model needed, please explicitly specify the model you need in this parameter. New faces that are added to an existing large person group will use the recognition model that's already associated with the collection. Existing face features in a large person group can't be updated to features extracted by another version of recognition model. * 'recognition_01': The default recognition model for [LargePersonGroup - Create](/docs/services/563879b61984550e40cbbe8d/operations/599acdee6ac60f11b48b5a9d). All those large person groups created before 2019 March are bonded with this recognition model. * 'recognition_02': Recognition model released in 2019 March. 'recognition_02' is recommended since its overall accuracy is improved compared with 'recognition_01'. Large person group quota: * Free-tier subscription quota: 1,000 large person groups. * S0-tier subscription quota: 1,000,000 large person groups.
#
# PUT /largepersongroups/{largePersonGroupId}
# operationId: LargePersonGroup_Create
export def "largepersongroups create-large-person-group" [
  large_person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recognition-model: string@recognition-model-completer # Name of recognition model. Recognition model is used when the face features are extracted and associated with detected faceIds, (Large)FaceList or (Large)PersonGroup. A recognition model name can be provided when performing Face - Detect or (Large)FaceList - Create or (Large)PersonGroup - Create. The default value is 'recognition_01', if latest model needed, please explicitly specify the model you need. (default: recognition_01)
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'largePersonGroupId' must be non-empty" } }
  let full_url = (build-url $base ({large_person_group_id: (encode-path-segment $large_person_group_id)} | format pattern "/largepersongroups/{large_person_group_id}") $auth.query)
  let req_body = {"recognitionModel": $recognition_model, "name": $name, "userData": $user_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# List all persons in a large person group, and retrieve person information (including personId, name, userData and persistedFaceIds of registered faces of the person).
#
# GET /largepersongroups/{largePersonGroupId}/persons
# operationId: LargePersonGroupPerson_List
export def "largepersongroups-persons list-large-group" [
  large_person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Starting person id to return (used to list a range of persons).
  --top: int # Number of persons to return starting with the person id indicated by the 'start' parameter.
]: nothing -> table<persistedFaceIds: list<string>, personId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'largePersonGroupId' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({large_person_group_id: (encode-path-segment $large_person_group_id)} | format pattern "/largepersongroups/{large_person_group_id}/persons") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start": $start, "top": $top} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new person in a specified large person group.
#
# POST /largepersongroups/{largePersonGroupId}/persons
# operationId: LargePersonGroupPerson_Create
export def "largepersongroups-persons create-large-group" [
  large_person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> record<persistedFaceIds: list<string>, personId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'largePersonGroupId' must be non-empty" } }
  let full_url = (build-url $base ({large_person_group_id: (encode-path-segment $large_person_group_id)} | format pattern "/largepersongroups/{large_person_group_id}/persons") $auth.query)
  let req_body = {"name": $name, "userData": $user_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete an existing person from a large person group. The persistedFaceId, userData, person name and face feature in the person entry will all be deleted.
#
# DELETE /largepersongroups/{largePersonGroupId}/persons/{personId}
# operationId: LargePersonGroupPerson_Delete
export def "largepersongroups-persons delete-large-group" [
  large_person_group_id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'largePersonGroupId' must be non-empty" } }
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  let full_url = (build-url $base ({large_person_group_id: (encode-path-segment $large_person_group_id), person_id: (encode-path-segment $person_id)} | format pattern "/largepersongroups/{large_person_group_id}/persons/{person_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve a person's name and userData, and the persisted faceIds representing the registered person face feature.
#
# GET /largepersongroups/{largePersonGroupId}/persons/{personId}
# operationId: LargePersonGroupPerson_Get
export def "largepersongroups-persons get-large-group" [
  large_person_group_id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<persistedFaceIds: list<string>, personId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'largePersonGroupId' must be non-empty" } }
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  let full_url = (build-url $base ({large_person_group_id: (encode-path-segment $large_person_group_id), person_id: (encode-path-segment $person_id)} | format pattern "/largepersongroups/{large_person_group_id}/persons/{person_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update name or userData of a person.
#
# PATCH /largepersongroups/{largePersonGroupId}/persons/{personId}
# operationId: LargePersonGroupPerson_Update
export def "largepersongroups-persons update-large-group" [
  large_person_group_id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'largePersonGroupId' must be non-empty" } }
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  let full_url = (build-url $base ({large_person_group_id: (encode-path-segment $large_person_group_id), person_id: (encode-path-segment $person_id)} | format pattern "/largepersongroups/{large_person_group_id}/persons/{person_id}") $auth.query)
  let req_body = {"name": $name, "userData": $user_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Add a face to a person into a large person group for face identification or verification. To deal with an image contains multiple faces, input face can be specified as an image with a targetFace rectangle. It returns a persistedFaceId representing the added face. No image will be stored. Only the extracted face feature will be stored on server until [LargePersonGroup PersonFace - Delete](/docs/services/563879b61984550e40cbbe8d/operations/599ae2966ac60f11b48b5aa3), [LargePersonGroup Person - Delete](/docs/services/563879b61984550e40cbbe8d/operations/599ade5c6ac60f11b48b5aa2) or [LargePersonGroup - Delete](/docs/services/563879b61984550e40cbbe8d/operations/599adc216ac60f11b48b5a9f) is called. Note persistedFaceId is different from faceId generated by [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236). * Higher face image quality means better recognition precision. Please consider high-quality faces: frontal, clear, and face size is 200x200 pixels (100 pixels between eyes) or bigger. * Each person entry can hold up to 248 faces. * JPEG, PNG, GIF (the first frame), and BMP format are supported. The allowed image file size is from 1KB to 6MB. * "targetFace" rectangle should contain one face. Zero or multiple faces will be regarded as an error. If the provided "targetFace" rectangle is not returned from [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236), there’s no guarantee to detect and add the face successfully. * Out of detectable face size (36x36 - 4096x4096 pixels), large head-pose, or large occlusions will cause failures. * Adding/deleting faces to/from a same person will be processed sequentially. Adding/deleting faces to/from different persons are processed in parallel. * The minimum detectable face size is 36x36 pixels in an image no larger than 1920x1080 pixels. Images with dimensions higher than 1920x1080 pixels will need a proportionally larger minimum face size. * Different 'detectionModel' values can be provided. To use and compare different detection models, please refer to [How to specify a detection model](https://docs.microsoft.com/en-us/azure/cognitive-services/face/face-api-how-to-topics/specify-detection-model) | Model | Recommended use-case(s) | | ---------- | -------- | | 'detection_01': | The default detection model for [LargePersonGroup Person - Add Face](/docs/services/563879b61984550e40cbbe8d/operations/599adf2a3a7b9412a4d53f42). Recommend for near frontal face detection. For scenarios with exceptionally large angle (head-pose) faces, occluded faces or wrong image orientation, the faces in such cases may not be detected. | | 'detection_02': | Detection model released in 2019 May with improved accuracy especially on small, side and blurry faces. |
#
# POST /largepersongroups/{largePersonGroupId}/persons/{personId}/persistedfaces
# operationId: LargePersonGroupPerson_AddFaceFromUrl
export def "largepersongroups-persons-persistedfaces create-large-group-face-from-url" [
  large_person_group_id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-data: string # User-specified data about the face for any purpose. The maximum length is 1KB.
  --target-face: list<int> # A face rectangle to specify the target face to be added to a person in the format of "targetFace=left,top,width,height". E.g. "targetFace=10,10,100,100". If there is more than one face in the image, targetFace is required to specify which face to add. No targetFace means there is only one face detected in the entire image.
  --detection-model: string@detection-model-completer # Name of detection model. Detection model is used to detect faces in the submitted image. A detection model name can be provided when performing Face - Detect or (Large)FaceList - Add Face or (Large)PersonGroup - Add Face. The default value is 'detection_01', if another model is needed, please explicitly specify it. (default: detection_01)
  url: string # Publicly reachable URL of an image
]: any -> record<persistedFaceId: string, userData: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'largePersonGroupId' must be non-empty" } }
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  let qp = [(serialize-qp "userData" $user_data "scalar") (serialize-qp "targetFace" $target_face "csv") (serialize-qp "detectionModel" $detection_model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({large_person_group_id: (encode-path-segment $large_person_group_id), person_id: (encode-path-segment $person_id)} | format pattern "/largepersongroups/{large_person_group_id}/persons/{person_id}/persistedfaces") $qp $auth.query)
  let req_body = {"url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"userData": $user_data, "targetFace": $target_face, "detectionModel": $detection_model} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete a face from a person in a large person group by specified largePersonGroupId, personId and persistedFaceId. Adding/deleting faces to/from a same person will be processed sequentially. Adding/deleting faces to/from different persons are processed in parallel.
#
# DELETE /largepersongroups/{largePersonGroupId}/persons/{personId}/persistedfaces/{persistedFaceId}
# operationId: LargePersonGroupPerson_DeleteFace
export def "largepersongroups-persons-persistedfaces delete-large-group-face" [
  large_person_group_id: string
  person_id: string
  persisted_face_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'largePersonGroupId' must be non-empty" } }
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  if ($persisted_face_id | is-empty) { error make --unspanned { msg: "path parameter 'persistedFaceId' must be non-empty" } }
  let full_url = (build-url $base ({large_person_group_id: (encode-path-segment $large_person_group_id), person_id: (encode-path-segment $person_id), persisted_face_id: (encode-path-segment $persisted_face_id)} | format pattern "/largepersongroups/{large_person_group_id}/persons/{person_id}/persistedfaces/{persisted_face_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve information about a persisted face (specified by persistedFaceId, personId and its belonging largePersonGroupId).
#
# GET /largepersongroups/{largePersonGroupId}/persons/{personId}/persistedfaces/{persistedFaceId}
# operationId: LargePersonGroupPerson_GetFace
export def "largepersongroups-persons-persistedfaces get-large-group-face" [
  large_person_group_id: string
  person_id: string
  persisted_face_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<persistedFaceId: string, userData: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'largePersonGroupId' must be non-empty" } }
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  if ($persisted_face_id | is-empty) { error make --unspanned { msg: "path parameter 'persistedFaceId' must be non-empty" } }
  let full_url = (build-url $base ({large_person_group_id: (encode-path-segment $large_person_group_id), person_id: (encode-path-segment $person_id), persisted_face_id: (encode-path-segment $persisted_face_id)} | format pattern "/largepersongroups/{large_person_group_id}/persons/{person_id}/persistedfaces/{persisted_face_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a person persisted face's userData field.
#
# PATCH /largepersongroups/{largePersonGroupId}/persons/{personId}/persistedfaces/{persistedFaceId}
# operationId: LargePersonGroupPerson_UpdateFace
export def "largepersongroups-persons-persistedfaces update-large-group-face" [
  large_person_group_id: string
  person_id: string
  persisted_face_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-data: string # User-provided data attached to the face. The size limit is 1KB.
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'largePersonGroupId' must be non-empty" } }
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  if ($persisted_face_id | is-empty) { error make --unspanned { msg: "path parameter 'persistedFaceId' must be non-empty" } }
  let full_url = (build-url $base ({large_person_group_id: (encode-path-segment $large_person_group_id), person_id: (encode-path-segment $person_id), persisted_face_id: (encode-path-segment $persisted_face_id)} | format pattern "/largepersongroups/{large_person_group_id}/persons/{person_id}/persistedfaces/{persisted_face_id}") $auth.query)
  let req_body = {"userData": $user_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Queue a large person group training task, the training task may not be started immediately.
#
# POST /largepersongroups/{largePersonGroupId}/train
# operationId: LargePersonGroup_Train
export def "largepersongroups-train create-large-person-group" [
  large_person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'largePersonGroupId' must be non-empty" } }
  let full_url = (build-url $base ({large_person_group_id: (encode-path-segment $large_person_group_id)} | format pattern "/largepersongroups/{large_person_group_id}/train") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [202]
}

# Retrieve the training status of a large person group (completed or ongoing).
#
# GET /largepersongroups/{largePersonGroupId}/training
# operationId: LargePersonGroup_GetTrainingStatus
export def "largepersongroups-training get-large-person-group-status" [
  large_person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdDateTime: string, lastActionDateTime: string, lastSuccessfulTrainingDateTime: string, message: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($large_person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'largePersonGroupId' must be non-empty" } }
  let full_url = (build-url $base ({large_person_group_id: (encode-path-segment $large_person_group_id)} | format pattern "/largepersongroups/{large_person_group_id}/training") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve the status of a take/apply snapshot operation.
#
# GET /operations/{operationId}
# operationId: Snapshot_GetOperationStatus
export def "operations get-snapshot-status" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdTime: string, lastActionTime: string, message: string, resourceLocation: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operationId' must be non-empty" } }
  let full_url = (build-url $base ({operation_id: (encode-path-segment $operation_id)} | format pattern "/operations/{operation_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List person groups’ personGroupId, name, userData and recognitionModel. * Person groups are stored in alphabetical order of personGroupId. * "start" parameter (string, optional) is a user-provided personGroupId value that returned entries have larger ids by string comparison. "start" set to empty to indicate return from the first item. * "top" parameter (int, optional) specifies the number of entries to return. A maximal of 1000 entries can be returned in one call. To fetch more, you can specify "start" with the last returned entry’s Id of the current call. For example, total 5 person groups: "group1", ..., "group5". "start=&top=" will return all 5 groups. "start=&top=2" will return "group1", "group2". "start=group2&top=3" will return "group3", "group4", "group5".
#
# GET /persongroups
# operationId: PersonGroup_List
export def "persongroups list-person-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # List person groups from the least personGroupId greater than the "start".
  --top: int # The number of person groups to list. (default: 1000)
  --return-recognition-model: oneof<nothing, bool> # A value indicating whether the operation should return 'recognitionModel' in response. (default: false)
]: nothing -> table<personGroupId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "returnRecognitionModel" $return_recognition_model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/persongroups" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start": $start, "top": $top, "returnRecognitionModel": $return_recognition_model} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete an existing person group. Persisted face features of all people in the person group will also be deleted.
#
# DELETE /persongroups/{personGroupId}
# operationId: PersonGroup_Delete
export def "persongroups delete-person-group" [
  person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'personGroupId' must be non-empty" } }
  let full_url = (build-url $base ({person_group_id: (encode-path-segment $person_group_id)} | format pattern "/persongroups/{person_group_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve person group name, userData and recognitionModel. To get person information under this personGroup, use [PersonGroup Person - List](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395241).
#
# GET /persongroups/{personGroupId}
# operationId: PersonGroup_Get
export def "persongroups get-person-group" [
  person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-recognition-model: oneof<nothing, bool> # A value indicating whether the operation should return 'recognitionModel' in response. (default: false)
]: nothing -> record<personGroupId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'personGroupId' must be non-empty" } }
  let qp = [(serialize-qp "returnRecognitionModel" $return_recognition_model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({person_group_id: (encode-path-segment $person_group_id)} | format pattern "/persongroups/{person_group_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"returnRecognitionModel": $return_recognition_model} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update an existing person group's display name and userData. The properties which does not appear in request body will not be updated.
#
# PATCH /persongroups/{personGroupId}
# operationId: PersonGroup_Update
export def "persongroups update-person-group" [
  person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'personGroupId' must be non-empty" } }
  let full_url = (build-url $base ({person_group_id: (encode-path-segment $person_group_id)} | format pattern "/persongroups/{person_group_id}") $auth.query)
  let req_body = {"name": $name, "userData": $user_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create a new person group with specified personGroupId, name, user-provided userData and recognitionModel. A person group is the container of the uploaded person data, including face recognition features. After creation, use [PersonGroup Person - Create](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523c) to add persons into the group, and then call [PersonGroup - Train](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395249) to get this group ready for [Face - Identify](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395239). No image will be stored. Only the person's extracted face features and userData will be stored on server until [PersonGroup Person - Delete](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523d) or [PersonGroup - Delete](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395245) is called. 'recognitionModel' should be specified to associate with this person group. The default value for 'recognitionModel' is 'recognition_01', if the latest model needed, please explicitly specify the model you need in this parameter. New faces that are added to an existing person group will use the recognition model that's already associated with the collection. Existing face features in a person group can't be updated to features extracted by another version of recognition model. * 'recognition_01': The default recognition model for [PersonGroup - Create](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395244). All those person groups created before 2019 March are bonded with this recognition model. * 'recognition_02': Recognition model released in 2019 March. 'recognition_02' is recommended since its overall accuracy is improved compared with 'recognition_01'. Person group quota: * Free-tier subscription quota: 1,000 person groups. Each holds up to 1,000 persons. * S0-tier subscription quota: 1,000,000 person groups. Each holds up to 10,000 persons. * to handle larger scale face identification problem, please consider using [LargePersonGroup](/docs/services/563879b61984550e40cbbe8d/operations/599acdee6ac60f11b48b5a9d).
#
# PUT /persongroups/{personGroupId}
# operationId: PersonGroup_Create
export def "persongroups create-person-group" [
  person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recognition-model: string@recognition-model-completer # Name of recognition model. Recognition model is used when the face features are extracted and associated with detected faceIds, (Large)FaceList or (Large)PersonGroup. A recognition model name can be provided when performing Face - Detect or (Large)FaceList - Create or (Large)PersonGroup - Create. The default value is 'recognition_01', if latest model needed, please explicitly specify the model you need. (default: recognition_01)
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'personGroupId' must be non-empty" } }
  let full_url = (build-url $base ({person_group_id: (encode-path-segment $person_group_id)} | format pattern "/persongroups/{person_group_id}") $auth.query)
  let req_body = {"recognitionModel": $recognition_model, "name": $name, "userData": $user_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# List all persons in a person group, and retrieve person information (including personId, name, userData and persistedFaceIds of registered faces of the person).
#
# GET /persongroups/{personGroupId}/persons
# operationId: PersonGroupPerson_List
export def "persongroups-persons list-group" [
  person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Starting person id to return (used to list a range of persons).
  --top: int # Number of persons to return starting with the person id indicated by the 'start' parameter.
]: nothing -> table<persistedFaceIds: list<string>, personId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'personGroupId' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({person_group_id: (encode-path-segment $person_group_id)} | format pattern "/persongroups/{person_group_id}/persons") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start": $start, "top": $top} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new person in a specified person group.
#
# POST /persongroups/{personGroupId}/persons
# operationId: PersonGroupPerson_Create
export def "persongroups-persons create-group" [
  person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> record<persistedFaceIds: list<string>, personId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'personGroupId' must be non-empty" } }
  let full_url = (build-url $base ({person_group_id: (encode-path-segment $person_group_id)} | format pattern "/persongroups/{person_group_id}/persons") $auth.query)
  let req_body = {"name": $name, "userData": $user_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete an existing person from a person group. The persistedFaceId, userData, person name and face feature in the person entry will all be deleted.
#
# DELETE /persongroups/{personGroupId}/persons/{personId}
# operationId: PersonGroupPerson_Delete
export def "persongroups-persons delete-group" [
  person_group_id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'personGroupId' must be non-empty" } }
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  let full_url = (build-url $base ({person_group_id: (encode-path-segment $person_group_id), person_id: (encode-path-segment $person_id)} | format pattern "/persongroups/{person_group_id}/persons/{person_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve a person's information, including registered persisted faces, name and userData.
#
# GET /persongroups/{personGroupId}/persons/{personId}
# operationId: PersonGroupPerson_Get
export def "persongroups-persons get-group" [
  person_group_id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<persistedFaceIds: list<string>, personId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'personGroupId' must be non-empty" } }
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  let full_url = (build-url $base ({person_group_id: (encode-path-segment $person_group_id), person_id: (encode-path-segment $person_id)} | format pattern "/persongroups/{person_group_id}/persons/{person_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update name or userData of a person.
#
# PATCH /persongroups/{personGroupId}/persons/{personId}
# operationId: PersonGroupPerson_Update
export def "persongroups-persons update-group" [
  person_group_id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'personGroupId' must be non-empty" } }
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  let full_url = (build-url $base ({person_group_id: (encode-path-segment $person_group_id), person_id: (encode-path-segment $person_id)} | format pattern "/persongroups/{person_group_id}/persons/{person_id}") $auth.query)
  let req_body = {"name": $name, "userData": $user_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Add a face to a person into a person group for face identification or verification. To deal with an image contains multiple faces, input face can be specified as an image with a targetFace rectangle. It returns a persistedFaceId representing the added face. No image will be stored. Only the extracted face feature will be stored on server until [PersonGroup PersonFace - Delete](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523e), [PersonGroup Person - Delete](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523d) or [PersonGroup - Delete](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395245) is called. Note persistedFaceId is different from faceId generated by [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236). * Higher face image quality means better recognition precision. Please consider high-quality faces: frontal, clear, and face size is 200x200 pixels (100 pixels between eyes) or bigger. * Each person entry can hold up to 248 faces. * JPEG, PNG, GIF (the first frame), and BMP format are supported. The allowed image file size is from 1KB to 6MB. * "targetFace" rectangle should contain one face. Zero or multiple faces will be regarded as an error. If the provided "targetFace" rectangle is not returned from [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236), there’s no guarantee to detect and add the face successfully. * Out of detectable face size (36x36 - 4096x4096 pixels), large head-pose, or large occlusions will cause failures. * Adding/deleting faces to/from a same person will be processed sequentially. Adding/deleting faces to/from different persons are processed in parallel. * The minimum detectable face size is 36x36 pixels in an image no larger than 1920x1080 pixels. Images with dimensions higher than 1920x1080 pixels will need a proportionally larger minimum face size. * Different 'detectionModel' values can be provided. To use and compare different detection models, please refer to [How to specify a detection model](https://docs.microsoft.com/en-us/azure/cognitive-services/face/face-api-how-to-topics/specify-detection-model) | Model | Recommended use-case(s) | | ---------- | -------- | | 'detection_01': | The default detection model for [PersonGroup Person - Add Face](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523b). Recommend for near frontal face detection. For scenarios with exceptionally large angle (head-pose) faces, occluded faces or wrong image orientation, the faces in such cases may not be detected. | | 'detection_02': | Detection model released in 2019 May with improved accuracy especially on small, side and blurry faces. |
#
# POST /persongroups/{personGroupId}/persons/{personId}/persistedfaces
# operationId: PersonGroupPerson_AddFaceFromUrl
export def "persongroups-persons-persistedfaces create-group-face-from-url" [
  person_group_id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-data: string # User-specified data about the face for any purpose. The maximum length is 1KB.
  --target-face: list<int> # A face rectangle to specify the target face to be added to a person in the format of "targetFace=left,top,width,height". E.g. "targetFace=10,10,100,100". If there is more than one face in the image, targetFace is required to specify which face to add. No targetFace means there is only one face detected in the entire image.
  --detection-model: string@detection-model-completer # Name of detection model. Detection model is used to detect faces in the submitted image. A detection model name can be provided when performing Face - Detect or (Large)FaceList - Add Face or (Large)PersonGroup - Add Face. The default value is 'detection_01', if another model is needed, please explicitly specify it. (default: detection_01)
  url: string # Publicly reachable URL of an image
]: any -> record<persistedFaceId: string, userData: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'personGroupId' must be non-empty" } }
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  let qp = [(serialize-qp "userData" $user_data "scalar") (serialize-qp "targetFace" $target_face "csv") (serialize-qp "detectionModel" $detection_model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({person_group_id: (encode-path-segment $person_group_id), person_id: (encode-path-segment $person_id)} | format pattern "/persongroups/{person_group_id}/persons/{person_id}/persistedfaces") $qp $auth.query)
  let req_body = {"url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"userData": $user_data, "targetFace": $target_face, "detectionModel": $detection_model} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete a face from a person in a person group by specified personGroupId, personId and persistedFaceId. Adding/deleting faces to/from a same person will be processed sequentially. Adding/deleting faces to/from different persons are processed in parallel.
#
# DELETE /persongroups/{personGroupId}/persons/{personId}/persistedfaces/{persistedFaceId}
# operationId: PersonGroupPerson_DeleteFace
export def "persongroups-persons-persistedfaces delete-group-face" [
  person_group_id: string
  person_id: string
  persisted_face_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'personGroupId' must be non-empty" } }
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  if ($persisted_face_id | is-empty) { error make --unspanned { msg: "path parameter 'persistedFaceId' must be non-empty" } }
  let full_url = (build-url $base ({person_group_id: (encode-path-segment $person_group_id), person_id: (encode-path-segment $person_id), persisted_face_id: (encode-path-segment $persisted_face_id)} | format pattern "/persongroups/{person_group_id}/persons/{person_id}/persistedfaces/{persisted_face_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve information about a persisted face (specified by persistedFaceId, personId and its belonging personGroupId).
#
# GET /persongroups/{personGroupId}/persons/{personId}/persistedfaces/{persistedFaceId}
# operationId: PersonGroupPerson_GetFace
export def "persongroups-persons-persistedfaces get-group-face" [
  person_group_id: string
  person_id: string
  persisted_face_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<persistedFaceId: string, userData: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'personGroupId' must be non-empty" } }
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  if ($persisted_face_id | is-empty) { error make --unspanned { msg: "path parameter 'persistedFaceId' must be non-empty" } }
  let full_url = (build-url $base ({person_group_id: (encode-path-segment $person_group_id), person_id: (encode-path-segment $person_id), persisted_face_id: (encode-path-segment $persisted_face_id)} | format pattern "/persongroups/{person_group_id}/persons/{person_id}/persistedfaces/{persisted_face_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a face to a person into a person group for face identification or verification. To deal with an image contains multiple faces, input face can be specified as an image with a targetFace rectangle. It returns a persistedFaceId representing the added face. No image will be stored. Only the extracted face feature will be stored on server until [PersonGroup PersonFace - Delete](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523e), [PersonGroup Person - Delete](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523d) or [PersonGroup - Delete](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395245) is called. Note persistedFaceId is different from faceId generated by [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236). * Higher face image quality means better recognition precision. Please consider high-quality faces: frontal, clear, and face size is 200x200 pixels (100 pixels between eyes) or bigger. * Each person entry can hold up to 248 faces. * JPEG, PNG, GIF (the first frame), and BMP format are supported. The allowed image file size is from 1KB to 6MB. * "targetFace" rectangle should contain one face. Zero or multiple faces will be regarded as an error. If the provided "targetFace" rectangle is not returned from [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236), there’s no guarantee to detect and add the face successfully. * Out of detectable face size (36x36 - 4096x4096 pixels), large head-pose, or large occlusions will cause failures. * Adding/deleting faces to/from a same person will be processed sequentially. Adding/deleting faces to/from different persons are processed in parallel.
#
# PATCH /persongroups/{personGroupId}/persons/{personId}/persistedfaces/{persistedFaceId}
# operationId: PersonGroupPerson_UpdateFace
export def "persongroups-persons-persistedfaces update-group-face" [
  person_group_id: string
  person_id: string
  persisted_face_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-data: string # User-provided data attached to the face. The size limit is 1KB.
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'personGroupId' must be non-empty" } }
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  if ($persisted_face_id | is-empty) { error make --unspanned { msg: "path parameter 'persistedFaceId' must be non-empty" } }
  let full_url = (build-url $base ({person_group_id: (encode-path-segment $person_group_id), person_id: (encode-path-segment $person_id), persisted_face_id: (encode-path-segment $persisted_face_id)} | format pattern "/persongroups/{person_group_id}/persons/{person_id}/persistedfaces/{persisted_face_id}") $auth.query)
  let req_body = {"userData": $user_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Queue a person group training task, the training task may not be started immediately.
#
# POST /persongroups/{personGroupId}/train
# operationId: PersonGroup_Train
export def "persongroups-train create-person-group" [
  person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'personGroupId' must be non-empty" } }
  let full_url = (build-url $base ({person_group_id: (encode-path-segment $person_group_id)} | format pattern "/persongroups/{person_group_id}/train") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [202]
}

# Retrieve the training status of a person group (completed or ongoing).
#
# GET /persongroups/{personGroupId}/training
# operationId: PersonGroup_GetTrainingStatus
export def "persongroups-training get-person-group-status" [
  person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdDateTime: string, lastActionDateTime: string, lastSuccessfulTrainingDateTime: string, message: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($person_group_id | is-empty) { error make --unspanned { msg: "path parameter 'personGroupId' must be non-empty" } }
  let full_url = (build-url $base ({person_group_id: (encode-path-segment $person_group_id)} | format pattern "/persongroups/{person_group_id}/training") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List all accessible snapshots with related information, including snapshots that were taken by the user, or snapshots to be applied to the user (subscription id was included in the applyScope in Snapshot - Take).
#
# GET /snapshots
# operationId: Snapshot_List
export def "snapshots list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # User specified object type as a search filter.
  --apply-scope: list<string> # User specified snapshot apply scopes as a search filter. ApplyScope is an array of the target Azure subscription ids for the snapshot, specified by the user who created the snapshot by Snapshot - Take.
]: nothing -> table<account: string, applyScope: list<string>, createdTime: string, id: string, lastUpdateTime: string, type: string, userData: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "applyScope" $apply_scope "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/snapshots" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "applyScope": $apply_scope} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Submit an operation to take a snapshot of face list, large face list, person group or large person group, with user-specified snapshot type, source object id, apply scope and an optional user data. The snapshot interfaces are for users to backup and restore their face data from one face subscription to another, inside same region or across regions. The workflow contains two phases, user first calls Snapshot - Take to create a copy of the source object and store it as a snapshot, then calls Snapshot - Apply to paste the snapshot to target subscription. The snapshots are stored in a centralized location (per Azure instance), so that they can be applied cross accounts and regions. Taking snapshot is an asynchronous operation. An operation id can be obtained from the "Operation-Location" field in response header, to be used in OperationStatus - Get for tracking the progress of creating the snapshot. The snapshot id will be included in the "resourceLocation" field in OperationStatus - Get response when the operation status is "succeeded". Snapshot taking time depends on the number of person and face entries in the source object. It could be in seconds, or up to several hours for 1,000,000 persons with multiple faces. Snapshots will be automatically expired and cleaned in 48 hours after it is created by Snapshot - Take. User can delete the snapshot using Snapshot - Delete by themselves any time before expiration. Taking snapshot for a certain object will not block any other operations against the object. All read-only operations (Get/List and Identify/FindSimilar/Verify) can be conducted as usual. For all writable operations, including Add/Update/Delete the source object or its persons/faces and Train, they are not blocked but not recommended because writable updates may not be reflected on the snapshot during its taking. After snapshot taking is completed, all readable and writable operations can work as normal. Snapshot will also include the training results of the source object, which means target subscription the snapshot applied to does not need re-train the target object before calling Identify/FindSimilar. * Free-tier subscription quota: 100 take operations per month. * S0-tier subscription quota: 100 take operations per day.
#
# POST /snapshots
# operationId: Snapshot_Take
export def "snapshots create-take" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  apply_scope: list<string> # Array of the target Face subscription ids for the snapshot, specified by the user who created the snapshot when calling Snapshot - Take. For each snapshot, only subscriptions included in the applyScope of Snapshot - Take can apply it.
  object_id: string # User specified source object id to take snapshot from.
  type: string@type-completer # User specified type for the source object to take snapshot from. Currently FaceList, PersonGroup, LargeFaceList and LargePersonGroup are supported.
  --user-data: string # User specified data about the snapshot for any purpose. Length should not exceed 16KB.
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/snapshots" $auth.query)
  let req_body = {"applyScope": $apply_scope, "objectId": $object_id, "type": $type, "userData": $user_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Delete an existing snapshot according to the snapshotId. All object data and information in the snapshot will also be deleted. Only the source subscription who took the snapshot can delete the snapshot. If the user does not delete a snapshot with this API, the snapshot will still be automatically deleted in 48 hours after creation.
#
# DELETE /snapshots/{snapshotId}
# operationId: Snapshot_Delete
export def "snapshots delete" [
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let full_url = (build-url $base ({snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/snapshots/{snapshot_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve information about a snapshot. Snapshot is only accessible to the source subscription who took it, and target subscriptions included in the applyScope in Snapshot - Take.
#
# GET /snapshots/{snapshotId}
# operationId: Snapshot_Get
export def "snapshots get" [
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account: string, applyScope: list<string>, createdTime: string, id: string, lastUpdateTime: string, type: string, userData: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let full_url = (build-url $base ({snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/snapshots/{snapshot_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update the information of a snapshot. Only the source subscription who took the snapshot can update the snapshot.
#
# PATCH /snapshots/{snapshotId}
# operationId: Snapshot_Update
export def "snapshots update" [
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apply-scope: list<string> # Array of the target Face subscription ids for the snapshot, specified by the user who created the snapshot when calling Snapshot - Take. For each snapshot, only subscriptions included in the applyScope of Snapshot - Take can apply it.
  --user-data: string # User specified data about the snapshot for any purpose. Length should not exceed 16KB.
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let full_url = (build-url $base ({snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/snapshots/{snapshot_id}") $auth.query)
  let req_body = {"applyScope": $apply_scope, "userData": $user_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Submit an operation to apply a snapshot to current subscription. For each snapshot, only subscriptions included in the applyScope of Snapshot - Take can apply it. The snapshot interfaces are for users to backup and restore their face data from one face subscription to another, inside same region or across regions. The workflow contains two phases, user first calls Snapshot - Take to create a copy of the source object and store it as a snapshot, then calls Snapshot - Apply to paste the snapshot to target subscription. The snapshots are stored in a centralized location (per Azure instance), so that they can be applied cross accounts and regions. Applying snapshot is an asynchronous operation. An operation id can be obtained from the "Operation-Location" field in response header, to be used in OperationStatus - Get for tracking the progress of applying the snapshot. The target object id will be included in the "resourceLocation" field in OperationStatus - Get response when the operation status is "succeeded". Snapshot applying time depends on the number of person and face entries in the snapshot object. It could be in seconds, or up to 1 hour for 1,000,000 persons with multiple faces. Snapshots will be automatically expired and cleaned in 48 hours after it is created by Snapshot - Take. So the target subscription is required to apply the snapshot in 48 hours since its creation. Applying a snapshot will not block any other operations against the target object, however it is not recommended because the correctness cannot be guaranteed during snapshot applying. After snapshot applying is completed, all operations towards the target object can work as normal. Snapshot also includes the training results of the source object, which means target subscription the snapshot applied to does not need re-train the target object before calling Identify/FindSimilar. One snapshot can be applied multiple times in parallel, while currently only CreateNew apply mode is supported, which means the apply operation will fail if target subscription already contains an object of same type and using the same objectId. Users can specify the "objectId" in request body to avoid such conflicts. * Free-tier subscription quota: 100 apply operations per month. * S0-tier subscription quota: 100 apply operations per day.
#
# POST /snapshots/{snapshotId}/apply
# operationId: Snapshot_Apply
export def "snapshots-apply create" [
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mode: string@mode-completer-1 # Snapshot applying mode. Currently only CreateNew is supported, which means the apply operation will fail if target subscription already contains an object of same type and using the same objectId. Users can specify the "objectId" in request body to avoid such conflicts. (default: CreateNew)
  object_id: string # User specified target object id to be created from the snapshot.
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let full_url = (build-url $base ({snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/snapshots/{snapshot_id}/apply") $auth.query)
  let req_body = {"mode": $mode, "objectId": $object_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Verify whether two faces belong to a same person or whether one face belongs to a person. Remarks: * Higher face image quality means better identification precision. Please consider high-quality faces: frontal, clear, and face size is 200x200 pixels (100 pixels between eyes) or bigger. * For the scenarios that are sensitive to accuracy please make your own judgment. * The 'recognitionModel' associated with the query faces' faceIds should be the same as the 'recognitionModel' used by the target face, person group or large person group.
#
# POST /verify
# operationId: Face_VerifyFaceToFace
export def "verify verify-face-face-to-face" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  face_id1: string # FaceId of the first face, comes from Face - Detect (format: uuid)
  face_id2: string # FaceId of the second face, comes from Face - Detect (format: uuid)
]: any -> record<confidence: float, isIdentical: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/verify" $auth.query)
  let req_body = {"faceId1": $face_id1, "faceId2": $face_id2} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
