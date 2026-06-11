# Auto-generated client for Lago API documentation v1.48.1
# Source: https://raw.githubusercontent.com/getlago/lago-openapi/main/openapi.yaml
# Auth: --token flag or $env.LAGO_API_DOCUMENTATION_TOKEN

const BASE_URL = "https://api.getlago.com/api/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LAGO_API_DOCUMENTATION_TOKEN | default "" }
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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.getlago.com/api/v1" "https://api.eu.getlago.com/api/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def default-currency-completer [] { ["AED" "AFN" "ALL" "AMD" "ANG" "AOA" "ARS" "AUD" "AWG" "AZN" "BAM" "BBD" "BDT" "BGN" "BIF" "BMD" "BND" "BOB" "BRL" "BSD" "BWP" "BYN" "BZD" "CAD" "CDF" "CHF" "CLF" "CLP" "CNY" "COP" "CRC" "CVE" "CZK" "DJF" "DKK" "DOP" "DZD" "EGP" "ETB" "EUR" "FJD" "FKP" "GBP" "GEL" "GHS" "GIP" "GMD" "GNF" "GTQ" "GYD" "HKD" "HNL" "HRK" "HTG" "HUF" "IDR" "ILS" "INR" "ISK" "JMD" "JPY" "KES" "KGS" "KHR" "KMF" "KRW" "KYD" "KZT" "LAK" "LBP" "LKR" "LRD" "LSL" "MAD" "MDL" "MGA" "MKD" "MMK" "MNT" "MOP" "MRO" "MUR" "MVR" "MWK" "MXN" "MYR" "MZN" "NAD" "NGN" "NIO" "NOK" "NPR" "NZD" "PAB" "PEN" "PGK" "PHP" "PKR" "PLN" "PYG" "QAR" "RON" "RSD" "RUB" "RWF" "SAR" "SBD" "SCR" "SEK" "SGD" "SHP" "SLL" "SOS" "SRD" "STD" "SZL" "THB" "TJS" "TOP" "TRY" "TTD" "TWD" "TZS" "UAH" "UGX" "USD" "UYU" "UZS" "VND" "VUV" "WST" "XAF" "XCD" "XOF" "XPF" "YER" "ZAR" "ZMW"] }
def document-numbering-completer [] { ["per_billing_entity" "per_customer"] }
def country-completer [] { ["AD" "AE" "AF" "AG" "AI" "AL" "AM" "AO" "AQ" "AR" "AS" "AT" "AU" "AW" "AX" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BL" "BM" "BN" "BO" "BQ" "BR" "BS" "BT" "BV" "BW" "BY" "BZ" "CA" "CC" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CU" "CV" "CW" "CX" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GF" "GG" "GH" "GI" "GL" "GM" "GN" "GP" "GQ" "GR" "GS" "GT" "GU" "GW" "GY" "HK" "HM" "HN" "HR" "HT" "HU" "ID" "IE" "IL" "IM" "IN" "IO" "IQ" "IR" "IS" "IT" "JE" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KP" "KR" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "LY" "MA" "MC" "MD" "ME" "MF" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MQ" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NF" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PM" "PN" "PR" "PS" "PT" "PW" "PY" "QA" "RE" "RO" "RS" "RU" "RW" "SA" "SB" "SC" "SD" "SE" "SG" "SH" "SI" "SJ" "SK" "SL" "SM" "SN" "SO" "SR" "SS" "ST" "SV" "SX" "SY" "SZ" "TC" "TD" "TF" "TG" "TH" "TJ" "TK" "TL" "TM" "TN" "TO" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "UM" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WF" "WS" "YE" "YT" "ZA" "ZM" "ZW"] }
def timezone-completer [] { ["Africa/Algiers" "Africa/Cairo" "Africa/Casablanca" "Africa/Harare" "Africa/Johannesburg" "Africa/Monrovia" "Africa/Nairobi" "America/Argentina/Buenos_Aires" "America/Bogota" "America/Caracas" "America/Chicago" "America/Chihuahua" "America/Denver" "America/Guatemala" "America/Guyana" "America/Halifax" "America/Indiana/Indianapolis" "America/Juneau" "America/La_Paz" "America/Lima" "America/Los_Angeles" "America/Mazatlan" "America/Mexico_City" "America/Monterrey" "America/Montevideo" "America/New_York" "America/Nuuk" "America/Phoenix" "America/Puerto_Rico" "America/Regina" "America/Santiago" "America/Sao_Paulo" "America/St_Johns" "America/Tijuana" "Asia/Almaty" "Asia/Baghdad" "Asia/Baku" "Asia/Bangkok" "Asia/Chongqing" "Asia/Colombo" "Asia/Dhaka" "Asia/Hong_Kong" "Asia/Irkutsk" "Asia/Jakarta" "Asia/Jerusalem" "Asia/Kabul" "Asia/Kamchatka" "Asia/Karachi" "Asia/Kathmandu" "Asia/Kolkata" "Asia/Krasnoyarsk" "Asia/Kuala_Lumpur" "Asia/Kuwait" "Asia/Magadan" "Asia/Muscat" "Asia/Novosibirsk" "Asia/Riyadh" "Asia/Seoul" "Asia/Shanghai" "Asia/Singapore" "Asia/Srednekolymsk" "Asia/Taipei" "Asia/Tashkent" "Asia/Tbilisi" "Asia/Tehran" "Asia/Tokyo" "Asia/Ulaanbaatar" "Asia/Urumqi" "Asia/Vladivostok" "Asia/Yakutsk" "Asia/Yangon" "Asia/Yekaterinburg" "Asia/Yerevan" "Atlantic/Azores" "Atlantic/Cape_Verde" "Atlantic/South_Georgia" "Australia/Adelaide" "Australia/Brisbane" "Australia/Darwin" "Australia/Hobart" "Australia/Melbourne" "Australia/Perth" "Australia/Sydney" "Europe/Amsterdam" "Europe/Athens" "Europe/Belgrade" "Europe/Berlin" "Europe/Bratislava" "Europe/Brussels" "Europe/Bucharest" "Europe/Budapest" "Europe/Copenhagen" "Europe/Dublin" "Europe/Helsinki" "Europe/Istanbul" "Europe/Kaliningrad" "Europe/Kyiv" "Europe/Lisbon" "Europe/Ljubljana" "Europe/London" "Europe/Madrid" "Europe/Minsk" "Europe/Moscow" "Europe/Paris" "Europe/Prague" "Europe/Riga" "Europe/Rome" "Europe/Samara" "Europe/Sarajevo" "Europe/Skopje" "Europe/Sofia" "Europe/Stockholm" "Europe/Tallinn" "Europe/Vienna" "Europe/Vilnius" "Europe/Volgograd" "Europe/Warsaw" "Europe/Zagreb" "Europe/Zurich" "GMT+12" "Pacific/Apia" "Pacific/Auckland" "Pacific/Chatham" "Pacific/Fakaofo" "Pacific/Fiji" "Pacific/Guadalcanal" "Pacific/Guam" "Pacific/Honolulu" "Pacific/Majuro" "Pacific/Midway" "Pacific/Noumea" "Pacific/Pago_Pago" "Pacific/Port_Moresby" "Pacific/Tongatapu" "UTC"] }
def time-granularity-completer [] { ["daily" "monthly" "weekly"] }
def customer-type-completer [] { ["company" "individual"] }
def status-completer [] { ["active" "terminated"] }
def reason-completer [] { ["duplicated_charge" "fraudulent_charge" "order_cancellation" "order_change" "other" "product_unsatisfactory"] }
def credit-status-completer [] { ["available" "consumed" "voided"] }
def refund-status-completer [] { ["failed" "pending" "succeeded"] }
def status-completer-1 [] { ["draft" "finalized"] }
def payment-status-completer [] { ["failed" "pending" "succeeded"] }
def invoice-type-completer [] { ["add_on" "advance_charges" "credit" "one_off" "progressive_billing" "subscription"] }
def fee-type-completer [] { ["add_on" "charge" "commitment" "credit" "subscription"] }
def payment-status-completer-1 [] { ["failed" "pending" "refunded" "succeeded"] }
def billing-time-completer [] { ["anniversary" "calendar"] }
def status-completer-2 [] { ["active" "canceled" "pending" "terminated"] }
def status-completer-3 [] { ["active" "pending"] }
def on-termination-credit-note-completer [] { ["credit" "refund" "skip"] }
def on-termination-invoice-completer [] { ["generate" "skip"] }
def subscription-status-completer [] { ["active" "canceled" "pending" "terminated"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "billing-entities listBillingEntities" } } | get name | first)
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

# List all billing entities
#
# GET /billing_entities
# operationId: listBillingEntities
export def "billing-entities listBillingEntities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<billing_entities: table<lago_id: string, code: string, name: string, default_currency: string, document_locale: string, document_numbering: string, document_number_prefix: string, finalize_zero_amount_invoice: bool, invoice_footer: string, invoice_grace_period: int, subscription_invoice_issuing_date_anchor: string, subscription_invoice_issuing_date_adjustment: string, is_default: bool, net_payment_term: int, address_line1: string, address_line2: string, city: string, state: string, country: string, zipcode: string, email: string, legal_name: string, legal_number: string, tax_identification_number: string, timezone: string, email_settings: list, eu_tax_management: bool, logo_url: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/billing_entities")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a billing entity
#
# POST /billing_entities
# operationId: createBillingEntity
# --billing_entity shape: {code: string, name: string, default_currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", document_numbering?: "per_customer"|"per_billing_entity", document_number_prefix?: string, finalize_zero_amount_invoice?: bool, billing_configuration?: record, net_payment_term?: int, address_line1?: string, address_line2?: string, city?: string, state?: string, country?: "AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", zipcode?: string, email?: string, legal_name?: string, legal_number?: string, tax_identification_number?: string, timezone?: "UTC"|"Africa/Algiers"|"Africa/Cairo"|"Africa/Casablanca"|"Africa/Harare"|"Africa/Johannesburg"|"Africa/Monrovia"|"Africa/Nairobi"|"America/Argentina/Buenos_Aires"|"America/Bogota"|"America/Caracas"|"America/Chicago"|"America/Chihuahua"|"America/Denver"|"America/Guatemala"|"America/Guyana"|"America/Halifax"|"America/Indiana/Indianapolis"|"America/Juneau"|"America/La_Paz"|"America/Lima"|"America/Los_Angeles"|"America/Mazatlan"|"America/Mexico_City"|"America/Monterrey"|"America/Montevideo"|"America/New_York"|"America/Nuuk"|"America/Phoenix"|"America/Puerto_Rico"|"America/Regina"|"America/Santiago"|"America/Sao_Paulo"|"America/St_Johns"|"America/Tijuana"|"Asia/Almaty"|"Asia/Baghdad"|"Asia/Baku"|"Asia/Bangkok"|"Asia/Chongqing"|"Asia/Colombo"|"Asia/Dhaka"|"Asia/Hong_Kong"|"Asia/Irkutsk"|"Asia/Jakarta"|"Asia/Jerusalem"|"Asia/Kabul"|"Asia/Kamchatka"|"Asia/Karachi"|"Asia/Kathmandu"|"Asia/Kolkata"|"Asia/Krasnoyarsk"|"Asia/Kuala_Lumpur"|"Asia/Kuwait"|"Asia/Magadan"|"Asia/Muscat"|"Asia/Novosibirsk"|"Asia/Riyadh"|"Asia/Seoul"|"Asia/Shanghai"|"Asia/Singapore"|"Asia/Srednekolymsk"|"Asia/Taipei"|"Asia/Tashkent"|"Asia/Tbilisi"|"Asia/Tehran"|"Asia/Tokyo"|"Asia/Ulaanbaatar"|"Asia/Urumqi"|"Asia/Vladivostok"|"Asia/Yakutsk"|"Asia/Yangon"|"Asia/Yekaterinburg"|"Asia/Yerevan"|"Atlantic/Azores"|"Atlantic/Cape_Verde"|"Atlantic/South_Georgia"|"Australia/Adelaide"|"Australia/Brisbane"|"Australia/Darwin"|"Australia/Hobart"|"Australia/Melbourne"|"Australia/Perth"|"Australia/Sydney"|"Europe/Amsterdam"|"Europe/Athens"|"Europe/Belgrade"|"Europe/Berlin"|"Europe/Bratislava"|"Europe/Brussels"|"Europe/Bucharest"|"Europe/Budapest"|"Europe/Copenhagen"|"Europe/Dublin"|"Europe/Helsinki"|"Europe/Istanbul"|"Europe/Kaliningrad"|"Europe/Kyiv"|"Europe/Lisbon"|"Europe/Ljubljana"|"Europe/London"|"Europe/Madrid"|"Europe/Minsk"|"Europe/Moscow"|"Europe/Paris"|"Europe/Prague"|"Europe/Riga"|"Europe/Rome"|"Europe/Samara"|"Europe/Sarajevo"|"Europe/Skopje"|"Europe/Sofia"|"Europe/Stockholm"|"Europe/Tallinn"|"Europe/Vienna"|"Europe/Vilnius"|"Europe/Volgograd"|"Europe/Warsaw"|"Europe/Zagreb"|"Europe/Zurich"|"GMT+12"|"Pacific/Apia"|"Pacific/Auckland"|"Pacific/Chatham"|"Pacific/Fakaofo"|"Pacific/Fiji"|"Pacific/Guadalcanal"|"Pacific/Guam"|"Pacific/Honolulu"|"Pacific/Majuro"|"Pacific/Midway"|"Pacific/Noumea"|"Pacific/Pago_Pago"|"Pacific/Port_Moresby"|"Pacific/Tongatapu", email_settings?: list, eu_tax_management?: bool, logo?: string}
export def "billing-entities createBillingEntity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  billing_entity: record # shape: {code: string, name: string, default_currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", document_numbering?: "per_customer"|"per_billing_entity", document_number_prefix?: string, finalize_zero_amount_invoice?: bool, billing_configuration?: record, net_payment_term?: int, address_line1?: string, address_line2?: string, city?: string, state?: string, country?: "AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", zipcode?: string, email?: string, legal_name?: string, legal_number?: string, tax_identification_number?: string, timezone?: "UTC"|"Africa/Algiers"|"Africa/Cairo"|"Africa/Casablanca"|"Africa/Harare"|"Africa/Johannesburg"|"Africa/Monrovia"|"Africa/Nairobi"|"America/Argentina/Buenos_Aires"|"America/Bogota"|"America/Caracas"|"America/Chicago"|"America/Chihuahua"|"America/Denver"|"America/Guatemala"|"America/Guyana"|"America/Halifax"|"America/Indiana/Indianapolis"|"America/Juneau"|"America/La_Paz"|"America/Lima"|"America/Los_Angeles"|"America/Mazatlan"|"America/Mexico_City"|"America/Monterrey"|"America/Montevideo"|"America/New_York"|"America/Nuuk"|"America/Phoenix"|"America/Puerto_Rico"|"America/Regina"|"America/Santiago"|"America/Sao_Paulo"|"America/St_Johns"|"America/Tijuana"|"Asia/Almaty"|"Asia/Baghdad"|"Asia/Baku"|"Asia/Bangkok"|"Asia/Chongqing"|"Asia/Colombo"|"Asia/Dhaka"|"Asia/Hong_Kong"|"Asia/Irkutsk"|"Asia/Jakarta"|"Asia/Jerusalem"|"Asia/Kabul"|"Asia/Kamchatka"|"Asia/Karachi"|"Asia/Kathmandu"|"Asia/Kolkata"|"Asia/Krasnoyarsk"|"Asia/Kuala_Lumpur"|"Asia/Kuwait"|"Asia/Magadan"|"Asia/Muscat"|"Asia/Novosibirsk"|"Asia/Riyadh"|"Asia/Seoul"|"Asia/Shanghai"|"Asia/Singapore"|"Asia/Srednekolymsk"|"Asia/Taipei"|"Asia/Tashkent"|"Asia/Tbilisi"|"Asia/Tehran"|"Asia/Tokyo"|"Asia/Ulaanbaatar"|"Asia/Urumqi"|"Asia/Vladivostok"|"Asia/Yakutsk"|"Asia/Yangon"|"Asia/Yekaterinburg"|"Asia/Yerevan"|"Atlantic/Azores"|"Atlantic/Cape_Verde"|"Atlantic/South_Georgia"|"Australia/Adelaide"|"Australia/Brisbane"|"Australia/Darwin"|"Australia/Hobart"|"Australia/Melbourne"|"Australia/Perth"|"Australia/Sydney"|"Europe/Amsterdam"|"Europe/Athens"|"Europe/Belgrade"|"Europe/Berlin"|"Europe/Bratislava"|"Europe/Brussels"|"Europe/Bucharest"|"Europe/Budapest"|"Europe/Copenhagen"|"Europe/Dublin"|"Europe/Helsinki"|"Europe/Istanbul"|"Europe/Kaliningrad"|"Europe/Kyiv"|"Europe/Lisbon"|"Europe/Ljubljana"|"Europe/London"|"Europe/Madrid"|"Europe/Minsk"|"Europe/Moscow"|"Europe/Paris"|"Europe/Prague"|"Europe/Riga"|"Europe/Rome"|"Europe/Samara"|"Europe/Sarajevo"|"Europe/Skopje"|"Europe/Sofia"|"Europe/Stockholm"|"Europe/Tallinn"|"Europe/Vienna"|"Europe/Vilnius"|"Europe/Volgograd"|"Europe/Warsaw"|"Europe/Zagreb"|"Europe/Zurich"|"GMT+12"|"Pacific/Apia"|"Pacific/Auckland"|"Pacific/Chatham"|"Pacific/Fakaofo"|"Pacific/Fiji"|"Pacific/Guadalcanal"|"Pacific/Guam"|"Pacific/Honolulu"|"Pacific/Majuro"|"Pacific/Midway"|"Pacific/Noumea"|"Pacific/Pago_Pago"|"Pacific/Port_Moresby"|"Pacific/Tongatapu", email_settings?: list, eu_tax_management?: bool, logo?: string}
]: any -> record<lago_id: string, code: string, name: string, default_currency: string, document_locale: string, document_numbering: string, document_number_prefix: string, finalize_zero_amount_invoice: bool, invoice_footer: string, invoice_grace_period: int, subscription_invoice_issuing_date_anchor: string, subscription_invoice_issuing_date_adjustment: string, is_default: bool, net_payment_term: int, address_line1: string, address_line2: string, city: string, state: string, country: string, zipcode: string, email: string, legal_name: string, legal_number: string, tax_identification_number: string, timezone: string, email_settings: list<string>, eu_tax_management: bool, logo_url: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/billing_entities")
  let body = {billing_entity: $billing_entity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a billing entity
#
# GET /billing_entities/{code}
# operationId: getBillingEntity
export def "billing-entities get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<billing_entity: record<lago_id: string, code: string, name: string, default_currency: string, document_locale: string, document_numbering: string, document_number_prefix: string, finalize_zero_amount_invoice: bool, invoice_footer: string, invoice_grace_period: int, subscription_invoice_issuing_date_anchor: string, subscription_invoice_issuing_date_adjustment: string, is_default: bool, net_payment_term: int, address_line1: string, address_line2: string, city: string, state: string, country: string, zipcode: string, email: string, legal_name: string, legal_number: string, tax_identification_number: string, timezone: string, email_settings: list<string>, eu_tax_management: bool, logo_url: string, created_at: string, updated_at: string, taxes: list<record>, selected_invoice_custom_sections: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/billing_entities/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a billing entity
#
# PUT /billing_entities/{code}
# operationId: updateBillingEntity
# --billing_configuration shape: {invoice_footer?: string, document_locale?: string, invoice_grace_period?: int, subscription_invoice_issuing_date_anchor?: "current_period_end"|"next_period_start", subscription_invoice_issuing_date_adjustment?: "align_with_finalization_date"|"keep_anchor"}
export def "billing-entities updateBillingEntity" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the billing entity (e.g. Acme Corp)
  --default-currency: string@default-currency-completer # e.g. USD
  --document-numbering: string@document-numbering-completer # The type of document numbering for this billing entity: - `per_customer`: document numbers are unique per customer - `per_billing_entity`: document numbers are unique per billing entity
  --document-number-prefix: string # The prefix used in document numbers for this billing entity (nullable, e.g. ABC-123)
  --finalize-zero-amount-invoice: string@bool-completer # Whether to finalize invoices with zero amount for this billing entity (e.g. true)
  --billing-configuration: record # shape: {invoice_footer?: string, document_locale?: string, invoice_grace_period?: int, subscription_invoice_issuing_date_anchor?: "current_period_end"|"next_period_start", subscription_invoice_issuing_date_adjustment?: "align_with_finalization_date"|"keep_anchor"}
  --net-payment-term: int # The net payment term (in days) for this billing entity (e.g. 0)
  --address-line1: string # The first line of the billing address (nullable, e.g. 5230 Penfield Ave)
  --address-line2: string # The second line of the billing address (nullable, e.g. Suite 100)
  --city: string # The city of the billing address (nullable, e.g. Woodland Hills)
  --state: string # The state of the billing address (nullable, e.g. CA)
  --country: string@country-completer # e.g. US
  --zipcode: string # The zipcode of the billing address (nullable, e.g. 91364)
  --email: string # The email address of the billing entity (nullable, format: email, e.g. billing@acme.com)
  --legal-name: string # The legal name of the billing entity (nullable, e.g. Acme Corporation)
  --legal-number: string # The legal registration number of the billing entity (nullable, e.g. US123456789)
  --tax-identification-number: string # The tax identification number of the billing entity (nullable, e.g. EU123456789)
  --timezone: string@timezone-completer # e.g. America/Los_Angeles
  --tax-codes: list # List of unique code used to identify the taxes. (e.g. [french_standard_vat])
  --email-settings: list # The email notification settings for this billing entity
  --eu-tax-management: string@bool-completer # Whether EU tax management is enabled for this billing entity (e.g. false)
  --logo: string # The base64 encoded logo image for the billing entity. Sending "null" will remove the logo, if any exist. (nullable, format: uri, e.g. data:image/png;base64,...)
  --invoice-custom-section-codes: list # The codes of the invoice custom section that should be associated with this billing entity (e.g. [custom_section_1, custom_section_2])
]: any -> record<lago_id: string, code: string, name: string, default_currency: string, document_locale: string, document_numbering: string, document_number_prefix: string, finalize_zero_amount_invoice: bool, invoice_footer: string, invoice_grace_period: int, subscription_invoice_issuing_date_anchor: string, subscription_invoice_issuing_date_adjustment: string, is_default: bool, net_payment_term: int, address_line1: string, address_line2: string, city: string, state: string, country: string, zipcode: string, email: string, legal_name: string, legal_number: string, tax_identification_number: string, timezone: string, email_settings: list<string>, eu_tax_management: bool, logo_url: string, created_at: string, updated_at: string, taxes: table<lago_id: string, name: string, code: string, description: string, rate: float, applied_to_organization: bool, created_at: string>, selected_invoice_custom_sections: table<lago_id: string, name: string, code: string, description: string, details: string, display_name: string, applied_to_organization: bool, organization_id: string, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/billing_entities/($code)")
  let body = {name: $name, default_currency: $default_currency, document_numbering: $document_numbering, document_number_prefix: $document_number_prefix, finalize_zero_amount_invoice: $finalize_zero_amount_invoice, billing_configuration: $billing_configuration, net_payment_term: $net_payment_term, address_line1: $address_line1, address_line2: $address_line2, city: $city, state: $state, country: $country, zipcode: $zipcode, email: $email, legal_name: $legal_name, legal_number: $legal_number, tax_identification_number: $tax_identification_number, timezone: $timezone, tax_codes: $tax_codes, email_settings: $email_settings, eu_tax_management: $eu_tax_management, logo: $logo, invoice_custom_section_codes: $invoice_custom_section_codes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all activity logs
#
# GET /activity_logs
# operationId: findAllActivityLogs
export def "activity-logs findAllActivityLogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --from-date: string # Filter activity logs from a specific date. (format: date, e.g. 2022-08-09)
  --to-date: string # Filter activity logs up to a specific date. (format: date, e.g. 2022-08-09)
  --activity-types: list # Filter results by activity types (e.g. [billing_metric.created, billing_metric.updated])
  --activity-sources: list # Filter results by activity sources (e.g. [api, front])
  --user-emails: list # Filter results by user emails (e.g. [dinesh@piedpiper.test])
  --external-customer-id: string # Unique identifier assigned to the customer in your application. (e.g. 5eb02857-a71e-4ea2-bcf9-57d3a41bc6ba)
  --external-subscription-id: string # External subscription ID (e.g. 5eb02857-a71e-4ea2-bcf9-57d3a41bc6ba)
  --resource-ids: list # Filter results by resources unique identifiers (e.g. [5eb02857-a71e-4ea2-bcf9-57d3a41bc6ba, 1a901a90-1a90-1a90-1a90-1a901a901a90])
  --resource-types: list # Filter results by resource class types (e.g. [BillableMetric, Invoice])
]: nothing -> record<activity_logs: table<activity_id: string, user_email: string, activity_type: string, activity_source: string, activity_object: record, activity_object_changes: record, external_customer_id: string, external_subscription_id: string, resource_id: string, resource_type: string, organization_id: string, logged_at: string, created_at: string>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "activity_types[]" $activity_types "multi") (serialize-qp "activity_sources[]" $activity_sources "multi") (serialize-qp "user_emails[]" $user_emails "multi") (serialize-qp "external_customer_id" $external_customer_id "scalar") (serialize-qp "external_subscription_id" $external_subscription_id "scalar") (serialize-qp "resource_ids[]" $resource_ids "multi") (serialize-qp "resource_types[]" $resource_types "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/activity_logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve an activity log
#
# GET /activity_logs/{activity_id}
# operationId: findActivityLog
export def "activity-logs findActivityLog" [
  activity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<activity_log: record<activity_id: string, user_email: string, activity_type: string, activity_source: string, activity_object: record, activity_object_changes: record, external_customer_id: string, external_subscription_id: string, resource_id: string, resource_type: string, organization_id: string, logged_at: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity_logs/($activity_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an add-on
#
# POST /add_ons
# operationId: createAddOn
# --add_on shape: {name?: string, invoice_display_name?: string, code?: string, amount_cents?: int, amount_currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", description?: string, tax_codes?: list}
export def "add-ons createAddOn" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  add_on: record # shape: {name?: string, invoice_display_name?: string, code?: string, amount_cents?: int, amount_currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", description?: string, tax_codes?: list}
]: any -> record<add_on: record<lago_id: string, name: string, invoice_display_name: string, code: string, amount_cents: int, amount_currency: string, description: string, created_at: string, taxes: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/add_ons")
  let body = {add_on: $add_on} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all add-ons
#
# GET /add_ons
# operationId: findAllAddOns
export def "add-ons findAllAddOns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
]: nothing -> record<add_ons: table<lago_id: string, name: string, invoice_display_name: string, code: string, amount_cents: int, amount_currency: string, description: string, created_at: string, taxes: list>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/add_ons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an add-on
#
# PUT /add_ons/{code}
# operationId: updateAddOn
# --add_on shape: {name?: string, invoice_display_name?: string, code?: string, amount_cents?: int, amount_currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", description?: string, tax_codes?: list}
export def "add-ons updateAddOn" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  add_on: record # shape: {name?: string, invoice_display_name?: string, code?: string, amount_cents?: int, amount_currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", description?: string, tax_codes?: list}
]: any -> record<add_on: record<lago_id: string, name: string, invoice_display_name: string, code: string, amount_cents: int, amount_currency: string, description: string, created_at: string, taxes: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/add_ons/($code)")
  let body = {add_on: $add_on} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an add-on
#
# GET /add_ons/{code}
# operationId: findAddOn
export def "add-ons findAddOn" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<add_on: record<lago_id: string, name: string, invoice_display_name: string, code: string, amount_cents: int, amount_currency: string, description: string, created_at: string, taxes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/add_ons/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an add-on
#
# DELETE /add_ons/{code}
# operationId: destroyAddOn
export def "add-ons destroyAddOn" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<add_on: record<lago_id: string, name: string, invoice_display_name: string, code: string, amount_cents: int, amount_currency: string, description: string, created_at: string, taxes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/add_ons/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all api logs
#
# GET /api_logs
# operationId: findAllApiLogs
export def "api-logs findAllApiLogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --from-date: string # Filter api logs from a specific date. (format: date, e.g. 2022-08-09)
  --to-date: string # Filter api logs up to a specific date. (format: date, e.g. 2022-08-09)
  --http-methods: list # Filter results by HTTP methods (e.g. [post, put])
  --http-statuses: list # Filter results by HTTP status or by generic request status (e.g. [failed, succeeded, 404])
  --api-version: string # Filter results by API version (e.g. v1)
  --request-paths: string # Filter results by the path of the request (e.g. /billable_metrics/)
]: nothing -> record<api_logs: table<api_version: string, client: string, http_method: string, http_status: int, logged_at: string, request_body: string, request_origin: string, request_path: string, created_at: string, request_id: string, request_response: string>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "http_methods[]" $http_methods "multi") (serialize-qp "http_statuses[]" $http_statuses "multi") (serialize-qp "api_version" $api_version "scalar") (serialize-qp "request_paths" $request_paths "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api_logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve an api log
#
# GET /api_logs/{request_id}
# operationId: findApiLog
export def "api-logs findApiLog" [
  request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<api_log: record<api_version: string, client: string, http_method: string, http_status: int, logged_at: string, request_body: string, request_origin: string, request_path: string, created_at: string, request_id: string, request_response: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api_logs/($request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List gross revenue
#
# GET /analytics/gross_revenue
# operationId: findAllGrossRevenues
export def "analytics-gross-revenue findAllGrossRevenues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --currency: string # Currency of revenue analytics. Format must be ISO 4217.
  --external-customer-id: string # The customer external unique identifier (provided by your own application). Use it to filter revenue analytics at the customer level. (e.g. 5eb02857-a71e-4ea2-bcf9-57d3a41bc6ba)
  --months: int # Show data only for given number of months. (e.g. 12)
]: nothing -> record<gross_revenues: table<month: string, amount_cents: int, currency: string, invoices_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currency" $currency "scalar") (serialize-qp "external_customer_id" $external_customer_id "scalar") (serialize-qp "months" $months "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/analytics/gross_revenue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List of finalized invoices
#
# GET /analytics/invoice_collection
# operationId: findAllInvoiceCollections
export def "analytics-invoice-collection findAllInvoiceCollections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --currency: string # The currency of revenue analytics. Format must be ISO 4217.
  --months: int # Show data only for given number of months. (e.g. 12)
]: nothing -> record<invoice_collections: table<month: string, payment_status: string, invoices_count: int, amount_cents: int, currency: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currency" $currency "scalar") (serialize-qp "months" $months "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/analytics/invoice_collection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List usage revenue
#
# GET /analytics/invoiced_usage
# operationId: findAllInvoicedUsages
export def "analytics-invoiced-usage findAllInvoicedUsages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --currency: string # The currency of invoiced usage analytics. Format must be ISO 4217.
  --months: int # Show data only for given number of months. (e.g. 12)
]: nothing -> record<invoiced_usages: table<month: string, code: string, amount_cents: int, currency: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currency" $currency "scalar") (serialize-qp "months" $months "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/analytics/invoiced_usage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List MRR
#
# GET /analytics/mrr
# operationId: findAllMrrs
export def "analytics-mrr findAllMrrs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --currency: string # Quantifies the revenue generated from `subscription` fees on a monthly basis. This figure is calculated post-application of applicable taxes and deduction of any applicable discounts. The method of calculation varies based on the subscription billing cycle:  - Revenue from `monthly` subscription invoices is included in the MRR for the month in which the invoice is issued. - Revenue from `quarterly` subscription invoices is distributed evenly over three months. This distribution applies to fees paid in advance (allocated to the next remaining months depending on calendar or anniversary billing) as well as to fees paid in arrears (allocated to the preceding months depending on calendar or anniversary billing). - Revenue from `yearly` subscription invoices is distributed evenly over twelve months. This allocation is applicable for fees paid in advance (spread over the next remaining months depending on calendar or anniversary billing) and for fees paid in arrears (spread over the previous months depending on calendar or anniversary billing). - Revenue from `semiannual` subscription invoices is distributed evenly over six months. This allocation is applicable for fees paid in advance (spread over the next remaining months depending on calendar or anniversary billing) and for fees paid in arrears (spread over the previous months depending on calendar or anniversary billing). - Revenue from `weekly` subscription invoices, the total revenue from all invoices issued within a month is summed up. This total is then divided by the number of invoices issued during that month, and the result is multiplied by 4.33, representing the average number of weeks in a month.
  --months: int # Show data only for given number of months. (e.g. 12)
]: nothing -> record<mrrs: table<month: string, amount_cents: int, currency: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currency" $currency "scalar") (serialize-qp "months" $months "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/analytics/mrr" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List overdue balance
#
# GET /analytics/overdue_balance
# operationId: findAllOverdueBalances
export def "analytics-overdue-balance findAllOverdueBalances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --currency: string # Currency of revenue analytics. Format must be ISO 4217.
  --external-customer-id: string # The customer external unique identifier (provided by your own application). Use it to filter revenue analytics at the customer level. (e.g. 5eb02857-a71e-4ea2-bcf9-57d3a41bc6ba)
  --months: int # Show data only for given number of months. (e.g. 12)
]: nothing -> record<overdue_balances: table<month: string, amount_cents: int, currency: string, lago_invoice_ids: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currency" $currency "scalar") (serialize-qp "external_customer_id" $external_customer_id "scalar") (serialize-qp "months" $months "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/analytics/overdue_balance" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List usage
#
# GET /analytics/usage
# operationId: findAllUsages
export def "analytics-usage findAllUsages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --time-granularity: string@time-granularity-completer # The time granularity of usage analytics. Possible values are 'daily', 'weekly', 'monthly', 'yearly'. (e.g. monthly)
  --currency: string # The currency of usage analytics. Format must be ISO 4217.
  --from-date: string # The start date of the period for which the usage analytics is calculated. (format: date, e.g. 2023-11-01)
  --to-date: string # The end date of the period for which the usage analytics is calculated. (format: date, e.g. 2023-11-30)
  --customer-type: string@customer-type-completer # The type of customer for which the usage analytics is calculated. Possible values are 'individual', 'company'. (e.g. individual)
  --external-customer-id: string # The external identifier of the customer for which the usage analytics is calculated. (e.g. ext-customer-123)
  --customer-country: string # The country of the customer for which the usage analytics is calculated.
  --external-subscription-id: string # The external identifier of the subscription for which the usage analytics is calculated. (e.g. ext-subscription-123)
  --is-billable-metric-recurring: string@bool-completer # Indicates whether the billable metric associated with the usage is recurring. (e.g. true)
  --plan-code: string # The code of the plan for which the usage analytics is calculated. (e.g. plan-code-123)
  --billable-metric-code: string # The code of the usage-based billable metrics for which the usage analytics is calculated. (e.g. code1)
]: nothing -> record<usages: table<organization_id: string, start_of_period_dt: string, end_of_period_dt: string, amount_currency: string, amount_cents: int, billable_metric_code: string, units: string, is_billable_metric_deleted: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time_granularity" $time_granularity "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "customer_type" $customer_type "scalar") (serialize-qp "external_customer_id" $external_customer_id "scalar") (serialize-qp "customer_country" $customer_country "scalar") (serialize-qp "external_subscription_id" $external_subscription_id "scalar") (serialize-qp "is_billable_metric_recurring" $is_billable_metric_recurring "scalar") (serialize-qp "plan_code" $plan_code "scalar") (serialize-qp "billable_metric_code" $billable_metric_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/analytics/usage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Apply a coupon to a customer
#
# POST /applied_coupons
# operationId: applyCoupon
# --applied_coupon shape: {external_customer_id: string, coupon_code: string, frequency?: "once"|"recurring"|"forever", frequency_duration?: int, amount_cents?: int, amount_currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", percentage_rate?: string}
export def "applied-coupons applyCoupon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  applied_coupon: record # shape: {external_customer_id: string, coupon_code: string, frequency?: "once"|"recurring"|"forever", frequency_duration?: int, amount_cents?: int, amount_currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", percentage_rate?: string}
]: any -> record<applied_coupon: record<lago_id: string, lago_coupon_id: string, coupon_code: string, coupon_name: string, coupon_status: string, coupon_deleted_at: string, lago_customer_id: string, external_customer_id: string, status: string, amount_cents: int, amount_cents_remaining: int, amount_currency: string, percentage_rate: string, frequency: string, frequency_duration: int, frequency_duration_remaining: int, expiration_at: string, created_at: string, terminated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/applied_coupons")
  let body = {applied_coupon: $applied_coupon} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all applied coupons
#
# GET /applied_coupons
# operationId: findAllAppliedCoupons
export def "applied-coupons findAllAppliedCoupons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --status: string@status-completer # The status of the coupon. Can be either `active` or `terminated`. (e.g. active)
  --external-customer-id: string # The customer external unique identifier (provided by your own application) (e.g. 5eb02857-a71e-4ea2-bcf9-57d3a41bc6ba)
  --coupon-code: list # The code of the coupon applied to the customer. Use it to filter applied coupons by their code. (e.g. [BLACK_FRIDAY_2024, CHRISTMAS_2024])
]: nothing -> record<applied_coupons: table<lago_id: string, lago_coupon_id: string, coupon_code: string, coupon_name: string, coupon_status: string, coupon_deleted_at: string, lago_customer_id: string, external_customer_id: string, status: string, amount_cents: int, amount_cents_remaining: int, amount_currency: string, percentage_rate: string, frequency: string, frequency_duration: int, frequency_duration_remaining: int, expiration_at: string, created_at: string, terminated_at: string, credits: list>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "external_customer_id" $external_customer_id "scalar") (serialize-qp "coupon_code[]" $coupon_code "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/applied_coupons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a billable metric
#
# POST /billable_metrics
# operationId: createBillableMetric
# --billable_metric shape: {name?: string, code?: string, description?: string, recurring?: bool, expression?: string, rounding_function?: "ceil"|"floor"|"round", rounding_precision?: int, field_name?: string, aggregation_type?: "count_agg"|"sum_agg"|"max_agg"|"unique_count_agg"|"weighted_sum_agg"|"latest_agg", weighted_interval?: "seconds", filters?: list}
export def "billable-metrics createBillableMetric" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  billable_metric: record # shape: {name?: string, code?: string, description?: string, recurring?: bool, expression?: string, rounding_function?: "ceil"|"floor"|"round", rounding_precision?: int, field_name?: string, aggregation_type?: "count_agg"|"sum_agg"|"max_agg"|"unique_count_agg"|"weighted_sum_agg"|"latest_agg", weighted_interval?: "seconds", filters?: list}
]: any -> record<billable_metric: record<lago_id: string, name: string, code: string, description: string, recurring: bool, rounding_function: string, rounding_precision: int, created_at: string, expression: string, field_name: string, aggregation_type: string, weighted_interval: string, filters: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/billable_metrics")
  let body = {billable_metric: $billable_metric} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all billable metrics
#
# GET /billable_metrics
# operationId: findAllBillableMetrics
export def "billable-metrics findAllBillableMetrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
]: nothing -> record<billable_metrics: table<lago_id: string, name: string, code: string, description: string, recurring: bool, rounding_function: string, rounding_precision: int, created_at: string, expression: string, field_name: string, aggregation_type: string, weighted_interval: string, filters: list>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/billable_metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Evaluate an expression for a billable metric
#
# POST /billable_metrics/evaluate_expression
# operationId: evaluateBillableMetricExpression
# --event shape: {code: string, timestamp?: any, properties: record}
export def "billable-metrics-evaluate-expression evaluateBillableMetricExpression" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  expression: string # Expression used to calculate the event units. The expression is evalutated for each event and the result is then used to calculate the total aggregated units. Accepted function are `ceil`, `concat` and `round` as well as `+`, `-`, `\` and `*` operations. Round is accepting an optional second parameter to specify the number of decimal.  (e.g. round((ended_at - started_at) * units))
  event: record # shape: {code: string, timestamp?: any, properties: record}
]: any -> record<expression_result: record<value: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/billable_metrics/evaluate_expression")
  let body = {expression: $expression, event: $event} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a billable metric
#
# PUT /billable_metrics/{code}
# operationId: updateBillableMetric
# --billable_metric shape: {name?: string, code?: string, description?: string, recurring?: bool, expression?: string, rounding_function?: "ceil"|"floor"|"round", rounding_precision?: int, field_name?: string, aggregation_type?: "count_agg"|"sum_agg"|"max_agg"|"unique_count_agg"|"weighted_sum_agg"|"latest_agg", weighted_interval?: "seconds", filters?: list}
export def "billable-metrics updateBillableMetric" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  billable_metric: record # shape: {name?: string, code?: string, description?: string, recurring?: bool, expression?: string, rounding_function?: "ceil"|"floor"|"round", rounding_precision?: int, field_name?: string, aggregation_type?: "count_agg"|"sum_agg"|"max_agg"|"unique_count_agg"|"weighted_sum_agg"|"latest_agg", weighted_interval?: "seconds", filters?: list}
]: any -> record<billable_metric: record<lago_id: string, name: string, code: string, description: string, recurring: bool, rounding_function: string, rounding_precision: int, created_at: string, expression: string, field_name: string, aggregation_type: string, weighted_interval: string, filters: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/billable_metrics/($code)")
  let body = {billable_metric: $billable_metric} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a billable metric
#
# DELETE /billable_metrics/{code}
# operationId: destroyBillableMetric
export def "billable-metrics destroyBillableMetric" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<billable_metric: record<lago_id: string, name: string, code: string, description: string, recurring: bool, rounding_function: string, rounding_precision: int, created_at: string, expression: string, field_name: string, aggregation_type: string, weighted_interval: string, filters: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/billable_metrics/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a billable metric
#
# GET /billable_metrics/{code}
# operationId: findBillableMetric
export def "billable-metrics findBillableMetric" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<billable_metric: record<lago_id: string, name: string, code: string, description: string, recurring: bool, rounding_function: string, rounding_precision: int, created_at: string, expression: string, field_name: string, aggregation_type: string, weighted_interval: string, filters: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/billable_metrics/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a feature
#
# POST /features
# operationId: createFeature
export def "features createFeature" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  feature: any
]: any -> record<feature: record<code: string, name: string, description: string, privileges: list<record>, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/features")
  let body = {feature: $feature} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all features
#
# GET /features
# operationId: findAllFeatures
export def "features findAllFeatures" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --search-term: string # Search in name, code and description.
]: nothing -> record<features: table<code: string, name: string, description: string, privileges: list, created_at: string>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "search_term" $search_term "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/features" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a feature
#
# PUT /features/{code}
# operationId: updateFeature
# --feature shape: {name?: string, description?: string, privileges?: list}
export def "features updateFeature" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  feature: record # shape: {name?: string, description?: string, privileges?: list}
]: any -> record<feature: record<code: string, name: string, description: string, privileges: list<record>, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/features/($code)")
  let body = {feature: $feature} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a feature
#
# DELETE /features/{code}
# operationId: destroyFeature
export def "features destroyFeature" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<feature: record<code: string, name: string, description: string, privileges: list<record>, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/features/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a feature
#
# GET /features/{code}
# operationId: findFeature
export def "features findFeature" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<feature: record<code: string, name: string, description: string, privileges: list<record>, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/features/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a privilege. Deleting a privilege removes it from all plans and subscriptions.
#
# DELETE /features/{code}/privileges/{privilege_code}
# operationId: deleteFeaturePrivilege
export def "features-privileges delete" [
  code: string
  privilege_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<feature: record<code: string, name: string, description: string, privileges: list<record>, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/features/($code)/privileges/($privilege_code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a coupon
#
# POST /coupons
# operationId: createCoupon
# --coupon shape: {name?: string, code?: string, description?: string, coupon_type?: "fixed_amount"|"percentage", amount_cents?: int, amount_currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", reusable?: bool, percentage_rate?: string, frequency?: "once"|"recurring"|"forever", frequency_duration?: int, expiration?: "no_expiration"|"time_limit", expiration_at?: string, applies_to?: record}
export def "coupons createCoupon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  coupon: record # shape: {name?: string, code?: string, description?: string, coupon_type?: "fixed_amount"|"percentage", amount_cents?: int, amount_currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", reusable?: bool, percentage_rate?: string, frequency?: "once"|"recurring"|"forever", frequency_duration?: int, expiration?: "no_expiration"|"time_limit", expiration_at?: string, applies_to?: record}
]: any -> record<coupon: record<lago_id: string, name: string, code: string, description: string, coupon_type: string, amount_cents: int, amount_currency: string, reusable: bool, limited_plans: bool, plan_codes: list<string>, limited_billable_metrics: bool, billable_metric_codes: list<string>, percentage_rate: string, frequency: string, frequency_duration: int, expiration: string, expiration_at: string, created_at: string, terminated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/coupons")
  let body = {coupon: $coupon} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all coupons
#
# GET /coupons
# operationId: findAllCoupons
export def "coupons findAllCoupons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
]: nothing -> record<coupons: table<lago_id: string, name: string, code: string, description: string, coupon_type: string, amount_cents: int, amount_currency: string, reusable: bool, limited_plans: bool, plan_codes: list, limited_billable_metrics: bool, billable_metric_codes: list, percentage_rate: string, frequency: string, frequency_duration: int, expiration: string, expiration_at: string, created_at: string, terminated_at: string>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/coupons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a coupon
#
# PUT /coupons/{code}
# operationId: updateCoupon
# --coupon shape: {name?: string, code?: string, description?: string, coupon_type?: "fixed_amount"|"percentage", amount_cents?: int, amount_currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", reusable?: bool, percentage_rate?: string, frequency?: "once"|"recurring"|"forever", frequency_duration?: int, expiration?: "no_expiration"|"time_limit", expiration_at?: string, applies_to?: record}
export def "coupons updateCoupon" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  coupon: record # shape: {name?: string, code?: string, description?: string, coupon_type?: "fixed_amount"|"percentage", amount_cents?: int, amount_currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", reusable?: bool, percentage_rate?: string, frequency?: "once"|"recurring"|"forever", frequency_duration?: int, expiration?: "no_expiration"|"time_limit", expiration_at?: string, applies_to?: record}
]: any -> record<coupon: record<lago_id: string, name: string, code: string, description: string, coupon_type: string, amount_cents: int, amount_currency: string, reusable: bool, limited_plans: bool, plan_codes: list<string>, limited_billable_metrics: bool, billable_metric_codes: list<string>, percentage_rate: string, frequency: string, frequency_duration: int, expiration: string, expiration_at: string, created_at: string, terminated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coupons/($code)")
  let body = {coupon: $coupon} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a coupon
#
# GET /coupons/{code}
# operationId: findCoupon
export def "coupons findCoupon" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<coupon: record<lago_id: string, name: string, code: string, description: string, coupon_type: string, amount_cents: int, amount_currency: string, reusable: bool, limited_plans: bool, plan_codes: list<string>, limited_billable_metrics: bool, billable_metric_codes: list<string>, percentage_rate: string, frequency: string, frequency_duration: int, expiration: string, expiration_at: string, created_at: string, terminated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coupons/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a coupon
#
# DELETE /coupons/{code}
# operationId: destroyCoupon
export def "coupons destroyCoupon" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<coupon: record<lago_id: string, name: string, code: string, description: string, coupon_type: string, amount_cents: int, amount_currency: string, reusable: bool, limited_plans: bool, plan_codes: list<string>, limited_billable_metrics: bool, billable_metric_codes: list<string>, percentage_rate: string, frequency: string, frequency_duration: int, expiration: string, expiration_at: string, created_at: string, terminated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coupons/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a credit note
#
# POST /credit_notes
# operationId: createCreditNote
# --credit_note shape: {invoice_id: string, reason?: "duplicated_charge"|"product_unsatisfactory"|"order_change"|"order_cancellation"|"fraudulent_charge"|"other", description?: string, credit_amount_cents?: int, refund_amount_cents?: int, offset_amount_cents?: int, items: list, metadata?: record}
export def "credit-notes createCreditNote" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  credit_note: record # shape: {invoice_id: string, reason?: "duplicated_charge"|"product_unsatisfactory"|"order_change"|"order_cancellation"|"fraudulent_charge"|"other", description?: string, credit_amount_cents?: int, refund_amount_cents?: int, offset_amount_cents?: int, items: list, metadata?: record}
]: any -> record<credit_note: record<lago_id: string, billing_entity_code: string, sequential_id: int, number: string, lago_invoice_id: string, invoice_number: string, issuing_date: string, credit_status: string, refund_status: string, reason: string, description: string, currency: string, total_amount_cents: int, taxes_amount_cents: int, taxes_rate: float, sub_total_excluding_taxes_amount_cents: int, balance_amount_cents: int, credit_amount_cents: int, refund_amount_cents: int, offset_amount_cents: int, coupons_adjustment_amount_cents: int, created_at: string, updated_at: string, file_url: string, items: list<record>, applied_taxes: list<record>, self_billed: bool, customer: record<lago_id: string, sequential_id: int, slug: string, external_id: string, billing_entity_code: string, address_line1: string, address_line2: string, applicable_timezone: string, city: string, country: string, currency: string, email: string, legal_name: string, legal_number: string, logo_url: string, name: string, firstname: string, lastname: string, account_type: string, customer_type: string, phone: string, state: string, tax_identification_number: string, timezone: string, url: string, zipcode: string, net_payment_term: int, created_at: string, updated_at: string, finalize_zero_amount_invoice: string, skip_invoice_custom_sections: bool, billing_configuration: record, shipping_address: record, metadata: list>, metadata: record, error_details: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit_notes")
  let body = {credit_note: $credit_note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all credit notes
#
# GET /credit_notes
# operationId: findAllCreditNotes
export def "credit-notes findAllCreditNotes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --external-customer-id: string # Unique identifier assigned to the customer in your application. (e.g. 5eb02857-a71e-4ea2-bcf9-57d3a41bc6ba)
  --issuing-date-from: string # Filter credit notes starting from a specific date. (format: date, e.g. 2022-07-08)
  --issuing-date-to: string # Filter credit notes up to a specific date. (format: date, e.g. 2022-08-09)
  --search-term: string # Search credit notes by id, number, customer name, customer external_id or customer email. (e.g. Jane)
  --currency: string # Filter credit notes by currency. Possible values ISO 4217 currency codes. (e.g. EUR)
  --reason: string@reason-completer # Filter credit notes by reasons. Possible values are `product_unsatisfactory`, `order_change`, `order_cancellation`, `fraudulent_charge`, `duplicated_charge` or `other`.
  --credit-status: string@credit-status-completer # Filter credit notes by credit status. Possible values are `available`, `consumed`  or `voided`.
  --refund-status: string@refund-status-completer # Filter credit notes by refund status. Possible values are `pending`, `succeeded`  or `failed`.
  --invoice-number: string # Filter credit notes by their related invoice number. (e.g. INV-001-002)
  --amount-from: int # Filter credit notes of at least a specific amount. This parameter must be defined in cents to ensure consistent handling for all currency types. (e.g. 9000)
  --amount-to: int # Filter credit notes up to a specific amount. This parameter must be defined in cents to ensure consistent handling for all currency types. (e.g. 100000)
  --self-billed: string@bool-completer # Filter credit notes belonging to a self billed invoice. Possible values are `true` or `false`. (e.g. true)
  --billing-entity-codes: list # Filter credit notes by billing entity codes. (e.g. [billing_entity_code_1, billing_entity_code_2])
]: nothing -> record<credit_notes: table<lago_id: string, billing_entity_code: string, sequential_id: int, number: string, lago_invoice_id: string, invoice_number: string, issuing_date: string, credit_status: string, refund_status: string, reason: string, description: string, currency: string, total_amount_cents: int, taxes_amount_cents: int, taxes_rate: float, sub_total_excluding_taxes_amount_cents: int, balance_amount_cents: int, credit_amount_cents: int, refund_amount_cents: int, offset_amount_cents: int, coupons_adjustment_amount_cents: int, created_at: string, updated_at: string, file_url: string, items: list, applied_taxes: list, self_billed: bool, customer: record, metadata: record, error_details: list>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "external_customer_id" $external_customer_id "scalar") (serialize-qp "issuing_date_from" $issuing_date_from "scalar") (serialize-qp "issuing_date_to" $issuing_date_to "scalar") (serialize-qp "search_term" $search_term "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "reason" $reason "scalar") (serialize-qp "credit_status" $credit_status "scalar") (serialize-qp "refund_status" $refund_status "scalar") (serialize-qp "invoice_number" $invoice_number "scalar") (serialize-qp "amount_from" $amount_from "scalar") (serialize-qp "amount_to" $amount_to "scalar") (serialize-qp "self_billed" $self_billed "scalar") (serialize-qp "billing_entity_codes[]" $billing_entity_codes "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/credit_notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a credit note
#
# PUT /credit_notes/{lago_id}
# operationId: updateCreditNote
# --credit_note shape: {refund_status: "pending"|"succeeded"|"failed", metadata?: record}
export def "credit-notes updateCreditNote" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  credit_note: record # shape: {refund_status: "pending"|"succeeded"|"failed", metadata?: record}
]: any -> record<credit_note: record<lago_id: string, billing_entity_code: string, sequential_id: int, number: string, lago_invoice_id: string, invoice_number: string, issuing_date: string, credit_status: string, refund_status: string, reason: string, description: string, currency: string, total_amount_cents: int, taxes_amount_cents: int, taxes_rate: float, sub_total_excluding_taxes_amount_cents: int, balance_amount_cents: int, credit_amount_cents: int, refund_amount_cents: int, offset_amount_cents: int, coupons_adjustment_amount_cents: int, created_at: string, updated_at: string, file_url: string, items: list<record>, applied_taxes: list<record>, self_billed: bool, customer: record<lago_id: string, sequential_id: int, slug: string, external_id: string, billing_entity_code: string, address_line1: string, address_line2: string, applicable_timezone: string, city: string, country: string, currency: string, email: string, legal_name: string, legal_number: string, logo_url: string, name: string, firstname: string, lastname: string, account_type: string, customer_type: string, phone: string, state: string, tax_identification_number: string, timezone: string, url: string, zipcode: string, net_payment_term: int, created_at: string, updated_at: string, finalize_zero_amount_invoice: string, skip_invoice_custom_sections: bool, billing_configuration: record, shipping_address: record, metadata: list>, metadata: record, error_details: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/credit_notes/($lago_id)")
  let body = {credit_note: $credit_note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a credit note
#
# GET /credit_notes/{lago_id}
# operationId: findCreditNote
export def "credit-notes findCreditNote" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<credit_note: record<lago_id: string, billing_entity_code: string, sequential_id: int, number: string, lago_invoice_id: string, invoice_number: string, issuing_date: string, credit_status: string, refund_status: string, reason: string, description: string, currency: string, total_amount_cents: int, taxes_amount_cents: int, taxes_rate: float, sub_total_excluding_taxes_amount_cents: int, balance_amount_cents: int, credit_amount_cents: int, refund_amount_cents: int, offset_amount_cents: int, coupons_adjustment_amount_cents: int, created_at: string, updated_at: string, file_url: string, items: list<record>, applied_taxes: list<record>, self_billed: bool, customer: record<lago_id: string, sequential_id: int, slug: string, external_id: string, billing_entity_code: string, address_line1: string, address_line2: string, applicable_timezone: string, city: string, country: string, currency: string, email: string, legal_name: string, legal_number: string, logo_url: string, name: string, firstname: string, lastname: string, account_type: string, customer_type: string, phone: string, state: string, tax_identification_number: string, timezone: string, url: string, zipcode: string, net_payment_term: int, created_at: string, updated_at: string, finalize_zero_amount_invoice: string, skip_invoice_custom_sections: bool, billing_configuration: record, shipping_address: record, metadata: list>, metadata: record, error_details: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/credit_notes/($lago_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download a credit note PDF
#
# POST /credit_notes/{lago_id}/download
# operationId: downloadCreditNote
export def "credit-notes-download downloadCreditNote" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<credit_note: record<lago_id: string, billing_entity_code: string, sequential_id: int, number: string, lago_invoice_id: string, invoice_number: string, issuing_date: string, credit_status: string, refund_status: string, reason: string, description: string, currency: string, total_amount_cents: int, taxes_amount_cents: int, taxes_rate: float, sub_total_excluding_taxes_amount_cents: int, balance_amount_cents: int, credit_amount_cents: int, refund_amount_cents: int, offset_amount_cents: int, coupons_adjustment_amount_cents: int, created_at: string, updated_at: string, file_url: string, items: list<record>, applied_taxes: list<record>, self_billed: bool, customer: record<lago_id: string, sequential_id: int, slug: string, external_id: string, billing_entity_code: string, address_line1: string, address_line2: string, applicable_timezone: string, city: string, country: string, currency: string, email: string, legal_name: string, legal_number: string, logo_url: string, name: string, firstname: string, lastname: string, account_type: string, customer_type: string, phone: string, state: string, tax_identification_number: string, timezone: string, url: string, zipcode: string, net_payment_term: int, created_at: string, updated_at: string, finalize_zero_amount_invoice: string, skip_invoice_custom_sections: bool, billing_configuration: record, shipping_address: record, metadata: list>, metadata: record, error_details: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/credit_notes/($lago_id)/download")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Estimate amounts for a new credit note
#
# POST /credit_notes/estimate
# operationId: estimateCreditNote
# --credit_note shape: {invoice_id: string, items: list}
export def "credit-notes-estimate estimateCreditNote" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  credit_note: record # shape: {invoice_id: string, items: list}
]: any -> record<estimated_credit_note: record<lago_invoice_id: string, invoice_number: string, currency: string, taxes_amount_cents: int, precise_taxes_amount_cents: float, taxes_rate: float, sub_total_excluding_taxes_amount_cents: int, max_creditable_amount_cents: int, max_refundable_amount_cents: int, max_offsettable_amount_cents: int, coupons_adjustment_amount_cents: int, precise_coupons_adjustment_amount_cents: float, items: list<record>, applied_taxes: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit_notes/estimate")
  let body = {credit_note: $credit_note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Void available credit
#
# PUT /credit_notes/{lago_id}/void
# operationId: voidCreditNote
export def "credit-notes-void voidCreditNote" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<credit_note: record<lago_id: string, billing_entity_code: string, sequential_id: int, number: string, lago_invoice_id: string, invoice_number: string, issuing_date: string, credit_status: string, refund_status: string, reason: string, description: string, currency: string, total_amount_cents: int, taxes_amount_cents: int, taxes_rate: float, sub_total_excluding_taxes_amount_cents: int, balance_amount_cents: int, credit_amount_cents: int, refund_amount_cents: int, offset_amount_cents: int, coupons_adjustment_amount_cents: int, created_at: string, updated_at: string, file_url: string, items: list<record>, applied_taxes: list<record>, self_billed: bool, customer: record<lago_id: string, sequential_id: int, slug: string, external_id: string, billing_entity_code: string, address_line1: string, address_line2: string, applicable_timezone: string, city: string, country: string, currency: string, email: string, legal_name: string, legal_number: string, logo_url: string, name: string, firstname: string, lastname: string, account_type: string, customer_type: string, phone: string, state: string, tax_identification_number: string, timezone: string, url: string, zipcode: string, net_payment_term: int, created_at: string, updated_at: string, finalize_zero_amount_invoice: string, skip_invoice_custom_sections: bool, billing_configuration: record, shipping_address: record, metadata: list>, metadata: record, error_details: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/credit_notes/($lago_id)/void")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace credit note metadata
#
# POST /credit_notes/{lago_id}/metadata
# operationId: replaceCreditNoteMetadata
export def "credit-notes-metadata replaceCreditNoteMetadata" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: record # Custom metadata stored as key-value pairs. Keys are strings (max 100 characters), values can be strings (max 255 characters) or null. (nullable, e.g. {external_id: ext-123, synced_at: 2024-01-15, source: })
]: any -> record<metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/credit_notes/($lago_id)/metadata")
  let body = {metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Merge credit note metadata
#
# PATCH /credit_notes/{lago_id}/metadata
# operationId: mergeCreditNoteMetadata
export def "credit-notes-metadata mergeCreditNoteMetadata" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: record # Custom metadata stored as key-value pairs. Keys are strings (max 100 characters), values can be strings (max 255 characters) or null. (nullable, e.g. {external_id: ext-123, synced_at: 2024-01-15, source: })
]: any -> record<metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/credit_notes/($lago_id)/metadata")
  let body = {metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete all credit note metadata
#
# DELETE /credit_notes/{lago_id}/metadata
# operationId: deleteAllCreditNoteMetadata
export def "credit-notes-metadata delete-by-lago_id" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/credit_notes/($lago_id)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a metadata key
#
# DELETE /credit_notes/{lago_id}/metadata/{key}
# operationId: deleteCreditNoteMetadataKey
export def "credit-notes-metadata delete-by-lago_id-key" [
  lago_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/credit_notes/($lago_id)/metadata/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a customer
#
# POST /customers
# operationId: createCustomer
# --customer shape: {external_id: string, billing_entity_code?: string, address_line1?: string, address_line2?: string, city?: string, country?: "AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", email?: string, legal_name?: string, legal_number?: string, logo_url?: string, name?: string, firstname?: string, lastname?: string, account_type?: "customer"|"partner", customer_type?: "company"|"individual", phone?: string, state?: string, tax_codes?: list, tax_identification_number?: string, timezone?: "UTC"|"Africa/Algiers"|"Africa/Cairo"|"Africa/Casablanca"|"Africa/Harare"|"Africa/Johannesburg"|"Africa/Monrovia"|"Africa/Nairobi"|"America/Argentina/Buenos_Aires"|"America/Bogota"|"America/Caracas"|"America/Chicago"|"America/Chihuahua"|"America/Denver"|"America/Godthab"|"America/Guatemala"|"America/Guyana"|"America/Halifax"|"America/Indiana/Indianapolis"|"America/Juneau"|"America/La_Paz"|"America/Lima"|"America/Los_Angeles"|"America/Mazatlan"|"America/Mexico_City"|"America/Monterrey"|"America/Montevideo"|"America/New_York"|"America/Phoenix"|"America/Puerto_Rico"|"America/Regina"|"America/Santiago"|"America/Sao_Paulo"|"America/St_Johns"|"America/Tijuana"|"Asia/Almaty"|"Asia/Baghdad"|"Asia/Baku"|"Asia/Bangkok"|"Asia/Chongqing"|"Asia/Colombo"|"Asia/Dhaka"|"Asia/Hong_Kong"|"Asia/Irkutsk"|"Asia/Jakarta"|"Asia/Jerusalem"|"Asia/Kabul"|"Asia/Kamchatka"|"Asia/Karachi"|"Asia/Kathmandu"|"Asia/Kolkata"|"Asia/Krasnoyarsk"|"Asia/Kuala_Lumpur"|"Asia/Kuwait"|"Asia/Magadan"|"Asia/Muscat"|"Asia/Novosibirsk"|"Asia/Rangoon"|"Asia/Riyadh"|"Asia/Seoul"|"Asia/Shanghai"|"Asia/Singapore"|"Asia/Srednekolymsk"|"Asia/Taipei"|"Asia/Tashkent"|"Asia/Tbilisi"|"Asia/Tehran"|"Asia/Tokyo"|"Asia/Ulaanbaatar"|"Asia/Urumqi"|"Asia/Vladivostok"|"Asia/Yakutsk"|"Asia/Yekaterinburg"|"Asia/Yerevan"|"Atlantic/Azores"|"Atlantic/Cape_Verde"|"Atlantic/South_Georgia"|"Australia/Adelaide"|"Australia/Brisbane"|"Australia/Darwin"|"Australia/Hobart"|"Australia/Melbourne"|"Australia/Perth"|"Australia/Sydney"|"Europe/Amsterdam"|"Europe/Athens"|"Europe/Belgrade"|"Europe/Berlin"|"Europe/Bratislava"|"Europe/Brussels"|"Europe/Bucharest"|"Europe/Budapest"|"Europe/Copenhagen"|"Europe/Dublin"|"Europe/Helsinki"|"Europe/Istanbul"|"Europe/Kaliningrad"|"Europe/Kiev"|"Europe/Lisbon"|"Europe/Ljubljana"|"Europe/London"|"Europe/Madrid"|"Europe/Minsk"|"Europe/Moscow"|"Europe/Paris"|"Europe/Prague"|"Europe/Riga"|"Europe/Rome"|"Europe/Samara"|"Europe/Sarajevo"|"Europe/Skopje"|"Europe/Sofia"|"Europe/Stockholm"|"Europe/Tallinn"|"Europe/Vienna"|"Europe/Vilnius"|"Europe/Volgograd"|"Europe/Warsaw"|"Europe/Zagreb"|"Europe/Zurich"|"GMT+12"|"Pacific/Apia"|"Pacific/Auckland"|"Pacific/Chatham"|"Pacific/Fakaofo"|"Pacific/Fiji"|"Pacific/Guadalcanal"|"Pacific/Guam"|"Pacific/Honolulu"|"Pacific/Majuro"|"Pacific/Midway"|"Pacific/Noumea"|"Pacific/Pago_Pago"|"Pacific/Port_Moresby"|"Pacific/Tongatapu", url?: string, zipcode?: string, net_payment_term?: int, finalize_zero_amount_invoice?: "inherit"|"skip"|"finalize", billing_configuration?: record, shipping_address?: record, integration_customers?: list, metadata?: list, skip_invoice_custom_sections?: bool, invoice_custom_section_codes?: list}
export def "customers createCustomer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  customer: record # shape: {external_id: string, billing_entity_code?: string, address_line1?: string, address_line2?: string, city?: string, country?: "AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", email?: string, legal_name?: string, legal_number?: string, logo_url?: string, name?: string, firstname?: string, lastname?: string, account_type?: "customer"|"partner", customer_type?: "company"|"individual", phone?: string, state?: string, tax_codes?: list, tax_identification_number?: string, timezone?: "UTC"|"Africa/Algiers"|"Africa/Cairo"|"Africa/Casablanca"|"Africa/Harare"|"Africa/Johannesburg"|"Africa/Monrovia"|"Africa/Nairobi"|"America/Argentina/Buenos_Aires"|"America/Bogota"|"America/Caracas"|"America/Chicago"|"America/Chihuahua"|"America/Denver"|"America/Godthab"|"America/Guatemala"|"America/Guyana"|"America/Halifax"|"America/Indiana/Indianapolis"|"America/Juneau"|"America/La_Paz"|"America/Lima"|"America/Los_Angeles"|"America/Mazatlan"|"America/Mexico_City"|"America/Monterrey"|"America/Montevideo"|"America/New_York"|"America/Phoenix"|"America/Puerto_Rico"|"America/Regina"|"America/Santiago"|"America/Sao_Paulo"|"America/St_Johns"|"America/Tijuana"|"Asia/Almaty"|"Asia/Baghdad"|"Asia/Baku"|"Asia/Bangkok"|"Asia/Chongqing"|"Asia/Colombo"|"Asia/Dhaka"|"Asia/Hong_Kong"|"Asia/Irkutsk"|"Asia/Jakarta"|"Asia/Jerusalem"|"Asia/Kabul"|"Asia/Kamchatka"|"Asia/Karachi"|"Asia/Kathmandu"|"Asia/Kolkata"|"Asia/Krasnoyarsk"|"Asia/Kuala_Lumpur"|"Asia/Kuwait"|"Asia/Magadan"|"Asia/Muscat"|"Asia/Novosibirsk"|"Asia/Rangoon"|"Asia/Riyadh"|"Asia/Seoul"|"Asia/Shanghai"|"Asia/Singapore"|"Asia/Srednekolymsk"|"Asia/Taipei"|"Asia/Tashkent"|"Asia/Tbilisi"|"Asia/Tehran"|"Asia/Tokyo"|"Asia/Ulaanbaatar"|"Asia/Urumqi"|"Asia/Vladivostok"|"Asia/Yakutsk"|"Asia/Yekaterinburg"|"Asia/Yerevan"|"Atlantic/Azores"|"Atlantic/Cape_Verde"|"Atlantic/South_Georgia"|"Australia/Adelaide"|"Australia/Brisbane"|"Australia/Darwin"|"Australia/Hobart"|"Australia/Melbourne"|"Australia/Perth"|"Australia/Sydney"|"Europe/Amsterdam"|"Europe/Athens"|"Europe/Belgrade"|"Europe/Berlin"|"Europe/Bratislava"|"Europe/Brussels"|"Europe/Bucharest"|"Europe/Budapest"|"Europe/Copenhagen"|"Europe/Dublin"|"Europe/Helsinki"|"Europe/Istanbul"|"Europe/Kaliningrad"|"Europe/Kiev"|"Europe/Lisbon"|"Europe/Ljubljana"|"Europe/London"|"Europe/Madrid"|"Europe/Minsk"|"Europe/Moscow"|"Europe/Paris"|"Europe/Prague"|"Europe/Riga"|"Europe/Rome"|"Europe/Samara"|"Europe/Sarajevo"|"Europe/Skopje"|"Europe/Sofia"|"Europe/Stockholm"|"Europe/Tallinn"|"Europe/Vienna"|"Europe/Vilnius"|"Europe/Volgograd"|"Europe/Warsaw"|"Europe/Zagreb"|"Europe/Zurich"|"GMT+12"|"Pacific/Apia"|"Pacific/Auckland"|"Pacific/Chatham"|"Pacific/Fakaofo"|"Pacific/Fiji"|"Pacific/Guadalcanal"|"Pacific/Guam"|"Pacific/Honolulu"|"Pacific/Majuro"|"Pacific/Midway"|"Pacific/Noumea"|"Pacific/Pago_Pago"|"Pacific/Port_Moresby"|"Pacific/Tongatapu", url?: string, zipcode?: string, net_payment_term?: int, finalize_zero_amount_invoice?: "inherit"|"skip"|"finalize", billing_configuration?: record, shipping_address?: record, integration_customers?: list, metadata?: list, skip_invoice_custom_sections?: bool, invoice_custom_section_codes?: list}
]: any -> record<customer: record<metadata: list<record>, taxes: list<record>, applicable_invoice_custom_sections: list<record>, error_details: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customers")
  let body = {customer: $customer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all customers
#
# GET /customers
# operationId: findAllCustomers
export def "customers findAllCustomers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --account-type: list # Filter customers by account type. (e.g. [customer, partner])
  --billing-entity-codes: list # Filter customers by billing entity codes. (e.g. [billing_entity_code_1, billing_entity_code_2])
  --search-term: string # Filter customers by search term. This will filter all customers whose name, firstname, lastname, legal name, external id or email contain the search term. (e.g. John Doe)
  --countries: list # Filter customers by countries. Possible values are the ISO 3166-1 alpha-2 codes. (e.g. [US, FR])
  --states: list # Filter customers by states. (e.g. [CA, Paris])
  --zipcodes: list # Filter customers by zipcodes. (e.g. [10115, 75001])
  --currencies: list # Filter customers by currencies. (e.g. [USD, EUR])
  --has-tax-identification-number: string@bool-completer # Filter customers by whether they have a tax identification number or not. (e.g. true)
  --metadatakey: string # Filter customers by metadata. Replace `key` with the actual metadata key you want to match, and provide the corresponding value. Providing empty value will search for customers without given metadata key. For example, `metadata[is_synced]=true&metadata[last_synced_at]=`. (e.g. value)
  --customer-type: string@customer-type-completer # Filter customers by customer type. (e.g. company)
  --has-customer-type: string@bool-completer # Filter customers by whether they have a customer type or not. (e.g. true)
]: nothing -> record<customers: table<metadata: list, taxes: list, applicable_invoice_custom_sections: list, error_details: list>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "account_type[]" $account_type "multi") (serialize-qp "billing_entity_codes[]" $billing_entity_codes "multi") (serialize-qp "search_term" $search_term "scalar") (serialize-qp "countries[]" $countries "multi") (serialize-qp "states[]" $states "multi") (serialize-qp "zipcodes[]" $zipcodes "multi") (serialize-qp "currencies[]" $currencies "multi") (serialize-qp "has_tax_identification_number" $has_tax_identification_number "scalar") (serialize-qp "metadata[key]" $metadatakey "scalar") (serialize-qp "customer_type" $customer_type "scalar") (serialize-qp "has_customer_type" $has_customer_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a customer
#
# GET /customers/{external_customer_id}
# operationId: findCustomer
export def "customers findCustomer" [
  external_customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<customer: record<metadata: list<record>, taxes: list<record>, applicable_invoice_custom_sections: list<record>, error_details: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($external_customer_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a customer
#
# DELETE /customers/{external_customer_id}
# operationId: destroyCustomer
export def "customers destroyCustomer" [
  external_customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<customer: record<metadata: list<record>, taxes: list<record>, applicable_invoice_custom_sections: list<record>, error_details: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($external_customer_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all customer's applied coupons
#
# GET /customers/{external_customer_id}/applied_coupons
# operationId: findAllCustomerAppliedCoupons
export def "customers-applied-coupons findAllCustomerAppliedCoupons" [
  external_customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --status: string@status-completer # The status of the coupon. Can be either `active` or `terminated`. (e.g. active)
  --coupon-code: list # The code of the coupon applied to the customer. Use it to filter applied coupons by their code. (e.g. [BLACK_FRIDAY_2024, CHRISTMAS_2024])
]: nothing -> record<applied_coupons: table<lago_id: string, lago_coupon_id: string, coupon_code: string, coupon_name: string, coupon_status: string, coupon_deleted_at: string, lago_customer_id: string, external_customer_id: string, status: string, amount_cents: int, amount_cents_remaining: int, amount_currency: string, percentage_rate: string, frequency: string, frequency_duration: int, frequency_duration_remaining: int, expiration_at: string, created_at: string, terminated_at: string, credits: list>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "coupon_code[]" $coupon_code "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/customers/($external_customer_id)/applied_coupons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an applied coupon
#
# DELETE /customers/{external_customer_id}/applied_coupons/{applied_coupon_id}
# operationId: deleteAppliedCoupon
export def "customers-applied-coupons delete" [
  external_customer_id: string
  applied_coupon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<applied_coupon: record<lago_id: string, lago_coupon_id: string, coupon_code: string, coupon_name: string, coupon_status: string, coupon_deleted_at: string, lago_customer_id: string, external_customer_id: string, status: string, amount_cents: int, amount_cents_remaining: int, amount_currency: string, percentage_rate: string, frequency: string, frequency_duration: int, frequency_duration_remaining: int, expiration_at: string, created_at: string, terminated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($external_customer_id)/applied_coupons/($applied_coupon_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all customer's credit notes
#
# GET /customers/{external_customer_id}/credit_notes
# operationId: findAllCustomerCreditNotes
export def "customers-credit-notes findAllCustomerCreditNotes" [
  external_customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --issuing-date-from: string # Filter credit notes starting from a specific date. (format: date, e.g. 2022-07-08)
  --issuing-date-to: string # Filter credit notes up to a specific date. (format: date, e.g. 2022-08-09)
  --search-term: string # Search credit notes by id, number, customer name, customer external_id or customer email. (e.g. Jane)
  --reason: string@reason-completer # Filter credit notes by reasons. Possible values are `product_unsatisfactory`, `order_change`, `order_cancellation`, `fraudulent_charge`, `duplicated_charge` or `other`.
  --credit-status: string@credit-status-completer # Filter credit notes by credit status. Possible values are `available`, `consumed`  or `voided`.
  --refund-status: string@refund-status-completer # Filter credit notes by refund status. Possible values are `pending`, `succeeded`  or `failed`.
  --invoice-number: string # Filter credit notes by their related invoice number. (e.g. INV-001-002)
  --amount-from: int # Filter credit notes of at least a specific amount. This parameter must be defined in cents to ensure consistent handling for all currency types. (e.g. 9000)
  --amount-to: int # Filter credit notes up to a specific amount. This parameter must be defined in cents to ensure consistent handling for all currency types. (e.g. 100000)
  --self-billed: string@bool-completer # Filter credit notes belonging to a self billed invoice. Possible values are `true` or `false`. (e.g. true)
]: nothing -> record<credit_notes: table<lago_id: string, billing_entity_code: string, sequential_id: int, number: string, lago_invoice_id: string, invoice_number: string, issuing_date: string, credit_status: string, refund_status: string, reason: string, description: string, currency: string, total_amount_cents: int, taxes_amount_cents: int, taxes_rate: float, sub_total_excluding_taxes_amount_cents: int, balance_amount_cents: int, credit_amount_cents: int, refund_amount_cents: int, offset_amount_cents: int, coupons_adjustment_amount_cents: int, created_at: string, updated_at: string, file_url: string, items: list, applied_taxes: list, self_billed: bool, customer: record, metadata: record, error_details: list>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "issuing_date_from" $issuing_date_from "scalar") (serialize-qp "issuing_date_to" $issuing_date_to "scalar") (serialize-qp "search_term" $search_term "scalar") (serialize-qp "reason" $reason "scalar") (serialize-qp "credit_status" $credit_status "scalar") (serialize-qp "refund_status" $refund_status "scalar") (serialize-qp "invoice_number" $invoice_number "scalar") (serialize-qp "amount_from" $amount_from "scalar") (serialize-qp "amount_to" $amount_to "scalar") (serialize-qp "self_billed" $self_billed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/customers/($external_customer_id)/credit_notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all customer's invoices
#
# GET /customers/{external_customer_id}/invoices
# operationId: findAllCustomerInvoices
export def "customers-invoices findAllCustomerInvoices" [
  external_customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --amount-from: int # Filter invoices of at least a specific amount. This parameter must be defined in cents to ensure consistent handling for all currency types. (e.g. 9000)
  --amount-to: int # Filter invoices up to a specific amount. This parameter must be defined in cents to ensure consistent handling for all currency types. (e.g. 100000)
  --issuing-date-from: string # Filter invoices starting from a specific date. (format: date, e.g. 2022-07-08)
  --issuing-date-to: string # Filter invoices up to a specific date. (format: date, e.g. 2022-08-09)
  --status: string@status-completer-1 # Filter invoices by status. Possible values are `draft` or `finalized`.
  --payment-status: string@payment-status-completer # Filter invoices by payment status. Possible values are `pending`, `failed` or `succeeded`.
  --payment-overdue: string@bool-completer # Filter invoices by payment_overdue. Possible values are `true` or `false`. (e.g. true)
  --search-term: string # Search invoices by id, number, customer name, customer external_id or customer email. (e.g. Jane)
  --payment-dispute-lost: string@bool-completer # Filter invoices with a payment dispute lost. Possible values are `true` or `false`. (e.g. true)
  --invoice-type: string@invoice-type-completer # Filter invoices by invoice type. Possible values are `subscription`, `add_on`, `credit`, `one_off`, `advance_charges` or `progressive_billing`.
  --self-billed: string@bool-completer # Filter invoices by self billed. Possible values are `true` or `false`. (e.g. true)
  --metadatakey: string # Filter invoices by metadata. Replace `key` with the actual metadata key you want to match, and provide the corresponding value. Providing empty value will search for invoice without given metadata key. For example, `metadata[color]=blue`. (e.g. someValue)
]: nothing -> record<invoices: table<lago_id: string, billing_entity_code: string, sequential_id: int, number: string, issuing_date: string, payment_dispute_lost_at: string, payment_due_date: string, payment_overdue: bool, net_payment_term: int, invoice_type: string, status: string, payment_status: string, currency: string, fees_amount_cents: int, coupons_amount_cents: int, credit_notes_amount_cents: int, sub_total_excluding_taxes_amount_cents: int, taxes_amount_cents: int, sub_total_including_taxes_amount_cents: int, prepaid_credit_amount_cents: int, prepaid_granted_credit_amount_cents: int, prepaid_purchased_credit_amount_cents: int, progressive_billing_credit_amount_cents: int, total_amount_cents: int, version_number: int, self_billed: bool, file_url: string, created_at: string, updated_at: string, customer: record, metadata: list, applied_taxes: list, applied_invoice_custom_sections: list, applied_usage_thresholds: list>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "amount_from" $amount_from "scalar") (serialize-qp "amount_to" $amount_to "scalar") (serialize-qp "issuing_date_from" $issuing_date_from "scalar") (serialize-qp "issuing_date_to" $issuing_date_to "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "payment_status" $payment_status "scalar") (serialize-qp "payment_overdue" $payment_overdue "scalar") (serialize-qp "search_term" $search_term "scalar") (serialize-qp "payment_dispute_lost" $payment_dispute_lost "scalar") (serialize-qp "invoice_type" $invoice_type "scalar") (serialize-qp "self_billed" $self_billed "scalar") (serialize-qp "metadata[key]" $metadatakey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/customers/($external_customer_id)/invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all customer's payments
#
# GET /customers/{external_customer_id}/payments
# operationId: findAllCustomerPayments
export def "customers-payments findAllCustomerPayments" [
  external_customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --invoice-id: string # Unique identifier assigned to the invoice within the Lago application. This ID is exclusively created by Lago and serves as a unique identifier for the invoice's record within the Lago system. (format: uuid, e.g. 1a901a90-1a90-1a90-1a90-1a901a901a90)
]: nothing -> record<payments: table<lago_id: string, lago_customer_id: string, external_customer_id: string, invoice_ids: list, invoice_numbers: list, lago_payable_id: string, payable_type: string, amount_cents: int, amount_currency: string, status: string, payment_status: string, type: string, reference: string, payment_provider_code: string, payment_provider_type: string, external_payment_id: string, provider_payment_id: string, provider_customer_id: string, payment_method_id: string, next_action: record, created_at: string>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "invoice_id" $invoice_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/customers/($external_customer_id)/payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all customer's payment requests
#
# GET /customers/{external_customer_id}/payment_requests
# operationId: findAllCustomerPaymentRequests
export def "customers-payment-requests findAllCustomerPaymentRequests" [
  external_customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --payment-status: string@payment-status-completer # Filter by payment status. Possible values are `pending`, `failed` or `succeeded`. (e.g. pending)
]: nothing -> record<payment_requests: table<lago_id: string, email: string, amount_cents: int, amount_currency: string, payment_status: string, created_at: string, customer: record, invoices: list>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "payment_status" $payment_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/customers/($external_customer_id)/payment_requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a customer portal URL
#
# GET /customers/{external_customer_id}/portal_url
# operationId: getCustomerPortalUrl
export def "customers-portal-url get" [
  external_customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<customer: record<portal_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($external_customer_id)/portal_url")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all customer's subscriptions
#
# GET /customers/{external_customer_id}/subscriptions
# operationId: findAllCustomerSubscriptions
export def "customers-subscriptions findAllCustomerSubscriptions" [
  external_customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --plan-code: string # The unique code representing the plan to be attached to the customer. This code must correspond to the code property of one of the active plans. (e.g. premium)
  --status: list # If the field is not defined, Lago will return only `active` subscriptions. However, if you wish to fetch subscriptions by different status you can define them in a status[] query param. Available filter values: `pending`, `canceled`, `terminated`, `active`. (e.g. [active, pending])
]: nothing -> record<subscriptions: table<lago_id: string, external_id: string, lago_customer_id: string, external_customer_id: string, billing_time: string, name: string, plan_code: string, plan_amount_cents: int, plan_amount_currency: string, status: string, created_at: string, canceled_at: string, started_at: string, ending_at: string, subscription_at: string, terminated_at: string, previous_plan_code: string, next_plan_code: string, downgrade_plan_date: string, trial_ended_at: string, current_billing_period_started_at: string, current_billing_period_ending_at: string, on_termination_credit_note: string, on_termination_invoice: string, applied_invoice_custom_sections: list, payment_method: record, consolidate_invoice: bool>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "plan_code" $plan_code "scalar") (serialize-qp "status[]" $status "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/customers/($external_customer_id)/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a wallet
#
# POST /customers/{external_customer_id}/wallets
# operationId: createCustomerWallet
# --wallet shape: {name?: string, code?: string, priority?: int, rate_amount: string, currency: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", paid_credits?: string, granted_credits?: string, external_customer_id: string, expiration_at?: string, invoice_requires_successful_payment?: bool, transaction_metadata?: list, transaction_name?: string, applies_to?: record, paid_top_up_min_amount_cents?: int, paid_top_up_max_amount_cents?: int, ignore_paid_top_up_limits_on_creation?: bool, invoice_custom_section?: record, recurring_transaction_rules?: list, payment_method?: record, metadata?: record}
export def "customers-wallets createCustomerWallet" [
  external_customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wallet: record # shape: {name?: string, code?: string, priority?: int, rate_amount: string, currency: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", paid_credits?: string, granted_credits?: string, external_customer_id: string, expiration_at?: string, invoice_requires_successful_payment?: bool, transaction_metadata?: list, transaction_name?: string, applies_to?: record, paid_top_up_min_amount_cents?: int, paid_top_up_max_amount_cents?: int, ignore_paid_top_up_limits_on_creation?: bool, invoice_custom_section?: record, recurring_transaction_rules?: list, payment_method?: record, metadata?: record}
]: any -> record<wallet: record<lago_id: string, lago_customer_id: string, external_customer_id: string, status: string, currency: string, name: string, code: string, priority: int, rate_amount: string, credits_balance: string, balance_cents: int, consumed_credits: string, created_at: string, expiration_at: string, last_balance_sync_at: string, last_consumed_credit_at: string, terminated_at: string, invoice_requires_successful_payment: bool, applies_to: record<fee_types: list, billable_metric_codes: list>, recurring_transaction_rules: list<record>, ongoing_balance_cents: int, ongoing_usage_balance_cents: int, credits_ongoing_balance: string, credits_ongoing_usage_balance: string, paid_top_up_min_amount_cents: int, paid_top_up_max_amount_cents: int, applied_invoice_custom_sections: list<record>, payment_method: record<payment_method_type: string, payment_method_id: string>, metadata: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($external_customer_id)/wallets")
  let body = {wallet: $wallet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all customer's wallets
#
# GET /customers/{external_customer_id}/wallets
# operationId: findAllCustomerWallets
export def "customers-wallets findAllCustomerWallets" [
  external_customer_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
]: nothing -> record<wallets: table<lago_id: string, lago_customer_id: string, external_customer_id: string, status: string, currency: string, name: string, code: string, priority: int, rate_amount: string, credits_balance: string, balance_cents: int, consumed_credits: string, created_at: string, expiration_at: string, last_balance_sync_at: string, last_consumed_credit_at: string, terminated_at: string, invoice_requires_successful_payment: bool, applies_to: record, recurring_transaction_rules: list, ongoing_balance_cents: int, ongoing_usage_balance_cents: int, credits_ongoing_balance: string, credits_ongoing_usage_balance: string, paid_top_up_min_amount_cents: int, paid_top_up_max_amount_cents: int, applied_invoice_custom_sections: list, payment_method: record, metadata: record>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/customers/($external_customer_id)/wallets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a wallet
#
# PUT /customers/{external_customer_id}/wallets/{code}
# operationId: updateCustomerWallet
# --wallet shape: {name?: string, code?: string, priority?: int, expiration_at?: string, invoice_requires_successful_payment?: bool, invoice_custom_section?: record, recurring_transaction_rules?: list, payment_method?: record, applies_to?: record, metadata?: record}
export def "customers-wallets updateCustomerWallet" [
  external_customer_id: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  wallet: record # shape: {name?: string, code?: string, priority?: int, expiration_at?: string, invoice_requires_successful_payment?: bool, invoice_custom_section?: record, recurring_transaction_rules?: list, payment_method?: record, applies_to?: record, metadata?: record}
]: any -> record<wallet: record<lago_id: string, lago_customer_id: string, external_customer_id: string, status: string, currency: string, name: string, code: string, priority: int, rate_amount: string, credits_balance: string, balance_cents: int, consumed_credits: string, created_at: string, expiration_at: string, last_balance_sync_at: string, last_consumed_credit_at: string, terminated_at: string, invoice_requires_successful_payment: bool, applies_to: record<fee_types: list, billable_metric_codes: list>, recurring_transaction_rules: list<record>, ongoing_balance_cents: int, ongoing_usage_balance_cents: int, credits_ongoing_balance: string, credits_ongoing_usage_balance: string, paid_top_up_min_amount_cents: int, paid_top_up_max_amount_cents: int, applied_invoice_custom_sections: list<record>, payment_method: record<payment_method_type: string, payment_method_id: string>, metadata: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($external_customer_id)/wallets/($code)")
  let body = {wallet: $wallet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a wallet
#
# GET /customers/{external_customer_id}/wallets/{code}
# operationId: findCustomerWallet
export def "customers-wallets findCustomerWallet" [
  external_customer_id: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<wallet: record<lago_id: string, lago_customer_id: string, external_customer_id: string, status: string, currency: string, name: string, code: string, priority: int, rate_amount: string, credits_balance: string, balance_cents: int, consumed_credits: string, created_at: string, expiration_at: string, last_balance_sync_at: string, last_consumed_credit_at: string, terminated_at: string, invoice_requires_successful_payment: bool, applies_to: record<fee_types: list, billable_metric_codes: list>, recurring_transaction_rules: list<record>, ongoing_balance_cents: int, ongoing_usage_balance_cents: int, credits_ongoing_balance: string, credits_ongoing_usage_balance: string, paid_top_up_min_amount_cents: int, paid_top_up_max_amount_cents: int, applied_invoice_custom_sections: list<record>, payment_method: record<payment_method_type: string, payment_method_id: string>, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($external_customer_id)/wallets/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Terminate a wallet
#
# DELETE /customers/{external_customer_id}/wallets/{code}
# operationId: destroyCustomerWallet
export def "customers-wallets destroyCustomerWallet" [
  external_customer_id: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<wallet: record<lago_id: string, lago_customer_id: string, external_customer_id: string, status: string, currency: string, name: string, code: string, priority: int, rate_amount: string, credits_balance: string, balance_cents: int, consumed_credits: string, created_at: string, expiration_at: string, last_balance_sync_at: string, last_consumed_credit_at: string, terminated_at: string, invoice_requires_successful_payment: bool, applies_to: record<fee_types: list, billable_metric_codes: list>, recurring_transaction_rules: list<record>, ongoing_balance_cents: int, ongoing_usage_balance_cents: int, credits_ongoing_balance: string, credits_ongoing_usage_balance: string, paid_top_up_min_amount_cents: int, paid_top_up_max_amount_cents: int, applied_invoice_custom_sections: list<record>, payment_method: record<payment_method_type: string, payment_method_id: string>, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($external_customer_id)/wallets/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace wallet metadata
#
# POST /customers/{external_customer_id}/wallets/{wallet_code}/metadata
# operationId: replaceCustomerWalletMetadata
export def "customers-wallets-metadata replaceCustomerWalletMetadata" [
  external_customer_id: string
  wallet_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: record # Custom metadata stored as key-value pairs. Keys are strings (max 100 characters), values can be strings (max 255 characters) or null. (nullable, e.g. {external_id: ext-123, synced_at: 2024-01-15, source: })
]: any -> record<metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($external_customer_id)/wallets/($wallet_code)/metadata")
  let body = {metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Merge wallet metadata
#
# PATCH /customers/{external_customer_id}/wallets/{wallet_code}/metadata
# operationId: mergeCustomerWalletMetadata
export def "customers-wallets-metadata mergeCustomerWalletMetadata" [
  external_customer_id: string
  wallet_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: record # Custom metadata stored as key-value pairs. Keys are strings (max 100 characters), values can be strings (max 255 characters) or null. (nullable, e.g. {external_id: ext-123, synced_at: 2024-01-15, source: })
]: any -> record<metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($external_customer_id)/wallets/($wallet_code)/metadata")
  let body = {metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete all wallet metadata
#
# DELETE /customers/{external_customer_id}/wallets/{wallet_code}/metadata
# operationId: deleteAllCustomerWalletMetadata
export def "customers-wallets-metadata delete-by-external_customer_id-wallet_code" [
  external_customer_id: string
  wallet_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($external_customer_id)/wallets/($wallet_code)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a metadata key
#
# DELETE /customers/{external_customer_id}/wallets/{wallet_code}/metadata/{key}
# operationId: deleteCustomerWalletMetadataKey
export def "customers-wallets-metadata delete-by-external_customer_id-wallet_code-key" [
  external_customer_id: string
  wallet_code: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($external_customer_id)/wallets/($wallet_code)/metadata/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List wallet alerts
#
# GET /customers/{external_customer_id}/wallets/{wallet_code}/alerts
# operationId: getCustomerWalletAlerts
export def "customers-wallets-alerts list" [
  external_customer_id: string
  wallet_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<alerts: table<lago_id: string, lago_organization_id: string, external_subscription_id: any, lago_wallet_id: string, wallet_code: string, billable_metric: any, alert_type: string, code: string, name: string, direction: string, previous_value: float, last_processed_at: string, thresholds: list, created_at: string>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($external_customer_id)/wallets/($wallet_code)/alerts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create wallet alert(s)
#
# POST /customers/{external_customer_id}/wallets/{wallet_code}/alerts
# operationId: createCustomerWalletAlert
# --alerts item shape: {code: string, name?: string, thresholds: list, alert_type: "wallet_balance_amount"|"wallet_credits_balance"|"wallet_ongoing_balance_amount"|"wallet_credits_ongoing_balance"}
export def "customers-wallets-alerts createCustomerWalletAlert" [
  external_customer_id: string
  wallet_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alert: any
  --alerts: list # Array of alerts to create. All alerts are created atomically - if any fail validation, none are created. — item shape: {code: string, name?: string, thresholds: list, alert_type: "wallet_balance_amount"|"wallet_credits_balance"|"wallet_ongoing_balance_amount"|"wallet_credits_ongoing_balance"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($external_customer_id)/wallets/($wallet_code)/alerts")
  let body = {alert: $alert, alerts: $alerts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete all wallet alerts
#
# DELETE /customers/{external_customer_id}/wallets/{wallet_code}/alerts
# operationId: deleteAllCustomerWalletAlerts
export def "customers-wallets-alerts delete-by-external_customer_id-wallet_code" [
  external_customer_id: string
  wallet_code: string
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
  let full_url = (build-url $base $"/customers/($external_customer_id)/wallets/($wallet_code)/alerts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a wallet alert
#
# GET /customers/{external_customer_id}/wallets/{wallet_code}/alerts/{code}
# operationId: getCustomerWalletAlert
export def "customers-wallets-alerts get" [
  external_customer_id: string
  wallet_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<alert: record<lago_id: string, lago_organization_id: string, external_subscription_id: any, lago_wallet_id: string, wallet_code: string, billable_metric: any, alert_type: string, code: string, name: string, direction: string, previous_value: float, last_processed_at: string, thresholds: list<record>, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($external_customer_id)/wallets/($wallet_code)/alerts/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a wallet alert
#
# PUT /customers/{external_customer_id}/wallets/{wallet_code}/alerts/{code}
# operationId: updateCustomerWalletAlert
export def "customers-wallets-alerts updateCustomerWalletAlert" [
  external_customer_id: string
  wallet_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  alert: any
]: any -> record<alert: record<lago_id: string, lago_organization_id: string, external_subscription_id: any, lago_wallet_id: string, wallet_code: string, billable_metric: any, alert_type: string, code: string, name: string, direction: string, previous_value: float, last_processed_at: string, thresholds: list<record>, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($external_customer_id)/wallets/($wallet_code)/alerts/($code)")
  let body = {alert: $alert} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a wallet alert
#
# DELETE /customers/{external_customer_id}/wallets/{wallet_code}/alerts/{code}
# operationId: deleteCustomerWalletAlert
export def "customers-wallets-alerts delete-by-external_customer_id-wallet_code-code" [
  external_customer_id: string
  wallet_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<alert: record<lago_id: string, lago_organization_id: string, external_subscription_id: any, lago_wallet_id: string, wallet_code: string, billable_metric: any, alert_type: string, code: string, name: string, direction: string, previous_value: float, last_processed_at: string, thresholds: list<record>, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($external_customer_id)/wallets/($wallet_code)/alerts/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve customer current usage
#
# GET /customers/{external_customer_id}/current_usage
# operationId: findCustomerCurrentUsage
@deprecated --flag filter-by-charge-id
@deprecated --flag filter-by-charge-code
@deprecated --flag filter-by-group
export def "customers-current-usage findCustomerCurrentUsage" [
  external_customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --external-subscription-id: string # The unique identifier of the subscription within your application. (e.g. sub_1234567890)
  --apply-taxes: string@bool-completer # Optional flag to determine if taxes should be applied. Defaults to `true` if not provided or if null.  (default: true, e.g. true)
  --charge-id: string # Filter usage to a specific charge by its Lago ID (UUID). Replaces deprecated `filter_by_charge_id`. (format: uuid, e.g. 1a901a90-1a90-1a90-1a90-1a901a901a90)
  --charge-code: string # Filter usage to a specific charge by its code. Replaces deprecated `filter_by_charge_code`. (e.g. storage)
  --billable-metric-code: string # Filter usage to a specific billable metric by its code. (e.g. storage)
  --group: record # Filter usage by pricing group. Pass key/value pairs as query parameters, e.g. `group[cloud]=aws`. Replaces deprecated `filter_by_group`.  (e.g. {cloud: aws})
  --filter-by-charge-id: string # Filter usage to a specific charge by its Lago ID (UUID). (DEPRECATED, format: uuid, e.g. 1a901a90-1a90-1a90-1a90-1a901a901a90)
  --filter-by-charge-code: string # Filter usage to a specific charge by its code. (DEPRECATED, e.g. storage)
  --filter-by-group: record # Filter usage by pricing group. Pass key/value pairs as query parameters, e.g. `filter_by_group[cloud]=aws`.  (DEPRECATED, e.g. {cloud: aws})
  --full-usage: string@bool-completer # When `true`, returns usage since subscription start instead of the current billing period. Requires one of `charge_id`, `charge_code`, `group` (or their deprecated `filter_by_*` equivalents) to be set.  (default: false, e.g. true)
  --filter-by-presentation: string # Filter `presentation_breakdowns` by a JSON-encoded array of presentation group key values. Only breakdowns matching the provided values will be returned. Pass an empty array to disable `presentation_breakdowns` entirely.  (e.g. ["engineering", "operations"])
]: nothing -> record<customer_usage: record<from_datetime: string, to_datetime: string, issuing_date: string, lago_invoice_id: string, currency: string, amount_cents: int, taxes_amount_cents: int, total_amount_cents: int, charges_usage: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "external_subscription_id" $external_subscription_id "scalar") (serialize-qp "apply_taxes" $apply_taxes "scalar") (serialize-qp "charge_id" $charge_id "scalar") (serialize-qp "charge_code" $charge_code "scalar") (serialize-qp "billable_metric_code" $billable_metric_code "scalar") (serialize-qp "group" $group "deepObject") (serialize-qp "filter_by_charge_id" $filter_by_charge_id "scalar") (serialize-qp "filter_by_charge_code" $filter_by_charge_code "scalar") (serialize-qp "filter_by_group" $filter_by_group "deepObject") (serialize-qp "full_usage" $full_usage "scalar") (serialize-qp "filter_by_presentation" $filter_by_presentation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/customers/($external_customer_id)/current_usage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve customer current and projected usage
#
# GET /customers/{external_customer_id}/projected_usage
# operationId: findCustomerProjectedUsage
export def "customers-projected-usage findCustomerProjectedUsage" [
  external_customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --external-subscription-id: string # The unique identifier of the subscription within your application. (e.g. sub_1234567890)
  --apply-taxes: string@bool-completer # Optional flag to determine if taxes should be applied. Defaults to `true` if not provided or if null.  (default: true, e.g. true)
]: nothing -> record<customer_projected_usage: record<from_datetime: string, to_datetime: string, issuing_date: string, lago_invoice_id: string, currency: string, amount_cents: int, projected_amount_cents: int, taxes_amount_cents: int, total_amount_cents: int, charges_usage: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "external_subscription_id" $external_subscription_id "scalar") (serialize-qp "apply_taxes" $apply_taxes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/customers/($external_customer_id)/projected_usage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve customer past usage
#
# GET /customers/{external_customer_id}/past_usage
# operationId: findAllCustomerPastUsage
export def "customers-past-usage findAllCustomerPastUsage" [
  external_customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --external-subscription-id: string # The unique identifier of the subscription within your application. (e.g. sub_1234567890)
  --billable-metric-code: string # Billable metric code filter to apply to the charge usage (e.g. cpu)
  --periods-count: int # Number of past billing period to returns in the result (e.g. 5)
]: nothing -> record<usage_periods: table<from_datetime: string, to_datetime: string, issuing_date: string, lago_invoice_id: string, currency: string, amount_cents: int, taxes_amount_cents: int, total_amount_cents: int, charges_usage: list>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "external_subscription_id" $external_subscription_id "scalar") (serialize-qp "billable_metric_code" $billable_metric_code "scalar") (serialize-qp "periods_count" $periods_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/customers/($external_customer_id)/past_usage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate a Customer Payment Provider Checkout URL
#
# POST /customers/{external_customer_id}/checkout_url
# operationId: generateCustomerCheckoutURL
export def "customers-checkout-url generateCustomerCheckoutURL" [
  external_customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<customer: record<lago_customer_id: string, external_customer_id: string, payment_provider: string, payment_provider_code: string, checkout_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($external_customer_id)/checkout_url")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all customer payment methods
#
# GET /customers/{external_customer_id}/payment_methods
# operationId: findAllCustomersPaymentMethods
export def "customers-payment-methods findAllCustomersPaymentMethods" [
  external_customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
]: nothing -> record<payment_methods: table<lago_id: string, is_default: bool, payment_provider_code: string, payment_provider_name: string, payment_provider_type: string, provider_method_id: string, created_at: string>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/customers/($external_customer_id)/payment_methods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the payment method as default
#
# PUT /customers/{external_customer_id}/payment_methods/{lago_id}/set_as_default
# operationId: paymentMethodSetAsDefault
export def "customers-payment-methods-set-as-default paymentMethodSetAsDefault" [
  lago_id: string
  external_customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<payment_method: record<lago_id: string, is_default: bool, payment_provider_code: string, payment_provider_name: string, payment_provider_type: string, provider_method_id: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($external_customer_id)/payment_methods/($lago_id)/set_as_default")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a payment method
#
# DELETE /customers/{external_customer_id}/payment_methods/{lago_id}
# operationId: destroyPaymentMethod
export def "customers-payment-methods destroyPaymentMethod" [
  lago_id: string
  external_customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<payment_method: record<lago_id: string, is_default: bool, payment_provider_code: string, payment_provider_name: string, payment_provider_type: string, provider_method_id: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($external_customer_id)/payment_methods/($lago_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send usage events
#
# POST /events
# operationId: createEvent
# --event shape: {transaction_id: string, external_subscription_id: string, code: string, timestamp?: any, precise_total_amount_cents?: string, properties?: record}
export def "events createEvent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  event: record # shape: {transaction_id: string, external_subscription_id: string, code: string, timestamp?: any, precise_total_amount_cents?: string, properties?: record}
]: any -> record<event: record<lago_id: string, transaction_id: string, lago_customer_id: any, code: string, timestamp: string, precise_total_amount_cents: string, properties: record<operation_type: string>, lago_subscription_id: string, external_subscription_id: string, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/events")
  let body = {event: $event} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all events
#
# GET /events
# operationId: findAllEvents
export def "events findAllEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --external-subscription-id: string # External subscription ID (e.g. 5eb02857-a71e-4ea2-bcf9-57d3a41bc6ba)
  --code: string # Filter events by its code. (e.g. event-123)
  --timestamp-from-started-at: string@bool-completer # Requires `external_subscription_id` to be set. Filter events by timestamp after the subscription started at datetime. (e.g. true)
  --timestamp-from: string # Filter events by timestamp starting from a specific date. (format: date-time, e.g. 2022-08-08T00:00:00Z)
  --timestamp-to: string # Filter events by timestamp up to a specific date. (format: date-time, e.g. 2022-08-08T00:00:00Z)
]: nothing -> record<events: table<lago_id: string, transaction_id: string, lago_customer_id: string, code: string, timestamp: string, precise_total_amount_cents: string, properties: record, lago_subscription_id: string, external_subscription_id: string, created_at: string>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "external_subscription_id" $external_subscription_id "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "timestamp_from_started_at" $timestamp_from_started_at "scalar") (serialize-qp "timestamp_from" $timestamp_from "scalar") (serialize-qp "timestamp_to" $timestamp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Batch multiple events
#
# POST /events/batch
# operationId: createBatchEvents
# --events item shape: {transaction_id: string, external_subscription_id: string, code: string, timestamp?: any, precise_total_amount_cents?: string, properties?: record}
export def "events-batch createBatchEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  events: list # item shape: {transaction_id: string, external_subscription_id: string, code: string, timestamp?: any, precise_total_amount_cents?: string, properties?: record}
]: any -> record<events: table<lago_id: string, transaction_id: string, lago_customer_id: any, code: string, timestamp: string, precise_total_amount_cents: string, properties: record, lago_subscription_id: string, external_subscription_id: string, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/events/batch")
  let body = {events: $events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Estimate fees for a pay in advance charge
#
# POST /events/estimate_fees
# operationId: eventEstimateFees
# --event shape: {code: string, external_subscription_id: string, properties?: record}
export def "events-estimate-fees eventEstimateFees" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  event: record # shape: {code: string, external_subscription_id: string, properties?: record}
]: any -> record<fees: table<lago_id: string, lago_charge_id: string, lago_charge_filter_id: string, lago_fixed_charge_id: string, lago_invoice_id: string, lago_true_up_fee_id: string, lago_true_up_parent_fee_id: string, lago_subscription_id: string, lago_customer_id: string, external_customer_id: string, external_subscription_id: string, amount_cents: int, precise_amount: string, precise_total_amount: string, amount_currency: string, taxes_amount_cents: int, taxes_precise_amount: string, taxes_rate: float, units: string, precise_unit_amount: string, total_aggregated_units: string, total_amount_cents: int, total_amount_currency: string, events_count: int, pay_in_advance: bool, invoiceable: bool, from_date: string, to_date: string, payment_status: string, created_at: string, succeeded_at: string, failed_at: string, refunded_at: string, event_transaction_id: string, description: string, precise_coupons_amount_cents: string, sub_total_excluding_taxes_amount_cents: int, sub_total_excluding_taxes_precise_amount_cents: string, amount_details: record, self_billed: bool, item: record, applied_taxes: list, pricing_unit_details: record, presentation_breakdowns: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/events/estimate_fees")
  let body = {event: $event} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Estimate instant fees for a pay in advance charge
#
# POST /events/estimate_instant_fees
# operationId: eventEstimateInstantFees
# --event shape: {code: string, external_subscription_id: string, properties?: record, transaction_id?: string}
export def "events-estimate-instant-fees eventEstimateInstantFees" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  event: record # shape: {code: string, external_subscription_id: string, properties?: record, transaction_id?: string}
]: any -> record<fees: table<lago_id: any, lago_charge_id: string, lago_charge_filter_id: string, lago_invoice_id: any, lago_true_up_fee_id: any, lago_true_up_parent_fee_id: any, lago_subscription_id: string, lago_customer_id: string, external_customer_id: string, external_subscription_id: string, amount_cents: int, precise_amount: float, precise_total_amount: float, amount_currency: string, taxes_amount_cents: int, taxes_precise_amount: float, taxes_rate: float, units: string, description: any, precise_unit_amount: float, precise_coupons_amount_cents: string, total_amount_cents: int, total_amount_currency: string, events_count: int, pay_in_advance: bool, invoiceable: bool, payment_status: string, created_at: any, succeeded_at: any, failed_at: any, refunded_at: any, event_transaction_id: string, amount_details: any, item: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/events/estimate_instant_fees")
  let body = {event: $event} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Batch estimate instant fees for a pay in advance charge
#
# POST /events/batch_estimate_instant_fees
# operationId: eventBatchEstimateInstantFees
# --events item shape: {event: record}
export def "events-batch-estimate-instant-fees eventBatchEstimateInstantFees" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  events: list # item shape: {event: record}
]: any -> record<fees: table<lago_id: any, lago_charge_id: string, lago_charge_filter_id: string, lago_invoice_id: any, lago_true_up_fee_id: any, lago_true_up_parent_fee_id: any, lago_subscription_id: string, lago_customer_id: string, external_customer_id: string, external_subscription_id: string, amount_cents: int, precise_amount: float, precise_total_amount: float, amount_currency: string, taxes_amount_cents: int, taxes_precise_amount: float, taxes_rate: float, units: string, description: any, precise_unit_amount: float, precise_coupons_amount_cents: string, total_amount_cents: int, total_amount_currency: string, events_count: int, pay_in_advance: bool, invoiceable: bool, payment_status: string, created_at: any, succeeded_at: any, failed_at: any, refunded_at: any, event_transaction_id: string, amount_details: any, item: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/events/batch_estimate_instant_fees")
  let body = {events: $events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a specific event
#
# GET /events/{transaction_id}
# operationId: findEvent
export def "events findEvent" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<event: record<lago_id: string, transaction_id: string, lago_customer_id: string, code: string, timestamp: string, precise_total_amount_cents: string, properties: record<operation_type: string>, lago_subscription_id: string, external_subscription_id: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/events/($transaction_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all fees
#
# GET /fees
# operationId: findAllFees
export def "fees findAllFees" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --external-customer-id: string # Unique identifier assigned to the customer in your application. (e.g. 5eb02857-a71e-4ea2-bcf9-57d3a41bc6ba)
  --external-subscription-id: string # External subscription ID (e.g. 5eb02857-a71e-4ea2-bcf9-57d3a41bc6ba)
  --event-transaction-id: string # Filter results by event transaction ID (e.g. et_12345678)
  --currency: string # Filter results by fee"s currency.
  --fee-type: string@fee-type-completer # The fee type. Possible values are `add-on`, `charge`, `credit`, `subscription` or "commitment". (e.g. charge)
  --billable-metric-code: string # Filter results by the `code` of the billable metric attached to the fee. Only applies to `charge` types. (e.g. bm_code)
  --payment-status: string@payment-status-completer-1 # Indicates the payment status of the fee. It represents the current status of the payment associated with the fee. The possible values for this field are `pending`, `succeeded`, `failed` and refunded`. (e.g. succeeded)
  --created-at-from: string # Filter results created after creation date and time in UTC. (format: date-time, e.g. 2023-03-28T12:21:51Z)
  --created-at-to: string # Filter results created before creation date and time in UTC. (format: date-time, e.g. 2023-03-28T12:21:51Z)
  --succeeded-at-from: string # Filter results with payment success after creation date and time in UTC. (format: date-time, e.g. 2023-03-28T12:21:51Z)
  --succeeded-at-to: string # Filter results with payment success after creation date and time in UTC. (format: date-time, e.g. 2023-03-28T12:21:51Z)
  --failed-at-from: string # Filter results with payment failure after creation date and time in UTC. (format: date-time, e.g. 2023-03-28T12:21:51Z)
  --failed-at-to: string # Filter results with payment failure after creation date and time in UTC. (format: date-time, e.g. 2023-03-28T12:21:51Z)
  --refunded-at-from: string # Filter results with payment refund after creation date and time in UTC. (format: date-time, e.g. 2023-03-28T12:21:51Z)
  --refunded-at-to: string # Filter results with payment refund after creation date and time in UTC. (format: date-time, e.g. 2023-03-28T12:21:51Z)
]: nothing -> record<fees: table<lago_id: string, lago_charge_id: string, lago_charge_filter_id: string, lago_fixed_charge_id: string, lago_invoice_id: string, lago_true_up_fee_id: string, lago_true_up_parent_fee_id: string, lago_subscription_id: string, lago_customer_id: string, external_customer_id: string, external_subscription_id: string, amount_cents: int, precise_amount: string, precise_total_amount: string, amount_currency: string, taxes_amount_cents: int, taxes_precise_amount: string, taxes_rate: float, units: string, precise_unit_amount: string, total_aggregated_units: string, total_amount_cents: int, total_amount_currency: string, events_count: int, pay_in_advance: bool, invoiceable: bool, from_date: string, to_date: string, payment_status: string, created_at: string, succeeded_at: string, failed_at: string, refunded_at: string, event_transaction_id: string, description: string, precise_coupons_amount_cents: string, sub_total_excluding_taxes_amount_cents: int, sub_total_excluding_taxes_precise_amount_cents: string, amount_details: record, self_billed: bool, item: record, applied_taxes: list, pricing_unit_details: record, presentation_breakdowns: list>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "external_customer_id" $external_customer_id "scalar") (serialize-qp "external_subscription_id" $external_subscription_id "scalar") (serialize-qp "event_transaction_id" $event_transaction_id "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "fee_type" $fee_type "scalar") (serialize-qp "billable_metric_code" $billable_metric_code "scalar") (serialize-qp "payment_status" $payment_status "scalar") (serialize-qp "created_at_from" $created_at_from "scalar") (serialize-qp "created_at_to" $created_at_to "scalar") (serialize-qp "succeeded_at_from" $succeeded_at_from "scalar") (serialize-qp "succeeded_at_to" $succeeded_at_to "scalar") (serialize-qp "failed_at_from" $failed_at_from "scalar") (serialize-qp "failed_at_to" $failed_at_to "scalar") (serialize-qp "refunded_at_from" $refunded_at_from "scalar") (serialize-qp "refunded_at_to" $refunded_at_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fees" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a specific fee
#
# GET /fees/{lago_id}
# operationId: findFee
export def "fees findFee" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fee: record<lago_id: string, lago_charge_id: string, lago_charge_filter_id: string, lago_fixed_charge_id: string, lago_invoice_id: string, lago_true_up_fee_id: string, lago_true_up_parent_fee_id: string, lago_subscription_id: string, lago_customer_id: string, external_customer_id: string, external_subscription_id: string, amount_cents: int, precise_amount: string, precise_total_amount: string, amount_currency: string, taxes_amount_cents: int, taxes_precise_amount: string, taxes_rate: float, units: string, precise_unit_amount: string, total_aggregated_units: string, total_amount_cents: int, total_amount_currency: string, events_count: int, pay_in_advance: bool, invoiceable: bool, from_date: string, to_date: string, payment_status: string, created_at: string, succeeded_at: string, failed_at: string, refunded_at: string, event_transaction_id: string, description: string, precise_coupons_amount_cents: string, sub_total_excluding_taxes_amount_cents: int, sub_total_excluding_taxes_precise_amount_cents: string, amount_details: record<plan_amount_cents: int, graduated_ranges: list, graduated_percentage_ranges: list, free_units: string, paid_units: string, per_package_size: int, per_package_unit_amount: string, per_unit_total_amount: string, units: string, free_events: int, rate: string, paid_events: int, fixed_fee_unit_amount: string, fixed_fee_total_amount: string, min_max_adjustment_total_amount: string, per_unit_amount: string, flat_unit_amount: string>, self_billed: bool, item: record<type: string, code: string, name: string, description: string, invoice_display_name: string, filter_invoice_display_name: string, filters: record, lago_item_id: string, item_type: string, grouped_by: record>, applied_taxes: list<record>, pricing_unit_details: record<lago_pricing_unit_id: string, pricing_unit_code: string, short_name: string, amount_cents: int, precise_amount_cents: string, unit_amount_cents: int, precise_unit_amount: string, conversion_rate: string>, presentation_breakdowns: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fees/($lago_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a fee
#
# PUT /fees/{lago_id}
# operationId: updateFee
# --fee shape: {payment_status: "pending"|"succeeded"|"failed"|"refunded"}
export def "fees updateFee" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  fee: record # shape: {payment_status: "pending"|"succeeded"|"failed"|"refunded"}
]: any -> record<fee: record<lago_id: string, lago_charge_id: string, lago_charge_filter_id: string, lago_fixed_charge_id: string, lago_invoice_id: string, lago_true_up_fee_id: string, lago_true_up_parent_fee_id: string, lago_subscription_id: string, lago_customer_id: string, external_customer_id: string, external_subscription_id: string, amount_cents: int, precise_amount: string, precise_total_amount: string, amount_currency: string, taxes_amount_cents: int, taxes_precise_amount: string, taxes_rate: float, units: string, precise_unit_amount: string, total_aggregated_units: string, total_amount_cents: int, total_amount_currency: string, events_count: int, pay_in_advance: bool, invoiceable: bool, from_date: string, to_date: string, payment_status: string, created_at: string, succeeded_at: string, failed_at: string, refunded_at: string, event_transaction_id: string, description: string, precise_coupons_amount_cents: string, sub_total_excluding_taxes_amount_cents: int, sub_total_excluding_taxes_precise_amount_cents: string, amount_details: record<plan_amount_cents: int, graduated_ranges: list, graduated_percentage_ranges: list, free_units: string, paid_units: string, per_package_size: int, per_package_unit_amount: string, per_unit_total_amount: string, units: string, free_events: int, rate: string, paid_events: int, fixed_fee_unit_amount: string, fixed_fee_total_amount: string, min_max_adjustment_total_amount: string, per_unit_amount: string, flat_unit_amount: string>, self_billed: bool, item: record<type: string, code: string, name: string, description: string, invoice_display_name: string, filter_invoice_display_name: string, filters: record, lago_item_id: string, item_type: string, grouped_by: record>, applied_taxes: list<record>, pricing_unit_details: record<lago_pricing_unit_id: string, pricing_unit_code: string, short_name: string, amount_cents: int, precise_amount_cents: string, unit_amount_cents: int, precise_unit_amount: string, conversion_rate: string>, presentation_breakdowns: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fees/($lago_id)")
  let body = {fee: $fee} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a fee
#
# DELETE /fees/{lago_id}
# operationId: deleteFee
export def "fees delete" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fee: record<lago_id: string, lago_charge_id: string, lago_charge_filter_id: string, lago_fixed_charge_id: string, lago_invoice_id: string, lago_true_up_fee_id: string, lago_true_up_parent_fee_id: string, lago_subscription_id: string, lago_customer_id: string, external_customer_id: string, external_subscription_id: string, amount_cents: int, precise_amount: string, precise_total_amount: string, amount_currency: string, taxes_amount_cents: int, taxes_precise_amount: string, taxes_rate: float, units: string, precise_unit_amount: string, total_aggregated_units: string, total_amount_cents: int, total_amount_currency: string, events_count: int, pay_in_advance: bool, invoiceable: bool, from_date: string, to_date: string, payment_status: string, created_at: string, succeeded_at: string, failed_at: string, refunded_at: string, event_transaction_id: string, description: string, precise_coupons_amount_cents: string, sub_total_excluding_taxes_amount_cents: int, sub_total_excluding_taxes_precise_amount_cents: string, amount_details: record<plan_amount_cents: int, graduated_ranges: list, graduated_percentage_ranges: list, free_units: string, paid_units: string, per_package_size: int, per_package_unit_amount: string, per_unit_total_amount: string, units: string, free_events: int, rate: string, paid_events: int, fixed_fee_unit_amount: string, fixed_fee_total_amount: string, min_max_adjustment_total_amount: string, per_unit_amount: string, flat_unit_amount: string>, self_billed: bool, item: record<type: string, code: string, name: string, description: string, invoice_display_name: string, filter_invoice_display_name: string, filters: record, lago_item_id: string, item_type: string, grouped_by: record>, applied_taxes: list<record>, pricing_unit_details: record<lago_pricing_unit_id: string, pricing_unit_code: string, short_name: string, amount_cents: int, precise_amount_cents: string, unit_amount_cents: int, precise_unit_amount: string, conversion_rate: string>, presentation_breakdowns: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fees/($lago_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a one-off invoice
#
# POST /invoices
# operationId: createInvoice
# --invoice shape: {external_customer_id: string, currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", fees: list, invoice_custom_section?: record, payment_method?: record}
export def "invoices createInvoice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  invoice: record # shape: {external_customer_id: string, currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", fees: list, invoice_custom_section?: record, payment_method?: record}
]: any -> record<invoice: record<billing_periods: list<record>, credits: list<record>, fees: list<record>, subscriptions: list<record>, error_details: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invoices")
  let body = {invoice: $invoice} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all invoices
#
# GET /invoices
# operationId: findAllInvoices
export def "invoices findAllInvoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --external-customer-id: string # Unique identifier assigned to the customer in your application. (e.g. 5eb02857-a71e-4ea2-bcf9-57d3a41bc6ba)
  --amount-from: int # Filter invoices of at least a specific amount. This parameter must be defined in cents to ensure consistent handling for all currency types. (e.g. 9000)
  --amount-to: int # Filter invoices up to a specific amount. This parameter must be defined in cents to ensure consistent handling for all currency types. (e.g. 100000)
  --issuing-date-from: string # Filter invoices starting from a specific date. (format: date, e.g. 2022-07-08)
  --issuing-date-to: string # Filter invoices up to a specific date. (format: date, e.g. 2022-08-09)
  --statuses: list # Filter invoices by statuses. Possible values are `draft`, `failed`, `finalized`, `pending` and `voided`.
  --payment-statuses: list # Filter invoices by payment statuses. Possible values are `pending`, `failed` or `succeeded`.
  --payment-overdue: string@bool-completer # Filter invoices by payment_overdue. Possible values are `true` or `false`. (e.g. true)
  --search-term: string # Search invoices by id, number, customer name, customer external_id or customer email. (e.g. Jane)
  --currency: string # Filter invoices by currency. Possible values ISO 4217 currency codes. (e.g. EUR)
  --payment-dispute-lost: string@bool-completer # Filter invoices with a payment dispute lost. Possible values are `true` or `false`. (e.g. true)
  --invoice-type: string@invoice-type-completer # Filter invoices by invoice type. Possible values are `subscription`, `add_on`, `credit`, `one_off`, `advance_charges` or `progressive_billing`.
  --self-billed: string@bool-completer # Filter invoices by self billed. Possible values are `true` or `false`. (e.g. true)
  --billing-entity-codes: list # Filter invoices by billing entity codes. Possible values are the billing entity codes you have created. (e.g. [acme_corp, foo_bar])
  --metadatakey: string # Filter invoices by metadata. Replace `key` with the actual metadata key you want to match, and provide the corresponding value. Providing empty value will search for invoice without given metadata key. For example, `metadata[color]=blue`. (e.g. someValue)
]: nothing -> record<invoices: table<lago_id: string, billing_entity_code: string, sequential_id: int, number: string, issuing_date: string, payment_dispute_lost_at: string, payment_due_date: string, payment_overdue: bool, net_payment_term: int, invoice_type: string, status: string, payment_status: string, currency: string, fees_amount_cents: int, coupons_amount_cents: int, credit_notes_amount_cents: int, sub_total_excluding_taxes_amount_cents: int, taxes_amount_cents: int, sub_total_including_taxes_amount_cents: int, prepaid_credit_amount_cents: int, prepaid_granted_credit_amount_cents: int, prepaid_purchased_credit_amount_cents: int, progressive_billing_credit_amount_cents: int, total_amount_cents: int, version_number: int, self_billed: bool, file_url: string, created_at: string, updated_at: string, customer: record, metadata: list, applied_taxes: list, applied_invoice_custom_sections: list, applied_usage_thresholds: list>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "external_customer_id" $external_customer_id "scalar") (serialize-qp "amount_from" $amount_from "scalar") (serialize-qp "amount_to" $amount_to "scalar") (serialize-qp "issuing_date_from" $issuing_date_from "scalar") (serialize-qp "issuing_date_to" $issuing_date_to "scalar") (serialize-qp "statuses[]" $statuses "multi") (serialize-qp "payment_statuses[]" $payment_statuses "multi") (serialize-qp "payment_overdue" $payment_overdue "scalar") (serialize-qp "search_term" $search_term "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "payment_dispute_lost" $payment_dispute_lost "scalar") (serialize-qp "invoice_type" $invoice_type "scalar") (serialize-qp "self_billed" $self_billed "scalar") (serialize-qp "billing_entity_codes[]" $billing_entity_codes "multi") (serialize-qp "metadata[key]" $metadatakey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an invoice
#
# PUT /invoices/{lago_id}
# operationId: updateInvoice
# --invoice shape: {payment_status?: "pending"|"succeeded"|"failed", metadata?: list}
export def "invoices updateInvoice" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  invoice: record # shape: {payment_status?: "pending"|"succeeded"|"failed", metadata?: list}
]: any -> record<invoice: record<billing_periods: list<record>, credits: list<record>, fees: list<record>, subscriptions: list<record>, error_details: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($lago_id)")
  let body = {invoice: $invoice} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an invoice
#
# GET /invoices/{lago_id}
# operationId: findInvoice
export def "invoices findInvoice" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<invoice: record<billing_periods: list<record>, credits: list<record>, fees: list<record>, subscriptions: list<record>, error_details: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($lago_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download an invoice PDF
#
# POST /invoices/{lago_id}/download
# operationId: downloadInvoice
export def "invoices-download downloadInvoice" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<invoice: record<billing_periods: list<record>, credits: list<record>, fees: list<record>, subscriptions: list<record>, error_details: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($lago_id)/download")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Finalize a draft invoice
#
# PUT /invoices/{lago_id}/finalize
# operationId: finalizeInvoice
export def "invoices-finalize finalizeInvoice" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<invoice: record<billing_periods: list<record>, credits: list<record>, fees: list<record>, subscriptions: list<record>, error_details: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($lago_id)/finalize")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark an invoice payment dispute as lost
#
# POST /invoices/{lago_id}/lose_dispute
# operationId: loseDisputeInvoice
export def "invoices-lose-dispute loseDisputeInvoice" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<invoice: record<billing_periods: list<record>, credits: list<record>, fees: list<record>, subscriptions: list<record>, error_details: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($lago_id)/lose_dispute")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refresh a draft invoice
#
# PUT /invoices/{lago_id}/refresh
# operationId: refreshInvoice
export def "invoices-refresh refreshInvoice" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<invoice: record<billing_periods: list<record>, credits: list<record>, fees: list<record>, subscriptions: list<record>, error_details: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($lago_id)/refresh")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retry generation of a failed invoice
#
# POST /invoices/{lago_id}/retry
# operationId: retryInvoice
export def "invoices-retry retryInvoice" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<invoice: record<billing_periods: list<record>, credits: list<record>, fees: list<record>, subscriptions: list<record>, error_details: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($lago_id)/retry")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate a payment URL
#
# POST /invoices/{lago_id}/payment_url
# operationId: invoicePaymentUrl
export def "invoices-payment-url invoicePaymentUrl" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<invoice_payment_details: record<lago_customer_id: string, lago_invoice_id: string, external_customer_id: string, payment_provider: string, payment_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($lago_id)/payment_url")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an invoice preview
#
# POST /invoices/preview
# operationId: invoicePreview
# --customer shape: {address_line1?: string, address_line2?: string, city?: string, country?: "AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", external_id?: string, integration_customers?: list, name?: string, currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", shipping_address?: record, state?: string, tax_identification_number?: string, timezone?: "UTC"|"Africa/Algiers"|"Africa/Cairo"|"Africa/Casablanca"|"Africa/Harare"|"Africa/Johannesburg"|"Africa/Monrovia"|"Africa/Nairobi"|"America/Argentina/Buenos_Aires"|"America/Bogota"|"America/Caracas"|"America/Chicago"|"America/Chihuahua"|"America/Denver"|"America/Guatemala"|"America/Guyana"|"America/Halifax"|"America/Indiana/Indianapolis"|"America/Juneau"|"America/La_Paz"|"America/Lima"|"America/Los_Angeles"|"America/Mazatlan"|"America/Mexico_City"|"America/Monterrey"|"America/Montevideo"|"America/New_York"|"America/Nuuk"|"America/Phoenix"|"America/Puerto_Rico"|"America/Regina"|"America/Santiago"|"America/Sao_Paulo"|"America/St_Johns"|"America/Tijuana"|"Asia/Almaty"|"Asia/Baghdad"|"Asia/Baku"|"Asia/Bangkok"|"Asia/Chongqing"|"Asia/Colombo"|"Asia/Dhaka"|"Asia/Hong_Kong"|"Asia/Irkutsk"|"Asia/Jakarta"|"Asia/Jerusalem"|"Asia/Kabul"|"Asia/Kamchatka"|"Asia/Karachi"|"Asia/Kathmandu"|"Asia/Kolkata"|"Asia/Krasnoyarsk"|"Asia/Kuala_Lumpur"|"Asia/Kuwait"|"Asia/Magadan"|"Asia/Muscat"|"Asia/Novosibirsk"|"Asia/Riyadh"|"Asia/Seoul"|"Asia/Shanghai"|"Asia/Singapore"|"Asia/Srednekolymsk"|"Asia/Taipei"|"Asia/Tashkent"|"Asia/Tbilisi"|"Asia/Tehran"|"Asia/Tokyo"|"Asia/Ulaanbaatar"|"Asia/Urumqi"|"Asia/Vladivostok"|"Asia/Yakutsk"|"Asia/Yangon"|"Asia/Yekaterinburg"|"Asia/Yerevan"|"Atlantic/Azores"|"Atlantic/Cape_Verde"|"Atlantic/South_Georgia"|"Australia/Adelaide"|"Australia/Brisbane"|"Australia/Darwin"|"Australia/Hobart"|"Australia/Melbourne"|"Australia/Perth"|"Australia/Sydney"|"Europe/Amsterdam"|"Europe/Athens"|"Europe/Belgrade"|"Europe/Berlin"|"Europe/Bratislava"|"Europe/Brussels"|"Europe/Bucharest"|"Europe/Budapest"|"Europe/Copenhagen"|"Europe/Dublin"|"Europe/Helsinki"|"Europe/Istanbul"|"Europe/Kaliningrad"|"Europe/Kyiv"|"Europe/Lisbon"|"Europe/Ljubljana"|"Europe/London"|"Europe/Madrid"|"Europe/Minsk"|"Europe/Moscow"|"Europe/Paris"|"Europe/Prague"|"Europe/Riga"|"Europe/Rome"|"Europe/Samara"|"Europe/Sarajevo"|"Europe/Skopje"|"Europe/Sofia"|"Europe/Stockholm"|"Europe/Tallinn"|"Europe/Vienna"|"Europe/Vilnius"|"Europe/Volgograd"|"Europe/Warsaw"|"Europe/Zagreb"|"Europe/Zurich"|"GMT+12"|"Pacific/Apia"|"Pacific/Auckland"|"Pacific/Chatham"|"Pacific/Fakaofo"|"Pacific/Fiji"|"Pacific/Guadalcanal"|"Pacific/Guam"|"Pacific/Honolulu"|"Pacific/Majuro"|"Pacific/Midway"|"Pacific/Noumea"|"Pacific/Pago_Pago"|"Pacific/Port_Moresby"|"Pacific/Tongatapu"}
# --coupons item shape: {name?: string, code: string, coupon_type?: "fixed_amount"|"percentage", amount_cents?: int, amount_currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", percentage_rate?: string, frequency_duration?: int}
# --subscriptions shape: {external_ids: list, plan_code?: string, terminated_at?: string}
export def "invoices-preview invoicePreview" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  customer: record # shape: {address_line1?: string, address_line2?: string, city?: string, country?: "AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", external_id?: string, integration_customers?: list, name?: string, currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", shipping_address?: record, state?: string, tax_identification_number?: string, timezone?: "UTC"|"Africa/Algiers"|"Africa/Cairo"|"Africa/Casablanca"|"Africa/Harare"|"Africa/Johannesburg"|"Africa/Monrovia"|"Africa/Nairobi"|"America/Argentina/Buenos_Aires"|"America/Bogota"|"America/Caracas"|"America/Chicago"|"America/Chihuahua"|"America/Denver"|"America/Guatemala"|"America/Guyana"|"America/Halifax"|"America/Indiana/Indianapolis"|"America/Juneau"|"America/La_Paz"|"America/Lima"|"America/Los_Angeles"|"America/Mazatlan"|"America/Mexico_City"|"America/Monterrey"|"America/Montevideo"|"America/New_York"|"America/Nuuk"|"America/Phoenix"|"America/Puerto_Rico"|"America/Regina"|"America/Santiago"|"America/Sao_Paulo"|"America/St_Johns"|"America/Tijuana"|"Asia/Almaty"|"Asia/Baghdad"|"Asia/Baku"|"Asia/Bangkok"|"Asia/Chongqing"|"Asia/Colombo"|"Asia/Dhaka"|"Asia/Hong_Kong"|"Asia/Irkutsk"|"Asia/Jakarta"|"Asia/Jerusalem"|"Asia/Kabul"|"Asia/Kamchatka"|"Asia/Karachi"|"Asia/Kathmandu"|"Asia/Kolkata"|"Asia/Krasnoyarsk"|"Asia/Kuala_Lumpur"|"Asia/Kuwait"|"Asia/Magadan"|"Asia/Muscat"|"Asia/Novosibirsk"|"Asia/Riyadh"|"Asia/Seoul"|"Asia/Shanghai"|"Asia/Singapore"|"Asia/Srednekolymsk"|"Asia/Taipei"|"Asia/Tashkent"|"Asia/Tbilisi"|"Asia/Tehran"|"Asia/Tokyo"|"Asia/Ulaanbaatar"|"Asia/Urumqi"|"Asia/Vladivostok"|"Asia/Yakutsk"|"Asia/Yangon"|"Asia/Yekaterinburg"|"Asia/Yerevan"|"Atlantic/Azores"|"Atlantic/Cape_Verde"|"Atlantic/South_Georgia"|"Australia/Adelaide"|"Australia/Brisbane"|"Australia/Darwin"|"Australia/Hobart"|"Australia/Melbourne"|"Australia/Perth"|"Australia/Sydney"|"Europe/Amsterdam"|"Europe/Athens"|"Europe/Belgrade"|"Europe/Berlin"|"Europe/Bratislava"|"Europe/Brussels"|"Europe/Bucharest"|"Europe/Budapest"|"Europe/Copenhagen"|"Europe/Dublin"|"Europe/Helsinki"|"Europe/Istanbul"|"Europe/Kaliningrad"|"Europe/Kyiv"|"Europe/Lisbon"|"Europe/Ljubljana"|"Europe/London"|"Europe/Madrid"|"Europe/Minsk"|"Europe/Moscow"|"Europe/Paris"|"Europe/Prague"|"Europe/Riga"|"Europe/Rome"|"Europe/Samara"|"Europe/Sarajevo"|"Europe/Skopje"|"Europe/Sofia"|"Europe/Stockholm"|"Europe/Tallinn"|"Europe/Vienna"|"Europe/Vilnius"|"Europe/Volgograd"|"Europe/Warsaw"|"Europe/Zagreb"|"Europe/Zurich"|"GMT+12"|"Pacific/Apia"|"Pacific/Auckland"|"Pacific/Chatham"|"Pacific/Fakaofo"|"Pacific/Fiji"|"Pacific/Guadalcanal"|"Pacific/Guam"|"Pacific/Honolulu"|"Pacific/Majuro"|"Pacific/Midway"|"Pacific/Noumea"|"Pacific/Pago_Pago"|"Pacific/Port_Moresby"|"Pacific/Tongatapu"}
  --plan-code: string # The code of the plan. It serves as a unique identifier associated with a particular plan. The code is typically used for internal or system-level identification purposes, like assigning a subscription, for instance. (e.g. startup)
  --subscription-at: string # The anniversary date and time of the initial subscription. This date serves as the basis for billing subscriptions with `anniversary` billing time. The `anniversary_date` should be provided in ISO 8601 datetime format and expressed in Coordinated Universal Time (UTC). (format: date-time, e.g. 2022-08-08T00:00:00Z)
  --billing-time: string@billing-time-completer # The billing time for the subscription, which can be set as either `anniversary` or `calendar`. If not explicitly provided, it will default to `calendar`. The billing time determines the timing of recurring billing cycles for the subscription. By specifying `anniversary`, the billing cycle will be based on the specific date the subscription started (billed fully), while `calendar` sets the billing cycle at the first day of the week/month/year (billed with proration). (e.g. anniversary)
  --coupons: list # item shape: {name?: string, code: string, coupon_type?: "fixed_amount"|"percentage", amount_cents?: int, amount_currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", percentage_rate?: string, frequency_duration?: int}
  --subscriptions: record # shape: {external_ids: list, plan_code?: string, terminated_at?: string}
  --billing-entity-code: string # The code of the billing entity to which will be associated a customer if the external_id is not provided. If billing_entity_code is not provided, default billing_entity of organization will be used. (e.g. acme_corp)
]: any -> record<invoice: record<billing_periods: list<record>, credits: list<record>, fees: list<record>, subscriptions: list<record>, error_details: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invoices/preview")
  let body = {customer: $customer, plan_code: $plan_code, subscription_at: $subscription_at, billing_time: $billing_time, coupons: $coupons, subscriptions: $subscriptions, billing_entity_code: $billing_entity_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retry an invoice payment
#
# POST /invoices/{lago_id}/retry_payment
# operationId: retryPayment
# --payment_method shape: {payment_method_type?: "provider"|"manual", payment_method_id?: string}
export def "invoices-retry-payment retryPayment" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --payment-method: record # Reference to a specific payment method for processing the payment. — shape: {payment_method_type?: "provider"|"manual", payment_method_id?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($lago_id)/retry_payment")
  let body = {payment_method: $payment_method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Void an invoice
#
# POST /invoices/{lago_id}/void
# operationId: voidInvoice
export def "invoices-void voidInvoice" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --generate-credit-note: string@bool-completer # Set to `true` to force voiding the invoice and generate a credit note. (e.g. true)
  --refund-amount: int # Portion of the invoice amount (in cents) to be refunded to the customer in the generated credit note. (e.g. 2000)
  --credit-amount: int # Portion of the invoice amount (in cents) to be credited to the customer's balance in the generated credit note. (e.g. 1150)
]: any -> record<invoice: record<billing_periods: list<record>, credits: list<record>, fees: list<record>, subscriptions: list<record>, error_details: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($lago_id)/void")
  let body = {generate_credit_note: $generate_credit_note, refund_amount: $refund_amount, credit_amount: $credit_amount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update your organization
#
# PUT /organizations
# operationId: updateOrganization
# --organization shape: {webhook_url?: string, country?: "AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", default_currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", address_line1?: string, address_line2?: string, state?: string, zipcode?: string, email?: string, city?: string, legal_name?: string, legal_number?: string, document_numbering?: "per_customer"|"per_organization", document_number_prefix?: string, net_payment_term?: int, tax_identification_number?: string, timezone?: "UTC"|"Africa/Algiers"|"Africa/Cairo"|"Africa/Casablanca"|"Africa/Harare"|"Africa/Johannesburg"|"Africa/Monrovia"|"Africa/Nairobi"|"America/Argentina/Buenos_Aires"|"America/Bogota"|"America/Caracas"|"America/Chicago"|"America/Chihuahua"|"America/Denver"|"America/Guatemala"|"America/Guyana"|"America/Halifax"|"America/Indiana/Indianapolis"|"America/Juneau"|"America/La_Paz"|"America/Lima"|"America/Los_Angeles"|"America/Mazatlan"|"America/Mexico_City"|"America/Monterrey"|"America/Montevideo"|"America/New_York"|"America/Nuuk"|"America/Phoenix"|"America/Puerto_Rico"|"America/Regina"|"America/Santiago"|"America/Sao_Paulo"|"America/St_Johns"|"America/Tijuana"|"Asia/Almaty"|"Asia/Baghdad"|"Asia/Baku"|"Asia/Bangkok"|"Asia/Chongqing"|"Asia/Colombo"|"Asia/Dhaka"|"Asia/Hong_Kong"|"Asia/Irkutsk"|"Asia/Jakarta"|"Asia/Jerusalem"|"Asia/Kabul"|"Asia/Kamchatka"|"Asia/Karachi"|"Asia/Kathmandu"|"Asia/Kolkata"|"Asia/Krasnoyarsk"|"Asia/Kuala_Lumpur"|"Asia/Kuwait"|"Asia/Magadan"|"Asia/Muscat"|"Asia/Novosibirsk"|"Asia/Riyadh"|"Asia/Seoul"|"Asia/Shanghai"|"Asia/Singapore"|"Asia/Srednekolymsk"|"Asia/Taipei"|"Asia/Tashkent"|"Asia/Tbilisi"|"Asia/Tehran"|"Asia/Tokyo"|"Asia/Ulaanbaatar"|"Asia/Urumqi"|"Asia/Vladivostok"|"Asia/Yakutsk"|"Asia/Yangon"|"Asia/Yekaterinburg"|"Asia/Yerevan"|"Atlantic/Azores"|"Atlantic/Cape_Verde"|"Atlantic/South_Georgia"|"Australia/Adelaide"|"Australia/Brisbane"|"Australia/Darwin"|"Australia/Hobart"|"Australia/Melbourne"|"Australia/Perth"|"Australia/Sydney"|"Europe/Amsterdam"|"Europe/Athens"|"Europe/Belgrade"|"Europe/Berlin"|"Europe/Bratislava"|"Europe/Brussels"|"Europe/Bucharest"|"Europe/Budapest"|"Europe/Copenhagen"|"Europe/Dublin"|"Europe/Helsinki"|"Europe/Istanbul"|"Europe/Kaliningrad"|"Europe/Kyiv"|"Europe/Lisbon"|"Europe/Ljubljana"|"Europe/London"|"Europe/Madrid"|"Europe/Minsk"|"Europe/Moscow"|"Europe/Paris"|"Europe/Prague"|"Europe/Riga"|"Europe/Rome"|"Europe/Samara"|"Europe/Sarajevo"|"Europe/Skopje"|"Europe/Sofia"|"Europe/Stockholm"|"Europe/Tallinn"|"Europe/Vienna"|"Europe/Vilnius"|"Europe/Volgograd"|"Europe/Warsaw"|"Europe/Zagreb"|"Europe/Zurich"|"GMT+12"|"Pacific/Apia"|"Pacific/Auckland"|"Pacific/Chatham"|"Pacific/Fakaofo"|"Pacific/Fiji"|"Pacific/Guadalcanal"|"Pacific/Guam"|"Pacific/Honolulu"|"Pacific/Majuro"|"Pacific/Midway"|"Pacific/Noumea"|"Pacific/Pago_Pago"|"Pacific/Port_Moresby"|"Pacific/Tongatapu", email_settings?: list, billing_configuration?: record, finalize_zero_amount_invoice?: bool}
export def "organizations updateOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization: record # shape: {webhook_url?: string, country?: "AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", default_currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", address_line1?: string, address_line2?: string, state?: string, zipcode?: string, email?: string, city?: string, legal_name?: string, legal_number?: string, document_numbering?: "per_customer"|"per_organization", document_number_prefix?: string, net_payment_term?: int, tax_identification_number?: string, timezone?: "UTC"|"Africa/Algiers"|"Africa/Cairo"|"Africa/Casablanca"|"Africa/Harare"|"Africa/Johannesburg"|"Africa/Monrovia"|"Africa/Nairobi"|"America/Argentina/Buenos_Aires"|"America/Bogota"|"America/Caracas"|"America/Chicago"|"America/Chihuahua"|"America/Denver"|"America/Guatemala"|"America/Guyana"|"America/Halifax"|"America/Indiana/Indianapolis"|"America/Juneau"|"America/La_Paz"|"America/Lima"|"America/Los_Angeles"|"America/Mazatlan"|"America/Mexico_City"|"America/Monterrey"|"America/Montevideo"|"America/New_York"|"America/Nuuk"|"America/Phoenix"|"America/Puerto_Rico"|"America/Regina"|"America/Santiago"|"America/Sao_Paulo"|"America/St_Johns"|"America/Tijuana"|"Asia/Almaty"|"Asia/Baghdad"|"Asia/Baku"|"Asia/Bangkok"|"Asia/Chongqing"|"Asia/Colombo"|"Asia/Dhaka"|"Asia/Hong_Kong"|"Asia/Irkutsk"|"Asia/Jakarta"|"Asia/Jerusalem"|"Asia/Kabul"|"Asia/Kamchatka"|"Asia/Karachi"|"Asia/Kathmandu"|"Asia/Kolkata"|"Asia/Krasnoyarsk"|"Asia/Kuala_Lumpur"|"Asia/Kuwait"|"Asia/Magadan"|"Asia/Muscat"|"Asia/Novosibirsk"|"Asia/Riyadh"|"Asia/Seoul"|"Asia/Shanghai"|"Asia/Singapore"|"Asia/Srednekolymsk"|"Asia/Taipei"|"Asia/Tashkent"|"Asia/Tbilisi"|"Asia/Tehran"|"Asia/Tokyo"|"Asia/Ulaanbaatar"|"Asia/Urumqi"|"Asia/Vladivostok"|"Asia/Yakutsk"|"Asia/Yangon"|"Asia/Yekaterinburg"|"Asia/Yerevan"|"Atlantic/Azores"|"Atlantic/Cape_Verde"|"Atlantic/South_Georgia"|"Australia/Adelaide"|"Australia/Brisbane"|"Australia/Darwin"|"Australia/Hobart"|"Australia/Melbourne"|"Australia/Perth"|"Australia/Sydney"|"Europe/Amsterdam"|"Europe/Athens"|"Europe/Belgrade"|"Europe/Berlin"|"Europe/Bratislava"|"Europe/Brussels"|"Europe/Bucharest"|"Europe/Budapest"|"Europe/Copenhagen"|"Europe/Dublin"|"Europe/Helsinki"|"Europe/Istanbul"|"Europe/Kaliningrad"|"Europe/Kyiv"|"Europe/Lisbon"|"Europe/Ljubljana"|"Europe/London"|"Europe/Madrid"|"Europe/Minsk"|"Europe/Moscow"|"Europe/Paris"|"Europe/Prague"|"Europe/Riga"|"Europe/Rome"|"Europe/Samara"|"Europe/Sarajevo"|"Europe/Skopje"|"Europe/Sofia"|"Europe/Stockholm"|"Europe/Tallinn"|"Europe/Vienna"|"Europe/Vilnius"|"Europe/Volgograd"|"Europe/Warsaw"|"Europe/Zagreb"|"Europe/Zurich"|"GMT+12"|"Pacific/Apia"|"Pacific/Auckland"|"Pacific/Chatham"|"Pacific/Fakaofo"|"Pacific/Fiji"|"Pacific/Guadalcanal"|"Pacific/Guam"|"Pacific/Honolulu"|"Pacific/Majuro"|"Pacific/Midway"|"Pacific/Noumea"|"Pacific/Pago_Pago"|"Pacific/Port_Moresby"|"Pacific/Tongatapu", email_settings?: list, billing_configuration?: record, finalize_zero_amount_invoice?: bool}
]: any -> record<organization: record<lago_id: string, name: string, created_at: string, webhook_url: string, webhook_urls: list<string>, country: string, default_currency: string, address_line1: string, address_line2: string, state: string, zipcode: string, email: string, city: string, legal_name: string, legal_number: string, document_numbering: string, document_number_prefix: string, net_payment_term: int, tax_identification_number: string, timezone: string, billing_configuration: record<invoice_footer: string, invoice_grace_period: int, document_locale: string>, taxes: list<record>, finalize_zero_amount_invoice: bool, events_store: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organizations")
  let body = {organization: $organization} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all payment receipts
#
# GET /payment_receipts
# operationId: findAllPaymentReceipts
export def "payment-receipts findAllPaymentReceipts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --invoice-id: string # Filter payment receipts by invoice id. (e.g. 1a901a90-1a90-1a90-1a90-1a901a901a90)
]: nothing -> record<payment_receipts: table<lago_id: string, created_at: string, number: string, payment: record>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "invoice_id" $invoice_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payment_receipts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a payment receipt
#
# GET /payment_receipts/{lago_id}
# operationId: findPaymentReceipt
export def "payment-receipts findPaymentReceipt" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<payment_receipt: record<lago_id: string, created_at: string, number: string, payment: record<lago_id: string, lago_customer_id: string, external_customer_id: string, invoice_ids: list, invoice_numbers: list, lago_payable_id: string, payable_type: string, amount_cents: int, amount_currency: string, status: string, payment_status: string, type: string, reference: string, payment_provider_code: string, payment_provider_type: string, external_payment_id: string, provider_payment_id: string, provider_customer_id: string, payment_method_id: string, next_action: record, created_at: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payment_receipts/($lago_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a payment request
#
# POST /payment_requests
# operationId: createPaymentRequest
# --payment_request shape: {external_customer_id: string, email: string, lago_invoice_ids: list, payment_method?: record}
export def "payment-requests createPaymentRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  payment_request: record # shape: {external_customer_id: string, email: string, lago_invoice_ids: list, payment_method?: record}
]: any -> record<payment_request: record<lago_id: string, email: string, amount_cents: int, amount_currency: string, payment_status: string, created_at: string, customer: record<lago_id: string, sequential_id: int, slug: string, external_id: string, billing_entity_code: string, address_line1: string, address_line2: string, applicable_timezone: string, city: string, country: string, currency: string, email: string, legal_name: string, legal_number: string, logo_url: string, name: string, firstname: string, lastname: string, account_type: string, customer_type: string, phone: string, state: string, tax_identification_number: string, timezone: string, url: string, zipcode: string, net_payment_term: int, created_at: string, updated_at: string, finalize_zero_amount_invoice: string, skip_invoice_custom_sections: bool, billing_configuration: record, shipping_address: record, metadata: list>, invoices: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_requests")
  let body = {payment_request: $payment_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all payment requests
#
# GET /payment_requests
# operationId: findAllPaymentRequests
export def "payment-requests findAllPaymentRequests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --external-customer-id: string # Unique identifier assigned to the customer in your application. (e.g. 5eb02857-a71e-4ea2-bcf9-57d3a41bc6ba)
  --payment-status: string@payment-status-completer # Filter by payment status. Possible values are `pending`, `failed` or `succeeded`. (e.g. pending)
]: nothing -> record<payment_requests: table<lago_id: string, email: string, amount_cents: int, amount_currency: string, payment_status: string, created_at: string, customer: record, invoices: list>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "external_customer_id" $external_customer_id "scalar") (serialize-qp "payment_status" $payment_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payment_requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a payment request
#
# GET /payment_requests/{lago_id}
# operationId: findPaymentRequest
export def "payment-requests findPaymentRequest" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<lago_id: string, email: string, amount_cents: int, amount_currency: string, payment_status: string, created_at: string, customer: record<lago_id: string, sequential_id: int, slug: string, external_id: string, billing_entity_code: string, address_line1: string, address_line2: string, applicable_timezone: string, city: string, country: string, currency: string, email: string, legal_name: string, legal_number: string, logo_url: string, name: string, firstname: string, lastname: string, account_type: string, customer_type: string, phone: string, state: string, tax_identification_number: string, timezone: string, url: string, zipcode: string, net_payment_term: int, created_at: string, updated_at: string, finalize_zero_amount_invoice: string, skip_invoice_custom_sections: bool, billing_configuration: record<invoice_grace_period: int, subscription_invoice_issuing_date_anchor: string, subscription_invoice_issuing_date_adjustment: string, payment_provider: string, payment_provider_code: string, provider_customer_id: string, sync: bool, sync_with_provider: bool, document_locale: string, provider_payment_methods: list>, shipping_address: record<address_line1: string, address_line2: string, city: string, country: string, state: string, zipcode: string>, metadata: list<record>>, invoices: table<lago_id: string, billing_entity_code: string, sequential_id: int, number: string, issuing_date: string, payment_dispute_lost_at: string, payment_due_date: string, payment_overdue: bool, net_payment_term: int, invoice_type: string, status: string, payment_status: string, currency: string, fees_amount_cents: int, coupons_amount_cents: int, credit_notes_amount_cents: int, sub_total_excluding_taxes_amount_cents: int, taxes_amount_cents: int, sub_total_including_taxes_amount_cents: int, prepaid_credit_amount_cents: int, prepaid_granted_credit_amount_cents: int, prepaid_purchased_credit_amount_cents: int, progressive_billing_credit_amount_cents: int, total_amount_cents: int, version_number: int, self_billed: bool, file_url: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payment_requests/($lago_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a payment
#
# POST /payments
# operationId: createPayment
# --payment shape: {invoice_id: string, amount_cents: int, reference: string, paid_at?: string}
export def "payments createPayment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  payment: record # shape: {invoice_id: string, amount_cents: int, reference: string, paid_at?: string}
]: any -> record<payment: record<lago_id: string, lago_customer_id: string, external_customer_id: string, invoice_ids: list<string>, invoice_numbers: list<string>, lago_payable_id: string, payable_type: string, amount_cents: int, amount_currency: string, status: string, payment_status: string, type: string, reference: string, payment_provider_code: string, payment_provider_type: string, external_payment_id: string, provider_payment_id: string, provider_customer_id: string, payment_method_id: string, next_action: record, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payments")
  let body = {payment: $payment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all payments
#
# GET /payments
# operationId: findAllPayments
export def "payments findAllPayments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --external-customer-id: string # Unique identifier assigned to the customer in your application. (e.g. 5eb02857-a71e-4ea2-bcf9-57d3a41bc6ba)
  --invoice-id: string # Unique identifier assigned to the invoice within the Lago application. This ID is exclusively created by Lago and serves as a unique identifier for the invoice's record within the Lago system. (format: uuid, e.g. 1a901a90-1a90-1a90-1a90-1a901a901a90)
]: nothing -> record<payments: table<lago_id: string, lago_customer_id: string, external_customer_id: string, invoice_ids: list, invoice_numbers: list, lago_payable_id: string, payable_type: string, amount_cents: int, amount_currency: string, status: string, payment_status: string, type: string, reference: string, payment_provider_code: string, payment_provider_type: string, external_payment_id: string, provider_payment_id: string, provider_customer_id: string, payment_method_id: string, next_action: record, created_at: string>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "external_customer_id" $external_customer_id "scalar") (serialize-qp "invoice_id" $invoice_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a payment
#
# GET /payments/{lago_id}
# operationId: findPayment
export def "payments findPayment" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<lago_id: string, lago_customer_id: string, external_customer_id: string, invoice_ids: list<string>, invoice_numbers: list<string>, lago_payable_id: string, payable_type: string, amount_cents: int, amount_currency: string, status: string, payment_status: string, type: string, reference: string, payment_provider_code: string, payment_provider_type: string, external_payment_id: string, provider_payment_id: string, provider_customer_id: string, payment_method_id: string, next_action: record, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/($lago_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a plan
#
# POST /plans
# operationId: createPlan
# --plan shape: {name: string, invoice_display_name?: string, code: string, interval: "weekly"|"monthly"|"quarterly"|"semiannual"|"yearly", description?: string, amount_cents: int, amount_currency: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", trial_period?: float, pay_in_advance: bool, bill_charges_monthly?: bool, bill_fixed_charges_monthly?: bool, tax_codes?: list, minimum_commitment?: record, charges?: list, fixed_charges?: list, usage_thresholds?: list, metadata?: record}
export def "plans createPlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  plan: record # shape: {name: string, invoice_display_name?: string, code: string, interval: "weekly"|"monthly"|"quarterly"|"semiannual"|"yearly", description?: string, amount_cents: int, amount_currency: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", trial_period?: float, pay_in_advance: bool, bill_charges_monthly?: bool, bill_fixed_charges_monthly?: bool, tax_codes?: list, minimum_commitment?: record, charges?: list, fixed_charges?: list, usage_thresholds?: list, metadata?: record}
]: any -> record<plan: record<lago_id: string, name: string, invoice_display_name: string, created_at: string, code: string, interval: string, description: string, amount_cents: int, amount_currency: string, trial_period: float, pay_in_advance: bool, bill_charges_monthly: bool, bill_fixed_charges_monthly: bool, minimum_commitment: record<lago_id: string, plan_code: string, amount_cents: int, invoice_display_name: string, interval: string, created_at: string, updated_at: string, taxes: list>, charges: list<record>, fixed_charges: list<record>, taxes: list<record>, usage_thresholds: list<record>, entitlements: list<record>, metadata: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/plans")
  let body = {plan: $plan} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all plans
#
# GET /plans
# operationId: findAllPlans
export def "plans findAllPlans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
]: nothing -> record<plans: table<lago_id: string, name: string, invoice_display_name: string, created_at: string, code: string, interval: string, description: string, amount_cents: int, amount_currency: string, trial_period: float, pay_in_advance: bool, bill_charges_monthly: bool, bill_fixed_charges_monthly: bool, minimum_commitment: record, charges: list, fixed_charges: list, taxes: list, usage_thresholds: list, entitlements: list, metadata: record>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/plans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a plan
#
# PUT /plans/{code}
# operationId: updatePlan
# --plan shape: {name?: string, invoice_display_name?: string, code?: string, interval?: "weekly"|"monthly"|"quarterly"|"semiannual"|"yearly", description?: string, amount_cents?: int, amount_currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", trial_period?: float, pay_in_advance?: bool, bill_charges_monthly?: bool, bill_fixed_charges_monthly?: bool, tax_codes?: list, minimum_commitment?: record, charges?: list, fixed_charges?: list, usage_thresholds?: list, cascade_updates?: bool, metadata?: record}
export def "plans updatePlan" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  plan: record # shape: {name?: string, invoice_display_name?: string, code?: string, interval?: "weekly"|"monthly"|"quarterly"|"semiannual"|"yearly", description?: string, amount_cents?: int, amount_currency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", trial_period?: float, pay_in_advance?: bool, bill_charges_monthly?: bool, bill_fixed_charges_monthly?: bool, tax_codes?: list, minimum_commitment?: record, charges?: list, fixed_charges?: list, usage_thresholds?: list, cascade_updates?: bool, metadata?: record}
]: any -> record<plan: record<lago_id: string, name: string, invoice_display_name: string, created_at: string, code: string, interval: string, description: string, amount_cents: int, amount_currency: string, trial_period: float, pay_in_advance: bool, bill_charges_monthly: bool, bill_fixed_charges_monthly: bool, minimum_commitment: record<lago_id: string, plan_code: string, amount_cents: int, invoice_display_name: string, interval: string, created_at: string, updated_at: string, taxes: list>, charges: list<record>, fixed_charges: list<record>, taxes: list<record>, usage_thresholds: list<record>, entitlements: list<record>, metadata: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)")
  let body = {plan: $plan} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a plan
#
# GET /plans/{code}
# operationId: findPlan
export def "plans findPlan" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<plan: record<lago_id: string, name: string, invoice_display_name: string, created_at: string, code: string, interval: string, description: string, amount_cents: int, amount_currency: string, trial_period: float, pay_in_advance: bool, bill_charges_monthly: bool, bill_fixed_charges_monthly: bool, minimum_commitment: record<lago_id: string, plan_code: string, amount_cents: int, invoice_display_name: string, interval: string, created_at: string, updated_at: string, taxes: list>, charges: list<record>, fixed_charges: list<record>, taxes: list<record>, usage_thresholds: list<record>, entitlements: list<record>, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a plan
#
# DELETE /plans/{code}
# operationId: destroyPlan
export def "plans destroyPlan" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<plan: record<lago_id: string, name: string, invoice_display_name: string, created_at: string, code: string, interval: string, description: string, amount_cents: int, amount_currency: string, trial_period: float, pay_in_advance: bool, bill_charges_monthly: bool, bill_fixed_charges_monthly: bool, minimum_commitment: record<lago_id: string, plan_code: string, amount_cents: int, invoice_display_name: string, interval: string, created_at: string, updated_at: string, taxes: list>, charges: list<record>, fixed_charges: list<record>, taxes: list<record>, usage_thresholds: list<record>, entitlements: list<record>, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an entitlement
#
# POST /plans/{code}/entitlements
# operationId: createEntitlement
export def "plans-entitlements createEntitlement" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  entitlements: record # Feature entitlements with their privilege values. Each key is a feature code, and the value is an object containing privilege codes with their associated values. (e.g. {seats: {max: 20, max_admins: 10, root: false}, sso: {provider: okta}})
]: any -> record<entitlements: table<code: string, name: string, description: string, privileges: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)/entitlements")
  let body = {entitlements: $entitlements} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all entitlements
#
# GET /plans/{code}/entitlements
# operationId: findAllEntitlements
export def "plans-entitlements findAllEntitlements" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<entitlements: table<code: string, name: string, description: string, privileges: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)/entitlements")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Partial update of an entitlement
#
# PATCH /plans/{code}/entitlements
# operationId: updateEntitlement
export def "plans-entitlements updateEntitlement" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  entitlements: record # Feature entitlements with their privilege values. Each key is a feature code, and the value is an object containing privilege codes with their associated values. (e.g. {seats: {max: 20, max_admins: 10, root: false}, sso: {provider: okta}})
]: any -> record<entitlements: table<code: string, name: string, description: string, privileges: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)/entitlements")
  let body = {entitlements: $entitlements} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an entitlement
#
# GET /plans/{code}/entitlements/{feature_code}
# operationId: findEntitlement
export def "plans-entitlements findEntitlement" [
  code: string
  feature_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<entitlement: record<code: string, name: string, description: string, privileges: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)/entitlements/($feature_code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an entitlement
#
# DELETE /plans/{code}/entitlements/{feature_code}
# operationId: destroyEntitlement
export def "plans-entitlements destroyEntitlement" [
  code: string
  feature_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<entitlement: record<code: string, name: string, description: string, privileges: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)/entitlements/($feature_code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a privilege from an entitlement
#
# DELETE /plans/{code}/entitlements/{feature_code}/privileges/{privilege_code}
# operationId: removeEntitlementPrivilege
export def "plans-entitlements-privileges removeEntitlementPrivilege" [
  code: string
  feature_code: string
  privilege_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<entitlement: record<code: string, name: string, description: string, privileges: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)/entitlements/($feature_code)/privileges/($privilege_code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace plan metadata
#
# POST /plans/{code}/metadata
# operationId: replacePlanMetadata
export def "plans-metadata replacePlanMetadata" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: record # Custom metadata stored as key-value pairs. Keys are strings (max 100 characters), values can be strings (max 255 characters) or null. (nullable, e.g. {external_id: ext-123, synced_at: 2024-01-15, source: })
]: any -> record<metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)/metadata")
  let body = {metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Merge plan metadata
#
# PATCH /plans/{code}/metadata
# operationId: mergePlanMetadata
export def "plans-metadata mergePlanMetadata" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: record # Custom metadata stored as key-value pairs. Keys are strings (max 100 characters), values can be strings (max 255 characters) or null. (nullable, e.g. {external_id: ext-123, synced_at: 2024-01-15, source: })
]: any -> record<metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)/metadata")
  let body = {metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete all plan metadata
#
# DELETE /plans/{code}/metadata
# operationId: deleteAllPlanMetadata
export def "plans-metadata delete-by-code" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a metadata key
#
# DELETE /plans/{code}/metadata/{key}
# operationId: deletePlanMetadataKey
export def "plans-metadata delete-by-code-key" [
  code: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)/metadata/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a charge
#
# POST /plans/{code}/charges
# operationId: createPlanCharge
export def "plans-charges createPlanCharge" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  charge: any
]: any -> record<charge: record<lago_id: string, lago_billable_metric_id: string, code: string, billable_metric_code: string, invoice_display_name: string, created_at: string, charge_model: string, pay_in_advance: bool, invoiceable: bool, regroup_paid_fees: string, prorated: bool, min_amount_cents: int, properties: record<grouped_by: list, pricing_group_keys: list, graduated_ranges: list, graduated_percentage_ranges: list, amount: string, free_units: int, package_size: int, rate: string, fixed_amount: string, free_units_per_events: int, free_units_per_total_aggregation: string, per_transaction_max_amount: string, per_transaction_min_amount: string, volume_ranges: list, presentation_group_keys: list>, filters: list<record>, taxes: list<record>, applied_pricing_unit: record<code: string, conversion_rate: string>, accepts_target_wallet: bool, lago_parent_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)/charges")
  let body = {charge: $charge} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all charges for a plan
#
# GET /plans/{code}/charges
# operationId: findAllPlanCharges
export def "plans-charges findAllPlanCharges" [
  code: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
]: nothing -> record<charges: table<lago_id: string, lago_billable_metric_id: string, code: string, billable_metric_code: string, invoice_display_name: string, created_at: string, charge_model: string, pay_in_advance: bool, invoiceable: bool, regroup_paid_fees: string, prorated: bool, min_amount_cents: int, properties: record, filters: list, taxes: list, applied_pricing_unit: record, accepts_target_wallet: bool, lago_parent_id: string>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/plans/($code)/charges" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a charge
#
# GET /plans/{code}/charges/{charge_code}
# operationId: findPlanCharge
export def "plans-charges findPlanCharge" [
  code: string
  charge_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<charge: record<lago_id: string, lago_billable_metric_id: string, code: string, billable_metric_code: string, invoice_display_name: string, created_at: string, charge_model: string, pay_in_advance: bool, invoiceable: bool, regroup_paid_fees: string, prorated: bool, min_amount_cents: int, properties: record<grouped_by: list, pricing_group_keys: list, graduated_ranges: list, graduated_percentage_ranges: list, amount: string, free_units: int, package_size: int, rate: string, fixed_amount: string, free_units_per_events: int, free_units_per_total_aggregation: string, per_transaction_max_amount: string, per_transaction_min_amount: string, volume_ranges: list, presentation_group_keys: list>, filters: list<record>, taxes: list<record>, applied_pricing_unit: record<code: string, conversion_rate: string>, accepts_target_wallet: bool, lago_parent_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)/charges/($charge_code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a charge
#
# PUT /plans/{code}/charges/{charge_code}
# operationId: updatePlanCharge
export def "plans-charges updatePlanCharge" [
  code: string
  charge_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  charge: any
]: any -> record<charge: record<lago_id: string, lago_billable_metric_id: string, code: string, billable_metric_code: string, invoice_display_name: string, created_at: string, charge_model: string, pay_in_advance: bool, invoiceable: bool, regroup_paid_fees: string, prorated: bool, min_amount_cents: int, properties: record<grouped_by: list, pricing_group_keys: list, graduated_ranges: list, graduated_percentage_ranges: list, amount: string, free_units: int, package_size: int, rate: string, fixed_amount: string, free_units_per_events: int, free_units_per_total_aggregation: string, per_transaction_max_amount: string, per_transaction_min_amount: string, volume_ranges: list, presentation_group_keys: list>, filters: list<record>, taxes: list<record>, applied_pricing_unit: record<code: string, conversion_rate: string>, accepts_target_wallet: bool, lago_parent_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)/charges/($charge_code)")
  let body = {charge: $charge} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a charge
#
# DELETE /plans/{code}/charges/{charge_code}
# operationId: destroyPlanCharge
# --charge shape: {cascade_updates?: bool}
export def "plans-charges destroyPlanCharge" [
  code: string
  charge_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --charge: record # shape: {cascade_updates?: bool}
]: any -> record<charge: record<lago_id: string, lago_billable_metric_id: string, code: string, billable_metric_code: string, invoice_display_name: string, created_at: string, charge_model: string, pay_in_advance: bool, invoiceable: bool, regroup_paid_fees: string, prorated: bool, min_amount_cents: int, properties: record<grouped_by: list, pricing_group_keys: list, graduated_ranges: list, graduated_percentage_ranges: list, amount: string, free_units: int, package_size: int, rate: string, fixed_amount: string, free_units_per_events: int, free_units_per_total_aggregation: string, per_transaction_max_amount: string, per_transaction_min_amount: string, volume_ranges: list, presentation_group_keys: list>, filters: list<record>, taxes: list<record>, applied_pricing_unit: record<code: string, conversion_rate: string>, accepts_target_wallet: bool, lago_parent_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)/charges/($charge_code)")
  let body = {charge: $charge} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a charge filter
#
# POST /plans/{code}/charges/{charge_code}/filters
# operationId: createPlanChargeFilter
# --filter shape: {cascade_updates?: bool, invoice_display_name?: string, properties: record, values: record}
export def "plans-charges-filters createPlanChargeFilter" [
  code: string
  charge_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  filter: record # shape: {cascade_updates?: bool, invoice_display_name?: string, properties: record, values: record}
]: any -> record<filter: record<lago_id: string, charge_code: string, invoice_display_name: string, properties: record<grouped_by: list, pricing_group_keys: list, graduated_ranges: list, graduated_percentage_ranges: list, amount: string, free_units: int, package_size: int, rate: string, fixed_amount: string, free_units_per_events: int, free_units_per_total_aggregation: string, per_transaction_max_amount: string, per_transaction_min_amount: string, volume_ranges: list>, values: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)/charges/($charge_code)/filters")
  let body = {filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all filters for a charge
#
# GET /plans/{code}/charges/{charge_code}/filters
# operationId: findAllPlanChargeFilters
export def "plans-charges-filters findAllPlanChargeFilters" [
  code: any
  charge_code: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
]: nothing -> record<filters: table<lago_id: string, charge_code: string, invoice_display_name: string, properties: record, values: record>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/plans/($code)/charges/($charge_code)/filters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a charge filter
#
# GET /plans/{code}/charges/{charge_code}/filters/{filter_id}
# operationId: findPlanChargeFilter
export def "plans-charges-filters findPlanChargeFilter" [
  code: string
  charge_code: string
  filter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<filter: record<lago_id: string, charge_code: string, invoice_display_name: string, properties: record<grouped_by: list, pricing_group_keys: list, graduated_ranges: list, graduated_percentage_ranges: list, amount: string, free_units: int, package_size: int, rate: string, fixed_amount: string, free_units_per_events: int, free_units_per_total_aggregation: string, per_transaction_max_amount: string, per_transaction_min_amount: string, volume_ranges: list>, values: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)/charges/($charge_code)/filters/($filter_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a charge filter
#
# PUT /plans/{code}/charges/{charge_code}/filters/{filter_id}
# operationId: updatePlanChargeFilter
# --filter shape: {cascade_updates?: bool, invoice_display_name?: string, properties?: record, values?: record}
export def "plans-charges-filters updatePlanChargeFilter" [
  code: string
  charge_code: string
  filter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  filter: record # shape: {cascade_updates?: bool, invoice_display_name?: string, properties?: record, values?: record}
]: any -> record<filter: record<lago_id: string, charge_code: string, invoice_display_name: string, properties: record<grouped_by: list, pricing_group_keys: list, graduated_ranges: list, graduated_percentage_ranges: list, amount: string, free_units: int, package_size: int, rate: string, fixed_amount: string, free_units_per_events: int, free_units_per_total_aggregation: string, per_transaction_max_amount: string, per_transaction_min_amount: string, volume_ranges: list>, values: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)/charges/($charge_code)/filters/($filter_id)")
  let body = {filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a charge filter
#
# DELETE /plans/{code}/charges/{charge_code}/filters/{filter_id}
# operationId: destroyPlanChargeFilter
# --filter shape: {cascade_updates?: bool}
export def "plans-charges-filters destroyPlanChargeFilter" [
  code: string
  charge_code: string
  filter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: record # shape: {cascade_updates?: bool}
]: any -> record<filter: record<lago_id: string, charge_code: string, invoice_display_name: string, properties: record<grouped_by: list, pricing_group_keys: list, graduated_ranges: list, graduated_percentage_ranges: list, amount: string, free_units: int, package_size: int, rate: string, fixed_amount: string, free_units_per_events: int, free_units_per_total_aggregation: string, per_transaction_max_amount: string, per_transaction_min_amount: string, volume_ranges: list>, values: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)/charges/($charge_code)/filters/($filter_id)")
  let body = {filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a fixed charge
#
# POST /plans/{code}/fixed_charges
# operationId: createPlanFixedCharge
export def "plans-fixed-charges createPlanFixedCharge" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  fixed_charge: any
]: any -> record<fixed_charge: record<lago_id: string, lago_add_on_id: string, invoice_display_name: string, add_on_code: string, created_at: string, code: string, charge_model: string, pay_in_advance: bool, prorated: bool, properties: record<amount: string, graduated_ranges: list, volume_ranges: list>, units: float, lago_parent_id: string, taxes: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)/fixed_charges")
  let body = {fixed_charge: $fixed_charge} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all fixed charges for a plan
#
# GET /plans/{code}/fixed_charges
# operationId: findAllPlanFixedCharges
export def "plans-fixed-charges findAllPlanFixedCharges" [
  code: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
]: nothing -> record<fixed_charges: table<lago_id: string, lago_add_on_id: string, invoice_display_name: string, add_on_code: string, created_at: string, code: string, charge_model: string, pay_in_advance: bool, prorated: bool, properties: record, units: float, lago_parent_id: string, taxes: list>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/plans/($code)/fixed_charges" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a fixed charge
#
# GET /plans/{code}/fixed_charges/{fixed_charge_code}
# operationId: findPlanFixedCharge
export def "plans-fixed-charges findPlanFixedCharge" [
  code: string
  fixed_charge_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fixed_charge: record<lago_id: string, lago_add_on_id: string, invoice_display_name: string, add_on_code: string, created_at: string, code: string, charge_model: string, pay_in_advance: bool, prorated: bool, properties: record<amount: string, graduated_ranges: list, volume_ranges: list>, units: float, lago_parent_id: string, taxes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)/fixed_charges/($fixed_charge_code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a fixed charge
#
# PUT /plans/{code}/fixed_charges/{fixed_charge_code}
# operationId: updatePlanFixedCharge
export def "plans-fixed-charges updatePlanFixedCharge" [
  code: string
  fixed_charge_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  fixed_charge: any
]: any -> record<fixed_charge: record<lago_id: string, lago_add_on_id: string, invoice_display_name: string, add_on_code: string, created_at: string, code: string, charge_model: string, pay_in_advance: bool, prorated: bool, properties: record<amount: string, graduated_ranges: list, volume_ranges: list>, units: float, lago_parent_id: string, taxes: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)/fixed_charges/($fixed_charge_code)")
  let body = {fixed_charge: $fixed_charge} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a fixed charge
#
# DELETE /plans/{code}/fixed_charges/{fixed_charge_code}
# operationId: destroyPlanFixedCharge
# --fixed_charge shape: {cascade_updates?: bool}
export def "plans-fixed-charges destroyPlanFixedCharge" [
  code: string
  fixed_charge_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fixed-charge: record # shape: {cascade_updates?: bool}
]: any -> record<fixed_charge: record<lago_id: string, lago_add_on_id: string, invoice_display_name: string, add_on_code: string, created_at: string, code: string, charge_model: string, pay_in_advance: bool, prorated: bool, properties: record<amount: string, graduated_ranges: list, volume_ranges: list>, units: float, lago_parent_id: string, taxes: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($code)/fixed_charges/($fixed_charge_code)")
  let body = {fixed_charge: $fixed_charge} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign a plan to a customer
#
# POST /subscriptions
# operationId: createSubscription
# --authorization shape: {amount_cents: int, amount_currency: string}
# --subscription shape: {billing_entity_code?: string, external_customer_id: string, plan_code: string, name?: string, external_id: string, billing_time?: "calendar"|"anniversary", ending_at?: string, subscription_at?: string, plan_overrides?: record, invoice_custom_section?: record, payment_method?: record, consolidate_invoice?: bool}
export def "subscriptions createSubscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authorization: record # Optionally, you can create a pre-authorization on the customer's card before creating a subscription. This process places a temporary hold (capture) for a specified amount on the customer's account, but does not actually withdraw the funds.  Important notes:   - The final amount due for the subscription is not known at the time of creation; it is determined only after the invoice is finalized.   - The payment intent generated for pre-authorization cannot be reused, as the final invoice amount may exceed the authorized amount.   - The payment intent is canceled immediately after creation, but this cancellation occurs asynchronously.   - For these reasons, it is recommended to use a small amount (such as $1) for pre-authorization. While this does not guarantee sufficient funds for the final payment, it helps reduce the likelihood of payment errors. — shape: {amount_cents: int, amount_currency: string}
  subscription: record # shape: {billing_entity_code?: string, external_customer_id: string, plan_code: string, name?: string, external_id: string, billing_time?: "calendar"|"anniversary", ending_at?: string, subscription_at?: string, plan_overrides?: record, invoice_custom_section?: record, payment_method?: record, consolidate_invoice?: bool}
]: any -> record<subscription: record<lago_id: string, external_id: string, lago_customer_id: string, external_customer_id: string, billing_time: string, name: string, plan_code: string, plan_amount_cents: int, plan_amount_currency: string, status: string, created_at: string, canceled_at: string, started_at: string, ending_at: string, subscription_at: string, terminated_at: string, previous_plan_code: string, next_plan_code: string, downgrade_plan_date: string, trial_ended_at: string, current_billing_period_started_at: string, current_billing_period_ending_at: string, on_termination_credit_note: string, on_termination_invoice: string, applied_invoice_custom_sections: list<record>, payment_method: record<payment_method_type: string, payment_method_id: string>, consolidate_invoice: bool, plan: record<lago_id: string, name: string, invoice_display_name: string, created_at: string, code: string, interval: string, description: string, amount_cents: int, amount_currency: string, trial_period: float, pay_in_advance: bool, bill_charges_monthly: bool, bill_fixed_charges_monthly: bool, minimum_commitment: record, charges: list, fixed_charges: list, taxes: list, usage_thresholds: list, entitlements: list, metadata: record>, applicable_usage_thresholds: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscriptions")
  let body = {authorization: $authorization, subscription: $subscription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all subscriptions
#
# GET /subscriptions
# operationId: findAllSubscriptions
export def "subscriptions findAllSubscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --external-customer-id: string # The customer external unique identifier (provided by your own application) (e.g. 5eb02857-a71e-4ea2-bcf9-57d3a41bc6ba)
  --plan-code: string # The unique code representing the plan to be attached to the customer. This code must correspond to the code property of one of the active plans. (e.g. premium)
  --status: list # If the field is not defined, Lago will return only `active` subscriptions. However, if you wish to fetch subscriptions by different status you can define them in a status[] query param. Available filter values: `pending`, `canceled`, `terminated`, `active`. (e.g. [active, pending])
]: nothing -> record<subscriptions: table<lago_id: string, external_id: string, lago_customer_id: string, external_customer_id: string, billing_time: string, name: string, plan_code: string, plan_amount_cents: int, plan_amount_currency: string, status: string, created_at: string, canceled_at: string, started_at: string, ending_at: string, subscription_at: string, terminated_at: string, previous_plan_code: string, next_plan_code: string, downgrade_plan_date: string, trial_ended_at: string, current_billing_period_started_at: string, current_billing_period_ending_at: string, on_termination_credit_note: string, on_termination_invoice: string, applied_invoice_custom_sections: list, payment_method: record, consolidate_invoice: bool>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "external_customer_id" $external_customer_id "scalar") (serialize-qp "plan_code" $plan_code "scalar") (serialize-qp "status[]" $status "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a subscription
#
# GET /subscriptions/{external_id}
# operationId: findSubscription
export def "subscriptions findSubscription" [
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-2 # By default, this endpoint only return `active` subscriptions. If you want to retrieve a subscription with a different `status`, you can specify it here.  _Note: As there may exists multiple `canceled` or `terminated` subscribtions for the same `external_id`, it is recommended to use the "List all subscriptions" endpoint to retrieve those subscriptions._  (default: active, e.g. active)
]: nothing -> record<subscription: record<lago_id: string, external_id: string, lago_customer_id: string, external_customer_id: string, billing_time: string, name: string, plan_code: string, plan_amount_cents: int, plan_amount_currency: string, status: string, created_at: string, canceled_at: string, started_at: string, ending_at: string, subscription_at: string, terminated_at: string, previous_plan_code: string, next_plan_code: string, downgrade_plan_date: string, trial_ended_at: string, current_billing_period_started_at: string, current_billing_period_ending_at: string, on_termination_credit_note: string, on_termination_invoice: string, applied_invoice_custom_sections: list<record>, payment_method: record<payment_method_type: string, payment_method_id: string>, consolidate_invoice: bool, plan: record<lago_id: string, name: string, invoice_display_name: string, created_at: string, code: string, interval: string, description: string, amount_cents: int, amount_currency: string, trial_period: float, pay_in_advance: bool, bill_charges_monthly: bool, bill_fixed_charges_monthly: bool, minimum_commitment: record, charges: list, fixed_charges: list, taxes: list, usage_thresholds: list, entitlements: list, metadata: record>, applicable_usage_thresholds: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a subscription
#
# PUT /subscriptions/{external_id}
# operationId: updateSubscription
# --subscription shape: {name?: string, ending_at: string, subscription_at?: string, plan_overrides?: record, invoice_custom_section?: record, payment_method?: record, consolidate_invoice?: bool}
export def "subscriptions updateSubscription" [
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-3 # By default, this endpoint only return `active` subscriptions. If you want to update a subscription with a different `status`, you can specify it here.  (default: active, e.g. active)
  --status: string@status-completer-3 # If the field is not defined and multiple `active` and `pending` subscriptions exists, Lago will update the `active` subscription. However, if you wish to update a `pending` subscription, please ensure that you include the `status` attribute with the `pending` value in your request body. (e.g. active)
  subscription: record # shape: {name?: string, ending_at: string, subscription_at?: string, plan_overrides?: record, invoice_custom_section?: record, payment_method?: record, consolidate_invoice?: bool}
]: any -> record<subscription: record<lago_id: string, external_id: string, lago_customer_id: string, external_customer_id: string, billing_time: string, name: string, plan_code: string, plan_amount_cents: int, plan_amount_currency: string, status: string, created_at: string, canceled_at: string, started_at: string, ending_at: string, subscription_at: string, terminated_at: string, previous_plan_code: string, next_plan_code: string, downgrade_plan_date: string, trial_ended_at: string, current_billing_period_started_at: string, current_billing_period_ending_at: string, on_termination_credit_note: string, on_termination_invoice: string, applied_invoice_custom_sections: list<record>, payment_method: record<payment_method_type: string, payment_method_id: string>, consolidate_invoice: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)" $qp)
  let body = {status: $status, subscription: $subscription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Terminate a subscription
#
# DELETE /subscriptions/{external_id}
# operationId: destroySubscription
export def "subscriptions destroySubscription" [
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string # If the field is not defined, Lago will terminate only `active` subscriptions. However, if you wish to cancel a `pending` subscription, please ensure that you include `status=pending` in your request. (e.g. pending)
  --on-termination-credit-note: string@on-termination-credit-note-completer # When a pay-in-advance subscription is terminated before the end of its billing period, we generate a credit note for the unused subscription time by default. This field allows you to control the behavior of the credit note generation:  - `credit`: A credit note is generated for the unused subscription time. The unused amount is credited back to the customer. - `refund`: A credit note is generated for the unused subscription time. If the invoice is paid or partially paid, the unused paid amount is refunded; any unpaid unused amount is credited back to the customer. - `skip`: No credit note is generated for the unused subscription time.  _Note: This field is only applicable to pay-in-advance plans and is ignored for pay-in-arrears plans._  (e.g. credit)
  --on-termination-invoice: string@on-termination-invoice-completer # When a subscription is terminated before the end of its billing period, we generate an invoice for the unbilled usage. This field allows you to control the behavior of the invoice generation:  - `generate`: An invoice is generated for the unbilled usage. - `skip`: No invoice is generated for the unbilled usage.  (e.g. generate)
]: nothing -> record<subscription: record<lago_id: string, external_id: string, lago_customer_id: string, external_customer_id: string, billing_time: string, name: string, plan_code: string, plan_amount_cents: int, plan_amount_currency: string, status: string, created_at: string, canceled_at: string, started_at: string, ending_at: string, subscription_at: string, terminated_at: string, previous_plan_code: string, next_plan_code: string, downgrade_plan_date: string, trial_ended_at: string, current_billing_period_started_at: string, current_billing_period_ending_at: string, on_termination_credit_note: string, on_termination_invoice: string, applied_invoice_custom_sections: list<record>, payment_method: record<payment_method_type: string, payment_method_id: string>, consolidate_invoice: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "on_termination_credit_note" $on_termination_credit_note "scalar") (serialize-qp "on_termination_invoice" $on_termination_invoice "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve subscription lifetime usage
#
# GET /subscriptions/{external_id}/lifetime_usage
# operationId: getSubscriptionLifetimeUsage
export def "subscriptions-lifetime-usage get" [
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<lifetime_usage: record<lago_id: string, lago_subscription_id: string, external_subscription_id: string, external_historical_usage_amount_cents: int, invoiced_usage_amount_cents: int, current_usage_amount_cents: int, from_datetime: string, to_datetime: string, usage_thresholds: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($external_id)/lifetime_usage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a subscription lifetime usage
#
# PUT /subscriptions/{external_id}/lifetime_usage
# operationId: updateSubscriptionLifetimeUsage
# --lifetime_usage shape: {external_historical_usage_amount_cents: int}
export def "subscriptions-lifetime-usage updateSubscriptionLifetimeUsage" [
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  lifetime_usage: record # shape: {external_historical_usage_amount_cents: int}
]: any -> record<lifetime_usage: record<lago_id: string, lago_subscription_id: string, external_subscription_id: string, external_historical_usage_amount_cents: int, invoiced_usage_amount_cents: int, current_usage_amount_cents: int, from_datetime: string, to_datetime: string, usage_thresholds: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($external_id)/lifetime_usage")
  let body = {lifetime_usage: $lifetime_usage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List subscription alerts
#
# GET /subscriptions/{external_id}/alerts
# operationId: getSubscriptionAlerts
export def "subscriptions-alerts list" [
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscription-status: string@subscription-status-completer # Filter by subscription status. When provided, the subscription is looked up with this status instead of the default `active` status. Possible values are `pending`, `active`, `terminated`, or `canceled`.  (default: active, e.g. active)
]: nothing -> record<alerts: table<lago_id: string, lago_organization_id: string, external_subscription_id: string, lago_wallet_id: any, wallet_code: any, billable_metric: record, alert_type: string, code: string, name: string, direction: string, previous_value: float, last_processed_at: string, thresholds: list, created_at: string>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_status" $subscription_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)/alerts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create subscription alert(s)
#
# POST /subscriptions/{external_id}/alerts
# operationId: createSubscriptionAlert
# --alerts item shape: {code: string, name?: string, thresholds: list, alert_type: "current_usage_amount"|"billable_metric_current_usage_amount"|"billable_metric_current_usage_units"|"lifetime_usage_amount", billable_metric_code?: string}
export def "subscriptions-alerts createSubscriptionAlert" [
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscription-status: string@subscription-status-completer # Filter by subscription status. When provided, the subscription is looked up with this status instead of the default `active` status. Possible values are `pending`, `active`, `terminated`, or `canceled`.  (default: active, e.g. active)
  --alert: any
  --alerts: list # Array of alerts to create. All alerts are created atomically - if any fail validation, none are created. — item shape: {code: string, name?: string, thresholds: list, alert_type: "current_usage_amount"|"billable_metric_current_usage_amount"|"billable_metric_current_usage_units"|"lifetime_usage_amount", billable_metric_code?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_status" $subscription_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)/alerts" $qp)
  let body = {alert: $alert, alerts: $alerts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete all subscription alerts
#
# DELETE /subscriptions/{external_id}/alerts
# operationId: deleteAllSubscriptionAlerts
export def "subscriptions-alerts delete-by-external_id" [
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscription-status: string@subscription-status-completer # Filter by subscription status. When provided, the subscription is looked up with this status instead of the default `active` status. Possible values are `pending`, `active`, `terminated`, or `canceled`.  (default: active, e.g. active)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_status" $subscription_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)/alerts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a subscription alert
#
# GET /subscriptions/{external_id}/alerts/{code}
# operationId: getSubscriptionAlert
export def "subscriptions-alerts get" [
  external_id: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscription-status: string@subscription-status-completer # Filter by subscription status. When provided, the subscription is looked up with this status instead of the default `active` status. Possible values are `pending`, `active`, `terminated`, or `canceled`.  (default: active, e.g. active)
]: nothing -> record<alert: record<lago_id: string, lago_organization_id: string, external_subscription_id: string, lago_wallet_id: any, wallet_code: any, billable_metric: record<lago_id: string, name: string, code: string, description: string, recurring: bool, rounding_function: string, rounding_precision: int, created_at: string, expression: string, field_name: string, aggregation_type: string, weighted_interval: string, filters: list>, alert_type: string, code: string, name: string, direction: string, previous_value: float, last_processed_at: string, thresholds: list<record>, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_status" $subscription_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)/alerts/($code)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a subscription alert
#
# PUT /subscriptions/{external_id}/alerts/{code}
# operationId: updateSubscriptionAlert
export def "subscriptions-alerts updateSubscriptionAlert" [
  external_id: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscription-status: string@subscription-status-completer # Filter by subscription status. When provided, the subscription is looked up with this status instead of the default `active` status. Possible values are `pending`, `active`, `terminated`, or `canceled`.  (default: active, e.g. active)
  alert: any
]: any -> record<alert: record<lago_id: string, lago_organization_id: string, external_subscription_id: string, lago_wallet_id: any, wallet_code: any, billable_metric: record<lago_id: string, name: string, code: string, description: string, recurring: bool, rounding_function: string, rounding_precision: int, created_at: string, expression: string, field_name: string, aggregation_type: string, weighted_interval: string, filters: list>, alert_type: string, code: string, name: string, direction: string, previous_value: float, last_processed_at: string, thresholds: list<record>, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_status" $subscription_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)/alerts/($code)" $qp)
  let body = {alert: $alert} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a subscription alert
#
# DELETE /subscriptions/{external_id}/alerts/{code}
# operationId: deleteSubscriptionAlert
export def "subscriptions-alerts delete-by-external_id-code" [
  external_id: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscription-status: string@subscription-status-completer # Filter by subscription status. When provided, the subscription is looked up with this status instead of the default `active` status. Possible values are `pending`, `active`, `terminated`, or `canceled`.  (default: active, e.g. active)
]: nothing -> record<alert: record<lago_id: string, lago_organization_id: string, external_subscription_id: string, lago_wallet_id: any, wallet_code: any, billable_metric: record<lago_id: string, name: string, code: string, description: string, recurring: bool, rounding_function: string, rounding_precision: int, created_at: string, expression: string, field_name: string, aggregation_type: string, weighted_interval: string, filters: list>, alert_type: string, code: string, name: string, direction: string, previous_value: float, last_processed_at: string, thresholds: list<record>, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_status" $subscription_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)/alerts/($code)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all subscription entitlements
#
# GET /subscriptions/{external_id}/entitlements
# operationId: findAllSubscriptionEntitlements
export def "subscriptions-entitlements findAllSubscriptionEntitlements" [
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscription-status: string@subscription-status-completer # Filter by subscription status. When provided, the subscription is looked up with this status instead of the default `active` status. Possible values are `pending`, `active`, `terminated`, or `canceled`.  (default: active, e.g. active)
]: nothing -> record<entitlements: table<code: string, name: string, description: string, privileges: list, overrides: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_status" $subscription_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)/entitlements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update subscription entitlements
#
# PATCH /subscriptions/{external_id}/entitlements
# operationId: updateSubscriptionEntitlements
export def "subscriptions-entitlements updateSubscriptionEntitlements" [
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscription-status: string@subscription-status-completer # Filter by subscription status. When provided, the subscription is looked up with this status instead of the default `active` status. Possible values are `pending`, `active`, `terminated`, or `canceled`.  (default: active, e.g. active)
  entitlements: record # Feature entitlements with their privilege values. Each key is a feature code, and the value is an object containing privilege codes with their associated values. (e.g. {seats: {max: 20, max_admins: 10, root: false}, sso: {provider: okta}})
]: any -> record<entitlements: table<code: string, name: string, description: string, privileges: list, overrides: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_status" $subscription_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)/entitlements" $qp)
  let body = {entitlements: $entitlements} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an entitlement from a subscription
#
# DELETE /subscriptions/{external_id}/entitlements/{feature_code}
# operationId: destroySubscriptionEntitlement
export def "subscriptions-entitlements destroySubscriptionEntitlement" [
  external_id: string
  feature_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscription-status: string@subscription-status-completer # Filter by subscription status. When provided, the subscription is looked up with this status instead of the default `active` status. Possible values are `pending`, `active`, `terminated`, or `canceled`.  (default: active, e.g. active)
]: nothing -> record<entitlement: record<code: string, name: string, description: string, privileges: list<record>, overrides: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_status" $subscription_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)/entitlements/($feature_code)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a privilege from a subscription entitlement override
#
# DELETE /subscriptions/{external_id}/entitlements/{feature_code}/privileges/{privilege_code}
# operationId: destroySubscriptionEntitlementPrivilege
export def "subscriptions-entitlements-privileges destroySubscriptionEntitlementPrivilege" [
  external_id: string
  feature_code: string
  privilege_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscription-status: string@subscription-status-completer # Filter by subscription status. When provided, the subscription is looked up with this status instead of the default `active` status. Possible values are `pending`, `active`, `terminated`, or `canceled`.  (default: active, e.g. active)
]: nothing -> record<entitlement: record<code: string, name: string, description: string, privileges: list<record>, overrides: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_status" $subscription_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)/entitlements/($feature_code)/privileges/($privilege_code)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all fixed charges for a subscription
#
# GET /subscriptions/{external_id}/fixed_charges
# operationId: findAllSubscriptionFixedCharges
export def "subscriptions-fixed-charges findAllSubscriptionFixedCharges" [
  external_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --subscription-status: string@subscription-status-completer # Filter by subscription status. When provided, the subscription is looked up with this status instead of the default `active` status. Possible values are `pending`, `active`, `terminated`, or `canceled`.  (default: active, e.g. active)
]: nothing -> record<fixed_charges: table<lago_id: string, lago_add_on_id: string, invoice_display_name: string, add_on_code: string, created_at: string, code: string, charge_model: string, pay_in_advance: bool, prorated: bool, properties: record, units: float, lago_parent_id: string, taxes: list>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "subscription_status" $subscription_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)/fixed_charges" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all charges for a subscription
#
# GET /subscriptions/{external_id}/charges
# operationId: findAllSubscriptionCharges
export def "subscriptions-charges findAllSubscriptionCharges" [
  external_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --subscription-status: string@subscription-status-completer # Filter by subscription status. When provided, the subscription is looked up with this status instead of the default `active` status. Possible values are `pending`, `active`, `terminated`, or `canceled`.  (default: active, e.g. active)
]: nothing -> record<charges: table<lago_id: string, lago_billable_metric_id: string, code: string, billable_metric_code: string, invoice_display_name: string, created_at: string, charge_model: string, pay_in_advance: bool, invoiceable: bool, regroup_paid_fees: string, prorated: bool, min_amount_cents: int, properties: record, filters: list, taxes: list, applied_pricing_unit: record, accepts_target_wallet: bool, lago_parent_id: string>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "subscription_status" $subscription_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)/charges" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a charge for a subscription
#
# GET /subscriptions/{external_id}/charges/{charge_code}
# operationId: findSubscriptionCharge
export def "subscriptions-charges findSubscriptionCharge" [
  external_id: any
  charge_code: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscription-status: string@subscription-status-completer # Filter by subscription status. When provided, the subscription is looked up with this status instead of the default `active` status. Possible values are `pending`, `active`, `terminated`, or `canceled`.  (default: active, e.g. active)
]: nothing -> record<charge: record<lago_id: string, lago_billable_metric_id: string, code: string, billable_metric_code: string, invoice_display_name: string, created_at: string, charge_model: string, pay_in_advance: bool, invoiceable: bool, regroup_paid_fees: string, prorated: bool, min_amount_cents: int, properties: record<grouped_by: list, pricing_group_keys: list, graduated_ranges: list, graduated_percentage_ranges: list, amount: string, free_units: int, package_size: int, rate: string, fixed_amount: string, free_units_per_events: int, free_units_per_total_aggregation: string, per_transaction_max_amount: string, per_transaction_min_amount: string, volume_ranges: list, presentation_group_keys: list>, filters: list<record>, taxes: list<record>, applied_pricing_unit: record<code: string, conversion_rate: string>, accepts_target_wallet: bool, lago_parent_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_status" $subscription_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)/charges/($charge_code)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Override a charge for a subscription
#
# PUT /subscriptions/{external_id}/charges/{charge_code}
# operationId: overrideSubscriptionCharge
# --charge shape: {invoice_display_name?: string, min_amount_cents?: int, properties?: any, filters?: list, tax_codes?: list, applied_pricing_unit?: record}
export def "subscriptions-charges overrideSubscriptionCharge" [
  external_id: any
  charge_code: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscription-status: string@subscription-status-completer # Filter by subscription status. When provided, the subscription is looked up with this status instead of the default `active` status. Possible values are `pending`, `active`, `terminated`, or `canceled`.  (default: active, e.g. active)
  charge: record # Properties of a charge that can be overridden at the subscription level. — shape: {invoice_display_name?: string, min_amount_cents?: int, properties?: any, filters?: list, tax_codes?: list, applied_pricing_unit?: record}
]: any -> record<charge: record<lago_id: string, lago_billable_metric_id: string, code: string, billable_metric_code: string, invoice_display_name: string, created_at: string, charge_model: string, pay_in_advance: bool, invoiceable: bool, regroup_paid_fees: string, prorated: bool, min_amount_cents: int, properties: record<grouped_by: list, pricing_group_keys: list, graduated_ranges: list, graduated_percentage_ranges: list, amount: string, free_units: int, package_size: int, rate: string, fixed_amount: string, free_units_per_events: int, free_units_per_total_aggregation: string, per_transaction_max_amount: string, per_transaction_min_amount: string, volume_ranges: list, presentation_group_keys: list>, filters: list<record>, taxes: list<record>, applied_pricing_unit: record<code: string, conversion_rate: string>, accepts_target_wallet: bool, lago_parent_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_status" $subscription_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)/charges/($charge_code)" $qp)
  let body = {charge: $charge} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a charge filter
#
# POST /subscriptions/{external_id}/charges/{charge_code}/filters
# operationId: createSubscriptionChargeFilter
# --filter shape: {cascade_updates?: bool, invoice_display_name?: string, properties: record, values: record}
export def "subscriptions-charges-filters createSubscriptionChargeFilter" [
  external_id: any
  charge_code: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscription-status: string@subscription-status-completer # Filter by subscription status. When provided, the subscription is looked up with this status instead of the default `active` status. Possible values are `pending`, `active`, `terminated`, or `canceled`.  (default: active, e.g. active)
  filter: record # shape: {cascade_updates?: bool, invoice_display_name?: string, properties: record, values: record}
]: any -> record<filter: record<lago_id: string, charge_code: string, invoice_display_name: string, properties: record<grouped_by: list, pricing_group_keys: list, graduated_ranges: list, graduated_percentage_ranges: list, amount: string, free_units: int, package_size: int, rate: string, fixed_amount: string, free_units_per_events: int, free_units_per_total_aggregation: string, per_transaction_max_amount: string, per_transaction_min_amount: string, volume_ranges: list>, values: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_status" $subscription_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)/charges/($charge_code)/filters" $qp)
  let body = {filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all filters for a charge
#
# GET /subscriptions/{external_id}/charges/{charge_code}/filters
# operationId: findAllSubscriptionChargeFilters
export def "subscriptions-charges-filters findAllSubscriptionChargeFilters" [
  external_id: any
  charge_code: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --subscription-status: string@subscription-status-completer # Filter by subscription status. When provided, the subscription is looked up with this status instead of the default `active` status. Possible values are `pending`, `active`, `terminated`, or `canceled`.  (default: active, e.g. active)
]: nothing -> record<filters: table<lago_id: string, charge_code: string, invoice_display_name: string, properties: record, values: record>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "subscription_status" $subscription_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)/charges/($charge_code)/filters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a charge filter
#
# GET /subscriptions/{external_id}/charges/{charge_code}/filters/{filter_id}
# operationId: findSubscriptionChargeFilter
export def "subscriptions-charges-filters findSubscriptionChargeFilter" [
  external_id: any
  charge_code: any
  filter_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscription-status: string@subscription-status-completer # Filter by subscription status. When provided, the subscription is looked up with this status instead of the default `active` status. Possible values are `pending`, `active`, `terminated`, or `canceled`.  (default: active, e.g. active)
]: nothing -> record<filter: record<lago_id: string, charge_code: string, invoice_display_name: string, properties: record<grouped_by: list, pricing_group_keys: list, graduated_ranges: list, graduated_percentage_ranges: list, amount: string, free_units: int, package_size: int, rate: string, fixed_amount: string, free_units_per_events: int, free_units_per_total_aggregation: string, per_transaction_max_amount: string, per_transaction_min_amount: string, volume_ranges: list>, values: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_status" $subscription_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)/charges/($charge_code)/filters/($filter_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a charge filter
#
# PUT /subscriptions/{external_id}/charges/{charge_code}/filters/{filter_id}
# operationId: updateSubscriptionChargeFilter
# --filter shape: {cascade_updates?: bool, invoice_display_name?: string, properties?: record, values?: record}
export def "subscriptions-charges-filters updateSubscriptionChargeFilter" [
  external_id: any
  charge_code: any
  filter_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscription-status: string@subscription-status-completer # Filter by subscription status. When provided, the subscription is looked up with this status instead of the default `active` status. Possible values are `pending`, `active`, `terminated`, or `canceled`.  (default: active, e.g. active)
  filter: record # shape: {cascade_updates?: bool, invoice_display_name?: string, properties?: record, values?: record}
]: any -> record<filter: record<lago_id: string, charge_code: string, invoice_display_name: string, properties: record<grouped_by: list, pricing_group_keys: list, graduated_ranges: list, graduated_percentage_ranges: list, amount: string, free_units: int, package_size: int, rate: string, fixed_amount: string, free_units_per_events: int, free_units_per_total_aggregation: string, per_transaction_max_amount: string, per_transaction_min_amount: string, volume_ranges: list>, values: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_status" $subscription_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)/charges/($charge_code)/filters/($filter_id)" $qp)
  let body = {filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a charge filter
#
# DELETE /subscriptions/{external_id}/charges/{charge_code}/filters/{filter_id}
# operationId: destroySubscriptionChargeFilter
export def "subscriptions-charges-filters destroySubscriptionChargeFilter" [
  external_id: any
  charge_code: any
  filter_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscription-status: string@subscription-status-completer # Filter by subscription status. When provided, the subscription is looked up with this status instead of the default `active` status. Possible values are `pending`, `active`, `terminated`, or `canceled`.  (default: active, e.g. active)
]: nothing -> record<filter: record<lago_id: string, charge_code: string, invoice_display_name: string, properties: record<grouped_by: list, pricing_group_keys: list, graduated_ranges: list, graduated_percentage_ranges: list, amount: string, free_units: int, package_size: int, rate: string, fixed_amount: string, free_units_per_events: int, free_units_per_total_aggregation: string, per_transaction_max_amount: string, per_transaction_min_amount: string, volume_ranges: list>, values: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_status" $subscription_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)/charges/($charge_code)/filters/($filter_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a fixed charge for a subscription
#
# GET /subscriptions/{external_id}/fixed_charges/{fixed_charge_code}
# operationId: findSubscriptionFixedCharge
export def "subscriptions-fixed-charges findSubscriptionFixedCharge" [
  external_id: any
  fixed_charge_code: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscription-status: string@subscription-status-completer # Filter by subscription status. When provided, the subscription is looked up with this status instead of the default `active` status. Possible values are `pending`, `active`, `terminated`, or `canceled`.  (default: active, e.g. active)
]: nothing -> record<fixed_charge: record<lago_id: string, lago_add_on_id: string, invoice_display_name: string, add_on_code: string, created_at: string, code: string, charge_model: string, pay_in_advance: bool, prorated: bool, properties: record<amount: string, graduated_ranges: list, volume_ranges: list>, units: float, lago_parent_id: string, taxes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_status" $subscription_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)/fixed_charges/($fixed_charge_code)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Override a fixed charge for a subscription
#
# PUT /subscriptions/{external_id}/fixed_charges/{fixed_charge_code}
# operationId: overrideSubscriptionFixedCharge
# --fixed_charge shape: {invoice_display_name?: string, units?: string, apply_units_immediately?: bool, properties?: record, tax_codes?: list}
export def "subscriptions-fixed-charges overrideSubscriptionFixedCharge" [
  external_id: any
  fixed_charge_code: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscription-status: string@subscription-status-completer # Filter by subscription status. When provided, the subscription is looked up with this status instead of the default `active` status. Possible values are `pending`, `active`, `terminated`, or `canceled`.  (default: active, e.g. active)
  fixed_charge: record # Properties of a fixed charge that can be overridden at the subscription level. — shape: {invoice_display_name?: string, units?: string, apply_units_immediately?: bool, properties?: record, tax_codes?: list}
]: any -> record<fixed_charge: record<lago_id: string, lago_add_on_id: string, invoice_display_name: string, add_on_code: string, created_at: string, code: string, charge_model: string, pay_in_advance: bool, prorated: bool, properties: record<amount: string, graduated_ranges: list, volume_ranges: list>, units: float, lago_parent_id: string, taxes: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_status" $subscription_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($external_id)/fixed_charges/($fixed_charge_code)" $qp)
  let body = {fixed_charge: $fixed_charge} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a tax
#
# POST /taxes
# operationId: createTax
# --tax shape: {name?: string, code?: string, rate?: string, description?: string, applied_to_organization?: bool}
export def "taxes createTax" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  tax: record # shape: {name?: string, code?: string, rate?: string, description?: string, applied_to_organization?: bool}
]: any -> record<tax: record<lago_id: string, name: string, code: string, description: string, rate: float, applied_to_organization: bool, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/taxes")
  let body = {tax: $tax} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all taxes
#
# GET /taxes
# operationId: findAllTaxes
export def "taxes findAllTaxes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
]: nothing -> record<taxes: table<lago_id: string, name: string, code: string, description: string, rate: float, applied_to_organization: bool, created_at: string>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/taxes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a tax
#
# PUT /taxes/{code}
# operationId: updateTax
# --tax shape: {name?: string, code?: string, rate?: string, description?: string, applied_to_organization?: bool}
export def "taxes updateTax" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  tax: record # shape: {name?: string, code?: string, rate?: string, description?: string, applied_to_organization?: bool}
]: any -> record<tax: record<lago_id: string, name: string, code: string, description: string, rate: float, applied_to_organization: bool, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/taxes/($code)")
  let body = {tax: $tax} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Tax
#
# GET /taxes/{code}
# operationId: findTax
export def "taxes findTax" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tax: record<lago_id: string, name: string, code: string, description: string, rate: float, applied_to_organization: bool, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/taxes/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a tax
#
# DELETE /taxes/{code}
# operationId: destroyTax
export def "taxes destroyTax" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tax: record<lago_id: string, name: string, code: string, description: string, rate: float, applied_to_organization: bool, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/taxes/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a wallet
#
# POST /wallets
# operationId: createWallet
# --wallet shape: {name?: string, code?: string, priority?: int, rate_amount: string, currency: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", paid_credits?: string, granted_credits?: string, external_customer_id: string, expiration_at?: string, invoice_requires_successful_payment?: bool, transaction_metadata?: list, transaction_name?: string, applies_to?: record, paid_top_up_min_amount_cents?: int, paid_top_up_max_amount_cents?: int, ignore_paid_top_up_limits_on_creation?: bool, invoice_custom_section?: record, recurring_transaction_rules?: list, payment_method?: record, metadata?: record}
export def "wallets createWallet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wallet: record # shape: {name?: string, code?: string, priority?: int, rate_amount: string, currency: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"ISK"|"JMD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KRW"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"STD"|"SZL"|"THB"|"TJS"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW", paid_credits?: string, granted_credits?: string, external_customer_id: string, expiration_at?: string, invoice_requires_successful_payment?: bool, transaction_metadata?: list, transaction_name?: string, applies_to?: record, paid_top_up_min_amount_cents?: int, paid_top_up_max_amount_cents?: int, ignore_paid_top_up_limits_on_creation?: bool, invoice_custom_section?: record, recurring_transaction_rules?: list, payment_method?: record, metadata?: record}
]: any -> record<wallet: record<lago_id: string, lago_customer_id: string, external_customer_id: string, status: string, currency: string, name: string, code: string, priority: int, rate_amount: string, credits_balance: string, balance_cents: int, consumed_credits: string, created_at: string, expiration_at: string, last_balance_sync_at: string, last_consumed_credit_at: string, terminated_at: string, invoice_requires_successful_payment: bool, applies_to: record<fee_types: list, billable_metric_codes: list>, recurring_transaction_rules: list<record>, ongoing_balance_cents: int, ongoing_usage_balance_cents: int, credits_ongoing_balance: string, credits_ongoing_usage_balance: string, paid_top_up_min_amount_cents: int, paid_top_up_max_amount_cents: int, applied_invoice_custom_sections: list<record>, payment_method: record<payment_method_type: string, payment_method_id: string>, metadata: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wallets")
  let body = {wallet: $wallet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all wallets
#
# GET /wallets
# operationId: findAllWallets
export def "wallets findAllWallets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --external-customer-id: string # The customer external unique identifier (provided by your own application). (e.g. 5eb02857-a71e-4ea2-bcf9-57d3a41bc6ba)
]: nothing -> record<wallets: table<lago_id: string, lago_customer_id: string, external_customer_id: string, status: string, currency: string, name: string, code: string, priority: int, rate_amount: string, credits_balance: string, balance_cents: int, consumed_credits: string, created_at: string, expiration_at: string, last_balance_sync_at: string, last_consumed_credit_at: string, terminated_at: string, invoice_requires_successful_payment: bool, applies_to: record, recurring_transaction_rules: list, ongoing_balance_cents: int, ongoing_usage_balance_cents: int, credits_ongoing_balance: string, credits_ongoing_usage_balance: string, paid_top_up_min_amount_cents: int, paid_top_up_max_amount_cents: int, applied_invoice_custom_sections: list, payment_method: record, metadata: record>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "external_customer_id" $external_customer_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wallets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a wallet
#
# PUT /wallets/{lago_id}
# operationId: updateWallet
# --wallet shape: {name?: string, code?: string, priority?: int, expiration_at?: string, invoice_requires_successful_payment?: bool, invoice_custom_section?: record, recurring_transaction_rules?: list, payment_method?: record, applies_to?: record, metadata?: record}
export def "wallets updateWallet" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  wallet: record # shape: {name?: string, code?: string, priority?: int, expiration_at?: string, invoice_requires_successful_payment?: bool, invoice_custom_section?: record, recurring_transaction_rules?: list, payment_method?: record, applies_to?: record, metadata?: record}
]: any -> record<wallet: record<lago_id: string, lago_customer_id: string, external_customer_id: string, status: string, currency: string, name: string, code: string, priority: int, rate_amount: string, credits_balance: string, balance_cents: int, consumed_credits: string, created_at: string, expiration_at: string, last_balance_sync_at: string, last_consumed_credit_at: string, terminated_at: string, invoice_requires_successful_payment: bool, applies_to: record<fee_types: list, billable_metric_codes: list>, recurring_transaction_rules: list<record>, ongoing_balance_cents: int, ongoing_usage_balance_cents: int, credits_ongoing_balance: string, credits_ongoing_usage_balance: string, paid_top_up_min_amount_cents: int, paid_top_up_max_amount_cents: int, applied_invoice_custom_sections: list<record>, payment_method: record<payment_method_type: string, payment_method_id: string>, metadata: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wallets/($lago_id)")
  let body = {wallet: $wallet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a wallet
#
# GET /wallets/{lago_id}
# operationId: findWallet
export def "wallets findWallet" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<wallet: record<lago_id: string, lago_customer_id: string, external_customer_id: string, status: string, currency: string, name: string, code: string, priority: int, rate_amount: string, credits_balance: string, balance_cents: int, consumed_credits: string, created_at: string, expiration_at: string, last_balance_sync_at: string, last_consumed_credit_at: string, terminated_at: string, invoice_requires_successful_payment: bool, applies_to: record<fee_types: list, billable_metric_codes: list>, recurring_transaction_rules: list<record>, ongoing_balance_cents: int, ongoing_usage_balance_cents: int, credits_ongoing_balance: string, credits_ongoing_usage_balance: string, paid_top_up_min_amount_cents: int, paid_top_up_max_amount_cents: int, applied_invoice_custom_sections: list<record>, payment_method: record<payment_method_type: string, payment_method_id: string>, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wallets/($lago_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Terminate a wallet
#
# DELETE /wallets/{lago_id}
# operationId: destroyWallet
export def "wallets destroyWallet" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<wallet: record<lago_id: string, lago_customer_id: string, external_customer_id: string, status: string, currency: string, name: string, code: string, priority: int, rate_amount: string, credits_balance: string, balance_cents: int, consumed_credits: string, created_at: string, expiration_at: string, last_balance_sync_at: string, last_consumed_credit_at: string, terminated_at: string, invoice_requires_successful_payment: bool, applies_to: record<fee_types: list, billable_metric_codes: list>, recurring_transaction_rules: list<record>, ongoing_balance_cents: int, ongoing_usage_balance_cents: int, credits_ongoing_balance: string, credits_ongoing_usage_balance: string, paid_top_up_min_amount_cents: int, paid_top_up_max_amount_cents: int, applied_invoice_custom_sections: list<record>, payment_method: record<payment_method_type: string, payment_method_id: string>, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wallets/($lago_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace wallet metadata
#
# POST /wallets/{lago_id}/metadata
# operationId: replaceWalletMetadata
export def "wallets-metadata replaceWalletMetadata" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: record # Custom metadata stored as key-value pairs. Keys are strings (max 100 characters), values can be strings (max 255 characters) or null. (nullable, e.g. {external_id: ext-123, synced_at: 2024-01-15, source: })
]: any -> record<metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wallets/($lago_id)/metadata")
  let body = {metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Merge wallet metadata
#
# PATCH /wallets/{lago_id}/metadata
# operationId: mergeWalletMetadata
export def "wallets-metadata mergeWalletMetadata" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: record # Custom metadata stored as key-value pairs. Keys are strings (max 100 characters), values can be strings (max 255 characters) or null. (nullable, e.g. {external_id: ext-123, synced_at: 2024-01-15, source: })
]: any -> record<metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wallets/($lago_id)/metadata")
  let body = {metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete all wallet metadata
#
# DELETE /wallets/{lago_id}/metadata
# operationId: deleteAllWalletMetadata
export def "wallets-metadata delete-by-lago_id" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wallets/($lago_id)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a metadata key
#
# DELETE /wallets/{lago_id}/metadata/{key}
# operationId: deleteWalletMetadataKey
export def "wallets-metadata delete-by-lago_id-key" [
  lago_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wallets/($lago_id)/metadata/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Top up a wallet
#
# POST /wallet_transactions
# operationId: createWalletTransaction
# --wallet_transaction shape: {wallet_id: string, name?: string, paid_credits?: string, granted_credits?: string, voided_credits?: string, invoice_requires_successful_payment?: bool, ignore_paid_top_up_limits?: bool, invoice_custom_section?: record, payment_method?: record, metadata?: list}
export def "wallet-transactions createWalletTransaction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  wallet_transaction: record # shape: {wallet_id: string, name?: string, paid_credits?: string, granted_credits?: string, voided_credits?: string, invoice_requires_successful_payment?: bool, ignore_paid_top_up_limits?: bool, invoice_custom_section?: record, payment_method?: record, metadata?: list}
]: any -> record<wallet_transactions: table<lago_id: string, lago_wallet_id: string, lago_invoice_id: string, lago_credit_note_id: string, lago_voided_invoice_id: string, status: string, source: string, transaction_status: string, transaction_type: string, amount: string, credit_amount: string, invoice_requires_successful_payment: bool, metadata: list, remaining_amount_cents: int, remaining_credit_amount: string, priority: int, settled_at: string, failed_at: string, created_at: string, name: string, applied_invoice_custom_sections: list, payment_method: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wallet_transactions")
  let body = {wallet_transaction: $wallet_transaction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a wallet transaction
#
# GET /wallet_transactions/{lago_id}
# operationId: findWalletTransaction
export def "wallet-transactions findWalletTransaction" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<lago_id: string, lago_wallet_id: string, lago_invoice_id: string, lago_credit_note_id: string, lago_voided_invoice_id: string, status: string, source: string, transaction_status: string, transaction_type: string, amount: string, credit_amount: string, invoice_requires_successful_payment: bool, metadata: table<key: string, value: string>, remaining_amount_cents: int, remaining_credit_amount: string, priority: int, settled_at: string, failed_at: string, created_at: string, name: string, applied_invoice_custom_sections: table<lago_id: string, created_at: string, invoice_custom_section_id: string, invoice_custom_section: record>, payment_method: record<payment_method_type: string, payment_method_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wallet_transactions/($lago_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate a payment URL
#
# POST /wallet_transactions/{lago_id}/payment_url
# operationId: walletTransactionPaymentUrl
export def "wallet-transactions-payment-url walletTransactionPaymentUrl" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<wallet_transaction_payment_details: record<lago_customer_id: string, lago_wallet_transaction_id: string, external_customer_id: string, payment_provider: string, payment_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wallet_transactions/($lago_id)/payment_url")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all consumptions for a wallet transaction
#
# GET /wallet_transactions/{lago_id}/consumptions
# operationId: findAllWalletTransactionConsumptions
export def "wallet-transactions-consumptions findAllWalletTransactionConsumptions" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
]: nothing -> record<wallet_transaction_consumptions: table<lago_id: string, amount_cents: int, credit_amount: string, created_at: string, wallet_transaction: record>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wallet_transactions/($lago_id)/consumptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all fundings for a wallet transaction
#
# GET /wallet_transactions/{lago_id}/fundings
# operationId: findAllWalletTransactionFundings
export def "wallet-transactions-fundings findAllWalletTransactionFundings" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
]: nothing -> record<wallet_transaction_fundings: table<lago_id: string, amount_cents: int, credit_amount: string, created_at: string, wallet_transaction: record>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wallet_transactions/($lago_id)/fundings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all wallet transactions
#
# GET /wallets/{lago_id}/wallet_transactions
# operationId: findAllWalletTransactions
export def "wallets-wallet-transactions findAllWalletTransactions" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
  --status: string # The status of the wallet transaction. Possible values are `pending` or `settled`. (e.g. pending)
  --transaction-status: string # The transaction status of the wallet transaction. Possible values are `purchased` (with pending or settled status), `granted` (without invoice_id), `voided` or `invoiced`. (e.g. purchased)
  --transaction-type: string # The transaction type of the wallet transaction. Possible values are `inbound` (increasing the wallet balance) or `outbound` (decreasing the wallet balance). (e.g. inbound)
]: nothing -> record<wallet_transactions: table<lago_id: string, lago_wallet_id: string, lago_invoice_id: string, lago_credit_note_id: string, lago_voided_invoice_id: string, status: string, source: string, transaction_status: string, transaction_type: string, amount: string, credit_amount: string, invoice_requires_successful_payment: bool, metadata: list, remaining_amount_cents: int, remaining_credit_amount: string, priority: int, settled_at: string, failed_at: string, created_at: string, name: string, applied_invoice_custom_sections: list, payment_method: record>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "transaction_status" $transaction_status "scalar") (serialize-qp "transaction_type" $transaction_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wallets/($lago_id)/wallet_transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve webhook public key
#
# GET /webhooks/public_key
# operationId: fetchPublicKey
export def "webhooks-public-key fetchPublicKey" [
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
  let full_url = (build-url $base "/webhooks/public_key")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a webhook_endpoint
#
# POST /webhook_endpoints
# operationId: createWebhookEndpoint
# --webhook_endpoint shape: {webhook_url: string, signature_algo?: "jwt"|"hmac"}
export def "webhook-endpoints createWebhookEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --webhook-endpoint: record # shape: {webhook_url: string, signature_algo?: "jwt"|"hmac"}
]: any -> record<webhook_endpoint: record<lago_id: string, lago_organization_id: string, webhook_url: string, signature_algo: string, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhook_endpoints")
  let body = {webhook_endpoint: $webhook_endpoint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all webhook endpoints
#
# GET /webhook_endpoints
# operationId: findAllWebhookEndpoints
export def "webhook-endpoints findAllWebhookEndpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (e.g. 1)
  --per-page: int # Number of records per page. (e.g. 20)
]: nothing -> record<webhook_endpoints: table<lago_id: string, lago_organization_id: string, webhook_url: string, signature_algo: string, created_at: string>, meta: record<current_page: int, next_page: int, prev_page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhook_endpoints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a webhook endpoint
#
# PUT /webhook_endpoints/{lago_id}
# operationId: updateWebhookEndpoint
# --webhook_endpoint shape: {webhook_url: string, signature_algo?: "jwt"|"hmac"}
export def "webhook-endpoints updateWebhookEndpoint" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --webhook-endpoint: record # shape: {webhook_url: string, signature_algo?: "jwt"|"hmac"}
]: any -> record<webhook_endpoint: record<lago_id: string, lago_organization_id: string, webhook_url: string, signature_algo: string, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhook_endpoints/($lago_id)")
  let body = {webhook_endpoint: $webhook_endpoint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a webhook endpoint
#
# GET /webhook_endpoints/{lago_id}
# operationId: findWebhookEndpoint
export def "webhook-endpoints findWebhookEndpoint" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<webhook_endpoint: record<lago_id: string, lago_organization_id: string, webhook_url: string, signature_algo: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhook_endpoints/($lago_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a webhook endpoint
#
# DELETE /webhook_endpoints/{lago_id}
# operationId: destroyWebhookEndpoint
export def "webhook-endpoints destroyWebhookEndpoint" [
  lago_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<webhook_endpoint: record<lago_id: string, lago_organization_id: string, webhook_url: string, signature_algo: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhook_endpoints/($lago_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
