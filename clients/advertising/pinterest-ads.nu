# Auto-generated client for Pinterest REST API v5.28.0
# Source: https://raw.githubusercontent.com/pinterest/api-description/main/v5/openapi.yaml
# Auth: --token flag or $env.PINTEREST_REST_API_TOKEN

const BASE_URL = "https://api.pinterest.com/v5"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PINTEREST_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://api.pinterest.com/v5"] }
def auth-scheme-completer [] { ["bearer" "basic"] }

# Completers for enum parameters
def country-completer [] { ["AD" "AE" "AF" "AG" "AI" "AL" "AM" "AO" "AQ" "AR" "AS" "AT" "AU" "AW" "AX" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BL" "BM" "BN" "BO" "BQ" "BR" "BS" "BT" "BV" "BW" "BY" "BZ" "CA" "CC" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CU" "CV" "CW" "CX" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GF" "GG" "GH" "GI" "GL" "GM" "GN" "GP" "GQ" "GR" "GS" "GT" "GU" "GW" "GY" "HK" "HM" "HN" "HR" "HT" "HU" "ID" "IE" "IL" "IM" "IN" "IO" "IQ" "IR" "IS" "IT" "JE" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KR" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "LY" "MA" "MC" "MD" "ME" "MF" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MQ" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NF" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PM" "PN" "PR" "PS" "PT" "PW" "PY" "QA" "RE" "RO" "RS" "RU" "RW" "SA" "SB" "SC" "SD" "SE" "SG" "SH" "SI" "SJ" "SK" "SL" "SM" "SN" "SO" "SR" "SS" "ST" "SV" "SX" "SY" "SZ" "TC" "TD" "TF" "TG" "TH" "TJ" "TK" "TL" "TM" "TN" "TO" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "UM" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WF" "WS" "YE" "YT" "ZA" "ZM" "ZW"] }
def currency-completer [] { ["ARS" "AUD" "BRL" "CAD" "CHF" "CLP" "COP" "CZK" "DKK" "EUR" "GBP" "HKD" "HUF" "ILS" "INR" "JPY" "KRW" "MXN" "NOK" "NZD" "PLN" "RON" "SEK" "SGD" "TRY" "UNK" "USD"] }
def order-completer [] { ["ASCENDING" "DESCENDING"] }
def granularity-completer [] { ["DAY" "HOUR" "MONTH" "TOTAL" "WEEK"] }
def click-window-days-completer [] { ["0" "1" "14" "30" "60" "7"] }
def engagement-window-days-completer [] { ["0" "1" "14" "30" "60" "7"] }
def view-window-days-completer [] { ["0" "1" "14" "30" "60" "7"] }
def conversion-report-time-completer [] { ["TIME_OF_AD_ACTION" "TIME_OF_CONVERSION"] }
def reporting-timezone-completer [] { ["AD_ACCOUNT_TIME_ZONE" "PINTEREST_TIME_ZONE"] }
def audience-insight-type-completer [] { ["PINTEREST_TOTAL_AUDIENCE" "YOUR_ENGAGED_AUDIENCE" "YOUR_TOTAL_AUDIENCE"] }
def ownership-type-completer [] { ["OWNED" "RECEIVED"] }
def operation-type-completer [] { ["REVOKE" "SHARE"] }
def account-type-completer [] { ["AD_ACCOUNT" "BUSINESS_ACCOUNT"] }
def sort-completer [] { ["BILLING_PERIOD" "DOCUMENT_TYPE" "DUE_DATE" "INVOICE_NUMBER" "TOTAL_AMOUNT"] }
def status-completer [] { ["CLOSED" "OPEN"] }
def document-type-completer [] { ["CREDIT_MEMO" "INVOICE"] }
def lookback-period-completer [] { ["14d" "1d"] }
def source-platform-completer [] { ["MOBILE" "MOBILE_ANDROID" "MOBILE_IOS" "OFFLINE" "PINTEREST_ANDROID" "PINTEREST_IOS" "PINTEREST_WEB" "POINT_OF_SALE" "WEB"] }
def ingestion-source-completer [] { ["CONVERSIONS_API" "FILE_UPLOAD" "MMP" "NATIVE" "TAG"] }
def operation-completer [] { ["ADD" "REMOVE"] }
def operation-type-completer-1 [] { ["REMOVE" "UPDATE"] }
def schedule-type-completer [] { ["CAMPAIGN_BID_MULTIPLIERS" "CAMPAIGN_BUDGET_CHANGE"] }
def currency-info-completer [] { ["ARS" "AUD" "BRL" "CAD" "CHF" "CLP" "COP" "CZK" "DKK" "EUR" "GBP" "HKD" "HUF" "ILS" "INR" "JPY" "KRW" "MXN" "NOK" "NZD" "PLN" "RON" "SEK" "SGD" "TRY" "UNK" "USD"] }
def placement-group-completer [] { ["ALL" "BROWSE" "OTHER" "SEARCH"] }
def privacy-completer [] { ["ALL" "PROTECTED" "PUBLIC" "PUBLIC_AND_SECRET" "SECRET"] }
def privacy-completer-1 [] { ["PUBLIC" "SECRET"] }
def asset-type-completer [] { ["AD_ACCOUNT" "ASSET_GROUP" "CATALOG" "CONSUMER" "PROFILE"] }
def invite-type-completer [] { ["MEMBER_INVITE" "PARTNER_INVITE" "PARTNER_REQUEST"] }
def asset-type-completer-1 [] { ["AD_ACCOUNT" "ASSET_GROUP" "CATALOG" "CONSUMER" "CONVERSION_TAG" "PROFILE"] }
def sort-by-completer [] { ["ID" "NAME" "PERMISSIONS"] }
def search-by-completer [] { ["ID" "NAME" "NAME_OR_ID" "NAME_OR_OWNER" "OWNER_NAME"] }
def asset-permission-type-completer [] { ["AGGREGATED_PERMISSION" "DIRECT_PERMISSION"] }
def partner-type-completer [] { ["EXTERNAL" "INTERNAL"] }
def asset-type-completer-2 [] { ["AD_ACCOUNT" "ASSET_GROUP" "CATALOG" "CONSUMER" "CONVERSION_SEGMENT" "CONVERSION_TAG" "PINNER_LIST" "PROFILE"] }
def catalog-type-completer [] { ["CREATIVE_ASSETS" "HOTEL" "RETAIL"] }
def language-completer [] { ["af-ZA" "ar-SA" "bg-BG" "bn-IN" "cs-CZ" "da-DK" "de" "el-GR" "en-AU" "en-CA" "en-GB" "en-IN" "en-US" "es-419" "es-AR" "es-ES" "es-MX" "fi-FI" "fr" "fr-CA" "he-IL" "hi-IN" "hr-HR" "hu-HU" "id-ID" "it" "ja" "ko-KR" "ms-MY" "nb-NO" "nl" "pl-PL" "pt-BR" "pt-PT" "ro-RO" "ru-RU" "sk-SK" "sv-SE" "te-IN" "th-TH" "tl-PH" "tr" "uk-UA" "vi-VN" "zh-CN" "zh-TW"] }
def default-availability-completer [] { ["" "IN_STOCK" "OUT_OF_STOCK" "PREORDER"] }
def default-country-completer [] { ["AD" "AE" "AF" "AG" "AI" "AL" "AM" "AO" "AQ" "AR" "AS" "AT" "AU" "AW" "AX" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BL" "BM" "BN" "BO" "BQ" "BR" "BS" "BT" "BV" "BW" "BY" "BZ" "CA" "CC" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CU" "CV" "CW" "CX" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GF" "GG" "GH" "GI" "GL" "GM" "GN" "GP" "GQ" "GR" "GS" "GT" "GU" "GW" "GY" "HK" "HM" "HN" "HR" "HT" "HU" "ID" "IE" "IL" "IM" "IN" "IO" "IQ" "IR" "IS" "IT" "JE" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KR" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "LY" "MA" "MC" "MD" "ME" "MF" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MQ" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NF" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PM" "PN" "PR" "PS" "PT" "PW" "PY" "QA" "RE" "RO" "RS" "RU" "RW" "SA" "SB" "SC" "SD" "SE" "SG" "SH" "SI" "SJ" "SK" "SL" "SM" "SN" "SO" "SR" "SS" "ST" "SV" "SX" "SY" "SZ" "TC" "TD" "TF" "TG" "TH" "TJ" "TK" "TL" "TM" "TN" "TO" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "UM" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WF" "WS" "YE" "YT" "ZA" "ZM" "ZW"] }
def default-currency-completer [] { ["" "AED" "AFN" "ALL" "AMD" "ANG" "AOA" "ARS" "AUD" "AWG" "AZN" "BAM" "BBD" "BDT" "BGN" "BHD" "BIF" "BMD" "BND" "BOB" "BRL" "BSD" "BTN" "BWP" "BYN" "BYR" "BZD" "CAD" "CDF" "CHF" "CLP" "CNY" "COP" "CRC" "CUC" "CUP" "CVE" "CZK" "DJF" "DKK" "DOP" "DZD" "EGP" "ERN" "ETB" "EUR" "FJD" "FKP" "GBP" "GEL" "GGP" "GHS" "GIP" "GMD" "GNF" "GTQ" "GYD" "HKD" "HNL" "HRK" "HTG" "HUF" "IDR" "ILS" "IMP" "INR" "IQD" "IRR" "ISK" "JEP" "JMD" "JOD" "JPY" "KES" "KGS" "KHR" "KMF" "KPW" "KRW" "KWD" "KYD" "KZT" "LAK" "LBP" "LKR" "LRD" "LSL" "LYD" "MAD" "MDL" "MGA" "MKD" "MMK" "MNT" "MOP" "MRO" "MUR" "MVR" "MWK" "MXN" "MYR" "MZN" "NAD" "NGN" "NIO" "NOK" "NPR" "NZD" "OMR" "PAB" "PEN" "PGK" "PHP" "PKR" "PLN" "PYG" "QAR" "RON" "RSD" "RUB" "RWF" "SAR" "SBD" "SCR" "SDG" "SEK" "SGD" "SHP" "SLL" "SOS" "SPL" "SRD" "STD" "SVC" "SYP" "SZL" "THB" "TJS" "TMT" "TND" "TOP" "TRY" "TTD" "TVD" "TWD" "TZS" "UAH" "UGX" "USD" "UYU" "UZS" "VEF" "VND" "VUV" "WST" "XAF" "XCD" "XDR" "XOF" "XPF" "YER" "ZAR" "ZMW" "ZWD"] }
def format-completer [] { ["CSV" "INTEGRATION" "TSV" "XML"] }
def status-completer-1 [] { ["ACTIVE" "INACTIVE"] }
def item-validation-issue-completer [] { ["ADDITIONAL_IMAGE_LINK_LENGTH_TOO_LONG" "ADDITIONAL_IMAGE_LINK_WARNING" "ADULT_INVALID" "ADWORDS_FORMAT_INVALID" "ADWORDS_FORMAT_WARNING" "ADWORDS_SAME_AS_LINK" "AD_IMAGE_0_LINK_DUPLICATED" "AD_IMAGE_0_LINK_LENGTH_TOO_LONG" "AD_IMAGE_0_LINK_REQUIRED" "AD_IMAGE_0_LINK_WARNING" "AD_IMAGE_0_TAG_DUPLICATED" "AD_IMAGE_0_TAG_LENGTH_TOO_LONG" "AD_IMAGE_0_TAG_REQUIRED" "AD_IMAGE_10_LINK_DUPLICATED" "AD_IMAGE_10_LINK_LENGTH_TOO_LONG" "AD_IMAGE_10_LINK_REQUIRED" "AD_IMAGE_10_LINK_WARNING" "AD_IMAGE_10_TAG_DUPLICATED" "AD_IMAGE_10_TAG_LENGTH_TOO_LONG" "AD_IMAGE_10_TAG_REQUIRED" "AD_IMAGE_11_LINK_DUPLICATED" "AD_IMAGE_11_LINK_LENGTH_TOO_LONG" "AD_IMAGE_11_LINK_REQUIRED" "AD_IMAGE_11_LINK_WARNING" "AD_IMAGE_11_TAG_DUPLICATED" "AD_IMAGE_11_TAG_LENGTH_TOO_LONG" "AD_IMAGE_11_TAG_REQUIRED" "AD_IMAGE_12_LINK_DUPLICATED" "AD_IMAGE_12_LINK_LENGTH_TOO_LONG" "AD_IMAGE_12_LINK_REQUIRED" "AD_IMAGE_12_LINK_WARNING" "AD_IMAGE_12_TAG_DUPLICATED" "AD_IMAGE_12_TAG_LENGTH_TOO_LONG" "AD_IMAGE_12_TAG_REQUIRED" "AD_IMAGE_13_LINK_DUPLICATED" "AD_IMAGE_13_LINK_LENGTH_TOO_LONG" "AD_IMAGE_13_LINK_REQUIRED" "AD_IMAGE_13_LINK_WARNING" "AD_IMAGE_13_TAG_DUPLICATED" "AD_IMAGE_13_TAG_LENGTH_TOO_LONG" "AD_IMAGE_13_TAG_REQUIRED" "AD_IMAGE_14_LINK_DUPLICATED" "AD_IMAGE_14_LINK_LENGTH_TOO_LONG" "AD_IMAGE_14_LINK_REQUIRED" "AD_IMAGE_14_LINK_WARNING" "AD_IMAGE_14_TAG_DUPLICATED" "AD_IMAGE_14_TAG_LENGTH_TOO_LONG" "AD_IMAGE_14_TAG_REQUIRED" "AD_IMAGE_15_LINK_DUPLICATED" "AD_IMAGE_15_LINK_LENGTH_TOO_LONG" "AD_IMAGE_15_LINK_REQUIRED" "AD_IMAGE_15_LINK_WARNING" "AD_IMAGE_15_TAG_DUPLICATED" "AD_IMAGE_15_TAG_LENGTH_TOO_LONG" "AD_IMAGE_15_TAG_REQUIRED" "AD_IMAGE_16_LINK_DUPLICATED" "AD_IMAGE_16_LINK_LENGTH_TOO_LONG" "AD_IMAGE_16_LINK_REQUIRED" "AD_IMAGE_16_LINK_WARNING" "AD_IMAGE_16_TAG_DUPLICATED" "AD_IMAGE_16_TAG_LENGTH_TOO_LONG" "AD_IMAGE_16_TAG_REQUIRED" "AD_IMAGE_17_LINK_DUPLICATED" "AD_IMAGE_17_LINK_LENGTH_TOO_LONG" "AD_IMAGE_17_LINK_REQUIRED" "AD_IMAGE_17_LINK_WARNING" "AD_IMAGE_17_TAG_DUPLICATED" "AD_IMAGE_17_TAG_LENGTH_TOO_LONG" "AD_IMAGE_17_TAG_REQUIRED" "AD_IMAGE_18_LINK_DUPLICATED" "AD_IMAGE_18_LINK_LENGTH_TOO_LONG" "AD_IMAGE_18_LINK_REQUIRED" "AD_IMAGE_18_LINK_WARNING" "AD_IMAGE_18_TAG_DUPLICATED" "AD_IMAGE_18_TAG_LENGTH_TOO_LONG" "AD_IMAGE_18_TAG_REQUIRED" "AD_IMAGE_19_LINK_DUPLICATED" "AD_IMAGE_19_LINK_LENGTH_TOO_LONG" "AD_IMAGE_19_LINK_REQUIRED" "AD_IMAGE_19_LINK_WARNING" "AD_IMAGE_19_TAG_DUPLICATED" "AD_IMAGE_19_TAG_LENGTH_TOO_LONG" "AD_IMAGE_19_TAG_REQUIRED" "AD_IMAGE_1_LINK_DUPLICATED" "AD_IMAGE_1_LINK_LENGTH_TOO_LONG" "AD_IMAGE_1_LINK_REQUIRED" "AD_IMAGE_1_LINK_WARNING" "AD_IMAGE_1_TAG_DUPLICATED" "AD_IMAGE_1_TAG_LENGTH_TOO_LONG" "AD_IMAGE_1_TAG_REQUIRED" "AD_IMAGE_2_LINK_DUPLICATED" "AD_IMAGE_2_LINK_LENGTH_TOO_LONG" "AD_IMAGE_2_LINK_REQUIRED" "AD_IMAGE_2_LINK_WARNING" "AD_IMAGE_2_TAG_DUPLICATED" "AD_IMAGE_2_TAG_LENGTH_TOO_LONG" "AD_IMAGE_2_TAG_REQUIRED" "AD_IMAGE_3_LINK_DUPLICATED" "AD_IMAGE_3_LINK_LENGTH_TOO_LONG" "AD_IMAGE_3_LINK_REQUIRED" "AD_IMAGE_3_LINK_WARNING" "AD_IMAGE_3_TAG_DUPLICATED" "AD_IMAGE_3_TAG_LENGTH_TOO_LONG" "AD_IMAGE_3_TAG_REQUIRED" "AD_IMAGE_4_LINK_DUPLICATED" "AD_IMAGE_4_LINK_LENGTH_TOO_LONG" "AD_IMAGE_4_LINK_REQUIRED" "AD_IMAGE_4_LINK_WARNING" "AD_IMAGE_4_TAG_DUPLICATED" "AD_IMAGE_4_TAG_LENGTH_TOO_LONG" "AD_IMAGE_4_TAG_REQUIRED" "AD_IMAGE_5_LINK_DUPLICATED" "AD_IMAGE_5_LINK_LENGTH_TOO_LONG" "AD_IMAGE_5_LINK_REQUIRED" "AD_IMAGE_5_LINK_WARNING" "AD_IMAGE_5_TAG_DUPLICATED" "AD_IMAGE_5_TAG_LENGTH_TOO_LONG" "AD_IMAGE_5_TAG_REQUIRED" "AD_IMAGE_6_LINK_DUPLICATED" "AD_IMAGE_6_LINK_LENGTH_TOO_LONG" "AD_IMAGE_6_LINK_REQUIRED" "AD_IMAGE_6_LINK_WARNING" "AD_IMAGE_6_TAG_DUPLICATED" "AD_IMAGE_6_TAG_LENGTH_TOO_LONG" "AD_IMAGE_6_TAG_REQUIRED" "AD_IMAGE_7_LINK_DUPLICATED" "AD_IMAGE_7_LINK_LENGTH_TOO_LONG" "AD_IMAGE_7_LINK_REQUIRED" "AD_IMAGE_7_LINK_WARNING" "AD_IMAGE_7_TAG_DUPLICATED" "AD_IMAGE_7_TAG_LENGTH_TOO_LONG" "AD_IMAGE_7_TAG_REQUIRED" "AD_IMAGE_8_LINK_DUPLICATED" "AD_IMAGE_8_LINK_LENGTH_TOO_LONG" "AD_IMAGE_8_LINK_REQUIRED" "AD_IMAGE_8_LINK_WARNING" "AD_IMAGE_8_TAG_DUPLICATED" "AD_IMAGE_8_TAG_LENGTH_TOO_LONG" "AD_IMAGE_8_TAG_REQUIRED" "AD_IMAGE_9_LINK_DUPLICATED" "AD_IMAGE_9_LINK_LENGTH_TOO_LONG" "AD_IMAGE_9_LINK_REQUIRED" "AD_IMAGE_9_LINK_WARNING" "AD_IMAGE_9_TAG_DUPLICATED" "AD_IMAGE_9_TAG_LENGTH_TOO_LONG" "AD_IMAGE_9_TAG_REQUIRED" "AD_LINK_FORMAT_WARNING" "AD_LINK_SAME_AS_LINK" "AD_VIDEO_0_LINK_DUPLICATED" "AD_VIDEO_0_LINK_LENGTH_TOO_LONG" "AD_VIDEO_0_LINK_REQUIRED" "AD_VIDEO_0_LINK_WARNING" "AD_VIDEO_0_TAG_DUPLICATED" "AD_VIDEO_0_TAG_LENGTH_TOO_LONG" "AD_VIDEO_0_TAG_REQUIRED" "AD_VIDEO_1_LINK_DUPLICATED" "AD_VIDEO_1_LINK_LENGTH_TOO_LONG" "AD_VIDEO_1_LINK_REQUIRED" "AD_VIDEO_1_LINK_WARNING" "AD_VIDEO_1_TAG_DUPLICATED" "AD_VIDEO_1_TAG_LENGTH_TOO_LONG" "AD_VIDEO_1_TAG_REQUIRED" "AD_VIDEO_2_LINK_DUPLICATED" "AD_VIDEO_2_LINK_LENGTH_TOO_LONG" "AD_VIDEO_2_LINK_REQUIRED" "AD_VIDEO_2_LINK_WARNING" "AD_VIDEO_2_TAG_DUPLICATED" "AD_VIDEO_2_TAG_LENGTH_TOO_LONG" "AD_VIDEO_2_TAG_REQUIRED" "AGE_GROUP_INVALID" "ANDROID_DEEP_LINK_INVALID" "AVAILABILITY_DATE_INVALID" "AVAILABILITY_INVALID" "BLOCKLISTED_IMAGE_SIGNATURE" "COUNTRY_DOES_NOT_MAP_TO_CURRENCY" "CUSTOM_LABEL_LENGTH_TOO_LONG" "DESCRIPTION_LENGTH_TOO_LONG" "DESCRIPTION_MISSING" "DUPLICATE_PRODUCTS" "EXPIRATION_DATE_INVALID" "GENDER_INVALID" "GTIN_INVALID" "IMAGE_LINK_INVALID" "IMAGE_LINK_LENGTH_TOO_LONG" "IMAGE_LINK_MISSING" "IMAGE_LINK_WARNING" "INVALID_DOMAIN" "IOS_DEEP_LINK_INVALID" "IS_BUNDLE_INVALID" "ITEMID_MISSING" "ITEM_ADDITIONAL_IMAGE_DOWNLOAD_FAILURE" "ITEM_MAIN_IMAGE_DOWNLOAD_FAILURE" "LINK_FORMAT_INVALID" "LINK_FORMAT_WARNING" "LINK_LENGTH_TOO_LONG" "LIST_PRICE_INVALID" "MAX_ITEMS_PER_ITEM_GROUP_EXCEEDED" "MIN_AD_PRICE_INVALID" "MPN_INVALID" "MULTIPACK_INVALID" "OPTIONAL_CONDITION_INVALID" "OPTIONAL_CONDITION_MISSING" "OPTIONAL_PRODUCT_CATEGORY_INVALID" "OPTIONAL_PRODUCT_CATEGORY_MISSING" "PARSE_LINE_ERROR" "PINJOIN_CONTENT_UNSAFE" "PRICE_CANNOT_BE_DETERMINED" "PRICE_MISSING" "PRODUCT_CATEGORY_DEPTH_WARNING" "PRODUCT_LINK_MISSING" "PRODUCT_PRICE_INVALID" "PRODUCT_TYPE_LENGTH_TOO_LONG" "SALES_PRICE_INVALID" "SALES_PRICE_TOO_HIGH" "SALES_PRICE_TOO_LOW" "SALE_DATE_INVALID" "SHIPPING_HEIGHT_INVALID" "SHIPPING_INVALID" "SHIPPING_WEIGHT_INVALID" "SHIPPING_WIDTH_INVALID" "SIZE_SYSTEM_INVALID" "SIZE_TYPE_INVALID" "TAX_INVALID" "TITLE_LENGTH_TOO_LONG" "TITLE_MISSING" "TOO_MANY_ADDITIONAL_IMAGE_LINKS" "UTM_SOURCE_AUTO_CORRECTED" "VIDEO_REQUIRED_WHEN_AD_VIDEO_PROVIDED" "WEIGHT_UNIT_INVALID"] }
def catalog-type-completer-1 [] { ["HOTEL" "RETAIL"] }
def grant-type-completer [] { ["authorization_code" "client_credentials" "refresh_token"] }
def pin-filter-completer [] { ["exclude_native" "exclude_repins" "has_been_promoted"] }
def pin-type-completer [] { ["PRIVATE"] }
def app-types-completer [] { ["ALL" "MOBILE" "TABLET" "WEB"] }
def split-field-completer [] { ["APP_TYPE" "NO_SPLIT"] }
def report-type-completer [] { ["ASYNC" "SYNC"] }
def region-completer [] { ["CA" "GB+IE" "US"] }
def lookback-window-completer [] { ["180" "365" "730" "90"] }
def engagement-type-completer [] { ["ENGAGEMENT" "OUTBOUND_CLICK" "SAVE"] }
def interest-completer [] { ["ALL" "ANIMALS" "ARCHITECTURE" "ART" "BEAUTY" "DIY_AND_CRAFTS" "EDUCATION" "EVENT_PLANNING" "FASHION" "FOOD_AND_DRINKS" "GARDENING" "HEALTH" "HOME_DECOR" "PARENTING" "TRAVEL" "WEDDING"] }
def from-claimed-content-completer [] { ["BOTH" "CLAIMED" "OTHER"] }
def pin-format-completer [] { ["ADS_IDEA" "ADS_PRODUCT" "ADS_STANDARD" "ADS_VIDEO" "ALL" "ORGANIC_IMAGE" "ORGANIC_PRODUCT" "ORGANIC_VIDEO"] }
def content-type-completer [] { ["ALL" "ORGANIC" "PAID"] }
def source-completer [] { ["ALL" "OTHER_PINS" "YOUR_PINS"] }
def split-field-completer-1 [] { ["APP_TYPE" "NO_SPLIT" "OWNED_CONTENT" "PIN_FORMAT" "SOURCE"] }
def sort-by-completer-1 [] { ["ENGAGEMENT" "IMPRESSION" "OUTBOUND_CLICK" "PIN_CLICK" "SAVE"] }
def created-in-last-n-days-completer [] { ["30"] }
def sort-by-completer-2 [] { ["IMPRESSION" "OUTBOUND_CLICK" "QUARTILE_95_PERCENT_VIEW" "SAVE" "VIDEO_10S_VIEW" "VIDEO_AVG_WATCH_TIME" "VIDEO_MRC_VIEW" "VIDEO_START" "VIDEO_V50_WATCH_TIME"] }
def feed-type-completer [] { ["ALL" "CREATOR_ONLY" "RANKED" "RANKED_CREATOR_ONLY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "ad-accounts accounts/list" } } | get name | first)
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

# List ad accounts
#
# GET /ad_accounts
# operationId: ad_accounts/list
export def "ad-accounts accounts/list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-shared-accounts: oneof<nothing, bool> # Include shared ad accounts (default: true)
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<country: string, created_time: int, currency: string, id: string, name: string, owner: record, permissions: list, time_zone: string, updated_time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_shared_accounts" $include_shared_accounts "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ad_accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create ad account
#
# POST /ad_accounts
# operationId: ad_accounts/create
export def "ad-accounts accounts/create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --country: string@country-completer # Country ID from ISO 3166-1 alpha-2.
  --currency: string@currency-completer # Currency Codes from ISO 4217
  --name: string # Ad account name.
  --owner-user-id: string # Advertiser's owning user ID.
  --time-zone: string # The time zone of the ad account, in IANA format (e.g., "America/Los_Angeles"). Adding your local time zone lets you view your campaigns and ad reporting in your preferred time zone. Future reports will be available in both your local time zone and default UTC time zone. Historical data takes 1-2 months to backfill. Your billing and order lines will remain in UTC. (e.g. America/Los_Angeles)
]: any -> record<country: string, created_time: int, currency: string, id: string, name: string, owner: record<id: string, username: string>, permissions: list<string>, time_zone: string, updated_time: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ad_accounts")
  let body = {country: $country, currency: $currency, name: $name, owner_user_id: $owner_user_id, time_zone: $time_zone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get ad account
#
# GET /ad_accounts/{ad_account_id}
# operationId: ad_accounts/get
export def "ad-accounts accounts/get" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<country: string, created_time: int, currency: string, id: string, name: string, owner: record<id: string, username: string>, permissions: list<string>, time_zone: string, updated_time: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List ad groups
#
# GET /ad_accounts/{ad_account_id}/ad_groups
# operationId: ad_groups/list
export def "ad-accounts-ad-groups groups/list" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
  --order: string@order-completer # The order in which to sort the items returned: "ASCENDING" or "DESCENDING" by ID. Note that higher-value IDs are associated with more-recently added items.
  --campaign-ids: list # List of Campaign Ids to use to filter the results.
  --ad-group-ids: list # List of Ad group Ids to retrieve keywords from. This feature is currently in BETA and is not available to all users.
  --entity-statuses: list # Entity status (default: [ACTIVE, PAUSED])
  --translate-interests-to-names: oneof<nothing, bool> # Return interests as text names (if value is true) rather than topic IDs. (default: false)
]: nothing -> record<bookmark: string, items: table<auto_targeting_enabled: bool, bid_multiplier: float, budget_type: string, pacing_delivery_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "campaign_ids" $campaign_ids "multi") (serialize-qp "ad_group_ids" $ad_group_ids "multi") (serialize-qp "entity_statuses" $entity_statuses "multi") (serialize-qp "translate_interests_to_names" $translate_interests_to_names "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ad_groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create ad groups
#
# POST /ad_accounts/{ad_account_id}/ad_groups
# operationId: ad_groups/create
export def "ad-accounts-ad-groups groups/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<items: table<data: record, exceptions: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ad_groups")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update ad groups
#
# PATCH /ad_accounts/{ad_account_id}/ad_groups
# operationId: ad_groups/update
export def "ad-accounts-ad-groups groups/update" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<items: table<data: record, exceptions: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ad_groups")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get ad group analytics
#
# GET /ad_accounts/{ad_account_id}/ad_groups/analytics
# operationId: ad_groups/analytics
export def "ad-accounts-ad-groups-analytics groups/analytics" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # Metric report start date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days back from today. (format: date)
  --end-date: string # Metric report end date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days past start_date. (format: date)
  --ad-group-ids: list # List of Ad group Ids to use to filter the results.
  --columns: list # Columns to retrieve, encoded as a comma-separated string. **NOTE**: Any metrics defined as MICRO_DOLLARS returns a value based on the advertiser profile's currency field. For USD, ($1/1,000,000, or $0.000001 - one one-ten-thousandth of a cent). it's microdollars. Otherwise, it's in microunits of the advertiser's currency.  For example, if the advertiser's currency is GBP (British pound sterling), all MICRO_DOLLARS fields will be in GBP microunits (1/1,000,000 British pound).  If a column has no value, it may not be returned.
  --granularity: string@granularity-completer #   TOTAL - metrics are aggregated over the specified date range.    DAY - metrics are broken down daily.    HOUR - metrics are broken down hourly.    WEEK - metrics are broken down weekly.    MONTH - metrics are broken down monthly
  --click-window-days: float@click-window-days-completer # Number of days to use as the conversion attribution window for a pin click action. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `30` days. (default: 30)
  --engagement-window-days: float@engagement-window-days-completer # Number of days to use as the conversion attribution window for an engagement action. Engagements include saves, closeups, link clicks, and carousel card swipes. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `30` days. **Note:** This parameter no longer returns new data. However, you can still access historic data through **Sept 30, 2027**. (default: 30)
  --view-window-days: float@view-window-days-completer # Number of days to use as the conversion attribution window for a view action. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `1` day. (default: 1)
  --conversion-report-time: string@conversion-report-time-completer # The date by which the conversion metrics returned from this endpoint will be reported. There are two dates associated with a conversion event: the date that the user interacted with the ad, and the date that the user completed a conversion event. (default: TIME_OF_AD_ACTION)
  --aggregate-report-rows: oneof<nothing, bool> # Determines if report rows should be aggregated across all requested entities. This feature is currently in BETA and is not available to all users. (default: false)
  --reporting-timezone: string@reporting-timezone-completer # Specify the timezone to be applied for the reporting. This feature is currently in BETA and is not available to all users. (e.g. PINTEREST_TIME_ZONE)
]: nothing -> table<AD_GROUP_ID: string, DATE: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "ad_group_ids" $ad_group_ids "multi") (serialize-qp "columns" $columns "csv") (serialize-qp "granularity" $granularity "scalar") (serialize-qp "click_window_days" $click_window_days "scalar") (serialize-qp "engagement_window_days" $engagement_window_days "scalar") (serialize-qp "view_window_days" $view_window_days "scalar") (serialize-qp "conversion_report_time" $conversion_report_time "scalar") (serialize-qp "aggregate_report_rows" $aggregate_report_rows "scalar") (serialize-qp "reporting_timezone" $reporting_timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ad_groups/analytics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get audience sizing
#
# POST /ad_accounts/{ad_account_id}/ad_groups/audience_sizing
# operationId: ad_groups/audience_sizing
# --keywords item shape: {match_type: "BROAD"|"PHRASE"|"EXACT"|"EXACT_NEGATIVE"|"PHRASE_NEGATIVE", value: string}
# --targeting_spec shape: {AGE_BUCKET?: list, APPTYPE?: list, AUDIENCE_EXCLUDE?: list, AUDIENCE_INCLUDE?: list, GENDER?: list, GEO?: list, GEO_EXCLUDE?: list, INTEREST?: list, LOCALE?: list, LOCATION?: list, LOCATION_EXCLUDE?: list, MAXIMUM_AGE?: string, MINIMUM_AGE?: string, SHOPPING_RETARGETING?: list, TARGETING_STRATEGY?: list}
export def "ad-accounts-ad-groups-audience-sizing sizing" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auto-targeting-enabled: oneof<nothing, bool> # Enable auto-targeting for ad group. Default value is True. Also known as [Pinterest Performance+ targeting](https://help.pinterest.com/en/business/article/performance-plus-targeting). (default: true)
  --creative-types: list # Pin creative types filter. **Note:** SHOP_THE_PIN has been deprecated. Please use COLLECTION instead. (nullable)
  --keywords: list # Array of keyword objects. If the keywords field is missing, all keywords will be targeted. (nullable) — item shape: {match_type: "BROAD"|"PHRASE"|"EXACT"|"EXACT_NEGATIVE"|"PHRASE_NEGATIVE", value: string}
  --placement-group: any # [Placement group](/docs/redoc/#section/Placement-group). (default: ALL)
  --product-group-ids: list # Targeted product group IDs. **Note:** This can only be combined with shopping/catalog sales campaigns. For more information, [click here](https://help.pinterest.com/en/business/article/shopping-ads#section-14571). SHOPPING_RETARGETING must be included in targeting_spec object or this field will be ignored. (nullable)
  --targeting-spec: record # shape: {AGE_BUCKET?: list, APPTYPE?: list, AUDIENCE_EXCLUDE?: list, AUDIENCE_INCLUDE?: list, GENDER?: list, GEO?: list, GEO_EXCLUDE?: list, INTEREST?: list, LOCALE?: list, LOCATION?: list, LOCATION_EXCLUDE?: list, MAXIMUM_AGE?: string, MINIMUM_AGE?: string, SHOPPING_RETARGETING?: list, TARGETING_STRATEGY?: list}
]: any -> record<audience_size_lower_bound: float, audience_size_upper_bound: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ad_groups/audience_sizing")
  let body = {auto_targeting_enabled: $auto_targeting_enabled, creative_types: $creative_types, keywords: $keywords, placement_group: $placement_group, product_group_ids: $product_group_ids, targeting_spec: $targeting_spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get targeting analytics for ad groups
#
# GET /ad_accounts/{ad_account_id}/ad_groups/targeting_analytics
# operationId: ad_groups_targeting_analytics/get
export def "ad-accounts-ad-groups-targeting-analytics analytics/get" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-group-ids: list # List of Ad group Ids to use to filter the results.
  --start-date: string # Metric report start date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days back from today. (format: date)
  --end-date: string # Metric report end date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days past start_date. (format: date)
  --targeting-types: list # Targeting type breakdowns for the report. The reporting per targeting type is independent from each other. ["AGE_BUCKET_AND_GENDER", "CREATIVE_ENHANCEMENTS"] are in BETA and not yet available to all users.
  --columns: list # Columns to retrieve, encoded as a comma-separated string. **NOTE**: Any metrics defined as MICRO_DOLLARS returns a value based on the advertiser profile's currency field. For USD, ($1/1,000,000, or $0.000001 - one one-ten-thousandth of a cent). it's microdollars. Otherwise, it's in microunits of the advertiser's currency.  For example, if the advertiser's currency is GBP (British pound sterling), all MICRO_DOLLARS fields will be in GBP microunits (1/1,000,000 British pound).  If a column has no value, it may not be returned.
  --granularity: string@granularity-completer #   TOTAL - metrics are aggregated over the specified date range.    DAY - metrics are broken down daily.    HOUR - metrics are broken down hourly.    WEEK - metrics are broken down weekly.    MONTH - metrics are broken down monthly
  --click-window-days: float@click-window-days-completer # Number of days to use as the conversion attribution window for a pin click action. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `30` days. (default: 30)
  --engagement-window-days: float@engagement-window-days-completer # Number of days to use as the conversion attribution window for an engagement action. Engagements include saves, closeups, link clicks, and carousel card swipes. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `30` days. **Note:** This parameter no longer returns new data. However, you can still access historic data through **Sept 30, 2027**. (default: 30)
  --view-window-days: float@view-window-days-completer # Number of days to use as the conversion attribution window for a view action. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `1` day. (default: 1)
  --conversion-report-time: string@conversion-report-time-completer # The date by which the conversion metrics returned from this endpoint will be reported. There are two dates associated with a conversion event: the date that the user interacted with the ad, and the date that the user completed a conversion event. (default: TIME_OF_AD_ACTION)
  --attribution-types: list # List of types of attribution for the conversion report
  --reporting-timezone: string@reporting-timezone-completer # Specify the timezone to be applied for the reporting. This feature is currently in BETA and is not available to all users. (e.g. PINTEREST_TIME_ZONE)
  --sort-columns: list # Sort Columns.
  --sort-ascending: oneof<nothing, bool> # Sort ascending.
]: nothing -> record<data: table<metrics: record, targeting_type: string, targeting_value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_group_ids" $ad_group_ids "multi") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "targeting_types" $targeting_types "csv") (serialize-qp "columns" $columns "csv") (serialize-qp "granularity" $granularity "scalar") (serialize-qp "click_window_days" $click_window_days "scalar") (serialize-qp "engagement_window_days" $engagement_window_days "scalar") (serialize-qp "view_window_days" $view_window_days "scalar") (serialize-qp "conversion_report_time" $conversion_report_time "scalar") (serialize-qp "attribution_types" $attribution_types "csv") (serialize-qp "reporting_timezone" $reporting_timezone "scalar") (serialize-qp "sort_columns" $sort_columns "multi") (serialize-qp "sort_ascending" $sort_ascending "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ad_groups/targeting_analytics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ad group
#
# GET /ad_accounts/{ad_account_id}/ad_groups/{ad_group_id}
# operationId: ad_groups/get
export def "ad-accounts-ad-groups groups/get" [
  ad_group_id: string
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auto_targeting_enabled: bool, bid_multiplier: float, budget_type: string, pacing_delivery_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ad_groups/($ad_group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Process dynamic titles CSV
#
# POST /ad_accounts/{ad_account_id}/ad_groups/{ad_group_id}/dynamic_titles
# operationId: ad_groups_dynamic_titles/process_csv
export def "ad-accounts-ad-groups-dynamic-titles csv" [
  ad_account_id: string
  ad_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  request_id: string # The request_id returned from the GET uploads endpoint.
]: any -> record<errors: table<error_type: string, row_number: int>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ad_groups/($ad_group_id)/dynamic_titles")
  let body = {request_id: $request_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get dynamic titles CSV download URL
#
# GET /ad_accounts/{ad_account_id}/ad_groups/{ad_group_id}/dynamic_titles/csv
# operationId: ad_groups_dynamic_titles/download_csv
export def "ad-accounts-ad-groups-dynamic-titles-csv csv" [
  ad_account_id: string
  ad_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<download_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ad_groups/($ad_group_id)/dynamic_titles/csv")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get dynamic titles status
#
# GET /ad_accounts/{ad_account_id}/ad_groups/{ad_group_id}/dynamic_titles/status
# operationId: ad_groups_dynamic_titles/get_status
export def "ad-accounts-ad-groups-dynamic-titles-status status" [
  ad_account_id: string
  ad_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<generated_count: int, is_ready: bool, reviewed_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ad_groups/($ad_group_id)/dynamic_titles/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get dynamic titles upload URL
#
# GET /ad_accounts/{ad_account_id}/ad_groups/{ad_group_id}/dynamic_titles/uploads
# operationId: ad_groups_dynamic_titles/get_upload_url
export def "ad-accounts-ad-groups-dynamic-titles-uploads url" [
  ad_account_id: string
  ad_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<existing_filename: string, request_id: string, upload_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ad_groups/($ad_group_id)/dynamic_titles/uploads")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create ad preview with pin or image
#
# POST /ad_accounts/{ad_account_id}/ad_previews
# operationId: ad_previews/create
export def "ad-accounts-ad-previews previews/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --image-url: string # Image URL. (e.g. https://somewebsite.com/someimage.jpg)
  --promotion-id: string # Promotion id for the ad to preview, optional and only applicable when creating ad preview for an existing promotion. (e.g. 7834020404549)
  --title: string # Title displayed below ad. (e.g. My Preview Image)
  --creative-type: any # Creative type of the ad preview. (e.g. MAX_WIDTH_VIDEO_COLLECTION)
  --pin-id: string # Pin ID. (e.g. 7389479023)
  --catalog-product-group-id: string # Catalog Product Group Id. (e.g. 123456789)
  --customizable-cta-type: any # Select a call to action (CTA) to display below your ad. CTA options for catalog sales campaigns are `SHOP_NOW`, `BOOK_NOW`, `ON_SALE`, `GET_DEAL`, `BUY_ONLINE_PICKUP_IN_STORE`
  --hero-image-title: string # Title displayed below ad. (e.g. My Preview Image)
  --hero-image-url: string # Hero image URL. (e.g. https://somewebsite.com/someimage.jpg)
  --hero-pin-id: string # Pin id for the hero image. When creative type is COLLECTION, either hero_pin_id or (hero_image_url, hero_image_title) is required. (e.g. 987654321)
  --image-tag: string # Multi image template tag. (e.g. Christmas Sale)
  --item-id: string # Item id for product to preview standard shopping ads, optional and only applicable when creative type is SHOPPING. (e.g. 111111111)
  --preferred-media-type: any # Preferred media type. (e.g. IMAGE)
  --show-promotion: oneof<nothing, bool> # Include promotion data in preview when available on catalog item. Defaults to false.
  --video-tag: string # Multi video template tag, image_tag and video_tag are mutual exclusive. (e.g. Black Friday Sale)
]: any -> record<url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ad_previews")
  let body = {image_url: $image_url, promotion_id: $promotion_id, title: $title, creative_type: $creative_type, pin_id: $pin_id, catalog_product_group_id: $catalog_product_group_id, customizable_cta_type: $customizable_cta_type, hero_image_title: $hero_image_title, hero_image_url: $hero_image_url, hero_pin_id: $hero_pin_id, image_tag: $image_tag, item_id: $item_id, preferred_media_type: $preferred_media_type, show_promotion: $show_promotion, video_tag: $video_tag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List ads
#
# GET /ad_accounts/{ad_account_id}/ads
# operationId: ads/list
export def "ad-accounts-ads ads/list" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
  --order: string@order-completer # The order in which to sort the items returned: "ASCENDING" or "DESCENDING" by ID. Note that higher-value IDs are associated with more-recently added items.
  --campaign-ids: list # List of Campaign Ids to use to filter the results.
  --ad-group-ids: list # List of Ad group Ids to retrieve keywords from. This feature is currently in BETA and is not available to all users.
  --ad-ids: list # List of Ad Ids to use to filter the results.
  --entity-statuses: list # Entity status (default: [ACTIVE, PAUSED])
]: nothing -> record<bookmark: string, items: table<ad_account_id: string, ad_group_id: string, android_deep_link: string, campaign_id: string, carousel_android_deep_links: list, carousel_destination_urls: list, carousel_ios_deep_links: list, carting_platform_type: record, carting_products: list, click_tracking_url: string, collection_items_destination_url_template: string, collections_header_type: record, created_time: int, creative_type: string, customizable_cta_type: string, destination_url: string, disclosure_type: string, disclosure_url: string, grid_click_type: string, id: string, ios_deep_link: string, is_carting: bool, is_collage_accepted_terms: bool, is_collage_single_destination: bool, is_pin_deleted: bool, is_removable: bool, lead_form_id: string, name: string, pin_id: string, quiz_pin_data: record, rejected_reasons: list, rejection_labels: list, review_status: record, status: string, summary_status: record, tracking_urls: record, type: string, updated_time: int, view_tracking_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "campaign_ids" $campaign_ids "multi") (serialize-qp "ad_group_ids" $ad_group_ids "multi") (serialize-qp "ad_ids" $ad_ids "multi") (serialize-qp "entity_statuses" $entity_statuses "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create ads
#
# POST /ad_accounts/{ad_account_id}/ads
# operationId: ads/create
export def "ad-accounts-ads ads/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<items: table<data: record, exceptions: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ads")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update ads
#
# PATCH /ad_accounts/{ad_account_id}/ads
# operationId: ads/update
export def "ad-accounts-ads ads/update" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<items: table<data: record, exceptions: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ads")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get ad analytics
#
# GET /ad_accounts/{ad_account_id}/ads/analytics
# operationId: ads/analytics
export def "ad-accounts-ads-analytics ads/analytics" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pin-ids: list # List of Pin IDs.
  --start-date: string # Metric report start date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days back from today. (format: date)
  --end-date: string # Metric report end date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days past start_date. (format: date)
  --ad-ids: list # List of Ad Ids to use to filter the results.
  --columns: list # Columns to retrieve, encoded as a comma-separated string. **NOTE**: Any metrics defined as MICRO_DOLLARS returns a value based on the advertiser profile's currency field. For USD, ($1/1,000,000, or $0.000001 - one one-ten-thousandth of a cent). it's microdollars. Otherwise, it's in microunits of the advertiser's currency.  For example, if the advertiser's currency is GBP (British pound sterling), all MICRO_DOLLARS fields will be in GBP microunits (1/1,000,000 British pound).  If a column has no value, it may not be returned.
  --granularity: string@granularity-completer #   TOTAL - metrics are aggregated over the specified date range.    DAY - metrics are broken down daily.    HOUR - metrics are broken down hourly.    WEEK - metrics are broken down weekly.    MONTH - metrics are broken down monthly
  --click-window-days: float@click-window-days-completer # Number of days to use as the conversion attribution window for a pin click action. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `30` days. (default: 30)
  --engagement-window-days: float@engagement-window-days-completer # Number of days to use as the conversion attribution window for an engagement action. Engagements include saves, closeups, link clicks, and carousel card swipes. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `30` days. **Note:** This parameter no longer returns new data. However, you can still access historic data through **Sept 30, 2027**. (default: 30)
  --view-window-days: float@view-window-days-completer # Number of days to use as the conversion attribution window for a view action. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `1` day. (default: 1)
  --conversion-report-time: string@conversion-report-time-completer # The date by which the conversion metrics returned from this endpoint will be reported. There are two dates associated with a conversion event: the date that the user interacted with the ad, and the date that the user completed a conversion event. (default: TIME_OF_AD_ACTION)
  --campaign-ids: list # List of Campaign Ids to use to filter the results.
  --reporting-timezone: string@reporting-timezone-completer # Specify the timezone to be applied for the reporting. This feature is currently in BETA and is not available to all users. (e.g. PINTEREST_TIME_ZONE)
]: nothing -> table<AD_ID: string, DATE: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pin_ids" $pin_ids "multi") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "ad_ids" $ad_ids "multi") (serialize-qp "columns" $columns "csv") (serialize-qp "granularity" $granularity "scalar") (serialize-qp "click_window_days" $click_window_days "scalar") (serialize-qp "engagement_window_days" $engagement_window_days "scalar") (serialize-qp "view_window_days" $view_window_days "scalar") (serialize-qp "conversion_report_time" $conversion_report_time "scalar") (serialize-qp "campaign_ids" $campaign_ids "multi") (serialize-qp "reporting_timezone" $reporting_timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ads/analytics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get targeting analytics for ads
#
# GET /ad_accounts/{ad_account_id}/ads/targeting_analytics
# operationId: ad_targeting_analytics/get
export def "ad-accounts-ads-targeting-analytics analytics/get" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-ids: list # List of Ad Ids to use to filter the results.
  --start-date: string # Metric report start date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days back from today. (format: date)
  --end-date: string # Metric report end date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days past start_date. (format: date)
  --targeting-types: list # Targeting type breakdowns for the report. The reporting per targeting type is independent from each other. ["AGE_BUCKET_AND_GENDER"] is in BETA and not yet available to all users.
  --columns: list # Columns to retrieve, encoded as a comma-separated string. **NOTE**: Any metrics defined as MICRO_DOLLARS returns a value based on the advertiser profile's currency field. For USD, ($1/1,000,000, or $0.000001 - one one-ten-thousandth of a cent). it's microdollars. Otherwise, it's in microunits of the advertiser's currency.  For example, if the advertiser's currency is GBP (British pound sterling), all MICRO_DOLLARS fields will be in GBP microunits (1/1,000,000 British pound).  If a column has no value, it may not be returned.
  --granularity: string@granularity-completer #   TOTAL - metrics are aggregated over the specified date range.    DAY - metrics are broken down daily.    HOUR - metrics are broken down hourly.    WEEK - metrics are broken down weekly.    MONTH - metrics are broken down monthly
  --click-window-days: float@click-window-days-completer # Number of days to use as the conversion attribution window for a pin click action. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `30` days.
  --engagement-window-days: float@engagement-window-days-completer # Number of days to use as the conversion attribution window for an engagement action. Engagements include saves, closeups, link clicks, and carousel card swipes. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `30` days.  **Note:** This parameter no longer returns new data. However, you can still access historic data through **Sept 30, 2027**.
  --view-window-days: float@view-window-days-completer # Number of days to use as the conversion attribution window for a view action. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `1` day.
  --conversion-report-time: string@conversion-report-time-completer # The date by which the conversion metrics returned from this endpoint will be reported. There are two dates associated with a conversion event: the date that the user interacted with the ad, and the date that the user completed a conversion event. (e.g. TIME_OF_AD_ACTION)
  --attribution-types: list # List of types of attribution for the conversion report
  --reporting-timezone: string@reporting-timezone-completer # Specify the timezone to be applied for the reporting. This feature is currently in BETA and is not available to all users. (e.g. PINTEREST_TIME_ZONE)
  --sort-columns: list # Sort Columns.
  --sort-ascending: oneof<nothing, bool> # Sort ascending.
]: nothing -> record<data: table<metrics: record, targeting_type: string, targeting_value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_ids" $ad_ids "multi") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "targeting_types" $targeting_types "csv") (serialize-qp "columns" $columns "csv") (serialize-qp "granularity" $granularity "scalar") (serialize-qp "click_window_days" $click_window_days "scalar") (serialize-qp "engagement_window_days" $engagement_window_days "scalar") (serialize-qp "view_window_days" $view_window_days "scalar") (serialize-qp "conversion_report_time" $conversion_report_time "scalar") (serialize-qp "attribution_types" $attribution_types "csv") (serialize-qp "reporting_timezone" $reporting_timezone "scalar") (serialize-qp "sort_columns" $sort_columns "multi") (serialize-qp "sort_ascending" $sort_ascending "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ads/targeting_analytics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ad
#
# GET /ad_accounts/{ad_account_id}/ads/{ad_id}
# operationId: ads/get
export def "ad-accounts-ads ads/get" [
  ad_id: string
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ad_account_id: string, ad_group_id: string, android_deep_link: string, campaign_id: string, carousel_android_deep_links: list<string>, carousel_destination_urls: list<string>, carousel_ios_deep_links: list<string>, carting_platform_type: record, carting_products: table<carting_product_id: string, display_preferred_retailers_only: bool, display_product_price: bool, preferred_retailers: list, randomize_preferred_retailers: bool>, click_tracking_url: string, collection_items_destination_url_template: string, collections_header_type: record, created_time: int, creative_type: string, customizable_cta_type: string, destination_url: string, disclosure_type: string, disclosure_url: string, grid_click_type: string, id: string, ios_deep_link: string, is_carting: bool, is_collage_accepted_terms: bool, is_collage_single_destination: bool, is_pin_deleted: bool, is_removable: bool, lead_form_id: string, name: string, pin_id: string, quiz_pin_data: record, rejected_reasons: list<string>, rejection_labels: list<string>, review_status: record, status: string, summary_status: record, tracking_urls: record<audience_verification: list<string>, buyable_button: list<string>, click: list<string>, engagement: list<string>, impression: list<string>>, type: string, updated_time: int, view_tracking_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ads/($ad_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ads credit discounts
#
# GET /ad_accounts/{ad_account_id}/ads_credit/discounts
# operationId: ads_credits_discounts/get
export def "ad-accounts-ads-credit-discounts discounts/get" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<active: bool, advertiser_id: string, discountCurrency: string, discountInMicroCurrency: float, discountType: record, remainingDiscountInMicroCurrency: float, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ads_credit/discounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Redeem ad credits
#
# POST /ad_accounts/{ad_account_id}/ads_credit/redeem
# operationId: ads_credit/redeem
export def "ad-accounts-ads-credit-redeem credit/redeem" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  offerCodeHash: string # Takes in a SHA256 hash of the offerCode. (e.g. 138e9e0ff7e38cf511b880975eb574c09aa9d5e1657590ab0431040da68caa67)
  --validateOnly: oneof<nothing, bool> # If true, only validate if we can redeem offer code. Otherwise it will actually apply the offer code to the account (e.g. true)
]: any -> record<errorCode: int, errorMessage: string, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ads_credit/redeem")
  let body = {offerCodeHash: $offerCodeHash, validateOnly: $validateOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get advertiser defined events
#
# GET /ad_accounts/{ad_account_id}/advertiser_defined_events
# operationId: advertiser_defined_events/get
export def "ad-accounts-advertiser-defined-events events/get" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<mapped_conversion_type: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/advertiser_defined_events")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create advertiser defined events
#
# POST /ad_accounts/{ad_account_id}/advertiser_defined_events
# operationId: advertiser_defined_events/create
# --items item shape: {mapped_conversion_type: any, name: string}
export def "ad-accounts-advertiser-defined-events events/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  items: list # List of advertiser defined events to create or update — item shape: {mapped_conversion_type: any, name: string}
]: any -> record<items: table<exceptions: list, name: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/advertiser_defined_events")
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update advertiser defined events
#
# PATCH /ad_accounts/{ad_account_id}/advertiser_defined_events
# operationId: advertiser_defined_events/update
# --items item shape: {mapped_conversion_type: any, name: string}
export def "ad-accounts-advertiser-defined-events events/update" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  items: list # List of advertiser defined events to create or update — item shape: {mapped_conversion_type: any, name: string}
]: any -> record<items: table<exceptions: list, name: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/advertiser_defined_events")
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete advertiser defined events
#
# DELETE /ad_accounts/{ad_account_id}/advertiser_defined_events
# operationId: advertiser_defined_events/delete
export def "ad-accounts-advertiser-defined-events events/delete" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --event-names: list # List of event names to delete
]: nothing -> record<items: table<exceptions: list, name: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "event_names" $event_names "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/advertiser_defined_events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ad account analytics
#
# GET /ad_accounts/{ad_account_id}/analytics
# operationId: ad_account/analytics
export def "ad-accounts-analytics account/analytics" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # Metric report start date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days back from today. (format: date)
  --end-date: string # Metric report end date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days past start_date. (format: date)
  --columns: list # Columns to retrieve, encoded as a comma-separated string. **NOTE**: Any metrics defined as MICRO_DOLLARS returns a value based on the advertiser profile's currency field. For USD, ($1/1,000,000, or $0.000001 - one one-ten-thousandth of a cent). it's microdollars. Otherwise, it's in microunits of the advertiser's currency.  For example, if the advertiser's currency is GBP (British pound sterling), all MICRO_DOLLARS fields will be in GBP microunits (1/1,000,000 British pound).  If a column has no value, it may not be returned.
  --granularity: string@granularity-completer #   TOTAL - metrics are aggregated over the specified date range.    DAY - metrics are broken down daily.    HOUR - metrics are broken down hourly.    WEEK - metrics are broken down weekly.    MONTH - metrics are broken down monthly
  --click-window-days: float@click-window-days-completer # Number of days to use as the conversion attribution window for a pin click action. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `30` days. (default: 30)
  --engagement-window-days: float@engagement-window-days-completer # Number of days to use as the conversion attribution window for an engagement action. Engagements include saves, closeups, link clicks, and carousel card swipes. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `30` days. **Note:** This parameter no longer returns new data. However, you can still access historic data through **Sept 30, 2027**. (default: 30)
  --view-window-days: float@view-window-days-completer # Number of days to use as the conversion attribution window for a view action. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `1` day. (default: 1)
  --conversion-report-time: string@conversion-report-time-completer # The date by which the conversion metrics returned from this endpoint will be reported. There are two dates associated with a conversion event: the date that the user interacted with the ad, and the date that the user completed a conversion event. (default: TIME_OF_AD_ACTION)
  --reporting-timezone: string@reporting-timezone-completer # Specify the timezone to be applied for the reporting. This feature is currently in BETA and is not available to all users. (e.g. PINTEREST_TIME_ZONE)
]: nothing -> table<AD_ACCOUNT_ID: string, DATE: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "columns" $columns "csv") (serialize-qp "granularity" $granularity "scalar") (serialize-qp "click_window_days" $click_window_days "scalar") (serialize-qp "engagement_window_days" $engagement_window_days "scalar") (serialize-qp "view_window_days" $view_window_days "scalar") (serialize-qp "conversion_report_time" $conversion_report_time "scalar") (serialize-qp "reporting_timezone" $reporting_timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/analytics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get audience insights
#
# GET /ad_accounts/{ad_account_id}/audience_insights
# operationId: audience_insights/get
export def "ad-accounts-audience-insights insights/get" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --audience-insight-type: string@audience-insight-type-completer # Type of audience insights. (e.g. YOUR_TOTAL_AUDIENCE)
]: nothing -> record<categories: table<id: string, index: float, key: string, name: string, ratio: float, subcategories: list>, date: string, demographics: record<ages: list<record>, countries: list<record>, devices: list<record>, genders: list<record>, metros: list<record>>, size: int, size_is_upper_bound: bool, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "audience_insight_type" $audience_insight_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/audience_insights" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create audience
#
# POST /ad_accounts/{ad_account_id}/audiences
# operationId: audiences/create
# --rule shape: {ad_account_id?: string, ad_id?: list, campaign_id?: list, country?: string, customer_list_id?: string, engagement_domain?: list, engagement_type?: string, engager_type?: int, event?: string, event_data?: record, event_source?: record, ingestion_source?: record, objective_type?: list, percentage?: any, pin_id?: list, prefill?: bool, retention_days?: int, seed_id?: any, url?: list, visitor_source_id?: any}
export def "ad-accounts-audiences audiences/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-ad-account-id: string # Ad account ID.
  --audience-type: any # [Audience types](/docs/reference/glossary/#Audience Types): ACTALIKE, ENGAGEMENT, CUSTOMER_LIST and VISITOR
  --description: string # Audience description. (nullable)
  --name: string # Audience name.
  --rule: record # JSON object defining targeted audience users. Example rule formats per audience type: CUSTOMER_LIST: { "customer_list_id": "<customer list ID>"} ACTALIKE: { "seed_id": ["<audience ID>"], "country": "US", "percentage": "10" } (Valid countries include: "US", "CA", and "GB". Percentage should be 1-10. The targeted audience should be this % size across Pinterest.) VISITOR: { "visitor_source_id": ["<conversion tag ID>"], "retention_days": "180", "event_source": {"=": ["web", "mobile"]}, "ingestion_source": {"=": ["tag"]}} (Retention days should be 1-540. Retention applies to specific customers.) ENGAGEMENT: {"engagement_domain": ["www.example.com"], "engager_type": 1} Learn more about [engagement audiences](/docs/work-with-targets-and-audiences/create-audiences/#engagement-audience). — shape: {ad_account_id?: string, ad_id?: list, campaign_id?: list, country?: string, customer_list_id?: string, engagement_domain?: list, engagement_type?: string, engager_type?: int, event?: string, event_data?: record, event_source?: record, ingestion_source?: record, objective_type?: list, percentage?: any, pin_id?: list, prefill?: bool, retention_days?: int, seed_id?: any, url?: list, visitor_source_id?: any}
]: any -> record<ad_account_id: string, audience_type: record, created_by_company_name: string, created_timestamp: int, description: string, id: string, is_nca: bool, name: string, rule: record<ad_account_id: string, ad_id: list<string>, campaign_id: list<string>, country: string, customer_list_id: string, engagement_domain: list<string>, engagement_type: string, engager_type: int, event: string, event_data: record<currency: record, lead_type: string, line_items: record, order_id: string, order_quantity: int, page_name: string, promo_code: string, property: string, search_query: string, value: string, video_title: string>, event_source: record, ingestion_source: record, objective_type: list<string>, percentage: any, pin_id: list<string>, prefill: bool, retention_days: int, seed_id: any, url: list<string>, visitor_source_id: any>, size: int, status: record, type: string, updated_timestamp: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/audiences")
  let body = {ad_account_id: $body_ad_account_id, audience_type: $audience_type, description: $description, name: $name, rule: $rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List audiences
#
# GET /ad_accounts/{ad_account_id}/audiences
# operationId: audiences/list
export def "ad-accounts-audiences audiences/list" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
  --order: string@order-completer # The order in which to sort the items returned: "ASCENDING" or "DESCENDING" by ID. Note that higher-value IDs are associated with more-recently added items.
  --ownership-type: string@ownership-type-completer
  --exclude-nca: oneof<nothing, bool> # When true, excludes audiences derived from new customer acquisition (expanded matching) customer lists from the result. Defaults to false (include all). (default: false)
]: nothing -> record<bookmark: string, items: table<ad_account_id: string, audience_type: record, created_by_company_name: string, created_timestamp: int, description: string, id: string, is_nca: bool, name: string, rule: record, size: int, status: record, type: string, updated_timestamp: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "ownership_type" $ownership_type "scalar") (serialize-qp "exclude_nca" $exclude_nca "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/audiences" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update audience sharing between ad accounts
#
# PATCH /ad_accounts/{ad_account_id}/audiences/ad_accounts/shared
# operationId: update_ad_account_to_ad_account_shared_audience
export def "ad-accounts-audiences-ad-accounts-shared audience" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  audience_id: any # Unique identifier of an audience (e.g. 2542621871096)
  operation_type: string@operation-type-completer # Operation type to share a specific audience or revoke access to a previously shared audience
  recipient_account_ids: list # Ad account IDs to share with or revoke from (request) / that received the audience (response).
]: any -> record<audience_id: record, permissions: list<string>, recipient_account_ids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/audiences/ad_accounts/shared")
  let body = {audience_id: $audience_id, operation_type: $operation_type, recipient_account_ids: $recipient_account_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update audience sharing from an ad account to businesses
#
# PATCH /ad_accounts/{ad_account_id}/audiences/businesses/shared
# operationId: update_ad_account_to_business_shared_audience
export def "ad-accounts-audiences-businesses-shared audience" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  audience_id: any # Unique identifier of an audience (e.g. 2542621871096)
  operation_type: string@operation-type-completer # Operation type to share a specific audience or revoke access to a previously shared audience
  recipient_business_ids: list # Business IDs to share with or revoke from (request) / that received the audience (response).
]: any -> record<audience_id: record, permissions: list<string>, recipient_business_ids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/audiences/businesses/shared")
  let body = {audience_id: $audience_id, operation_type: $operation_type, recipient_business_ids: $recipient_business_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List accounts with access to an audience owned by an ad account
#
# GET /ad_accounts/{ad_account_id}/audiences/shared/accounts
# operationId: ad_accounts_audiences_shared_accounts/list
export def "ad-accounts-audiences-shared-accounts accounts/list" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --audience-id: string # Unique identifier of the audience to use to filter the results.
  --account-type: string@account-type-completer # Filter accounts by account type.
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<account_id: string, account_name: string, account_type: record, shared_on_timestamp: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "audience_id" $audience_id "scalar") (serialize-qp "account_type" $account_type "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/audiences/shared/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update audience
#
# PATCH /ad_accounts/{ad_account_id}/audiences/{audience_id}
# operationId: audiences/update
# --rule shape: {ad_account_id?: string, ad_id?: list, campaign_id?: list, country?: string, customer_list_id?: string, engagement_domain?: list, engagement_type?: string, engager_type?: int, event?: string, event_data?: record, event_source?: record, ingestion_source?: record, objective_type?: list, percentage?: any, pin_id?: list, prefill?: bool, retention_days?: int, seed_id?: any, url?: list, visitor_source_id?: any}
export def "ad-accounts-audiences audiences/update" [
  audience_id: string
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-ad-account-id: string # Ad account ID.
  --audience-type: any # [Audience types](/docs/reference/glossary/#Audience Types): ACTALIKE, ENGAGEMENT, CUSTOMER_LIST and VISITOR
  --description: string # Audience description. (nullable)
  --name: string # Audience name.
  --operation-type: any # Audience operation type (update or remove). Only valid in update request body.
  --rule: record # JSON object defining targeted audience users. Example rule formats per audience type: CUSTOMER_LIST: { "customer_list_id": "<customer list ID>"} ACTALIKE: { "seed_id": ["<audience ID>"], "country": "US", "percentage": "10" } (Valid countries include: "US", "CA", and "GB". Percentage should be 1-10. The targeted audience should be this % size across Pinterest.) VISITOR: { "visitor_source_id": ["<conversion tag ID>"], "retention_days": "180", "event_source": {"=": ["web", "mobile"]}, "ingestion_source": {"=": ["tag"]}} (Retention days should be 1-540. Retention applies to specific customers.) ENGAGEMENT: {"engagement_domain": ["www.example.com"], "engager_type": 1} Learn more about [engagement audiences](/docs/work-with-targets-and-audiences/create-audiences/#engagement-audience). — shape: {ad_account_id?: string, ad_id?: list, campaign_id?: list, country?: string, customer_list_id?: string, engagement_domain?: list, engagement_type?: string, engager_type?: int, event?: string, event_data?: record, event_source?: record, ingestion_source?: record, objective_type?: list, percentage?: any, pin_id?: list, prefill?: bool, retention_days?: int, seed_id?: any, url?: list, visitor_source_id?: any}
]: any -> record<ad_account_id: string, audience_type: record, created_by_company_name: string, created_timestamp: int, description: string, id: string, is_nca: bool, name: string, rule: record<ad_account_id: string, ad_id: list<string>, campaign_id: list<string>, country: string, customer_list_id: string, engagement_domain: list<string>, engagement_type: string, engager_type: int, event: string, event_data: record<currency: record, lead_type: string, line_items: record, order_id: string, order_quantity: int, page_name: string, promo_code: string, property: string, search_query: string, value: string, video_title: string>, event_source: record, ingestion_source: record, objective_type: list<string>, percentage: any, pin_id: list<string>, prefill: bool, retention_days: int, seed_id: any, url: list<string>, visitor_source_id: any>, size: int, status: record, type: string, updated_timestamp: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/audiences/($audience_id)")
  let body = {ad_account_id: $body_ad_account_id, audience_type: $audience_type, description: $description, name: $name, operation_type: $operation_type, rule: $rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get audience
#
# GET /ad_accounts/{ad_account_id}/audiences/{audience_id}
# operationId: audiences/get
export def "ad-accounts-audiences audiences/get" [
  audience_id: string
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ad_account_id: string, audience_type: record, created_by_company_name: string, created_timestamp: int, description: string, id: string, is_nca: bool, name: string, rule: record<ad_account_id: string, ad_id: list<string>, campaign_id: list<string>, country: string, customer_list_id: string, engagement_domain: list<string>, engagement_type: string, engager_type: int, event: string, event_data: record<currency: record, lead_type: string, line_items: record, order_id: string, order_quantity: int, page_name: string, promo_code: string, property: string, search_query: string, value: string, video_title: string>, event_source: record, ingestion_source: record, objective_type: list<string>, percentage: any, pin_id: list<string>, prefill: bool, retention_days: int, seed_id: any, url: list<string>, visitor_source_id: any>, size: int, status: record, type: string, updated_timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/audiences/($audience_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get bid floors
#
# POST /ad_accounts/{ad_account_id}/bid_floor
# operationId: ad_groups_bid_floor/get
# --bid_floor_specs item shape: {billable_event: any, countries?: list, creative_type?: any, currency: any, objective_type?: any, optimization_goal_metadata?: any}
export def "ad-accounts-bid-floor floor/get" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  bid_floor_specs: list # List of bid floor specifications. — item shape: {billable_event: any, countries?: list, creative_type?: any, currency: any, objective_type?: any, optimization_goal_metadata?: any}
  --targeting-spec: any # Ad group targeting specification defining the ad group target audience.
]: any -> record<bid_floors: list<int>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/bid_floor")
  let body = {bid_floor_specs: $bid_floor_specs, targeting_spec: $targeting_spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get download url for a billing invoice
#
# GET /ad_accounts/{ad_account_id}/billing_invoice/{billing_invoice_id}/download
# operationId: billing_invoice_download/get
export def "ad-accounts-billing-invoice-download download/get" [
  ad_account_id: string
  billing_invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<download_url: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/billing_invoice/($billing_invoice_id)/download")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get billing invoices
#
# GET /ad_accounts/{ad_account_id}/billing_invoices
# operationId: billing_invoices/get
export def "ad-accounts-billing-invoices invoices/get" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
  --order: string@order-completer # The order in which to sort the items returned: "ASCENDING" or "DESCENDING" by ID. Note that higher-value IDs are associated with more-recently added items.
  --qp-sort: string@sort-completer # Field of which to sort billing invoices (default: DUE_DATE)
  --status: string@status-completer # Status of billing invoices to filter by
  --document-type: string@document-type-completer # Document type of billing invoices to filter by
  --start-due-date: string # Starting point for due dates when searching for invoices. Format: YYYY-MM-DD (format: date)
  --end-due-date: string # Ending point for due dates when searching for invoices. Format: YYYY-MM-DD (format: date)
]: nothing -> record<bookmark: string, items: table<ad_account_id: string, ad_account_name: string, amount_billed_micro_currency: int, amount_discount_micro_currency: int, amount_net_micro_currency: int, amount_tax_micro_currency: int, bill_to_country: string, billing_period_end_date: string, billing_period_start_date: string, currency: string, document_type: record, id: string, invoice_due_date: string, payment_terms: string, status: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "document_type" $document_type "scalar") (serialize-qp "start_due_date" $start_due_date "scalar") (serialize-qp "end_due_date" $end_due_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/billing_invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get billing profiles
#
# GET /ad_accounts/{ad_account_id}/billing_profiles
# operationId: billing_profiles/get
export def "ad-accounts-billing-profiles profiles/get" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --is-active: oneof<nothing, bool> # Return active billing profiles, if false return all billing profiles.
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<advertiser_id: string, billing_type: record, card_type: record, id: string, payment_method_brand: record, status: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "is_active" $is_active "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/billing_profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get advertiser entities in bulk
#
# POST /ad_accounts/{ad_account_id}/bulk/download
# operationId: bulk_download/create
# --campaign_filter shape: {campaign_status?: list, end_time?: string, name?: string, objective_type?: list, start_time?: string}
export def "ad-accounts-bulk-download download/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaign-filter: record # shape: {campaign_status?: list, end_time?: string, name?: string, objective_type?: list, start_time?: string}
  --entity-ids: list # All entities specified by these IDs as well as their children and grandchildren will be downloaded if the entity type is one of the types requested to be downloaded.
  --entity-types: list # All entity types specified will be downloaded. Fewer types result in faster downloads. (e.g. [CAMPAIGN, AD_GROUP])
  --output-format: any # default: JSON
  --updated-since: string # Unix UTC timestamp to retrieve all entities that have changed since this time. (e.g. 1622848072)
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/bulk/download")
  let body = {campaign_filter: $campaign_filter, entity_ids: $entity_ids, entity_types: $entity_types, output_format: $output_format, updated_since: $updated_since} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create/update ad entities in bulk
#
# POST /ad_accounts/{ad_account_id}/bulk/upsert
# operationId: bulk_upsert/create
# --create shape: {ad_groups?: list, ads?: list, campaigns?: list, catalog_product_groups?: list, keywords?: list, labels?: list, product_groups?: list, schedules?: list}
# --update shape: {ad_groups?: list, ads?: list, campaigns?: list, catalog_product_groups?: list, keywords?: list, labels?: list, product_groups?: list, schedules?: list}
export def "ad-accounts-bulk-upsert upsert/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --create: record # Request for creation of entities in bulk. — shape: {ad_groups?: list, ads?: list, campaigns?: list, catalog_product_groups?: list, keywords?: list, labels?: list, product_groups?: list, schedules?: list}
  --update: record # Request for creation of entities in bulk. — shape: {ad_groups?: list, ads?: list, campaigns?: list, catalog_product_groups?: list, keywords?: list, labels?: list, product_groups?: list, schedules?: list}
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/bulk/upsert")
  let body = {create: $create, update: $update} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Download advertiser entities in bulk
#
# GET /ad_accounts/{ad_account_id}/bulk/{bulk_request_id}
# operationId: bulk_request/get
export def "ad-accounts-bulk request/get" [
  ad_account_id: string
  bulk_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-details: oneof<nothing, bool> # If set to True then attach the errors/details to all the requests (default: false)
]: nothing -> record<result_url: string, status: string, workload_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_details" $include_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/bulk/($bulk_request_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create ad preview records for one or more ad groups
#
# POST /ad_accounts/{ad_account_id}/campaign_ad_preview
# operationId: campaign_ad_preview/create
export def "ad-accounts-campaign-ad-preview preview/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<data: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/campaign_ad_preview")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch ad preview records for one or more ad groups
#
# GET /ad_accounts/{ad_account_id}/campaign_ad_preview
# operationId: campaign_ad_preview/read
export def "ad-accounts-campaign-ad-preview preview/read" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-group-ids: list # List of Ad group Ids to use to filter the results.
]: nothing -> table<ad_account_id: string, ad_group_id: string, client_id: int, expires_at: int, is_active: bool, pin_id: int, pin_promotion_id: int, promoted_product_group_id: int, url: string, user_id: int, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_group_ids" $ad_group_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/campaign_ad_preview" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete ad preview records for one or more ad groups
#
# DELETE /ad_accounts/{ad_account_id}/campaign_ad_preview
# operationId: campaign_ad_preview/delete
export def "ad-accounts-campaign-ad-preview preview/delete" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-group-ids: list # List of Ad group Ids to use to filter the results.
]: nothing -> table<status: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_group_ids" $ad_group_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/campaign_ad_preview" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List campaigns
#
# GET /ad_accounts/{ad_account_id}/campaigns
# operationId: campaigns/list
export def "ad-accounts-campaigns campaigns/list" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
  --order: string@order-completer # The order in which to sort the items returned: "ASCENDING" or "DESCENDING" by ID. Note that higher-value IDs are associated with more-recently added items.
  --campaign-ids: list # List of Campaign Ids to use to filter the results.
  --entity-statuses: list # Entity status (default: [ACTIVE, PAUSED])
]: nothing -> record<bookmark: string, items: table<ad_account_id: string, bid_options: record, created_time: int, daily_spend_cap: int, default_ad_group_budget_in_micro_currency: int, end_time: int, id: string, intended_promotion_type: string, is_automated_campaign: bool, is_campaign_budget_optimization: bool, is_carting: bool, is_flexible_daily_budgets: bool, is_ltv_optimized: bool, is_performance_plus: bool, is_top_of_search: bool, lifetime_spend_cap: int, name: string, objective_type: string, order_line_id: string, performance_plus_campaign_settings: record, start_time: int, status: string, summary_status: record, tracking_urls: record, type: string, updated_time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "campaign_ids" $campaign_ids "multi") (serialize-qp "entity_statuses" $entity_statuses "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/campaigns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create campaigns
#
# POST /ad_accounts/{ad_account_id}/campaigns
# operationId: campaigns/create
export def "ad-accounts-campaigns campaigns/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<items: table<data: record, exceptions: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/campaigns")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update campaigns
#
# PATCH /ad_accounts/{ad_account_id}/campaigns
# operationId: campaigns/update
export def "ad-accounts-campaigns campaigns/update" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<items: table<data: record, exceptions: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/campaigns")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get campaign analytics
#
# GET /ad_accounts/{ad_account_id}/campaigns/analytics
# operationId: campaigns/analytics
export def "ad-accounts-campaigns-analytics campaigns/analytics" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # Metric report start date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days back from today. (format: date)
  --end-date: string # Metric report end date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days past start_date. (format: date)
  --campaign-ids: list # List of Campaign Ids to use to filter the results.
  --columns: list # Columns to retrieve, encoded as a comma-separated string. **NOTE**: Any metrics defined as MICRO_DOLLARS returns a value based on the advertiser profile's currency field. For USD, ($1/1,000,000, or $0.000001 - one one-ten-thousandth of a cent). it's microdollars. Otherwise, it's in microunits of the advertiser's currency.  For example, if the advertiser's currency is GBP (British pound sterling), all MICRO_DOLLARS fields will be in GBP microunits (1/1,000,000 British pound).  If a column has no value, it may not be returned.
  --granularity: string@granularity-completer #   TOTAL - metrics are aggregated over the specified date range.    DAY - metrics are broken down daily.    HOUR - metrics are broken down hourly.    WEEK - metrics are broken down weekly.    MONTH - metrics are broken down monthly
  --click-window-days: float@click-window-days-completer # Number of days to use as the conversion attribution window for a pin click action. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `30` days. (default: 30)
  --engagement-window-days: float@engagement-window-days-completer # Number of days to use as the conversion attribution window for an engagement action. Engagements include saves, closeups, link clicks, and carousel card swipes. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `30` days. **Note:** This parameter no longer returns new data. However, you can still access historic data through **Sept 30, 2027**. (default: 30)
  --view-window-days: float@view-window-days-completer # Number of days to use as the conversion attribution window for a view action. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `1` day. (default: 1)
  --conversion-report-time: string@conversion-report-time-completer # The date by which the conversion metrics returned from this endpoint will be reported. There are two dates associated with a conversion event: the date that the user interacted with the ad, and the date that the user completed a conversion event. (default: TIME_OF_AD_ACTION)
  --aggregate-report-rows: oneof<nothing, bool> # Determines if report rows should be aggregated across all requested entities. This feature is currently in BETA and is not available to all users. (default: false)
  --reporting-timezone: string@reporting-timezone-completer # Specify the timezone to be applied for the reporting. This feature is currently in BETA and is not available to all users. (e.g. PINTEREST_TIME_ZONE)
]: nothing -> table<CAMPAIGN_ID: string, DATE: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "campaign_ids" $campaign_ids "multi") (serialize-qp "columns" $columns "csv") (serialize-qp "granularity" $granularity "scalar") (serialize-qp "click_window_days" $click_window_days "scalar") (serialize-qp "engagement_window_days" $engagement_window_days "scalar") (serialize-qp "view_window_days" $view_window_days "scalar") (serialize-qp "conversion_report_time" $conversion_report_time "scalar") (serialize-qp "aggregate_report_rows" $aggregate_report_rows "scalar") (serialize-qp "reporting_timezone" $reporting_timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/campaigns/analytics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get campaign delivery estimates
#
# POST /ad_accounts/{ad_account_id}/campaigns/delivery_estimates
# operationId: get_campaign_delivery_estimates
export def "ad-accounts-campaigns-delivery-estimates estimates" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<curves: table<estimation_type: record, points: list>, derived_metrics: record<cpc: float, cpc_lower: float, cpc_upper: float, cpm: float, cpm_lower: float, cpm_upper: float, lifetime_frequency: float, lifetime_frequency_lower: float, lifetime_frequency_upper: float, lifetime_impression: float, lifetime_impression_lower: float, lifetime_impression_upper: float, lifetime_reach: float, lifetime_reach_lower: float, lifetime_reach_upper: float, weekly_click: float, weekly_click_lower: float, weekly_click_upper: float, weekly_frequency: float, weekly_frequency_lower: float, weekly_frequency_upper: float, weekly_impression: float, weekly_impression_lower: float, weekly_impression_upper: float, weekly_reach: float, weekly_reach_lower: float, weekly_reach_upper: float>, max_potential_spend: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/campaigns/delivery_estimates")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get targeting analytics for campaigns
#
# GET /ad_accounts/{ad_account_id}/campaigns/targeting_analytics
# operationId: campaign_targeting_analytics/get
export def "ad-accounts-campaigns-targeting-analytics analytics/get" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaign-ids: list # List of Campaign Ids to use to filter the results.
  --start-date: string # Metric report start date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days back from today. (format: date)
  --end-date: string # Metric report end date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days past start_date. (format: date)
  --targeting-types: list # Targeting type breakdowns for the report. The reporting per targeting type is independent from each other. ["AGE_BUCKET_AND_GENDER"] is in BETA and not yet available to all users.
  --columns: list # Columns to retrieve, encoded as a comma-separated string. **NOTE**: Any metrics defined as MICRO_DOLLARS returns a value based on the advertiser profile's currency field. For USD, ($1/1,000,000, or $0.000001 - one one-ten-thousandth of a cent). it's microdollars. Otherwise, it's in microunits of the advertiser's currency.  For example, if the advertiser's currency is GBP (British pound sterling), all MICRO_DOLLARS fields will be in GBP microunits (1/1,000,000 British pound).  If a column has no value, it may not be returned.
  --granularity: string@granularity-completer #   TOTAL - metrics are aggregated over the specified date range.    DAY - metrics are broken down daily.    HOUR - metrics are broken down hourly.    WEEK - metrics are broken down weekly.    MONTH - metrics are broken down monthly
  --click-window-days: float@click-window-days-completer # Number of days to use as the conversion attribution window for a pin click action. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `30` days. (default: 30)
  --engagement-window-days: float@engagement-window-days-completer # Number of days to use as the conversion attribution window for an engagement action. Engagements include saves, closeups, link clicks, and carousel card swipes. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `30` days. **Note:** This parameter no longer returns new data. However, you can still access historic data through **Sept 30, 2027**. (default: 30)
  --view-window-days: float@view-window-days-completer # Number of days to use as the conversion attribution window for a view action. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `1` day. (default: 1)
  --conversion-report-time: string@conversion-report-time-completer # The date by which the conversion metrics returned from this endpoint will be reported. There are two dates associated with a conversion event: the date that the user interacted with the ad, and the date that the user completed a conversion event. (default: TIME_OF_AD_ACTION)
  --attribution-types: list # List of types of attribution for the conversion report
  --reporting-timezone: string@reporting-timezone-completer # Specify the timezone to be applied for the reporting. This feature is currently in BETA and is not available to all users. (e.g. PINTEREST_TIME_ZONE)
]: nothing -> record<data: table<metrics: record, targeting_type: string, targeting_value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "campaign_ids" $campaign_ids "multi") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "targeting_types" $targeting_types "csv") (serialize-qp "columns" $columns "csv") (serialize-qp "granularity" $granularity "scalar") (serialize-qp "click_window_days" $click_window_days "scalar") (serialize-qp "engagement_window_days" $engagement_window_days "scalar") (serialize-qp "view_window_days" $view_window_days "scalar") (serialize-qp "conversion_report_time" $conversion_report_time "scalar") (serialize-qp "attribution_types" $attribution_types "csv") (serialize-qp "reporting_timezone" $reporting_timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/campaigns/targeting_analytics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get campaign
#
# GET /ad_accounts/{ad_account_id}/campaigns/{campaign_id}
# operationId: campaigns/get
export def "ad-accounts-campaigns campaigns/get" [
  campaign_id: string
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ad_account_id: string, bid_options: record<age_bucket_multipliers: record<AGE_BUCKET: record>, app_type_multipliers: record<APP_TYPE: record>, audience_multipliers: record<AUDIENCE_ID: string>, freq_bid_multiplier_time_window: record, frequency_multipliers: record, gender_multipliers: record<GENDER: record>, placement_multipliers: record<PLACEMENT: record>>, created_time: int, daily_spend_cap: int, default_ad_group_budget_in_micro_currency: int, end_time: int, id: string, intended_promotion_type: string, is_automated_campaign: bool, is_campaign_budget_optimization: bool, is_carting: bool, is_flexible_daily_budgets: bool, is_ltv_optimized: bool, is_performance_plus: bool, is_top_of_search: bool, lifetime_spend_cap: int, name: string, objective_type: string, order_line_id: string, performance_plus_campaign_settings: record, start_time: int, status: string, summary_status: record, tracking_urls: record, type: string, updated_time: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/campaigns/($campaign_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List conversion deletion requests
#
# GET /ad_accounts/{ad_account_id}/conversion_deletion_requests
# operationId: conversion_deletion_request/list
export def "ad-accounts-conversion-deletion-requests request/list" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
  --order: string@order-completer # The order in which to sort the items returned: "ASCENDING" or "DESCENDING" by ID. Note that higher-value IDs are associated with more-recently added items.
]: nothing -> record<bookmark: string, items: table<created_time: string, processed_time: string, request_id: string, status: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/conversion_deletion_requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a conversion deletion request
#
# POST /ad_accounts/{ad_account_id}/conversion_deletion_requests
# operationId: conversion_deletion_request/create
export def "ad-accounts-conversion-deletion-requests request/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  deletion_targets: any # Object containing the targets of the conversion deletion request. Users can be identified with user_emails, epiks, or both within the same request.
]: any -> record<created_time: string, processed_time: string, request_id: string, status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/conversion_deletion_requests")
  let body = {deletion_targets: $deletion_targets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single conversion deletion request
#
# GET /ad_accounts/{ad_account_id}/conversion_deletion_requests/{request_id}
# operationId: conversion_deletion_request/get
export def "ad-accounts-conversion-deletion-requests request/get" [
  request_id: string
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_time: string, processed_time: string, request_id: string, status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/conversion_deletion_requests/($request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a conversion deletion request
#
# DELETE /ad_accounts/{ad_account_id}/conversion_deletion_requests/{request_id}
# operationId: conversion_deletion_request/delete
export def "ad-accounts-conversion-deletion-requests request/delete" [
  request_id: string
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_time: string, processed_time: string, request_id: string, status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/conversion_deletion_requests/($request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get event quality score (EQS)
#
# GET /ad_accounts/{ad_account_id}/conversion_eqs
# operationId: conversion_eqs/list
export def "ad-accounts-conversion-eqs eqs/list" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lookback-period: string@lookback-period-completer # Lookback window (number of days).
  --source-platform: string@source-platform-completer # Source platform of event.
  --ingestion-source: string@ingestion-source-completer # Ingestion source of event.
]: nothing -> table<ingestion_source: string, lookback_period: string, overall_status: string, quality_components: record<advertiser_external_id: record, click_id_epik: record, external_event_id: record, hashed_email: record, hashed_maid: record, ip_address: record, order_id: record, order_value: record, product_id: record, source_url: record, user_agent: record>, source_platform: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lookback_period" $lookback_period "scalar") (serialize-qp "source_platform" $source_platform "scalar") (serialize-qp "ingestion_source" $ingestion_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/conversion_eqs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create conversion tag
#
# POST /ad_accounts/{ad_account_id}/conversion_tags
# operationId: conversion_tags/create
export def "ad-accounts-conversion-tags tags/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --aem-db-enabled: oneof<nothing, bool> # Whether Automatic Enhanced Match birthdate is enabled. See [Enhanced match](https://help.pinterest.com/en/business/article/enhanced-match) for more information. (nullable, default: false)
  --aem-enabled: oneof<nothing, bool> # Whether Automatic Enhanced Match email is enabled. See [Enhanced match](https://help.pinterest.com/en/business/article/enhanced-match) for more information. (nullable, default: false)
  --aem-external-id-enabled: oneof<nothing, bool> # Whether Automatic Enhanced Match location is enabled. See [Enhanced match](https://help.pinterest.com/en/business/article/enhanced-match) for more information. (nullable, default: false)
  --aem-fnln-enabled: oneof<nothing, bool> # Whether Automatic Enhanced Match name is enabled. See [Enhanced match](https://help.pinterest.com/en/business/article/enhanced-match) for more information. (nullable, default: false)
  --aem-ge-enabled: oneof<nothing, bool> # Whether Automatic Enhanced Match gender is enabled. See [Enhanced match](https://help.pinterest.com/en/business/article/enhanced-match) for more information. (nullable, default: false)
  --aem-loc-enabled: oneof<nothing, bool> # Whether Automatic Enhanced Match location is enabled. See [Enhanced match](https://help.pinterest.com/en/business/article/enhanced-match) for more information. (nullable, default: false)
  --aem-ph-enabled: oneof<nothing, bool> # Whether Automatic Enhanced Match phone is enabled. See [Enhanced match](https://help.pinterest.com/en/business/article/enhanced-match) for more information. (nullable, default: false)
  --md-frequency: float # Metadata ingestion frequency. (nullable, default: 1, e.g. 0.6)
  name: string # Conversion tag name. (e.g. download_picture)
]: any -> record<ad_account_id: string, status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/conversion_tags")
  let body = {aem_db_enabled: $aem_db_enabled, aem_enabled: $aem_enabled, aem_external_id_enabled: $aem_external_id_enabled, aem_fnln_enabled: $aem_fnln_enabled, aem_ge_enabled: $aem_ge_enabled, aem_loc_enabled: $aem_loc_enabled, aem_ph_enabled: $aem_ph_enabled, md_frequency: $md_frequency, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List conversion tags
#
# GET /ad_accounts/{ad_account_id}/conversion_tags
# operationId: conversion_tags/list
export def "ad-accounts-conversion-tags tags/list" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter-deleted: oneof<nothing, bool> # Filter by deleted status (default: false)
]: nothing -> record<items: table<ad_account_id: string, status: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter_deleted" $filter_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/conversion_tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Ocpm eligible conversion tags
#
# GET /ad_accounts/{ad_account_id}/conversion_tags/ocpm_eligible
# operationId: ocpm_eligible_conversion_tags/get
export def "ad-accounts-conversion-tags-ocpm-eligible tags/get" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/conversion_tags/ocpm_eligible")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get page visit conversion tags
#
# GET /ad_accounts/{ad_account_id}/conversion_tags/page_visit
# operationId: page_visit_conversion_tags/get
export def "ad-accounts-conversion-tags-page-visit tags/get" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
  --order: string@order-completer # The order in which to sort the items returned: "ASCENDING" or "DESCENDING" by ID. Note that higher-value IDs are associated with more-recently added items.
]: nothing -> record<bookmark: string, items: table<ad_account_id: string, conversion_event: string, conversion_tag_id: string, created_time: int, reporting_conversion_event: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/conversion_tags/page_visit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get conversion tag
#
# GET /ad_accounts/{ad_account_id}/conversion_tags/{conversion_tag_id}
# operationId: conversion_tags/get
export def "ad-accounts-conversion-tags tags/get" [
  ad_account_id: string
  conversion_tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ad_account_id: string, status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/conversion_tags/($conversion_tag_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get customer lists
#
# GET /ad_accounts/{ad_account_id}/customer_lists
# operationId: customer_lists/list
export def "ad-accounts-customer-lists lists/list" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
  --order: string@order-completer # The order in which to sort the items returned: "ASCENDING" or "DESCENDING" by ID. Note that higher-value IDs are associated with more-recently added items.
  --exclude-nca: oneof<nothing, bool> # When true, excludes customer lists uploaded for new customer acquisition (expanded matching) from the result. Defaults to false (include all). (default: false)
]: nothing -> record<bookmark: string, items: table<ad_account_id: string, created_time: float, exceptions: record, id: string, is_nca: bool, name: string, num_batches: float, num_removed_user_records: float, num_uploaded_user_records: float, status: record, type: string, updated_time: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "exclude_nca" $exclude_nca "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/customer_lists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create customer lists
#
# POST /ad_accounts/{ad_account_id}/customer_lists
# operationId: customer_lists/create
# --records_v2 item shape: {email?: string, external_id?: string, hashed_phone_number?: string, hashed_pinner_id?: string, ip_address?: string, liveramp_envelope?: string, maid?: string, user_agent?: string}
export def "ad-accounts-customer-lists lists/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --is-nca: oneof<nothing, bool> # Whether the list was uploaded for new customer acquisition (expanded matching). Immutable after creation.
  --list-type: any # Type of customer list (e.g., EMAIL, IDFA, MAID). (default: EMAIL)
  name: string # Customer list name. (e.g. The Glengarry Glen Ross leads)
  --records: string # Records list. Can be any combination of emails, MAIDs, or IDFAs. Emails must be lowercase and can be plain text or hashed using SHA1, SHA256, or MD5. MAIDs and IDFAs must be hashed with SHA1, SHA256, or MD5. (e.g. email1@pinterest.com,email2@pinterest.com,..<more records>)
  --records-v2: list # Multi-field record format. Array of objects with optional email, maid, ip_address, user_agent, external_id, hashed_pinner_id, hashed_phone_number, and liveramp_envelope per row. Provide exactly one of records or records_v2. — item shape: {email?: string, external_id?: string, hashed_phone_number?: string, hashed_pinner_id?: string, ip_address?: string, liveramp_envelope?: string, maid?: string, user_agent?: string}
]: any -> record<ad_account_id: string, created_time: float, exceptions: record, id: string, is_nca: bool, name: string, num_batches: float, num_removed_user_records: float, num_uploaded_user_records: float, status: record, type: string, updated_time: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/customer_lists")
  let body = {is_nca: $is_nca, list_type: $list_type, name: $name, records: $records, records_v2: $records_v2} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get customer list
#
# GET /ad_accounts/{ad_account_id}/customer_lists/{customer_list_id}
# operationId: customer_lists/get
export def "ad-accounts-customer-lists lists/get" [
  ad_account_id: string
  customer_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ad_account_id: string, created_time: float, exceptions: record, id: string, is_nca: bool, name: string, num_batches: float, num_removed_user_records: float, num_uploaded_user_records: float, status: record, type: string, updated_time: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/customer_lists/($customer_list_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update customer list
#
# PATCH /ad_accounts/{ad_account_id}/customer_lists/{customer_list_id}
# operationId: customer_lists/update
# --records_v2 item shape: {email?: string, external_id?: string, hashed_phone_number?: string, hashed_pinner_id?: string, ip_address?: string, liveramp_envelope?: string, maid?: string, user_agent?: string}
export def "ad-accounts-customer-lists lists/update" [
  ad_account_id: string
  customer_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  operation_type: any # Customer list update operation type (add or remove). Only valid in update request body.
  --records: string # Records list. Can be any combination of emails, MAIDs, or IDFAs. Emails must be lowercase and can be plain text or hashed using SHA1, SHA256, or MD5. MAIDs and IDFAs must be hashed with SHA1, SHA256, or MD5. (e.g. email1@pinterest.com,email2@pinterest.com,..<more records>)
  --records-v2: list # Multi-field record format. Array of objects with optional email, maid, ip_address, user_agent, external_id, hashed_pinner_id, hashed_phone_number, and liveramp_envelope per row. Provide exactly one of records or records_v2. — item shape: {email?: string, external_id?: string, hashed_phone_number?: string, hashed_pinner_id?: string, ip_address?: string, liveramp_envelope?: string, maid?: string, user_agent?: string}
]: any -> record<ad_account_id: string, created_time: float, exceptions: record, id: string, is_nca: bool, name: string, num_batches: float, num_removed_user_records: float, num_uploaded_user_records: float, status: record, type: string, updated_time: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/customer_lists/($customer_list_id)")
  let body = {operation_type: $operation_type, records: $records, records_v2: $records_v2} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create customer list upload
#
# POST /ad_accounts/{ad_account_id}/customer_lists/{customer_list_id}/uploads
# operationId: customer_list_uploads/create
export def "ad-accounts-customer-lists-uploads uploads/create" [
  ad_account_id: string
  customer_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  operation: string@operation-completer # User list operation type (add or remove) (e.g. REMOVE)
  total_parts: int # Number of parts to upload the file in. (e.g. 2)
]: any -> record<customer_list_upload: record<ad_account_id: record, creation_time: int, customer_list_id: record, error_counts: list<record>, id: record, operation: string, record_counts: record<invalid: int, processed: int, valid: int>, state: record, updated_time: int>, s3_multipart_upload_data: record<file_parts: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/customer_lists/($customer_list_id)/uploads")
  let body = {operation: $operation, total_parts: $total_parts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get customer list upload
#
# GET /ad_accounts/{ad_account_id}/customer_lists/{customer_list_id}/uploads/{customer_list_upload_id}
# operationId: customer_list_uploads/get
export def "ad-accounts-customer-lists-uploads uploads/get" [
  ad_account_id: string
  customer_list_id: string
  customer_list_upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ad_account_id: record, creation_time: int, customer_list_id: record, error_counts: table<count: int, error_code: int, message: string>, id: record, operation: string, record_counts: record<invalid: int, processed: int, valid: int>, state: record, updated_time: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/customer_lists/($customer_list_id)/uploads/($customer_list_upload_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Run customer list upload
#
# POST /ad_accounts/{ad_account_id}/customer_lists/{customer_list_id}/uploads/{customer_list_upload_id}/run
# operationId: customer_list_uploads/run
export def "ad-accounts-customer-lists-uploads-run uploads/run" [
  ad_account_id: string
  customer_list_id: string
  customer_list_upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ad_account_id: record, creation_time: int, customer_list_id: record, error_counts: table<count: int, error_code: int, message: string>, id: record, operation: string, record_counts: record<invalid: int, processed: int, valid: int>, state: record, updated_time: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/customer_lists/($customer_list_id)/uploads/($customer_list_upload_id)/run")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List customer segments
#
# GET /ad_accounts/{ad_account_id}/customer_segments
# operationId: customer_segment/list
export def "ad-accounts-customer-segments segment/list" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
  --order: string@order-completer # The order in which to sort the items returned: "ASCENDING" or "DESCENDING" by ID. Note that higher-value IDs are associated with more-recently added items.
  --include-sizing: oneof<nothing, bool> # Include audience sizing in result or not (default: false)
  --search-query: string # Search query. Can contain pin description keywords or comma-separated pin IDs.
]: nothing -> record<bookmark: string, items: table<ad_account_id: string, audience_ids: list, created_time: int, id: string, name: string, status: record, updated_time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "include_sizing" $include_sizing "scalar") (serialize-qp "search_query" $search_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/customer_segments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create customer segments
#
# POST /ad_accounts/{ad_account_id}/customer_segments
# operationId: customer_segment/create
export def "ad-accounts-customer-segments segment/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  audience_ids: list # Audience IDs included in the customer segment.
  name: string # Customer segment name.
]: any -> record<ad_account_id: string, audience_ids: list<string>, created_time: int, id: string, name: string, status: record, updated_time: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/customer_segments")
  let body = {audience_ids: $audience_ids, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update customer segments
#
# PATCH /ad_accounts/{ad_account_id}/customer_segments
# operationId: customer_segment/update
export def "ad-accounts-customer-segments segment/update" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --audience-ids: list # Audience IDs to update the customer segment to. Only applicable for UPDATE operations.
  id: string # Customer segment ID.
  operation_type: string@operation-type-completer-1 # Audience operation type (update or remove). (e.g. UPDATE)
]: any -> record<code: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/customer_segments")
  let body = {audience_ids: $audience_ids, id: $id, operation_type: $operation_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send conversions
#
# POST /ad_accounts/{ad_account_id}/events
# operationId: events/create
# --data item shape: {action_source: string, app_id?: string, app_info?: record, app_name?: string, app_version?: string, custom_data?: record, device_brand?: string, device_carrier?: string, device_info?: record, device_model?: string, device_type?: string, event_id: string, event_name: string, event_source_url?: string, event_time: int, language?: string, opt_out?: bool, os_version?: string, partner_name?: string, user_data: any, wifi?: bool}
export def "ad-accounts-events events/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --test: oneof<nothing, bool> # Include query param ?test=true to mark the request as a test request. The events will not be recorded but the API will still return the same response messages. Use this mode to verify your requests are working and your events are constructed correctly. Warning: If you use this query parameter, be certain that it is off (set to false or deleted) before sending a legitimate (non-testing) request.
  data: list # A list of events (one or more) encapsulated by a data object. (e.g. [{event_name: checkout, action_source: app_ios, event_time: 1769818893, event_id: eventId0001, event_source_url: https://www.my-clothing-shop.org/, opt_out: false, advertiser_tracking_enabled: true, partner_name: ss-partnername, user_data: {em: [411e44ce1261728ffd2c0686e44e3fffe413c0e2c5adc498bc7da883d476b9c8, 09831ea51bd1b7b32a836683a00a9ccaf3d05f59499f42d9883412ed79289969], hashed_maids: [0192518eb84137ccfe82c8b6322d29631dae7e28ed9d0f6dd5f245d73a58c5f1, 837b850ac46d62b2272a71de73c27801ff011ac1e36c5432620c8755cf90db46], client_ip_address: 216.3.128.12, client_user_agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.87 Safari/537.36, ph: [45df139772a81b6011bdc1c9cc3d1cb408fc0b10ec0c5cb9d4d4e107f0ddc49d], ge: [0d248e82c62c9386878327d491c762a002152d42ab2c391a31c44d9f62675ddf], db: [d4426a0086d10f12ad265539ae8d54221dc67786053d511407204b76e99d7739], ln: [7e546b3aa43f989dd359672e6c3409d4f9d4e8f155ae1e9b90ee060985468c19], fn: [ec1e6a072231703f1bc41429052fff8c00a7e0c6aaec2e7107241ca8f3ceb6b2], ct: [4ac01a129bfd10385c9278c2cf2c46fac5ab57350841234f587c8522a2e4ce36], st: [49a6d05b8e4b516656e464271d9dd38d0a7e0142f7f49546f4dabd2720cafc34], zp: [fd5f56b40a79a385708428e7b32ab996a681080a166a2206e750eb4819186145], country: [9b202ecbc6d45c6d8901d989a918878397a3eb9d00e8f48022fc051b19d21a1d], external_id: [6a7a73766627eb611720883d5a11cc62b5bfee237b00a6658d78c50032ec4aee], click_id: dj0yJnU9b2JDcFFHekV4SHJNcmVrbFBkUEdqakh0akdUT1VjVVUmcD0yJm49cnNBQ3F2Q2dOVDBXWWhkWklrUGxBUSZ0PUFBQUFBR1BaY3Bv, partner_id: BUJrTlRRzGJmWhRXFZdkioV6wKPBve7Lom__GU9J74hq2NIQj4O3nOZJrp3mcUr5MptkXsI14juMOIM9mNZnM4zEUFT2JLVaFhcOfuuWz3IWEDtBf6I0DPc}, custom_data: {currency: USD, value: 66.95, content_ids: [product-id-001, product-id-002], content_name: pinterest-themed-clothing, content_category: shirts, content_brand: pinterest-brand, contents: [{id: product-id-001, item_price: 14.99, quantity: 3, item_name: pinterest-shirt-girl, item_category: pinterest-clothing-shirts, item_brand: pinterest}, {id: product-id-002, item_price: 10.99, quantity: 2, item_name: pinterest-shirt-men, item_category: pinterest-clothing-shirts, item_brand: pinterest}], num_items: 5, order_id: my_order_id, search_string: sample string, opt_out_type: LDP, predicted_ltv: 2794.82}, app_id: 429047995, app_name: Pinterest, app_version: 7.9, device_brand: Apple, device_carrier: T-Mobile, device_model: iPhone X, device_type: iPhone, os_version: 12.1.4, wifi: false, language: en, device_info: {brand: Apple, Samsung, Motorola, type: iPhone, Android, model: 16 Pro, Galaxy S25 Ultra, form_factor: cellphone, os_family: ios, os_name: 10, os_version: 18.3, os_release_name: 18.3, kernel_version: 6.15, carrier: T-Mobile, screen_width: 1320, screen_height: 2868, screen_density: 460, cpu_cores: 8, storage_size: 256, storage_free_space: 184, external_storage_size: 512, external_storage_free_space: 126, locale: en-us, languages: [en, de, lt], timezone: USA/New York, timezone_abbr: PDT, network_type: wifi, battery_level: 78}, app_info: {app_name: MyAwesomeApp, app_package_name: com.company.myawesomeapp, app_id: 429047995, app_version: 7.9, app_store: Google Play Store, window_width: 1678, window_height: 900, install_time: 1739222269, user_agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36}}]) — item shape: {action_source: string, app_id?: string, app_info?: record, app_name?: string, app_version?: string, custom_data?: record, device_brand?: string, device_carrier?: string, device_info?: record, device_model?: string, device_type?: string, event_id: string, event_name: string, event_source_url?: string, event_time: int, language?: string, opt_out?: bool, os_version?: string, partner_name?: string, user_data: any, wifi?: bool}
]: any -> record<events: table<error_message: string, status: record, warning_message: string>, num_events_processed: int, num_events_received: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "test" $test "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/events" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get audience insights scope and type
#
# GET /ad_accounts/{ad_account_id}/insights/audiences
# operationId: audience_insights_scope_and_type/get
export def "ad-accounts-insights-audiences type/get" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<date: string, scope: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/insights/audiences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get keywords
#
# GET /ad_accounts/{ad_account_id}/keywords
# operationId: keywords/get
export def "ad-accounts-keywords keywords/get" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaign-id: string # Campaign Id to use to filter the results.
  --ad-group-id: string # Ad group Id.
  --ad-group-ids: list # List of Ad group Ids to retrieve keywords from. This feature is currently in BETA and is not available to all users.
  --match-types: list # Keyword [match type](/docs/api-features/targeting-overview/)
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<archived: bool, bid: int, id: string, match_type: record, parent_id: string, parent_type: string, type: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "campaign_id" $campaign_id "scalar") (serialize-qp "ad_group_id" $ad_group_id "scalar") (serialize-qp "ad_group_ids" $ad_group_ids "multi") (serialize-qp "match_types" $match_types "multi") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/keywords" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create keywords
#
# POST /ad_accounts/{ad_account_id}/keywords
# operationId: keywords/create
# --keywords item shape: {bid?: int, match_type: any, value: string}
export def "ad-accounts-keywords keywords/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keywords: list # Keywords — item shape: {bid?: int, match_type: any, value: string}
  parent_id: string # Keyword data
]: any -> record<errors: table<data: record, error_messages: list>, keywords: table<archived: bool, bid: int, id: string, match_type: record, parent_id: string, parent_type: string, type: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/keywords")
  let body = {keywords: $keywords, parent_id: $parent_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update keywords
#
# PATCH /ad_accounts/{ad_account_id}/keywords
# operationId: keywords/update
# --keywords item shape: {archived?: bool, bid?: int, id: string}
export def "ad-accounts-keywords keywords/update" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --keywords: list # Keywords — item shape: {archived?: bool, bid?: int, id: string}
]: any -> record<errors: table<data: record, error_messages: list>, keywords: table<archived: bool, bid: int, id: string, match_type: record, parent_id: string, parent_type: string, type: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/keywords")
  let body = {keywords: $keywords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get country's keyword metrics
#
# GET /ad_accounts/{ad_account_id}/keywords/metrics
# operationId: country_keywords_metrics/get
export def "ad-accounts-keywords-metrics metrics/get" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --country-code: string # Two letter country code (ISO 3166-1 alpha-2)
  --keywords: list # Comma-separated keywords
]: nothing -> record<data: table<keyword: string, metrics: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country_code" $country_code "scalar") (serialize-qp "keywords" $keywords "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/keywords/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List labels
#
# GET /ad_accounts/{ad_account_id}/labels
# operationId: labels/list
export def "ad-accounts-labels labels/list" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaign-ids: list # List of Campaign Ids to use to filter the results.
  --label-ids: list # List of Label Ids to use to filter the results.
  --entity-statuses: list # Label entity status (default: [ACTIVE])
  --label-types: list # Label type. (default: [BRAND, CUSTOM])
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<id: record, label_type: string, status: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "campaign_ids" $campaign_ids "multi") (serialize-qp "label_ids" $label_ids "multi") (serialize-qp "entity_statuses" $entity_statuses "multi") (serialize-qp "label_types" $label_types "multi") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/labels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create labels
#
# POST /ad_accounts/{ad_account_id}/labels
# operationId: labels/create
# --labels item shape: {label_type: "BRAND"|"CUSTOM", value: string}
export def "ad-accounts-labels labels/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  labels: list # Labels that you are applying to the campaign. — item shape: {label_type: "BRAND"|"CUSTOM", value: string}
]: any -> record<errors: table<data: record, error_messages: list>, labels: table<id: record, label_type: string, status: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/labels")
  let body = {labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update labels
#
# PATCH /ad_accounts/{ad_account_id}/labels
# operationId: labels/update
# --labels item shape: {id: any, status?: "ACTIVE"|"ARCHIVED", value?: string}
export def "ad-accounts-labels labels/update" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  labels: list # Labels that you are applying to the campaign. — item shape: {id: any, status?: "ACTIVE"|"ARCHIVED", value?: string}
]: any -> record<errors: table<data: record, error_messages: list>, labels: table<id: record, label_type: string, status: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/labels")
  let body = {labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Apply label to entity
#
# POST /ad_accounts/{ad_account_id}/labels/{label_id}/apply
# operationId: labels/apply
export def "ad-accounts-labels-apply labels/apply" [
  ad_account_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  entity_ids: list # Entity IDs to apply label to.
]: any -> record<entities_labels: table<entity_id: string, entity_type: record, label_id: string, status: record>, errors: table<data: record, error_messages: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/labels/($label_id)/apply")
  let body = {entity_ids: $entity_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove label from entities
#
# POST /ad_accounts/{ad_account_id}/labels/{label_id}/remove
# operationId: labels/remove
export def "ad-accounts-labels-remove labels/remove" [
  ad_account_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  entity_ids: list # Entity IDs to apply label to.
]: any -> record<entities_labels: table<entity_id: string, entity_type: record, label_id: string, status: record>, errors: table<data: record, error_messages: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/labels/($label_id)/remove")
  let body = {entity_ids: $entity_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List lead forms
#
# GET /ad_accounts/{ad_account_id}/lead_forms
# operationId: lead_forms/list
export def "ad-accounts-lead-forms forms/list" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
  --order: string@order-completer # The order in which to sort the items returned: "ASCENDING" or "DESCENDING" by ID. Note that higher-value IDs are associated with more-recently added items.
]: nothing -> record<bookmark: string, items: table<ad_account_id: string, completion_message: string, created_time: int, disclosure_language: string, has_accepted_terms: bool, id: string, name: string, policy_links: list, privacy_policy_link: string, questions: list, status: string, updated_time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/lead_forms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create lead forms
#
# POST /ad_accounts/{ad_account_id}/lead_forms
# operationId: lead_forms/create
export def "ad-accounts-lead-forms forms/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<items: table<data: record, exceptions: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/lead_forms")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update lead forms
#
# PATCH /ad_accounts/{ad_account_id}/lead_forms
# operationId: lead_forms/update
export def "ad-accounts-lead-forms forms/update" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<items: table<data: record, exceptions: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/lead_forms")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get lead form by id
#
# GET /ad_accounts/{ad_account_id}/lead_forms/{lead_form_id}
# operationId: lead_form/get
export def "ad-accounts-lead-forms form/get" [
  lead_form_id: string
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ad_account_id: string, completion_message: string, created_time: int, disclosure_language: string, has_accepted_terms: bool, id: string, name: string, policy_links: table<label: string, link: string>, privacy_policy_link: string, questions: table<custom_question_field_type: string, custom_question_label: string, custom_question_options: list, question_type: string>, status: string, updated_time: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/lead_forms/($lead_form_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create lead form test data
#
# POST /ad_accounts/{ad_account_id}/lead_forms/{lead_form_id}/test
# operationId: lead_form_test/create
export def "ad-accounts-lead-forms-test test/create" [
  ad_account_id: string
  lead_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  answers: list # Test lead answers. Should follow the creation order. (e.g. [John, Doe, abc@email.com, 987654321])
]: any -> record<subscription_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/lead_forms/($lead_form_id)/test")
  let body = {answers: $answers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get lead ads subscriptions
#
# GET /ad_accounts/{ad_account_id}/leads/subscriptions
# operationId: ad_accounts_subscriptions/get_list
export def "ad-accounts-leads-subscriptions list" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<ad_account_id: string, api_version: string, created_time: int, cryptographic_algorithm: string, cryptographic_key: string, id: string, lead_form_id: string, user_account_id: string, webhook_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/leads/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create lead ads subscription
#
# POST /ad_accounts/{ad_account_id}/leads/subscriptions
# operationId: ad_accounts_subscriptions/post
export def "ad-accounts-leads-subscriptions subscriptions/post" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --partner-access-token: string # Partner access token. Only for clients that requires authentication. We recommend to avoid this param.
  --partner-metadata: any # Partner metadata. Only for clients that requires special handling. We recommend to avoid this param.
  --partner-refresh-token: string # Partner refresh token. Only for clients that requires authentication. We recommend to avoid this param.
  --lead-form-id: string # Lead form ID.
  webhook_url: string # Standard HTTPS webhook URL.
]: any -> record<ad_account_id: string, api_version: string, created_time: int, cryptographic_algorithm: string, cryptographic_key: string, id: string, lead_form_id: string, user_account_id: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/leads/subscriptions")
  let body = {partner_access_token: $partner_access_token, partner_metadata: $partner_metadata, partner_refresh_token: $partner_refresh_token, lead_form_id: $lead_form_id, webhook_url: $webhook_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get lead ads subscription by ID
#
# GET /ad_accounts/{ad_account_id}/leads/subscriptions/{subscription_id}
# operationId: ad_accounts_subscriptions/get_by_id
export def "ad-accounts-leads-subscriptions id-by-ad_account_id-subscription_id" [
  ad_account_id: string
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ad_account_id: string, api_version: string, created_time: int, cryptographic_algorithm: string, cryptographic_key: string, id: string, lead_form_id: string, user_account_id: string, webhook_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/leads/subscriptions/($subscription_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete lead ads subscription
#
# DELETE /ad_accounts/{ad_account_id}/leads/subscriptions/{subscription_id}
# operationId: ad_accounts_subscriptions/del_by_id
export def "ad-accounts-leads-subscriptions id-by-ad_account_id-subscription_id-1" [
  ad_account_id: string
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ad_account_id: string, api_version: string, created_time: int, cryptographic_algorithm: string, cryptographic_key: string, id: string, lead_form_id: string, user_account_id: string, webhook_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/leads/subscriptions/($subscription_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a request to export leads collected from a lead ad
#
# POST /ad_accounts/{ad_account_id}/leads_export
# operationId: leads_export/create
export def "ad-accounts-leads-export export/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ad_id: string # ID for the ad collecting leads. (e.g. 687201361754)
  end_date: string # Export leads collected on and before end date (UTC). Format: YYYY-MM-DD. (e.g. 2020-12-20)
  start_date: string # Export leads collected on and after start date (UTC). Format: YYYY-MM-DD. (e.g. 2020-12-20)
]: any -> record<leads_export_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/leads_export")
  let body = {ad_id: $ad_id, end_date: $end_date, start_date: $start_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the lead export from the lead export create call
#
# GET /ad_accounts/{ad_account_id}/leads_export/{leads_export_id}
# operationId: leads_export/get
export def "ad-accounts-leads-export export/get" [
  ad_account_id: string
  leads_export_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<download_url: string, export_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/leads_export/($leads_export_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get advertiser Marketing Mix Modeling (MMM) report.
#
# GET /ad_accounts/{ad_account_id}/mmm_reports
# operationId: analytics/get_mmm_report
export def "ad-accounts-mmm-reports report-by-ad_account_id" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Token returned from the post request creation call
]: nothing -> record<message: string, report_status: record, size: float, status: string, token: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/mmm_reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a request for a Marketing Mix Modeling (MMM) report
#
# POST /ad_accounts/{ad_account_id}/mmm_reports
# operationId: analytics/create_mmm_report
export def "ad-accounts-mmm-reports report-by-ad_account_id-1" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --advertiser-ids: list # Advertiser IDs for multi-advertiser report
  columns: list # Metric and entity columns
  --countries: list # A List of countries for filtering
  --custom-column-ids: list # List of custom column IDs
  end_date: string # Metric report end date (UTC). Format: YYYY-MM-DD (e.g. 2020-12-20)
  granularity: any #   DAY - metrics are broken down daily.    WEEK - metrics are broken down weekly.
  level: any # Level of the report
  report_name: string # Name of the Marketing Mix Modeling (MMM) report
  start_date: string # Metric report start date (UTC). Format: YYYY-MM-DD (e.g. 2020-12-20)
  targeting_types: list # List of targeting types (e.g. [GENDER])
]: any -> record<message: string, report_status: record, size: float, status: string, token: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/mmm_reports")
  let body = {advertiser_ids: $advertiser_ids, columns: $columns, countries: $countries, custom_column_ids: $custom_column_ids, end_date: $end_date, granularity: $granularity, level: $level, report_name: $report_name, start_date: $start_date, targeting_types: $targeting_types} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send Measurement Source Of Truth (MSOT) attributed conversion events
#
# POST /ad_accounts/{ad_account_id}/msot/events
# operationId: msot_events/create
@deprecated --flag total-events
export def "ad-accounts-msot-events events/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --action-timestamps: list # Timestamp(s) when the ad action(s) happened. Unix timestamp in seconds. (e.g. [1451410040])
  ad_group_id: any # The ID of the ad group that was attributed to the conversion event. (e.g. 2680060704746)
  --attribution-model: any # The attribution model used to attribute the conversion event. (e.g. multi_touch)
  --attribution-scope: any # Ad event type. (e.g. click)
  --attribution-score: float # Credit given to the attributed ad actions. Allowed values are > 0 and <= 1. (format: double, e.g. 0.5)
  --campaign-id: any # The ID of the campaign that was attributed to the conversion event. (e.g. 626736533506)
  --click-window: string # Click window used for attribution (for example, `1d`, `7d`, `30d`, `lifetime`).
  --currency: any # Currency code for the `value` field, required if `value` is present. Currency Codes should be in ISO 4217 standard.
  event_id: string # A unique id string that identifies this event. If you are already sending us events through Conversions API, then this id should match the event_id sent through Conversions API. (e.g. eventId0001)
  event_name: any # Type of user event. (e.g. add_to_cart)
  event_timestamp: int # The time when the event occurred. Unix timestamp in seconds. (format: int64, e.g. 1451431341)
  --total-event-touchpoints: int # Total number of ad events including other non-Pinterest ad platforms. (e.g. 2)
  --total-events: int # Deprecated: use `total_events_fractional` instead to avoid rounding errors. Total number of conversion events that are reported in one API call.  If you are sending one API request for one attributed conversion event then this value should be 1. If you are sending multiple attributed conversion events in one API request then this value should be the total number of attributed conversion events in the request. (DEPRECATED, e.g. 2)
  --total-events-fractional: float # Total number of conversion events that are reported in one API call. Use this field instead of `total_events` to send precise fractional values.  If you are sending one API request for one attributed conversion event with full credit, this value should be 1.0. For partial attribution, send the exact fractional value (e.g., 0.5 for half credit). (format: double)
  --value: float # Order value of the conversion event. Required if `event_name` is `add_to_cart` or `checkout`. (format: double, e.g. 123.45)
  --view-window: string # View window used for attribution (for example, `1d`, `7d`, `30d`).
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/msot/events")
  let body = {action_timestamps: $action_timestamps, ad_group_id: $ad_group_id, attribution_model: $attribution_model, attribution_scope: $attribution_scope, attribution_score: $attribution_score, campaign_id: $campaign_id, click_window: $click_window, currency: $currency, event_id: $event_id, event_name: $event_name, event_timestamp: $event_timestamp, total_event_touchpoints: $total_event_touchpoints, total_events: $total_events, total_events_fractional: $total_events_fractional, value: $value, view_window: $view_window} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get order lines.
#
# GET /ad_accounts/{ad_account_id}/order_lines
# operationId: order_lines/list
export def "ad-accounts-order-lines lines/list" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
  --order: string@order-completer # The order in which to sort the items returned: "ASCENDING" or "DESCENDING" by ID. Note that higher-value IDs are associated with more-recently added items.
]: nothing -> record<bookmark: string, items: table<ad_account_id: string, budget: float, campaign_ids: list, end_time: float, id: string, name: string, paid_budget: float, paid_type: record, purchase_order_id: string, start_time: float, status: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/order_lines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get order line
#
# GET /ad_accounts/{ad_account_id}/order_lines/{order_line_id}
# operationId: order_lines/get
export def "ad-accounts-order-lines lines/get" [
  order_line_id: string
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ad_account_id: string, budget: float, campaign_ids: list<string>, end_time: float, id: string, name: string, paid_budget: float, paid_type: record, purchase_order_id: string, start_time: float, status: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/order_lines/($order_line_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get pins analytics
#
# GET /ad_accounts/{ad_account_id}/pins/analytics
# operationId: ad_pins/analytics
export def "ad-accounts-pins-analytics pins/analytics" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaign-id: string # Campaign Id to use to filter the results.
  --pin-ids: list # List of Pin IDs.
  --start-date: string # Metric report start date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days back from today. (format: date)
  --end-date: string # Metric report end date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days past start_date. (format: date)
  --columns: list # Columns to retrieve, encoded as a comma-separated string. **NOTE**: Any metrics defined as MICRO_DOLLARS returns a value based on the advertiser profile's currency field. For USD, ($1/1,000,000, or $0.000001 - one one-ten-thousandth of a cent). it's microdollars. Otherwise, it's in microunits of the advertiser's currency.  For example, if the advertiser's currency is GBP (British pound sterling), all MICRO_DOLLARS fields will be in GBP microunits (1/1,000,000 British pound).  If a column has no value, it may not be returned.
  --granularity: string@granularity-completer #   TOTAL - metrics are aggregated over the specified date range.    DAY - metrics are broken down daily.    HOUR - metrics are broken down hourly.    WEEK - metrics are broken down weekly.    MONTH - metrics are broken down monthly
  --click-window-days: float@click-window-days-completer # Number of days to use as the conversion attribution window for a pin click action. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `30` days. (default: 30)
  --engagement-window-days: float@engagement-window-days-completer # Number of days to use as the conversion attribution window for an engagement action. Engagements include saves, closeups, link clicks, and carousel card swipes. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `30` days. **Note:** This parameter no longer returns new data. However, you can still access historic data through **Sept 30, 2027**. (default: 30)
  --view-window-days: float@view-window-days-completer # Number of days to use as the conversion attribution window for a view action. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `1` day. (default: 1)
  --conversion-report-time: string@conversion-report-time-completer # The date by which the conversion metrics returned from this endpoint will be reported. There are two dates associated with a conversion event: the date that the user interacted with the ad, and the date that the user completed a conversion event. (default: TIME_OF_AD_ACTION)
]: nothing -> table<DATE: string, PIN_ID: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "campaign_id" $campaign_id "scalar") (serialize-qp "pin_ids" $pin_ids "multi") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "columns" $columns "csv") (serialize-qp "granularity" $granularity "scalar") (serialize-qp "click_window_days" $click_window_days "scalar") (serialize-qp "engagement_window_days" $engagement_window_days "scalar") (serialize-qp "view_window_days" $view_window_days "scalar") (serialize-qp "conversion_report_time" $conversion_report_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/pins/analytics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create product group promotions
#
# POST /ad_accounts/{ad_account_id}/product_group_promotions
# operationId: product_group_promotions/create
# --product_group_promotion item shape: {ad_group_id?: string, bid_in_micro_currency?: int, catalog_product_group_id?: string, catalog_product_group_name?: string, collections_header_type?: "SHOP_THIS_COLLECTION"|"EXPLORE_THIS_COLLECTION"|"NO_HEADER"|"ON_SALE"|"GET_DEAL"|"", collections_hero_destination_url?: string, collections_hero_pin_id?: string, creative_type?: "REGULAR"|"VIDEO"|"SHOPPING"|"CAROUSEL"|"MAX_VIDEO"|"SHOP_THE_PIN"|"COLLECTION"|"IDEA"|"SHOWCASE"|"QUIZ"|"COLLAGE"|"MAX_WIDTH_REGULAR_COLLECTION"|"MAX_WIDTH_VIDEO_COLLECTION"|"APP", customizable_cta_type?: "GET_OFFER"|"LEARN_MORE"|"ORDER_NOW"|"SHOP_NOW"|"SIGN_UP"|"SUBSCRIBE"|"BUY_NOW"|"CONTACT_US"|"GET_QUOTE"|"VISIT_SITE"|"APPLY_NOW"|"BOOK_NOW"|"REGISTER_NOW"|"FIND_A_DEALER"|"WATCH_NOW"|"READ_MORE"|"BUY_TICKETS"|"DONATE_NOW"|"DOWNLOAD"|"EXPLORE_MORE"|"FIND_A_LOCATION"|"GET_DEAL"|"GET_RECIPE"|"GET_SHOWTIMES"|"ON_SALE"|"PLAY_GAME"|"TRY_IT"|"BUY_ONLINE_PICKUP_IN_STORE"|"SHOP_ON_ADVERTISER"|"SHOP_THE_COLLECTION"|"GET_IT_NOW"|"TAKE_A_PEEK"|"TAKE_A_CLOSER_LOOK", definition?: string, grid_click_type?: "CLOSEUP"|"DIRECT_TO_DESTINATION", id?: string, included?: bool, is_generate_background?: bool, is_image_auto_resizing?: bool, is_mdl?: bool, parent_id?: string, preferred_media_type?: "VIDEO"|"IMAGE"|"", relative_definition?: string, selected_image_tag?: string, selected_video_tag?: string, slideshow_collections_description?: string, slideshow_collections_title?: string, status?: "ACTIVE"|"PAUSED"|"ARCHIVED"|"DRAFT"|"DELETED_DRAFT", tracking_url?: string}
export def "ad-accounts-product-group-promotions promotions/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ad_group_id: string # ID of the ad group the product group promotion belongs to. (e.g. 2680059592705)
  product_group_promotion: list # List of product group promotions to create or update. (e.g. [{slideshow_collections_description: Description, creative_type: REGULAR, collections_hero_pin_id: 123123, catalog_product_group_name: catalogProductGroupName to create, collections_hero_destination_url: http://www.pinterest.com, tracking_url: https://www.pinterest.com, slideshow_collections_title: Title, status: ACTIVE, is_mdl: true}, {id: 2680059592705, catalog_product_group_id: 1234123, slideshow_collections_description: Description, creative_type: REGULAR, collections_hero_pin_id: 123123, catalog_product_group_name: catalogProductGroupName to update, collections_hero_destination_url: http://www.pinterest.com, tracking_url: https://www.pinterest.com, slideshow_collections_title: Title, status: ACTIVE}]) — item shape: {ad_group_id?: string, bid_in_micro_currency?: int, catalog_product_group_id?: string, catalog_product_group_name?: string, collections_header_type?: "SHOP_THIS_COLLECTION"|"EXPLORE_THIS_COLLECTION"|"NO_HEADER"|"ON_SALE"|"GET_DEAL"|"", collections_hero_destination_url?: string, collections_hero_pin_id?: string, creative_type?: "REGULAR"|"VIDEO"|"SHOPPING"|"CAROUSEL"|"MAX_VIDEO"|"SHOP_THE_PIN"|"COLLECTION"|"IDEA"|"SHOWCASE"|"QUIZ"|"COLLAGE"|"MAX_WIDTH_REGULAR_COLLECTION"|"MAX_WIDTH_VIDEO_COLLECTION"|"APP", customizable_cta_type?: "GET_OFFER"|"LEARN_MORE"|"ORDER_NOW"|"SHOP_NOW"|"SIGN_UP"|"SUBSCRIBE"|"BUY_NOW"|"CONTACT_US"|"GET_QUOTE"|"VISIT_SITE"|"APPLY_NOW"|"BOOK_NOW"|"REGISTER_NOW"|"FIND_A_DEALER"|"WATCH_NOW"|"READ_MORE"|"BUY_TICKETS"|"DONATE_NOW"|"DOWNLOAD"|"EXPLORE_MORE"|"FIND_A_LOCATION"|"GET_DEAL"|"GET_RECIPE"|"GET_SHOWTIMES"|"ON_SALE"|"PLAY_GAME"|"TRY_IT"|"BUY_ONLINE_PICKUP_IN_STORE"|"SHOP_ON_ADVERTISER"|"SHOP_THE_COLLECTION"|"GET_IT_NOW"|"TAKE_A_PEEK"|"TAKE_A_CLOSER_LOOK", definition?: string, grid_click_type?: "CLOSEUP"|"DIRECT_TO_DESTINATION", id?: string, included?: bool, is_generate_background?: bool, is_image_auto_resizing?: bool, is_mdl?: bool, parent_id?: string, preferred_media_type?: "VIDEO"|"IMAGE"|"", relative_definition?: string, selected_image_tag?: string, selected_video_tag?: string, slideshow_collections_description?: string, slideshow_collections_title?: string, status?: "ACTIVE"|"PAUSED"|"ARCHIVED"|"DRAFT"|"DELETED_DRAFT", tracking_url?: string}
]: any -> record<items: table<data: record, exceptions: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/product_group_promotions")
  let body = {ad_group_id: $ad_group_id, product_group_promotion: $product_group_promotion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update product group promotions
#
# PATCH /ad_accounts/{ad_account_id}/product_group_promotions
# operationId: product_group_promotions/update
# --product_group_promotion item shape: {ad_group_id?: string, bid_in_micro_currency?: int, catalog_product_group_id?: string, catalog_product_group_name?: string, collections_header_type?: "SHOP_THIS_COLLECTION"|"EXPLORE_THIS_COLLECTION"|"NO_HEADER"|"ON_SALE"|"GET_DEAL"|"", collections_hero_destination_url?: string, collections_hero_pin_id?: string, creative_type?: "REGULAR"|"VIDEO"|"SHOPPING"|"CAROUSEL"|"MAX_VIDEO"|"SHOP_THE_PIN"|"COLLECTION"|"IDEA"|"SHOWCASE"|"QUIZ"|"COLLAGE"|"MAX_WIDTH_REGULAR_COLLECTION"|"MAX_WIDTH_VIDEO_COLLECTION"|"APP", customizable_cta_type?: "GET_OFFER"|"LEARN_MORE"|"ORDER_NOW"|"SHOP_NOW"|"SIGN_UP"|"SUBSCRIBE"|"BUY_NOW"|"CONTACT_US"|"GET_QUOTE"|"VISIT_SITE"|"APPLY_NOW"|"BOOK_NOW"|"REGISTER_NOW"|"FIND_A_DEALER"|"WATCH_NOW"|"READ_MORE"|"BUY_TICKETS"|"DONATE_NOW"|"DOWNLOAD"|"EXPLORE_MORE"|"FIND_A_LOCATION"|"GET_DEAL"|"GET_RECIPE"|"GET_SHOWTIMES"|"ON_SALE"|"PLAY_GAME"|"TRY_IT"|"BUY_ONLINE_PICKUP_IN_STORE"|"SHOP_ON_ADVERTISER"|"SHOP_THE_COLLECTION"|"GET_IT_NOW"|"TAKE_A_PEEK"|"TAKE_A_CLOSER_LOOK", definition?: string, grid_click_type?: "CLOSEUP"|"DIRECT_TO_DESTINATION", id?: string, included?: bool, is_generate_background?: bool, is_image_auto_resizing?: bool, is_mdl?: bool, parent_id?: string, preferred_media_type?: "VIDEO"|"IMAGE"|"", relative_definition?: string, selected_image_tag?: string, selected_video_tag?: string, slideshow_collections_description?: string, slideshow_collections_title?: string, status?: "ACTIVE"|"PAUSED"|"ARCHIVED"|"DRAFT"|"DELETED_DRAFT", tracking_url?: string}
export def "ad-accounts-product-group-promotions promotions/update" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ad_group_id: string # ID of the ad group the product group promotion belongs to. (e.g. 2680059592705)
  product_group_promotion: list # List of product group promotions to create or update. (e.g. [{slideshow_collections_description: Description, creative_type: REGULAR, collections_hero_pin_id: 123123, catalog_product_group_name: catalogProductGroupName to create, collections_hero_destination_url: http://www.pinterest.com, tracking_url: https://www.pinterest.com, slideshow_collections_title: Title, status: ACTIVE, is_mdl: true}, {id: 2680059592705, catalog_product_group_id: 1234123, slideshow_collections_description: Description, creative_type: REGULAR, collections_hero_pin_id: 123123, catalog_product_group_name: catalogProductGroupName to update, collections_hero_destination_url: http://www.pinterest.com, tracking_url: https://www.pinterest.com, slideshow_collections_title: Title, status: ACTIVE}]) — item shape: {ad_group_id?: string, bid_in_micro_currency?: int, catalog_product_group_id?: string, catalog_product_group_name?: string, collections_header_type?: "SHOP_THIS_COLLECTION"|"EXPLORE_THIS_COLLECTION"|"NO_HEADER"|"ON_SALE"|"GET_DEAL"|"", collections_hero_destination_url?: string, collections_hero_pin_id?: string, creative_type?: "REGULAR"|"VIDEO"|"SHOPPING"|"CAROUSEL"|"MAX_VIDEO"|"SHOP_THE_PIN"|"COLLECTION"|"IDEA"|"SHOWCASE"|"QUIZ"|"COLLAGE"|"MAX_WIDTH_REGULAR_COLLECTION"|"MAX_WIDTH_VIDEO_COLLECTION"|"APP", customizable_cta_type?: "GET_OFFER"|"LEARN_MORE"|"ORDER_NOW"|"SHOP_NOW"|"SIGN_UP"|"SUBSCRIBE"|"BUY_NOW"|"CONTACT_US"|"GET_QUOTE"|"VISIT_SITE"|"APPLY_NOW"|"BOOK_NOW"|"REGISTER_NOW"|"FIND_A_DEALER"|"WATCH_NOW"|"READ_MORE"|"BUY_TICKETS"|"DONATE_NOW"|"DOWNLOAD"|"EXPLORE_MORE"|"FIND_A_LOCATION"|"GET_DEAL"|"GET_RECIPE"|"GET_SHOWTIMES"|"ON_SALE"|"PLAY_GAME"|"TRY_IT"|"BUY_ONLINE_PICKUP_IN_STORE"|"SHOP_ON_ADVERTISER"|"SHOP_THE_COLLECTION"|"GET_IT_NOW"|"TAKE_A_PEEK"|"TAKE_A_CLOSER_LOOK", definition?: string, grid_click_type?: "CLOSEUP"|"DIRECT_TO_DESTINATION", id?: string, included?: bool, is_generate_background?: bool, is_image_auto_resizing?: bool, is_mdl?: bool, parent_id?: string, preferred_media_type?: "VIDEO"|"IMAGE"|"", relative_definition?: string, selected_image_tag?: string, selected_video_tag?: string, slideshow_collections_description?: string, slideshow_collections_title?: string, status?: "ACTIVE"|"PAUSED"|"ARCHIVED"|"DRAFT"|"DELETED_DRAFT", tracking_url?: string}
]: any -> record<items: table<data: record, exceptions: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/product_group_promotions")
  let body = {ad_group_id: $ad_group_id, product_group_promotion: $product_group_promotion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get product group promotions
#
# GET /ad_accounts/{ad_account_id}/product_group_promotions
# operationId: product_group_promotions/list
export def "ad-accounts-product-group-promotions promotions/list" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
  --order: string@order-completer # The order in which to sort the items returned: "ASCENDING" or "DESCENDING" by ID. Note that higher-value IDs are associated with more-recently added items.
  --product-group-promotion-ids: list # List of Product group promotion Ids.
  --entity-statuses: list # Entity status (default: [ACTIVE, PAUSED])
  --ad-group-id: string # Ad group Id.
]: nothing -> record<bookmark: string, items: table<ad_group_id: string, bid_in_micro_currency: int, catalog_product_group_id: string, catalog_product_group_name: string, collections_header_type: string, collections_hero_destination_url: string, collections_hero_pin_id: string, creative_type: string, customizable_cta_type: string, definition: string, grid_click_type: string, id: string, included: bool, is_generate_background: bool, is_image_auto_resizing: bool, is_mdl: bool, parent_id: string, preferred_media_type: string, relative_definition: string, selected_image_tag: string, selected_video_tag: string, slideshow_collections_description: string, slideshow_collections_title: string, status: string, tracking_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "product_group_promotion_ids" $product_group_promotion_ids "multi") (serialize-qp "entity_statuses" $entity_statuses "multi") (serialize-qp "ad_group_id" $ad_group_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/product_group_promotions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a product group promotion by id
#
# GET /ad_accounts/{ad_account_id}/product_group_promotions/{product_group_promotion_id}
# operationId: product_group_promotions/get
export def "ad-accounts-product-group-promotions promotions/get" [
  ad_account_id: string
  product_group_promotion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ad_group_id: string, bid_in_micro_currency: int, catalog_product_group_id: string, catalog_product_group_name: string, collections_header_type: string, collections_hero_destination_url: string, collections_hero_pin_id: string, creative_type: string, customizable_cta_type: string, definition: string, grid_click_type: string, id: string, included: bool, is_generate_background: bool, is_image_auto_resizing: bool, is_mdl: bool, parent_id: string, preferred_media_type: string, relative_definition: string, selected_image_tag: string, selected_video_tag: string, slideshow_collections_description: string, slideshow_collections_title: string, status: string, tracking_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/product_group_promotions/($product_group_promotion_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get product group analytics
#
# GET /ad_accounts/{ad_account_id}/product_groups/analytics
# operationId: product_groups/analytics
export def "ad-accounts-product-groups-analytics groups/analytics" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # Metric report start date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days back from today. (format: date)
  --end-date: string # Metric report end date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days past start_date. (format: date)
  --product-group-ids: list # List of Product group Ids to use to filter the results.
  --columns: list # Columns to retrieve, encoded as a comma-separated string. **NOTE**: Any metrics defined as MICRO_DOLLARS returns a value based on the advertiser profile's currency field. For USD, ($1/1,000,000, or $0.000001 - one one-ten-thousandth of a cent). it's microdollars. Otherwise, it's in microunits of the advertiser's currency.  For example, if the advertiser's currency is GBP (British pound sterling), all MICRO_DOLLARS fields will be in GBP microunits (1/1,000,000 British pound).  If a column has no value, it may not be returned.
  --granularity: string@granularity-completer #   TOTAL - metrics are aggregated over the specified date range.    DAY - metrics are broken down daily.    HOUR - metrics are broken down hourly.    WEEK - metrics are broken down weekly.    MONTH - metrics are broken down monthly
  --click-window-days: float@click-window-days-completer # Number of days to use as the conversion attribution window for a pin click action. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `30` days. (default: 30)
  --engagement-window-days: float@engagement-window-days-completer # Number of days to use as the conversion attribution window for an engagement action. Engagements include saves, closeups, link clicks, and carousel card swipes. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `30` days. **Note:** This parameter no longer returns new data. However, you can still access historic data through **Sept 30, 2027**. (default: 30)
  --view-window-days: float@view-window-days-completer # Number of days to use as the conversion attribution window for a view action. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `1` day. (default: 1)
  --conversion-report-time: string@conversion-report-time-completer # The date by which the conversion metrics returned from this endpoint will be reported. There are two dates associated with a conversion event: the date that the user interacted with the ad, and the date that the user completed a conversion event. (default: TIME_OF_AD_ACTION)
  --reporting-timezone: string@reporting-timezone-completer # Specify the timezone to be applied for the reporting. This feature is currently in BETA and is not available to all users. (e.g. PINTEREST_TIME_ZONE)
]: nothing -> table<DATE: string, PRODUCT_GROUP_ID: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "product_group_ids" $product_group_ids "multi") (serialize-qp "columns" $columns "csv") (serialize-qp "granularity" $granularity "scalar") (serialize-qp "click_window_days" $click_window_days "scalar") (serialize-qp "engagement_window_days" $engagement_window_days "scalar") (serialize-qp "view_window_days" $view_window_days "scalar") (serialize-qp "conversion_report_time" $conversion_report_time "scalar") (serialize-qp "reporting_timezone" $reporting_timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/product_groups/analytics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List of ad groups using promotions IDs.
#
# GET /ad_accounts/{ad_account_id}/promotion_applied_entities
# operationId: get_ad_groups_by_promotion_ids/list
export def "ad-accounts-promotion-applied-entities ids/list" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
  --order: string@order-completer # The order in which to sort the items returned: "ASCENDING" or "DESCENDING" by ID. Note that higher-value IDs are associated with more-recently added items.
  --promotion-ids: list # List of Promotion IDs to use to filter the results.
]: nothing -> record<bookmark: string, items: table<auto_targeting_enabled: bool, bid_multiplier: float, budget_type: string, pacing_delivery_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "promotion_ids" $promotion_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/promotion_applied_entities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get promotions
#
# GET /ad_accounts/{ad_account_id}/promotions
# operationId: promotions/list
export def "ad-accounts-promotions promotions/list" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
  --order: string@order-completer # The order in which to sort the items returned: "ASCENDING" or "DESCENDING" by ID. Note that higher-value IDs are associated with more-recently added items.
]: nothing -> record<bookmark: string, items: table<ad_account_id: string, discount_status: string, end_time: int, external_id: string, id: string, platform_type: string, promotion_code: string, promotion_custom_id: string, promotion_title: string, promotion_type: string, start_time: int, status: record, template_values: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/promotions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create promotions
#
# POST /ad_accounts/{ad_account_id}/promotions
# operationId: promotions/create
export def "ad-accounts-promotions promotions/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<promotions: table<data: record, exception: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/promotions")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update promotions
#
# PATCH /ad_accounts/{ad_account_id}/promotions
# operationId: promotions/update
export def "ad-accounts-promotions promotions/update" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<promotions: table<data: record, exception: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/promotions")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get promotion by id
#
# GET /ad_accounts/{ad_account_id}/promotions/{promotion_id}
# operationId: promotions/get
export def "ad-accounts-promotions promotions/get" [
  promotion_id: string
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ad_account_id: string, discount_status: string, end_time: int, external_id: string, id: string, platform_type: string, promotion_code: string, promotion_custom_id: string, promotion_title: string, promotion_type: string, start_time: int, status: record, template_values: table<amount: float, currency_code: string, custom_text: string, percent: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/promotions/($promotion_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete promotion by id
#
# DELETE /ad_accounts/{ad_account_id}/promotions/{promotion_id}
# operationId: promotions/delete
export def "ad-accounts-promotions promotions/delete" [
  promotion_id: string
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ad_account_id: string, discount_status: string, end_time: int, external_id: string, id: string, platform_type: string, promotion_code: string, promotion_custom_id: string, promotion_title: string, promotion_type: string, start_time: int, status: record, template_values: table<amount: float, currency_code: string, custom_text: string, percent: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/promotions/($promotion_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the account analytics report created by the async call
#
# GET /ad_accounts/{ad_account_id}/reports
# operationId: analytics/get_report
export def "ad-accounts-reports report-by-ad_account_id" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Token returned from the post request creation call
]: nothing -> record<report_status: string, size: float, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create async request for an account analytics report
#
# POST /ad_accounts/{ad_account_id}/reports
# operationId: analytics/create_report
# --custom_conversion_event_metrics item shape: {custom_event_metrics_type: "ADE_COST_PER_ACTION"|"ADE_ROAS"|"ADE_TOTAL_CONVERSIONS"|"ADE_TOTAL_VALUE_IN_MICRO_DOLLAR"|"ADE_AVERAGE_VALUE_IN_MICRO_DOLLAR"|"ADE_TOTAL_CLICK"|"ADE_TOTAL_CLICK_VALUE_IN_MICRO_DOLLAR"|"ADE_TOTAL_VIEW"|"ADE_TOTAL_VIEW_VALUE_IN_MICRO_DOLLAR"|"ADE_TOTAL_CONVERSION_RATE"|"ADE_WEB_COST_PER_ACTION"|"ADE_WEB_ROAS"|"ADE_TOTAL_WEB_CONVERSIONS"|"ADE_TOTAL_WEB_VALUE_IN_MICRO_DOLLAR"|"ADE_TOTAL_WEB_CLICK"|"ADE_TOTAL_WEB_CLICK_VALUE_IN_MICRO_DOLLAR"|"ADE_TOTAL_WEB_VIEW"|"ADE_TOTAL_WEB_VIEW_VALUE_IN_MICRO_DOLLAR"|"ADE_INAPP_COST_PER_ACTION"|"ADE_INAPP_ROAS"|"ADE_TOTAL_INAPP_CONVERSIONS"|"ADE_TOTAL_INAPP_VALUE_IN_MICRO_DOLLAR"|"ADE_TOTAL_INAPP_CLICK"|"ADE_TOTAL_INAPP_CLICK_VALUE_IN_MICRO_DOLLAR"|"ADE_TOTAL_INAPP_VIEW"|"ADE_TOTAL_INAPP_VIEW_VALUE_IN_MICRO_DOLLAR"|"ADE_OFFLINE_COST_PER_ACTION"|"ADE_OFFLINE_ROAS"|"ADE_TOTAL_OFFLINE_CONVERSIONS"|"ADE_TOTAL_OFFLINE_VALUE_IN_MICRO_DOLLAR"|"ADE_TOTAL_OFFLINE_CLICK"|"ADE_TOTAL_OFFLINE_CLICK_VALUE_IN_MICRO_DOLLAR"|"ADE_TOTAL_OFFLINE_VIEW"|"ADE_TOTAL_OFFLINE_VIEW_VALUE_IN_MICRO_DOLLAR"|"ADE_TOTAL_CONVERSION_PRODUCT_QUANTITY"|"ADE_TOTAL_CONVERSION_PRODUCT_VALUE"|"ADE_TOTAL_CONVERSION_PRODUCT_VALUE_IN_MICRO_UNITS"|"ADE_TOTAL_CONVERSION_PRODUCT_VALUE_IN_USD"|"ADE_TOTAL_CONVERSION_PRODUCT_VALUE_IN_MICRO_USD"|"ADE_TOTAL_WEB_CONVERSION_PRODUCT_QUANTITY"|"ADE_TOTAL_WEB_CONVERSION_PRODUCT_VALUE"|"ADE_TOTAL_WEB_CONVERSION_PRODUCT_VALUE_IN_MICRO_UNITS"|"ADE_TOTAL_WEB_CONVERSION_PRODUCT_VALUE_IN_USD"|"ADE_TOTAL_WEB_CONVERSION_PRODUCT_VALUE_IN_MICRO_USD"|"ADE_TOTAL_INAPP_CONVERSION_PRODUCT_QUANTITY"|"ADE_TOTAL_INAPP_CONVERSION_PRODUCT_VALUE"|"ADE_TOTAL_INAPP_CONVERSION_PRODUCT_VALUE_IN_MICRO_UNITS"|"ADE_TOTAL_INAPP_CONVERSION_PRODUCT_VALUE_IN_USD"|"ADE_TOTAL_INAPP_CONVERSION_PRODUCT_VALUE_IN_MICRO_USD"|"ADE_TOTAL_OFFLINE_CONVERSION_PRODUCT_QUANTITY"|"ADE_TOTAL_OFFLINE_CONVERSION_PRODUCT_VALUE"|"ADE_TOTAL_OFFLINE_CONVERSION_PRODUCT_VALUE_IN_MICRO_UNITS"|"ADE_TOTAL_OFFLINE_CONVERSION_PRODUCT_VALUE_IN_USD"|"ADE_TOTAL_OFFLINE_CONVERSION_PRODUCT_VALUE_IN_MICRO_USD", custom_event_name: string}
# --metrics_filters item shape: {field: "SPEND_IN_DOLLAR"|"TOTAL_IMPRESSION", operator: "LESS_THAN"|"GREATER_THAN", values: list}
export def "ad-accounts-reports report-by-ad_account_id-1" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-group-ids: list # List of ad group ids
  --ad-group-statuses: list # List of values for filtering
  --ad-ids: list # List of ad ids. This parameter is not supported for Product Item level reports.
  --ad-statuses: list # List of values for filtering. This parameter is not supported for Product Item level reports.
  --attribution-types: list # List of attribution types for the conversion report.
  --campaign-brand-label: string # Campaign brand label for filtering.
  --campaign-custom-label: string # Campaign custom label for filtering.
  --campaign-ids: list # List of campaign ids
  --campaign-objective-types: list # List of values for filtering. ["WEB_SESSIONS"] is in BETA.
  --campaign-statuses: list # List of status values for filtering
  --click-window-days: any # Number of days to use as the conversion attribution window for a pin click action. (default: 30)
  --columns: list # Metric and entity columns. Pin promotion and ad related columns are not supported for Product Item level reports.
  --combine-targeting-types: oneof<nothing, bool> # Determines if the targeting types included in the request should be consolidated into a single breakdown. (default: false)
  --conversion-report-time: any # Date dimension for conversion metrics. (default: TIME_OF_AD_ACTION)
  --custom-conversion-event-metrics: list # List of advertiser-defined custom conversion event metrics to include in the report — item shape: {custom_event_metrics_type: "ADE_COST_PER_ACTION"|"ADE_ROAS"|"ADE_TOTAL_CONVERSIONS"|"ADE_TOTAL_VALUE_IN_MICRO_DOLLAR"|"ADE_AVERAGE_VALUE_IN_MICRO_DOLLAR"|"ADE_TOTAL_CLICK"|"ADE_TOTAL_CLICK_VALUE_IN_MICRO_DOLLAR"|"ADE_TOTAL_VIEW"|"ADE_TOTAL_VIEW_VALUE_IN_MICRO_DOLLAR"|"ADE_TOTAL_CONVERSION_RATE"|"ADE_WEB_COST_PER_ACTION"|"ADE_WEB_ROAS"|"ADE_TOTAL_WEB_CONVERSIONS"|"ADE_TOTAL_WEB_VALUE_IN_MICRO_DOLLAR"|"ADE_TOTAL_WEB_CLICK"|"ADE_TOTAL_WEB_CLICK_VALUE_IN_MICRO_DOLLAR"|"ADE_TOTAL_WEB_VIEW"|"ADE_TOTAL_WEB_VIEW_VALUE_IN_MICRO_DOLLAR"|"ADE_INAPP_COST_PER_ACTION"|"ADE_INAPP_ROAS"|"ADE_TOTAL_INAPP_CONVERSIONS"|"ADE_TOTAL_INAPP_VALUE_IN_MICRO_DOLLAR"|"ADE_TOTAL_INAPP_CLICK"|"ADE_TOTAL_INAPP_CLICK_VALUE_IN_MICRO_DOLLAR"|"ADE_TOTAL_INAPP_VIEW"|"ADE_TOTAL_INAPP_VIEW_VALUE_IN_MICRO_DOLLAR"|"ADE_OFFLINE_COST_PER_ACTION"|"ADE_OFFLINE_ROAS"|"ADE_TOTAL_OFFLINE_CONVERSIONS"|"ADE_TOTAL_OFFLINE_VALUE_IN_MICRO_DOLLAR"|"ADE_TOTAL_OFFLINE_CLICK"|"ADE_TOTAL_OFFLINE_CLICK_VALUE_IN_MICRO_DOLLAR"|"ADE_TOTAL_OFFLINE_VIEW"|"ADE_TOTAL_OFFLINE_VIEW_VALUE_IN_MICRO_DOLLAR"|"ADE_TOTAL_CONVERSION_PRODUCT_QUANTITY"|"ADE_TOTAL_CONVERSION_PRODUCT_VALUE"|"ADE_TOTAL_CONVERSION_PRODUCT_VALUE_IN_MICRO_UNITS"|"ADE_TOTAL_CONVERSION_PRODUCT_VALUE_IN_USD"|"ADE_TOTAL_CONVERSION_PRODUCT_VALUE_IN_MICRO_USD"|"ADE_TOTAL_WEB_CONVERSION_PRODUCT_QUANTITY"|"ADE_TOTAL_WEB_CONVERSION_PRODUCT_VALUE"|"ADE_TOTAL_WEB_CONVERSION_PRODUCT_VALUE_IN_MICRO_UNITS"|"ADE_TOTAL_WEB_CONVERSION_PRODUCT_VALUE_IN_USD"|"ADE_TOTAL_WEB_CONVERSION_PRODUCT_VALUE_IN_MICRO_USD"|"ADE_TOTAL_INAPP_CONVERSION_PRODUCT_QUANTITY"|"ADE_TOTAL_INAPP_CONVERSION_PRODUCT_VALUE"|"ADE_TOTAL_INAPP_CONVERSION_PRODUCT_VALUE_IN_MICRO_UNITS"|"ADE_TOTAL_INAPP_CONVERSION_PRODUCT_VALUE_IN_USD"|"ADE_TOTAL_INAPP_CONVERSION_PRODUCT_VALUE_IN_MICRO_USD"|"ADE_TOTAL_OFFLINE_CONVERSION_PRODUCT_QUANTITY"|"ADE_TOTAL_OFFLINE_CONVERSION_PRODUCT_VALUE"|"ADE_TOTAL_OFFLINE_CONVERSION_PRODUCT_VALUE_IN_MICRO_UNITS"|"ADE_TOTAL_OFFLINE_CONVERSION_PRODUCT_VALUE_IN_USD"|"ADE_TOTAL_OFFLINE_CONVERSION_PRODUCT_VALUE_IN_MICRO_USD", custom_event_name: string}
  end_date: string # Metric report end date (UTC). Format: YYYY-MM-DD
  --end-hour: int # Which hour of the end date to stop the report (inclusive). Only allowed for hourly reports.
  --engagement-window-days: any # Number of days to use as the conversion attribution window for an engagement action. (default: 30)
  granularity: any #   TOTAL - metrics are aggregated over the specified date range.   DAY - metrics are broken down daily.   HOUR - metrics are broken down hourly.   WEEKLY - metrics are broken down weekly.   MONTHLY - metrics are broken down monthly.
  --level: any # Level of the report
  --metrics-filters: list # List of metrics filters — item shape: {field: "SPEND_IN_DOLLAR"|"TOTAL_IMPRESSION", operator: "LESS_THAN"|"GREATER_THAN", values: list}
  --primary-sort: any # default: BY_ID
  --product-group-ids: list # List of product group ids
  --product-group-statuses: list # List of values for filtering
  --product-item-ids: list # List of product item ids
  --report-format: any # default: JSON
  --reporting-timezone: any # Specify the timezone to be applied for the reporting.
  start_date: string # Metric report start date (UTC). Format: YYYY-MM-DD
  --start-hour: int # Which hour of the start date to begin the report. Only allowed for hourly reports.
  --targeting-types: list # List of targeting types. Requires `level` to be a value ending in `_TARGETING`.
  --view-window-days: any # Number of days to use as the conversion attribution window for a view action. (default: 1)
]: any -> record<message: string, report_status: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/reports")
  let body = {ad_group_ids: $ad_group_ids, ad_group_statuses: $ad_group_statuses, ad_ids: $ad_ids, ad_statuses: $ad_statuses, attribution_types: $attribution_types, campaign_brand_label: $campaign_brand_label, campaign_custom_label: $campaign_custom_label, campaign_ids: $campaign_ids, campaign_objective_types: $campaign_objective_types, campaign_statuses: $campaign_statuses, click_window_days: $click_window_days, columns: $columns, combine_targeting_types: $combine_targeting_types, conversion_report_time: $conversion_report_time, custom_conversion_event_metrics: $custom_conversion_event_metrics, end_date: $end_date, end_hour: $end_hour, engagement_window_days: $engagement_window_days, granularity: $granularity, level: $level, metrics_filters: $metrics_filters, primary_sort: $primary_sort, product_group_ids: $product_group_ids, product_group_statuses: $product_group_statuses, product_item_ids: $product_item_ids, report_format: $report_format, reporting_timezone: $reporting_timezone, start_date: $start_date, start_hour: $start_hour, targeting_types: $targeting_types, view_window_days: $view_window_days} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get advertiser brand, category, SKU report
#
# GET /ad_accounts/{ad_account_id}/reports/brand_category_sku
# operationId: analytics/get_conversion_product_report
export def "ad-accounts-reports-brand-category-sku report-by-ad_account_id" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Token returned from the post request creation call
]: nothing -> record<message: string, report_status: record, size: float, token: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/reports/brand_category_sku" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a request for a brand, category, SKU report
#
# POST /ad_accounts/{ad_account_id}/reports/brand_category_sku
# operationId: analytics/create_conversion_product_report
export def "ad-accounts-reports-brand-category-sku report-by-ad_account_id-1" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-group-ids: list #   List of ad group ids.   Only support ad_group_ids field when level of the report is AD_GROUP. (e.g. [12345678])
  --campaign-ids: list #   List of campaign ids.   Only support campaign_ids field when level of the report is CAMPAIGN. (e.g. [12345678])
  --campaign-objective-types: list # List of values for filtering. Default is ['CONSIDERATION','AWARENESS','WEB_CONVERSION','VIDEO_COMPLETION'].
  --click-window-days: any # Number of days to use as the conversion attribution window for a pin click action. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `30` days. (default: 30)
  columns: list # Metric and entity columns
  --conversion-product-attribution-type: any #   Required attribution type of the B/C/S report.   When the attribution type is BRAND_ATTRIBUTION, start_date for the report must be after 2025-04-01. (default: DEFAULT)
  --conversion-product-breakdown: any # Report breakdown type. This is used to specify the breakdown of the report by brand, category, or SKU. (default: PRODUCT_BRAND)
  --conversion-report-time: any # The date by which the conversion metrics returned from this endpoint will be reported. There are two dates associated with a conversion event: the date that the user interacted with the ad, and the date that the user completed a conversion event. (default: TIME_OF_AD_ACTION)
  end_date: string #   Metric report end date (UTC). Format: YYYY-MM-DD.   A max of 1 year is allowed between the start and end date for reports. (e.g. 2024-04-23)
  granularity: any # Report granularity for time-based metric aggregation
  level: any # Level of the report
  --product-sku-ids: list #   List of SKU ids.   Only support product_sku_ids field when report breakdown type is PRODUCT_SKU_GROUP. (e.g. [WBC45678, WBC45679])
  report_name: string # Name of the conversion product report
  start_date: string #   Metric report start date (UTC). Format: YYYY-MM-DD.   Start date must be after 2024-03-16. 7 day minimum time window for report is required. (e.g. 2024-04-17)
  --view-window-days: any # Number of days to use as the conversion attribution window for a view action. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `1` day. (default: 30)
]: any -> record<message: string, report_status: record, size: float, token: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/reports/brand_category_sku")
  let body = {ad_group_ids: $ad_group_ids, campaign_ids: $campaign_ids, campaign_objective_types: $campaign_objective_types, click_window_days: $click_window_days, columns: $columns, conversion_product_attribution_type: $conversion_product_attribution_type, conversion_product_breakdown: $conversion_product_breakdown, conversion_report_time: $conversion_report_time, end_date: $end_date, granularity: $granularity, level: $level, product_sku_ids: $product_sku_ids, report_name: $report_name, start_date: $start_date, view_window_days: $view_window_days} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete ads data for ad account in API Sandbox
#
# DELETE /ad_accounts/{ad_account_id}/sandbox
# operationId: sandbox/delete
export def "ad-accounts-sandbox sandbox/delete" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/sandbox")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Schedules
#
# GET /ad_accounts/{ad_account_id}/schedules
# operationId: schedules/list
export def "ad-accounts-schedules schedules/list" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
  --order: string@order-completer # The order in which to sort the items returned: "ASCENDING" or "DESCENDING" by ID. Note that higher-value IDs are associated with more-recently added items.
  --schedule-statuses: list # Filter schedules by status (one or more)
  --schedule-type: string@schedule-type-completer # Filter schedules by a type (e.g. CAMPAIGN_BUDGET_CHANGE)
  --entity-ids: list # List of Entity IDs, must be associated with the Ad Accound ID provided in the path.
]: nothing -> record<bookmark: string, items: table<delta_value: any, end_timestamp: int, entity_id: record, entity_type: record, name: string, schedule_action: record, schedule_id: string, schedule_status: record, schedule_type: record, start_timestamp: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "schedule_statuses" $schedule_statuses "multi") (serialize-qp "schedule_type" $schedule_type "scalar") (serialize-qp "entity_ids" $entity_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create schedules
#
# POST /ad_accounts/{ad_account_id}/schedules
# operationId: schedules/create
export def "ad-accounts-schedules schedules/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<data: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/schedules")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update schedules
#
# PATCH /ad_accounts/{ad_account_id}/schedules
# operationId: schedules/update
export def "ad-accounts-schedules schedules/update" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<data: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/schedules")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Salesforce account details including bill-to information.
#
# GET /ad_accounts/{ad_account_id}/ssio/accounts
# operationId: ssio_accounts/get
export def "ad-accounts-ssio-accounts accounts/get" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<billto_infos: table<addresses: list, id: string, io_terms: string, io_terms_id: string, io_type: string, row_terms: string, row_terms_id: string, us_terms: string, us_terms_id: string>, can_edit: bool, currency: string, eligible: bool, error: string, pmp_names: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ssio/accounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create insertion order through SSIO.
#
# POST /ad_accounts/{ad_account_id}/ssio/insertion_orders
# operationId: ssio_insertion_order/create
export def "ad-accounts-ssio-insertion-orders order/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  accepted_terms_id: string # The SFDC id for the terms
  --accepted-terms-time: int # The UTC timestamp (to the nearest sec) of when terms were accepted
  --agency-link: string # URL link for agency
  billing_contact_email: string # The billing contact email
  billing_contact_firstname: string # The billing contact first name
  billing_contact_lastname: string # The billing contact last name
  billto_billing_address_id: string # The bill-to billing address id
  billto_business_address_id: string # The bill-to business address id
  billto_company_id: string # The bill-to company id
  --budget-amount: float # If Budget order line, the budget amount. (format: double)
  currency_info: string@currency-info-completer # Currency Codes from ISO 4217
  --end-date: string # End date of time period. Format: YYYY-MM-DD
  --estimated-monthly-spend: float # If Ongoing (perpetual) order line, the estimated monthly spend (format: double)
  media_contact_email: string # The media contact email
  media_contact_firstname: string # The media contact first name
  media_contact_lastname: string # The media contact last name
  order_line_type: any # Type can be Budget or Perpetual
  order_name: string # The order name
  pmp_id: string # The pmp id
  po_number: string # The po number
  start_date: string # Starting date of time period. Format: YYYY-MM-DD
  --user-email: string # The email of user submitting the insertion order
]: any -> record<pin_order_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ssio/insertion_orders")
  let body = {accepted_terms_id: $accepted_terms_id, accepted_terms_time: $accepted_terms_time, agency_link: $agency_link, billing_contact_email: $billing_contact_email, billing_contact_firstname: $billing_contact_firstname, billing_contact_lastname: $billing_contact_lastname, billto_billing_address_id: $billto_billing_address_id, billto_business_address_id: $billto_business_address_id, billto_company_id: $billto_company_id, budget_amount: $budget_amount, currency_info: $currency_info, end_date: $end_date, estimated_monthly_spend: $estimated_monthly_spend, media_contact_email: $media_contact_email, media_contact_firstname: $media_contact_firstname, media_contact_lastname: $media_contact_lastname, order_line_type: $order_line_type, order_name: $order_name, pmp_id: $pmp_id, po_number: $po_number, start_date: $start_date, user_email: $user_email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Edit insertion order through SSIO.
#
# PATCH /ad_accounts/{ad_account_id}/ssio/insertion_orders
# operationId: ssio_insertion_order/edit
export def "ad-accounts-ssio-insertion-orders order/edit" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ads-manager-order-line-id: string # Ads manager OrderLineId
  --agency-link: string # URL link for agency
  --billing-contact-email: string # The billing contact email
  --billing-contact-firstname: string # The billing contact first name
  --billing-contact-lastname: string # The billing contact last name
  --budget-amount: float # If Budget order line, the budget amount. (format: double)
  --end-date: string # End date of time period. Format: YYYY-MM-DD
  --media-contact-email: string # The media contact email
  --media-contact-firstname: string # The media contact first name
  --media-contact-lastname: string # The media contact last name
  --oracle-line-id: string # LineId in the Oracle DB
  --po-number: string # The po number
  --salesforce-order-id: string # OrderId in SFDC
  --salesforce-order-line-id: string # OrderLineId in SFDC
  --start-date: string # Starting date of time period. Format: YYYY-MM-DD
  --user-email: string # The email of user submitting the insertion order
]: any -> record<pin_order_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ssio/insertion_orders")
  let body = {ads_manager_order_line_id: $ads_manager_order_line_id, agency_link: $agency_link, billing_contact_email: $billing_contact_email, billing_contact_firstname: $billing_contact_firstname, billing_contact_lastname: $billing_contact_lastname, budget_amount: $budget_amount, end_date: $end_date, media_contact_email: $media_contact_email, media_contact_firstname: $media_contact_firstname, media_contact_lastname: $media_contact_lastname, oracle_line_id: $oracle_line_id, po_number: $po_number, salesforce_order_id: $salesforce_order_id, salesforce_order_line_id: $salesforce_order_line_id, start_date: $start_date, user_email: $user_email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get insertion order status by ad account id.
#
# GET /ad_accounts/{ad_account_id}/ssio/insertion_orders/status
# operationId: ssio_insertion_orders_status/get_by_ad_account
export def "ad-accounts-ssio-insertion-orders-status account" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<creation_time: string, pin_order_id: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ssio/insertion_orders/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get insertion order status by pin order id.
#
# GET /ad_accounts/{ad_account_id}/ssio/insertion_orders/{pin_order_id}/status
# operationId: ssio_insertion_orders_status/get_by_pin_order_id
export def "ad-accounts-ssio-insertion-orders-status id" [
  ad_account_id: string
  pin_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ssio/insertion_orders/($pin_order_id)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Salesforce order lines by ad account id.
#
# GET /ad_accounts/{ad_account_id}/ssio/order_lines
# operationId: ssio_order_lines/get_by_ad_account
export def "ad-accounts-ssio-order-lines account" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pin-order-id: string # The pin order id associated with the SSIO insertion order
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<accepted_terms_id: string, accepted_terms_time: string, ads_manager_order_line_id: string, agency_link: string, bill_to_company_name: string, billing_contact_email: string, billing_contact_firstname: string, billing_contact_lastname: string, budget_amount: float, currency_info: string, end_date: string, estimated_monthly_spend: float, last_modified_date_time: string, media_contact_email: string, media_contact_firstname: string, media_contact_lastname: string, order_name: string, pin_order_id: string, pmp_name: string, po_number: string, salesforce_order_line_id: string, start_date: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pin_order_id" $pin_order_id "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/ssio/order_lines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get targeting analytics for an ad account
#
# GET /ad_accounts/{ad_account_id}/targeting_analytics
# operationId: ad_account_targeting_analytics/get
export def "ad-accounts-targeting-analytics analytics/get" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # Metric report start date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days back from today. (format: date)
  --end-date: string # Metric report end date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days past start_date. (format: date)
  --targeting-types: list # Targeting type breakdowns for the report. The reporting per targeting type is independent from each other. ["AGE_BUCKET_AND_GENDER"] is in BETA and not yet available to all users.
  --columns: list # Columns to retrieve, encoded as a comma-separated string. **NOTE**: Any metrics defined as MICRO_DOLLARS returns a value based on the advertiser profile's currency field. For USD, ($1/1,000,000, or $0.000001 - one one-ten-thousandth of a cent). it's microdollars. Otherwise, it's in microunits of the advertiser's currency.  For example, if the advertiser's currency is GBP (British pound sterling), all MICRO_DOLLARS fields will be in GBP microunits (1/1,000,000 British pound).  If a column has no value, it may not be returned.
  --granularity: string@granularity-completer #   TOTAL - metrics are aggregated over the specified date range.    DAY - metrics are broken down daily.    HOUR - metrics are broken down hourly.    WEEK - metrics are broken down weekly.    MONTH - metrics are broken down monthly
  --click-window-days: float@click-window-days-completer # Number of days to use as the conversion attribution window for a pin click action. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `30` days. (default: 30)
  --engagement-window-days: float@engagement-window-days-completer # Number of days to use as the conversion attribution window for an engagement action. Engagements include saves, closeups, link clicks, and carousel card swipes. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `30` days. **Note:** This parameter no longer returns new data. However, you can still access historic data through **Sept 30, 2027**. (default: 30)
  --view-window-days: float@view-window-days-completer # Number of days to use as the conversion attribution window for a view action. Applies to Pinterest Tag conversion metrics. Prior conversion tags use their defined attribution windows. If not specified, defaults to `1` day. (default: 1)
  --conversion-report-time: string@conversion-report-time-completer # The date by which the conversion metrics returned from this endpoint will be reported. There are two dates associated with a conversion event: the date that the user interacted with the ad, and the date that the user completed a conversion event. (default: TIME_OF_AD_ACTION)
  --attribution-types: list # List of types of attribution for the conversion report
  --reporting-timezone: string@reporting-timezone-completer # Specify the timezone to be applied for the reporting. This feature is currently in BETA and is not available to all users. (e.g. PINTEREST_TIME_ZONE)
]: nothing -> record<data: table<metrics: record, targeting_type: string, targeting_value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "targeting_types" $targeting_types "csv") (serialize-qp "columns" $columns "csv") (serialize-qp "granularity" $granularity "scalar") (serialize-qp "click_window_days" $click_window_days "scalar") (serialize-qp "engagement_window_days" $engagement_window_days "scalar") (serialize-qp "view_window_days" $view_window_days "scalar") (serialize-qp "conversion_report_time" $conversion_report_time "scalar") (serialize-qp "attribution_types" $attribution_types "csv") (serialize-qp "reporting_timezone" $reporting_timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/targeting_analytics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List targeting templates
#
# GET /ad_accounts/{ad_account_id}/targeting_templates
# operationId: targeting_template/list
export def "ad-accounts-targeting-templates template/list" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
  --order: string@order-completer # The order in which to sort the items returned: "ASCENDING" or "DESCENDING" by ID. Note that higher-value IDs are associated with more-recently added items.
  --include-sizing: oneof<nothing, bool> # Include audience sizing in result or not (default: false)
  --search-query: string # Search query. Can contain pin description keywords or comma-separated pin IDs.
]: nothing -> record<bookmark: string, items: table<ad_account_id: string, auto_targeting_enabled: bool, created_time: int, id: string, keywords: list, name: string, placement_group: string, sizing: record, status: record, targeting_attributes: record, tracking_urls: record, updated_time: int, valid: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "include_sizing" $include_sizing "scalar") (serialize-qp "search_query" $search_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/targeting_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create targeting templates
#
# POST /ad_accounts/{ad_account_id}/targeting_templates
# operationId: targeting_template/create
# --keywords item shape: {match_type?: "BROAD"|"PHRASE"|"EXACT"|"EXACT_NEGATIVE"|"PHRASE_NEGATIVE", value?: string}
# --tracking_urls shape: {audience_verification?: list, buyable_button?: list, click?: list, engagement?: list, impression?: list}
export def "ad-accounts-targeting-templates template/create" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auto-targeting-enabled: oneof<nothing, bool> # Enable auto-targeting for ad group. Also known as ["expanded targeting"](https://help.pinterest.com/en/business/article/expanded-targeting). (default: true)
  --keywords: list # item shape: {match_type?: "BROAD"|"PHRASE"|"EXACT"|"EXACT_NEGATIVE"|"PHRASE_NEGATIVE", value?: string}
  name: string # targeting template name
  --placement-group: string@placement-group-completer # Campaign placement group type (default: ALL, e.g. ALL)
  targeting_attributes: any # targeting profile attributes
  --tracking-urls: record #   Third-party tracking URLs. Up to three tracking URLs - with a max length of 2,000 - are supported for   each event type. Tracking URLs set at the ad group or ad level can override   those set at the campaign level. For more information, see [Third-party and dynamic tracking](https://help.pinterest.com/en/business/article/third-party-and-dynamic-tracking). (nullable, e.g. {impression: [URL1, URL2], click: [URL1, URL2], engagement: [URL1, URL2], buyable_button: [URL1, URL2], audience_verification: [URL1, URL2]}) — shape: {audience_verification?: list, buyable_button?: list, click?: list, engagement?: list, impression?: list}
]: any -> record<ad_account_id: string, auto_targeting_enabled: bool, created_time: int, id: string, keywords: table<match_type: string, value: string>, name: string, placement_group: string, sizing: record<reach_estimate: record<estimate: int, lower_bound: int, upper_bound: int>>, status: record, targeting_attributes: record<AGE_BUCKET: list<string>, APPTYPE: list<string>, AUDIENCE_EXCLUDE: list<string>, AUDIENCE_INCLUDE: list<string>, GENDER: list<string>, GEO: list<string>, GEO_EXCLUDE: list<string>, INTEREST: list<string>, LOCALE: list<string>, LOCATION: list<string>, LOCATION_EXCLUDE: list<string>, MAXIMUM_AGE: string, MINIMUM_AGE: string, SHOPPING_RETARGETING: list<record>, TARGETING_STRATEGY: list<string>>, tracking_urls: record<audience_verification: list<string>, buyable_button: list<string>, click: list<string>, engagement: list<string>, impression: list<string>>, updated_time: int, valid: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/targeting_templates")
  let body = {auto_targeting_enabled: $auto_targeting_enabled, keywords: $keywords, name: $name, placement_group: $placement_group, targeting_attributes: $targeting_attributes, tracking_urls: $tracking_urls} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update targeting templates
#
# PATCH /ad_accounts/{ad_account_id}/targeting_templates
# operationId: targeting_template/update
export def "ad-accounts-targeting-templates template/update" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string # Targeting template ID (e.g. 643)
  operation_type: string@operation-type-completer-1 # Audience operation type (update or remove). (e.g. UPDATE)
  --targeting-attributes: any # targeting profile attributes
]: any -> record<code: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/targeting_templates")
  let body = {id: $id, operation_type: $operation_type, targeting_attributes: $targeting_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List templates
#
# GET /ad_accounts/{ad_account_id}/templates
# operationId: templates/list
export def "ad-accounts-templates templates/list" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
  --order: string@order-completer # The order in which to sort the items returned: "ASCENDING" or "DESCENDING" by ID. Note that higher-value IDs are associated with more-recently added items.
]: nothing -> record<bookmark: string, items: table<ad_account_id: string, ad_account_ids: list, ade_columns: list, attribution_type: any, click_window_days: float, columns: list, conversion_report_time_type: record, creation_source: record, custom_column_ids: list, display_metadata: string, engagement_window_days: float, filters_json: string, granularity: string, id: string, ingestion_sources: list, is_default: bool, is_deleted: bool, is_owned_by_user: bool, is_scheduled: bool, name: string, report_end_relative_days_in_past: float, report_format: string, report_level: string, report_start_relative_days_in_past: float, reporting_time_zone: record, sort_by: any, type: string, updated_time: float, user_id: string, view_window_days: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create async request for an analytics report using a template
#
# POST /ad_accounts/{ad_account_id}/templates/{template_id}/reports
# operationId: analytics/create_template_report
export def "ad-accounts-templates-reports report" [
  ad_account_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # Metric report start date (UTC). Format: YYYY-MM-DD. Cannot be more than 2.5 years back from today. (format: date)
  --end-date: string # Metric report end date (UTC). Format: YYYY-MM-DD. Cannot be more than 2.5 years past start date. (format: date)
  --granularity: string@granularity-completer #   TOTAL - metrics are aggregated over the specified date range.    DAY - metrics are broken down daily.    HOUR - metrics are broken down hourly.    WEEK - metrics are broken down weekly.    MONTH - metrics are broken down monthly
]: nothing -> record<message: string, report_status: string, template_id: string, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "granularity" $granularity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/templates/($template_id)/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get terms of service
#
# GET /ad_accounts/{ad_account_id}/terms_of_service
# operationId: terms_of_service/get
export def "ad-accounts-terms-of-service service/get" [
  ad_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-html: oneof<nothing, bool> # Return HTML in TOS text. (default: false)
  --tos-type: string # Request type.
]: nothing -> record<ad_account_id: string, has_accepted: bool, html: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_html" $include_html "scalar") (serialize-qp "tos_type" $tos_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_accounts/($ad_account_id)/terms_of_service" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get item bid options (POST)
#
# POST /advanced_auction/items/get
# operationId: advanced_auction_items_get/post
# --items item shape: {country: "AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", item_id: string, language: "AM"|"AR"|"AZ"|"BG"|"BN"|"BS"|"CA"|"CS"|"DA"|"DV"|"DZ"|"DE"|"EL"|"EN"|"ES"|"ET"|"FA"|"FI"|"FR"|"HE"|"HI"|"HR"|"HU"|"HY"|"ID"|"IN"|"IS"|"IT"|"IW"|"JA"|"KA"|"KM"|"KO"|"LO"|"LT"|"LV"|"MK"|"MN"|"MS"|"MY"|"NB"|"NE"|"NL"|"NO"|"PL"|"PT"|"RO"|"RU"|"SK"|"SL"|"SQ"|"SR"|"SV"|"TL"|"UK"|"VI"|"TE"|"TH"|"TR"|"XX"|"ZH"}
export def "advanced-auction-items-get get/post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  catalog_id: any # Catalog id pertaining to the retail item (e.g. 2680059592705)
  items: list # A list of retail catalog items to fetch bid options for — item shape: {country: "AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", item_id: string, language: "AM"|"AR"|"AZ"|"BG"|"BN"|"BS"|"CA"|"CS"|"DA"|"DV"|"DZ"|"DE"|"EL"|"EN"|"ES"|"ET"|"FA"|"FI"|"FR"|"HE"|"HI"|"HR"|"HU"|"HY"|"ID"|"IN"|"IS"|"IT"|"IW"|"JA"|"KA"|"KM"|"KO"|"LO"|"LT"|"LV"|"MK"|"MN"|"MS"|"MY"|"NB"|"NE"|"NL"|"NO"|"PL"|"PT"|"RO"|"RU"|"SK"|"SL"|"SQ"|"SR"|"SV"|"TL"|"UK"|"VI"|"TE"|"TH"|"TR"|"XX"|"ZH"}
]: any -> record<catalog_id: record, items: table<bid_options: record, country: string, item_id: string, language: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/advanced_auction/items/get" $qp)
  let body = {catalog_id: $catalog_id, items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Operate on item level bid options
#
# POST /advanced_auction/items/submit
# operationId: advanced_auction_items_submit/post
export def "advanced-auction-items-submit submit/post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  catalog_id: any # Catalog id pertaining to all items (e.g. 2680059592705)
  items: list # Array of item bid option operations
]: any -> record<catalog_id: record, items: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/advanced_auction/items/submit" $qp)
  let body = {catalog_id: $catalog_id, items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create board
#
# POST /boards
# operationId: boards/create
export def "boards boards/create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --description: string # nullable, e.g. My favorite summer recipes
  --is-ads-only: oneof<nothing, bool> # If set to `true`, the board will be ad-only and can store ad-only Pins. (default: false, e.g. true)
  name: string #     Name of the board.      **Note:** If you create an ad-only board by setting `is_ads_only`     to `true`, the board name automatically becomes "Ad-only Pins". (e.g. Summer recipes)
  --privacy: any #     Privacy setting for a board. Learn more about [secret](https://help.pinterest.com/en/article/secret-boards)     boards and [protected](https://help.pinterest.com/en/business/article/protected-boards) boards.      **Note:** If you create an ad-only board by setting `is_ads_only`     to `true`, the `privacy` settng automatically becomes `PROTECTED`.  (default: PUBLIC)
]: any -> record<privacy: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boards" $qp)
  let body = {description: $description, is_ads_only: $is_ads_only, name: $name, privacy: $privacy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List boards
#
# GET /boards
# operationId: boards/list
export def "boards boards/list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --privacy: string@privacy-completer # The privacy level of the board
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<privacy: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar") (serialize-qp "privacy" $privacy "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get board
#
# GET /boards/{board_id}
# operationId: boards/get
export def "boards boards/get" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
]: nothing -> record<privacy: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($board_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete board
#
# DELETE /boards/{board_id}
# operationId: boards/delete
export def "boards boards/delete" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
]: nothing -> record<privacy: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($board_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update board
#
# PATCH /boards/{board_id}
# operationId: boards/update
export def "boards boards/update" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --description: string # nullable, e.g. My favorite summer recipes
  --name: string #     Name of the board.      **Note:** If you create an ad-only board by setting `is_ads_only`     to `true`, the board name automatically becomes "Ad-only Pins". (e.g. Summer recipes)
  --privacy: string@privacy-completer-1
]: any -> record<privacy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($board_id)" $qp)
  let body = {description: $description, name: $name, privacy: $privacy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Pins on board
#
# GET /boards/{board_id}/pins
# operationId: boards/list_pins
export def "boards-pins pins" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --creative-types: list # Pin creative types filter. **Note:** SHOP_THE_PIN has been deprecated. Please use COLLECTION instead.
  --ad-account-id: string # Unique identifier of an ad account.
  --pin-metrics: oneof<nothing, bool> # Specify whether to return 90d and lifetime Pin metrics. Total comments and total reactions are only available with lifetime Pin metrics. If Pin was created before `2023-03-20` lifetime metrics will only be available for Video and Idea Pin formats. Lifetime metrics are available for all Pin formats since then. (default: false)
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<alt_text: string, description: string, link: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "creative_types" $creative_types "multi") (serialize-qp "ad_account_id" $ad_account_id "scalar") (serialize-qp "pin_metrics" $pin_metrics "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($board_id)/pins" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List board sections
#
# GET /boards/{board_id}/sections
# operationId: board_sections/list
export def "boards-sections sections/list" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($board_id)/sections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create board section
#
# POST /boards/{board_id}/sections
# operationId: board_sections/create
export def "boards-sections sections/create" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --id: string # e.g. 549755885175
  name: string # e.g. Salads
]: any -> record<id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($board_id)/sections" $qp)
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete board section
#
# DELETE /boards/{board_id}/sections/{section_id}
# operationId: board_sections/delete
export def "boards-sections sections/delete" [
  board_id: string
  section_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($board_id)/sections/($section_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update board section
#
# PATCH /boards/{board_id}/sections/{section_id}
# operationId: board_sections/update
export def "boards-sections sections/update" [
  board_id: string
  section_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --id: string # e.g. 549755885175
  name: string # e.g. Salads
]: any -> record<id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($board_id)/sections/($section_id)" $qp)
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Pins on board section
#
# GET /boards/{board_id}/sections/{section_id}/pins
# operationId: board_sections/list_pins
export def "boards-sections-pins pins" [
  board_id: string
  section_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<alt_text: string, description: string, link: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/boards/($board_id)/sections/($section_id)/pins" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Brand Account
#
# POST /business_access/business_hierarchy/{business_hierarchy_id}/brand_accounts
# operationId: brand_accounts/create
# --profile_image shape: {content_type: "image/jpeg"|"image/png", data: string}
export def "business-access-business-hierarchy-brand-accounts accounts/create" [
  business_hierarchy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --about: string # Brand Account about information
  country: string@country-completer # Country ID from ISO 3166-1 alpha-2.
  name: string # Brand Account name
  --profile-image: record # Base64-encoded image media source — shape: {content_type: "image/jpeg"|"image/png", data: string}
  username: string # Brand Account username
  --website: string # Brand Account website
]: any -> record<brand_account_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/business_access/business_hierarchy/($business_hierarchy_id)/brand_accounts")
  let body = {about: $about, country: $country, name: $name, profile_image: $profile_image, username: $username, website: $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a Brand Account
#
# PATCH /business_access/business_hierarchy/{business_hierarchy_id}/brand_accounts/{brand_account_id}
# operationId: brand_accounts/update
# --profile_image shape: {content_type?: "image/jpeg"|"image/png", data?: string}
export def "business-access-business-hierarchy-brand-accounts accounts/update" [
  brand_account_id: string
  business_hierarchy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --about: string # Brand Account about information
  --country: string@country-completer # Country ID from ISO 3166-1 alpha-2.
  --name: string # Brand Account name
  --profile-image: record # Base64-encoded image media source — shape: {content_type?: "image/jpeg"|"image/png", data?: string}
  --username: string # Brand Account username
  --website: string # Brand Account website
]: any -> record<brand_account_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/business_access/business_hierarchy/($business_hierarchy_id)/brand_accounts/($brand_account_id)")
  let body = {about: $about, country: $country, name: $name, profile_image: $profile_image, username: $username, website: $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List business employers for user
#
# GET /businesses/employers
# operationId: get/business_employers
export def "businesses-employers employers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --assets-summary: oneof<nothing, bool> # Include assets summary in the response if this is true. Defaults to true.  The assets summary returns a dictionary representing a summary of the assets for the business user ID, with information like the ad accounts and profiles the user has permissions for and what those permissions are (default: true)
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<assets_summary: record, business_roles: list, created_by_business: record, created_by_user: record, created_time: int, id: string, is_shared_partner: bool, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assets_summary" $assets_summary "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/businesses/employers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept or decline an invite/request
#
# PATCH /businesses/invites
# operationId: respond_business_access_invites
# --invites item shape: {action: record, invite_id: string}
export def "businesses-invites invites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  invites: list # item shape: {action: record, invite_id: string}
]: any -> record<items: table<exception: record, invite: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/businesses/invites")
  let body = {invites: $invites} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new asset group.
#
# POST /businesses/{business_id}/asset_groups
# operationId: asset_group/create
# --asset_group shape: {ad_accounts_ids: list, asset_group_description: string, asset_group_name: string, asset_group_types: list, catalogs_ids: list, created_by: any, created_time: int, id: string, owner: any, profiles_ids: list, updated_time: int}
export def "businesses-asset-groups group/create" [
  business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset-group: record # shape: {ad_accounts_ids: list, asset_group_description: string, asset_group_name: string, asset_group_types: list, catalogs_ids: list, created_by: any, created_time: int, id: string, owner: any, profiles_ids: list, updated_time: int}
  asset_group_description: string # Asset group description. (e.g. Asset groups that has ad accounts shared in Canada)
  asset_group_name: string # Asset Group name. (e.g. Canada Ad Accounts)
  asset_group_types: list # Asset Group Types. Note: The asset group types are used for user reference and categorization purposes only and do not impact the functionality of the asset group. (e.g. [BRAND, LOCATION_OR_LANGUAGE, PRODUCT_LINE, OTHER])
]: any -> record<asset_group: record<ad_accounts_ids: list<string>, asset_group_description: string, asset_group_name: string, asset_group_types: list<string>, catalogs_ids: list<string>, created_by: record<email: string, id: string, username: string>, created_time: int, id: string, owner: record<email: string, id: string, username: string>, profiles_ids: list<string>, updated_time: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/businesses/($business_id)/asset_groups")
  let body = {asset_group: $asset_group, asset_group_description: $asset_group_description, asset_group_name: $asset_group_name, asset_group_types: $asset_group_types} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update asset groups.
#
# PATCH /businesses/{business_id}/asset_groups
# operationId: asset_group/update
# --asset_groups_to_update item shape: {asset_group_id: string, asset_group_types?: list, assets_to_add?: list, assets_to_remove?: list, description?: string, name?: string}
# --exceptions item shape: {asset_group_id?: string, code?: int, message?: string}
# --updated_asset_groups item shape: {ad_accounts_ids: list, asset_group_description: string, asset_group_name: string, asset_group_types: list, catalogs_ids: list, created_by: any, created_time: int, id: string, owner: any, profiles_ids: list, updated_time: int}
export def "businesses-asset-groups group/update" [
  business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset-groups-to-update: list # A list of asset groups and the data that will be used to update them. — item shape: {asset_group_id: string, asset_group_types?: list, assets_to_add?: list, assets_to_remove?: list, description?: string, name?: string}
]: any -> record<exceptions: table<asset_group_id: string, code: int, message: string>, updated_asset_groups: table<ad_accounts_ids: list, asset_group_description: string, asset_group_name: string, asset_group_types: list, catalogs_ids: list, created_by: record, created_time: int, id: string, owner: record, profiles_ids: list, updated_time: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/businesses/($business_id)/asset_groups")
  let body = {asset_groups_to_update: $asset_groups_to_update} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete asset groups.
#
# DELETE /businesses/{business_id}/asset_groups
# operationId: asset_group/delete
export def "businesses-asset-groups group/delete" [
  business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  asset_groups_to_delete: list
]: any -> record<deleted_asset_groups: list<string>, exceptions: table<asset_group_id: string, code: int, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/businesses/($business_id)/asset_groups")
  let body = {asset_groups_to_delete: $asset_groups_to_delete} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List business assets
#
# GET /businesses/{business_id}/assets
# operationId: business_assets/get
export def "businesses-assets assets/get" [
  business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permissions: list # A list of asset permissions used to filter the assets. Only assets where the requesting business has at least one of the specified permissions will be returned.
  --child-asset-id: string # A child asset unique identifier. Used to fetch asset groups that contain the asset id as a child.
  --asset-group-id: string # An asset group unique identifier. Used to fetch assets contained within the specified asset group.
  --asset-type: string@asset-type-completer # A resource type to filter the assets by. Only assets of the specified type will be returned. (default: AD_ACCOUNT)
  --start-index: int # An index to start fetching the results from. Only the results starting from this index will be returned. (default: 0)
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<catalog_info: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permissions" $permissions "multi") (serialize-qp "child_asset_id" $child_asset_id "scalar") (serialize-qp "asset_group_id" $asset_group_id "scalar") (serialize-qp "asset_type" $asset_type "scalar") (serialize-qp "start_index" $start_index "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/businesses/($business_id)/assets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get members with access to asset
#
# GET /businesses/{business_id}/assets/{asset_id}/members
# operationId: business_asset_members/get
export def "businesses-assets-members members/get" [
  business_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-index: int # An index to start fetching the results from. Only the results starting from this index will be returned. (default: 0)
  --fetch-system-users: oneof<nothing, bool> # Fetches system users if True. Fetches regular user employees if False. (default: false)
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<permissions: list, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_index" $start_index "scalar") (serialize-qp "fetch_system_users" $fetch_system_users "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/businesses/($business_id)/assets/($asset_id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get partners with access to asset
#
# GET /businesses/{business_id}/assets/{asset_id}/partners
# operationId: business_asset_partners/get
export def "businesses-assets-partners partners/get" [
  business_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-index: int # An index to start fetching the results from. Only the results starting from this index will be returned. (default: 0)
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<permissions: list, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_index" $start_index "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/businesses/($business_id)/assets/($asset_id)/partners" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List received audiences for a business
#
# GET /businesses/{business_id}/audiences
# operationId: shared_audiences_for_business/list
export def "businesses-audiences business/list" [
  business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string@order-completer # The order in which to sort the items returned: "ASCENDING" or "DESCENDING" by ID. Note that higher-value IDs are associated with more-recently added items.
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<ad_account_id: string, audience_type: record, created_by_company_name: string, created_timestamp: int, description: string, id: string, is_nca: bool, name: string, rule: record, size: int, status: record, type: string, updated_timestamp: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/businesses/($business_id)/audiences" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update audience sharing from a business to ad accounts
#
# PATCH /businesses/{business_id}/audiences/ad_accounts/shared
# operationId: update_business_to_ad_account_shared_audience
export def "businesses-audiences-ad-accounts-shared audience" [
  business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  audience_id: any # Unique identifier of an audience (e.g. 2542621871096)
  operation_type: string@operation-type-completer # Operation type to share a specific audience or revoke access to a previously shared audience
  recipient_account_ids: list # Ad account IDs to share with or revoke from (request) / that received the audience (response).
]: any -> record<audience_id: record, permissions: list<string>, recipient_account_ids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/businesses/($business_id)/audiences/ad_accounts/shared")
  let body = {audience_id: $audience_id, operation_type: $operation_type, recipient_account_ids: $recipient_account_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update audience sharing between businesses
#
# PATCH /businesses/{business_id}/audiences/businesses/shared
# operationId: update_business_to_business_shared_audience
export def "businesses-audiences-businesses-shared audience" [
  business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  audience_id: any # Unique identifier of an audience (e.g. 2542621871096)
  operation_type: string@operation-type-completer # Operation type to share a specific audience or revoke access to a previously shared audience
  recipient_business_ids: list # Business IDs to share with or revoke from (request) / that received the audience (response).
]: any -> record<audience_id: record, permissions: list<string>, recipient_business_ids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/businesses/($business_id)/audiences/businesses/shared")
  let body = {audience_id: $audience_id, operation_type: $operation_type, recipient_business_ids: $recipient_business_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List accounts with access to an audience owned by a business
#
# GET /businesses/{business_id}/audiences/shared/accounts
# operationId: business_account_audiences_shared_accounts/list
export def "businesses-audiences-shared-accounts accounts/list" [
  business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --audience-id: string # Unique identifier of the audience to use to filter the results.
  --account-type: string@account-type-completer # Filter accounts by account type.
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<account_id: string, account_name: string, account_type: record, shared_on_timestamp: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "audience_id" $audience_id "scalar") (serialize-qp "account_type" $account_type "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/businesses/($business_id)/audiences/shared/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get invites/requests
#
# GET /businesses/{business_id}/invites
# operationId: get/invites
export def "businesses-invites get/invites" [
  business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --is-member: oneof<nothing, bool> # A boolean field to indicate whether the invite is to create a partnership or a membership. (default: true)
  --invite-status: list # A list of invite statuses to filter invites by. Only invites whose status is in the provided statuses will be returned.
  --invite-type: string@invite-type-completer # Invite type to filter invites by. Only invites of the specified type will be returned. (e.g. MEMBER_INVITE)
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<assets_summary: record, business_roles: list, created_by_business: record, created_by_user: record, created_time: int, id: string, invite_data: record, is_received_invite: bool, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "is_member" $is_member "scalar") (serialize-qp "invite_status" $invite_status "multi") (serialize-qp "invite_type" $invite_type "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/businesses/($business_id)/invites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create invites or requests
#
# POST /businesses/{business_id}/invites
# operationId: create_membership_or_partnership_invites
export def "businesses-invites invites-by-business_id" [
  business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  business_role: any # e.g. BIZ_ADMIN
  invite_type: string@invite-type-completer # The type of invite. MEMBER_INVITE invites a member to access your business assets. PARTNER_INVITE invites a partner to access your business assets. PARTNER_REQUEST requests access to a partner's business assets. (e.g. MEMBER_INVITE)
  --members: list # A list of usernames, emails, or a mix of them. Should be used if invite_type is MEMBER_INVITE (e.g. [business0101, user@business.com])
  --partners: list # A list of partner_id. Should be used if invite_type is PARTNER_INVITE or PARTNER_REQUEST (e.g. [809944451643622187, 766456567741825556])
]: any -> record<items: table<exception: record, invite: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/businesses/($business_id)/invites")
  let body = {business_role: $business_role, invite_type: $invite_type, members: $members, partners: $partners} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel invites/requests
#
# DELETE /businesses/{business_id}/invites
# operationId: cancel_invites_or_requests
export def "businesses-invites requests" [
  business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  invite_ids: list # A list of invite/request ids to cancel.
]: any -> record<items: table<exception: record, invite: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/businesses/($business_id)/invites")
  let body = {invite_ids: $invite_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update invite/request with an asset permission
#
# POST /businesses/{business_id}/invites/assets/access
# operationId: create_asset_invites
# --invites item shape: {asset_id_to_permissions: record, invite_id: string, invite_type: "MEMBER_INVITE"|"PARTNER_INVITE"|"PARTNER_REQUEST"}
export def "businesses-invites-assets-access invites" [
  business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  invites: list # item shape: {asset_id_to_permissions: record, invite_id: string, invite_type: "MEMBER_INVITE"|"PARTNER_INVITE"|"PARTNER_REQUEST"}
]: any -> record<items: table<exception: record, invite: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/businesses/($business_id)/invites/assets/access")
  let body = {invites: $invites} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get business members
#
# GET /businesses/{business_id}/members
# operationId: get/business_members
export def "businesses-members members" [
  business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fetch-system-users: oneof<nothing, bool> # Fetches system users if True. Fetches regular user employees if False. (default: false)
  --assets-summary: oneof<nothing, bool> # Include assets summary in the response if this is true.  The assets summary returns a dictionary representing a summary of the assets for the business user ID, with information like the ad accounts and profiles the user has permissions for and what those permissions are (default: false)
  --business-roles: list # A list of business roles to filter the members by. Only members whose roles are in the specified roles will be returned.
  --member-ids: string # A list of business members ids separated by comma.
  --start-index: int # An index to start fetching the results from. Only the results starting from this index will be returned. (default: 0)
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<assets_summary: record, business_roles: list, created_by_business: record, created_by_user: record, created_time: int, id: string, is_shared_partner: bool, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fetch_system_users" $fetch_system_users "scalar") (serialize-qp "assets_summary" $assets_summary "scalar") (serialize-qp "business_roles" $business_roles "multi") (serialize-qp "member_ids" $member_ids "scalar") (serialize-qp "start_index" $start_index "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/businesses/($business_id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Terminate business memberships
#
# DELETE /businesses/{business_id}/members
# operationId: delete_business_membership
# --members item shape: {business_role: "EMPLOYEE"|"BIZ_ADMIN", member_id: string}
export def "businesses-members membership" [
  business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  members: list # item shape: {business_role: "EMPLOYEE"|"BIZ_ADMIN", member_id: string}
]: any -> record<deleted_members: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/businesses/($business_id)/members")
  let body = {members: $members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update member's business role
#
# PATCH /businesses/{business_id}/members
# operationId: update/business_memberships
export def "businesses-members memberships" [
  business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<items: table<business_role: string, member_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/businesses/($business_id)/members")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign/Update member asset permissions
#
# PATCH /businesses/{business_id}/members/assets/access
# operationId: business_members_asset_access/update
# --accesses item shape: {asset_id: string, member_id: string, permissions: list}
export def "businesses-members-assets-access access/update" [
  business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  accesses: list # List of member asset accesses to assign or update. — item shape: {asset_id: string, member_id: string, permissions: list}
]: any -> record<items: table<response: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/businesses/($business_id)/members/assets/access")
  let body = {accesses: $accesses} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete member access to asset
#
# DELETE /businesses/{business_id}/members/assets/access
# operationId: business_members_asset_access/delete
# --accesses item shape: {asset_id: string, member_id: string}
export def "businesses-members-assets-access access/delete" [
  business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  accesses: list # List of members asset access to be deleted — item shape: {asset_id: string, member_id: string}
]: any -> record<items: table<asset_id: string, member_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/businesses/($business_id)/members/assets/access")
  let body = {accesses: $accesses} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get assets assigned to a member
#
# GET /businesses/{business_id}/members/{member_id}/assets
# operationId: business_member_assets/get
export def "businesses-members-assets assets/get" [
  business_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset-type: string@asset-type-completer-1 # A resource type to filter the assets by. Only assets of the specified type will be returned. (default: AD_ACCOUNT)
  --start-index: int # An index to start fetching the results from. Only the results starting from this index will be returned. (default: 0)
  --sort-by: string@sort-by-completer # The field to sort member assets by (e.g. NAME)
  --sort-ascending: oneof<nothing, bool> # Sort assets in ascending order (default: true)
  --search-by: string@search-by-completer # The field to search member assets by (e.g. NAME)
  --search-value: string # The value to search for
  --asset-permission-type: string@asset-permission-type-completer # The type of asset permission to filter by (e.g. AGGREGATED_PERMISSION)
  --ad-account-statuses: list # A list of ad account statuses to filter the assets by. Only used when asset_type is AD_ACCOUNT.
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<asset_group_info: record, asset_id: string, asset_type: string, permissions: list>, total_data_count: int, total_data_count_by_status: record<ACTIVE: int, ARCHIVED: int, PAUSED: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset_type" $asset_type "scalar") (serialize-qp "start_index" $start_index "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_ascending" $sort_ascending "scalar") (serialize-qp "search_by" $search_by "scalar") (serialize-qp "search_value" $search_value "scalar") (serialize-qp "asset_permission_type" $asset_permission_type "scalar") (serialize-qp "ad_account_statuses" $ad_account_statuses "multi") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/businesses/($business_id)/members/($member_id)/assets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get business partners
#
# GET /businesses/{business_id}/partners
# operationId: get/business_partners
export def "businesses-partners partners-by-business_id" [
  business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --assets-summary: oneof<nothing, bool> # Include assets summary in the response if this is true.  The assets summary returns a dictionary representing a summary of the assets for the business user ID, with information like the ad accounts and profiles the user has permissions for and what those permissions are (default: false)
  --partner-type: string@partner-type-completer # Specifies whether to fetch internal or external (shared) partners. If partner_type=INTERNAL, the asset being queried is for accesses the partner has to your business assets. If partner_type=EXTERNAL, the asset being queried is for the accesses you have to the partner's business asset. (e.g. INTERNAL)
  --partner-ids: string # A list of business partner ids separated by commas used to filter the results. Only partners with the specified ids will be returned.
  --start-index: int # An index to start fetching the results from. Only the results starting from this index will be returned. (default: 0)
  --sort-ascending: oneof<nothing, bool> # Sort ascending.
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<assets_summary: record, business_roles: list, created_by_business: record, created_by_user: record, created_time: int, id: string, is_shared_partner: bool, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assets_summary" $assets_summary "scalar") (serialize-qp "partner_type" $partner_type "scalar") (serialize-qp "partner_ids" $partner_ids "scalar") (serialize-qp "start_index" $start_index "scalar") (serialize-qp "sort_ascending" $sort_ascending "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/businesses/($business_id)/partners" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Terminate business partnerships
#
# DELETE /businesses/{business_id}/partners
# operationId: delete_business_partners
export def "businesses-partners partners-by-business_id-1" [
  business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  partner_ids: list # A list of partner ids to be deleted
  --partner-type: any # nullable
]: any -> record<deleted_partners: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/businesses/($business_id)/partners")
  let body = {partner_ids: $partner_ids, partner_type: $partner_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign/Update partner asset permissions
#
# PATCH /businesses/{business_id}/partners/assets
# operationId: update_partner_asset_access_handler_impl
# --accesses item shape: {asset_id: string, partner_id: string, permissions: list}
export def "businesses-partners-assets impl-by-business_id" [
  business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  accesses: list # List of partner asset accesses to assign or update. — item shape: {asset_id: string, partner_id: string, permissions: list}
]: any -> record<items: table<asset_id: string, asset_type: string, partner_id: string, permissions: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/businesses/($business_id)/partners/assets")
  let body = {accesses: $accesses} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete partner access to asset
#
# DELETE /businesses/{business_id}/partners/assets
# operationId: delete_partner_asset_access_handler_impl
# --accesses item shape: {asset_id: string, partner_id: string, partner_type?: "INTERNAL"|"EXTERNAL"}
export def "businesses-partners-assets impl-by-business_id-1" [
  business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  accesses: list # List of partner asset accesses to delete. — item shape: {asset_id: string, partner_id: string, partner_type?: "INTERNAL"|"EXTERNAL"}
]: any -> record<items: table<asset_id: string, asset_type: string, is_shared_partner: bool, partner_id: string, permissions: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/businesses/($business_id)/partners/assets")
  let body = {accesses: $accesses} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get assets assigned to a partner or assets assigned by a partner
#
# GET /businesses/{business_id}/partners/{partner_id}/assets
# operationId: business_partner_asset_access/get
export def "businesses-partners-assets access/get" [
  business_id: string
  partner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --partner-type: string@partner-type-completer # Specifies whether to fetch internal or external (shared) partners.  If partner_type=INTERNAL, the asset being queried is for accesses the partner has to your business assets.  If partner_type=EXTERNAL, the asset being queried is for the accesses you have to the partner's business asset. (default: INTERNAL)
  --asset-type: string@asset-type-completer-2 # A resource type to filter the assets by. Only assets of the specified type will be returned. (default: AD_ACCOUNT)
  --start-index: int # An index to start fetching the results from. Only the results starting from this index will be returned. (default: 0)
  --sort-by: string@sort-by-completer # The field to sort member assets by (e.g. NAME)
  --sort-ascending: oneof<nothing, bool> # Sort assets in ascending order (default: true)
  --search-by: string@search-by-completer # The field to search member assets by (e.g. NAME)
  --search-value: string # The value to search for
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<asset_group_info: record, asset_id: string, asset_type: string, permissions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "partner_type" $partner_type "scalar") (serialize-qp "asset_type" $asset_type "scalar") (serialize-qp "start_index" $start_index "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_ascending" $sort_ascending "scalar") (serialize-qp "search_by" $search_by "scalar") (serialize-qp "search_value" $search_value "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/businesses/($business_id)/partners/($partner_id)/assets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a request to access an existing partner's assets.
#
# POST /businesses/{business_id}/requests/assets/access
# operationId: asset_access_requests/create
# --asset_requests item shape: {asset_id_to_permissions: record, partner_id: string}
export def "businesses-requests-assets-access requests/create" [
  business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  asset_requests: list # item shape: {asset_id_to_permissions: record, partner_id: string}
]: any -> record<exceptions: table<code: int, messages: list>, invites: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/businesses/($business_id)/requests/assets/access")
  let body = {asset_requests: $asset_requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a system user information.
#
# PATCH /businesses/{business_id}/system_users/{system_user_id}
# operationId: system_user/update
export def "businesses-system-users user/update" [
  business_id: string
  system_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # New system user name
]: any -> record<code: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/businesses/($business_id)/system_users/($system_user_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List catalogs
#
# GET /catalogs
# operationId: catalogs/list
export def "catalogs catalogs/list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<catalog_type: string, created_at: string, id: string, name: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/catalogs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create catalog
#
# POST /catalogs
# operationId: catalogs/create
export def "catalogs catalogs/create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  catalog_type: string@catalog-type-completer # Type of the catalog entity.
  name: string # A human-friendly name associated to a catalog entity.
]: any -> record<catalog_type: string, created_at: string, id: string, name: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/catalogs" $qp)
  let body = {catalog_type: $catalog_type, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List available filter values
#
# GET /catalogs/available_filter_values
# Discriminator (response): catalog_type = RETAIL, HOTEL, CREATIVE_ASSETS
# operationId: catalogs/available_filter_values
export def "catalogs-available-filter-values values" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --catalog-id: string # Filter entities for a given catalog_id.
  --feed-id: string # Filter entities for a given feed_id. If not given, all feeds are considered.
  --country: string@country-completer # Country for the Catalogs Items
  --language: string@language-completer # Language for the Catalogs Items
  --ad-account-id: string # Unique identifier of an ad account.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "catalog_id" $catalog_id "scalar") (serialize-qp "feed_id" $feed_id "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/catalogs/available_filter_values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List feeds
#
# GET /catalogs/feeds
# operationId: feeds/list
export def "catalogs-feeds feeds/list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --catalog-id: string # Filter entities for a given catalog_id. If not given, all catalogs are considered.
  --ad-account-id: string # Unique identifier of an ad account.
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "catalog_id" $catalog_id "scalar") (serialize-qp "ad_account_id" $ad_account_id "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/catalogs/feeds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create feed
#
# POST /catalogs/feeds
# Discriminator (response): catalog_type = RETAIL, HOTEL, CREATIVE_ASSETS
# operationId: feeds/create
# --credentials shape: {password: string, username: string}
# --preferred_processing_schedule shape: {time: string, timezone: any}
export def "catalogs-feeds feeds/create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --credentials: record # This field is **OPTIONAL**. Use this if your feed file requires username and password. (nullable) — shape: {password: string, username: string}
  --default-availability: string@default-availability-completer # Default availability for products in a feed. (nullable)
  --default-country: string@default-country-completer # Country ID from ISO 3166-1 alpha-2.
  --default-currency: string@default-currency-completer # Currency Codes from ISO 4217. (nullable)
  --default-locale: any # The locale used within a feed for product descriptions.
  --format: string@format-completer # The file format of a feed.
  --location: string # The URL where a feed is available for download. This URL is what Pinterest will use to download a feed for processing.
  --name: string # A human-friendly name associated to a given feed.
  --preferred-processing-schedule: record # Daily processing schedule. This field is **OPTIONAL**. Use this to configure the preferred time for processing a feed (otherwise random). (nullable) — shape: {time: string, timezone: any}
  --status: any # default: ACTIVE
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/catalogs/feeds" $qp)
  let body = {credentials: $credentials, default_availability: $default_availability, default_country: $default_country, default_currency: $default_currency, default_locale: $default_locale, format: $format, location: $location, name: $name, preferred_processing_schedule: $preferred_processing_schedule, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get feed
#
# GET /catalogs/feeds/{feed_id}
# Discriminator (response): catalog_type = RETAIL, HOTEL, CREATIVE_ASSETS
# operationId: feeds/get
export def "catalogs-feeds feeds/get" [
  feed_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/catalogs/feeds/($feed_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update feed
#
# PATCH /catalogs/feeds/{feed_id}
# Discriminator (response): catalog_type = RETAIL, HOTEL, CREATIVE_ASSETS
# operationId: feeds/update
# --credentials shape: {password: string, username: string}
# --preferred_processing_schedule shape: {time: string, timezone: any}
export def "catalogs-feeds feeds/update" [
  feed_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --credentials: record # This field is **OPTIONAL**. Use this if your feed file requires username and password. (nullable) — shape: {password: string, username: string}
  --default-availability: string@default-availability-completer # Default availability for products in a feed. (nullable)
  --default-currency: string@default-currency-completer # Currency Codes from ISO 4217. (nullable)
  --format: string@format-completer # The file format of a feed.
  --location: string # The URL where a feed is available for download. This URL is what Pinterest will use to download a feed for processing.
  --name: string # A human-friendly name associated to a given feed.
  --preferred-processing-schedule: record # Daily processing schedule. This field is **OPTIONAL**. Use this to configure the preferred time for processing a feed (otherwise random). (nullable) — shape: {time: string, timezone: any}
  --status: string@status-completer-1 # Status for catalogs entities. Present in catalogs_feed values. When a feed is deleted, the response will inform DELETED as status.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/catalogs/feeds/($feed_id)" $qp)
  let body = {credentials: $credentials, default_availability: $default_availability, default_currency: $default_currency, format: $format, location: $location, name: $name, preferred_processing_schedule: $preferred_processing_schedule, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete feed
#
# DELETE /catalogs/feeds/{feed_id}
# Discriminator (response): catalog_type = RETAIL, HOTEL, CREATIVE_ASSETS
# operationId: feeds/delete
export def "catalogs-feeds feeds/delete" [
  feed_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/catalogs/feeds/($feed_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ingest feed items
#
# POST /catalogs/feeds/{feed_id}/ingest
# operationId: feeds/ingest
export def "catalogs-feeds-ingest feeds/ingest" [
  feed_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
]: nothing -> record<created_at: string, feed_id: string, id: string, status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/catalogs/feeds/($feed_id)/ingest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List feed processing results
#
# GET /catalogs/feeds/{feed_id}/processing_results
# operationId: feed_processing_results/list
export def "catalogs-feeds-processing-results results/list" [
  feed_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<created_at: string, id: string, ingestion_details: record, product_counts: record, status: string, updated_at: string, validation_details: record, video_counts: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/catalogs/feeds/($feed_id)/processing_results" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get catalogs items (POST)
#
# POST /catalogs/items
# operationId: items/post
# --filters shape: {catalog_id?: string, catalog_type: "RETAIL"|"HOTEL"|"CREATIVE_ASSETS", item_ids?: list, hotel_ids?: list, creative_assets_ids?: list}
export def "catalogs-items items/post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  country: string@country-completer # Country ID from ISO 3166-1 alpha-2.
  filters: record # shape: {catalog_id?: string, catalog_type: "RETAIL"|"HOTEL"|"CREATIVE_ASSETS", item_ids?: list, hotel_ids?: list, creative_assets_ids?: list}
  language: any # We recommend using the CatalogsLocale values.
]: any -> record<items: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/catalogs/items" $qp)
  let body = {country: $country, filters: $filters, language: $language} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Operate on item batch
#
# POST /catalogs/items/batch
# Discriminator (response): catalog_type = RETAIL, HOTEL, CREATIVE_ASSETS
# operationId: items_batch/post
export def "catalogs-items-batch batch/post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/catalogs/items/batch" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get item batch status
#
# GET /catalogs/items/batch/{batch_id}
# Discriminator (response): catalog_type = RETAIL, HOTEL, CREATIVE_ASSETS
# operationId: items_batch/get
export def "catalogs-items-batch batch/get" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/catalogs/items/batch/($batch_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List item issues
#
# GET /catalogs/processing_results/{processing_result_id}/item_issues
# operationId: items_issues/list
export def "catalogs-processing-results-item-issues issues/list" [
  processing_result_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --item-numbers: list # Item number based on order of appearance in the Catalogs Feed. For example, '0' refers to first item found in a feed that was downloaded from a 'location' specified during feed creation.
  --item-validation-issue: string@item-validation-issue-completer # Filter item validation issues that have a given type of item validation issue.
  --ad-account-id: string # Unique identifier of an ad account.
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<errors: record, item_id: string, item_number: int, warnings: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "item_numbers" $item_numbers "multi") (serialize-qp "item_validation_issue" $item_validation_issue "scalar") (serialize-qp "ad_account_id" $ad_account_id "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/catalogs/processing_results/($processing_result_id)/item_issues" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List product groups
#
# GET /catalogs/product_groups
# operationId: catalogs_product_groups/list
export def "catalogs-product-groups groups/list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: list # Comma-separated list of product group ids
  --feed-id: string # Filter entities for a given feed_id. If not given, all feeds are considered.
  --catalog-id: string # Filter entities for a given catalog_id. If not given, all catalogs are considered.
  --ad-account-id: string # Unique identifier of an ad account.
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "feed_id" $feed_id "scalar") (serialize-qp "catalog_id" $catalog_id "scalar") (serialize-qp "ad_account_id" $ad_account_id "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/catalogs/product_groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create product group
#
# POST /catalogs/product_groups
# Discriminator (response): catalog_type = RETAIL, HOTEL, CREATIVE_ASSETS
# operationId: catalogs_product_groups/create
@deprecated --flag is-featured
export def "catalogs-product-groups groups/create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --description: string # nullable
  --feed-id: string # Catalog Feed id pertaining to the catalog product group. (e.g. 2680059592705)
  --filters: any # Object holding a group of filters for request on catalog product group.  This is a distinct schema. It is not possible to create or update a Product Group with empty filters. But some automatically generated Product Groups might have empty filters.
  --is-featured: oneof<nothing, bool> # boolean indicator of whether the product group is being featured or not (DEPRECATED)
  --name: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/catalogs/product_groups" $qp)
  let body = {description: $description, feed_id: $feed_id, filters: $filters, is_featured: $is_featured, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete product groups
#
# DELETE /catalogs/product_groups/multiple
# operationId: catalogs_product_groups/delete_many
export def "catalogs-product-groups-multiple many" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: list # Comma-separated list of product group ids
  --ad-account-id: string # Unique identifier of an ad account.
]: nothing -> record<code: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/catalogs/product_groups/multiple" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create product groups
#
# POST /catalogs/product_groups/multiple
# operationId: catalogs_product_groups/create_many
export def "catalogs-product-groups-multiple many-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --body: record
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/catalogs/product_groups/multiple" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get product group
#
# GET /catalogs/product_groups/{product_group_id}
# Discriminator (response): catalog_type = RETAIL, HOTEL, CREATIVE_ASSETS
# operationId: catalogs_product_groups/get
export def "catalogs-product-groups groups/get" [
  product_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/catalogs/product_groups/($product_group_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update single product group
#
# PATCH /catalogs/product_groups/{product_group_id}
# Discriminator (response): catalog_type = RETAIL, HOTEL, CREATIVE_ASSETS
# operationId: catalogs_product_groups/update
@deprecated --flag is-featured
export def "catalogs-product-groups groups/update" [
  product_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --description: string # nullable
  --filters: any # Object holding a group of filters for request on catalog product group.  This is a distinct schema. It is not possible to create or update a Product Group with empty filters. But some automatically generated Product Groups might have empty filters.
  --is-featured: oneof<nothing, bool> # boolean indicator of whether the product group is being featured or not (DEPRECATED)
  --name: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/catalogs/product_groups/($product_group_id)" $qp)
  let body = {description: $description, filters: $filters, is_featured: $is_featured, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete product group
#
# DELETE /catalogs/product_groups/{product_group_id}
# Discriminator (response): catalog_type = RETAIL, HOTEL, CREATIVE_ASSETS
# operationId: catalogs_product_groups/delete
export def "catalogs-product-groups groups/delete" [
  product_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/catalogs/product_groups/($product_group_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get product counts
#
# GET /catalogs/product_groups/{product_group_id}/product_counts
# Discriminator (response): catalog_type = RETAIL, HOTEL, CREATIVE_ASSETS
# operationId: catalogs_product_groups/product_counts_get
export def "catalogs-product-groups-product-counts get" [
  product_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/catalogs/product_groups/($product_group_id)/product_counts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List products by product group
#
# GET /catalogs/product_groups/{product_group_id}/products
# operationId: catalogs_product_group_pins/list
export def "catalogs-product-groups-products pins/list" [
  product_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --pin-metrics: oneof<nothing, bool> # Specify whether to return 90d and lifetime Pin metrics. Total comments and total reactions are only available with lifetime Pin metrics. If Pin was created before `2023-03-20` lifetime metrics will only be available for Video and Idea Pin formats. Lifetime metrics are available for all Pin formats since then. (default: false)
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar") (serialize-qp "pin_metrics" $pin_metrics "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/catalogs/product_groups/($product_group_id)/products" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List products by filter
#
# POST /catalogs/products/get_by_product_group_filters
# operationId: products_by_product_group_filter/list
export def "catalogs-products-get-by-product-group-filters filter/list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
  --ad-account-id: string # Unique identifier of an ad account.
  --pin-metrics: oneof<nothing, bool> # Specify whether to return 90d and lifetime Pin metrics. Total comments and total reactions are only available with lifetime Pin metrics. If Pin was created before `2023-03-20` lifetime metrics will only be available for Video and Idea Pin formats. Lifetime metrics are available for all Pin formats since then. (default: false)
  --feed-id: string # Catalog Feed id pertaining to the catalog product group filter. (e.g. 2680059592705)
  --filters: any # Object holding a group of filters for a catalog product group
]: any -> record<bookmark: string, items: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "ad_account_id" $ad_account_id "scalar") (serialize-qp "pin_metrics" $pin_metrics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/catalogs/products/get_by_product_group_filters" $qp)
  let body = {feed_id: $feed_id, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get catalogs report
#
# GET /catalogs/reports
# operationId: reports/get
export def "catalogs-reports reports/get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --qp-token: string # Token returned from the post request creation call
]: nothing -> record<report_status: string, size: float, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/catalogs/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Build catalogs report
#
# POST /catalogs/reports
# Discriminator (request): catalog_type = RETAIL, HOTEL
# operationId: reports/create
# --report shape: {feed_id?: string, processing_result_id?: string, report_type: "FEED_INGESTION_ISSUES"|"DISTRIBUTION_ISSUES"|"ALL_ITEMS", catalog_id?: string, product_group_id?: string}
export def "catalogs-reports reports/create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  catalog_type: string@catalog-type-completer-1
  --report: record # shape: {feed_id?: string, processing_result_id?: string, report_type: "FEED_INGESTION_ISSUES"|"DISTRIBUTION_ISSUES"|"ALL_ITEMS", catalog_id?: string, product_group_id?: string}
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/catalogs/reports" $qp)
  let body = {catalog_type: $catalog_type, report: $report} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List report stats
#
# GET /catalogs/reports/stats
# operationId: reports/stats
export def "catalogs-reports-stats reports/stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --parameters: record # Contains the parameters for report identification.
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar") (serialize-qp "parameters" $parameters "multi") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/catalogs/reports/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Operate on local inventory item batch
#
# POST /catalogs/{catalog_id}/local_inventory_items/batch
# operationId: catalogs_local_inventory_items_batch/operate
export def "catalogs-local-inventory-items-batch batch/operate" [
  catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  operations: list # Array of inventory operations. Up to 1000 items per request.
]: any -> record<batch_id: string, completed_time: string, created_time: string, operation_results: list<record>, status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/catalogs/($catalog_id)/local_inventory_items/batch" $qp)
  let body = {operations: $operations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get local inventory items (POST)
#
# POST /catalogs/{catalog_id}/local_inventory_items/query
# operationId: catalogs_local_inventory_items/post
# --item_filters item shape: {item_id: string, store_code: string}
export def "catalogs-local-inventory-items-query items/post" [
  catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  item_filters: list # Array of local inventory item identifiers. Each item requires an item_id and store_code pair. Up to 1000 items. — item shape: {item_id: string, store_code: string}
]: any -> record<items: table<ad_link: string, availability: record, created_at: int, item_id: string, last_updated_time: int, price: string, sale_price: string, store_metadata: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/catalogs/($catalog_id)/local_inventory_items/query" $qp)
  let body = {item_filters: $item_filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List local stores
#
# GET /catalogs/{catalog_id}/local_stores
# operationId: catalogs_local_stores/list
export def "catalogs-local-stores stores/list" [
  catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # List of local store IDs to filter by.
  --ad-account-id: string # Unique identifier of an ad account.
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<address_primary: string, address_secondary: string, city: string, country: record, created_at: string, id: string, latitude: float, longitude: float, name: string, postal_code: string, region: string, store_code: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "ad_account_id" $ad_account_id "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/catalogs/($catalog_id)/local_stores" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create local stores
#
# POST /catalogs/{catalog_id}/local_stores
# operationId: catalogs_local_stores/create
export def "catalogs-local-stores stores/create" [
  catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --body: record
]: any -> table<data: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/catalogs/($catalog_id)/local_stores" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update local stores
#
# PATCH /catalogs/{catalog_id}/local_stores
# operationId: catalogs_local_stores/update
export def "catalogs-local-stores stores/update" [
  catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --body: record
]: any -> table<data: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/catalogs/($catalog_id)/local_stores" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete local stores
#
# DELETE /catalogs/{catalog_id}/local_stores
# operationId: catalogs_local_stores/delete
export def "catalogs-local-stores stores/delete" [
  catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # List of local store IDs to filter by.
  --ad-account-id: string # Unique identifier of an ad account.
]: nothing -> table<id: string, status: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/catalogs/($catalog_id)/local_stores" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get supplemental items batch status
#
# GET /catalogs/{catalog_id}/supplemental_items/batch/{batch_id}
# operationId: catalogs_supplemental_items_batch/get
export def "catalogs-supplemental-items-batch batch/get" [
  catalog_id: string
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
]: nothing -> record<batch_id: string, completed_time: string, created_time: string, operation_results: list<record>, status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/catalogs/($catalog_id)/supplemental_items/batch/($batch_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get integration metadata list
#
# GET /integrations
# operationId: integrations/get_list
export def "integrations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<additional_id_1: string, connected_advertiser_id: string, connected_lba_id: string, connected_merchant_id: string, connected_tag_id: string, connected_user_id: string, created_time: int, external_business_id: string, id: record, partner_access_token: string, partner_access_token_expiry: int, partner_metadata: string, partner_primary_email: string, partner_refresh_token: string, partner_refresh_token_expiry: int, scopes: string, updated_time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/integrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create commerce integration
#
# POST /integrations/commerce
# operationId: integrations_commerce/post
export def "integrations-commerce commerce/post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additional-id-1: string
  --connected-advertiser-id: string
  --connected-lba-id: string
  --connected-merchant-id: string
  --connected-tag-id: string
  --external-business-id: string # External business ID for the integration.
  --partner-access-token: string
  --partner-access-token-expiry: float
  --partner-metadata: string
  --partner-primary-email: string
  --partner-refresh-token: string
  --partner-refresh-token-expiry: float
  --scopes: string
]: any -> record<additional_id_1: string, connected_advertiser_id: string, connected_lba_id: string, connected_merchant_id: string, connected_tag_id: string, connected_user_id: string, created_timestamp: float, external_business_id: string, id: record, partner_access_token_expiry: float, partner_metadata: string, partner_refresh_token_expiry: float, scopes: string, updated_timestamp: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/commerce")
  let body = {additional_id_1: $additional_id_1, connected_advertiser_id: $connected_advertiser_id, connected_lba_id: $connected_lba_id, connected_merchant_id: $connected_merchant_id, connected_tag_id: $connected_tag_id, external_business_id: $external_business_id, partner_access_token: $partner_access_token, partner_access_token_expiry: $partner_access_token_expiry, partner_metadata: $partner_metadata, partner_primary_email: $partner_primary_email, partner_refresh_token: $partner_refresh_token, partner_refresh_token_expiry: $partner_refresh_token_expiry, scopes: $scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get commerce integration
#
# GET /integrations/commerce/{external_business_id}
# operationId: integrations_commerce/get
export def "integrations-commerce commerce/get" [
  external_business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<additional_id_1: string, connected_advertiser_id: string, connected_lba_id: string, connected_merchant_id: string, connected_tag_id: string, connected_user_id: string, created_timestamp: float, external_business_id: string, id: record, partner_access_token_expiry: float, partner_metadata: string, partner_refresh_token_expiry: float, scopes: string, updated_timestamp: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integrations/commerce/($external_business_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update commerce integration
#
# PATCH /integrations/commerce/{external_business_id}
# operationId: integrations_commerce/patch
export def "integrations-commerce commerce/patch" [
  external_business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additional-id-1: string
  --connected-advertiser-id: string
  --connected-lba-id: string
  --connected-merchant-id: string
  --connected-tag-id: string
  --partner-access-token: string
  --partner-access-token-expiry: float
  --partner-metadata: string
  --partner-primary-email: string
  --partner-refresh-token: string
  --partner-refresh-token-expiry: float
  --scopes: string
]: any -> record<additional_id_1: string, connected_advertiser_id: string, connected_lba_id: string, connected_merchant_id: string, connected_tag_id: string, connected_user_id: string, created_timestamp: float, external_business_id: string, id: record, partner_access_token_expiry: float, partner_metadata: string, partner_refresh_token_expiry: float, scopes: string, updated_timestamp: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integrations/commerce/($external_business_id)")
  let body = {additional_id_1: $additional_id_1, connected_advertiser_id: $connected_advertiser_id, connected_lba_id: $connected_lba_id, connected_merchant_id: $connected_merchant_id, connected_tag_id: $connected_tag_id, partner_access_token: $partner_access_token, partner_access_token_expiry: $partner_access_token_expiry, partner_metadata: $partner_metadata, partner_primary_email: $partner_primary_email, partner_refresh_token: $partner_refresh_token, partner_refresh_token_expiry: $partner_refresh_token_expiry, scopes: $scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete commerce integration
#
# DELETE /integrations/commerce/{external_business_id}
# operationId: integrations_commerce/del
export def "integrations-commerce commerce/del" [
  external_business_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<additional_id_1: string, connected_advertiser_id: string, connected_lba_id: string, connected_merchant_id: string, connected_tag_id: string, connected_user_id: string, created_timestamp: float, external_business_id: string, id: record, partner_access_token_expiry: float, partner_metadata: string, partner_refresh_token_expiry: float, scopes: string, updated_timestamp: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integrations/commerce/($external_business_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Receives batched logs from integration applications.
#
# POST /integrations/logs
# operationId: integrations_logs/post
# --logs item shape: {advertiser_id?: string, app_version_number?: string, client_timestamp: int, error?: record, event_type: any, external_business_id?: string, feed_profile_id?: string, log_level: any, merchant_id?: string, message?: string, platform_version_number?: string, request?: record, tag_id?: string}
export def "integrations-logs logs/post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  logs: list # item shape: {advertiser_id?: string, app_version_number?: string, client_timestamp: int, error?: record, event_type: any, external_business_id?: string, feed_profile_id?: string, log_level: any, merchant_id?: string, message?: string, platform_version_number?: string, request?: record, tag_id?: string}
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/logs")
  let body = {logs: $logs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get integration metadata
#
# GET /integrations/{id}
# operationId: integrations/get_by_id
export def "integrations id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<additional_id_1: string, connected_advertiser_id: string, connected_lba_id: string, connected_merchant_id: string, connected_tag_id: string, connected_user_id: string, created_time: int, external_business_id: string, id: record, partner_access_token: string, partner_access_token_expiry: int, partner_metadata: string, partner_primary_email: string, partner_refresh_token: string, partner_refresh_token_expiry: int, scopes: string, updated_time: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integrations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List media uploads
#
# GET /media
# operationId: media/list
export def "media media/list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<media_id: string, media_type: record, status: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/media" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Register media upload
#
# POST /media
# operationId: media/create
export def "media media/create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  media_type: any # e.g. video
]: any -> record<media_id: string, media_type: record, upload_parameters: record<Content_Type: string, key: string, policy: string, x_amz_algorithm: string, x_amz_credential: string, x_amz_date: string, x_amz_security_token: string, x_amz_signature: string>, upload_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/media")
  let body = {media_type: $media_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get media upload details
#
# GET /media/{media_id}
# operationId: media/get
export def "media media/get" [
  media_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<media_id: string, media_type: record, status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/media/($media_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Receive notifications from external partners.
#
# POST /notifications
# operationId: notification/post
export def "notifications notification/post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<error_msg: string, received_at: int, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate OAuth access token for conversion API
#
# POST /oauth/conversion_token
# operationId: oauth/conversion_token
export def "oauth-conversion-token token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<access_token: string, token_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/conversion_token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate OAuth access token
#
# POST /oauth/token
# operationId: oauth/token
export def "oauth-token oauth/token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string
  --continuous-refresh: string #   If your app was created before **September 25, 2025**, set to `true` to generate a [continuous refresh token](/docs/getting-started/set-up-authentication-and-authorization/#exchange-the-default-refresh-token-for-a-continuous-refresh-token), which has a 60-day expiration window. We no longer support the legacy refresh token, which has a 365-day expiration window.    If your app was created on or after **September 25, 2025**, ignore this parameter. You automatically receive a continuous refresh token when you request an access token.
  grant_type: string@grant-type-completer # The type of OAuth grant being requested.
  --redirect-uri: string
  --refresh-token: string
  --scope: string
]: any -> record<access_token: string, expires_in: int, refresh_token: string, refresh_token_expires_at: int, refresh_token_expires_in: int, response_type: record, scope: string, token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/token")
  let body = {code: $code, continuous_refresh: $continuous_refresh, grant_type: $grant_type, redirect_uri: $redirect_uri, refresh_token: $refresh_token, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Revoke a token
#
# POST /oauth/token/revoke
# operationId: token/revoke
export def "oauth-token-revoke token/revoke" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # The token to revoke. (e.g. pinr.eyJhbGciOiJS...)
  --token-type-hint: any # The type of the token to revoke. Please refer to [our developer guide for more information](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/) for more information.
]: any -> record<code: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/token/revoke")
  let body = {token: $body_token, token_type_hint: $token_type_hint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create Pin
#
# POST /pins
# operationId: pins/create
# --media_source shape: {content_type?: "image/jpeg"|"image/png", data?: string, is_standard?: bool, source_type: "image_base64"|"image_url"|"video_id"|"multiple_image_base64"|"multiple_image_urls"|"pin_url", url?: string, cover_image_content_type?: any, cover_image_data?: string, cover_image_key_frame_time?: int, cover_image_url?: string, media_id?: string, index?: int, items?: list, is_affiliate_link?: bool}
export def "pins pins/create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --ai-disclosures: any # AI disclosure declarations the creator has made about this Pin.
  --alt-text: string # nullable
  --board-id: string # The board to which this Pin belongs.
  --board-section-id: string # The board section to which this Pin belongs. (nullable)
  --description: string # nullable
  --dominant-color: string # Dominant pin color. Hex number, e.g. `#6E7874`. (nullable)
  --link: string # nullable
  --media-source: record # Pin media source that can be an image, video, or a mix of both passed in as a request. — shape: {content_type?: "image/jpeg"|"image/png", data?: string, is_standard?: bool, source_type: "image_base64"|"image_url"|"video_id"|"multiple_image_base64"|"multiple_image_urls"|"pin_url", url?: string, cover_image_content_type?: any, cover_image_data?: string, cover_image_key_frame_time?: int, cover_image_url?: string, media_id?: string, index?: int, items?: list, is_affiliate_link?: bool}
  --parent-pin-id: string # The source pin id if this pin was saved from another pin. [Learn more](https://help.pinterest.com/article/save-pins-on-pinterest). (nullable)
  --sponsor-id: string # The sponsor account id to request paid partnership from.  Currently the field is only available to a list of users in a closed beta. (nullable)
  --title: string # nullable
]: any -> record<alt_text: string, description: string, link: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pins" $qp)
  let body = {ai_disclosures: $ai_disclosures, alt_text: $alt_text, board_id: $board_id, board_section_id: $board_section_id, description: $description, dominant_color: $dominant_color, link: $link, media_source: $media_source, parent_pin_id: $parent_pin_id, sponsor_id: $sponsor_id, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Pins
#
# GET /pins
# operationId: pins/list
export def "pins pins/list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pin-filter: string@pin-filter-completer # The filter to apply to the pins
  --pin-metrics: oneof<nothing, bool> # Specify whether to return 90d and lifetime Pin metrics. Total comments and total reactions are only available with lifetime Pin metrics. If Pin was created before `2023-03-20` lifetime metrics will only be available for Video and Idea Pin formats. Lifetime metrics are available for all Pin formats since then. (default: false)
  --include-protected-pins: oneof<nothing, bool> # Whether to include protected pins in the results (default: false)
  --pin-type: string@pin-type-completer # The type of pins to return, currently only enabled for private pins
  --creative-types: list # Pin creative types filter. **Note:** SHOP_THE_PIN has been deprecated. Please use COLLECTION instead.
  --ad-account-id: string # Unique identifier of an ad account.
  --domain: string # Only return pins with links that match the exact domain. Domain should not include 'www.' prefix. For example, 'pinterest.com' is a valid domain, but 'www.pinterest.com' is not (will not match any pins).
  --domains: list # Only return pins with links whose domain matches any value in the list. Values are joined comma-separated on the wire (e.g. `?domains=instagram.com,jcpenney.com`).
  --include-product-tag-obj: oneof<nothing, bool> # Include product tag objects in the response with their associated links.
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<alt_text: string, description: string, link: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pin_filter" $pin_filter "scalar") (serialize-qp "pin_metrics" $pin_metrics "scalar") (serialize-qp "include_protected_pins" $include_protected_pins "scalar") (serialize-qp "pin_type" $pin_type "scalar") (serialize-qp "creative_types" $creative_types "multi") (serialize-qp "ad_account_id" $ad_account_id "scalar") (serialize-qp "domain" $domain "scalar") (serialize-qp "domains" $domains "multi") (serialize-qp "include_product_tag_obj" $include_product_tag_obj "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pins" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get multiple Pin analytics
#
# GET /pins/analytics
# operationId: multi_pins/analytics
export def "pins-analytics list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pin-ids: list # List of Pin IDs.
  --start-date: string # Metric report start date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days back from today. (format: date)
  --end-date: string # Metric report end date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days past start_date. (format: date)
  --app-types: string@app-types-completer # Apps or devices to get data for, default is all. (default: ALL)
  --metric-types: list # Pin metric types to get data for.
  --ad-account-id: string # Unique identifier of an ad account.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pin_ids" $pin_ids "multi") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "app_types" $app_types "scalar") (serialize-qp "metric_types" $metric_types "csv") (serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pins/analytics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Pin
#
# GET /pins/{pin_id}
# operationId: pins/get
export def "pins pins/get" [
  pin_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --pin-metrics: oneof<nothing, bool> # Specify whether to return 90d and lifetime Pin metrics. Total comments and total reactions are only available with lifetime Pin metrics. If Pin was created before `2023-03-20` lifetime metrics will only be available for Video and Idea Pin formats. Lifetime metrics are available for all Pin formats since then. (default: false)
]: nothing -> record<alt_text: string, description: string, link: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar") (serialize-qp "pin_metrics" $pin_metrics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pins/($pin_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Pin
#
# PATCH /pins/{pin_id}
# operationId: pins/update
# --carousel_slots item shape: {description?: string, link?: string, title?: string}
export def "pins pins/update" [
  pin_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --ai-disclosures: any # AI disclosure declarations the creator has made about this Pin.
  --alt-text: string # nullable
  --board-id: string # The board to which this Pin belongs.
  --board-section-id: string # The board section to which this Pin belongs. (nullable)
  --carousel-slots: list # Carousel Pin slots data. — item shape: {description?: string, link?: string, title?: string}
  --description: string # nullable
  --link: string # nullable
  --title: string # nullable
]: any -> record<alt_text: string, description: string, link: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pins/($pin_id)" $qp)
  let body = {ai_disclosures: $ai_disclosures, alt_text: $alt_text, board_id: $board_id, board_section_id: $board_section_id, carousel_slots: $carousel_slots, description: $description, link: $link, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Pin
#
# DELETE /pins/{pin_id}
# operationId: pins/delete
export def "pins pins/delete" [
  pin_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
]: nothing -> record<alt_text: string, description: string, link: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pins/($pin_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Pin analytics
#
# GET /pins/{pin_id}/analytics
# operationId: pins/analytics
export def "pins-analytics pins/analytics" [
  pin_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # Metric report start date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days back from today. (format: date)
  --end-date: string # Metric report end date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days past start_date. (format: date)
  --app-types: string@app-types-completer # Apps or devices to get data for, default is all. (default: ALL)
  --metric-types: list # Pin metric types to get data for. VIDEO_MRC_VIEW are Video views, VIDEO_V50_WATCH_TIME is Total play time. If Pin was created before `2023-03-20`, Profile visits and Follows will only be available for Idea Pins. These metrics are available for all Pin formats since then. Keep in mind this cannot have ALL if split_field is set to any value other than `NO_SPLIT`.
  --split-field: string@split-field-completer # How to split the data into groups. Not including this param means data won't be split. (default: NO_SPLIT)
  --ad-account-id: string # Unique identifier of an ad account.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "app_types" $app_types "scalar") (serialize-qp "metric_types" $metric_types "csv") (serialize-qp "split_field" $split_field "scalar") (serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pins/($pin_id)/analytics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add product tags to pin
#
# POST /pins/{pin_id}/product_tags
# operationId: product_tags/bulk_add
# --product_tags item shape: {pin_id: string}
export def "pins-product-tags add" [
  pin_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  product_tags: list # List of product tags to add. Maximum 24 items allowed. — item shape: {pin_id: string}
]: any -> record<product_tags: table<pin_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pins/($pin_id)/product_tags")
  let body = {product_tags: $product_tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get product tags for pin
#
# GET /pins/{pin_id}/product_tags
# operationId: product_tags/list
export def "pins-product-tags tags/list" [
  pin_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<product_tags: table<pin_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pins/($pin_id)/product_tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete product tags from pin
#
# POST /pins/{pin_id}/product_tags/bulk-delete
# operationId: product_tags/bulk_delete
# --product_tags item shape: {pin_id: string}
export def "pins-product-tags-bulk-delete delete" [
  pin_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  product_tags: list # List of product tags to delete. — item shape: {pin_id: string}
]: any -> record<code: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pins/($pin_id)/product_tags/bulk-delete")
  let body = {product_tags: $product_tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Save Pin
#
# POST /pins/{pin_id}/save
# operationId: pins/save
export def "pins-save pins/save" [
  pin_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --board-id: string # Unique identifier of the board to which the pin will be saved. (nullable)
  --board-section-id: string # Unique identifier of the board section to which the pin will be saved. (nullable)
]: any -> record<alt_text: string, description: string, link: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pins/($pin_id)/save" $qp)
  let body = {board_id: $board_id, board_section_id: $board_section_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get ad accounts countries
#
# GET /resources/ad_account_countries
# operationId: ad_account_countries/get
export def "resources-ad-account-countries countries/get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<code: record, currency: string, index: float, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/resources/ad_account_countries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get available metrics' definitions
#
# GET /resources/delivery_metrics
# operationId: delivery_metrics/get
export def "resources-delivery-metrics metrics/get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --report-type: string@report-type-completer # Report type.
]: nothing -> record<items: table<category: string, definition: string, display_name: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "report_type" $report_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/resources/delivery_metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get lead form questions
#
# GET /resources/lead_form_questions
# operationId: lead_form_questions/get
export def "resources-lead-form-questions questions/get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/resources/lead_form_questions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get metrics ready state
#
# GET /resources/metrics_ready_state
# operationId: metrics_ready_state/get
export def "resources-metrics-ready-state state/get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # Analytics reports request date (UTC). Format: YYYY-MM-DD
]: nothing -> record<conversion_metrics_ready: bool, non_conversion_metrics_ready: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/resources/metrics_ready_state" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get interest details
#
# GET /resources/targeting/interests/{interest_id}
# operationId: interest_targeting_options/get
export def "resources-targeting-interests options/get" [
  interest_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<child_interests: list<string>, id: string, level: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/resources/targeting/interests/($interest_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get targeting options
#
# GET /resources/targeting/{targeting_type}
# operationId: targeting_options/get
export def "resources-targeting options/get" [
  targeting_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --client-id: string # Client ID
  --oauth-signature: string # Oauth signature
  --timestamp: string # Timestamp.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar") (serialize-qp "client_id" $client_id "scalar") (serialize-qp "oauth_signature" $oauth_signature "scalar") (serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/resources/targeting/($targeting_type)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search user's boards
#
# GET /search/boards
# operationId: search_user_boards/get
export def "search-boards boards/get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --qp-query: string # Search query. Can contain pin description keywords or comma-separated pin IDs.
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<privacy: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/boards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search pins by a given search term
#
# GET /search/partner/pins
# operationId: search_partner_pins
export def "search-partner-pins pins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --term: string # Search term to look up pins.
  --country-code: string # Two letter country code (ISO 3166-1 alpha-2)
  --bookmark: string # Cursor used to fetch the next page of items
  --locale: string # Search locale.
  --limit: int # Max search result size (default: 10)
]: nothing -> record<bookmark: string, items: table<alt_text: string, description: string, id: string, link: string, media: record, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "term" $term "scalar") (serialize-qp "country_code" $country_code "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/partner/pins" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search user's Pins
#
# GET /search/pins
# operationId: search_user_pins/list
export def "search-pins pins/list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --qp-query: string # Search query. Can contain pin description keywords or comma-separated pin IDs.
  --bookmark: string # Cursor used to fetch the next page of items
]: nothing -> record<bookmark: string, items: table<alt_text: string, description: string, link: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "bookmark" $bookmark "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/pins" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List related terms
#
# GET /terms/related
# operationId: terms_related/list
export def "terms-related related/list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --terms: list # List of input terms.
]: nothing -> record<id: string, related_term_count: int, related_terms_list: table<related_terms: list, term: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "terms" $terms "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/terms/related" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List suggested terms
#
# GET /terms/suggested
# operationId: terms_suggested/list
export def "terms-suggested suggested/list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --term: string # Input term.
  --limit: int # Max suggested terms to return. (default: 4)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "term" $term "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/terms/suggested" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns editorial articles for a given region
#
# GET /trends/editorial_articles
# operationId: trends_editorial_articles/list
export def "trends-editorial-articles articles/list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string@region-completer #      The geographic region of interest. Only top product categories within the specified region will be returned.      The `region` parameter is formatted as ISO 3166-2 country codes delimited by `+`.      - `US` - United States     - `GB+IE` - Great Britain & Ireland     - `CA` - Canada
]: nothing -> table<board_url: string, description: string, interests: list<string>, pins_url: list<string>, related_keywords: list<record>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/trends/editorial_articles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List trending keywords
#
# GET /trends/keywords/{region}/top/{trend_type}
# operationId: trending_keywords/list
export def "trends-keywords-top keywords/list" [
  region: string
  trend_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --interests: list #   The list of supported interests is:   - `animals` - Animals   - `architecture` - Architecture   - `art` - Art   - `beauty` - Beauty   - `childrens_fashion` - Children's Fashion   - `design` - Design   - `diy_and_crafts` - DIY & Crafts   - `education` - Education   - `electronics` - Electronics   - `entertainment` - Entertainment   - `event_planning` - Event Planning   - `finance` - Finance   - `food_and_drinks` - Food & Drink   - `gardening` - Gardening   - `health` - Health   - `home_decor` - Home Decor   - `mens_fashion` - Men's Fashion   - `parenting` - Parenting   - `quotes` - Quotes   - `sport` - Sports   - `travel` - Travel   - `vehicles` - Vehicles   - `wedding` - Wedding   - `womens_fashion` - Women's Fashion
  --genders: list # If set, filters the results to trends among users who identify with the specified gender(s). If unset, trends among all genders will be returned. The `unknown` group includes users with unspecified or customized gender profile settings.
  --ages: list # If set, filters the results to trends among users in the specified age range(s). If unset, trends among all age groups will be returned.
  --include-keywords: list # If set, filters the results to top trends which include at least one of the specified keywords. If unset, no keyword filtering logic is applied. (e.g. [recipes, dessert])
  --normalize-against-group: oneof<nothing, bool> #  Governs how the resulting time series data will be normalized to a [0-100] scale.    By default (`false`), the data will be normalized independently for each keyword.  The peak search volume observation in *each* keyword's time series will be represented by the value 100.  This is ideal for analyzing when an individual keyword is expected to peak in interest.    If set to `true`, the data will be normalized as a group.  The peak search volume observation across *all* keywords in the response will be represented by the value 100, and all other values scaled accordingly.  Use this option when you wish to compare relative search volume between multiple keywords. (default: false)
  --limit: int # The maximum number of trending keywords that will be returned. Keywords are returned in trend-ranked order, so a `limit` of 50 will return the top 50 trends. (default: 50)
  --include-demographics: oneof<nothing, bool> # Including the age and gender distribution for each keyword. By default (`false`), the response will not include demographics data. (default: false)
]: nothing -> record<trends: table<demographics: record, has_prediction: bool, keyword: string, pct_growth_mom: int, pct_growth_wow: int, pct_growth_yoy: int, predicted_time_series: record, time_series: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "interests" $interests "multi") (serialize-qp "genders" $genders "multi") (serialize-qp "ages" $ages "multi") (serialize-qp "include_keywords" $include_keywords "multi") (serialize-qp "normalize_against_group" $normalize_against_group "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "include_demographics" $include_demographics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/trends/keywords/($region)/top/($trend_type)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get product category details
#
# GET /trends/product_categories/details
# operationId: trends_product_categories_details/list
export def "trends-product-categories-details details/list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --product-categories: list # List of product categories
  --region: string@region-completer #      The geographic region of interest. Only top product categories within the specified region will be returned.      The `region` parameter is formatted as ISO 3166-2 country codes delimited by `+`.      - `US` - United States     - `GB+IE` - Great Britain & Ireland     - `CA` - Canada
  --lookback-window: float@lookback-window-completer #   Time period for historical data analysis in days. The lookback window defines how far back in time the API will analyze data to compute trend metrics.   - `90` - Last 90 days (3 months)   - `180` - Last 180 days (6 months)   - `365` - Last 365 days (1 year)   - `730` - Last 730 days (2 years)
  --engagement-type: string@engagement-type-completer #     Type of engagement metric to analyze. - `ENGAGEMENT` - Overall engagement metric - `OUTBOUND_CLICK` - Number of outbound clicks - `SAVE` - Number of pin saves
]: nothing -> table<demographics: record<age: record, gender: record>, has_prediction: bool, metrics_highlights: record<engagement: record, outbound_clicks: record, pin_saves: record>, predicted_time_series: record, product_category: string, related_searches: list<string>, time_series: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "product_categories" $product_categories "multi") (serialize-qp "region" $region "scalar") (serialize-qp "lookback_window" $lookback_window "scalar") (serialize-qp "engagement_type" $engagement_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/trends/product_categories/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of growing Shopping Product Categories
#
# GET /trends/product_categories/trending
# operationId: trends_product_categories_trending/list
export def "trends-product-categories-trending trending/list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string@region-completer #      The geographic region of interest. Only top product categories within the specified region will be returned.      The `region` parameter is formatted as ISO 3166-2 country codes delimited by `+`.      - `US` - United States     - `GB+IE` - Great Britain & Ireland     - `CA` - Canada
  --verticals: list # List of verticals to filter by
  --ages: list # Age to filter by. If not provided, the results will be filtered by all ages.
  --genders: list # Gender to filter by, If not provided, the results will be filtered by all genders.
  --engagement-type: string@engagement-type-completer #     Type of engagement metric to analyze. - `ENGAGEMENT` - Overall engagement metric - `OUTBOUND_CLICK` - Number of outbound clicks - `SAVE` - Number of pin saves
]: nothing -> table<engagement_type: record, pct_change_mom: int, percent_relative_volume: int, pinterest_product_category_id: int, product_category: string, verticals: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "verticals" $verticals "multi") (serialize-qp "ages" $ages "multi") (serialize-qp "genders" $genders "multi") (serialize-qp "engagement_type" $engagement_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/trends/product_categories/trending" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get featured topics
#
# GET /trends/topics/featured
# operationId: trends_featured_topics/list
export def "trends-topics-featured topics/list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --interest: string@interest-completer # Interest to filter by
  --region: string@region-completer #      The geographic region of interest. Only top product categories within the specified region will be returned.      The `region` parameter is formatted as ISO 3166-2 country codes delimited by `+`.      - `US` - United States     - `GB+IE` - Great Britain & Ireland     - `CA` - Canada
]: nothing -> table<interest: record, market: record, trends: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "interest" $interest "scalar") (serialize-qp "region" $region "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/trends/topics/featured" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user account
#
# GET /user_account
# operationId: user_account/get
export def "user-account account/get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
]: nothing -> record<about: string, account_type: record, board_count: int, business_name: string, follower_count: int, following_count: int, id: string, monthly_views: int, pin_count: int, profile_image: string, username: string, website_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_account" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user account analytics
#
# GET /user_account/analytics
# operationId: user_account/analytics
export def "user-account-analytics account/analytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # Metric report start date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days back from today. (format: date)
  --end-date: string # Metric report end date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days past start_date. (format: date)
  --from-claimed-content: string@from-claimed-content-completer # Filter on Pins that match your claimed domain. (default: BOTH)
  --pin-format: string@pin-format-completer # Pin formats to get data for, default is all. (default: ALL)
  --app-types: string@app-types-completer # Apps or devices to get data for, default is all. (default: ALL)
  --content-type: string@content-type-completer # Filter to paid or organic data. Default is all. (default: ALL)
  --qp-source: string@source-completer # Filter to activity from Pins created and saved by your, or activity created and saved by others from your claimed accounts (default: ALL)
  --metric-types: list # Metric types to get data for, default is all.
  --split-field: string@split-field-completer-1 # How to split the data into groups. Not including this param means data won't be split. (default: NO_SPLIT)
  --ad-account-id: string # Unique identifier of an ad account.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "from_claimed_content" $from_claimed_content "scalar") (serialize-qp "pin_format" $pin_format "scalar") (serialize-qp "app_types" $app_types "scalar") (serialize-qp "content_type" $content_type "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "metric_types" $metric_types "csv") (serialize-qp "split_field" $split_field "scalar") (serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_account/analytics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user account top pins analytics
#
# GET /user_account/analytics/top_pins
# operationId: user_account/analytics/top_pins
export def "user-account-analytics-top-pins pins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # Metric report start date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days back from today. (format: date)
  --end-date: string # Metric report end date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days past start_date. (format: date)
  --sort-by: string@sort-by-completer-1 # Specify sorting order for metrics
  --from-claimed-content: string@from-claimed-content-completer # Filter on Pins that match your claimed domain. (default: BOTH)
  --pin-format: string@pin-format-completer # Pin formats to get data for, default is all. (default: ALL)
  --app-types: string@app-types-completer # Apps or devices to get data for, default is all. (default: ALL)
  --content-type: string@content-type-completer # Filter to paid or organic data. Default is all. (default: ALL)
  --qp-source: string@source-completer # Filter to activity from Pins created and saved by your, or activity created and saved by others from your claimed accounts (default: ALL)
  --metric-types: list # Metric types to get data for, default is all.
  --num-of-pins: int # Number of pins to include, default is 10. Max is 50. (default: 10)
  --created-in-last-n-days: float@created-in-last-n-days-completer # Get metrics for pins created in the last "n" days.
  --ad-account-id: string # Unique identifier of an ad account.
]: nothing -> record<date_availability: record<is_realtime: bool, latest_available_timestamp: float>, pins: table<data_status: record, metrics: record, pin_id: string>, sort_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "from_claimed_content" $from_claimed_content "scalar") (serialize-qp "pin_format" $pin_format "scalar") (serialize-qp "app_types" $app_types "scalar") (serialize-qp "content_type" $content_type "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "metric_types" $metric_types "csv") (serialize-qp "num_of_pins" $num_of_pins "scalar") (serialize-qp "created_in_last_n_days" $created_in_last_n_days "scalar") (serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_account/analytics/top_pins" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user account top video pins analytics
#
# GET /user_account/analytics/top_video_pins
# operationId: user_account/analytics/top_video_pins
export def "user-account-analytics-top-video-pins pins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # Metric report start date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days back from today. (format: date)
  --end-date: string # Metric report end date (UTC). Format: YYYY-MM-DD. Cannot be more than 90 days past start_date. (format: date)
  --sort-by: string@sort-by-completer-2 # Specify sorting order for video metrics
  --from-claimed-content: string@from-claimed-content-completer # Filter on Pins that match your claimed domain. (default: BOTH)
  --pin-format: string@pin-format-completer # Pin formats to get data for, default is all. (default: ALL)
  --app-types: string@app-types-completer # Apps or devices to get data for, default is all. (default: ALL)
  --content-type: string@content-type-completer # Filter to paid or organic data. Default is all. (default: ALL)
  --qp-source: string@source-completer # Filter to activity from Pins created and saved by your, or activity created and saved by others from your claimed accounts (default: ALL)
  --metric-types: list # Metric types to get video data for, default is all.
  --num-of-pins: int # Number of pins to include, default is 10. Max is 50. (default: 10)
  --created-in-last-n-days: float@created-in-last-n-days-completer # Get metrics for pins created in the last "n" days.
  --ad-account-id: string # Unique identifier of an ad account.
]: nothing -> record<date_availability: record<is_realtime: bool, latest_available_timestamp: float>, pins: table<data_status: record, metrics: record, pin_id: string>, sort_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "from_claimed_content" $from_claimed_content "scalar") (serialize-qp "pin_format" $pin_format "scalar") (serialize-qp "app_types" $app_types "scalar") (serialize-qp "content_type" $content_type "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "metric_types" $metric_types "csv") (serialize-qp "num_of_pins" $num_of_pins "scalar") (serialize-qp "created_in_last_n_days" $created_in_last_n_days "scalar") (serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_account/analytics/top_video_pins" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List linked businesses
#
# GET /user_account/businesses
# operationId: linked_business_accounts/get
export def "user-account-businesses accounts/get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<image_large_url: string, image_medium_url: string, image_small_url: string, image_xlarge_url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_account/businesses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List followers
#
# GET /user_account/followers
# operationId: followers/list
export def "user-account-followers followers/list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<type: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_account/followers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List following
#
# GET /user_account/following
# operationId: user_following/get
export def "user-account-following following/get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --explicit-following: oneof<nothing, bool> # Whether or not to include implicit user follows, which means followees with board follows. When explicit_following is True, it means we only want explicit user follows. (default: false)
  --feed-type: string@feed-type-completer # Thrift param specifying what type of followees will be kept. Default to include all followees. (default: ALL, e.g. CREATOR_ONLY)
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<type: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar") (serialize-qp "explicit_following" $explicit_following "scalar") (serialize-qp "feed_type" $feed_type "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_account/following" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List following boards
#
# GET /user_account/following/boards
# operationId: boards_user_follows/list
export def "user-account-following-boards follows/list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --explicit-following: oneof<nothing, bool> # Whether or not to include implicit user follows, which means followees with board follows. When explicit_following is True, it means we only want explicit user follows. (default: false)
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<privacy: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar") (serialize-qp "explicit_following" $explicit_following "scalar") (serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_account/following/boards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Follow user
#
# POST /user_account/following/{username}
# operationId: follow_user/update
export def "user-account-following user/update" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auto-follow: oneof<nothing, bool> #   Whether this request comes as result of auto-follow after clicking on a link.   Follow links can be used by partners on their site or in emails.   Only selected partners can be followed this way. We verify that partner can be auto-followed.
]: any -> record<type: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_account/following/($username)")
  let body = {auto_follow: $auto_follow} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get user websites
#
# GET /user_account/websites
# operationId: user_websites/get
export def "user-account-websites websites/get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<status: string, verified_at: string, website: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_account/websites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify website
#
# POST /user_account/websites
# operationId: verify_website/update
export def "user-account-websites website/update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
  --verification-method: any # Method used to verify website ownership. (default: METATAG)
  --website: string # Website with path or domain only
]: any -> record<status: string, verified_at: string, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_account/websites" $qp)
  let body = {verification_method: $verification_method, website: $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unverify website
#
# DELETE /user_account/websites
# operationId: unverify_website/delete
export def "user-account-websites website/delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --website: string # Website with path or domain only
]: nothing -> record<status: string, verified_at: string, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "website" $website "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_account/websites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user verification code for website claiming
#
# GET /user_account/websites/verification
# operationId: website_verification/get
export def "user-account-websites-verification verification/get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-account-id: string # Unique identifier of an ad account.
]: nothing -> record<dns_txt_record: string, file_content: string, filename: string, metatag: string, verification_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_account_id" $ad_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_account/websites/verification" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List following interests
#
# GET /users/{username}/interests/follow
# operationId: user_account/followed_interests
export def "users-interests-follow interests" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: string # Cursor used to fetch the next page of items
  --page-size: int # Maximum number of items to include in a single page. See documentation on [Pagination](/docs/reference/pagination/) for more information. (default: 25)
]: nothing -> record<bookmark: string, items: table<canonical_url: string, id: string, key: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookmark" $bookmark "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($username)/interests/follow" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
