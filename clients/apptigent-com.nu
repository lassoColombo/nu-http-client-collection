# Auto-generated client for PowerTools Developer v2021.1.01
# Source: https://api.apis.guru/v2/specs/apptigent.com/2021.1.01/openapi.json
# Auth: --token flag or $env.POWERTOOLS_DEVELOPER_TOKEN

const BASE_URL = "https://connect.apptigent.com/api/utilities"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o POWERTOOLS_DEVELOPER_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-ibm-client-id" => { {scheme: $scheme, headers: {X-IBM-Client-Id: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://connect.apptigent.com/api/utilities"] }
def auth-scheme-completer [] { ["x-ibm-client-id"] }

# Completers for enum parameters
def type-completer [] { ["Maximum" "Minimum"] }
def type-completer-1 [] { ["Decimal" "Integer"] }
def ignorecase-completer [] { ["false" "true"] }
def trim-completer [] { ["false" "true"] }
def lower-completer [] { ["false" "true"] }
def source-completer [] { ["Arcminute" "Arcsecond" "Centiradian" "Deciradian" "Degree" "Gradian" "Microdegree" "Microradian" "Millidegree" "Milliradian" "Nanodegree" "Nanoradian" "Radian" "Revolution"] }
def target-completer [] { ["Arcminute" "Arcsecond" "Centiradian" "Deciradian" "Degree" "Gradian" "Microdegree" "Microradian" "Millidegree" "Milliradian" "Nanodegree" "Nanoradian" "Radian" "Revolution"] }
def source-completer-1 [] { ["Acre" "Hectare" "SquareCentimeter" "SquareDecimeter" "SquareFoot" "SquareInch" "SquareKilometer" "SquareMeter" "SquareMicrometer" "SquareMile" "SquareMillimeter" "SquareYard"] }
def target-completer-1 [] { ["Acre" "Hectare" "SquareCentimeter" "SquareDecimeter" "SquareFoot" "SquareInch" "SquareKilometer" "SquareMeter" "SquareMicrometer" "SquareMile" "SquareMillimeter" "SquareYard"] }
def alphacase-completer [] { ["Lower" "Title" "Upper"] }
def source-completer-2 [] { ["AUD" "BGN" "BRL" "CAD" "CHF" "CNY" "CZK" "DKK" "EUR" "GBP" "HKD" "HRK" "HUF" "IDR" "ILS" "INR" "ISK" "JPY" "KRW" "MXN" "MYR" "NOK" "NZD" "PHP" "PLN" "RON" "RUB" "SEK" "SGD" "THB" "TRY" "USD" "ZAR"] }
def target-completer-2 [] { ["AUD" "BGN" "BRL" "CAD" "CHF" "CNY" "CZK" "DKK" "EUR" "GBP" "HKD" "HRK" "HUF" "IDR" "ILS" "INR" "ISK" "JPY" "KRW" "MXN" "MYR" "NOK" "NZD" "PHP" "PLN" "RON" "RUB" "SEK" "SGD" "THB" "TRY" "USD" "ZAR"] }
def source-completer-3 [] { ["Centimeter" "Decimeter" "Fathom" "Foot" "Hectometer" "Inch" "Kilometer" "LightYear" "Meter" "Micrometer" "Mile" "Millimeter" "Nanometer" "NauticalMile" "Yard"] }
def target-completer-3 [] { ["Centimeter" "Decimeter" "Fathom" "Foot" "Hectometer" "Inch" "Kilometer" "LightYear" "Meter" "Micrometer" "Mile" "Millimeter" "Nanometer" "NauticalMile" "Yard"] }
def source-completer-4 [] { ["Day" "Hour" "Microsecond" "Millisecond" "Minute" "Month" "Nanosecond" "Second" "Week" "Year"] }
def target-completer-4 [] { ["Day" "Hour" "Microsecond" "Millisecond" "Minute" "Month" "Nanosecond" "Second" "Week" "Year"] }
def source-completer-5 [] { ["BritishThermalUnit" "Calorie" "ElectronVolt" "FootPound" "GigawattHour" "Joule" "Kilocalorie" "Kilojoule" "KilowattHour" "Megajoule" "MegawattHour" "TerawattHour" "Therm (EU)" "Therm (UK)" "Therm (US)" "WattHour"] }
def target-completer-5 [] { ["BritishThermalUnit" "Calorie" "ElectronVolt" "FootPound" "GigawattHour" "Joule" "Kilocalorie" "Kilojoule" "KilowattHour" "Megajoule" "MegawattHour" "TerawattHour" "Therm (EU)" "Therm (UK)" "Therm (US)" "WattHour"] }
def format-completer [] { ["BMP" "GIF" "JPG" "PNG" "TIF"] }
def accept-completer [] { ["image/bmp" "image/gif" "image/jpeg" "image/png"] }
def source-completer-6 [] { ["BritishThermalUnitPerHour" "Decawatt" "Deciwatt" "ElectricalHorsepower" "Femtowatt" "Gigawatt" "HydraulicHorsepower" "Kilowatt" "MechanicalHorsepower" "Megawatt" "Microwatt" "Milliwatt" "Nanowatt" "Petawatt" "Picowatt" "Terawatt" "Watt"] }
def target-completer-6 [] { ["BritishThermalUnitPerHour" "Decawatt" "Deciwatt" "ElectricalHorsepower" "Femtowatt" "Gigawatt" "HydraulicHorsepower" "Kilowatt" "MechanicalHorsepower" "Megawatt" "Microwatt" "Milliwatt" "Nanowatt" "Petawatt" "Picowatt" "Terawatt" "Watt"] }
def source-completer-7 [] { ["CentimeterPerHour" "CentimeterPerMinute" "CentimeterPerSecond" "DecimeterPerMinute" "DecimeterPerSecond" "FootPerHour" "FootPerMinute" "FootPerSecond" "InchPerHour" "InchPerMinute" "InchPerSecond" "KilometerPerHour" "KilometerPerMinute" "KilometerPerSecond" "Knot" "MeterPerHour" "MeterPerMinute" "MeterPerSecond" "MicrometerPerMinute" "MicrometerPerSecond" "MilePerHour" "MillimeterPerHour" "MillimeterPerMinute" "MillimeterPerSecond" "NanometerPerMinute" "NanometerPerSecond" "YardPerHour" "YardPerMinute" "YardPerSecond"] }
def target-completer-7 [] { ["CentimeterPerHour" "CentimeterPerMinute" "CentimeterPerSecond" "DecimeterPerMinute" "DecimeterPerSecond" "FootPerHour" "FootPerMinute" "FootPerSecond" "InchPerHour" "InchPerMinute" "InchPerSecond" "KilometerPerHour" "KilometerPerMinute" "KilometerPerSecond" "Knot" "MeterPerHour" "MeterPerMinute" "MeterPerSecond" "MicrometerPerMinute" "MicrometerPerSecond" "MilePerHour" "MillimeterPerHour" "MillimeterPerMinute" "MillimeterPerSecond" "NanometerPerMinute" "NanometerPerSecond" "YardPerHour" "YardPerMinute" "YardPerSecond"] }
def source-completer-8 [] { ["Celsius" "Fahrenheit" "Kelvin" "Newton"] }
def target-completer-8 [] { ["Celsius" "Fahrenheit" "Kelvin" "Newton"] }
def source-completer-9 [] { ["Centiliter" "CubicCentimeter" "CubicDecimeter" "CubicFoot" "CubicHectometer" "CubicInch" "CubicKilometer" "CubicMeter" "CubicMillimeter" "CubicYard" "Cup" "Deciliter" "Gallon" "ImperialBeerBarrel" "ImperialGallon" "ImperialOunce" "ImperialPint" "Kiloliter" "Liter" "Microliter" "Milliliter" "Ounce" "Pint" "Quart" "Tablespoon" "Teaspoon"] }
def target-completer-9 [] { ["Centiliter" "CubicCentimeter" "CubicDecimeter" "CubicFoot" "CubicHectometer" "CubicInch" "CubicKilometer" "CubicMeter" "CubicMillimeter" "CubicYard" "Cup" "Deciliter" "Gallon" "ImperialBeerBarrel" "ImperialGallon" "ImperialOunce" "ImperialPint" "Kiloliter" "Liter" "Microliter" "Milliliter" "Ounce" "Pint" "Quart" "Tablespoon" "Teaspoon"] }
def source-completer-10 [] { ["Centigram" "Decagram" "Decigram" "Earth Mass" "Grain" "Gram" "Hectogram" "Kilogram" "Long Hundredweight" "Long Ton" "Megaton" "Microgram" "Milligram" "Nanogram" "Ounce" "Pound" "Short Hundredweight" "Short Ton" "Slug" "Solar Mass" "Stone" "Ton"] }
def target-completer-10 [] { ["Centigram" "Decagram" "Decigram" "Grain" "Gram" "Hectogram" "Kilogram" "Microgram" "Milligram" "Nanogram" "Ounce" "Pound" "Stone" "Ton"] }
def position-completer [] { ["BottomCenter" "BottomLeft" "BottomRight" "MiddleCenter" "MiddleLeft" "MiddleRight" "TopCenter" "TopLeft" "TopRight"] }
def culture-completer [] { ["af-ZA" "ar-AE" "ar-BH" "ar-DZ" "ar-EG" "ar-IQ" "ar-JO" "ar-KW" "ar-LB" "ar-LY" "ar-MA" "ar-OM" "ar-QA" "ar-SA" "ar-SY" "ar-TN" "ar-YE" "az-AZ" "be-BY" "bg-BG" "bs-BA" "ca-ES" "cs-CZ" "cy-GB" "da-DK" "de-AT" "de-CH" "de-DE" "de-LI" "de-LU" "el-GR" "en-AU" "en-BZ" "en-CA" "en-CB" "en-GB" "en-IE" "en-JM" "en-NZ" "en-PH" "en-TT" "en-US" "en-ZA" "en-ZW" "es-AR" "es-BO" "es-CL" "es-CO" "es-CR" "es-DO" "es-EC" "es-ES" "es-GT" "es-HN" "es-MX" "es-NI" "es-PA" "es-PE" "es-PR" "es-PY" "es-SV" "es-UY" "es-VE" "et-EE" "eu-ES" "fa-IR" "fi-FI" "fo-FO" "fr-BE" "fr-CA" "fr-CH" "fr-FR" "fr-LU" "fr-MC" "gl-ES" "gu-IN" "he-IL" "hi-IN" "hr-BA" "hr-HR" "hu-HU" "hy-AM" "id-ID" "is-IS" "it-CH" "it-IT" "ja-JP" "ka-GE" "kk-KZ" "kn-IN" "ko-KR" "ky-KG" "lt-LT" "lv-LV" "mi-NZ" "mn-MN" "mr-IN" "ms-BN" "ms-MY" "mt-MT" "nl-BE" "nl-NL" "nn-NO" "ns-ZA" "pa-IN" "pl-PL" "ps-AR" "pt-BR" "pt-PT" "ro-RO" "ru-RU" "sa-IN" "sk-SK" "sl-SI" "sq-AL" "sr-BA" "sr-SP" "sv-FI" "sv-SE" "sw-KE" "ta-IN" "te-IN" "th-TH" "tl-PH" "tn-ZA" "tr-TR" "uk-UA" "ur-PK" "uz-UZ" "vi-VN" "zh-CN" "zh-HK" "zh-MO" "zh-SG" "zh-TW" "zu-ZA"] }
def match-completer [] { ["All" "Any" "None"] }
def orientation-completer [] { ["Horizontal" "Vertical"] }
def uppercase-completer [] { ["false" "true"] }
def algorithm-completer [] { ["MD5" "SHA1" "SHA256" "SHA384" "SHA512"] }
def payload-completer [] { ["Bitcoin Payment (address|amount|label|message)" "Bookmark (url|title)" "Calendar Event (subject|description|location|start|end|allDayEvent['true' or 'false']|format ['universal' or 'iCal'])" "Geolocation (latitude|longitude)" "Mail (recipient|subject|message)" "Phone Number (string)" "Plain Text (string)" "SMS (number|message)" "URL (string)" "WiFi (ssid|password|authenticationMode ['WEP', 'WPA' or 'WPA2'])"] }
def symbol-completer [] { ["CDAXX.INDX (DAX Composite Index [Germany])" "DJA.INDX (Dow Jones Composite Average)" "DJI.INDX (Dow Jones Industrial Average)" "DJT.INDX (Dow Jones Transportation)" "DJUS.INDX (Dow Jones US)" "DXY.INDX (US Dollar Index)" "ES.INDX (S&P 500 Futures)" "FTSE.INDX (FTSE 100 Index [UK])" "GDAXI.INDX (DAX Index [Germany])" "GDOW.INDX (Global Dow USD)" "GPTSE.INDX (S&P TSX Composite Index [Canada])" "GSPC.INDX (S&P 500)" "HSCE.INDX (Hang Seng China Enterprise (CEI))" "HSI.INDX (Hang Seng Index [Hong Kong])" "IXIC.INDX (NASDAQ Composite)" "MID.INDX (S&P Midcap 400)" "N100.INDX (EuroNext 100)" "N225.INDX (Nikkei 225 Index)" "NDX.INDX (NASDAQ 100)" "NY.INDX (NYSE US 100 Index)" "NYA.INDX (NYSE Composite)" "RTSI.INDX (RTSI Index [Russia])" "SSEC.INDX (Shanghai Composite)" "SSMI.INDX (Swiss Market Index)"] }
def ignore-case-completer [] { ["false" "true"] }
def algorithm-completer-1 [] { ["Bicubic (default)" "Bilinear" "Cubic (Box)" "Cubic (Catmull-Rom)" "Cubic (Hermite)" "Cubic (Spline)" "Nearest Neighbor" "Robidoux" "Robidoux Sharp" "Sinc (Lanczos2)" "Sinc (Lanczos3)" "Sinc (Lanczos5)" "Sinc (Lanczos8)"] }
def units-completer [] { ["Percent" "Pixels"] }
def order-completer [] { ["Ascending" "Descending"] }
def language-completer [] { ["Arabic (Bahrain)" "Arabic (Egypt)" "Arabic (Iraq)" "Arabic (Jordan)" "Arabic (Kuwait)" "Arabic (Lebanon)" "Arabic (Oman)" "Arabic (Qatar)" "Arabic (Saudi Arabia)" "Arabic (Syria)" "Arabic (United Arab Emirates)" "Bulgarian (Bulgaria)" "Catalan (Spain)" "Chinese (Cantonese, Traditional)" "Chinese (Mandarin, Simplified)" "Chinese (Taiwanese Mandarin)" "Croatian (Croatia)" "Czech (Czech Republic)" "Danish (Denmark)" "Dutch (Netherlands)" "English (Australia)" "English (Canada)" "English (Hong Kong)" "English (India)" "English (Ireland)" "English (New Zealand)" "English (Philippines)" "English (Singapore)" "English (South Africa)" "English (United Kingdom)" "English (United States)" "Estonian(Estonia)" "Finnish (Finland)" "French (Canada)" "French (France)" "German (Germany)" "Greek (Greece)" "Gujarati (Indian)" "Hindi (India)" "Hungarian (Hungary)" "Irish(Ireland)" "Italian (Italy)" "Japanese (Japan)" "Korean (Korea)" "Latvian (Latvia)" "Lithuanian (Lithuania)" "Maltese(Malta)" "Marathi (India)" "Norwegian (Norway)" "Polish (Poland)" "Portuguese (Brazil)" "Portuguese (Portugal)" "Romanian (Romania)" "Russian (Russia)" "Slovak (Slovakia)" "Slovenian (Slovenia)" "Spanish (Argentina)" "Spanish (Bolivia)" "Spanish (Chile)" "Spanish (Colombia)" "Spanish (Costa Rica)" "Spanish (Cuba)" "Spanish (Dominican Republic)" "Spanish (Ecuador)" "Spanish (El Salvador)" "Spanish (Guatemala)" "Spanish (Honduras)" "Spanish (Mexico)" "Spanish (Nicaragua)" "Spanish (Panama)" "Spanish (Paraguay)" "Spanish (Peru)" "Spanish (Puerto Rico)" "Spanish (Spain)" "Spanish (USA)" "Spanish (Uruguay)" "Spanish (Venezuela)" "Swedish (Sweden)" "Tamil (India)" "Telugu (India)" "Thai (Thailand)" "Turkish (Turkey)"] }
def exchange-completer [] { ["BMEX (Bolsas y Mercados Españoles)" "MISX (Moscow Stock Exchange)" "XASE (American Stock Exchange)" "XASX (Australia Stock Exchange)" "XBKK (Stock Exchange of Thailand)" "XBRU (Euronext Brussels)" "XCNQ (Candadian Securities Exchange)" "XCSE (Copenhagen Stock Exchange)" "XDFM (Dubai Financial Market)" "XFKA (Fukuoka Stock Exchange)" "XFRA (Deutsche Borse)" "XHKG (Hong Kong Stock Exchange)" "XJSE (Johannesburg Stock Exchange)" "XLIS (Euronext Lisbon)" "XLON (London Stock Exchange)" "XMEX (Mexican Stock Exchange)" "XNAS (NASDAQ Stock Exchange)" "XNGO (Nagoya Stock Exchange)" "XNSE (National Stock Exchange India)" "XNYS (New York Stock Exchange)" "XNZE (New Zealand Stock Exchange)" "XPAR (Euronext Paris)" "XSAP (Sapporo Stock Exchange)" "XSES (Singapore Stock Exchange)" "XSHG (Shanghai Stock Exchange)" "XSTO (Stockholm Stock Exchange)" "XSWX (SIX Swiss Exchange)" "XTAE (Tel Aviv Stock Exchange)" "XTSE (Toronto Stock Exchange)"] }
def extension-completer [] { ["CSS" "CSV" "HTML" "JS" "JSON" "TXT" "XML"] }
def accept-completer-1 [] { ["application/json" "application/xml" "text/css" "text/csv" "text/html" "text/javascript" "text/plain"] }
def type-completer-2 [] { ["PlainText" "SSML"] }
def voice-completer [] { ["ar-EG, Hoda (Female)" "ar-SA, Naayf (Male)" "bg-BG, Ivan (Male)" "ca-ES, Herena (Female)" "cs-CZ, Jakub (Male)" "da-DK, Helle (Female)" "de-AT, Michael (Male)" "de-CH, Karsten (Male)" "de-DE, Hedda (Female)" "de-DE, Stefan (Male)" "el-GR, Stefanos (Male)" "en-AU, Catherine (Female)" "en-AU, Hayley (Female)" "en-CA, Heather (Female)" "en-CA, Linda (Female)" "en-GB, George (Male)" "en-GB, Hazel (Female)" "en-GB, Susan (Female)" "en-IE, Sean (Male)" "en-IN, Heera (Female)" "en-IN, Priya (Female)" "en-IN, Ravi (Male)" "en-US, Aria (Female)" "en-US, Benjamin (Male)" "en-US, Guy (Male)" "en-US, Zira (Female)" "es-ES, Helena (Female)" "es-ES, Laura (Female)" "es-ES, Pablo (Male)" "es-MX, Hilda (Female)" "es-MX, Raul (Male)" "fi-FI, Heidi (Female)" "fr-CA, Caroline (Female)" "fr-CA, Harmonie (Female)" "fr-CH, Guillaume (Male)" "fr-FR, Hortense (Female)" "fr-FR, Julie (Female)" "fr-FR, Paul (Male)" "he-IL, Asaf (Male)" "hi-IN, Hemant (Male)" "hi-IN, Kalpana (Female)" "hr-HR, Matej (Male)" "hu-HU, Szabolcs (Male)" "id-ID, Andika (Male)" "it-IT, Cosimo (Male)" "it-IT, Lucia (Female)" "ja-JP, Ayumi (Female)" "ja-JP, Haruka (Female)" "ja-JP, Ichiro (Male)" "ko-KR, Heami (Female)" "ms-MY, Rizwan (Male)" "nb-NO, Hulda (Female)" "nl-NL, Hanna (Female)" "pl-PL, Paulina (Female)" "pt-BR, Daniel (Male)" "pt-BR, Heloisa (Female)" "pt-PT, Helia (Female)" "ro-RO, Andrei (Male)" "ru-RU, Ekaterina (Female)" "ru-RU, Irina (Female)" "ru-RU, Pavel (Male)" "sk-SK, Filip (Male)" "sl-SI, Lado (Male)" "sv-SE, Hedvig (Female)" "ta-IN, Valluvar (Male)" "te-IN, Chitra (Female)" "th-TH, Pattara (Male)" "tr-TR, Seda (Female)" "vi-VN, An (Male)" "zh-CN, Huihui (Female)" "zh-CN, Kangkang (Male)" "zh-CN, Yaoyao (Female)" "zh-HK, Danny (Male)" "zh-HK, Tracy (Female)" "zh-TW, HanHan (Female)" "zh-TW, Yating (Female)" "zh-TW, Zhiwei (Male)"] }
def language-completer-1 [] { ["Arabic" "Chinese (Simplified)" "Czech" "Danish" "Dutch" "English" "Finnish" "French" "German" "Greek" "Hindi" "Hungarian" "Italian" "Japanese" "Klingon" "Korean" "Norweigan" "Polish" "Portuguese" "Russian" "Spanish" "Swedish" "Turkish" "Vietnamese" "Welsh"] }
def type-completer-3 [] { ["Both" "End" "Start"] }
def font-completer [] { ["Arial" "Arial Black" "Arial Narrow" "Book Antiqua" "Britannic Bold" "Brush Script MT" "Calisto MT" "Century Gothic" "Century Schoolbook" "Colonna MT" "Comic Sans MS" "Cooper Black" "Copperplate Gothic Bold" "Copperplate Gothic Light" "Courier New" "Edwardian Script ITC" "Engravers MT" "Franklin Gothic Demi" "Franklin Gothic Heavy" "Franklin Gothic Medium" "Garamond" "Georgia" "Gill Sans MT" "Gill Sans MT Condensed" "Gill Sans Ultra Bold" "Gill Sans Ultra Bold Condensed" "Goudy Old Style" "Haettenschweiler" "Holidays MT" "Impact" "Lucida Calligraphy" "Lucida Console" "Lucida Handwriting" "Lucida Sans Typewriter" "Lucida Sans Unicode" "MS Outlook" "Marlett" "Microsoft Sans Serif" "Palace Script MT" "Palatino Linotype" "Papyrus" "Playbill" "Rockwell" "Rockwell Condensed" "Rockwell Extra Bold" "Script MT Bold" "Stencil" "Symbol" "Tahoma" "Times New Roman" "Trebuchet MS" "Verdana" "Vivaldi" "Webdings" "Wingdings 1" "Wingdings 2" "Wingdings 3"] }
def horizontal-completer [] { ["Center" "Left" "Right"] }
def vertical-completer [] { ["Bottom" "Center" "Top"] }
def source-completer-11 [] { ["AUS Central Standard Time - (GMT+09:30) Darwin" "AUS Eastern Standard Time - (GMT+10:00) Canberra, Melbourne, Sydney" "Afghanistan Standard Time - (GMT+04:30) Kabul" "Alaskan Standard Time - (GMT-09:00) Alaska" "Arab Standard Time - (GMT+03:00) Kuwait, Riyadh" "Arabian Standard Time - (GMT+04:00) Abu Dhabi, Muscat" "Arabic Standard Time - (GMT+03:00) Baghdad" "Argentina Standard Time - (GMT-03:00) Buenos Aires" "Atlantic Standard Time - (GMT-04:00) Atlantic Time (Canada)" "Azerbaijan Standard Time - (GMT+04:00) Baku" "Azores Standard Time - (GMT-01:00) Azores" "Canada Central Standard Time - (GMT-06:00) Saskatchewan" "Cape Verde Standard Time - (GMT-01:00) Cape Verde Is." "Caucasus Standard Time - (GMT+04:00) Yerevan" "Cen. Australia Standard Time - (GMT+09:30) Adelaide" "Central America Standard Time - (GMT-06:00) Central America" "Central Asia Standard Time - (GMT+06:00) Astana, Dhaka" "Central Brazilian Standard Time - (GMT-04:00) Manaus" "Central Europe Standard Time - (GMT+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague" "Central European Standard Time - (GMT+01:00) Sarajevo, Skopje, Warsaw, Zagreb" "Central Pacific Standard Time - (GMT+11:00) Magadan, Solomon Is., New Caledonia" "Central Standard Time (Mexico) - (GMT-06:00) Guadalajara, Mexico City, Monterrey" "Central Standard Time - (GMT-06:00) Central Time (US & Canada)" "China Standard Time - (GMT+08:00) Beijing, Chongqing, Hong Kong, Urumqi" "Dateline Standard Time - (GMT-12:00) International Date Line West" "E. Africa Standard Time - (GMT+03:00) Nairobi" "E. Australia Standard Time - (GMT+10:00) Brisbane" "E. Europe Standard Time - (GMT+02:00) Minsk" "E. South America Standard Time - (GMT-03:00) Brasilia" "Eastern Standard Time - (GMT-05:00) Eastern Time (US & Canada)" "Egypt Standard Time - (GMT+02:00) Cairo" "Ekaterinburg Standard Time - (GMT+05:00) Ekaterinburg" "FLE Standard Time - (GMT+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius" "Fiji Standard Time - (GMT+12:00) Fiji, Kamchatka, Marshall Is." "GMT Standard Time - (GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London" "GTB Standard Time - (GMT+02:00) Athens, Bucharest, Istanbul" "Georgian Standard Time - (GMT+03:00) Tbilisi" "Greenland Standard Time - (GMT-03:00) Greenland" "Greenwich Standard Time - (GMT) Monrovia, Reykjavik" "Hawaiian Standard Time - (GMT-10:00) Hawaii" "India Standard Time - (GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi" "Iran Standard Time - (GMT+03:30) Tehran" "Israel Standard Time - (GMT+02:00) Jerusalem" "Korea Standard Time - (GMT+09:00) Seoul" "Mauritius Standard Time - (GMT+04:00) Port Louis" "Mid-Atlantic Standard Time - (GMT-02:00) Mid-Atlantic" "Middle East Standard Time - (GMT+02:00) Beirut" "Montevideo Standard Time - (GMT-03:00) Montevideo" "Mountain Standard Time (Mexico) - (GMT-07:00) Chihuahua, La Paz, Mazatlan" "Mountain Standard Time - (GMT-07:00) Mountain Time (US & Canada)" "Myanmar Standard Time - (GMT+06:30) Yangon (Rangoon)" "N. Central Asia Standard Time - (GMT+06:00) Almaty, Novosibirsk" "Namibia Standard Time - (GMT+02:00) Windhoek" "Nepal Standard Time - (GMT+05:45) Kathmandu" "New Zealand Standard Time - (GMT+12:00) Auckland, Wellington" "Newfoundland Standard Time - (GMT-03:30) Newfoundland" "North Asia East Standard Time - (GMT+08:00) Irkutsk, Ulaan Bataar" "North Asia Standard Time - (GMT+07:00) Krasnoyarsk" "Pacific SA Standard Time - (GMT-04:00) Santiago" "Pacific Standard Time (Mexico) - (GMT-08:00) Tijuana, Baja California" "Pacific Standard Time - (GMT-08:00) Pacific Time (US & Canada)" "Pakistan Standard Time - (GMT+05:00) Islamabad, Karachi" "Russian Standard Time - (GMT+03:00) Moscow, St. Petersburg, Volgograd" "SA Eastern Standard Time - (GMT-03:00) Georgetown" "SA Pacific Standard Time - (GMT-05:00) Bogota, Lima, Quito, Rio Branco" "SA Western Standard Time - (GMT-04:00) La Paz" "SE Asia Standard Time - (GMT+07:00) Bangkok, Hanoi, Jakarta" "Samoa Standard Time - (GMT-11:00) Midway Island, Samoa" "Singapore Standard Time - (GMT+08:00) Kuala Lumpur, Singapore" "South Africa Standard Time - (GMT+02:00) Harare, Pretoria" "Sri Lanka Standard Time - (GMT+05:30) Sri Jayawardenepura" "Taipei Standard Time - (GMT+08:00) Taipei" "Tasmania Standard Time - (GMT+10:00) Hobart" "Tokyo Standard Time - (GMT+09:00) Osaka, Sapporo, Tokyo" "Tonga Standard Time - (GMT+13:00) Nuku'alofa" "US Eastern Standard Time - (GMT-05:00) Indiana (East)" "US Mountain Standard Time - (GMT-07:00) Arizona" "Venezuela Standard Time - (GMT-04:30) Caracas" "Vladivostok Standard Time - (GMT+10:00) Vladivostok" "W. Australia Standard Time - (GMT+08:00) Perth" "W. Central Africa Standard Time - (GMT+01:00) West Central Africa" "W. Europe Standard Time - (GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna" "West Asia Standard Time - (GMT+05:00) Tashkent" "West Pacific Standard Time - (GMT+10:00) Guam, Port Moresby" "Yakutsk Standard Time - (GMT+09:00) Yakutsk"] }
def target-completer-11 [] { ["AUS Central Standard Time - (GMT+09:30) Darwin" "AUS Eastern Standard Time - (GMT+10:00) Canberra, Melbourne, Sydney" "Afghanistan Standard Time - (GMT+04:30) Kabul" "Alaskan Standard Time - (GMT-09:00) Alaska" "Arab Standard Time - (GMT+03:00) Kuwait, Riyadh" "Arabian Standard Time - (GMT+04:00) Abu Dhabi, Muscat" "Arabic Standard Time - (GMT+03:00) Baghdad" "Argentina Standard Time - (GMT-03:00) Buenos Aires" "Atlantic Standard Time - (GMT-04:00) Atlantic Time (Canada)" "Azerbaijan Standard Time - (GMT+04:00) Baku" "Azores Standard Time - (GMT-01:00) Azores" "Canada Central Standard Time - (GMT-06:00) Saskatchewan" "Cape Verde Standard Time - (GMT-01:00) Cape Verde Is." "Caucasus Standard Time - (GMT+04:00) Yerevan" "Cen. Australia Standard Time - (GMT+09:30) Adelaide" "Central America Standard Time - (GMT-06:00) Central America" "Central Asia Standard Time - (GMT+06:00) Astana, Dhaka" "Central Brazilian Standard Time - (GMT-04:00) Manaus" "Central Europe Standard Time - (GMT+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague" "Central European Standard Time - (GMT+01:00) Sarajevo, Skopje, Warsaw, Zagreb" "Central Pacific Standard Time - (GMT+11:00) Magadan, Solomon Is., New Caledonia" "Central Standard Time (Mexico) - (GMT-06:00) Guadalajara, Mexico City, Monterrey" "Central Standard Time - (GMT-06:00) Central Time (US & Canada)" "China Standard Time - (GMT+08:00) Beijing, Chongqing, Hong Kong, Urumqi" "Dateline Standard Time - (GMT-12:00) International Date Line West" "E. Africa Standard Time - (GMT+03:00) Nairobi" "E. Australia Standard Time - (GMT+10:00) Brisbane" "E. Europe Standard Time - (GMT+02:00) Minsk" "E. South America Standard Time - (GMT-03:00) Brasilia" "Eastern Standard Time - (GMT-05:00) Eastern Time (US & Canada)" "Egypt Standard Time - (GMT+02:00) Cairo" "Ekaterinburg Standard Time - (GMT+05:00) Ekaterinburg" "FLE Standard Time - (GMT+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius" "Fiji Standard Time - (GMT+12:00) Fiji, Kamchatka, Marshall Is." "GMT Standard Time - (GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London" "GTB Standard Time - (GMT+02:00) Athens, Bucharest, Istanbul" "Georgian Standard Time - (GMT+03:00) Tbilisi" "Greenland Standard Time - (GMT-03:00) Greenland" "Greenwich Standard Time - (GMT) Monrovia, Reykjavik" "Hawaiian Standard Time - (GMT-10:00) Hawaii" "India Standard Time - (GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi" "Iran Standard Time - (GMT+03:30) Tehran" "Israel Standard Time - (GMT+02:00) Jerusalem" "Korea Standard Time - (GMT+09:00) Seoul" "Mauritius Standard Time - (GMT+04:00) Port Louis" "Mid-Atlantic Standard Time - (GMT-02:00) Mid-Atlantic" "Middle East Standard Time - (GMT+02:00) Beirut" "Montevideo Standard Time - (GMT-03:00) Montevideo" "Mountain Standard Time (Mexico) - (GMT-07:00) Chihuahua, La Paz, Mazatlan" "Mountain Standard Time - (GMT-07:00) Mountain Time (US & Canada)" "Myanmar Standard Time - (GMT+06:30) Yangon (Rangoon)" "N. Central Asia Standard Time - (GMT+06:00) Almaty, Novosibirsk" "Namibia Standard Time - (GMT+02:00) Windhoek" "Nepal Standard Time - (GMT+05:45) Kathmandu" "New Zealand Standard Time - (GMT+12:00) Auckland, Wellington" "Newfoundland Standard Time - (GMT-03:30) Newfoundland" "North Asia East Standard Time - (GMT+08:00) Irkutsk, Ulaan Bataar" "North Asia Standard Time - (GMT+07:00) Krasnoyarsk" "Pacific SA Standard Time - (GMT-04:00) Santiago" "Pacific Standard Time (Mexico) - (GMT-08:00) Tijuana, Baja California" "Pacific Standard Time - (GMT-08:00) Pacific Time (US & Canada)" "Pakistan Standard Time - (GMT+05:00) Islamabad, Karachi" "Russian Standard Time - (GMT+03:00) Moscow, St. Petersburg, Volgograd" "SA Eastern Standard Time - (GMT-03:00) Georgetown" "SA Pacific Standard Time - (GMT-05:00) Bogota, Lima, Quito, Rio Branco" "SA Western Standard Time - (GMT-04:00) La Paz" "SE Asia Standard Time - (GMT+07:00) Bangkok, Hanoi, Jakarta" "Samoa Standard Time - (GMT-11:00) Midway Island, Samoa" "Singapore Standard Time - (GMT+08:00) Kuala Lumpur, Singapore" "South Africa Standard Time - (GMT+02:00) Harare, Pretoria" "Sri Lanka Standard Time - (GMT+05:30) Sri Jayawardenepura" "Taipei Standard Time - (GMT+08:00) Taipei" "Tasmania Standard Time - (GMT+10:00) Hobart" "Tokyo Standard Time - (GMT+09:00) Osaka, Sapporo, Tokyo" "Tonga Standard Time - (GMT+13:00) Nuku'alofa" "US Eastern Standard Time - (GMT-05:00) Indiana (East)" "US Mountain Standard Time - (GMT-07:00) Arizona" "Venezuela Standard Time - (GMT-04:30) Caracas" "Vladivostok Standard Time - (GMT+10:00) Vladivostok" "W. Australia Standard Time - (GMT+08:00) Perth" "W. Central Africa Standard Time - (GMT+01:00) West Central Africa" "W. Europe Standard Time - (GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna" "West Asia Standard Time - (GMT+05:00) Tashkent" "West Pacific Standard Time - (GMT+10:00) Guam, Port Moresby" "Yakutsk Standard Time - (GMT+09:00) Yakutsk"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "add-to-collection create" } } | get name | first)
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

# Collections - Add to collection
#
# POST /AddToCollection
# operationId: AddToCollection
export def "add-to-collection create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --index: string # Index position for operation (leave blank to specify end of collection)
  input: list<string> # Collection of values or objects to modify
  --item: string # Item (for multiple items, leave blank and use Items)
  --items: list<string> # Items (Collection, for a single item leave blank and use Item)
]: any -> record<result: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/AddToCollection")
  let req_body = {"index": $index, "input": $input, "item": $item, "items": $items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Data - CSV to JSON
#
# POST /CSVtoJSON
# operationId: CsvToJson
export def "cs-vto-json create-csv" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --header: oneof<nothing, bool> # Include header row (default: true)
  input: string # CSV string
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CSVtoJSON")
  let req_body = {"header": $header, "input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Calculate Absolute
#
# POST /CalculateAbsolute
# operationId: CalculateAbsolute
export def "calculate-absolute create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value to calculate
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CalculateAbsolute")
  let req_body = {"decimals": $decimals, "input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Calculate Addition
#
# POST /CalculateAddition
# operationId: CalculateAddition
export def "calculate-addition create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value
  value: float # Addend, subtrahend, factor, divisor or radicand
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CalculateAddition")
  let req_body = {"decimals": $decimals, "input": $input, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Calculate average
#
# POST /CalculateAverage
# operationId: CalculateAverage
export def "calculate-average create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: list<float> # Colllection of values to calculate
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CalculateAverage")
  let req_body = {"decimals": $decimals, "input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Calculate Cosine
#
# POST /CalculateCosine
# operationId: CalculateCosine
export def "calculate-cosine create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value to calculate
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CalculateCosine")
  let req_body = {"decimals": $decimals, "input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Calculate Division
#
# POST /CalculateDivision
# operationId: CalculateDivision
export def "calculate-division create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value
  value: float # Addend, subtrahend, factor, divisor or radicand
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CalculateDivision")
  let req_body = {"decimals": $decimals, "input": $input, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Calculate Logarithm
#
# POST /CalculateLogarithm
# operationId: CalculateLogarithm
export def "calculate-logarithm create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value to calculate
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CalculateLogarithm")
  let req_body = {"decimals": $decimals, "input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Calculate median
#
# POST /CalculateMedian
# operationId: CalculateMedian
export def "calculate-median create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: list<float> # Colllection of values to calculate
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CalculateMedian")
  let req_body = {"decimals": $decimals, "input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Calculate minimum or maximum
#
# POST /CalculateMinMax
# operationId: CalculateMinMax
export def "calculate-min-max create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: list<float> # Colllection of values to calculate
  type: string@type-completer # Minimum or Maximum (default: Minimum)
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CalculateMinMax")
  let req_body = {"input": $input, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Calculate Modulo
#
# POST /CalculateModulo
# operationId: CalculateModulo
export def "calculate-modulo create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value
  value: float # Addend, subtrahend, factor, divisor or radicand
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CalculateModulo")
  let req_body = {"decimals": $decimals, "input": $input, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Calculate Multiplication
#
# POST /CalculateMultiplication
# operationId: CalculateMultiplication
export def "calculate-multiplication create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value
  value: float # Addend, subtrahend, factor, divisor or radicand
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CalculateMultiplication")
  let req_body = {"decimals": $decimals, "input": $input, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Calculate Nth Root
#
# POST /CalculateNthRoot
# operationId: CalculateNthRoot
export def "calculate-nth-root create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value
  value: float # Addend, subtrahend, factor, divisor or radicand
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CalculateNthRoot")
  let req_body = {"decimals": $decimals, "input": $input, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Calculate power
#
# POST /CalculatePower
# operationId: CalculatePower
export def "calculate-power create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Number to raise
  power: float # Power
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CalculatePower")
  let req_body = {"decimals": $decimals, "input": $input, "power": $power} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Calculate Sine
#
# POST /CalculateSine
# operationId: CalculateSine
export def "calculate-sine create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value to calculate
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CalculateSine")
  let req_body = {"decimals": $decimals, "input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Calculate Square Root
#
# POST /CalculateSquareRoot
# operationId: CalculateSquareRoot
export def "calculate-square-root create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value to calculate
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CalculateSquareRoot")
  let req_body = {"decimals": $decimals, "input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Calculate Subtraction
#
# POST /CalculateSubtraction
# operationId: CalculateSubtraction
export def "calculate-subtraction create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value
  value: float # Addend, subtrahend, factor, divisor or radicand
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CalculateSubtraction")
  let req_body = {"decimals": $decimals, "input": $input, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Calculate sum
#
# POST /CalculateSum
# operationId: CalculateSum
export def "calculate-sum create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: list<float> # Colllection of values to calculate
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CalculateSum")
  let req_body = {"decimals": $decimals, "input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Calculate Tangent
#
# POST /CalculateTangent
# operationId: CalculateTangent
export def "calculate-tangent create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value to calculate
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CalculateTangent")
  let req_body = {"decimals": $decimals, "input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Calculate variance
#
# POST /CalculateVariance
# operationId: CalculateVariance
export def "calculate-variance create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: list<float> # Colllection of values to calculate
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CalculateVariance")
  let req_body = {"decimals": $decimals, "input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Collections - Contains number
#
# POST /CollectionContainsNumber
# operationId: CollectionContainsNumber
export def "collection-contains-number create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: list<float> # Collection of strings to search
  --body-match: float # Number to match
  --type: string@type-completer-1 # Type of number - integer or decimal (default: Integer)
]: any -> record<item: float, items: list<float>, status: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CollectionContainsNumber")
  let req_body = {"input": $input, "match": $body_match, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Collections - Contains string
#
# POST /CollectionContainsString
# operationId: CollectionContainsString
export def "collection-contains-string create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ignorecase: string@ignorecase-completer # Ignore case when performing comparison
  input: list<string> # Collection of strings to search
  --body-match: string # Text to match
  --trim: string@trim-completer # Trim white space from comparison string
]: any -> record<item: string, items: list<string>, status: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CollectionContainsString")
  let req_body = {"ignorecase": $ignorecase, "input": $input, "match": $body_match, "trim": $trim} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Collections - Ends with string
#
# POST /CollectionEndsWithString
# operationId: CollectionEndsWithString
export def "collection-ends-with-string create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ignorecase: string@ignorecase-completer # Ignore case when performing comparison
  input: list<string> # Collection of strings to search
  --body-match: string # Text to match
  --trim: string@trim-completer # Trim white space from comparison string
]: any -> record<item: string, items: list<string>, status: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CollectionEndsWithString")
  let req_body = {"ignorecase": $ignorecase, "input": $input, "match": $body_match, "trim": $trim} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Collections - Starts with string
#
# POST /CollectionStartsWithString
# operationId: CollectionStartsWithString
export def "collection-starts-with-string create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ignorecase: string@ignorecase-completer # Ignore case when performing comparison
  input: list<string> # Collection of strings to search
  --body-match: string # Text to match
  --trim: string@trim-completer # Trim white space from comparison string
]: any -> record<item: string, items: list<string>, status: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CollectionStartsWithString")
  let req_body = {"ignorecase": $ignorecase, "input": $input, "match": $body_match, "trim": $trim} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Collections - Collection to JSON
#
# POST /CollectionToJSON
# operationId: CollectionToJSON
export def "collection-to-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: list<string> # Collection containing strings to convert
  name: string # Collection name
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CollectionToJSON")
  let req_body = {"input": $input, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Collections - Collection to XML
#
# POST /CollectionToXML
# operationId: CollectionToXml
export def "collection-to-xml create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  child: string # Name of child XML node(s)
  input: list<string> # Collection containing strings to convert
  root: string # Name of root XML node
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CollectionToXML")
  let req_body = {"child": $child, "input": $input, "root": $root} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Text - Compare strings
#
# POST /CompareStrings
# operationId: CompareStrings
export def "compare-strings create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  compare: string # Comparison string
  input: string # Original string
  lower: string@lower-completer # Convert strings to lowercase before comparison
  trim: string@trim-completer # Trim strings before comparison
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CompareStrings")
  let req_body = {"compare": $compare, "input": $input, "lower": $lower, "trim": $trim} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Text - Contains string
#
# POST /ContainsString
# operationId: ContainsString
export def "contains-string create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  find: string # Text to match
  input: string # Text to search
  lower: string@lower-completer # Convert strings to lowercase
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ContainsString")
  let req_body = {"find": $find, "input": $input, "lower": $lower} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Convert angle
#
# POST /ConvertAngle
# operationId: ConvertAngle
export def "convert-angle create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float
  --body-source: string@source-completer
  target: string@target-completer
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ConvertAngle")
  let req_body = {"input": $input, "source": $body_source, "target": $target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Convert area
#
# POST /ConvertArea
# operationId: ConvertArea
export def "convert-area create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float
  --body-source: string@source-completer-1
  target: string@target-completer-1
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ConvertArea")
  let req_body = {"input": $input, "source": $body_source, "target": $target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Text - Convert case
#
# POST /ConvertCase
# operationId: ConvertCase
export def "convert-case create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  alphacase: string@alphacase-completer # Case of conversion result
  input: string # String containing the text to convert
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ConvertCase")
  let req_body = {"alphacase": $alphacase, "input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Currency - Convert currency
#
# POST /ConvertCurrency
# operationId: ConvertCurrency
export def "convert-currency create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float # Amount to convert
  --body-source: string@source-completer-2 # default: USD
  target: string@target-completer-2
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ConvertCurrency")
  let req_body = {"input": $input, "source": $body_source, "target": $target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Convert distance
#
# POST /ConvertDistance
# operationId: ConvertDistance
export def "convert-distance create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float
  --body-source: string@source-completer-3
  target: string@target-completer-3
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ConvertDistance")
  let req_body = {"input": $input, "source": $body_source, "target": $target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Convert duration
#
# POST /ConvertDuration
# operationId: ConvertDuration
export def "convert-duration create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float
  --body-source: string@source-completer-4
  target: string@target-completer-4
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ConvertDuration")
  let req_body = {"input": $input, "source": $body_source, "target": $target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Convert energy
#
# POST /ConvertEnergy
# operationId: ConvertEnergy
export def "convert-energy create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float
  --body-source: string@source-completer-5
  target: string@target-completer-5
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ConvertEnergy")
  let req_body = {"input": $input, "source": $body_source, "target": $target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Files - Convert Image
#
# POST /ConvertImage
# operationId: ConvertImage
export def "convert-image create" [
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
  file: string # Source image file (format: binary)
  format: string@format-completer # Output file format (default: PNG)
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ConvertImage")
  let req_body = {"file": $file, "format": $format} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "image/bmp")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Math - Convert power
#
# POST /ConvertPower
# operationId: ConvertPower
export def "convert-power create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float
  --body-source: string@source-completer-6
  target: string@target-completer-6
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ConvertPower")
  let req_body = {"input": $input, "source": $body_source, "target": $target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Convert speed
#
# POST /ConvertSpeed
# operationId: ConvertSpeed
export def "convert-speed create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float
  --body-source: string@source-completer-7
  target: string@target-completer-7
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ConvertSpeed")
  let req_body = {"input": $input, "source": $body_source, "target": $target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Convert temperature
#
# POST /ConvertTemperature
# operationId: ConvertTemperature
export def "convert-temperature create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float
  --body-source: string@source-completer-8
  target: string@target-completer-8
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ConvertTemperature")
  let req_body = {"input": $input, "source": $body_source, "target": $target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Convert volume
#
# POST /ConvertVolume
# operationId: ConvertVolume
export def "convert-volume create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float
  --body-source: string@source-completer-9
  target: string@target-completer-9
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ConvertVolume")
  let req_body = {"input": $input, "source": $body_source, "target": $target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Convert weight
#
# POST /ConvertWeight
# operationId: ConvertWeight
export def "convert-weight create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float
  --body-source: string@source-completer-10
  target: string@target-completer-10
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ConvertWeight")
  let req_body = {"input": $input, "source": $body_source, "target": $target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Collections - Count collection
#
# POST /CountCollection
# operationId: CountCollection
export def "count-collection create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: list<string> # Collection of items to count
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CountCollection")
  let req_body = {"input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Files - Crop Image
#
# POST /CropImage
# operationId: CropImage
export def "crop-image create" [
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
  height: float # Height (Y-axis down, negative to reverse)
  width: float # Width (X-axis right, negative to reverse)
  file: string # Source image file (format: binary)
  position: string@position-completer # Crop start position (use negative values to reverse crop area) (default: TopLeft)
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CropImage")
  let req_body = {"Height": $height, "Width": $width, "file": $file, "position": $position} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "image/bmp")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# DateTime - DateTime difference
#
# POST /DateTimeDifference
# operationId: DateTimeDifference
export def "date-time-difference create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  date_time1: string # First date/time value
  date_time2: string # Second date/time value
]: any -> record<days: float, hours: float, milliseconds: float, minutes: float, months: float, ticks: float, totalDays: float, totalHours: float, totalMilliseconds: float, totalMinutes: float, totalMonths: float, totalSeconds: float, totalYears: float, years: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/DateTimeDifference")
  let req_body = {"dateTime1": $date_time1, "dateTime2": $date_time2} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# DateTime - Get date and time information
#
# POST /DateTimeInfo
# operationId: DateTimeInfo
export def "date-time-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  culture: string@culture-completer # Language culture (default: en-US)
  input: string # Source date and time
]: any -> record<DayOfWeek: float, DayOfYear: float, MinutesInDay: float, SecondsInDay: float, Ticks: float, WeekOfYear: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/DateTimeInfo")
  let req_body = {"culture": $culture, "input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Text - Decode string
#
# POST /DecodeString
# operationId: DecodeString
export def "decode-string create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-source: string # Encoded string variable or text value
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/DecodeString")
  let req_body = {"source": $body_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Text - Encode string
#
# POST /EncodeString
# operationId: EncodeString
export def "encode-string create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-source: string # String variable or text value
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/EncodeString")
  let req_body = {"source": $body_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Files - File to string
#
# POST /FileToString
# operationId: FileToString
export def "file-to-string create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # Source file (10MB limit) (format: binary)
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/FileToString")
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Collections - Filter collection
#
# POST /FilterCollection
# operationId: FilterCollection
export def "filter-collection create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: list<string> # Collection of strings to filter
  keywords: string # Keywords (separate multiple values with commas)
  --body-match: string@match-completer # Match type (default: Any)
]: any -> record<result: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/FilterCollection")
  let req_body = {"input": $input, "keywords": $keywords, "match": $body_match} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Files - Flip Image
#
# POST /FlipImage
# operationId: FlipImage
export def "flip-image create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # Source image file (format: binary)
  orientation: string@orientation-completer # Horizontal or Vertical (default: Horizontal)
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/FlipImage")
  let req_body = {"file": $file, "orientation": $orientation} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Currency - Format currency
#
# POST /FormatCurrency
# operationId: FormatCurrency
export def "format-currency create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float # Amount to format
  target: string@target-completer-2
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/FormatCurrency")
  let req_body = {"input": $input, "target": $target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# DateTime - Format date and time
#
# POST /FormatDateTime
# operationId: FormatDateTime
export def "format-date-time create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  culture: string@culture-completer # Language culture (default: en-US)
  format: string # Output format
  input: string # Source date and time
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/FormatDateTime")
  let req_body = {"culture": $culture, "format": $format, "input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Text - Generate GUID
#
# POST /GenerateGuid
# operationId: GenerateGuid
export def "generate-guid generate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  uppercase: string@uppercase-completer # All uppercase alpha characters
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/GenerateGuid")
  let req_body = {"uppercase": $uppercase} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Text - Generate hash
#
# POST /GenerateHash
# operationId: GenerateHash
export def "generate-hash generate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  algorithm: string@algorithm-completer # Hash algorithm
  input: string # Hash source string
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/GenerateHash")
  let req_body = {"algorithm": $algorithm, "input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Files - Generate QR code
#
# POST /GenerateQRCode
# operationId: GenerateQRCode
export def "generate-qr-code generate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: string # Text value(s) (vertical bar delimited by type)
  payload: string@payload-completer # Payload type (default: Plain Text (string))
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/GenerateQRCode")
  let req_body = {"input": $input, "payload": $payload} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Data - JSON to CSV
#
# POST /JSONtoCSV
# operationId: JsonToCsv
export def "jso-nto-csv create-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --header: oneof<nothing, bool> # Include header row (default: true)
  input: string # JSON array object
  --omit: string # Columns to omit (comma separated)
  --order: string # Column order (comma separated)
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/JSONtoCSV")
  let req_body = {"header": $header, "input": $input, "omit": $omit, "order": $order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Data - JSON to HTML Table
#
# POST /JSONtoHTML
# operationId: JsonToHtml
export def "jso-nto-html create-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternate: string # Alternate header row markup
  --attributes: string # Optional table attributes (single quoted values)
  --header: oneof<nothing, bool> # Include header row (default: true)
  input: string # JSON array object
  --omit: string # Columns to omit (comma separated)
  --order: string # Column order (comma separated)
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/JSONtoHTML")
  let req_body = {"alternate": $alternate, "attributes": $attributes, "header": $header, "input": $input, "omit": $omit, "order": $order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Data - JSON to XML
#
# POST /JSONtoXML
# operationId: JsonToXml
export def "jso-nto-xml create-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: string # JSON array object
  root: string # Name of root node
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/JSONtoXML")
  let req_body = {"input": $input, "root": $root} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Text - Join strings
#
# POST /JoinStrings
# operationId: JoinStrings
export def "join-strings create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: list<string> # Collection of strings to be joined
  lower: string@lower-completer # Convert strings in collection to lowercase
  separator: string # Separator character
  trim: string@trim-completer # Trim strings in collection
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/JoinStrings")
  let req_body = {"input": $input, "lower": $lower, "separator": $separator, "trim": $trim} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Finance - Market index
#
# POST /MarketIndex
# operationId: MarketIndex
export def "market-index create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Date (yyyy-MM-dd, leave empty for last trading day)
  symbol: string@symbol-completer # Market index
]: any -> record<adj_close: float, adj_high: float, adj_low: float, adj_open: float, adj_volume: float, close: float, date: string, exchange: string, high: float, low: float, open: float, symbol: string, volume: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/MarketIndex")
  let req_body = {"date": $date, "symbol": $symbol} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Data - Query JSON
#
# POST /QueryJSON
# operationId: QueryJson
export def "query-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: string # XML or JSON string
  query: string # XPath or JSONPath query
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/QueryJSON")
  let req_body = {"input": $input, "query": $query} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Data - Query XML
#
# POST /QueryXML
# operationId: QueryXml
export def "query-xml list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: string # XML or JSON string
  query: string # XPath or JSONPath query
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/QueryXML")
  let req_body = {"input": $input, "query": $query} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Random number
#
# POST /RandomNumber
# operationId: RandomNumber
export def "random-number create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  end: float # End of range
  start: float # Start of range
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/RandomNumber")
  let req_body = {"end": $end, "start": $start} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Text - Redact string
#
# POST /RedactString
# operationId: RedactString
export def "redact-string create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --regex: string # Regular expression pattern for matching strings
  --body-source: string # String containing the complete text
  --value: string # Individual string to redact
  --values: list<string> # Collection of strings to redact
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/RedactString")
  let req_body = {"regex": $regex, "source": $body_source, "value": $value, "values": $values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Collections - Remove from collection
#
# POST /RemoveFromCollection
# operationId: RemoveFromCollection
export def "remove-from-collection delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --index: string # Index position for operation (leave blank to specify end of collection)
  input: list<string> # Collection of values or objects to modify
  --item: string # Item (for multiple items, leave blank and use Items)
  --items: list<string> # Items (Collection, for a single item leave blank and use Item)
]: any -> record<result: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/RemoveFromCollection")
  let req_body = {"index": $index, "input": $input, "item": $item, "items": $items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Text - Replace string
#
# POST /ReplaceString
# operationId: ReplaceString
export def "replace-string update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  replacement: string # Replacement text
  --body-source: string # String containing the text to be replaced
  value: string # Text to replace
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ReplaceString")
  let req_body = {"replacement": $replacement, "source": $body_source, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Collections - Replace values in collection
#
# POST /ReplaceValuesInCollection
# operationId: ReplaceValuesInCollection
export def "replace-values-in-collection update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ignore_case: string@ignore-case-completer # Ignore case (default: true)
  input: list<string> # Collection of strings
  --body-match: string # Match value
  replacement: string # Replacement value
]: any -> record<result: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ReplaceValuesInCollection")
  let req_body = {"ignoreCase": $ignore_case, "input": $input, "match": $body_match, "replacement": $replacement} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Files - Resize Image
#
# POST /ResizeImage
# operationId: ResizeImage
export def "resize-image resize" [
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
  algorithm: string@algorithm-completer-1 # Optimize output quality of the target image (default: Bicubic (default))
  file: string # Source image file (format: binary)
  --height: float # Image height (pixels or percent)
  units: string@units-completer # Image adjustment units (default: Pixels)
  --width: float # Image width (pixels or percent)
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ResizeImage")
  let req_body = {"algorithm": $algorithm, "file": $file, "height": $height, "units": $units, "width": $width} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "image/bmp")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Files - Rotate Image
#
# POST /RotateImage
# operationId: RotateImage
export def "rotate-image create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  degrees: string # Number of degrees
  file: string # Source image file (format: binary)
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/RotateImage")
  let req_body = {"degrees": $degrees, "file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Math - Round number
#
# POST /RoundNumber
# operationId: RoundNumber
export def "round-number create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value to calculate
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/RoundNumber")
  let req_body = {"decimals": $decimals, "input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Text - Shorten hyperlink
#
# POST /ShortenLink
# operationId: ShortenLink
export def "shorten-link create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-source: string # String variable or text value
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ShortenLink")
  let req_body = {"source": $body_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Collections - Sort collection
#
# POST /SortCollection
# operationId: SortCollection
export def "sort-collection create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: list<string> # Collection of strings to sort
  order: string@order-completer # Sort order (default: Ascending)
]: any -> record<result: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/SortCollection")
  let req_body = {"input": $input, "order": $order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Text - Speech to Text
#
# POST /SpeechToText
# operationId: SpeechToText
export def "speech-to-text create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # Source audio file (WAV, MP3, AAC, M4A) (format: binary)
  language: string@language-completer # Language of audio input (default: English (United States))
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/SpeechToText")
  let req_body = {"file": $file, "language": $language} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Collections - Split collection
#
# POST /SplitCollection
# operationId: SplitCollection
export def "split-collection create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --index: string # Index location to split (leave empty to use Match value)
  input: list<string> # Collection of items to split
  --body-match: string # String to match (explicit, case-insensitive, leave empty to use Index)
]: any -> record<result1: list<string>, result2: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/SplitCollection")
  let req_body = {"index": $index, "input": $input, "match": $body_match} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Text - Split string
#
# POST /SplitString
# operationId: SplitString
export def "split-string create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  characters: string # One or more characters that will be used to split the text
  input: string # Text to split
]: any -> record<data: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/SplitString")
  let req_body = {"characters": $characters, "input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Math - Calculate standard deviation
#
# POST /StandardDeviation
# operationId: StandardDeviation
export def "standard-deviation create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: list<float> # Colllection of values to calculate
]: any -> record<result: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/StandardDeviation")
  let req_body = {"decimals": $decimals, "input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Finance - Stock prices
#
# POST /StockPrices
# operationId: StockPrices
export def "stock-prices create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Date (yyyy-MM-dd, leave empty for latest)
  --exchange: string@exchange-completer # Stock exchange
  symbols: string # Stock ticker symbols (comma-separated, max 20)
]: any -> record<result: table<close: float, date: string, exchange: string, high: float, low: float, open: float, symbol: string, volume: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/StockPrices")
  let req_body = {"date": $date, "exchange": $exchange, "symbols": $symbols} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Text - String to File
#
# POST /StringToFile
# operationId: StringToFile
export def "string-to-file create" [
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
  extension: string@extension-completer # File extension (default: TXT)
  filename: string # Name of file (without extension)
  input: string # Text string (body of file)
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/StringToFile")
  let req_body = {"extension": $extension, "filename": $filename, "input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Text - Text to Speech
#
# POST /TextToSpeech
# operationId: TextToSpeech
export def "text-to-speech create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string # Text to convert (10,000 characters max)
  type: string@type-completer-2 # Text or file type (default: PlainText)
  voice: string@voice-completer # Voice locale (must match language of input text) (default: en-US, Aria (Female))
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/TextToSpeech")
  let req_body = {"text": $text, "type": $type, "voice": $voice} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "audio/mp3"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Text - Translate string
#
# POST /TranslateString
# operationId: TranslateString
export def "translate-string create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: string # String containing the text to be translated
  language: string@language-completer-1 # Translation language
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/TranslateString")
  let req_body = {"input": $input, "language": $language} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Text - Trim string
#
# POST /TrimString
# operationId: TrimString
export def "trim-string create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-source: string # String containing the text to be trimmed
  type: string@type-completer-3 # Type of white space to remove
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/TrimString")
  let req_body = {"source": $body_source, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Text - Decode URL
#
# POST /URLDecode
# operationId: UrlDecode
export def "url-decode create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-source: string # Encoded string variable or text value
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/URLDecode")
  let req_body = {"source": $body_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Text - Encode URL
#
# POST /URLEncode
# operationId: UrlEncode
export def "url-encode create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-source: string # String variable or text value
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/URLEncode")
  let req_body = {"source": $body_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Text - Validate email
#
# POST /ValidateEmail
# operationId: ValidateEmail
export def "validate-email validate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-source: string # String variable or text value
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ValidateEmail")
  let req_body = {"source": $body_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Text - Verify hash
#
# POST /VerifyHash
# operationId: VerifyHash
export def "verify-hash verify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  algorithm: string@algorithm-completer # Hash algorithm
  hash: string # Hashed result
  input: string # Original source string
]: any -> record<result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/VerifyHash")
  let req_body = {"algorithm": $algorithm, "hash": $hash, "input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Files - Watermark Image
#
# POST /WatermarkImage
# operationId: WatermarkImage
export def "watermark-image create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  color: string # Text color hex value (default: 000000)
  file: string # Source image file (format: binary)
  font: string@font-completer # Text font (default: Arial)
  horizontal: string@horizontal-completer # Horizontal alignment (default: Center)
  size: float # Font size (points)
  text: string # Watermark text
  vertical: string@vertical-completer # Vertical alignment (default: Center)
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/WatermarkImage")
  let req_body = {"color": $color, "file": $file, "font": $font, "horizontal": $horizontal, "size": $size, "text": $text, "vertical": $vertical} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# DateTime - Get world time
#
# POST /WorldTime
# operationId: WorldTime
export def "world-time create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # Display format (defaults to 'yyyy-MM-dd HH:mm:ss')
  input: string # Source date and time
  --body-source: string@source-completer-11 # default: GMT Standard Time - (GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London
  target: string@target-completer-11 # default: GMT Standard Time - (GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/WorldTime")
  let req_body = {"format": $format, "input": $input, "source": $body_source, "target": $target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Data - XML to JSON
#
# POST /XMLtoJSON
# operationId: XmlToJson
export def "xm-lto-json create-xml" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: string # XML string
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-ibm-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/XMLtoJSON")
  let req_body = {"input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
