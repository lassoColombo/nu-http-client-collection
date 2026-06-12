# Auto-generated client for Logfire v0.1.0
# Source: https://logfire-api.pydantic.dev/openapi.json
# Auth: --token flag or $env.LOGFIRE_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LOGFIRE_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def schema-type-completer [] { ["input" "metadata" "output"] }
def plan-completer [] { ["growth" "team"] }
def cancellation-feedback-completer [] { ["low_quality" "missing_features" "too_complex" "too_expensive" "unused"] }
def oidc-provider-type-completer [] { ["azure" "keycloak" "okta"] }
def project-access-policy-completer [] { ["all" "public"] }
def scope-completer [] { ["organization" "project"] }
def timezone-completer [] { ["Africa/Abidjan" "Africa/Accra" "Africa/Addis_Ababa" "Africa/Algiers" "Africa/Asmara" "Africa/Asmera" "Africa/Bamako" "Africa/Bangui" "Africa/Banjul" "Africa/Bissau" "Africa/Blantyre" "Africa/Brazzaville" "Africa/Bujumbura" "Africa/Cairo" "Africa/Casablanca" "Africa/Ceuta" "Africa/Conakry" "Africa/Dakar" "Africa/Dar_es_Salaam" "Africa/Djibouti" "Africa/Douala" "Africa/El_Aaiun" "Africa/Freetown" "Africa/Gaborone" "Africa/Harare" "Africa/Johannesburg" "Africa/Juba" "Africa/Kampala" "Africa/Khartoum" "Africa/Kigali" "Africa/Kinshasa" "Africa/Lagos" "Africa/Libreville" "Africa/Lome" "Africa/Luanda" "Africa/Lubumbashi" "Africa/Lusaka" "Africa/Malabo" "Africa/Maputo" "Africa/Maseru" "Africa/Mbabane" "Africa/Mogadishu" "Africa/Monrovia" "Africa/Nairobi" "Africa/Ndjamena" "Africa/Niamey" "Africa/Nouakchott" "Africa/Ouagadougou" "Africa/Porto-Novo" "Africa/Sao_Tome" "Africa/Timbuktu" "Africa/Tripoli" "Africa/Tunis" "Africa/Windhoek" "America/Adak" "America/Anchorage" "America/Anguilla" "America/Antigua" "America/Araguaina" "America/Argentina/Buenos_Aires" "America/Argentina/Catamarca" "America/Argentina/ComodRivadavia" "America/Argentina/Cordoba" "America/Argentina/Jujuy" "America/Argentina/La_Rioja" "America/Argentina/Mendoza" "America/Argentina/Rio_Gallegos" "America/Argentina/Salta" "America/Argentina/San_Juan" "America/Argentina/San_Luis" "America/Argentina/Tucuman" "America/Argentina/Ushuaia" "America/Aruba" "America/Asuncion" "America/Atikokan" "America/Atka" "America/Bahia" "America/Bahia_Banderas" "America/Barbados" "America/Belem" "America/Belize" "America/Blanc-Sablon" "America/Boa_Vista" "America/Bogota" "America/Boise" "America/Buenos_Aires" "America/Cambridge_Bay" "America/Campo_Grande" "America/Cancun" "America/Caracas" "America/Catamarca" "America/Cayenne" "America/Cayman" "America/Chicago" "America/Chihuahua" "America/Ciudad_Juarez" "America/Coral_Harbour" "America/Cordoba" "America/Costa_Rica" "America/Coyhaique" "America/Creston" "America/Cuiaba" "America/Curacao" "America/Danmarkshavn" "America/Dawson" "America/Dawson_Creek" "America/Denver" "America/Detroit" "America/Dominica" "America/Edmonton" "America/Eirunepe" "America/El_Salvador" "America/Ensenada" "America/Fort_Nelson" "America/Fort_Wayne" "America/Fortaleza" "America/Glace_Bay" "America/Godthab" "America/Goose_Bay" "America/Grand_Turk" "America/Grenada" "America/Guadeloupe" "America/Guatemala" "America/Guayaquil" "America/Guyana" "America/Halifax" "America/Havana" "America/Hermosillo" "America/Indiana/Indianapolis" "America/Indiana/Knox" "America/Indiana/Marengo" "America/Indiana/Petersburg" "America/Indiana/Tell_City" "America/Indiana/Vevay" "America/Indiana/Vincennes" "America/Indiana/Winamac" "America/Indianapolis" "America/Inuvik" "America/Iqaluit" "America/Jamaica" "America/Jujuy" "America/Juneau" "America/Kentucky/Louisville" "America/Kentucky/Monticello" "America/Knox_IN" "America/Kralendijk" "America/La_Paz" "America/Lima" "America/Los_Angeles" "America/Louisville" "America/Lower_Princes" "America/Maceio" "America/Managua" "America/Manaus" "America/Marigot" "America/Martinique" "America/Matamoros" "America/Mazatlan" "America/Mendoza" "America/Menominee" "America/Merida" "America/Metlakatla" "America/Mexico_City" "America/Miquelon" "America/Moncton" "America/Monterrey" "America/Montevideo" "America/Montreal" "America/Montserrat" "America/Nassau" "America/New_York" "America/Nipigon" "America/Nome" "America/Noronha" "America/North_Dakota/Beulah" "America/North_Dakota/Center" "America/North_Dakota/New_Salem" "America/Nuuk" "America/Ojinaga" "America/Panama" "America/Pangnirtung" "America/Paramaribo" "America/Phoenix" "America/Port-au-Prince" "America/Port_of_Spain" "America/Porto_Acre" "America/Porto_Velho" "America/Puerto_Rico" "America/Punta_Arenas" "America/Rainy_River" "America/Rankin_Inlet" "America/Recife" "America/Regina" "America/Resolute" "America/Rio_Branco" "America/Rosario" "America/Santa_Isabel" "America/Santarem" "America/Santiago" "America/Santo_Domingo" "America/Sao_Paulo" "America/Scoresbysund" "America/Shiprock" "America/Sitka" "America/St_Barthelemy" "America/St_Johns" "America/St_Kitts" "America/St_Lucia" "America/St_Thomas" "America/St_Vincent" "America/Swift_Current" "America/Tegucigalpa" "America/Thule" "America/Thunder_Bay" "America/Tijuana" "America/Toronto" "America/Tortola" "America/Vancouver" "America/Virgin" "America/Whitehorse" "America/Winnipeg" "America/Yakutat" "America/Yellowknife" "Antarctica/Casey" "Antarctica/Davis" "Antarctica/DumontDUrville" "Antarctica/Macquarie" "Antarctica/Mawson" "Antarctica/McMurdo" "Antarctica/Palmer" "Antarctica/Rothera" "Antarctica/South_Pole" "Antarctica/Syowa" "Antarctica/Troll" "Antarctica/Vostok" "Arctic/Longyearbyen" "Asia/Aden" "Asia/Almaty" "Asia/Amman" "Asia/Anadyr" "Asia/Aqtau" "Asia/Aqtobe" "Asia/Ashgabat" "Asia/Ashkhabad" "Asia/Atyrau" "Asia/Baghdad" "Asia/Bahrain" "Asia/Baku" "Asia/Bangkok" "Asia/Barnaul" "Asia/Beirut" "Asia/Bishkek" "Asia/Brunei" "Asia/Calcutta" "Asia/Chita" "Asia/Choibalsan" "Asia/Chongqing" "Asia/Chungking" "Asia/Colombo" "Asia/Dacca" "Asia/Damascus" "Asia/Dhaka" "Asia/Dili" "Asia/Dubai" "Asia/Dushanbe" "Asia/Famagusta" "Asia/Gaza" "Asia/Harbin" "Asia/Hebron" "Asia/Ho_Chi_Minh" "Asia/Hong_Kong" "Asia/Hovd" "Asia/Irkutsk" "Asia/Istanbul" "Asia/Jakarta" "Asia/Jayapura" "Asia/Jerusalem" "Asia/Kabul" "Asia/Kamchatka" "Asia/Karachi" "Asia/Kashgar" "Asia/Kathmandu" "Asia/Katmandu" "Asia/Khandyga" "Asia/Kolkata" "Asia/Krasnoyarsk" "Asia/Kuala_Lumpur" "Asia/Kuching" "Asia/Kuwait" "Asia/Macao" "Asia/Macau" "Asia/Magadan" "Asia/Makassar" "Asia/Manila" "Asia/Muscat" "Asia/Nicosia" "Asia/Novokuznetsk" "Asia/Novosibirsk" "Asia/Omsk" "Asia/Oral" "Asia/Phnom_Penh" "Asia/Pontianak" "Asia/Pyongyang" "Asia/Qatar" "Asia/Qostanay" "Asia/Qyzylorda" "Asia/Rangoon" "Asia/Riyadh" "Asia/Saigon" "Asia/Sakhalin" "Asia/Samarkand" "Asia/Seoul" "Asia/Shanghai" "Asia/Singapore" "Asia/Srednekolymsk" "Asia/Taipei" "Asia/Tashkent" "Asia/Tbilisi" "Asia/Tehran" "Asia/Tel_Aviv" "Asia/Thimbu" "Asia/Thimphu" "Asia/Tokyo" "Asia/Tomsk" "Asia/Ujung_Pandang" "Asia/Ulaanbaatar" "Asia/Ulan_Bator" "Asia/Urumqi" "Asia/Ust-Nera" "Asia/Vientiane" "Asia/Vladivostok" "Asia/Yakutsk" "Asia/Yangon" "Asia/Yekaterinburg" "Asia/Yerevan" "Atlantic/Azores" "Atlantic/Bermuda" "Atlantic/Canary" "Atlantic/Cape_Verde" "Atlantic/Faeroe" "Atlantic/Faroe" "Atlantic/Jan_Mayen" "Atlantic/Madeira" "Atlantic/Reykjavik" "Atlantic/South_Georgia" "Atlantic/St_Helena" "Atlantic/Stanley" "Australia/ACT" "Australia/Adelaide" "Australia/Brisbane" "Australia/Broken_Hill" "Australia/Canberra" "Australia/Currie" "Australia/Darwin" "Australia/Eucla" "Australia/Hobart" "Australia/LHI" "Australia/Lindeman" "Australia/Lord_Howe" "Australia/Melbourne" "Australia/NSW" "Australia/North" "Australia/Perth" "Australia/Queensland" "Australia/South" "Australia/Sydney" "Australia/Tasmania" "Australia/Victoria" "Australia/West" "Australia/Yancowinna" "Brazil/Acre" "Brazil/DeNoronha" "Brazil/East" "Brazil/West" "CET" "CST6CDT" "Canada/Atlantic" "Canada/Central" "Canada/Eastern" "Canada/Mountain" "Canada/Newfoundland" "Canada/Pacific" "Canada/Saskatchewan" "Canada/Yukon" "Chile/Continental" "Chile/EasterIsland" "Cuba" "EET" "EST" "EST5EDT" "Egypt" "Eire" "Etc/GMT" "Etc/GMT+0" "Etc/GMT+1" "Etc/GMT+10" "Etc/GMT+11" "Etc/GMT+12" "Etc/GMT+2" "Etc/GMT+3" "Etc/GMT+4" "Etc/GMT+5" "Etc/GMT+6" "Etc/GMT+7" "Etc/GMT+8" "Etc/GMT+9" "Etc/GMT-0" "Etc/GMT-1" "Etc/GMT-10" "Etc/GMT-11" "Etc/GMT-12" "Etc/GMT-13" "Etc/GMT-14" "Etc/GMT-2" "Etc/GMT-3" "Etc/GMT-4" "Etc/GMT-5" "Etc/GMT-6" "Etc/GMT-7" "Etc/GMT-8" "Etc/GMT-9" "Etc/GMT0" "Etc/Greenwich" "Etc/UCT" "Etc/UTC" "Etc/Universal" "Etc/Zulu" "Europe/Amsterdam" "Europe/Andorra" "Europe/Astrakhan" "Europe/Athens" "Europe/Belfast" "Europe/Belgrade" "Europe/Berlin" "Europe/Bratislava" "Europe/Brussels" "Europe/Bucharest" "Europe/Budapest" "Europe/Busingen" "Europe/Chisinau" "Europe/Copenhagen" "Europe/Dublin" "Europe/Gibraltar" "Europe/Guernsey" "Europe/Helsinki" "Europe/Isle_of_Man" "Europe/Istanbul" "Europe/Jersey" "Europe/Kaliningrad" "Europe/Kiev" "Europe/Kirov" "Europe/Kyiv" "Europe/Lisbon" "Europe/Ljubljana" "Europe/London" "Europe/Luxembourg" "Europe/Madrid" "Europe/Malta" "Europe/Mariehamn" "Europe/Minsk" "Europe/Monaco" "Europe/Moscow" "Europe/Nicosia" "Europe/Oslo" "Europe/Paris" "Europe/Podgorica" "Europe/Prague" "Europe/Riga" "Europe/Rome" "Europe/Samara" "Europe/San_Marino" "Europe/Sarajevo" "Europe/Saratov" "Europe/Simferopol" "Europe/Skopje" "Europe/Sofia" "Europe/Stockholm" "Europe/Tallinn" "Europe/Tirane" "Europe/Tiraspol" "Europe/Ulyanovsk" "Europe/Uzhgorod" "Europe/Vaduz" "Europe/Vatican" "Europe/Vienna" "Europe/Vilnius" "Europe/Volgograd" "Europe/Warsaw" "Europe/Zagreb" "Europe/Zaporozhye" "Europe/Zurich" "Factory" "GB" "GB-Eire" "GMT" "GMT+0" "GMT-0" "GMT0" "Greenwich" "HST" "Hongkong" "Iceland" "Indian/Antananarivo" "Indian/Chagos" "Indian/Christmas" "Indian/Cocos" "Indian/Comoro" "Indian/Kerguelen" "Indian/Mahe" "Indian/Maldives" "Indian/Mauritius" "Indian/Mayotte" "Indian/Reunion" "Iran" "Israel" "Jamaica" "Japan" "Kwajalein" "Libya" "MET" "MST" "MST7MDT" "Mexico/BajaNorte" "Mexico/BajaSur" "Mexico/General" "NZ" "NZ-CHAT" "Navajo" "PRC" "PST8PDT" "Pacific/Apia" "Pacific/Auckland" "Pacific/Bougainville" "Pacific/Chatham" "Pacific/Chuuk" "Pacific/Easter" "Pacific/Efate" "Pacific/Enderbury" "Pacific/Fakaofo" "Pacific/Fiji" "Pacific/Funafuti" "Pacific/Galapagos" "Pacific/Gambier" "Pacific/Guadalcanal" "Pacific/Guam" "Pacific/Honolulu" "Pacific/Johnston" "Pacific/Kanton" "Pacific/Kiritimati" "Pacific/Kosrae" "Pacific/Kwajalein" "Pacific/Majuro" "Pacific/Marquesas" "Pacific/Midway" "Pacific/Nauru" "Pacific/Niue" "Pacific/Norfolk" "Pacific/Noumea" "Pacific/Pago_Pago" "Pacific/Palau" "Pacific/Pitcairn" "Pacific/Pohnpei" "Pacific/Ponape" "Pacific/Port_Moresby" "Pacific/Rarotonga" "Pacific/Saipan" "Pacific/Samoa" "Pacific/Tahiti" "Pacific/Tarawa" "Pacific/Tongatapu" "Pacific/Truk" "Pacific/Wake" "Pacific/Wallis" "Pacific/Yap" "Poland" "Portugal" "ROC" "ROK" "Singapore" "Turkey" "UCT" "US/Alaska" "US/Aleutian" "US/Arizona" "US/Central" "US/East-Indiana" "US/Eastern" "US/Hawaii" "US/Indiana-Starke" "US/Michigan" "US/Mountain" "US/Pacific" "US/Samoa" "UTC" "Universal" "W-SU" "WET" "Zulu" "localtime"] }
def client-type-completer [] { ["confidential" "public"] }
def on-error-completer [] { ["allow" "block"] }
def action-completer [] { ["block" "flag" "observe" "redact"] }
def window-completer [] { ["1h" "24h" "5m" "7d"] }
def notify-when-completer [] { ["has_matches" "has_matches_changed" "matches_changed" "starts_having_matches"] }
def variant-completer [] { ["alert" "alert:has_errors" "alert:is_empty" "filter_alert" "filter_alert:issue"] }
def type-completer [] { ["opsgenie" "webhook"] }
def format-completer [] { ["auto" "raw-data" "slack-blockkit" "slack-legacy"] }
def order-completer [] { ["ASC" "DESC"] }
def order-by-completer [] { ["created_at" "start_timestamp"] }
def format-completer-1 [] { ["json" "pydantic-evals"] }
def action-completer-1 [] { ["archive" "unarchive"] }
def sort-order-completer [] { ["asc" "desc"] }
def state-completer [] { ["ignored" "open" "resolved"] }
def sort-by-completer [] { ["first_exception_type" "first_span_message" "matches_count" "max_start_timestamp" "min_start_timestamp"] }
def api-format-completer [] { ["anthropic" "gemini" "openai-chat" "openai-responses"] }
def visibility-completer [] { ["private" "public"] }
def sort-by-completer-1 [] { ["created_at" "description" "expires_at"] }
def expires-in-completer [] { ["3" "30" "7"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "ui-api-account-me get" } } | get name | first)
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

# Account Get
#
# GET /ui-api/account/me/
# operationId: account_get
export def "ui-api-account-me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, email: string, default_organization: record<id: string, organization_name: string>, personal_organization: record<id: string, organization_name: string>, country: any, city: any, company_name: any, company_role: any, created_at: string, identity_providers: record<google: record<provider_id: any, provider_username: any>, github: record<provider_id: any, provider_username: any>, local: record<provider_id: any, provider_username: any>, custom_providers: record>, session_duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/account/me/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Account Update
#
# PUT /ui-api/account/me/
# operationId: account_update
export def "ui-api-account-me update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-organization-id: string # format: uuid
  --country: string
  --city: string
  --company-name: string
  --company-role: string
  --session-duration: string # format: duration
]: any -> record<id: string, name: string, email: string, default_organization: record<id: string, organization_name: string>, personal_organization: record<id: string, organization_name: string>, country: any, city: any, company_name: any, company_role: any, created_at: string, identity_providers: record<google: record<provider_id: any, provider_username: any>, github: record<provider_id: any, provider_username: any>, local: record<provider_id: any, provider_username: any>, custom_providers: record>, session_duration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/account/me/")
  let body = {default_organization_id: $default_organization_id, country: $country, city: $city, company_name: $company_name, company_role: $company_role, session_duration: $session_duration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Account Delete
#
# DELETE /ui-api/account/me/
# operationId: account_delete
export def "ui-api-account-me delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/account/me/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Logout
#
# POST /ui-api/account/logout/
# operationId: logout
export def "ui-api-account-logout logout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/account/logout/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initiate Email Address Update
#
# POST /ui-api/account/email/initiate-update/
# operationId: initiate_email_address_update
export def "ui-api-account-email-initiate-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  new_email: string # format: email
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/account/email/initiate-update/")
  let body = {new_email: $new_email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update User Email Address
#
# PATCH /ui-api/account/email/
# operationId: update_user_email_address
export def "ui-api-account-email address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string
  --password: any
  --totp-code: any
  --recovery-code: any
]: any -> record<id: string, name: string, email: string, default_organization: record<id: string, organization_name: string>, personal_organization: record<id: string, organization_name: string>, country: any, city: any, company_name: any, company_role: any, created_at: string, identity_providers: record<google: record<provider_id: any, provider_username: any>, github: record<provider_id: any, provider_username: any>, local: record<provider_id: any, provider_username: any>, custom_providers: record>, session_duration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/account/email/")
  let body = {token: $body_token, password: $password, totp_code: $totp_code, recovery_code: $recovery_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Account Requirements
#
# GET /ui-api/account/delete-requirements/
# operationId: delete_account_requirements
export def "ui-api-account-delete-requirements requirements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/account/delete-requirements/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Verify Session Age
#
# GET /ui-api/account/session/verify/
# operationId: verify_session_age
export def "ui-api-account-session-verify age" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<is_recent: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/account/session/verify/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update User Password
#
# PUT /ui-api/account/password/
# operationId: update_user_password
export def "ui-api-account-password password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --current-password: string # format: password
  --new-password: string # format: password
  --totp-code: string
  --recovery-code: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/account/password/")
  let body = {current_password: $current_password, new_password: $new_password, totp_code: $totp_code, recovery_code: $recovery_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Leave Organization
#
# POST /ui-api/account/{organization}/leave/
# operationId: leave_organization
export def "ui-api-account-leave organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/account/($organization)/leave/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initiate Authenticated Totp Reset
#
# POST /ui-api/account/totp/reset/initiate/
# operationId: initiate_authenticated_totp_reset
export def "ui-api-account-totp-reset-initiate reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  recovery_code: string
]: any -> record<session_token: string, totp_secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/account/totp/reset/initiate/")
  let body = {recovery_code: $recovery_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Complete Authenticated Totp Reset
#
# POST /ui-api/account/totp/reset/complete/
# operationId: complete_authenticated_totp_reset
export def "ui-api-account-totp-reset-complete reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  session_token: string
  totp_code: string
]: any -> record<recovery_codes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/account/totp/reset/complete/")
  let body = {session_token: $session_token, totp_code: $totp_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Device Tokens
#
# GET /ui-api/account/security/tokens/
# operationId: list_device_tokens
export def "ui-api-account-security-tokens tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, created_at: any, expiration: string, sdk_machine_name: any, user_agent: any, ip_location: any, is_current: bool, sso: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/account/security/tokens/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke Device Token
#
# DELETE /ui-api/account/security/tokens/{token_id}/
# operationId: revoke_device_token
export def "ui-api-account-security-tokens token" [
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/account/security/tokens/($token_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Issue Authorize Idp State
#
# POST /ui-api/account/security/tokens/{token_id}/authorize-idp-state/
# operationId: issue_authorize_idp_state
export def "ui-api-account-security-tokens-authorize-idp-state state" [
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  organization_id: string # format: uuid
]: any -> record<state: string, expires_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/account/security/tokens/($token_id)/authorize-idp-state/")
  let body = {organization_id: $organization_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Authorize Device Token Idp
#
# POST /ui-api/account/security/tokens/{token_id}/authorize-idp/
# operationId: authorize_device_token_idp
export def "ui-api-account-security-tokens-authorize-idp idp-by-token_id" [
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  organization_id: string # format: uuid
  code: string
  redirect_uri: string
  provider: string
  state: string
]: any -> record<status: string, organization_id: string, dex_provider_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/account/security/tokens/($token_id)/authorize-idp/")
  let body = {organization_id: $organization_id, code: $code, redirect_uri: $redirect_uri, provider: $provider, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke Device Token Idp
#
# DELETE /ui-api/account/security/tokens/{token_id}/authorize-idp/
# operationId: revoke_device_token_idp
export def "ui-api-account-security-tokens-authorize-idp idp-by-token_id-1" [
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # format: uuid
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organization_id" $organization_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/account/security/tokens/($token_id)/authorize-idp/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Oauth Client Sessions
#
# GET /ui-api/account/security/sessions/
# operationId: list_oauth_client_sessions
export def "ui-api-account-security-sessions sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: string, organization_name: string, client_id: string, client_name: string, project_id: any, project_name: any, family_id: string, created_at: string, last_used_at: any, expires_at: string, resource: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/account/security/sessions/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke Oauth Client Session
#
# DELETE /ui-api/account/security/sessions/{family_id}/
# operationId: revoke_oauth_client_session
export def "ui-api-account-security-sessions session" [
  family_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/account/security/sessions/($family_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upsert Onboarding Survey
#
# POST /ui-api/account/me/onboarding-survey
# operationId: upsert_onboarding_survey
export def "ui-api-account-me-onboarding-survey survey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  outcome: string
  --usage: any
  --usage-other: any
  --goals: list
  --agent-stage: any
  --skipped-at-step-id: any
]: any -> record<usage: any, usage_other: any, goals: any, agent_stage: any, outcome: string, skipped_at_step_id: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/account/me/onboarding-survey")
  let body = {outcome: $outcome, usage: $usage, usage_other: $usage_other, goals: $goals, agent_stage: $agent_stage, skipped_at_step_id: $skipped_at_step_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Query Generator
#
# GET /ui-api/ai/query_generator/{organization}/{project}/
# operationId: query_generator
export def "ui-api-ai-query-generator generator" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --prompt: string
]: nothing -> record<result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "prompt" $prompt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/ai/query_generator/($organization)/($project)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Query Fixer
#
# POST /ui-api/ai/query_fixer/{organization}/{project}/
# operationId: query_fixer
export def "ui-api-ai-query-fixer fixer" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  where_clause: string
  --body-error: string
]: any -> record<result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/ai/query_fixer/($organization)/($project)/")
  let body = {where_clause: $where_clause, error: $body_error} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Time Range Generator
#
# GET /ui-api/ai/time_range_generator/{organization}/{project}/
# operationId: time_range_generator
export def "ui-api-ai-time-range-generator generator" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --prompt: string
  --timezone: string
]: nothing -> record<result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "prompt" $prompt "scalar") (serialize-qp "timezone" $timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/ai/time_range_generator/($organization)/($project)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cron Schedule Generator
#
# GET /ui-api/ai/cron_schedule_generator/{organization}/{project}/
# operationId: cron_schedule_generator
export def "ui-api-ai-cron-schedule-generator generator" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --prompt: string
]: nothing -> record<result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "prompt" $prompt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/ai/cron_schedule_generator/($organization)/($project)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Tab Name Generator
#
# GET /ui-api/ai/tab_name_generator/{organization}/{project}/
# operationId: tab_name_generator
export def "ui-api-ai-tab-name-generator generator" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string
]: nothing -> record<result: record<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/ai/tab_name_generator/($organization)/($project)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run Summary
#
# POST /ui-api/ai/run_summary/{organization}/{project}/
# operationId: run_summary
export def "ui-api-ai-run-summary summary" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  conversation: string
]: any -> record<title: string, description: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/ai/run_summary/($organization)/($project)/")
  let body = {conversation: $conversation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Populate Dataset Case
#
# POST /ui-api/ai/populate_dataset_case/{organization}/{project}/
# operationId: populate_dataset_case
export def "ui-api-ai-populate-dataset-case case" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  dataset_id: string # format: uuid
  span_attributes: record
  --span-name: any
]: any -> record<result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/ai/populate_dataset_case/($organization)/($project)/")
  let body = {dataset_id: $dataset_id, span_attributes: $span_attributes, span_name: $span_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Dataset From Span
#
# POST /ui-api/ai/create_dataset_from_span/{organization}/{project}/
# operationId: create_dataset_from_span
export def "ui-api-ai-create-dataset-from-span span" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_description: string # Description of what the dataset should be used for
  span_attributes: record
  --span-name: any
]: any -> record<result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/ai/create_dataset_from_span/($organization)/($project)/")
  let body = {user_description: $user_description, span_attributes: $span_attributes, span_name: $span_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Dataset Guidance
#
# POST /ui-api/ai/update_dataset_guidance/{organization}/{project}/
# operationId: update_dataset_guidance
export def "ui-api-ai-update-dataset-guidance guidance" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  dataset_id: string # format: uuid
  case_inputs: record
  --case-expected-output: any
  --case-metadata: any
]: any -> record<result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/ai/update_dataset_guidance/($organization)/($project)/")
  let body = {dataset_id: $dataset_id, case_inputs: $case_inputs, case_expected_output: $case_expected_output, case_metadata: $case_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate Synthetic Cases
#
# POST /ui-api/ai/generate_synthetic_cases/{organization}/{project}/
# operationId: generate_synthetic_cases
export def "ui-api-ai-generate-synthetic-cases cases" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  dataset_id: string # format: uuid
  description: string # Description of what kind of cases to generate
  --count: int # Number of cases to generate (default: 5)
]: any -> record<result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/ai/generate_synthetic_cases/($organization)/($project)/")
  let body = {dataset_id: $dataset_id, description: $description, count: $count} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate Schema
#
# POST /ui-api/ai/generate_schema/{organization}/{project}/
# operationId: generate_schema
export def "ui-api-ai-generate-schema schema" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # Natural language description of the data shape
  schema_type: string@schema-type-completer # Which schema this is for (input, output, or metadata)
]: any -> record<result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/ai/generate_schema/($organization)/($project)/")
  let body = {description: $description, schema_type: $schema_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Explore Chat
#
# POST /ui-api/ai/explore_chat/{organization}/{project}/
# operationId: explore_chat
# --notebookContext item shape: {id: string, type: string, position: int, query?: any, content?: any}
export def "ui-api-ai-explore-chat chat" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --focusedCellId: any
  --notebookContext: list # default: [] — item shape: {id: string, type: string, position: int, query?: any, content?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/ai/explore_chat/($organization)/($project)/")
  let body = {focusedCellId: $focusedCellId, notebookContext: $notebookContext} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Metrics Query Generator
#
# GET /ui-api/ai/metrics_query_generator/{organization}/{project}/
# operationId: metrics_query_generator
export def "ui-api-ai-metrics-query-generator generator" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --prompt: string
]: nothing -> record<result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "prompt" $prompt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/ai/metrics_query_generator/($organization)/($project)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List User Announcements
#
# GET /ui-api/announcements/
# operationId: list_user_announcements
export def "ui-api-announcements announcements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, title: string, message: string, created_at: string, updated_at: string, expires_at: any, archive: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/announcements/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Seen Announcements
#
# POST /ui-api/announcements/seen/
# operationId: seen_announcements
export def "ui-api-announcements-seen announcements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  announcement_ids: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/announcements/seen/")
  let body = {announcement_ids: $announcement_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Public Banners
#
# GET /ui-api/instance-banners/public/
# operationId: list_public_banners
export def "ui-api-instance-banners-public banners" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, message: string, variant: string, content_version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/instance-banners/public/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Banners
#
# GET /ui-api/instance-banners/
# operationId: list_banners
export def "ui-api-instance-banners banners" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, message: string, variant: string, visible_when_logged_out: bool, starts_at: any, ends_at: any, content_version: int, created_by: any, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/instance-banners/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Dismissed Banners
#
# GET /ui-api/instance-banners/dismissed/
# operationId: list_dismissed_banners
export def "ui-api-instance-banners-dismissed banners" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<banner_id: string, content_version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/instance-banners/dismissed/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Dismiss Banner
#
# POST /ui-api/instance-banners/{banner_id}/dismiss/
# operationId: dismiss_banner
export def "ui-api-instance-banners-dismiss banner" [
  banner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/instance-banners/($banner_id)/dismiss/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Oauth Scopes
#
# GET /ui-api/organizations/{organization}/api-keys/scopes/
# operationId: list_oauth_scopes
export def "ui-api-organizations-api-keys-scopes scopes" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: any, description: string, hint: string, default: bool, project_scoped: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/api-keys/scopes/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Api Keys
#
# GET /ui-api/organizations/{organization}/api-keys/
# operationId: list_api_keys
export def "ui-api-organizations-api-keys keys" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: string, name: string, description: any, scopes: list<string>, project_id: any, project_name: any, all_projects: bool, created_by: any, created_by_name: any, created_at: string, last_used_at: any, expires_at: any, user_id: any, active: bool, updated_at: any, updated_by: any, claims: record<project_gateway_proxy: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/api-keys/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Api Key
#
# POST /ui-api/organizations/{organization}/api-keys/
# operationId: create_api_key
# --claims shape: {project:gateway_proxy?: record}
export def "ui-api-organizations-api-keys key-by-organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  description: any
  scopes: list
  --claims: record # shape: {project:gateway_proxy?: record}
  project_id: any
  --all-projects: oneof<nothing, bool>
  --expires-at: any
  --is-personal: oneof<nothing, bool>
]: any -> record<api_key: record<id: string, organization_id: string, name: string, description: any, scopes: list<string>, project_id: any, project_name: any, all_projects: bool, created_by: any, created_by_name: any, created_at: string, last_used_at: any, expires_at: any, user_id: any, active: bool, updated_at: any, updated_by: any, claims: record<project_gateway_proxy: record>>, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/api-keys/")
  let body = {name: $name, description: $description, scopes: $scopes, claims: $claims, project_id: $project_id, all_projects: $all_projects, expires_at: $expires_at, is_personal: $is_personal} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Api Key
#
# PATCH /ui-api/organizations/{organization}/api-keys/{api_key_id}/
# operationId: update_api_key
export def "ui-api-organizations-api-keys key-by-api_key_id-organization" [
  api_key_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --description: any
]: any -> record<id: string, organization_id: string, name: string, description: any, scopes: list<string>, project_id: any, project_name: any, all_projects: bool, created_by: any, created_by_name: any, created_at: string, last_used_at: any, expires_at: any, user_id: any, active: bool, updated_at: any, updated_by: any, claims: record<project_gateway_proxy: record<spending_limit_daily: any, spending_limit_weekly: any, spending_limit_monthly: any, spending_limit_total: any, cache_enabled: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/api-keys/($api_key_id)/")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Api Key
#
# DELETE /ui-api/organizations/{organization}/api-keys/{api_key_id}/
# operationId: delete_api_key
export def "ui-api-organizations-api-keys key-by-api_key_id-organization-1" [
  api_key_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/api-keys/($api_key_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke Api Key
#
# POST /ui-api/organizations/{organization}/api-keys/{api_key_id}/revoke/
# operationId: revoke_api_key
export def "ui-api-organizations-api-keys-revoke key" [
  api_key_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/api-keys/($api_key_id)/revoke/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reactivate Api Key
#
# POST /ui-api/organizations/{organization}/api-keys/{api_key_id}/reactivate/
# operationId: reactivate_api_key
export def "ui-api-organizations-api-keys-reactivate key" [
  api_key_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/api-keys/($api_key_id)/reactivate/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Admin List Gateway Promo Codes
#
# GET /ui-api/organizations/{organization}/gateway-admin/promo-codes/
# operationId: admin_list_gateway_promo_codes
export def "ui-api-organizations-gateway-admin-promo-codes codes" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, code: string, credit_amount_cents: int, active: bool, expires_at: any, max_redemptions: any, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway-admin/promo-codes/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Admin Create Gateway Promo Code
#
# POST /ui-api/organizations/{organization}/gateway-admin/promo-codes/
# operationId: admin_create_gateway_promo_code
export def "ui-api-organizations-gateway-admin-promo-codes code" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string
  credit_amount_cents: int
  --active: oneof<nothing, bool>
  --expires-at: any
  --max-redemptions: any
]: any -> record<id: string, code: string, credit_amount_cents: int, active: bool, expires_at: any, max_redemptions: any, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway-admin/promo-codes/")
  let body = {code: $code, credit_amount_cents: $credit_amount_cents, active: $active, expires_at: $expires_at, max_redemptions: $max_redemptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Admin List Built In Providers
#
# GET /ui-api/organizations/{organization}/gateway-admin/built-in-providers/
# operationId: admin_list_built_in_providers
export def "ui-api-organizations-gateway-admin-built-in-providers providers" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: any, description: any, provider_type: string, slug: string, base_url: string, inject_cost: bool, is_built_in: bool, block_on_error: bool, created_at: string, created_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway-admin/built-in-providers/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Admin Create Built In Provider
#
# POST /ui-api/organizations/{organization}/gateway-admin/built-in-providers/
# operationId: admin_create_built_in_provider
export def "ui-api-organizations-gateway-admin-built-in-providers provider-by-organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  provider_type: string
  slug: string
  --body-base-url: string
  credentials: string
  description: any
  --inject-cost: oneof<nothing, bool>
  --block-on-error: oneof<nothing, bool>
]: any -> record<id: string, organization_id: any, description: any, provider_type: string, slug: string, base_url: string, inject_cost: bool, is_built_in: bool, block_on_error: bool, created_at: string, created_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway-admin/built-in-providers/")
  let body = {provider_type: $provider_type, slug: $slug, base_url: $body_base_url, credentials: $credentials, description: $description, inject_cost: $inject_cost, block_on_error: $block_on_error} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Admin Get Built In Provider
#
# GET /ui-api/organizations/{organization}/gateway-admin/built-in-providers/{provider_id}/
# operationId: admin_get_built_in_provider
export def "ui-api-organizations-gateway-admin-built-in-providers provider-by-provider_id-organization" [
  provider_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, organization_id: any, description: any, provider_type: string, slug: string, base_url: string, inject_cost: bool, is_built_in: bool, block_on_error: bool, created_at: string, created_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway-admin/built-in-providers/($provider_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Admin Update Built In Provider
#
# PATCH /ui-api/organizations/{organization}/gateway-admin/built-in-providers/{provider_id}/
# operationId: admin_update_built_in_provider
export def "ui-api-organizations-gateway-admin-built-in-providers provider-by-provider_id-organization-1" [
  provider_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: any
  --body-base-url: any
  --credentials: any
  --inject-cost: any
  --block-on-error: any
]: any -> record<id: string, organization_id: any, description: any, provider_type: string, slug: string, base_url: string, inject_cost: bool, is_built_in: bool, block_on_error: bool, created_at: string, created_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway-admin/built-in-providers/($provider_id)/")
  let body = {description: $description, base_url: $body_base_url, credentials: $credentials, inject_cost: $inject_cost, block_on_error: $block_on_error} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Admin Delete Built In Provider
#
# DELETE /ui-api/organizations/{organization}/gateway-admin/built-in-providers/{provider_id}/
# operationId: admin_delete_built_in_provider
export def "ui-api-organizations-gateway-admin-built-in-providers provider-by-provider_id-organization-2" [
  provider_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway-admin/built-in-providers/($provider_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Admin List Built In Routing Groups
#
# GET /ui-api/organizations/{organization}/gateway-admin/built-in-routing-groups/
# operationId: admin_list_built_in_routing_groups
export def "ui-api-organizations-gateway-admin-built-in-routing-groups groups" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: any, slug: string, description: any, built_in: bool, created_at: string, created_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway-admin/built-in-routing-groups/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Admin Create Built In Routing Group
#
# POST /ui-api/organizations/{organization}/gateway-admin/built-in-routing-groups/
# operationId: admin_create_built_in_routing_group
export def "ui-api-organizations-gateway-admin-built-in-routing-groups group-by-organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  slug: string
  description: any
]: any -> record<id: string, organization_id: any, slug: string, description: any, built_in: bool, created_at: string, created_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway-admin/built-in-routing-groups/")
  let body = {slug: $slug, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Admin Get Built In Routing Group
#
# GET /ui-api/organizations/{organization}/gateway-admin/built-in-routing-groups/{routing_group_id}/
# operationId: admin_get_built_in_routing_group
export def "ui-api-organizations-gateway-admin-built-in-routing-groups group-by-routing_group_id-organization" [
  routing_group_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, organization_id: any, slug: string, description: any, built_in: bool, created_at: string, created_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway-admin/built-in-routing-groups/($routing_group_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Admin Update Built In Routing Group
#
# PATCH /ui-api/organizations/{organization}/gateway-admin/built-in-routing-groups/{routing_group_id}/
# operationId: admin_update_built_in_routing_group
export def "ui-api-organizations-gateway-admin-built-in-routing-groups group-by-routing_group_id-organization-1" [
  routing_group_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: any
]: any -> record<id: string, organization_id: any, slug: string, description: any, built_in: bool, created_at: string, created_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway-admin/built-in-routing-groups/($routing_group_id)/")
  let body = {description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Admin Delete Built In Routing Group
#
# DELETE /ui-api/organizations/{organization}/gateway-admin/built-in-routing-groups/{routing_group_id}/
# operationId: admin_delete_built_in_routing_group
export def "ui-api-organizations-gateway-admin-built-in-routing-groups group-by-routing_group_id-organization-2" [
  routing_group_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway-admin/built-in-routing-groups/($routing_group_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Admin List Built In Routing Group Members
#
# GET /ui-api/organizations/{organization}/gateway-admin/built-in-routing-groups/{routing_group_id}/members/
# operationId: admin_list_built_in_routing_group_members
export def "ui-api-organizations-gateway-admin-built-in-routing-groups-members members" [
  routing_group_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, provider_id: string, routing_group_id: string, priority: int, weight: float, active: bool, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway-admin/built-in-routing-groups/($routing_group_id)/members/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Admin Add Member To Built In Routing Group
#
# POST /ui-api/organizations/{organization}/gateway-admin/built-in-routing-groups/{routing_group_id}/members/
# operationId: admin_add_member_to_built_in_routing_group
export def "ui-api-organizations-gateway-admin-built-in-routing-groups-members group-by-routing_group_id-organization" [
  routing_group_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  provider_id: string # format: uuid
  priority: int
  weight: float
  --active: oneof<nothing, bool>
]: any -> record<id: string, provider_id: string, routing_group_id: string, priority: int, weight: float, active: bool, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway-admin/built-in-routing-groups/($routing_group_id)/members/")
  let body = {provider_id: $provider_id, priority: $priority, weight: $weight, active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Admin Update Built In Routing Group Member
#
# PATCH /ui-api/organizations/{organization}/gateway-admin/built-in-routing-groups/{routing_group_id}/members/{member_id}/
# operationId: admin_update_built_in_routing_group_member
export def "ui-api-organizations-gateway-admin-built-in-routing-groups-members member" [
  routing_group_id: string
  member_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --priority: any
  --weight: any
  --active: any
]: any -> record<id: string, provider_id: string, routing_group_id: string, priority: int, weight: float, active: bool, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway-admin/built-in-routing-groups/($routing_group_id)/members/($member_id)/")
  let body = {priority: $priority, weight: $weight, active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Admin Remove Member From Built In Routing Group
#
# DELETE /ui-api/organizations/{organization}/gateway-admin/built-in-routing-groups/{routing_group_id}/members/{member_id}/
# operationId: admin_remove_member_from_built_in_routing_group
export def "ui-api-organizations-gateway-admin-built-in-routing-groups-members group-by-routing_group_id-member_id-organization" [
  routing_group_id: string
  member_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway-admin/built-in-routing-groups/($routing_group_id)/members/($member_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Groups Get By Organization
#
# GET /ui-api/organizations/{organization}/groups/
# operationId: groups_get_by_organization
export def "ui-api-organizations-groups organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: string, name: string, description: any, role: string, user_count: int, project_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/groups/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Groups Create
#
# POST /ui-api/organizations/{organization}/groups/
# operationId: groups_create
export def "ui-api-organizations-groups create" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string
  role: string # format: uuid
  --members: list
  --projects: list
]: any -> record<id: string, organization_id: string, name: string, description: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/groups/")
  let body = {name: $name, description: $description, role: $role, members: $members, projects: $projects} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Groups Get By Id
#
# GET /ui-api/organizations/{organization}/groups/{group_id}/
# operationId: groups_get_by_id
export def "ui-api-organizations-groups id" [
  group_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, organization_id: string, name: string, description: any, role: string, members: table<id: string, name: string, email: string>, projects: table<id: string, group_id: string, organization_id: string, project_id: string, project_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/groups/($group_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Groups Update
#
# PUT /ui-api/organizations/{organization}/groups/{group_id}/
# operationId: groups_update
export def "ui-api-organizations-groups update" [
  group_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  description: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/groups/($group_id)/")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Groups Delete
#
# DELETE /ui-api/organizations/{organization}/groups/{group_id}/
# operationId: groups_delete
export def "ui-api-organizations-groups delete" [
  group_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/groups/($group_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Organizations Check Name
#
# POST /ui-api/organizations/check-name/
# operationId: organizations_check_name
export def "ui-api-organizations-check-name name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  organization_name: string
]: any -> record<available: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/organizations/check-name/")
  let body = {organization_name: $organization_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Organizations List
#
# GET /ui-api/organizations/
# operationId: organizations_list
export def "ui-api-organizations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_name: string, subscription_plan: any, has_admin_panel: bool, created_at: string, updated_at: string, billing_email: any, organization_display_name: any, github_handle: any, location: any, avatar: any, links: any, description: any, spending_cap_total_units: any, spending_cap_reached_at: any, planless_grace_period_ends_at: any, gateway_enabled: bool, ai_enabled: bool, ai_training_enabled: bool, analytics_enabled: bool, use_enterprise_llm: bool, billing_cycle_start: any, billing_cycle_end: any, is_personal_organization: bool, included_observations: int, role: record<id: string, organization_id: string, name: string, description: any, origin: string, editable: bool, scope: string, has_all_permissions: bool, permissions: list, project_access_policy: string>, requires_enterprise_login: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/organizations/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Organization Create
#
# POST /ui-api/organizations/
# operationId: organization_create
# --links item shape: {url: string, icon: string, name: string}
export def "ui-api-organizations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  organization_name: string
  --organization-display-name: string
  --github-handle: string
  --location: string
  --avatar: string
  --links: list # item shape: {url: string, icon: string, name: string}
  --description: string
]: any -> record<id: string, organization_name: string, subscription_plan: any, has_admin_panel: bool, created_at: string, updated_at: string, billing_email: any, organization_display_name: any, github_handle: any, location: any, avatar: any, links: any, description: any, spending_cap_total_units: any, spending_cap_reached_at: any, planless_grace_period_ends_at: any, gateway_enabled: bool, ai_enabled: bool, ai_training_enabled: bool, analytics_enabled: bool, use_enterprise_llm: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/organizations/")
  let body = {organization_name: $organization_name, organization_display_name: $organization_display_name, github_handle: $github_handle, location: $location, avatar: $avatar, links: $links, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Convert Account To Organization
#
# POST /ui-api/organizations/convert-account-to-organization/
# operationId: convert_account_to_organization
export def "ui-api-organizations-convert-account-to-organization organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  new_organization_name: string
  --new-organization-display-name: string
  --new-organization-avatar: string
  new_personal_account_name: string
  --new-personal-account-avatar: string
  --new-personal-account-display-name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/organizations/convert-account-to-organization/")
  let body = {new_organization_name: $new_organization_name, new_organization_display_name: $new_organization_display_name, new_organization_avatar: $new_organization_avatar, new_personal_account_name: $new_personal_account_name, new_personal_account_avatar: $new_personal_account_avatar, new_personal_account_display_name: $new_personal_account_display_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# User Email Routing List
#
# GET /ui-api/organizations/user-email-routing/
# operationId: user_email_routing_list
export def "ui-api-organizations-user-email-routing list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: string, user_id: string, user_email_id: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/organizations/user-email-routing/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Organization Get
#
# GET /ui-api/organizations/{organization}/
# operationId: organization_get
export def "ui-api-organizations get" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, organization_name: string, subscription_plan: any, has_admin_panel: bool, created_at: string, updated_at: string, billing_email: any, organization_display_name: any, github_handle: any, location: any, avatar: any, links: any, description: any, spending_cap_total_units: any, spending_cap_reached_at: any, planless_grace_period_ends_at: any, gateway_enabled: bool, ai_enabled: bool, ai_training_enabled: bool, analytics_enabled: bool, use_enterprise_llm: bool, billing_cycle_start: any, billing_cycle_end: any, is_personal_organization: bool, included_observations: int, role: record<id: string, organization_id: string, name: string, description: any, origin: string, editable: bool, scope: string, has_all_permissions: bool, permissions: list<string>, project_access_policy: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Organizations Update
#
# PUT /ui-api/organizations/{organization}/
# operationId: organizations_update
# --links item shape: {url: string, icon: string, name: string}
export def "ui-api-organizations update" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-name: string
  --billing-email: string
  --organization-display-name: string
  --github-handle: string
  --location: string
  --avatar: string
  --links: list # item shape: {url: string, icon: string, name: string}
  --description: string
]: any -> record<id: string, organization_name: string, subscription_plan: any, has_admin_panel: bool, created_at: string, updated_at: string, billing_email: any, organization_display_name: any, github_handle: any, location: any, avatar: any, links: any, description: any, spending_cap_total_units: any, spending_cap_reached_at: any, planless_grace_period_ends_at: any, gateway_enabled: bool, ai_enabled: bool, ai_training_enabled: bool, analytics_enabled: bool, use_enterprise_llm: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/")
  let body = {organization_name: $organization_name, billing_email: $billing_email, organization_display_name: $organization_display_name, github_handle: $github_handle, location: $location, avatar: $avatar, links: $links, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Organization Delete
#
# DELETE /ui-api/organizations/{organization}/
# operationId: organization_delete
export def "ui-api-organizations delete" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Organization Set As Personal
#
# POST /ui-api/organizations/{organization}/set-as-personal/
# operationId: organization_set_as_personal
export def "ui-api-organizations-set-as-personal personal" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/set-as-personal/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Organization Get Retention Periods
#
# GET /ui-api/organizations/{organization}/retention/
# operationId: organization_get_retention_periods
export def "ui-api-organizations-retention periods" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<records_retention_days: int, metrics_retention_days: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/retention/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Organization Set Retention Period
#
# POST /ui-api/organizations/{organization}/retention/
# operationId: organization_set_retention_period
export def "ui-api-organizations-retention period" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  records_retention_days: int
  metrics_retention_days: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/retention/")
  let body = {records_retention_days: $records_retention_days, metrics_retention_days: $metrics_retention_days} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Organization Get Current Subscription Plan Limits
#
# GET /ui-api/organizations/{organization}/subscription-plan-limits/
# operationId: organization_get_current_subscription_plan_limits
export def "ui-api-organizations-subscription-plan-limits limits" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<projects: any, seats: any, guests: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/subscription-plan-limits/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Organization Get Subscription Plan Limits By Name
#
# GET /ui-api/organizations/{organization}/subscription-plan-limits/{plan}/
# operationId: organization_get_subscription_plan_limits_by_name
export def "ui-api-organizations-subscription-plan-limits name" [
  plan: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<projects: any, seats: any, guests: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/subscription-plan-limits/($plan)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Organization Get Subscription Plan Usage
#
# GET /ui-api/organizations/{organization}/subscription-plan-usage/
# operationId: organization_get_subscription_plan_usage
export def "ui-api-organizations-subscription-plan-usage usage" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<projects: int, seats: int, guests: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/subscription-plan-usage/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Organization Get All Permissions
#
# GET /ui-api/organizations/{organization}/all-permissions/
# operationId: organization_get_all_permissions
export def "ui-api-organizations-all-permissions permissions" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<organization_permissions: table<id: string, title: string, description: string, implies: list>, project_permissions: table<id: string, title: string, description: string, implies: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/all-permissions/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Organization Subscription Checkout Session
#
# POST /ui-api/organizations/{organization}/create-subscription-checkout-session/
# Discriminator (request): plan = growth, team
# operationId: create_organization_subscription_checkout_session
export def "ui-api-organizations-create-subscription-checkout-session session" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  plan: string@plan-completer
  --seats: int
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/create-subscription-checkout-session/")
  let body = {plan: $plan, seats: $seats} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Organization Gateway Checkout Session
#
# GET /ui-api/organizations/{organization}/create-gateway-checkout-session/
# operationId: create_organization_gateway_checkout_session
export def "ui-api-organizations-create-gateway-checkout-session session" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/create-gateway-checkout-session/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Organization Stripe Portal Session
#
# GET /ui-api/organizations/{organization}/create-stripe-portal-session/
# operationId: create_organization_stripe_portal_session
export def "ui-api-organizations-create-stripe-portal-session session" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/create-stripe-portal-session/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Schedule Organization Subscription Cancel
#
# POST /ui-api/organizations/{organization}/schedule-subscription-cancel/
# operationId: schedule_organization_subscription_cancel
export def "ui-api-organizations-schedule-subscription-cancel cancel" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cancellation-feedback: string@cancellation-feedback-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/schedule-subscription-cancel/")
  let body = {cancellation_feedback: $cancellation_feedback} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Uncancel Organization Subscription
#
# POST /ui-api/organizations/{organization}/uncancel-subscription/
# operationId: uncancel_organization_subscription
export def "ui-api-organizations-uncancel-subscription subscription" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/uncancel-subscription/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel Organization Scheduled Plan Change
#
# POST /ui-api/organizations/{organization}/cancel-scheduled-plan-change/
# operationId: cancel_organization_scheduled_plan_change
export def "ui-api-organizations-cancel-scheduled-plan-change change" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/cancel-scheduled-plan-change/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Apply Organization Plan Change
#
# POST /ui-api/organizations/{organization}/apply-plan-change/
# Discriminator (request): plan = team, growth
# operationId: apply_organization_plan_change
export def "ui-api-organizations-apply-plan-change change" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  plan: string@plan-completer
  --seats: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/apply-plan-change/")
  let body = {plan: $plan, seats: $seats} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Preview Organization Plan Change
#
# POST /ui-api/organizations/{organization}/preview-plan-change/
# Discriminator (request): plan = team, growth
# operationId: preview_organization_plan_change
export def "ui-api-organizations-preview-plan-change change" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  plan: string@plan-completer
  --seats: int
]: any -> record<is_deferred: bool, effective_date: string, currency: string, amount_due: int, upcoming_recurring_amount: int, lines: table<description: string, amount: int, period_start: string, period_end: string>, upcoming_recurring_lines: table<description: string, amount: int, period_start: string, period_end: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/preview-plan-change/")
  let body = {plan: $plan, seats: $seats} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Organization Upcoming Subscription
#
# GET /ui-api/organizations/{organization}/upcoming-subscription/
# operationId: get_organization_upcoming_subscription
export def "ui-api-organizations-upcoming-subscription subscription" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/upcoming-subscription/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Organization Billing Email
#
# PUT /ui-api/organizations/{organization}/billing-emails/
# operationId: update_organization_billing_email
export def "ui-api-organizations-billing-emails email" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  new_billing_email: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/billing-emails/")
  let body = {new_billing_email: $new_billing_email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Re Send Verification Email
#
# POST /ui-api/organizations/{organization}/billing-emails/resend-verification/
# operationId: re_send_verification_email
export def "ui-api-organizations-billing-emails-resend-verification email" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/billing-emails/resend-verification/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Verify Organization Billing Email
#
# PUT /ui-api/organizations/{organization}/billing-emails/verify/
# operationId: verify_organization_billing_email
export def "ui-api-organizations-billing-emails-verify email" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/billing-emails/verify/")
  let body = {code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get Organization Usage
#
# GET /ui-api/organizations/{organization}/usage/
# operationId: get_organization_usage
export def "ui-api-organizations-usage usage" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<observations: int, included_observations: int, price_per_million_observations_cents: int, percentage: float, allowance_available: int, cycle_start: string, cycle_end: string, spending_cap: any, spending_cap_percentage: any, spending_cap_reached_at: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/usage/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Organization Write Tokens
#
# GET /ui-api/organizations/{organization}/write-tokens/
# operationId: get_organization_write_tokens
export def "ui-api-organizations-write-tokens tokens" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, project_id: string, created_at: string, description: any, expires_at: any, project_name: string, created_by_name: any, token_prefix: string, active: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/write-tokens/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Platform Last Six Months Usage
#
# GET /ui-api/organizations/{organization}/get-platform-usage/
# operationId: get_platform_last_six_months_usage
export def "ui-api-organizations-get-platform-usage usage" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/get-platform-usage/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get User Organization Email
#
# GET /ui-api/organizations/{organization}/user-email/
# operationId: get_user_organization_email
export def "ui-api-organizations-user-email email-by-organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/user-email/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set User Organization Email
#
# PUT /ui-api/organizations/{organization}/user-email/
# operationId: set_user_organization_email
export def "ui-api-organizations-user-email email-by-organization-1" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_email_id: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/user-email/")
  let body = {user_email_id: $user_email_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Ai Settings
#
# PATCH /ui-api/organizations/{organization}/ai-settings/
# operationId: update_ai_settings
export def "ui-api-organizations-ai-settings settings" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ai-enabled: oneof<nothing, bool>
  --ai-training-enabled: oneof<nothing, bool>
]: any -> record<ai_enabled: bool, ai_training_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/ai-settings/")
  let body = {ai_enabled: $ai_enabled, ai_training_enabled: $ai_training_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Organization Get Identity Providers
#
# GET /ui-api/organizations/{organization}/identity-providers/
# operationId: organization_get_identity_providers
export def "ui-api-organizations-identity-providers providers" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string
]: nothing -> table<id: string, organization_id: string, provider_type: string, provider_name: string, dex_provider_id: string, oidc_provider_type: any, provider_configuration: any, active: bool, can_disable: bool, will_invalidate_org_access: bool, group_mapping: any, restrict_login_to_mapped_groups: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/identity-providers/")
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Organization Add Identity Provider
#
# POST /ui-api/organizations/{organization}/identity-providers/
# operationId: organization_add_identity_provider
# --provider_configuration shape: {issuer: string, client_id: string, client_secret: string, redirect_uri: string}
# --group_mapping item shape: {group_id: string, organization_role: string, project_roles?: list}
export def "ui-api-organizations-identity-providers provider-by-organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  provider_name: string
  oidc_provider_type: string@oidc-provider-type-completer
  provider_configuration: record # shape: {issuer: string, client_id: string, client_secret: string, redirect_uri: string}
  --group-mapping: list # item shape: {group_id: string, organization_role: string, project_roles?: list}
]: any -> record<id: string, organization_id: string, provider_type: string, provider_name: string, dex_provider_id: string, oidc_provider_type: any, provider_configuration: any, active: bool, group_mapping: any, restrict_login_to_mapped_groups: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/identity-providers/")
  let body = {provider_name: $provider_name, oidc_provider_type: $oidc_provider_type, provider_configuration: $provider_configuration, group_mapping: $group_mapping} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Organization Get Identity Provider Usage Count
#
# GET /ui-api/organizations/{organization}/identity-providers/{provider_id}/usage-count/
# operationId: organization_get_identity_provider_usage_count
export def "ui-api-organizations-identity-providers-usage-count count" [
  provider_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/identity-providers/($provider_id)/usage-count/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Organization Activate Identity Provider
#
# POST /ui-api/organizations/{organization}/identity-providers/{provider_id}/activate/
# operationId: organization_activate_identity_provider
export def "ui-api-organizations-identity-providers-activate provider" [
  provider_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/identity-providers/($provider_id)/activate/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Organization Deactivate Identity Provider
#
# POST /ui-api/organizations/{organization}/identity-providers/{provider_id}/deactivate/
# operationId: organization_deactivate_identity_provider
export def "ui-api-organizations-identity-providers-deactivate provider" [
  provider_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/identity-providers/($provider_id)/deactivate/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Organization Update Identity Provider
#
# PUT /ui-api/organizations/{organization}/identity-providers/{provider_id}/
# operationId: organization_update_identity_provider
# --provider_configuration shape: {issuer: string, client_id: string, client_secret?: string, redirect_uri: string}
export def "ui-api-organizations-identity-providers provider-by-provider_id-organization" [
  provider_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  provider_configuration: record # shape: {issuer: string, client_id: string, client_secret?: string, redirect_uri: string}
]: any -> record<id: string, organization_id: string, provider_type: string, provider_name: string, dex_provider_id: string, oidc_provider_type: any, provider_configuration: any, active: bool, group_mapping: any, restrict_login_to_mapped_groups: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/identity-providers/($provider_id)/")
  let body = {provider_configuration: $provider_configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Organization Delete Identity Provider
#
# DELETE /ui-api/organizations/{organization}/identity-providers/{provider_id}/
# operationId: organization_delete_identity_provider
export def "ui-api-organizations-identity-providers provider-by-provider_id-organization-1" [
  provider_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/identity-providers/($provider_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Organization Group Mapping
#
# PUT /ui-api/organizations/{organization}/identity-providers/{provider_id}/group-mapping/
# operationId: update_organization_group_mapping
# --group_mapping item shape: {group_id: string, organization_role: string, project_roles?: list}
export def "ui-api-organizations-identity-providers-group-mapping mapping" [
  provider_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  group_mapping: list # item shape: {group_id: string, organization_role: string, project_roles?: list}
  --restrict-login-to-mapped-groups: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/identity-providers/($provider_id)/group-mapping/")
  let body = {group_mapping: $group_mapping, restrict_login_to_mapped_groups: $restrict_login_to_mapped_groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Organization Get Members
#
# GET /ui-api/organizations/{organization}/members/
# operationId: organization_get_members
export def "ui-api-organizations-members members" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string, email: string, role_id: string, member_since: string, github_username: any, avatar: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/members/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Organization Update Member
#
# PUT /ui-api/organizations/{organization}/members/{user_id}/
# operationId: organization_update_member
export def "ui-api-organizations-members member-by-organization-user_id" [
  organization: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  role_id: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/members/($user_id)/")
  let body = {role_id: $role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Organization Remove Member
#
# DELETE /ui-api/organizations/{organization}/members/{user_id}/
# operationId: organization_remove_member
export def "ui-api-organizations-members member-by-organization-user_id-1" [
  organization: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/members/($user_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Organization Invitation
#
# POST /ui-api/organizations/{organization}/invitations/
# operationId: create_organization_invitation
export def "ui-api-organizations-invitations invitation" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  max_usage_count: int
  --expiration: string # format: date-time
  role_id: string # format: uuid
]: any -> record<id: string, organization_id: string, expiration: any, max_usage_count: int, role_id: string, usage_count: int, created_at: string, last_used_at: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/invitations/")
  let body = {max_usage_count: $max_usage_count, expiration: $expiration, role_id: $role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Organization Invitations
#
# GET /ui-api/organizations/{organization}/invitations/
# operationId: get_organization_invitations
export def "ui-api-organizations-invitations invitations" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: string, expiration: any, max_usage_count: int, role_id: string, usage_count: int, created_at: string, last_used_at: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/invitations/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke Organization Invitation
#
# POST /ui-api/organizations/{organization}/invitations/{invitation_id}/revoke/
# operationId: revoke_organization_invitation
export def "ui-api-organizations-invitations-revoke invitation" [
  invitation_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/invitations/($invitation_id)/revoke/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Claim Organization Invitation
#
# POST /ui-api/organizations/{organization}/invitations/{invitation_id}/claim/
# operationId: claim_organization_invitation
export def "ui-api-organizations-invitations-claim invitation" [
  organization: string
  invitation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/invitations/($invitation_id)/claim/")
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Subscription Details
#
# GET /ui-api/organizations/{organization}/payments/details/
# operationId: get_subscription_details
export def "ui-api-organizations-payments-details details" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<stripe_customer: record<id: string, organization_id: string, subscription_id: any, usage_based_subscription_id: any, subscription_status: string, payment_method_id: any, created_at: string, updated_at: any, updated_by_name: any, subscription_plan: any>, billing_information: record<address: any, name: any, phone: any, metadata: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/payments/details/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Payment Invoices
#
# GET /ui-api/organizations/{organization}/payments/invoices/
# operationId: get_payment_invoices
export def "ui-api-organizations-payments-invoices invoices" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: any, description: string, amount_due: string, amount_paid: string, currency: string, hosted_invoice_url: any, invoice_pdf: any, status: any, created_at: string, period_end: any, period_start: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/payments/invoices/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Upcoming Invoice
#
# GET /ui-api/organizations/{organization}/payments/invoices/upcoming/
# operationId: get_upcoming_invoice
export def "ui-api-organizations-payments-invoices-upcoming invoice" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<products: table<id: string, description: string, lines: list>, amount_due: string, amount_paid: string, subtotal: string, total_discount_amounts: string, currency: string, period_end: any, period_start: any, usage_total: any, discounts: table<coupon: record, start: any, end: any>, credit_balance: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/payments/invoices/upcoming/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Billing Information
#
# PUT /ui-api/organizations/{organization}/payments/billing/
# operationId: update_billing_information
# --metadata shape: {company_name?: string, account_type?: "individual"|"company", vat_or_gst?: string}
export def "ui-api-organizations-payments-billing information" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --address: record
  --phone: string
  --metadata: record # The billing metadata. — shape: {company_name?: string, account_type?: "individual"|"company", vat_or_gst?: string}
]: any -> record<stripe_customer: record<id: string, organization_id: string, subscription_id: any, usage_based_subscription_id: any, subscription_status: string, payment_method_id: any, created_at: string, updated_at: any, updated_by_name: any, subscription_plan: any>, billing_information: record<address: any, name: any, phone: any, metadata: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/payments/billing/")
  let body = {name: $name, address: $address, phone: $phone, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Usage Summary For Range
#
# GET /ui-api/organizations/{organization}/payments/usage/range/
# operationId: get_usage_summary_for_range
export def "ui-api-organizations-payments-usage-range range" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # format: date
  --end-date: string # format: date
]: nothing -> record<amount_base: float, amount_discount: float, amount_total: float, estimate_total: float, daily_usage: table<records_count: int, metrics_count: int, date: string, project_id: string, token_id: string>, start_date: string, end_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/payments/usage/range/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Apply Coupon
#
# POST /ui-api/organizations/{organization}/payments/coupons/
# operationId: apply_coupon
export def "ui-api-organizations-payments-coupons coupon" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --coupon: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "coupon" $coupon "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/payments/coupons/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Refresh Tokens
#
# GET /ui-api/organizations/{organization}/refresh-tokens/
# operationId: list_refresh_tokens
export def "ui-api-organizations-refresh-tokens tokens" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: string, organization_name: string, user_id: string, user_name: string, client_name: string, project_id: any, project_name: any, family_id: string, parent_id: any, created_at: string, last_used_at: any, expires_at: string, revoked_at: any, revoke_reason: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/refresh-tokens/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke Refresh Token By Family Id
#
# POST /ui-api/organizations/{organization}/refresh-tokens/{family_id}/revoke/
# operationId: revoke_refresh_token_by_family_id
export def "ui-api-organizations-refresh-tokens-revoke id" [
  family_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  reason: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/refresh-tokens/($family_id)/revoke/")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Roles Get By Organization
#
# GET /ui-api/organizations/{organization}/roles/
# operationId: roles_get_by_organization
export def "ui-api-organizations-roles organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: string, name: string, description: any, origin: string, editable: bool, scope: string, has_all_permissions: bool, permissions: list<string>, project_access_policy: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/roles/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Roles Create
#
# POST /ui-api/organizations/{organization}/roles/
# operationId: roles_create
export def "ui-api-organizations-roles create" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  description: any
  permissions: list
  --project-access-policy: string@project-access-policy-completer
  scope: string@scope-completer
]: any -> record<id: string, organization_id: string, name: string, description: any, origin: string, editable: bool, scope: string, has_all_permissions: bool, permissions: list<string>, project_access_policy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/roles/")
  let body = {name: $name, description: $description, permissions: $permissions, project_access_policy: $project_access_policy, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Roles Get By Id
#
# GET /ui-api/organizations/{organization}/roles/{role_id}/
# operationId: roles_get_by_id
export def "ui-api-organizations-roles id" [
  role_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, organization_id: string, name: string, description: any, origin: string, editable: bool, scope: string, has_all_permissions: bool, permissions: list<string>, project_access_policy: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/roles/($role_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Roles Update
#
# PUT /ui-api/organizations/{organization}/roles/{role_id}/
# operationId: roles_update
export def "ui-api-organizations-roles update" [
  role_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  description: any
  permissions: list
  --project-access-policy: string@project-access-policy-completer
]: any -> record<id: string, organization_id: string, name: string, description: any, origin: string, editable: bool, scope: string, has_all_permissions: bool, permissions: list<string>, project_access_policy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/roles/($role_id)/")
  let body = {name: $name, description: $description, permissions: $permissions, project_access_policy: $project_access_policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Roles Delete
#
# DELETE /ui-api/organizations/{organization}/roles/{role_id}/
# operationId: roles_delete
export def "ui-api-organizations-roles delete" [
  role_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/roles/($role_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Schedule
#
# POST /ui-api/organizations/{organization}/schedules/
# operationId: create_schedule
# --windows item shape: {days: list, start_time: string, end_time: string}
export def "ui-api-organizations-schedules schedule-by-organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  label: string
  timezone: string@timezone-completer
  windows: list # item shape: {days: list, start_time: string, end_time: string}
]: any -> record<id: string, organization_id: string, label: string, timezone: string, windows: table<days: list, start_time: string, end_time: string>, created_at: string, updated_at: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/schedules/")
  let body = {label: $label, timezone: $timezone, windows: $windows} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Schedules
#
# GET /ui-api/organizations/{organization}/schedules/
# operationId: list_schedules
export def "ui-api-organizations-schedules schedules" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: string, label: string, timezone: string, windows: list<record>, created_at: string, updated_at: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/schedules/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Schedule
#
# GET /ui-api/organizations/{organization}/schedules/{schedule_id}/
# operationId: get_schedule
export def "ui-api-organizations-schedules schedule-by-schedule_id-organization" [
  schedule_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, organization_id: string, label: string, timezone: string, windows: table<days: list, start_time: string, end_time: string>, created_at: string, updated_at: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/schedules/($schedule_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Schedule
#
# PUT /ui-api/organizations/{organization}/schedules/{schedule_id}/
# operationId: update_schedule
# --windows item shape: {days: list, start_time: string, end_time: string}
export def "ui-api-organizations-schedules schedule-by-schedule_id-organization-1" [
  schedule_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string
  --timezone: string@timezone-completer
  --windows: list # item shape: {days: list, start_time: string, end_time: string}
]: any -> record<id: string, organization_id: string, label: string, timezone: string, windows: table<days: list, start_time: string, end_time: string>, created_at: string, updated_at: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/schedules/($schedule_id)/")
  let body = {label: $label, timezone: $timezone, windows: $windows} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Schedule
#
# DELETE /ui-api/organizations/{organization}/schedules/{schedule_id}/
# operationId: delete_schedule
export def "ui-api-organizations-schedules schedule-by-schedule_id-organization-2" [
  schedule_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/schedules/($schedule_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Oauth Client Scopes By Org
#
# GET /ui-api/organizations/{organization}/oauth-clients/scopes/
# operationId: list_oauth_client_scopes_by_org
export def "ui-api-organizations-oauth-clients-scopes org" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: any, description: string, hint: string, default: bool, project_scoped: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/oauth-clients/scopes/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Oauth Client
#
# POST /ui-api/organizations/{organization}/oauth-clients/
# operationId: create_oauth_client
export def "ui-api-organizations-oauth-clients client-by-organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  client_name: string
  client_type: string@client-type-completer
  redirect_uris: list
  allowed_scopes: list
]: any -> record<client: record<id: string, organization_id: any, client_id: string, client_name: string, client_type: string, allowed_scopes: list<string>, grant_types: list<string>, response_types: list<string>, require_pkce: bool, token_endpoint_auth_method: string, client_metadata: record, created_by: any, created_at: string, updated_at: string, redirect_uris: list<string>, active_secrets_count: int>, client_secret: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/oauth-clients/")
  let body = {client_name: $client_name, client_type: $client_type, redirect_uris: $redirect_uris, allowed_scopes: $allowed_scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Oauth Clients
#
# GET /ui-api/organizations/{organization}/oauth-clients/
# operationId: list_oauth_clients
export def "ui-api-organizations-oauth-clients clients" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: any, client_id: string, client_name: string, client_type: string, allowed_scopes: list<string>, grant_types: list<string>, response_types: list<string>, require_pkce: bool, token_endpoint_auth_method: string, client_metadata: record, created_by: any, created_at: string, updated_at: string, redirect_uris: list<string>, active_secrets_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/oauth-clients/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Oauth Client
#
# GET /ui-api/organizations/{organization}/oauth-clients/{client_id}/
# operationId: get_oauth_client
export def "ui-api-organizations-oauth-clients client-by-client_id-organization" [
  client_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, organization_id: any, client_id: string, client_name: string, client_type: string, allowed_scopes: list<string>, grant_types: list<string>, response_types: list<string>, require_pkce: bool, token_endpoint_auth_method: string, client_metadata: record, created_by: any, created_at: string, updated_at: string, redirect_uris: list<string>, active_secrets_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/oauth-clients/($client_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Oauth Client
#
# PATCH /ui-api/organizations/{organization}/oauth-clients/{client_id}/
# operationId: update_oauth_client
export def "ui-api-organizations-oauth-clients client-by-client_id-organization-1" [
  client_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-name: any
  --redirect-uris: any
  --allowed-scopes: any
]: any -> record<id: string, organization_id: any, client_id: string, client_name: string, client_type: string, allowed_scopes: list<string>, grant_types: list<string>, response_types: list<string>, require_pkce: bool, token_endpoint_auth_method: string, client_metadata: record, created_by: any, created_at: string, updated_at: string, redirect_uris: list<string>, active_secrets_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/oauth-clients/($client_id)/")
  let body = {client_name: $client_name, redirect_uris: $redirect_uris, allowed_scopes: $allowed_scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Oauth Client
#
# DELETE /ui-api/organizations/{organization}/oauth-clients/{client_id}/
# operationId: delete_oauth_client
export def "ui-api-organizations-oauth-clients client-by-client_id-organization-2" [
  client_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/oauth-clients/($client_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Client Secrets
#
# GET /ui-api/organizations/{organization}/oauth-clients/{client_id}/secrets/
# operationId: list_client_secrets
export def "ui-api-organizations-oauth-clients-secrets secrets" [
  client_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-inactive: oneof<nothing, bool> # default: false
]: nothing -> table<id: string, oauth_client_id: string, token_prefix: any, is_active: bool, expires_at: any, created_at: string, created_by: any, last_used_at: any, notes: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_inactive" $include_inactive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/oauth-clients/($client_id)/secrets/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Client Secret
#
# POST /ui-api/organizations/{organization}/oauth-clients/{client_id}/secrets/
# operationId: create_client_secret
export def "ui-api-organizations-oauth-clients-secrets secret-by-client_id-organization" [
  client_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notes: any
]: any -> record<secret_metadata: record<id: string, oauth_client_id: string, token_prefix: any, is_active: bool, expires_at: any, created_at: string, created_by: any, last_used_at: any, notes: any>, client_secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/oauth-clients/($client_id)/secrets/")
  let body = {notes: $notes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deactivate Client Secret
#
# DELETE /ui-api/organizations/{organization}/oauth-clients/{client_id}/secrets/{secret_id}/
# operationId: deactivate_client_secret
export def "ui-api-organizations-oauth-clients-secrets secret-by-client_id-secret_id-organization" [
  client_id: string
  secret_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/oauth-clients/($client_id)/secrets/($secret_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Integrations
#
# GET /ui-api/organizations/{organization}/integrations/
# operationId: list_integrations
export def "ui-api-organizations-integrations integrations" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<providers: table<id: string, display_name: string, kinds: list, auth_style: string, default_scopes: list, config: record, implemented: bool>, installations: table<id: string, organization_id: string, provider_id: string, provider_display_name: string, provider_kinds: list, external_account_id: string, external_account_name: string, external_account_url: any, status: string, token_style: string, scopes: list, config: record, installed_by_user_id: any, installed_at: string, last_refresh_at: any, last_refresh_error: any, last_verified_at: any, approved_resource_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/integrations/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Repositories
#
# GET /ui-api/organizations/{organization}/integrations/repositories/
# operationId: list_repositories
export def "ui-api-organizations-integrations-repositories repositories" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, installation_id: string, external_resource_id: string, full_name: string, external_account_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/integrations/repositories/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disconnect Integration
#
# DELETE /ui-api/organizations/{organization}/integrations/{install_id}
# operationId: disconnect_integration
export def "ui-api-organizations-integrations integration" [
  install_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/integrations/($install_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Slack Install Start
#
# POST /ui-api/organizations/{organization}/integrations/slack/install/start
# operationId: slack_install_start
export def "ui-api-organizations-integrations-slack-install-start start" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/integrations/slack/install/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Github Install Start
#
# POST /ui-api/organizations/{organization}/integrations/github/install/start
# operationId: github_install_start
export def "ui-api-organizations-integrations-github-install-start start" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/integrations/github/install/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validate Materialized View Query
#
# POST /ui-api/organizations/{organization}/materialized-views/validate/
# operationId: validate_materialized_view_query
export def "ui-api-organizations-materialized-views-validate query" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --body-query: string
]: any -> record<name: string, query: string, date_field: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/materialized-views/validate/")
  let body = {name: $name, query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Materialized View
#
# POST /ui-api/organizations/{organization}/materialized-views/
# operationId: create_materialized_view
export def "ui-api-organizations-materialized-views view-by-organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --body-query: string
]: any -> record<materialized_view_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/materialized-views/")
  let body = {name: $name, query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Materialized Views
#
# GET /ui-api/organizations/{organization}/materialized-views/
# operationId: list_materialized_views
export def "ui-api-organizations-materialized-views views" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<materialized_view_id: int, view_table_id: int, name: string, query: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/materialized-views/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Materialized View
#
# DELETE /ui-api/organizations/{organization}/materialized-views/{materialized_view_id}/
# operationId: delete_materialized_view
export def "ui-api-organizations-materialized-views view-by-materialized_view_id-organization" [
  materialized_view_id: int
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/materialized-views/($materialized_view_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Extract And Create Materialized Views
#
# POST /ui-api/organizations/{organization}/materialized-views/extract/
# operationId: extract_and_create_materialized_views
export def "ui-api-organizations-materialized-views-extract views" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-query: string
]: any -> record<materialized_views: table<name: string, query: string, materialized_view_id: any, was_created: bool, error: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/materialized-views/extract/")
  let body = {query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Gateway Api Keys
#
# GET /ui-api/organizations/{organization}/gateway/projects/{project}/api-keys/
# operationId: list_gateway_api_keys
export def "ui-api-organizations-gateway-projects-api-keys keys" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, project_id: string, description: any, status: string, cache_enabled: any, expires_at: any, spending_limit_daily: any, spending_limit_weekly: any, spending_limit_monthly: any, spending_limit_total: any, created_at: string, created_by: any, created_by_name: any, is_personal: bool, key_preview: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/projects/($project)/api-keys/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Gateway Api Key
#
# POST /ui-api/organizations/{organization}/gateway/projects/{project}/api-keys/
# operationId: create_gateway_api_key
export def "ui-api-organizations-gateway-projects-api-keys key-by-project-organization" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string
  expires_at: any
  spending_limit_daily: any
  spending_limit_weekly: any
  spending_limit_monthly: any
  spending_limit_total: any
  --cache-enabled: any
]: any -> record<api_key: record<id: string, project_id: string, description: any, status: string, cache_enabled: any, expires_at: any, spending_limit_daily: any, spending_limit_weekly: any, spending_limit_monthly: any, spending_limit_total: any, created_at: string, created_by: any, created_by_name: any, is_personal: bool, key_preview: string>, key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/projects/($project)/api-keys/")
  let body = {description: $description, expires_at: $expires_at, spending_limit_daily: $spending_limit_daily, spending_limit_weekly: $spending_limit_weekly, spending_limit_monthly: $spending_limit_monthly, spending_limit_total: $spending_limit_total, cache_enabled: $cache_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Gateway Api Key
#
# GET /ui-api/organizations/{organization}/gateway/projects/{project}/api-keys/{api_key_id}/
# operationId: get_gateway_api_key
export def "ui-api-organizations-gateway-projects-api-keys key-by-api_key_id-project-organization" [
  api_key_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, project_id: string, description: any, status: string, cache_enabled: any, expires_at: any, spending_limit_daily: any, spending_limit_weekly: any, spending_limit_monthly: any, spending_limit_total: any, created_at: string, created_by: any, created_by_name: any, is_personal: bool, key_preview: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/projects/($project)/api-keys/($api_key_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Gateway Api Key
#
# PATCH /ui-api/organizations/{organization}/gateway/projects/{project}/api-keys/{api_key_id}/
# operationId: update_gateway_api_key
export def "ui-api-organizations-gateway-projects-api-keys key-by-api_key_id-project-organization-1" [
  api_key_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: any
  --status: any
  --expires-at: any
  --spending-limit-daily: any
  --spending-limit-weekly: any
  --spending-limit-monthly: any
  --spending-limit-total: any
  --cache-enabled: any
]: any -> record<id: string, project_id: string, description: any, status: string, cache_enabled: any, expires_at: any, spending_limit_daily: any, spending_limit_weekly: any, spending_limit_monthly: any, spending_limit_total: any, created_at: string, created_by: any, created_by_name: any, is_personal: bool, key_preview: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/projects/($project)/api-keys/($api_key_id)/")
  let body = {description: $description, status: $status, expires_at: $expires_at, spending_limit_daily: $spending_limit_daily, spending_limit_weekly: $spending_limit_weekly, spending_limit_monthly: $spending_limit_monthly, spending_limit_total: $spending_limit_total, cache_enabled: $cache_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Gateway Api Key
#
# DELETE /ui-api/organizations/{organization}/gateway/projects/{project}/api-keys/{api_key_id}/
# operationId: delete_gateway_api_key
export def "ui-api-organizations-gateway-projects-api-keys key-by-api_key_id-project-organization-2" [
  api_key_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/projects/($project)/api-keys/($api_key_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reveal Gateway Api Key Plaintext
#
# POST /ui-api/organizations/{organization}/gateway/projects/{project}/api-keys/{api_key_id}/key/reveal/
# operationId: reveal_gateway_api_key_plaintext
export def "ui-api-organizations-gateway-projects-api-keys-key-reveal plaintext" [
  api_key_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/projects/($project)/api-keys/($api_key_id)/key/reveal/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Gateway Balance
#
# GET /ui-api/organizations/{organization}/gateway/balance/
# operationId: get_gateway_balance
export def "ui-api-organizations-gateway-balance balance" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<balance_cents: int, balance_dollars: float, auto_recharge_enabled: bool, auto_recharge_threshold_cents: any, auto_recharge_to_cents: any, metronome_billing_configured: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/balance/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Auto Recharge Settings
#
# PATCH /ui-api/organizations/{organization}/gateway/balance/auto-recharge/
# operationId: update_auto_recharge_settings
export def "ui-api-organizations-gateway-balance-auto-recharge settings" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --threshold-amount-cents: int
  --recharge-to-amount-cents: int
]: any -> record<balance_cents: int, balance_dollars: float, auto_recharge_enabled: bool, auto_recharge_threshold_cents: any, auto_recharge_to_cents: any, metronome_billing_configured: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/balance/auto-recharge/")
  let body = {enabled: $enabled, threshold_amount_cents: $threshold_amount_cents, recharge_to_amount_cents: $recharge_to_amount_cents} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Gateway Guardrail Connections
#
# GET /ui-api/organizations/{organization}/gateway/guardrail-connections/
# operationId: list_gateway_guardrail_connections
export def "ui-api-organizations-gateway-guardrail-connections connections" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: string, name: string, provider: string, base_url: string, auth: record<type: string, has_secret: bool>, timeout_ms: int, enabled: bool, dependent_guardrail_count: int, warning: string, created_at: string, updated_at: string, created_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrail-connections/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Gateway Guardrail Connection
#
# POST /ui-api/organizations/{organization}/gateway/guardrail-connections/
# operationId: create_gateway_guardrail_connection
export def "ui-api-organizations-gateway-guardrail-connections connection-by-organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  provider: string
  --body-base-url: string
  --enabled: oneof<nothing, bool>
  --body-auth: any
  --timeout-ms: int
]: any -> record<id: string, organization_id: string, name: string, provider: string, base_url: string, auth: record<type: string, has_secret: bool>, timeout_ms: int, enabled: bool, dependent_guardrail_count: int, warning: string, created_at: string, updated_at: string, created_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrail-connections/")
  let body = {name: $name, provider: $provider, base_url: $body_base_url, enabled: $enabled, auth: $body_auth, timeout_ms: $timeout_ms} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Gateway Guardrail Connection
#
# GET /ui-api/organizations/{organization}/gateway/guardrail-connections/{connection_id}/
# operationId: get_gateway_guardrail_connection
export def "ui-api-organizations-gateway-guardrail-connections connection-by-connection_id-organization" [
  connection_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, organization_id: string, name: string, provider: string, base_url: string, auth: record<type: string, has_secret: bool>, timeout_ms: int, enabled: bool, dependent_guardrail_count: int, warning: string, created_at: string, updated_at: string, created_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrail-connections/($connection_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Gateway Guardrail Connection
#
# PATCH /ui-api/organizations/{organization}/gateway/guardrail-connections/{connection_id}/
# operationId: update_gateway_guardrail_connection
export def "ui-api-organizations-gateway-guardrail-connections connection-by-connection_id-organization-1" [
  connection_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --provider: string
  --body-base-url: string
  --enabled: oneof<nothing, bool>
  --body-auth: any
  --timeout-ms: int
]: any -> record<id: string, organization_id: string, name: string, provider: string, base_url: string, auth: record<type: string, has_secret: bool>, timeout_ms: int, enabled: bool, dependent_guardrail_count: int, warning: string, created_at: string, updated_at: string, created_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrail-connections/($connection_id)/")
  let body = {name: $name, provider: $provider, base_url: $body_base_url, enabled: $enabled, auth: $body_auth, timeout_ms: $timeout_ms} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Gateway Guardrail Connection
#
# DELETE /ui-api/organizations/{organization}/gateway/guardrail-connections/{connection_id}/
# operationId: delete_gateway_guardrail_connection
export def "ui-api-organizations-gateway-guardrail-connections connection-by-connection_id-organization-2" [
  connection_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrail-connections/($connection_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test Gateway Guardrail Connection
#
# POST /ui-api/organizations/{organization}/gateway/guardrail-connections/{connection_id}/test/
# operationId: test_gateway_guardrail_connection
export def "ui-api-organizations-gateway-guardrail-connections-test connection" [
  connection_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<health: record<ok: bool, status_code: any, error: string>, analyze: record<ok: bool, status_code: any, error: string, result_count: int, entity_types: list<string>>, anonymize: record<ok: bool, status_code: any, error: string, anonymized: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrail-connections/($connection_id)/test/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Gateway Guardrails
#
# GET /ui-api/organizations/{organization}/gateway/guardrails/
# operationId: list_gateway_guardrails
export def "ui-api-organizations-gateway-guardrails guardrails" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled-only: oneof<nothing, bool> # default: false
]: nothing -> table<id: string, organization_id: string, name: string, description: any, enabled: bool, stage: string, on_error: string, executor: any, source: string, template_slug: any, effective_status: string, inactive_reason: any, created_at: string, updated_at: string, created_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enabled_only" $enabled_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Gateway Guardrail
#
# POST /ui-api/organizations/{organization}/gateway/guardrails/
# operationId: create_gateway_guardrail
export def "ui-api-organizations-gateway-guardrails guardrail-by-organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: any
  --enabled: oneof<nothing, bool>
  stage: string
  on_error: string@on-error-completer
  executor: any
]: any -> record<id: string, organization_id: string, name: string, description: any, enabled: bool, stage: string, on_error: string, executor: any, source: string, template_slug: any, effective_status: string, inactive_reason: any, created_at: string, updated_at: string, created_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/")
  let body = {name: $name, description: $description, enabled: $enabled, stage: $stage, on_error: $on_error, executor: $executor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Gateway Regex Guardrail Templates
#
# GET /ui-api/organizations/{organization}/gateway/guardrails/templates/
# operationId: list_gateway_regex_guardrail_templates
export def "ui-api-organizations-gateway-guardrails-templates templates" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<slug: string, name: string, description: string, category: string, pattern: string, replacement: string, flags: string, message_roles: list<string>, numbered_replacement: bool, validator: string, recommended: bool, icon: string, sample_messages: list<record>, available_actions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/templates/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Install Gateway Regex Guardrail Template
#
# POST /ui-api/organizations/{organization}/gateway/guardrails/templates/install/
# operationId: install_gateway_regex_guardrail_template
export def "ui-api-organizations-gateway-guardrails-templates-install template" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  template_slug: string
  --action: string@action-completer
  --enabled: oneof<nothing, bool>
  --target-route-slug: any
  --target-route-slugs: list
]: any -> record<id: string, organization_id: string, name: string, description: any, enabled: bool, stage: string, on_error: string, executor: any, source: string, template_slug: any, effective_status: string, inactive_reason: any, created_at: string, updated_at: string, created_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/templates/install/")
  let body = {template_slug: $template_slug, action: $action, enabled: $enabled, target_route_slug: $target_route_slug, target_route_slugs: $target_route_slugs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Install Recommended Gateway Regex Guardrail Templates
#
# POST /ui-api/organizations/{organization}/gateway/guardrails/templates/install-recommended/
# operationId: install_recommended_gateway_regex_guardrail_templates
export def "ui-api-organizations-gateway-guardrails-templates-install-recommended templates" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: string, name: string, description: any, enabled: bool, stage: string, on_error: string, executor: any, source: string, template_slug: any, effective_status: string, inactive_reason: any, created_at: string, updated_at: string, created_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/templates/install-recommended/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Gateway Prebuilt Guardrail Policies
#
# GET /ui-api/organizations/{organization}/gateway/guardrails/prebuilt-policies/
# operationId: list_gateway_prebuilt_guardrail_policies
export def "ui-api-organizations-gateway-guardrails-prebuilt-policies policies" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<template_slug: string, name: string, description: string, category: string, icon: any, sample_messages: list<record>, template_sample_messages: list<record>, user_sample_messages: list<record>, available_actions: list<record>, target_summary: record<kind: string, count: int>, targets: list<record>, has_drift: bool, drift_count: int, guardrail_ids: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/prebuilt-policies/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Gateway Prebuilt Guardrail Policy Match Counts
#
# GET /ui-api/organizations/{organization}/gateway/guardrails/prebuilt-policies/match-counts/
# operationId: get_gateway_prebuilt_guardrail_policy_match_counts
export def "ui-api-organizations-gateway-guardrails-prebuilt-policies-match-counts counts" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --window: string@window-completer # default: 5m
]: nothing -> record<policies: record, window_seconds: int, telemetry_available: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "window" $window "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/prebuilt-policies/match-counts/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Gateway Prebuilt Guardrail Policy Timings
#
# GET /ui-api/organizations/{organization}/gateway/guardrails/prebuilt-policies/timings/
# operationId: get_gateway_prebuilt_guardrail_policy_timings
export def "ui-api-organizations-gateway-guardrails-prebuilt-policies-timings timings" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --window: string@window-completer # default: 1h
]: nothing -> record<policies: record, window_seconds: int, telemetry_available: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "window" $window "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/prebuilt-policies/timings/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Gateway Prebuilt Guardrail Policy
#
# GET /ui-api/organizations/{organization}/gateway/guardrails/prebuilt-policies/{template_slug}/
# operationId: get_gateway_prebuilt_guardrail_policy
export def "ui-api-organizations-gateway-guardrails-prebuilt-policies policy-by-template_slug-organization" [
  template_slug: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<template_slug: string, name: string, description: string, category: string, icon: any, sample_messages: table<role: string, content: string>, template_sample_messages: table<role: string, content: string>, user_sample_messages: table<role: string, content: string>, available_actions: table<action: string, available: bool, unavailable_reason: string>, target_summary: record<kind: string, count: int>, targets: table<target: any, action: string>, has_drift: bool, drift_count: int, guardrail_ids: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/prebuilt-policies/($template_slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Save Gateway Prebuilt Guardrail Policy
#
# PUT /ui-api/organizations/{organization}/gateway/guardrails/prebuilt-policies/{template_slug}/
# operationId: save_gateway_prebuilt_guardrail_policy
# --targets item shape: {target: any, action: "observe"|"flag"|"redact"|"block"}
# --sample_messages item shape: {role: "system"|"user"|"assistant"|"tool", content: string}
export def "ui-api-organizations-gateway-guardrails-prebuilt-policies policy-by-template_slug-organization-1" [
  template_slug: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  targets: list # item shape: {target: any, action: "observe"|"flag"|"redact"|"block"}
  --sample-messages: list # item shape: {role: "system"|"user"|"assistant"|"tool", content: string}
]: any -> record<template_slug: string, name: string, description: string, category: string, icon: any, sample_messages: table<role: string, content: string>, template_sample_messages: table<role: string, content: string>, user_sample_messages: table<role: string, content: string>, available_actions: table<action: string, available: bool, unavailable_reason: string>, target_summary: record<kind: string, count: int>, targets: table<target: any, action: string>, has_drift: bool, drift_count: int, guardrail_ids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/prebuilt-policies/($template_slug)/")
  let body = {targets: $targets, sample_messages: $sample_messages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Gateway Prebuilt Guardrail Policy
#
# DELETE /ui-api/organizations/{organization}/gateway/guardrails/prebuilt-policies/{template_slug}/
# operationId: delete_gateway_prebuilt_guardrail_policy
export def "ui-api-organizations-gateway-guardrails-prebuilt-policies policy-by-template_slug-organization-2" [
  template_slug: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/prebuilt-policies/($template_slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Gateway Custom Regex Policies
#
# GET /ui-api/organizations/{organization}/gateway/guardrails/custom-regex-policies/
# operationId: list_gateway_custom_regex_policies
export def "ui-api-organizations-gateway-guardrails-custom-regex-policies policies" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string, description: any, regex_pattern: string, regex_flags: string, sample_messages: list<record>, targets: list<record>, target_summary: record<kind: string, count: int>, guardrail_ids: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/custom-regex-policies/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Gateway Custom Regex Policy
#
# POST /ui-api/organizations/{organization}/gateway/guardrails/custom-regex-policies/
# operationId: create_gateway_custom_regex_policy
# --targets item shape: {target: any, action: "observe"|"flag"|"redact"|"block"}
export def "ui-api-organizations-gateway-guardrails-custom-regex-policies policy-by-organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: any
  regex_pattern: string
  --regex-flags: string
  targets: list # item shape: {target: any, action: "observe"|"flag"|"redact"|"block"}
  --sample-messages: any
]: any -> record<id: string, name: string, description: any, regex_pattern: string, regex_flags: string, sample_messages: table<role: string, content: string>, targets: table<target: any, action: string>, target_summary: record<kind: string, count: int>, guardrail_ids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/custom-regex-policies/")
  let body = {name: $name, description: $description, regex_pattern: $regex_pattern, regex_flags: $regex_flags, targets: $targets, sample_messages: $sample_messages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Gateway Custom Regex Policy Match Counts
#
# GET /ui-api/organizations/{organization}/gateway/guardrails/custom-regex-policies/match-counts/
# operationId: get_gateway_custom_regex_policy_match_counts
export def "ui-api-organizations-gateway-guardrails-custom-regex-policies-match-counts counts" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --window: string@window-completer # default: 5m
]: nothing -> record<policies: record, window_seconds: int, telemetry_available: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "window" $window "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/custom-regex-policies/match-counts/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Gateway Custom Regex Policy Timings
#
# GET /ui-api/organizations/{organization}/gateway/guardrails/custom-regex-policies/timings/
# operationId: get_gateway_custom_regex_policy_timings
export def "ui-api-organizations-gateway-guardrails-custom-regex-policies-timings timings" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --window: string@window-completer # default: 1h
]: nothing -> record<policies: record, window_seconds: int, telemetry_available: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "window" $window "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/custom-regex-policies/timings/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Gateway Custom Regex Policy
#
# GET /ui-api/organizations/{organization}/gateway/guardrails/custom-regex-policies/{policy_id}/
# operationId: get_gateway_custom_regex_policy
export def "ui-api-organizations-gateway-guardrails-custom-regex-policies policy-by-policy_id-organization" [
  policy_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, description: any, regex_pattern: string, regex_flags: string, sample_messages: table<role: string, content: string>, targets: table<target: any, action: string>, target_summary: record<kind: string, count: int>, guardrail_ids: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/custom-regex-policies/($policy_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Save Gateway Custom Regex Policy
#
# PUT /ui-api/organizations/{organization}/gateway/guardrails/custom-regex-policies/{policy_id}/
# operationId: save_gateway_custom_regex_policy
# --targets item shape: {target: any, action: "observe"|"flag"|"redact"|"block"}
export def "ui-api-organizations-gateway-guardrails-custom-regex-policies policy-by-policy_id-organization-1" [
  policy_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: any
  regex_pattern: string
  --regex-flags: string
  targets: list # item shape: {target: any, action: "observe"|"flag"|"redact"|"block"}
  --sample-messages: any
]: any -> record<id: string, name: string, description: any, regex_pattern: string, regex_flags: string, sample_messages: table<role: string, content: string>, targets: table<target: any, action: string>, target_summary: record<kind: string, count: int>, guardrail_ids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/custom-regex-policies/($policy_id)/")
  let body = {name: $name, description: $description, regex_pattern: $regex_pattern, regex_flags: $regex_flags, targets: $targets, sample_messages: $sample_messages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Gateway Custom Regex Policy
#
# DELETE /ui-api/organizations/{organization}/gateway/guardrails/custom-regex-policies/{policy_id}/
# operationId: delete_gateway_custom_regex_policy
export def "ui-api-organizations-gateway-guardrails-custom-regex-policies policy-by-policy_id-organization-2" [
  policy_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/custom-regex-policies/($policy_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test Gateway Prebuilt Guardrail Policy Sample
#
# POST /ui-api/organizations/{organization}/gateway/guardrails/prebuilt-policies/{template_slug}/test/
# operationId: test_gateway_prebuilt_guardrail_policy_sample
export def "ui-api-organizations-gateway-guardrails-prebuilt-policies-test sample" [
  template_slug: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  target: any
  action: string@action-completer
  text: string
  --include-redacted-text: oneof<nothing, bool>
]: any -> record<ok: bool, action: string, entities: table<type: string, count: int>, redacted_text: string, error: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/prebuilt-policies/($template_slug)/test/")
  let body = {target: $target, action: $action, text: $text, include_redacted_text: $include_redacted_text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Gateway Presidio Policies
#
# GET /ui-api/organizations/{organization}/gateway/guardrails/presidio-policies/
# operationId: list_gateway_presidio_policies
export def "ui-api-organizations-gateway-guardrails-presidio-policies policies" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string, description: any, connection_id: string, connection_enabled: bool, on_error: string, config: record<language: string, entities: record, score_threshold: float>, sample_texts: list<string>, targets: list<record>, target_summary: record<kind: string, count: int>, effective_status: string, inactive_reason: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/presidio-policies/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Gateway Presidio Policy
#
# POST /ui-api/organizations/{organization}/gateway/guardrails/presidio-policies/
# operationId: create_gateway_presidio_policy
# --config shape: {language: string, entities: record, score_threshold?: float}
# --targets item shape: {target: any}
export def "ui-api-organizations-gateway-guardrails-presidio-policies policy-by-organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: any
  connection_id: string # format: uuid
  on_error: string@on-error-completer
  config: record # shape: {language: string, entities: record, score_threshold?: float}
  targets: list # item shape: {target: any}
  --sample-texts: any
]: any -> record<id: string, name: string, description: any, connection_id: string, connection_enabled: bool, on_error: string, config: record<language: string, entities: record, score_threshold: float>, sample_texts: list<string>, targets: table<target: any>, target_summary: record<kind: string, count: int>, effective_status: string, inactive_reason: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/presidio-policies/")
  let body = {name: $name, description: $description, connection_id: $connection_id, on_error: $on_error, config: $config, targets: $targets, sample_texts: $sample_texts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Test Gateway Presidio Policy Sample
#
# POST /ui-api/organizations/{organization}/gateway/guardrails/presidio-policies/test-sample/
# operationId: test_gateway_presidio_policy_sample
# --config shape: {language: string, entities: record, score_threshold?: float}
export def "ui-api-organizations-gateway-guardrails-presidio-policies-test-sample sample" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
  config: record # shape: {language: string, entities: record, score_threshold?: float}
  text: string
  --include-redacted-text: oneof<nothing, bool>
]: any -> record<ok: bool, action: string, entities: table<type: string, count: int>, redacted_text: string, error: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/presidio-policies/test-sample/")
  let body = {connection_id: $connection_id, config: $config, text: $text, include_redacted_text: $include_redacted_text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Gateway Presidio Policy
#
# GET /ui-api/organizations/{organization}/gateway/guardrails/presidio-policies/{policy_id}/
# operationId: get_gateway_presidio_policy
export def "ui-api-organizations-gateway-guardrails-presidio-policies policy-by-policy_id-organization" [
  policy_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, description: any, connection_id: string, connection_enabled: bool, on_error: string, config: record<language: string, entities: record, score_threshold: float>, sample_texts: list<string>, targets: table<target: any>, target_summary: record<kind: string, count: int>, effective_status: string, inactive_reason: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/presidio-policies/($policy_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Save Gateway Presidio Policy
#
# PUT /ui-api/organizations/{organization}/gateway/guardrails/presidio-policies/{policy_id}/
# operationId: save_gateway_presidio_policy
# --config shape: {language: string, entities: record, score_threshold?: float}
# --targets item shape: {target: any}
export def "ui-api-organizations-gateway-guardrails-presidio-policies policy-by-policy_id-organization-1" [
  policy_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: any
  connection_id: string # format: uuid
  on_error: string@on-error-completer
  config: record # shape: {language: string, entities: record, score_threshold?: float}
  targets: list # item shape: {target: any}
  --sample-texts: any
]: any -> record<id: string, name: string, description: any, connection_id: string, connection_enabled: bool, on_error: string, config: record<language: string, entities: record, score_threshold: float>, sample_texts: list<string>, targets: table<target: any>, target_summary: record<kind: string, count: int>, effective_status: string, inactive_reason: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/presidio-policies/($policy_id)/")
  let body = {name: $name, description: $description, connection_id: $connection_id, on_error: $on_error, config: $config, targets: $targets, sample_texts: $sample_texts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Gateway Presidio Policy
#
# DELETE /ui-api/organizations/{organization}/gateway/guardrails/presidio-policies/{policy_id}/
# operationId: delete_gateway_presidio_policy
export def "ui-api-organizations-gateway-guardrails-presidio-policies policy-by-policy_id-organization-2" [
  policy_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/presidio-policies/($policy_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Gateway Guardrail Match Counts
#
# GET /ui-api/organizations/{organization}/gateway/guardrails/match-counts/
# operationId: get_gateway_guardrail_match_counts
export def "ui-api-organizations-gateway-guardrails-match-counts counts" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --window: string@window-completer # default: 5m
]: nothing -> record<guardrails: record, window_seconds: int, telemetry_available: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "window" $window "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/match-counts/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Gateway Guardrail Timings
#
# GET /ui-api/organizations/{organization}/gateway/guardrails/timings/
# operationId: get_gateway_guardrail_timings
export def "ui-api-organizations-gateway-guardrails-timings timings" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --window: string@window-completer # default: 1h
]: nothing -> record<guardrails: record, window_seconds: int, telemetry_available: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "window" $window "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/timings/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Gateway Guardrail
#
# GET /ui-api/organizations/{organization}/gateway/guardrails/{guardrail_id}/
# operationId: get_gateway_guardrail
export def "ui-api-organizations-gateway-guardrails guardrail-by-guardrail_id-organization" [
  guardrail_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, organization_id: string, name: string, description: any, enabled: bool, stage: string, on_error: string, executor: any, source: string, template_slug: any, effective_status: string, inactive_reason: any, created_at: string, updated_at: string, created_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/($guardrail_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Gateway Guardrail
#
# PUT /ui-api/organizations/{organization}/gateway/guardrails/{guardrail_id}/
# operationId: update_gateway_guardrail
export def "ui-api-organizations-gateway-guardrails guardrail-by-guardrail_id-organization-1" [
  guardrail_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: any
  --enabled: oneof<nothing, bool>
  stage: string
  on_error: string@on-error-completer
  executor: any
]: any -> record<id: string, organization_id: string, name: string, description: any, enabled: bool, stage: string, on_error: string, executor: any, source: string, template_slug: any, effective_status: string, inactive_reason: any, created_at: string, updated_at: string, created_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/($guardrail_id)/")
  let body = {name: $name, description: $description, enabled: $enabled, stage: $stage, on_error: $on_error, executor: $executor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Gateway Guardrail
#
# DELETE /ui-api/organizations/{organization}/gateway/guardrails/{guardrail_id}/
# operationId: delete_gateway_guardrail
export def "ui-api-organizations-gateway-guardrails guardrail-by-guardrail_id-organization-2" [
  guardrail_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/($guardrail_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test Gateway Guardrail Sample
#
# POST /ui-api/organizations/{organization}/gateway/guardrails/{guardrail_id}/test/
# operationId: test_gateway_guardrail_sample
export def "ui-api-organizations-gateway-guardrails-test sample" [
  guardrail_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string
  --include-redacted-text: oneof<nothing, bool>
]: any -> record<ok: bool, action: string, entities: table<type: string, count: int>, redacted_text: string, error: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/($guardrail_id)/test/")
  let body = {text: $text, include_redacted_text: $include_redacted_text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Gateway Guardrail Bindings
#
# GET /ui-api/organizations/{organization}/gateway/guardrails/{guardrail_id}/bindings/
# operationId: list_gateway_guardrail_bindings
export def "ui-api-organizations-gateway-guardrails-bindings bindings" [
  guardrail_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, guardrail_id: string, organization_id: string, project_id: any, api_key_id: any, target_provider_slug: any, target_route_slug: any, priority: int, enabled: bool, created_at: string, created_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/($guardrail_id)/bindings/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Gateway Guardrail Binding
#
# POST /ui-api/organizations/{organization}/gateway/guardrails/{guardrail_id}/bindings/
# operationId: create_gateway_guardrail_binding
export def "ui-api-organizations-gateway-guardrails-bindings binding-by-guardrail_id-organization" [
  guardrail_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --project-id: any
  --api-key-id: any
  --target-provider-slug: any
  --target-route-slug: any
  --priority: int
]: any -> record<id: string, guardrail_id: string, organization_id: string, project_id: any, api_key_id: any, target_provider_slug: any, target_route_slug: any, priority: int, enabled: bool, created_at: string, created_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/($guardrail_id)/bindings/")
  let body = {enabled: $enabled, project_id: $project_id, api_key_id: $api_key_id, target_provider_slug: $target_provider_slug, target_route_slug: $target_route_slug, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Gateway Guardrail Binding
#
# DELETE /ui-api/organizations/{organization}/gateway/guardrails/{guardrail_id}/bindings/{binding_id}/
# operationId: delete_gateway_guardrail_binding
export def "ui-api-organizations-gateway-guardrails-bindings binding-by-guardrail_id-binding_id-organization" [
  guardrail_id: string
  binding_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/guardrails/($guardrail_id)/bindings/($binding_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get All Member Gateway Limits Settings
#
# GET /ui-api/organizations/{organization}/gateway/members/settings/
# operationId: get_all_member_gateway_limits_settings
export def "ui-api-organizations-gateway-members-settings settings-by-organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<user_id: string, user_name: string, gateway_spending_limit_daily: any, gateway_spending_limit_weekly: any, gateway_spending_limit_monthly: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/members/settings/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Member Gateway Limits Settings
#
# PATCH /ui-api/organizations/{organization}/gateway/members/settings/{member_user_id}/
# operationId: update_member_gateway_limits_settings
export def "ui-api-organizations-gateway-members-settings settings-by-member_user_id-organization" [
  member_user_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --gateway-spending-limit-daily: any
  --gateway-spending-limit-weekly: any
  --gateway-spending-limit-monthly: any
]: any -> record<user_id: string, user_name: string, gateway_spending_limit_daily: any, gateway_spending_limit_weekly: any, gateway_spending_limit_monthly: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/members/settings/($member_user_id)/")
  let body = {gateway_spending_limit_daily: $gateway_spending_limit_daily, gateway_spending_limit_weekly: $gateway_spending_limit_weekly, gateway_spending_limit_monthly: $gateway_spending_limit_monthly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Personal Api Keys
#
# GET /ui-api/organizations/{organization}/gateway/projects/{project}/personal-api-keys/
# operationId: list_personal_api_keys
export def "ui-api-organizations-gateway-projects-personal-api-keys keys" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, project_id: string, description: any, status: string, cache_enabled: any, expires_at: any, spending_limit_daily: any, spending_limit_weekly: any, spending_limit_monthly: any, spending_limit_total: any, created_at: string, created_by: any, created_by_name: any, is_personal: bool, key_preview: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/projects/($project)/personal-api-keys/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Personal Api Key
#
# POST /ui-api/organizations/{organization}/gateway/projects/{project}/personal-api-keys/
# operationId: create_personal_api_key
export def "ui-api-organizations-gateway-projects-personal-api-keys key-by-project-organization" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string
  expires_at: any
  spending_limit_daily: any
  spending_limit_weekly: any
  spending_limit_monthly: any
  spending_limit_total: any
  --cache-enabled: any
]: any -> record<api_key: record<id: string, project_id: string, description: any, status: string, cache_enabled: any, expires_at: any, spending_limit_daily: any, spending_limit_weekly: any, spending_limit_monthly: any, spending_limit_total: any, created_at: string, created_by: any, created_by_name: any, is_personal: bool, key_preview: string>, key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/projects/($project)/personal-api-keys/")
  let body = {description: $description, expires_at: $expires_at, spending_limit_daily: $spending_limit_daily, spending_limit_weekly: $spending_limit_weekly, spending_limit_monthly: $spending_limit_monthly, spending_limit_total: $spending_limit_total, cache_enabled: $cache_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Personal Api Key
#
# GET /ui-api/organizations/{organization}/gateway/projects/{project}/personal-api-keys/{api_key_id}/
# operationId: get_personal_api_key
export def "ui-api-organizations-gateway-projects-personal-api-keys key-by-api_key_id-project-organization" [
  api_key_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, project_id: string, description: any, status: string, cache_enabled: any, expires_at: any, spending_limit_daily: any, spending_limit_weekly: any, spending_limit_monthly: any, spending_limit_total: any, created_at: string, created_by: any, created_by_name: any, is_personal: bool, key_preview: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/projects/($project)/personal-api-keys/($api_key_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Personal Api Key
#
# PATCH /ui-api/organizations/{organization}/gateway/projects/{project}/personal-api-keys/{api_key_id}/
# operationId: update_personal_api_key
export def "ui-api-organizations-gateway-projects-personal-api-keys key-by-api_key_id-project-organization-1" [
  api_key_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: any
  --status: any
  --expires-at: any
  --spending-limit-daily: any
  --spending-limit-weekly: any
  --spending-limit-monthly: any
  --spending-limit-total: any
  --cache-enabled: any
]: any -> record<id: string, project_id: string, description: any, status: string, cache_enabled: any, expires_at: any, spending_limit_daily: any, spending_limit_weekly: any, spending_limit_monthly: any, spending_limit_total: any, created_at: string, created_by: any, created_by_name: any, is_personal: bool, key_preview: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/projects/($project)/personal-api-keys/($api_key_id)/")
  let body = {description: $description, status: $status, expires_at: $expires_at, spending_limit_daily: $spending_limit_daily, spending_limit_weekly: $spending_limit_weekly, spending_limit_monthly: $spending_limit_monthly, spending_limit_total: $spending_limit_total, cache_enabled: $cache_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Personal Api Key
#
# DELETE /ui-api/organizations/{organization}/gateway/projects/{project}/personal-api-keys/{api_key_id}/
# operationId: delete_personal_api_key
export def "ui-api-organizations-gateway-projects-personal-api-keys key-by-api_key_id-project-organization-2" [
  api_key_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/projects/($project)/personal-api-keys/($api_key_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reveal Personal Api Key Plaintext
#
# POST /ui-api/organizations/{organization}/gateway/projects/{project}/personal-api-keys/{api_key_id}/key/reveal/
# operationId: reveal_personal_api_key_plaintext
export def "ui-api-organizations-gateway-projects-personal-api-keys-key-reveal plaintext" [
  api_key_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/projects/($project)/personal-api-keys/($api_key_id)/key/reveal/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Personal Api Key Usage
#
# GET /ui-api/organizations/{organization}/gateway/projects/{project}/personal-api-keys/{api_key_id}/usage/
# operationId: get_personal_api_key_usage
export def "ui-api-organizations-gateway-projects-personal-api-keys-usage usage" [
  api_key_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<daily: float, weekly: float, monthly: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/projects/($project)/personal-api-keys/($api_key_id)/usage/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Redeem Gateway Promo Code
#
# POST /ui-api/organizations/{organization}/gateway/promo-codes/redeem/
# operationId: redeem_gateway_promo_code
export def "ui-api-organizations-gateway-promo-codes-redeem code" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  promo_code: string
]: any -> record<promo_code: string, credit_amount_cents: int, balance_cents: int, balance_dollars: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/promo-codes/redeem/")
  let body = {promo_code: $promo_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Project Gateway Settings
#
# GET /ui-api/organizations/{organization}/gateway/projects/{project}/settings/
# operationId: get_project_gateway_settings
export def "ui-api-organizations-gateway-projects-settings settings-by-project-organization" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<gateway_spending_limit_daily: any, gateway_spending_limit_weekly: any, gateway_spending_limit_monthly: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/projects/($project)/settings/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Project Gateway Settings
#
# PATCH /ui-api/organizations/{organization}/gateway/projects/{project}/settings/
# operationId: update_project_gateway_settings
export def "ui-api-organizations-gateway-projects-settings settings-by-project-organization-1" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --gateway-spending-limit-daily: any
  --gateway-spending-limit-weekly: any
  --gateway-spending-limit-monthly: any
]: any -> record<gateway_spending_limit_daily: any, gateway_spending_limit_weekly: any, gateway_spending_limit_monthly: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/projects/($project)/settings/")
  let body = {gateway_spending_limit_daily: $gateway_spending_limit_daily, gateway_spending_limit_weekly: $gateway_spending_limit_weekly, gateway_spending_limit_monthly: $gateway_spending_limit_monthly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Gateway Providers
#
# GET /ui-api/organizations/{organization}/gateway/providers/
# operationId: list_gateway_providers
export def "ui-api-organizations-gateway-providers providers" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-built-in: oneof<nothing, bool> # default: true
]: nothing -> table<id: string, organization_id: any, description: any, provider_type: string, slug: string, base_url: string, inject_cost: bool, is_built_in: bool, block_on_error: bool, created_at: string, created_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_built_in" $include_built_in "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/providers/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Gateway Provider
#
# POST /ui-api/organizations/{organization}/gateway/providers/
# operationId: create_gateway_provider
export def "ui-api-organizations-gateway-providers provider-by-organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  provider_type: string
  slug: string
  --body-base-url: string
  credentials: string
  description: any
  --inject-cost: oneof<nothing, bool>
  --block-on-error: oneof<nothing, bool>
]: any -> record<id: string, organization_id: any, description: any, provider_type: string, slug: string, base_url: string, inject_cost: bool, is_built_in: bool, block_on_error: bool, created_at: string, created_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/providers/")
  let body = {provider_type: $provider_type, slug: $slug, base_url: $body_base_url, credentials: $credentials, description: $description, inject_cost: $inject_cost, block_on_error: $block_on_error} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Built In Providers
#
# GET /ui-api/organizations/{organization}/gateway/providers/built-in/
# operationId: list_built_in_providers
export def "ui-api-organizations-gateway-providers-built-in providers" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: any, description: any, provider_type: string, slug: string, base_url: string, inject_cost: bool, is_built_in: bool, block_on_error: bool, created_at: string, created_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/providers/built-in/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Gateway Provider
#
# GET /ui-api/organizations/{organization}/gateway/providers/{provider_id}/
# operationId: get_gateway_provider
export def "ui-api-organizations-gateway-providers provider-by-provider_id-organization" [
  provider_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, organization_id: any, description: any, provider_type: string, slug: string, base_url: string, inject_cost: bool, is_built_in: bool, block_on_error: bool, created_at: string, created_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/providers/($provider_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Gateway Provider
#
# PATCH /ui-api/organizations/{organization}/gateway/providers/{provider_id}/
# operationId: update_gateway_provider
export def "ui-api-organizations-gateway-providers provider-by-provider_id-organization-1" [
  provider_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: any
  --body-base-url: any
  --credentials: any
  --inject-cost: any
  --block-on-error: any
]: any -> record<id: string, organization_id: any, description: any, provider_type: string, slug: string, base_url: string, inject_cost: bool, is_built_in: bool, block_on_error: bool, created_at: string, created_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/providers/($provider_id)/")
  let body = {description: $description, base_url: $body_base_url, credentials: $credentials, inject_cost: $inject_cost, block_on_error: $block_on_error} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Gateway Provider
#
# DELETE /ui-api/organizations/{organization}/gateway/providers/{provider_id}/
# operationId: delete_gateway_provider
export def "ui-api-organizations-gateway-providers provider-by-provider_id-organization-2" [
  provider_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/providers/($provider_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Gateway Routing Groups
#
# GET /ui-api/organizations/{organization}/gateway/routing-groups/
# operationId: list_gateway_routing_groups
export def "ui-api-organizations-gateway-routing-groups groups" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: any, slug: string, description: any, built_in: bool, created_at: string, created_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/routing-groups/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Gateway Routing Group
#
# POST /ui-api/organizations/{organization}/gateway/routing-groups/
# operationId: create_gateway_routing_group
export def "ui-api-organizations-gateway-routing-groups group-by-organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  slug: string
  description: any
]: any -> record<id: string, organization_id: any, slug: string, description: any, built_in: bool, created_at: string, created_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/routing-groups/")
  let body = {slug: $slug, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Gateway Routing Group
#
# GET /ui-api/organizations/{organization}/gateway/routing-groups/{routing_group_id}/
# operationId: get_gateway_routing_group
export def "ui-api-organizations-gateway-routing-groups group-by-routing_group_id-organization" [
  routing_group_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, organization_id: any, slug: string, description: any, built_in: bool, created_at: string, created_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/routing-groups/($routing_group_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Gateway Routing Group
#
# PATCH /ui-api/organizations/{organization}/gateway/routing-groups/{routing_group_id}/
# operationId: update_gateway_routing_group
export def "ui-api-organizations-gateway-routing-groups group-by-routing_group_id-organization-1" [
  routing_group_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: any
]: any -> record<id: string, organization_id: any, slug: string, description: any, built_in: bool, created_at: string, created_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/routing-groups/($routing_group_id)/")
  let body = {description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Gateway Routing Group
#
# DELETE /ui-api/organizations/{organization}/gateway/routing-groups/{routing_group_id}/
# operationId: delete_gateway_routing_group
export def "ui-api-organizations-gateway-routing-groups group-by-routing_group_id-organization-2" [
  routing_group_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/routing-groups/($routing_group_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Gateway Routing Group Members
#
# GET /ui-api/organizations/{organization}/gateway/routing-groups/{routing_group_id}/members/
# operationId: list_gateway_routing_group_members
export def "ui-api-organizations-gateway-routing-groups-members members" [
  routing_group_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, provider_id: string, routing_group_id: string, priority: int, weight: float, active: bool, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/routing-groups/($routing_group_id)/members/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add Member To Routing Group
#
# POST /ui-api/organizations/{organization}/gateway/routing-groups/{routing_group_id}/members/
# operationId: add_member_to_routing_group
export def "ui-api-organizations-gateway-routing-groups-members group-by-routing_group_id-organization" [
  routing_group_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  provider_id: string # format: uuid
  priority: int
  weight: float
  --active: oneof<nothing, bool>
]: any -> record<id: string, provider_id: string, routing_group_id: string, priority: int, weight: float, active: bool, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/routing-groups/($routing_group_id)/members/")
  let body = {provider_id: $provider_id, priority: $priority, weight: $weight, active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Routing Group Member
#
# PATCH /ui-api/organizations/{organization}/gateway/routing-groups/{routing_group_id}/members/{member_id}/
# operationId: update_routing_group_member
export def "ui-api-organizations-gateway-routing-groups-members member" [
  routing_group_id: string
  member_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --priority: any
  --weight: any
  --active: any
]: any -> record<id: string, provider_id: string, routing_group_id: string, priority: int, weight: float, active: bool, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/routing-groups/($routing_group_id)/members/($member_id)/")
  let body = {priority: $priority, weight: $weight, active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove Member From Routing Group
#
# DELETE /ui-api/organizations/{organization}/gateway/routing-groups/{routing_group_id}/members/{member_id}/
# operationId: remove_member_from_routing_group
export def "ui-api-organizations-gateway-routing-groups-members group-by-routing_group_id-member_id-organization" [
  routing_group_id: string
  member_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/routing-groups/($routing_group_id)/members/($member_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Gateway Settings
#
# GET /ui-api/organizations/{organization}/gateway/settings/
# operationId: get_gateway_settings
export def "ui-api-organizations-gateway-settings settings-by-organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<gateway_enabled: bool, billing_status: string, builtin_providers_access_status: string, builtin_providers_enabled: bool, organization_name: string, is_personal_organization: bool, gateway_service_name: string, gateway_spending_limit_daily: any, gateway_spending_limit_weekly: any, gateway_spending_limit_monthly: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/settings/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Gateway Settings
#
# PATCH /ui-api/organizations/{organization}/gateway/settings/
# operationId: update_gateway_settings
export def "ui-api-organizations-gateway-settings settings-by-organization-1" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --gateway-enabled: oneof<nothing, bool>
  --gateway-service-name: string
  --gateway-spending-limit-daily: any
  --gateway-spending-limit-weekly: any
  --gateway-spending-limit-monthly: any
]: any -> record<gateway_enabled: bool, billing_status: string, builtin_providers_access_status: string, builtin_providers_enabled: bool, organization_name: string, is_personal_organization: bool, gateway_service_name: string, gateway_spending_limit_daily: any, gateway_spending_limit_weekly: any, gateway_spending_limit_monthly: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/settings/")
  let body = {gateway_enabled: $gateway_enabled, gateway_service_name: $gateway_service_name, gateway_spending_limit_daily: $gateway_spending_limit_daily, gateway_spending_limit_weekly: $gateway_spending_limit_weekly, gateway_spending_limit_monthly: $gateway_spending_limit_monthly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Builtin Providers Preference
#
# PATCH /ui-api/organizations/{organization}/gateway/settings/built-in-providers/
# operationId: update_builtin_providers_preference
export def "ui-api-organizations-gateway-settings-built-in-providers preference" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
]: any -> record<gateway_enabled: bool, billing_status: string, builtin_providers_access_status: string, builtin_providers_enabled: bool, organization_name: string, is_personal_organization: bool, gateway_service_name: string, gateway_spending_limit_daily: any, gateway_spending_limit_weekly: any, gateway_spending_limit_monthly: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/settings/built-in-providers/")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Activate Builtin Providers
#
# POST /ui-api/organizations/{organization}/gateway/settings/built-in-providers/activate/
# operationId: activate_builtin_providers
export def "ui-api-organizations-gateway-settings-built-in-providers-activate providers" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --promo-code: string
]: any -> record<gateway_enabled: bool, billing_status: string, builtin_providers_access_status: string, builtin_providers_enabled: bool, organization_name: string, is_personal_organization: bool, gateway_service_name: string, gateway_spending_limit_daily: any, gateway_spending_limit_weekly: any, gateway_spending_limit_monthly: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/settings/built-in-providers/activate/")
  let body = {promo_code: $promo_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Telemetry Settings
#
# GET /ui-api/organizations/{organization}/gateway/projects/{project}/telemetry/
# operationId: get_telemetry_settings
export def "ui-api-organizations-gateway-projects-telemetry settings" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<gateway_otel_enabled: bool, write_token_prefix: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/projects/($project)/telemetry/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable Telemetry
#
# POST /ui-api/organizations/{organization}/gateway/projects/{project}/telemetry/enable
# operationId: enable_telemetry
export def "ui-api-organizations-gateway-projects-telemetry-enable telemetry" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<gateway_otel_enabled: bool, write_token_prefix: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/projects/($project)/telemetry/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable Telemetry
#
# POST /ui-api/organizations/{organization}/gateway/projects/{project}/telemetry/disable
# operationId: disable_telemetry
export def "ui-api-organizations-gateway-projects-telemetry-disable telemetry" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<gateway_otel_enabled: bool, write_token_prefix: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/projects/($project)/telemetry/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Organization Analytics
#
# GET /ui-api/organizations/{organization}/gateway/usage/analytics/
# operationId: get_organization_analytics
export def "ui-api-organizations-gateway-usage-analytics analytics" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # format: date
  --end-date: string # format: date
]: nothing -> table<date: string, cost: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/usage/analytics/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Organization Usage Summary
#
# GET /ui-api/organizations/{organization}/gateway/usage/summary/
# operationId: get_organization_usage_summary
export def "ui-api-organizations-gateway-usage-summary summary" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<daily: float, weekly: float, monthly: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/usage/summary/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Projects Usage Breakdown
#
# GET /ui-api/organizations/{organization}/gateway/usage/projects/
# operationId: get_projects_usage_breakdown
export def "ui-api-organizations-gateway-usage-projects breakdown" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<project_id: string, project_name: string, monthly_spend: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/usage/projects/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Members Usage Breakdown
#
# GET /ui-api/organizations/{organization}/gateway/usage/members/
# operationId: get_members_usage_breakdown
export def "ui-api-organizations-gateway-usage-members breakdown" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<user_id: string, user_name: string, monthly_spend: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/usage/members/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Gateway Analytics
#
# GET /ui-api/organizations/{organization}/gateway/projects/{project}/usage/analytics/
# operationId: get_gateway_analytics
export def "ui-api-organizations-gateway-projects-usage-analytics analytics" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # format: date
  --end-date: string # format: date
]: nothing -> table<date: string, cost: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/projects/($project)/usage/analytics/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Gateway Usage Summary
#
# GET /ui-api/organizations/{organization}/gateway/projects/{project}/usage/summary/
# operationId: get_gateway_usage_summary
export def "ui-api-organizations-gateway-projects-usage-summary summary" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<daily: float, weekly: float, monthly: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/projects/($project)/usage/summary/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Api Keys Usage Breakdown
#
# GET /ui-api/organizations/{organization}/gateway/projects/{project}/usage/api-keys/
# operationId: get_api_keys_usage_breakdown
export def "ui-api-organizations-gateway-projects-usage-api-keys breakdown" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<api_key_id: string, description: any, status: string, monthly_spend: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/projects/($project)/usage/api-keys/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Api Key Usage Summary
#
# GET /ui-api/organizations/{organization}/gateway/projects/{project}/usage/api-keys/{api_key_id}/
# operationId: get_api_key_usage_summary
export def "ui-api-organizations-gateway-projects-usage-api-keys summary" [
  api_key_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<daily: float, weekly: float, monthly: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/gateway/projects/($project)/usage/api-keys/($api_key_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Trust Policies
#
# GET /ui-api/organizations/{organization}/oidc/trust-policies/
# operationId: list_trust_policies
export def "ui-api-organizations-oidc-trust-policies policies" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: string, project_id: any, project_name: any, name: string, provider: any, claims: record, allowed_algorithms: list<string>, scopes: list<string>, token_ttl_seconds: int, active: bool, created_by: any, created_at: string, updated_at: string, scope_claims: record<project_gateway_proxy: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/oidc/trust-policies/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Trust Policy
#
# POST /ui-api/organizations/{organization}/oidc/trust-policies/
# operationId: create_trust_policy
# --scope_claims shape: {project:gateway_proxy?: record}
export def "ui-api-organizations-oidc-trust-policies policy-by-organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  project_id: any
  provider: any
  claims: record
  allowed_algorithms: list
  scopes: list
  token_ttl_seconds: int
  --scope-claims: record # shape: {project:gateway_proxy?: record}
]: any -> record<id: string, organization_id: string, project_id: any, project_name: any, name: string, provider: any, claims: record, allowed_algorithms: list<string>, scopes: list<string>, token_ttl_seconds: int, active: bool, created_by: any, created_at: string, updated_at: string, scope_claims: record<project_gateway_proxy: record<spending_limit_daily: any, spending_limit_weekly: any, spending_limit_monthly: any, spending_limit_total: any, cache_enabled: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/oidc/trust-policies/")
  let body = {name: $name, project_id: $project_id, provider: $provider, claims: $claims, allowed_algorithms: $allowed_algorithms, scopes: $scopes, token_ttl_seconds: $token_ttl_seconds, scope_claims: $scope_claims} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Trust Policy
#
# GET /ui-api/organizations/{organization}/oidc/trust-policies/{policy_id}/
# operationId: get_trust_policy
export def "ui-api-organizations-oidc-trust-policies policy-by-policy_id-organization" [
  policy_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, organization_id: string, project_id: any, project_name: any, name: string, provider: any, claims: record, allowed_algorithms: list<string>, scopes: list<string>, token_ttl_seconds: int, active: bool, created_by: any, created_at: string, updated_at: string, scope_claims: record<project_gateway_proxy: record<spending_limit_daily: any, spending_limit_weekly: any, spending_limit_monthly: any, spending_limit_total: any, cache_enabled: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/oidc/trust-policies/($policy_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Trust Policy
#
# PUT /ui-api/organizations/{organization}/oidc/trust-policies/{policy_id}/
# operationId: update_trust_policy
# --scope_claims shape: {project:gateway_proxy?: record}
export def "ui-api-organizations-oidc-trust-policies policy-by-policy_id-organization-1" [
  policy_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  provider: any
  claims: record
  allowed_algorithms: list
  scopes: list
  token_ttl_seconds: int
  --scope-claims: record # shape: {project:gateway_proxy?: record}
]: any -> record<id: string, organization_id: string, project_id: any, project_name: any, name: string, provider: any, claims: record, allowed_algorithms: list<string>, scopes: list<string>, token_ttl_seconds: int, active: bool, created_by: any, created_at: string, updated_at: string, scope_claims: record<project_gateway_proxy: record<spending_limit_daily: any, spending_limit_weekly: any, spending_limit_monthly: any, spending_limit_total: any, cache_enabled: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/oidc/trust-policies/($policy_id)/")
  let body = {name: $name, provider: $provider, claims: $claims, allowed_algorithms: $allowed_algorithms, scopes: $scopes, token_ttl_seconds: $token_ttl_seconds, scope_claims: $scope_claims} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Trust Policy
#
# DELETE /ui-api/organizations/{organization}/oidc/trust-policies/{policy_id}/
# operationId: delete_trust_policy
export def "ui-api-organizations-oidc-trust-policies policy-by-policy_id-organization-2" [
  policy_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/oidc/trust-policies/($policy_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Trust Policy Usage Summary
#
# GET /ui-api/organizations/{organization}/oidc/trust-policies/{policy_id}/usage/
# operationId: get_trust_policy_usage_summary
export def "ui-api-organizations-oidc-trust-policies-usage summary" [
  policy_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<daily: float, weekly: float, monthly: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/oidc/trust-policies/($policy_id)/usage/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set Trust Policy Active
#
# PATCH /ui-api/organizations/{organization}/oidc/trust-policies/{policy_id}/active/
# operationId: set_trust_policy_active
export def "ui-api-organizations-oidc-trust-policies-active active" [
  policy_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
]: any -> record<id: string, organization_id: string, project_id: any, project_name: any, name: string, provider: any, claims: record, allowed_algorithms: list<string>, scopes: list<string>, token_ttl_seconds: int, active: bool, created_by: any, created_at: string, updated_at: string, scope_claims: record<project_gateway_proxy: record<spending_limit_daily: any, spending_limit_weekly: any, spending_limit_monthly: any, spending_limit_total: any, cache_enabled: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/oidc/trust-policies/($policy_id)/active/")
  let body = {active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Workload Scopes
#
# GET /ui-api/organizations/{organization}/oidc/scopes/
# operationId: list_workload_scopes
export def "ui-api-organizations-oidc-scopes scopes" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<scopes: table<id: any, description: string, hint: string, default: bool, project_scoped: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/oidc/scopes/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Token Exchanges
#
# GET /ui-api/organizations/{organization}/oidc/exchanges/
# operationId: list_token_exchanges
export def "ui-api-organizations-oidc-exchanges exchanges" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trust-policy-id: string
  --limit: int # default: 100
  --cursor: string
  --success: string
  --scope: string
  --state: string
  --start-time: string
  --end-time: string
]: nothing -> record<items: table<id: string, trust_policy_id: string, project_id: any, scopes: list, token_jti: any, expires_at: any, expired: bool, success: bool, failure_reason: any, ip_address: any, created_at: string, revoked_at: any>, next_cursor: any, prev_cursor: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "trust_policy_id" $trust_policy_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "success" $success "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/oidc/exchanges/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke Token Exchange
#
# DELETE /ui-api/organizations/{organization}/oidc/exchanges/{exchange_id}/
# operationId: revoke_token_exchange
export def "ui-api-organizations-oidc-exchanges exchange" [
  exchange_id: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/oidc/exchanges/($exchange_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Stripe Checkout Info
#
# GET /ui-api/organizations/{organization}/stripe-checkout-info/
# operationId: get_stripe_checkout_info
export def "ui-api-organizations-stripe-checkout-info info" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --session-id: string
]: nothing -> record<organization_name: string, plan: string, is_first_paid_upgrade: bool, is_org_resubscription: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "session_id" $session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/stripe-checkout-info/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Oauth Client Scopes
#
# GET /ui-api/oauth-clients/scopes/
# operationId: list_oauth_client_scopes
export def "ui-api-oauth-clients-scopes scopes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: any, description: string, hint: string, default: bool, project_scoped: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/oauth-clients/scopes/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Platform Config
#
# GET /ui-api/platform-config/
# operationId: get_platform_config
export def "ui-api-platform-config config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allow_signups: bool, allow_organization_creation: bool, ai_enabled: bool, on_prem: bool, materialize_dashboards: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/platform-config/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Project Agent Summary
#
# GET /ui-api/organizations/{organization}/projects/{project}/agents/summary/
# operationId: get_project_agent_summary
export def "ui-api-organizations-projects-agents-summary summary" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deployment-environment: string
  --age-minutes: int # default: 10080
  --min-timestamp: string
  --max-timestamp: string
]: nothing -> table<name: string, description: any, run_count: int, total_input_tokens: int, total_output_tokens: int, avg_duration_ms: float, exception_count: int, total_cost: float, last_active: string, model: any, system: any, detail_buckets: list<string>, detail_counts: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deployment_environment" $deployment_environment "scalar") (serialize-qp "age_minutes" $age_minutes "scalar") (serialize-qp "min_timestamp" $min_timestamp "scalar") (serialize-qp "max_timestamp" $max_timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/agents/summary/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Project Agent Traces
#
# GET /ui-api/organizations/{organization}/projects/{project}/agents/traces/
# operationId: get_project_agent_traces
export def "ui-api-organizations-projects-agents-traces traces" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --agent-name: string
  --limit: int # default: 20
  --q: string
  --deployment-environment: string
  --age-minutes: int # default: 10080
  --min-timestamp: string
  --max-timestamp: string
]: nothing -> table<trace_id: string, span_id: string, parent_span_id: any, span_name: string, start_timestamp: string, duration_ms: any, agent_name: any, model: any, provider: any, system: any, tokens_in: int, tokens_out: int, is_exception: bool, otel_status_code: any, message: any, operation_name: any, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agent_name" $agent_name "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "deployment_environment" $deployment_environment "scalar") (serialize-qp "age_minutes" $age_minutes "scalar") (serialize-qp "min_timestamp" $min_timestamp "scalar") (serialize-qp "max_timestamp" $max_timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/agents/traces/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Project Agent All Traces
#
# GET /ui-api/organizations/{organization}/projects/{project}/agents/traces/all/
# operationId: get_project_agent_all_traces
export def "ui-api-organizations-projects-agents-traces-all traces" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 20
  --deployment-environment: string
  --age-minutes: int # default: 10080
  --min-timestamp: string
  --max-timestamp: string
]: nothing -> table<trace_id: string, span_id: string, parent_span_id: any, span_name: string, start_timestamp: string, duration_ms: any, agent_name: any, model: any, provider: any, system: any, tokens_in: int, tokens_out: int, is_exception: bool, otel_status_code: any, message: any, operation_name: any, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "deployment_environment" $deployment_environment "scalar") (serialize-qp "age_minutes" $age_minutes "scalar") (serialize-qp "min_timestamp" $min_timestamp "scalar") (serialize-qp "max_timestamp" $max_timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/agents/traces/all/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Project Agent Timeseries
#
# GET /ui-api/organizations/{organization}/projects/{project}/agents/timeseries/
# operationId: get_project_agent_timeseries
export def "ui-api-organizations-projects-agents-timeseries timeseries" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --agent-name: string
  --deployment-environment: string
  --interval: string
  --age-minutes: int # default: 10080
  --min-timestamp: string
  --max-timestamp: string
]: nothing -> table<bucket: string, run_count: int, tokens_in: int, tokens_out: int, cache_write_tokens: int, cache_read_tokens: int, latency_ms: float, error_count: int, cost: float, avg_turns: float, p90_turns: float, avg_tool_calls: float, p90_tool_calls: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agent_name" $agent_name "scalar") (serialize-qp "deployment_environment" $deployment_environment "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "age_minutes" $age_minutes "scalar") (serialize-qp "min_timestamp" $min_timestamp "scalar") (serialize-qp "max_timestamp" $max_timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/agents/timeseries/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Project Agent Info
#
# GET /ui-api/organizations/{organization}/projects/{project}/agents/info/
# operationId: get_project_agent_info
export def "ui-api-organizations-projects-agents-info info" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --agent-name: string
  --limit: int # default: 50
  --deployment-environment: string
  --age-minutes: int # default: 10080
  --min-timestamp: string
  --max-timestamp: string
]: nothing -> record<tool_definitions: table<span_id: string, start_timestamp: string, tool_definitions_json: any>, system_instructions_json: any, input_messages_json: any, model_settings: any, sampled_at: any, sampled_run_trace_id: any, sampled_run_span_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agent_name" $agent_name "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "deployment_environment" $deployment_environment "scalar") (serialize-qp "age_minutes" $age_minutes "scalar") (serialize-qp "min_timestamp" $min_timestamp "scalar") (serialize-qp "max_timestamp" $max_timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/agents/info/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Project Agent Managed Variables Used
#
# GET /ui-api/organizations/{organization}/projects/{project}/agents/managed-variables-used/
# operationId: get_project_agent_managed_variables_used
export def "ui-api-organizations-projects-agents-managed-variables-used used" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --agent-name: string
  --deployment-environment: string
  --age-minutes: int # default: 10080
  --min-timestamp: string
  --max-timestamp: string
]: nothing -> table<name: string, label: any, run_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agent_name" $agent_name "scalar") (serialize-qp "deployment_environment" $deployment_environment "scalar") (serialize-qp "age_minutes" $age_minutes "scalar") (serialize-qp "min_timestamp" $min_timestamp "scalar") (serialize-qp "max_timestamp" $max_timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/agents/managed-variables-used/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Agent Optimizer Evidence Preview Route
#
# GET /ui-api/organizations/{organization}/projects/{project}/agents/optimizer/evidence-preview/
# operationId: get_agent_optimizer_evidence_preview_route
export def "ui-api-organizations-projects-agents-optimizer-evidence-preview route" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --agent-name: string
  --max-candidate-spans: int # default: 500
  --lookback-minutes: int # default: 10080
  --deployment-environment: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agent_name" $agent_name "scalar") (serialize-qp "max_candidate_spans" $max_candidate_spans "scalar") (serialize-qp "lookback_minutes" $lookback_minutes "scalar") (serialize-qp "deployment_environment" $deployment_environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/agents/optimizer/evidence-preview/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stream Agent Optimizer Proposal Route
#
# POST /ui-api/organizations/{organization}/projects/{project}/agents/optimizer/proposal/stream/
# operationId: stream_agent_optimizer_proposal_route
export def "ui-api-organizations-projects-agents-optimizer-proposal-stream route" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deployment-environment: string
  agent_name: string
  --max-candidate-spans: int
  --lookback-minutes: int
  --evidence-snapshot: any
  --refinement-instructions: any
  --previous-proposed-value: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deployment_environment" $deployment_environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/agents/optimizer/proposal/stream/" $qp)
  let body = {agent_name: $agent_name, max_candidate_spans: $max_candidate_spans, lookback_minutes: $lookback_minutes, evidence_snapshot: $evidence_snapshot, refinement_instructions: $refinement_instructions, previous_proposed_value: $previous_proposed_value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Agent Customizations
#
# GET /ui-api/organizations/{organization}/projects/{project}/agents/customizations/
# operationId: get_agent_customizations
export def "ui-api-organizations-projects-agents-customizations customizations" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, project_id: string, agent_name: string, icon_emoji: any, icon_color: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/agents/customizations/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upsert Agent Customization
#
# PUT /ui-api/organizations/{organization}/projects/{project}/agents/customizations/
# operationId: upsert_agent_customization
export def "ui-api-organizations-projects-agents-customizations customization-by-organization-project" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  agent_name: string
  --icon-emoji: string
  --icon-color: string
]: any -> record<id: string, project_id: string, agent_name: string, icon_emoji: any, icon_color: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/agents/customizations/")
  let body = {agent_name: $agent_name, icon_emoji: $icon_emoji, icon_color: $icon_color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Agent Customization
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/agents/customizations/
# operationId: delete_agent_customization
export def "ui-api-organizations-projects-agents-customizations customization-by-organization-project-1" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --agent-name: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agent_name" $agent_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/agents/customizations/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Conversations
#
# GET /ui-api/organizations/{organization}/projects/{project}/ai-chat-conversations/
# operationId: list_conversations
export def "ui-api-organizations-projects-ai-chat-conversations conversations" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: string, project_id: any, created_by: string, title: string, message_count: int, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/ai-chat-conversations/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Conversation
#
# POST /ui-api/organizations/{organization}/projects/{project}/ai-chat-conversations/
# operationId: create_conversation
export def "ui-api-organizations-projects-ai-chat-conversations conversation-by-project-organization" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string
]: any -> record<id: string, organization_id: string, project_id: any, created_by: string, title: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/ai-chat-conversations/")
  let body = {title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Conversation
#
# GET /ui-api/organizations/{organization}/projects/{project}/ai-chat-conversations/{conversation_id}/
# operationId: get_conversation
export def "ui-api-organizations-projects-ai-chat-conversations conversation-by-conversation_id-project-organization" [
  conversation_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<conversation: record<id: string, organization_id: string, project_id: any, created_by: string, title: string, created_at: string, updated_at: string>, messages: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/ai-chat-conversations/($conversation_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Conversation
#
# PATCH /ui-api/organizations/{organization}/projects/{project}/ai-chat-conversations/{conversation_id}/
# operationId: update_conversation
export def "ui-api-organizations-projects-ai-chat-conversations conversation-by-conversation_id-project-organization-1" [
  conversation_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string
]: any -> record<id: string, organization_id: string, project_id: any, created_by: string, title: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/ai-chat-conversations/($conversation_id)/")
  let body = {title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Conversation
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/ai-chat-conversations/{conversation_id}/
# operationId: delete_conversation
export def "ui-api-organizations-projects-ai-chat-conversations conversation-by-conversation_id-project-organization-2" [
  conversation_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/ai-chat-conversations/($conversation_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stream Message
#
# POST /ui-api/organizations/{organization}/projects/{project}/ai-chat-conversations/messages/
# operationId: stream_message
export def "ui-api-organizations-projects-ai-chat-conversations-messages message" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conversation-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "conversation_id" $conversation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/ai-chat-conversations/messages/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Project Oauth Scopes
#
# GET /ui-api/organizations/{organization}/projects/{project}/api-keys/scopes/
# operationId: list_project_oauth_scopes
export def "ui-api-organizations-projects-api-keys-scopes scopes" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: any, description: string, hint: string, default: bool, project_scoped: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/api-keys/scopes/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Project Api Keys
#
# GET /ui-api/organizations/{organization}/projects/{project}/api-keys/
# operationId: list_project_api_keys
export def "ui-api-organizations-projects-api-keys keys" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: string, name: string, description: any, scopes: list<string>, project_id: any, project_name: any, all_projects: bool, created_by: any, created_by_name: any, created_at: string, last_used_at: any, expires_at: any, user_id: any, active: bool, updated_at: any, updated_by: any, claims: record<project_gateway_proxy: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/api-keys/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Project Api Key
#
# POST /ui-api/organizations/{organization}/projects/{project}/api-keys/
# operationId: create_project_api_key
# --claims shape: {project:gateway_proxy?: record}
export def "ui-api-organizations-projects-api-keys key-by-organization-project" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  description: any
  scopes: list
  --claims: record # shape: {project:gateway_proxy?: record}
  --expires-at: any
  --is-personal: oneof<nothing, bool>
]: any -> record<api_key: record<id: string, organization_id: string, name: string, description: any, scopes: list<string>, project_id: any, project_name: any, all_projects: bool, created_by: any, created_by_name: any, created_at: string, last_used_at: any, expires_at: any, user_id: any, active: bool, updated_at: any, updated_by: any, claims: record<project_gateway_proxy: record>>, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/api-keys/")
  let body = {name: $name, description: $description, scopes: $scopes, claims: $claims, expires_at: $expires_at, is_personal: $is_personal} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Project Api Key
#
# PATCH /ui-api/organizations/{organization}/projects/{project}/api-keys/{api_key_id}/
# operationId: update_project_api_key
export def "ui-api-organizations-projects-api-keys key-by-api_key_id-organization-project" [
  api_key_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --description: any
]: any -> record<id: string, organization_id: string, name: string, description: any, scopes: list<string>, project_id: any, project_name: any, all_projects: bool, created_by: any, created_by_name: any, created_at: string, last_used_at: any, expires_at: any, user_id: any, active: bool, updated_at: any, updated_by: any, claims: record<project_gateway_proxy: record<spending_limit_daily: any, spending_limit_weekly: any, spending_limit_monthly: any, spending_limit_total: any, cache_enabled: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/api-keys/($api_key_id)/")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Project Api Key
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/api-keys/{api_key_id}/
# operationId: delete_project_api_key
export def "ui-api-organizations-projects-api-keys key-by-api_key_id-organization-project-1" [
  api_key_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/api-keys/($api_key_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Project Api Key Claims
#
# PATCH /ui-api/organizations/{organization}/projects/{project}/api-keys/{api_key_id}/claims/
# operationId: update_project_api_key_claims
# --claims shape: {project:gateway_proxy?: record}
export def "ui-api-organizations-projects-api-keys-claims claims" [
  api_key_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  claims: record # shape: {project:gateway_proxy?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/api-keys/($api_key_id)/claims/")
  let body = {claims: $claims} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke Project Api Key
#
# POST /ui-api/organizations/{organization}/projects/{project}/api-keys/{api_key_id}/revoke/
# operationId: revoke_project_api_key
export def "ui-api-organizations-projects-api-keys-revoke key" [
  api_key_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/api-keys/($api_key_id)/revoke/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reactivate Project Api Key
#
# POST /ui-api/organizations/{organization}/projects/{project}/api-keys/{api_key_id}/reactivate/
# operationId: reactivate_project_api_key
export def "ui-api-organizations-projects-api-keys-reactivate key" [
  api_key_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/api-keys/($api_key_id)/reactivate/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Alerts
#
# GET /ui-api/organizations/{organization}/projects/{project}/alerts/
# operationId: list_alerts
export def "ui-api-organizations-projects-alerts alerts" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: string, project_id: string, created_at: string, updated_at: any, created_by_name: any, updated_by_name: any, name: string, description: any, query: string, time_window: string, frequency: string, watermark: string, channels: list<record>, notify_when: string, active: bool, last_run: any, has_matches: any, has_errors: any, result: any, result_length: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/alerts/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Alert
#
# POST /ui-api/organizations/{organization}/projects/{project}/alerts/
# operationId: create_alert
export def "ui-api-organizations-projects-alerts alert-by-organization-project" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  description: string
  --body-query: any
  time_window: string # format: duration
  frequency: string # format: duration
  watermark: string # format: duration
  --active: oneof<nothing, bool> # Whether the alert starts enabled. (default: true)
  --channel-ids: any # Legacy shorthand for assigning channels without schedules.
  --channel-assignments: any # Schedule-aware channel configuration. When both `channel_assignments` and `channel_ids` are provided, `channel_assignments` is used.
  notify_when: string@notify-when-completer
]: any -> record<id: string, organization_id: string, project_id: string, created_at: string, updated_at: any, created_by_name: any, updated_by_name: any, name: string, description: any, query: string, time_window: string, frequency: string, watermark: string, channels: table<id: string, organization_id: string, label: string, active: bool, created_at: string, updated_at: any, created_by_name: any, updated_by_name: any, config: any, schedule_id: any>, notify_when: string, active: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/alerts/")
  let body = {name: $name, description: $description, query: $body_query, time_window: $time_window, frequency: $frequency, watermark: $watermark, active: $active, channel_ids: $channel_ids, channel_assignments: $channel_assignments, notify_when: $notify_when} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Alert
#
# PUT /ui-api/organizations/{organization}/projects/{project}/alerts/{alert_id}/
# operationId: update_alert
# --channel_assignments item shape: {channel_id: string, schedule_id?: any}
export def "ui-api-organizations-projects-alerts alert-by-alert_id-organization-project" [
  alert_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --description: string
  --time-window: string # format: duration
  --frequency: string # format: duration
  --watermark: string # format: duration
  --active: oneof<nothing, bool>
  --body-query: string
  --channel-ids: any # Legacy shorthand for assigning channels without schedules.
  --channel-assignments: list # Schedule-aware channel configuration. When both `channel_assignments` and `channel_ids` are provided, `channel_assignments` is used. — item shape: {channel_id: string, schedule_id?: any}
  --notify-when: string@notify-when-completer
]: any -> record<id: string, organization_id: string, project_id: string, created_at: string, updated_at: any, created_by_name: any, updated_by_name: any, name: string, description: any, query: string, time_window: string, frequency: string, watermark: string, channels: table<id: string, organization_id: string, label: string, active: bool, created_at: string, updated_at: any, created_by_name: any, updated_by_name: any, config: any, schedule_id: any>, notify_when: string, active: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/alerts/($alert_id)/")
  let body = {name: $name, description: $description, time_window: $time_window, frequency: $frequency, watermark: $watermark, active: $active, query: $body_query, channel_ids: $channel_ids, channel_assignments: $channel_assignments, notify_when: $notify_when} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Alert
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/alerts/{alert_id}/
# operationId: delete_alert
export def "ui-api-organizations-projects-alerts alert-by-alert_id-organization-project-1" [
  alert_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/alerts/($alert_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Alert
#
# GET /ui-api/organizations/{organization}/projects/{project}/alerts/{alert_id}/
# operationId: get_alert
export def "ui-api-organizations-projects-alerts alert-by-alert_id-organization-project-2" [
  alert_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, organization_id: string, project_id: string, created_at: string, updated_at: any, created_by_name: any, updated_by_name: any, name: string, description: any, query: string, time_window: string, frequency: string, watermark: string, channels: table<id: string, organization_id: string, label: string, active: bool, created_at: string, updated_at: any, created_by_name: any, updated_by_name: any, config: any, schedule_id: any>, notify_when: string, active: bool, last_run: any, has_matches: any, has_errors: any, result: any, result_length: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/alerts/($alert_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Alert Run
#
# GET /ui-api/organizations/{organization}/projects/{project}/alerts/{alert_id}/run/{alert_run_id}/
# operationId: get_alert_run
export def "ui-api-organizations-projects-alerts-run run" [
  alert_id: string
  alert_run_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, alert_id: string, created_at: string, channels: table<id: string, last_delivery_at: any, status_code: any, message: any>, query: string, window_min: string, window_max: string, status: string, run_started_at: any, run_finished_at: any, result: any, has_matches: any, has_errors: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/alerts/($alert_id)/run/($alert_run_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Alert History
#
# GET /ui-api/organizations/{organization}/projects/{project}/alerts/{alert_id}/history/
# operationId: get_alert_history
export def "ui-api-organizations-projects-alerts-history history" [
  alert_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-timestamp: string # format: date-time
  --end-timestamp: string # format: date-time
  --limit: int # default: 100
  --offset: int # default: 0
  --filter-matches: oneof<nothing, bool> # default: false
]: nothing -> record<filtered_alert_runs: table<id: string, alert_id: string, created_at: string, channels: list, query: string, window_min: string, window_max: string, status: string, run_started_at: any, run_finished_at: any, result: any, has_matches: any, has_errors: any>, total_runs: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_timestamp" $start_timestamp "scalar") (serialize-qp "end_timestamp" $end_timestamp "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter_matches" $filter_matches "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/alerts/($alert_id)/history/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Alert Timeline
#
# GET /ui-api/organizations/{organization}/projects/{project}/alerts/{alert_id}/timeline/
# operationId: get_alert_timeline
export def "ui-api-organizations-projects-alerts-timeline timeline" [
  alert_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-timestamp: string # format: date-time
  --end-timestamp: string # format: date-time
]: nothing -> table<name: string, window_max: string, prev_window_max: any, alert_id: string, new_query: any, old_query: any, new_matches: any, old_matches: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_timestamp" $start_timestamp "scalar") (serialize-qp "end_timestamp" $end_timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/alerts/($alert_id)/timeline/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get User Alert Notification
#
# GET /ui-api/organizations/{organization}/projects/{project}/alerts/{alert_id}/notifications/
# operationId: get_user_alert_notification
export def "ui-api-organizations-projects-alerts-notifications notification-by-alert_id-organization-project" [
  alert_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<is_muted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/alerts/($alert_id)/notifications/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update User Alert Notification
#
# PUT /ui-api/organizations/{organization}/projects/{project}/alerts/{alert_id}/notifications/
# operationId: update_user_alert_notification
export def "ui-api-organizations-projects-alerts-notifications notification-by-alert_id-organization-project-1" [
  alert_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-muted: oneof<nothing, bool>
]: any -> record<is_muted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/alerts/($alert_id)/notifications/")
  let body = {is_muted: $is_muted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Record Annotation From Ui
#
# POST /ui-api/organizations/{organization}/projects/{project}/annotation/
# operationId: record_annotation_from_ui
export def "ui-api-organizations-projects-annotation ui-by-project-organization" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  trace_id: string
  span_id: string
  name: string
  value: any
  --comment: any
  --extra: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/annotation/")
  let body = {trace_id: $trace_id, span_id: $span_id, name: $name, value: $value, comment: $comment, extra: $extra} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Annotation From Ui
#
# PUT /ui-api/organizations/{organization}/projects/{project}/annotation/
# operationId: update_annotation_from_ui
export def "ui-api-organizations-projects-annotation ui-by-project-organization-1" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  trace_id: string
  span_id: string
  name: string
  value: any
  --comment: any
  --extra: any
  annotation_id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/annotation/")
  let body = {trace_id: $trace_id, span_id: $span_id, name: $name, value: $value, comment: $comment, extra: $extra, annotation_id: $annotation_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Annotation From Ui
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/annotation/
# operationId: delete_annotation_from_ui
export def "ui-api-organizations-projects-annotation ui-by-project-organization-2" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  trace_id: string
  span_id: string
  name: string
  annotation_id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/annotation/")
  let body = {trace_id: $trace_id, span_id: $span_id, name: $name, annotation_id: $annotation_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Autocomplete Records Get
#
# GET /ui-api/organizations/{organization}/projects/{project}/autocomplete/records/
# operationId: autocomplete_records_get
export def "ui-api-organizations-projects-autocomplete-records get" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tags: list<string>, span_names: list<string>, attribute_keys: list<string>, otel_scope_names: list<string>, service_names: list<string>, otel_resource_attribute_keys: list<string>, deployment_environments: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/autocomplete/records/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Autocomplete Metrics Get
#
# GET /ui-api/organizations/{organization}/projects/{project}/autocomplete/metrics/
# operationId: autocomplete_metrics_get
export def "ui-api-organizations-projects-autocomplete-metrics get" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<metrics: table<metric_name: string, metric_type: string, unit: string>, attribute_keys: list<string>, otel_scope_names: list<string>, service_names: list<string>, otel_resource_attribute_keys: list<string>, deployment_environments: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/autocomplete/metrics/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Schemas
#
# GET /ui-api/organizations/{organization}/projects/{project}/autocomplete/schemas/
# operationId: get_schemas
export def "ui-api-organizations-projects-autocomplete-schemas schemas" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tables: table<name: string, description: string, schema: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/autocomplete/schemas/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Channel
#
# POST /ui-api/organizations/{organization}/projects/{project}/channels/
# operationId: create_channel
export def "ui-api-organizations-projects-channels channel-by-organization-project" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  label: string
  config: any
]: any -> record<id: string, organization_id: string, label: string, active: bool, created_at: string, updated_at: any, created_by_name: any, updated_by_name: any, config: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/channels/")
  let body = {label: $label, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Channels
#
# GET /ui-api/organizations/{organization}/projects/{project}/channels/
# operationId: list_channels
export def "ui-api-organizations-projects-channels channels" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: string, label: string, active: bool, created_at: string, updated_at: any, created_by_name: any, updated_by_name: any, config: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/channels/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Try Webhook Channel
#
# POST /ui-api/organizations/{organization}/projects/{project}/channels/try-webhook/
# Discriminator (request): type = webhook, opsgenie
# operationId: try_webhook_channel
export def "ui-api-organizations-projects-channels-try-webhook channel" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --variant: string@variant-completer
  type: string@type-completer
  --format: string@format-completer
  --body-url: string
  --auth-key: string
  --body-base-url: string
]: any -> record<kind: string, succeeded: bool, trace_id: string, status_code: any, message: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variant" $variant "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/channels/try-webhook/" $qp)
  let body = {type: $type, format: $format, url: $body_url, auth_key: $auth_key, base_url: $body_base_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Example Webhook Payload
#
# POST /ui-api/organizations/{organization}/projects/{project}/channels/example-webhook-payload/
# Discriminator (request): type = webhook, opsgenie
# operationId: get_example_webhook_payload
export def "ui-api-organizations-projects-channels-example-webhook-payload payload" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --variant: string@variant-completer
  type: string@type-completer
  --format: string@format-completer
  --body-url: string
  --auth-key: string
  --body-base-url: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variant" $variant "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/channels/example-webhook-payload/" $qp)
  let body = {type: $type, format: $format, url: $body_url, auth_key: $auth_key, base_url: $body_base_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Channel
#
# GET /ui-api/organizations/{organization}/projects/{project}/channels/{channel_id}/
# operationId: get_channel
export def "ui-api-organizations-projects-channels channel-by-channel_id-organization-project" [
  channel_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, organization_id: string, label: string, active: bool, created_at: string, updated_at: any, created_by_name: any, updated_by_name: any, config: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/channels/($channel_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Channel
#
# PUT /ui-api/organizations/{organization}/projects/{project}/channels/{channel_id}/
# operationId: update_channel
export def "ui-api-organizations-projects-channels channel-by-channel_id-organization-project-1" [
  channel_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: any
  --config: any
  --active: any
]: any -> record<id: string, organization_id: string, label: string, active: bool, created_at: string, updated_at: any, created_by_name: any, updated_by_name: any, config: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/channels/($channel_id)/")
  let body = {label: $label, config: $config, active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Channel
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/channels/{channel_id}/
# operationId: delete_channel
export def "ui-api-organizations-projects-channels channel-by-channel_id-organization-project-2" [
  channel_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/channels/($channel_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Panels
#
# GET /ui-api/organizations/{organization}/projects/{project}/panels/
# operationId: get_panels
export def "ui-api-organizations-projects-panels panels" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, project_id: string, name: string, description: string, created_at: string, updated_at: string, source_code: string, transpiled_code: string, config: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/panels/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Panel
#
# POST /ui-api/organizations/{organization}/projects/{project}/panels/create/
# operationId: create_panel
export def "ui-api-organizations-projects-panels-create panel" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  description: string
  source_code: string
  transpiled_code: string
  config: any
]: any -> record<id: string, project_id: string, name: string, description: string, created_at: string, updated_at: string, source_code: string, transpiled_code: string, config: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/panels/create/")
  let body = {name: $name, description: $description, source_code: $source_code, transpiled_code: $transpiled_code, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Panel
#
# PUT /ui-api/organizations/{organization}/projects/{project}/panels/update/
# operationId: update_panel
export def "ui-api-organizations-projects-panels-update panel" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  description: string
  source_code: string
  transpiled_code: string
  config: any
]: any -> record<id: string, project_id: string, name: string, description: string, created_at: string, updated_at: string, source_code: string, transpiled_code: string, config: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/panels/update/")
  let body = {name: $name, description: $description, source_code: $source_code, transpiled_code: $transpiled_code, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Panel
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/panels/delete/
# operationId: delete_panel
export def "ui-api-organizations-projects-panels-delete panel" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/panels/delete/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Dashboards
#
# GET /ui-api/organizations/{organization}/projects/{project}/dashboards/
# operationId: list_dashboards
export def "ui-api-organizations-projects-dashboards dashboards" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, project_id: string, created_at: string, updated_at: any, created_by_name: any, updated_by_name: any, dashboard_name: string, dashboard_slug: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/dashboards/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Dashboard
#
# POST /ui-api/organizations/{organization}/projects/{project}/dashboards/
# operationId: create_dashboard
# --definition shape: {kind: string, metadata: record, spec: record}
export def "ui-api-organizations-projects-dashboards dashboard-by-organization-project" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  slug: string
  definition: record # shape: {kind: string, metadata: record, spec: record}
]: any -> record<id: string, project_id: string, created_at: string, updated_at: any, created_by_name: any, updated_by_name: any, dashboard_name: string, dashboard_slug: string, version: int, definition: record<kind: string, metadata: record<name: string, createdAt: string, updatedAt: string, version: int, project: string>, spec: record<display: any, datasources: record, variables: list, panels: any, layouts: list, duration: any, refreshInterval: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/dashboards/")
  let body = {name: $name, slug: $slug, definition: $definition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Dashboard
#
# GET /ui-api/organizations/{organization}/projects/{project}/dashboards/{dashboard_slug}/
# operationId: get_dashboard
export def "ui-api-organizations-projects-dashboards dashboard-by-dashboard_slug-organization-project" [
  dashboard_slug: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dashboard: record<kind: string, metadata: record<name: string, createdAt: string, updatedAt: string, version: int, project: string>, spec: record<display: any, datasources: record, variables: list, panels: any, layouts: list, duration: any, refreshInterval: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/dashboards/($dashboard_slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Dashboard
#
# PUT /ui-api/organizations/{organization}/projects/{project}/dashboards/{dashboard_slug}/
# operationId: update_dashboard
export def "ui-api-organizations-projects-dashboards dashboard-by-dashboard_slug-organization-project-1" [
  dashboard_slug: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: any
  --definition: any
  --version: any
]: any -> record<id: string, project_id: string, created_at: string, updated_at: any, created_by_name: any, updated_by_name: any, dashboard_name: string, dashboard_slug: string, version: int, definition: record<kind: string, metadata: record<name: string, createdAt: string, updatedAt: string, version: int, project: string>, spec: record<display: any, datasources: record, variables: list, panels: any, layouts: list, duration: any, refreshInterval: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/dashboards/($dashboard_slug)/")
  let body = {name: $name, definition: $definition, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Dashboard
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/dashboards/{dashboard_slug}/
# operationId: delete_dashboard
export def "ui-api-organizations-projects-dashboards dashboard-by-dashboard_slug-organization-project-2" [
  dashboard_slug: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/dashboards/($dashboard_slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Dashboard Panels And Layouts
#
# PUT /ui-api/organizations/{organization}/projects/{project}/dashboards/{dashboard_slug}/panels-and-layouts/
# operationId: update_dashboard_panels_and_layouts
# --layouts item shape: {kind: string, spec: record}
export def "ui-api-organizations-projects-dashboards-panels-and-layouts layouts" [
  dashboard_slug: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  panels: any
  layouts: list # item shape: {kind: string, spec: record}
  --version: any
]: any -> record<id: string, project_id: string, created_at: string, updated_at: any, created_by_name: any, updated_by_name: any, dashboard_name: string, dashboard_slug: string, version: int, definition: record<kind: string, metadata: record<name: string, createdAt: string, updatedAt: string, version: int, project: string>, spec: record<display: any, datasources: record, variables: list, panels: any, layouts: list, duration: any, refreshInterval: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/dashboards/($dashboard_slug)/panels-and-layouts/")
  let body = {panels: $panels, layouts: $layouts, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Dashboard Variables
#
# PUT /ui-api/organizations/{organization}/projects/{project}/dashboards/{dashboard_slug}/variables/
# operationId: update_dashboard_variables
export def "ui-api-organizations-projects-dashboards-variables variables" [
  dashboard_slug: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-variables: list
  --version: any
]: any -> record<id: string, project_id: string, created_at: string, updated_at: any, created_by_name: any, updated_by_name: any, dashboard_name: string, dashboard_slug: string, version: int, definition: record<kind: string, metadata: record<name: string, createdAt: string, updatedAt: string, version: int, project: string>, spec: record<display: any, datasources: record, variables: list, panels: any, layouts: list, duration: any, refreshInterval: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/dashboards/($dashboard_slug)/variables/")
  let body = {variables: $body_variables, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate View
#
# POST /ui-api/organizations/{organization}/projects/{project}/enhanced-json-views/generate/
# operationId: generate_view
export def "ui-api-organizations-projects-enhanced-json-views-generate view" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  json_data: record
  --refinement-prompt: any
  --existing-jsx: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/enhanced-json-views/generate/")
  let body = {json_data: $json_data, refinement_prompt: $refinement_prompt, existing_jsx: $existing_jsx} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get View
#
# GET /ui-api/organizations/{organization}/projects/{project}/enhanced-json-views/
# operationId: get_view
export def "ui-api-organizations-projects-enhanced-json-views view-by-project-organization" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema-fingerprint: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "schema_fingerprint" $schema_fingerprint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/enhanced-json-views/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Save View
#
# PUT /ui-api/organizations/{organization}/projects/{project}/enhanced-json-views/
# operationId: save_view
export def "ui-api-organizations-projects-enhanced-json-views view-by-project-organization-1" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  schema_fingerprint: string
  json_schema: record
  jsx_source: string
  transpiled_code: string
  --sample-data: any
]: any -> record<id: string, project_id: string, schema_fingerprint: string, json_schema: any, jsx_source: string, transpiled_code: string, sample_data: any, created_by: any, updated_by: any, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/enhanced-json-views/")
  let body = {schema_fingerprint: $schema_fingerprint, json_schema: $json_schema, jsx_source: $jsx_source, transpiled_code: $transpiled_code, sample_data: $sample_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Views
#
# GET /ui-api/organizations/{organization}/projects/{project}/enhanced-json-views/list/
# operationId: list_views
export def "ui-api-organizations-projects-enhanced-json-views-list views" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, project_id: string, schema_fingerprint: string, json_schema: any, jsx_source: string, transpiled_code: string, sample_data: any, created_by: any, updated_by: any, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/enhanced-json-views/list/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete View
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/enhanced-json-views/{view_id}/
# operationId: delete_view
export def "ui-api-organizations-projects-enhanced-json-views view-by-view_id-project-organization" [
  view_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/enhanced-json-views/($view_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch Query Records
#
# POST /ui-api/organizations/{organization}/projects/{project}/fetch-query/
# operationId: fetch_query_records
# --columns item shape: {name: string, expression?: any}
export def "ui-api-organizations-projects-fetch-query records" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --columns: list # List of columns to select, optionally as an expression with an alias (e.g. `select attributes->>'foo' as foo` -> [('foo', 'attributes->>'foo')] — item shape: {name: string, expression?: any}
  --body-where: string # SQL WHERE clause to filter the records. The clause should be in the form of a SQL expression, e.g. `service_name = 'my-service'` (default: true)
  --tab-hidden: oneof<nothing, bool>
  --min-start-timestamp: string # format: date-time
  --max-start-timestamp: string # format: date-time
  order: string@order-completer
  --limit: int
  --timezone: string
  --trace-limit: int
  --last-span: list
  --include-ancestors: oneof<nothing, bool>
  --deployment-environment: list
  --table: string
  --exclude-trace-ids: list
]: any -> record<result_spans: table<start_timestamp: string, trace_id: string, span_id: string, parent_span_id: any, span_name: string, level: any, service_name: string, otel_scope_name: any, tags: list, created_at: string, end_timestamp: string, kind: string, message: string, is_exception: bool, exception_type: any, otel_scope_version: any, service_version: any, http_response_status_code: any, gen_ai_operation_name: any, gen_ai_request_model: any, gen_ai_response_model: any, gen_ai_system: any, gen_ai_usage_input_tokens: any, gen_ai_usage_output_tokens: any, gen_ai_response_id: any, operation_cost: any, user_columns: record, matched_filter: bool>, extra_spans: table<start_timestamp: string, trace_id: string, span_id: string, parent_span_id: any, span_name: string, level: any, service_name: string, otel_scope_name: any, tags: list, created_at: string, end_timestamp: string, kind: string, message: string, is_exception: bool, exception_type: any, otel_scope_version: any, service_version: any, http_response_status_code: any, gen_ai_operation_name: any, gen_ai_request_model: any, gen_ai_response_model: any, gen_ai_system: any, gen_ai_usage_input_tokens: any, gen_ai_usage_output_tokens: any, gen_ai_response_id: any, operation_cost: any, user_columns: record, matched_filter: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/fetch-query/")
  let body = {columns: $columns, where: $body_where, tab_hidden: $tab_hidden, min_start_timestamp: $min_start_timestamp, max_start_timestamp: $max_start_timestamp, order: $order, limit: $limit, timezone: $timezone, trace_limit: $trace_limit, last_span: $last_span, include_ancestors: $include_ancestors, deployment_environment: $deployment_environment, table: $table, exclude_trace_ids: $exclude_trace_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch Ancestor Records
#
# POST /ui-api/organizations/{organization}/projects/{project}/fetch-ancestors/
# operationId: fetch_ancestor_records
# --columns item shape: {name: string, expression?: any}
export def "ui-api-organizations-projects-fetch-ancestors records" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --columns: list # List of columns to select, optionally as an expression with an alias (e.g. `select attributes->>'foo' as foo` -> [('foo', 'attributes->>'foo')] — item shape: {name: string, expression?: any}
  --body-where: string # SQL WHERE clause to filter the records. The clause should be in the form of a SQL expression, e.g. `service_name = 'my-service'` (default: true)
  --tab-hidden: oneof<nothing, bool>
  ancestors: list
  min_start_timestamp: string # format: date-time
  --max-start-timestamp: string # format: date-time
  --deployment-environment: list
  --timezone: string
  --table: string
]: any -> record<spans: table<start_timestamp: string, trace_id: string, span_id: string, parent_span_id: any, span_name: string, level: any, service_name: string, otel_scope_name: any, tags: list, created_at: string, end_timestamp: string, kind: string, message: string, is_exception: bool, exception_type: any, otel_scope_version: any, service_version: any, http_response_status_code: any, gen_ai_operation_name: any, gen_ai_request_model: any, gen_ai_response_model: any, gen_ai_system: any, gen_ai_usage_input_tokens: any, gen_ai_usage_output_tokens: any, gen_ai_response_id: any, operation_cost: any, user_columns: record, matched_filter: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/fetch-ancestors/")
  let body = {columns: $columns, where: $body_where, tab_hidden: $tab_hidden, ancestors: $ancestors, min_start_timestamp: $min_start_timestamp, max_start_timestamp: $max_start_timestamp, deployment_environment: $deployment_environment, timezone: $timezone, table: $table} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch Trace
#
# POST /ui-api/organizations/{organization}/projects/{project}/fetch-trace/
# operationId: fetch_trace
# --columns item shape: {name: string, expression?: any}
export def "ui-api-organizations-projects-fetch-trace trace" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --columns: list # List of columns to select, optionally as an expression with an alias (e.g. `select attributes->>'foo' as foo` -> [('foo', 'attributes->>'foo')] — item shape: {name: string, expression?: any}
  --body-where: string # SQL WHERE clause to filter the records. The clause should be in the form of a SQL expression, e.g. `service_name = 'my-service'` (default: true)
  trace_id: string
  --parent-span-id: any
  limit: int
  order_by: string@order-by-completer
  --cursor: list
  --min-start-timestamp: string # format: date-time
  --max-start-timestamp: string # format: date-time
  --deployment-environment: list
  --timezone: string
  --table: string
]: any -> record<spans: table<start_timestamp: string, trace_id: string, span_id: string, parent_span_id: any, span_name: string, level: any, service_name: string, otel_scope_name: any, tags: list, created_at: string, end_timestamp: string, kind: string, message: string, is_exception: bool, exception_type: any, otel_scope_version: any, service_version: any, http_response_status_code: any, gen_ai_operation_name: any, gen_ai_request_model: any, gen_ai_response_model: any, gen_ai_system: any, gen_ai_usage_input_tokens: any, gen_ai_usage_output_tokens: any, gen_ai_response_id: any, operation_cost: any, user_columns: record, matched_filter: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/fetch-trace/")
  let body = {columns: $columns, where: $body_where, trace_id: $trace_id, parent_span_id: $parent_span_id, limit: $limit, order_by: $order_by, cursor: $cursor, min_start_timestamp: $min_start_timestamp, max_start_timestamp: $max_start_timestamp, deployment_environment: $deployment_environment, timezone: $timezone, table: $table} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch Traces Around Trace
#
# POST /ui-api/organizations/{organization}/projects/{project}/fetch-traces-around-trace/
# operationId: fetch_traces_around_trace
# --columns item shape: {name: string, expression?: any}
export def "ui-api-organizations-projects-fetch-traces-around-trace trace" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --columns: list # List of columns to select, optionally as an expression with an alias (e.g. `select attributes->>'foo' as foo` -> [('foo', 'attributes->>'foo')] — item shape: {name: string, expression?: any}
  --body-where: string # SQL WHERE clause to filter the records. The clause should be in the form of a SQL expression, e.g. `service_name = 'my-service'` (default: true)
  trace_id: string
  limit: int
  trace_timestamp: string # format: date-time
  --min-start-timestamp: string # format: date-time
  --max-start-timestamp: string # format: date-time
  --deployment-environment: list
  --timezone: string
  --table: string
]: any -> record<spans: table<start_timestamp: string, trace_id: string, span_id: string, parent_span_id: any, span_name: string, level: any, service_name: string, otel_scope_name: any, tags: list, created_at: string, end_timestamp: string, kind: string, message: string, is_exception: bool, exception_type: any, otel_scope_version: any, service_version: any, http_response_status_code: any, gen_ai_operation_name: any, gen_ai_request_model: any, gen_ai_response_model: any, gen_ai_system: any, gen_ai_usage_input_tokens: any, gen_ai_usage_output_tokens: any, gen_ai_response_id: any, operation_cost: any, user_columns: record, matched_filter: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/fetch-traces-around-trace/")
  let body = {columns: $columns, where: $body_where, trace_id: $trace_id, limit: $limit, trace_timestamp: $trace_timestamp, min_start_timestamp: $min_start_timestamp, max_start_timestamp: $max_start_timestamp, deployment_environment: $deployment_environment, timezone: $timezone, table: $table} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch Trace Counts
#
# POST /ui-api/organizations/{organization}/projects/{project}/fetch-trace-counts/
# operationId: fetch_trace_counts
export def "ui-api-organizations-projects-fetch-trace-counts counts" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tab-hidden: oneof<nothing, bool>
  trace_ids: list
  --body-where: string
  --min-start-timestamp: string # format: date-time
  --max-start-timestamp: string # format: date-time
  --deployment-environment: list
  --timezone: string
  --table: string
]: any -> record<counts: table<trace_id: string, count: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/fetch-trace-counts/")
  let body = {tab_hidden: $tab_hidden, trace_ids: $trace_ids, where: $body_where, min_start_timestamp: $min_start_timestamp, max_start_timestamp: $max_start_timestamp, deployment_environment: $deployment_environment, timezone: $timezone, table: $table} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch Trace Graph
#
# POST /ui-api/organizations/{organization}/projects/{project}/fetch-trace-graph/
# operationId: fetch_trace_graph
export def "ui-api-organizations-projects-fetch-trace-graph graph" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tab-hidden: oneof<nothing, bool>
  trace_ids: list
  --deployment-environment: list
  --min-start-timestamp: string # format: date-time
  --max-start-timestamp: string # format: date-time
  --timezone: string
  --table: string
]: any -> record<graphs: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/fetch-trace-graph/")
  let body = {tab_hidden: $tab_hidden, trace_ids: $trace_ids, deployment_environment: $deployment_environment, min_start_timestamp: $min_start_timestamp, max_start_timestamp: $max_start_timestamp, timezone: $timezone, table: $table} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch Record Details
#
# POST /ui-api/organizations/{organization}/projects/{project}/fetch-details/
# operationId: fetch_record_details
# --columns item shape: {name: string, expression?: any}
# --span_locators item shape: {trace_id: string, span_id: string}
export def "ui-api-organizations-projects-fetch-details details" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --columns: list # List of columns to select, optionally as an expression with an alias (e.g. `select attributes->>'foo' as foo` -> [('foo', 'attributes->>'foo')] — item shape: {name: string, expression?: any}
  span_locators: list # item shape: {trace_id: string, span_id: string}
  --min-start-timestamp: any
  --max-start-timestamp: any
  --timezone: any
]: any -> table<start_timestamp: string, end_timestamp: string, message: string, day: string, duration: any, otel_status_code: any, otel_status_message: any, otel_links: any, otel_events: any, otel_scope_name: any, otel_scope_version: any, http_response_status_code: any, url_path: any, url_query: any, url_full: any, http_route: any, http_method: any, log_body: any, attributes: any, attributes_json_schema: any, otel_scope_attributes: any, service_namespace: any, service_instance_id: any, service_version: any, process_pid: any, otel_resource_attributes: any, telemetry_sdk_name: any, telemetry_sdk_language: any, telemetry_sdk_version: any, deployment_environment: any, exception_type: any, user_columns: record, trace_id: string, span_id: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/fetch-details/")
  let body = {columns: $columns, span_locators: $span_locators, min_start_timestamp: $min_start_timestamp, max_start_timestamp: $max_start_timestamp, timezone: $timezone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch Record Annotations
#
# POST /ui-api/organizations/{organization}/projects/{project}/fetch-record-annotations/
# operationId: fetch_record_annotations
export def "ui-api-organizations-projects-fetch-record-annotations annotations" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  trace_id: string
  span_id: string
  --min-start-timestamp: any
  --max-start-timestamp: any
  --timezone: any
]: any -> table<start_timestamp: string, end_timestamp: string, message: string, day: string, duration: any, otel_status_code: any, otel_status_message: any, otel_links: any, otel_events: any, otel_scope_name: any, otel_scope_version: any, http_response_status_code: any, url_path: any, url_query: any, url_full: any, http_route: any, http_method: any, log_body: any, attributes: any, attributes_json_schema: any, otel_scope_attributes: any, service_namespace: any, service_instance_id: any, service_version: any, process_pid: any, otel_resource_attributes: any, telemetry_sdk_name: any, telemetry_sdk_language: any, telemetry_sdk_version: any, deployment_environment: any, exception_type: any, user_columns: record, trace_id: string, span_id: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/fetch-record-annotations/")
  let body = {trace_id: $trace_id, span_id: $span_id, min_start_timestamp: $min_start_timestamp, max_start_timestamp: $max_start_timestamp, timezone: $timezone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch Trace Annotation Counts
#
# POST /ui-api/organizations/{organization}/projects/{project}/fetch-trace-annotations-counts/
# operationId: fetch_trace_annotation_counts
export def "ui-api-organizations-projects-fetch-trace-annotations-counts counts" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tab-hidden: oneof<nothing, bool>
  trace_ids: list
  --min-start-timestamp: any
  --max-start-timestamp: any
  --timezone: any
]: any -> table<trace_id: string, span_id: string, n_annotations: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/fetch-trace-annotations-counts/")
  let body = {tab_hidden: $tab_hidden, trace_ids: $trace_ids, min_start_timestamp: $min_start_timestamp, max_start_timestamp: $max_start_timestamp, timezone: $timezone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Datasets
#
# GET /ui-api/organizations/{organization}/projects/{project}/datasets/
# operationId: list_datasets
export def "ui-api-organizations-projects-datasets datasets" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, project_id: string, name: string, description: any, guidance: any, ai_managed_guidance: bool, case_count: int, created_at: string, updated_at: string, created_by_name: any, updated_by_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/datasets/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Dataset
#
# POST /ui-api/organizations/{organization}/projects/{project}/datasets/
# operationId: create_dataset
export def "ui-api-organizations-projects-datasets dataset-by-organization-project" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: any
  --input-schema: any
  --output-schema: any
  --metadata-schema: any
  --guidance: any
  --ai-managed-guidance: oneof<nothing, bool> # default: false
  --evaluators: any
  --report-evaluators: any
]: any -> record<id: string, project_id: string, name: string, description: any, input_schema: any, output_schema: any, metadata_schema: any, guidance: any, ai_managed_guidance: bool, evaluators: any, report_evaluators: any, case_count: int, created_at: string, updated_at: string, created_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/datasets/")
  let body = {name: $name, description: $description, input_schema: $input_schema, output_schema: $output_schema, metadata_schema: $metadata_schema, guidance: $guidance, ai_managed_guidance: $ai_managed_guidance, evaluators: $evaluators, report_evaluators: $report_evaluators} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Dataset
#
# GET /ui-api/organizations/{organization}/projects/{project}/datasets/{dataset_id}/
# operationId: get_dataset
export def "ui-api-organizations-projects-datasets dataset-by-dataset_id-organization-project" [
  dataset_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, project_id: string, name: string, description: any, input_schema: any, output_schema: any, metadata_schema: any, guidance: any, ai_managed_guidance: bool, evaluators: any, report_evaluators: any, case_count: int, created_at: string, updated_at: string, created_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/datasets/($dataset_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Dataset
#
# PATCH /ui-api/organizations/{organization}/projects/{project}/datasets/{dataset_id}/
# operationId: update_dataset
export def "ui-api-organizations-projects-datasets dataset-by-dataset_id-organization-project-1" [
  dataset_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: any
  --description: any
  --input-schema: any
  --output-schema: any
  --metadata-schema: any
  --guidance: any
  --ai-managed-guidance: any
  --evaluators: any
  --report-evaluators: any
]: any -> record<id: string, project_id: string, name: string, description: any, input_schema: any, output_schema: any, metadata_schema: any, guidance: any, ai_managed_guidance: bool, evaluators: any, report_evaluators: any, case_count: int, created_at: string, updated_at: string, created_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/datasets/($dataset_id)/")
  let body = {name: $name, description: $description, input_schema: $input_schema, output_schema: $output_schema, metadata_schema: $metadata_schema, guidance: $guidance, ai_managed_guidance: $ai_managed_guidance, evaluators: $evaluators, report_evaluators: $report_evaluators} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Dataset
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/datasets/{dataset_id}/
# operationId: delete_dataset
export def "ui-api-organizations-projects-datasets dataset-by-dataset_id-organization-project-2" [
  dataset_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/datasets/($dataset_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Dataset By Name
#
# GET /ui-api/organizations/{organization}/projects/{project}/datasets/by-name/{name}/
# operationId: get_dataset_by_name
export def "ui-api-organizations-projects-datasets-by-name name" [
  name: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, project_id: string, name: string, description: any, input_schema: any, output_schema: any, metadata_schema: any, guidance: any, ai_managed_guidance: bool, evaluators: any, report_evaluators: any, case_count: int, created_at: string, updated_at: string, created_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/datasets/by-name/($name)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Cases
#
# GET /ui-api/organizations/{organization}/projects/{project}/datasets/{dataset_id}/cases/
# operationId: list_cases
export def "ui-api-organizations-projects-datasets-cases cases" [
  dataset_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # default: 0
  --limit: int # default: 100
  --tags: string
]: nothing -> table<id: string, dataset_id: string, name: any, inputs: record, expected_output: any, metadata: any, evaluators: any, source_trace_id: any, source_span_id: any, tags: any, version: int, created_at: string, created_by: any, updated_at: string, updated_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "tags" $tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/datasets/($dataset_id)/cases/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Case
#
# POST /ui-api/organizations/{organization}/projects/{project}/datasets/{dataset_id}/cases/
# operationId: create_case
export def "ui-api-organizations-projects-datasets-cases case-by-dataset_id-organization-project" [
  dataset_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: any
  inputs: record
  --expected-output: any
  --metadata: any
  --evaluators: any
  --source-trace-id: any
  --source-span-id: any
  --tags: any
]: any -> record<id: string, dataset_id: string, name: any, inputs: record, expected_output: any, metadata: any, evaluators: any, source_trace_id: any, source_span_id: any, tags: any, version: int, created_at: string, created_by: any, updated_at: string, updated_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/datasets/($dataset_id)/cases/")
  let body = {name: $name, inputs: $inputs, expected_output: $expected_output, metadata: $metadata, evaluators: $evaluators, source_trace_id: $source_trace_id, source_span_id: $source_span_id, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Case
#
# GET /ui-api/organizations/{organization}/projects/{project}/datasets/{dataset_id}/cases/{case_id}/
# operationId: get_case
export def "ui-api-organizations-projects-datasets-cases case-by-dataset_id-case_id-organization-project" [
  dataset_id: string
  case_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, dataset_id: string, name: any, inputs: record, expected_output: any, metadata: any, evaluators: any, source_trace_id: any, source_span_id: any, tags: any, version: int, created_at: string, created_by: any, updated_at: string, updated_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/datasets/($dataset_id)/cases/($case_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Case
#
# PATCH /ui-api/organizations/{organization}/projects/{project}/datasets/{dataset_id}/cases/{case_id}/
# operationId: update_case
export def "ui-api-organizations-projects-datasets-cases case-by-dataset_id-case_id-organization-project-1" [
  dataset_id: string
  case_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: any
  --inputs: any
  --expected-output: any
  --metadata: any
  --evaluators: any
  --tags: any
]: any -> record<id: string, dataset_id: string, name: any, inputs: record, expected_output: any, metadata: any, evaluators: any, source_trace_id: any, source_span_id: any, tags: any, version: int, created_at: string, created_by: any, updated_at: string, updated_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/datasets/($dataset_id)/cases/($case_id)/")
  let body = {name: $name, inputs: $inputs, expected_output: $expected_output, metadata: $metadata, evaluators: $evaluators, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Case
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/datasets/{dataset_id}/cases/{case_id}/
# operationId: delete_case
export def "ui-api-organizations-projects-datasets-cases case-by-dataset_id-case_id-organization-project-2" [
  dataset_id: string
  case_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/datasets/($dataset_id)/cases/($case_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk Create Cases
#
# POST /ui-api/organizations/{organization}/projects/{project}/datasets/{dataset_id}/cases/bulk/
# operationId: bulk_create_cases
# --cases item shape: {name?: any, inputs: record, expected_output?: any, metadata?: any, evaluators?: any, source_trace_id?: any, source_span_id?: any, tags?: any}
export def "ui-api-organizations-projects-datasets-cases-bulk cases" [
  dataset_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  cases: list # item shape: {name?: any, inputs: record, expected_output?: any, metadata?: any, evaluators?: any, source_trace_id?: any, source_span_id?: any, tags?: any}
]: any -> table<id: string, dataset_id: string, name: any, inputs: record, expected_output: any, metadata: any, evaluators: any, source_trace_id: any, source_span_id: any, tags: any, version: int, created_at: string, created_by: any, updated_at: string, updated_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/datasets/($dataset_id)/cases/bulk/")
  let body = {cases: $cases} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Case From Trace
#
# POST /ui-api/organizations/{organization}/projects/{project}/datasets/from-trace/
# operationId: create_case_from_trace
export def "ui-api-organizations-projects-datasets-from-trace trace" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  dataset_id: string # format: uuid
  trace_id: string
  span_id: string
  --name: any
  inputs: record
  --expected-output: any
  --metadata: any
  --evaluators: any
  --tags: any
]: any -> record<id: string, dataset_id: string, name: any, inputs: record, expected_output: any, metadata: any, evaluators: any, source_trace_id: any, source_span_id: any, tags: any, version: int, created_at: string, created_by: any, updated_at: string, updated_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/datasets/from-trace/")
  let body = {dataset_id: $dataset_id, trace_id: $trace_id, span_id: $span_id, name: $name, inputs: $inputs, expected_output: $expected_output, metadata: $metadata, evaluators: $evaluators, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Export Dataset
#
# GET /ui-api/organizations/{organization}/projects/{project}/datasets/{dataset_id}/export/
# operationId: export_dataset
export def "ui-api-organizations-projects-datasets-export dataset" [
  dataset_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer-1 # default: pydantic-evals
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/datasets/($dataset_id)/export/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Preview Deletion Query
#
# POST /ui-api/organizations/{organization}/projects/{project}/deletion-job/preview/
# operationId: preview_deletion_query
export def "ui-api-organizations-projects-deletion-job-preview query" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  sql: string
]: any -> record<table: string, select_sql: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/deletion-job/preview/")
  let body = {sql: $sql} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Deletion Job
#
# POST /ui-api/organizations/{organization}/projects/{project}/deletion-job/
# operationId: create_deletion_job
export def "ui-api-organizations-projects-deletion-job job" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  sql: string
]: any -> record<deletion_job_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/deletion-job/")
  let body = {sql: $sql} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Deletion Jobs
#
# GET /ui-api/organizations/{organization}/projects/{project}/deletion-job/
# operationId: list_deletion_jobs
export def "ui-api-organizations-projects-deletion-job jobs" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<deletion_job_id: int, table_id: int, organization_id: string, project_id: string, deletion_sql: string, created_at: string, updated_at: string, state: string, progress: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/deletion-job/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Experiments
#
# GET /ui-api/organizations/{organization}/projects/{project}/experiments/
# operationId: get_experiments
export def "ui-api-organizations-projects-experiments experiments" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-start-timestamp: string # format: date-time
  --max-start-timestamp: string # format: date-time
  --offset: int # default: 0
  --qp-sort: list # default: []
  --search: string
  --archived: string
  --experiment-names: string
  --dataset-names: string
  --trace-ids: string
]: nothing -> record<data: table<id: string, created_at: string, updated_at: string, organization_id: string, project_id: string, experiment_name: any, dataset_name: any, task_name: any, archived: bool, metadata: any, trace_id: any, span_id: any>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_start_timestamp" $min_start_timestamp "scalar") (serialize-qp "max_start_timestamp" $max_start_timestamp "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "experiment_names" $experiment_names "scalar") (serialize-qp "dataset_names" $dataset_names "scalar") (serialize-qp "trace_ids" $trace_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/experiments/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Experiment
#
# PATCH /ui-api/organizations/{organization}/projects/{project}/experiments/{experiment_id}/
# operationId: update_experiment
export def "ui-api-organizations-projects-experiments experiment" [
  experiment_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --experiment-name: string
  --archived: oneof<nothing, bool>
]: any -> record<id: string, created_at: string, updated_at: string, organization_id: string, project_id: string, experiment_name: any, dataset_name: any, task_name: any, archived: bool, metadata: any, trace_id: any, span_id: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/experiments/($experiment_id)/")
  let body = {experiment_name: $experiment_name, archived: $archived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Batch Toggle Archive
#
# POST /ui-api/organizations/{organization}/projects/{project}/experiments/toggle/
# operationId: batch_toggle_archive
export def "ui-api-organizations-projects-experiments-toggle archive" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  experiment_ids: list
  action: string@action-completer-1
]: any -> table<id: string, created_at: string, updated_at: string, organization_id: string, project_id: string, experiment_name: any, dataset_name: any, task_name: any, archived: bool, metadata: any, trace_id: any, span_id: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/experiments/toggle/")
  let body = {experiment_ids: $experiment_ids, action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Experiment Names
#
# GET /ui-api/organizations/{organization}/projects/{project}/experiments/experiment_names/
# operationId: get_experiment_names
export def "ui-api-organizations-projects-experiments-experiment-names names" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-start-timestamp: string # format: date-time
  --max-start-timestamp: string # format: date-time
  --archived: string
  --dataset-names: string
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_start_timestamp" $min_start_timestamp "scalar") (serialize-qp "max_start_timestamp" $max_start_timestamp "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "dataset_names" $dataset_names "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/experiments/experiment_names/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Dataset Names
#
# GET /ui-api/organizations/{organization}/projects/{project}/experiments/dataset_names/
# operationId: get_dataset_names
export def "ui-api-organizations-projects-experiments-dataset-names names" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-start-timestamp: string # format: date-time
  --max-start-timestamp: string # format: date-time
  --archived: string
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_start_timestamp" $min_start_timestamp "scalar") (serialize-qp "max_start_timestamp" $max_start_timestamp "scalar") (serialize-qp "archived" $archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/experiments/dataset_names/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Dataset Stats
#
# GET /ui-api/organizations/{organization}/projects/{project}/experiments/dataset_stats/
# operationId: get_dataset_stats
export def "ui-api-organizations-projects-experiments-dataset-stats stats" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-start-timestamp: string # format: date-time
  --max-start-timestamp: string # format: date-time
  --archived: string
]: nothing -> table<dataset_name: string, experiment_count: int, last_experiment_at: string, last_pass_rate: any, case_count: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_start_timestamp" $min_start_timestamp "scalar") (serialize-qp "max_start_timestamp" $max_start_timestamp "scalar") (serialize-qp "archived" $archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/experiments/dataset_stats/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Compare Experiments
#
# POST /ui-api/organizations/{organization}/projects/{project}/experiments/compare/
# operationId: compare_experiments
export def "ui-api-organizations-projects-experiments-compare experiments" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  experiment_ids: list
]: any -> record<experiments: table<experiment: record, metadata: any, averages: record, analyses: any, report_evaluator_failures: any, case_count: int>, summary: record<metric_keys: list<string>, score_keys: list<string>, label_keys: list<string>, token_metric_keys: list<string>, metadata_keys: list<string>, has_assertions: bool, has_tokens: bool, has_metadata: bool, label_values: record, assertion_keys: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/experiments/compare/")
  let body = {experiment_ids: $experiment_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Compare Experiment Cases
#
# POST /ui-api/organizations/{organization}/projects/{project}/experiments/compare/cases/
# operationId: get_compare_experiment_cases
export def "ui-api-organizations-projects-experiments-compare-cases cases" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  experiment_ids: list
  --baseline-experiment-id: any
  --offset: int # default: 0
  --limit: int # default: 30
  --sort-by: any
  --sort-order: string@sort-order-completer # default: asc
  --search: any
  --labels-filter: any
  --assertions-filter: any
  --scores-filter: any
  --metrics-filter: any
]: any -> record<cases: table<trace_id: string, span_id: string, parent_span_id: string, case_name: string, inputs: any, expected_output: any, output: any, metadata: any, metrics: record, scores: record, labels: record, assertions: record, task_duration: float, total_duration: float, exception_type: any, exception_message: any, source_case_name: any>, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/experiments/compare/cases/")
  let body = {experiment_ids: $experiment_ids, baseline_experiment_id: $baseline_experiment_id, offset: $offset, limit: $limit, sort_by: $sort_by, sort_order: $sort_order, search: $search, labels_filter: $labels_filter, assertions_filter: $assertions_filter, scores_filter: $scores_filter, metrics_filter: $metrics_filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Gateway Config
#
# GET /ui-api/organizations/{organization}/projects/{project}/gateway-config/
# operationId: get_gateway_config
export def "ui-api-organizations-projects-gateway-config config-by-project-organization" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/gateway-config/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Save Gateway Config
#
# PUT /ui-api/organizations/{organization}/projects/{project}/gateway-config/
# operationId: save_gateway_config
export def "ui-api-organizations-projects-gateway-config config-by-project-organization-1" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key: string
]: any -> record<id: string, project_id: string, gateway_url: string, has_api_key: bool, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/gateway-config/")
  let body = {api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Gateway Config
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/gateway-config/
# operationId: delete_gateway_config
export def "ui-api-organizations-projects-gateway-config config-by-project-organization-2" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/gateway-config/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test Gateway Config
#
# POST /ui-api/organizations/{organization}/projects/{project}/gateway-config/test/
# operationId: test_gateway_config
export def "ui-api-organizations-projects-gateway-config-test config" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: any
]: any -> record<success: bool, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/gateway-config/test/")
  let body = {api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Projects Create Invitation
#
# POST /ui-api/organizations/{organization}/projects/{project}/invitations/
# operationId: projects_create_invitation
export def "ui-api-organizations-projects-invitations invitation" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  max_usage_count: int
  --expiration: string # format: date-time
  role_id: string # format: uuid
]: any -> record<id: string, project_id: string, expiration: any, max_usage_count: int, usage_count: int, role_id: string, created_at: string, last_used_at: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/invitations/")
  let body = {max_usage_count: $max_usage_count, expiration: $expiration, role_id: $role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Project Invitations
#
# GET /ui-api/organizations/{organization}/projects/{project}/invitations/
# operationId: list_project_invitations
export def "ui-api-organizations-projects-invitations invitations" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, project_id: string, expiration: any, max_usage_count: int, usage_count: int, role_id: string, created_at: string, last_used_at: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/invitations/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Projects Revoke Invitation
#
# POST /ui-api/organizations/{organization}/projects/{project}/invitations/{invitation_id}/revoke/
# operationId: projects_revoke_invitation
export def "ui-api-organizations-projects-invitations-revoke invitation" [
  invitation_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/invitations/($invitation_id)/revoke/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Claim Project Invitation
#
# POST /ui-api/organizations/{organization}/projects/{project}/invitations/{invitation_id}/claim/
# operationId: claim_project_invitation
export def "ui-api-organizations-projects-invitations-claim invitation" [
  organization: string
  project: string
  invitation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/invitations/($invitation_id)/claim/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Issues Config
#
# GET /ui-api/organizations/{organization}/projects/{project}/issues/
# operationId: get_issues_config
export def "ui-api-organizations-projects-issues config-by-project-organization" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/issues/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable Issues
#
# POST /ui-api/organizations/{organization}/projects/{project}/issues/
# operationId: enable_issues
# --channel_assignments item shape: {channel_id: string, schedule_id?: any}
export def "ui-api-organizations-projects-issues issues-by-organization-project" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  notification_interval: string # format: duration
  --channel-ids: any # Legacy shorthand for assigning channels without schedules.
  --channel-assignments: list # Schedule-aware channel configuration. When both `channel_assignments` and `channel_ids` are provided, `channel_assignments` is used. — item shape: {channel_id: string, schedule_id?: any}
  --extra-sql-filter: any
]: any -> record<id: string, project_id: string, created_at: string, created_by_name: any, updated_at: string, updated_by_name: any, name: string, where_clause: string, is_private: bool, filter_alert: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/issues/")
  let body = {notification_interval: $notification_interval, channel_ids: $channel_ids, channel_assignments: $channel_assignments, extra_sql_filter: $extra_sql_filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Issues Config
#
# PUT /ui-api/organizations/{organization}/projects/{project}/issues/
# operationId: update_issues_config
# --channel_assignments item shape: {channel_id: string, schedule_id?: any}
export def "ui-api-organizations-projects-issues config-by-organization-project" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  notification_interval: string # format: duration
  --channel-ids: any # Legacy shorthand for assigning channels without schedules.
  --channel-assignments: list # Schedule-aware channel configuration. When both `channel_assignments` and `channel_ids` are provided, `channel_assignments` is used. — item shape: {channel_id: string, schedule_id?: any}
  --extra-sql-filter: any
]: any -> record<id: string, project_id: string, created_at: string, created_by_name: any, updated_at: string, updated_by_name: any, name: string, where_clause: string, is_private: bool, filter_alert: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/issues/")
  let body = {notification_interval: $notification_interval, channel_ids: $channel_ids, channel_assignments: $channel_assignments, extra_sql_filter: $extra_sql_filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable Issues
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/issues/
# operationId: disable_issues
export def "ui-api-organizations-projects-issues issues-by-organization-project-1" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/issues/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Issues
#
# GET /ui-api/organizations/{organization}/projects/{project}/issues/list/
# operationId: list_issues
export def "ui-api-organizations-projects-issues-list issues" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer # default: open
  --offset: int # default: 0
  --limit: int # default: 20
  --search: string
  --sort-by: string@sort-by-completer # default: max_start_timestamp
  --sort-order: string@sort-order-completer # default: desc
  --deployment-environment: string
]: nothing -> record<data: table<id: string, project_id: string, filter_alert_id: string, created_at: string, updated_at: string, index: int, fingerprint: string, issue_label: string, issue_description: any, last_opened_at: string, state: string, first_trace_id: any, first_span_id: any, first_span_message: any, first_exception_type: any, first_exception_message: any, first_exception_stacktrace: any, latest_trace_id: any, latest_span_id: any, last_notified: any, matches_count: int, min_start_timestamp: any, max_start_timestamp: any, service_names: list, environments: list>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "deployment_environment" $deployment_environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/issues/list/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Issue Counts
#
# GET /ui-api/organizations/{organization}/projects/{project}/issues/counts/
# operationId: get_issue_counts
export def "ui-api-organizations-projects-issues-counts counts" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string
  --deployment-environment: string
]: nothing -> record<open: int, resolved: int, ignored: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "deployment_environment" $deployment_environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/issues/counts/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Issue Detail
#
# GET /ui-api/organizations/{organization}/projects/{project}/issues/detail/{issue_index}/
# operationId: get_issue_detail
export def "ui-api-organizations-projects-issues-detail detail" [
  issue_index: int
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, project_id: string, filter_alert_id: string, created_at: string, updated_at: string, index: int, fingerprint: string, issue_label: string, issue_description: any, last_opened_at: string, state: string, first_trace_id: any, first_span_id: any, first_span_message: any, first_exception_type: any, first_exception_message: any, first_exception_stacktrace: any, latest_trace_id: any, latest_span_id: any, last_notified: any, matches_count: int, min_start_timestamp: any, max_start_timestamp: any, service_names: list<string>, environments: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/issues/detail/($issue_index)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Issue
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/issues/{filter_alert_issue_id}/
# operationId: delete_issue
export def "ui-api-organizations-projects-issues issue" [
  filter_alert_issue_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/issues/($filter_alert_issue_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Project Llm Summary
#
# GET /ui-api/organizations/{organization}/projects/{project}/llms/summary/
# operationId: get_project_llm_summary
export def "ui-api-organizations-projects-llms-summary summary" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deployment-environment: string
  --age-minutes: int # default: 10080
  --min-timestamp: string
  --max-timestamp: string
]: nothing -> table<system: string, model: string, call_count: int, error_count: int, avg_latency_ms: float, max_latency_ms: float, total_input_tokens: int, total_output_tokens: int, total_cache_read_tokens: int, total_cost: float, truncated_count: int, tool_call_count: int, last_active: string, detail_error_rate: list<float>, detail_latency_ms: list<float>, detail_truncated_rate: list<float>, detail_tool_call_rate: list<float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deployment_environment" $deployment_environment "scalar") (serialize-qp "age_minutes" $age_minutes "scalar") (serialize-qp "min_timestamp" $min_timestamp "scalar") (serialize-qp "max_timestamp" $max_timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/llms/summary/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Project Llm Timeseries
#
# GET /ui-api/organizations/{organization}/projects/{project}/llms/timeseries/
# operationId: get_project_llm_timeseries
export def "ui-api-organizations-projects-llms-timeseries timeseries" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --system: string
  --model: string
  --deployment-environment: string
  --interval: string
  --age-minutes: int # default: 10080
  --min-timestamp: string
  --max-timestamp: string
]: nothing -> table<bucket: string, call_count: int, error_count: int, latency_ms: float, p50_latency_ms: float, p90_latency_ms: float, tokens_in: int, tokens_out: int, cache_read_tokens: int, cost: float, truncated_count: int, tool_call_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "system" $system "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "deployment_environment" $deployment_environment "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "age_minutes" $age_minutes "scalar") (serialize-qp "min_timestamp" $min_timestamp "scalar") (serialize-qp "max_timestamp" $max_timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/llms/timeseries/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Project Llm Agents
#
# GET /ui-api/organizations/{organization}/projects/{project}/llms/agents/
# operationId: get_project_llm_agents
export def "ui-api-organizations-projects-llms-agents agents" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --system: string
  --model: string
  --deployment-environment: string
  --age-minutes: int # default: 10080
  --min-timestamp: string
  --max-timestamp: string
]: nothing -> table<agent_name: string, run_count: int, last_active: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "system" $system "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "deployment_environment" $deployment_environment "scalar") (serialize-qp "age_minutes" $age_minutes "scalar") (serialize-qp "min_timestamp" $min_timestamp "scalar") (serialize-qp "max_timestamp" $max_timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/llms/agents/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Project Llm Calls
#
# GET /ui-api/organizations/{organization}/projects/{project}/llms/calls/
# operationId: get_project_llm_calls
export def "ui-api-organizations-projects-llms-calls calls" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --system: string
  --model: string
  --limit: int # default: 50
  --deployment-environment: string
  --age-minutes: int # default: 10080
  --min-timestamp: string
  --max-timestamp: string
]: nothing -> table<trace_id: string, span_id: string, start_timestamp: string, duration_ms: float, model: string, input_tokens: int, output_tokens: int, cost: float, is_exception: bool, error_type: any, finish_reasons: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "system" $system "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "deployment_environment" $deployment_environment "scalar") (serialize-qp "age_minutes" $age_minutes "scalar") (serialize-qp "min_timestamp" $min_timestamp "scalar") (serialize-qp "max_timestamp" $max_timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/llms/calls/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Project Get Members
#
# GET /ui-api/organizations/{organization}/projects/{project}/members/
# operationId: project_get_members
export def "ui-api-organizations-projects-members members" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string, email: string, project_role_id: any, organization_role_id: string, source: string, github_username: any, avatar: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/members/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Project Update Member
#
# PUT /ui-api/organizations/{organization}/projects/{project}/members/{user_id}/
# operationId: project_update_member
export def "ui-api-organizations-projects-members member-by-user_id-organization-project" [
  user_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  role_id: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/members/($user_id)/")
  let body = {role_id: $role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Project Remove Member
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/members/{user_id}/
# operationId: project_remove_member
export def "ui-api-organizations-projects-members member-by-user_id-organization-project-1" [
  user_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/members/($user_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Notebooks
#
# GET /ui-api/organizations/{organization}/projects/{project}/notebooks/
# operationId: list_notebooks
export def "ui-api-organizations-projects-notebooks notebooks" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, project_id: string, created_by: any, created_by_name: any, name: string, is_private: bool, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/notebooks/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Notebook
#
# POST /ui-api/organizations/{organization}/projects/{project}/notebooks/
# operationId: create_notebook
export def "ui-api-organizations-projects-notebooks notebook-by-organization-project" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> record<id: string, project_id: string, created_by: any, created_by_name: any, name: string, is_private: bool, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/notebooks/")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Notebook
#
# GET /ui-api/organizations/{organization}/projects/{project}/notebooks/{notebook_id}/
# operationId: get_notebook
export def "ui-api-organizations-projects-notebooks notebook-by-notebook_id-organization-project" [
  notebook_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, project_id: string, created_by: any, created_by_name: any, name: string, is_private: bool, created_at: string, updated_at: string, cells: table<id: string, notebook_id: string, position: int, cell_type: string, content: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/notebooks/($notebook_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Notebook
#
# PUT /ui-api/organizations/{organization}/projects/{project}/notebooks/{notebook_id}/
# operationId: update_notebook
export def "ui-api-organizations-projects-notebooks notebook-by-notebook_id-organization-project-1" [
  notebook_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> record<id: string, project_id: string, created_by: any, created_by_name: any, name: string, is_private: bool, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/notebooks/($notebook_id)/")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Notebook
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/notebooks/{notebook_id}/
# operationId: delete_notebook
export def "ui-api-organizations-projects-notebooks notebook-by-notebook_id-organization-project-2" [
  notebook_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/notebooks/($notebook_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk Update Cells
#
# PUT /ui-api/organizations/{organization}/projects/{project}/notebooks/{notebook_id}/cells/
# operationId: bulk_update_cells
# --cells item shape: {id?: string, position?: int, cell_type?: string, content?: string, delete?: bool}
export def "ui-api-organizations-projects-notebooks-cells cells" [
  notebook_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  cells: list # item shape: {id?: string, position?: int, cell_type?: string, content?: string, delete?: bool}
]: any -> table<id: string, notebook_id: string, position: int, cell_type: string, content: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/notebooks/($notebook_id)/cells/")
  let body = {cells: $cells} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Online Eval Hide Rules
#
# GET /ui-api/organizations/{organization}/projects/{project}/online-eval-hide-rules/
# operationId: list_online_eval_hide_rules
export def "ui-api-organizations-projects-online-eval-hide-rules rules" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, project_id: string, target: any, evaluator_name: any, evaluator_version: any, hide_before: any, created_at: string, created_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/online-eval-hide-rules/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Online Eval Hide Rule
#
# POST /ui-api/organizations/{organization}/projects/{project}/online-eval-hide-rules/
# operationId: create_online_eval_hide_rule
export def "ui-api-organizations-projects-online-eval-hide-rules rule-by-project-organization" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --target: any
  --evaluator-name: any
  --evaluator-version: any
  --hide-before: any
]: any -> record<id: string, project_id: string, target: any, evaluator_name: any, evaluator_version: any, hide_before: any, created_at: string, created_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/online-eval-hide-rules/")
  let body = {target: $target, evaluator_name: $evaluator_name, evaluator_version: $evaluator_version, hide_before: $hide_before} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Online Eval Hide Rule
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/online-eval-hide-rules/{rule_id}/
# operationId: delete_online_eval_hide_rule
export def "ui-api-organizations-projects-online-eval-hide-rules rule-by-rule_id-project-organization" [
  rule_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/online-eval-hide-rules/($rule_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Prompts
#
# GET /ui-api/organizations/{organization}/projects/{project}/prompts/
# operationId: list_prompts
export def "ui-api-organizations-projects-prompts prompts" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: string, project_id: string, name: string, slug: string, variable_name: string, type: string, description: any, created_at: string, updated_at: string, created_by: string, created_by_name: any, version_count: int, latest_version: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Prompt
#
# POST /ui-api/organizations/{organization}/projects/{project}/prompts/
# operationId: create_prompt
export def "ui-api-organizations-projects-prompts prompt-by-organization-project" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: any
  --slug: any
  --type: string
]: any -> record<id: string, organization_id: string, project_id: string, name: string, slug: string, variable_name: string, type: string, description: any, created_at: string, updated_at: string, created_by: string, created_by_name: any, version_count: int, latest_version: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/")
  let body = {name: $name, description: $description, slug: $slug, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Prompt
#
# GET /ui-api/organizations/{organization}/projects/{project}/prompts/{prompt_slug}/
# operationId: get_prompt
export def "ui-api-organizations-projects-prompts prompt-by-prompt_slug-organization-project" [
  prompt_slug: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, organization_id: string, project_id: string, name: string, slug: string, variable_name: string, type: string, description: any, created_at: string, updated_at: string, created_by: string, created_by_name: any, version_count: int, latest_version: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/($prompt_slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Prompt
#
# PUT /ui-api/organizations/{organization}/projects/{project}/prompts/{prompt_slug}/
# operationId: update_prompt
export def "ui-api-organizations-projects-prompts prompt-by-prompt_slug-organization-project-1" [
  prompt_slug: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --description: any
  --slug: string
]: any -> record<id: string, organization_id: string, project_id: string, name: string, slug: string, variable_name: string, type: string, description: any, created_at: string, updated_at: string, created_by: string, created_by_name: any, version_count: int, latest_version: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/($prompt_slug)/")
  let body = {name: $name, description: $description, slug: $slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Prompt
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/prompts/{prompt_slug}/
# operationId: delete_prompt
export def "ui-api-organizations-projects-prompts prompt-by-prompt_slug-organization-project-2" [
  prompt_slug: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/($prompt_slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Prompt Settings
#
# GET /ui-api/organizations/{organization}/projects/{project}/prompts/{prompt_slug}/settings/
# operationId: get_prompt_settings
export def "ui-api-organizations-projects-prompts-settings settings-by-prompt_slug-organization-project" [
  prompt_slug: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<api_format: string, route: any, model: any, model_settings: record, stream: bool, tools: table<name: string, description: any, parameters: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/($prompt_slug)/settings/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Prompt Settings
#
# PUT /ui-api/organizations/{organization}/projects/{project}/prompts/{prompt_slug}/settings/
# operationId: update_prompt_settings
# --tools item shape: {name: string, description: any, parameters: record}
export def "ui-api-organizations-projects-prompts-settings settings-by-prompt_slug-organization-project-1" [
  prompt_slug: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-format: string@api-format-completer
  --route: any
  --model: any
  --model-settings: any
  --stream: oneof<nothing, bool>
  --tools: list # item shape: {name: string, description: any, parameters: record}
]: any -> record<api_format: string, route: any, model: any, model_settings: record, stream: bool, tools: table<name: string, description: any, parameters: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/($prompt_slug)/settings/")
  let body = {api_format: $api_format, route: $route, model: $model, model_settings: $model_settings, stream: $stream, tools: $tools} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Prompt Version
#
# POST /ui-api/organizations/{organization}/projects/{project}/prompts/{prompt_slug}/versions/
# operationId: create_prompt_version
export def "ui-api-organizations-projects-prompts-versions version-by-prompt_slug-organization-project" [
  prompt_slug: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  template: string
  --description: any
]: any -> record<id: string, organization_id: string, project_id: string, prompt_id: string, version: int, template: string, description: any, created_at: string, created_by: string, created_by_name: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/($prompt_slug)/versions/")
  let body = {template: $template, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Prompt Versions
#
# GET /ui-api/organizations/{organization}/projects/{project}/prompts/{prompt_slug}/versions/
# operationId: list_prompt_versions
export def "ui-api-organizations-projects-prompts-versions versions" [
  prompt_slug: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: string, project_id: string, prompt_id: string, version: int, template: string, description: any, created_at: string, created_by: string, created_by_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/($prompt_slug)/versions/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Prompt Version
#
# GET /ui-api/organizations/{organization}/projects/{project}/prompts/{prompt_slug}/versions/{version}/
# operationId: get_prompt_version
export def "ui-api-organizations-projects-prompts-versions version-by-prompt_slug-version-organization-project" [
  prompt_slug: string
  version: int
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, organization_id: string, project_id: string, prompt_id: string, version: int, template: string, description: any, created_at: string, created_by: string, created_by_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/($prompt_slug)/versions/($version)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Prompt Scenarios
#
# GET /ui-api/organizations/{organization}/projects/{project}/prompts/{prompt_slug}/scenarios/
# operationId: list_prompt_scenarios
export def "ui-api-organizations-projects-prompts-scenarios scenarios" [
  prompt_slug: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, organization_id: string, project_id: string, prompt_id: string, name: string, messages: list<record>, variables: record, is_default: bool, position: int, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/($prompt_slug)/scenarios/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Prompt Scenario
#
# POST /ui-api/organizations/{organization}/projects/{project}/prompts/{prompt_slug}/scenarios/
# operationId: create_prompt_scenario
# --messages item shape: {role: "system"|"user"|"assistant"|"tool", parts: list}
export def "ui-api-organizations-projects-prompts-scenarios scenario-by-prompt_slug-organization-project" [
  prompt_slug: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --messages: list # item shape: {role: "system"|"user"|"assistant"|"tool", parts: list}
  --body-variables: record
]: any -> record<id: string, organization_id: string, project_id: string, prompt_id: string, name: string, messages: table<role: string, parts: list>, variables: record, is_default: bool, position: int, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/($prompt_slug)/scenarios/")
  let body = {name: $name, messages: $messages, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reorder Prompt Scenarios
#
# PUT /ui-api/organizations/{organization}/projects/{project}/prompts/{prompt_slug}/scenarios/reorder/
# operationId: reorder_prompt_scenarios
export def "ui-api-organizations-projects-prompts-scenarios-reorder scenarios" [
  prompt_slug: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  scenario_ids: list
]: any -> table<id: string, organization_id: string, project_id: string, prompt_id: string, name: string, messages: list<record>, variables: record, is_default: bool, position: int, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/($prompt_slug)/scenarios/reorder/")
  let body = {scenario_ids: $scenario_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Prompt Scenario
#
# PUT /ui-api/organizations/{organization}/projects/{project}/prompts/{prompt_slug}/scenarios/{scenario_id}/
# operationId: update_prompt_scenario
# --messages item shape: {role: "system"|"user"|"assistant"|"tool", parts: list}
export def "ui-api-organizations-projects-prompts-scenarios scenario-by-prompt_slug-scenario_id-organization-project" [
  prompt_slug: string
  scenario_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --messages: list # item shape: {role: "system"|"user"|"assistant"|"tool", parts: list}
  --body-variables: record
]: any -> record<id: string, organization_id: string, project_id: string, prompt_id: string, name: string, messages: table<role: string, parts: list>, variables: record, is_default: bool, position: int, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/($prompt_slug)/scenarios/($scenario_id)/")
  let body = {name: $name, messages: $messages, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Prompt Scenario
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/prompts/{prompt_slug}/scenarios/{scenario_id}/
# operationId: delete_prompt_scenario
export def "ui-api-organizations-projects-prompts-scenarios scenario-by-prompt_slug-scenario_id-organization-project-1" [
  prompt_slug: string
  scenario_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/($prompt_slug)/scenarios/($scenario_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Render Prompt
#
# POST /ui-api/organizations/{organization}/projects/{project}/prompts/{prompt_slug}/render/
# operationId: render_prompt
# --messages item shape: {role: "system"|"user"|"assistant"|"tool", parts: list}
export def "ui-api-organizations-projects-prompts-render prompt" [
  prompt_slug: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  template: string
  messages: list # item shape: {role: "system"|"user"|"assistant"|"tool", parts: list}
  --scenario-variables: record
  --scenario-id: any
  --dataset-case-id: any
  --variable-targeting-key: any
  --variable-attributes: any
]: any -> record<messages: any, validation_errors: list<string>, validation_warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/($prompt_slug)/render/")
  let body = {template: $template, messages: $messages, scenario_variables: $scenario_variables, scenario_id: $scenario_id, dataset_case_id: $dataset_case_id, variable_targeting_key: $variable_targeting_key, variable_attributes: $variable_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resolve Prompt Reference
#
# POST /ui-api/organizations/{organization}/projects/{project}/prompts/{prompt_slug}/references/resolve/
# operationId: resolve_prompt_reference
export def "ui-api-organizations-projects-prompts-references-resolve reference" [
  prompt_slug: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  reference_name: string
  --scenario-variables: record
  --scenario-id: any
  --dataset-case-id: any
  --variable-targeting-key: any
  --variable-attributes: any
]: any -> record<reference_name: string, resolved_name: any, value: any, serialized_value: any, label: any, version: any, reason: string, validation_errors: list<string>, validation_warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/($prompt_slug)/references/resolve/")
  let body = {reference_name: $reference_name, scenario_variables: $scenario_variables, scenario_id: $scenario_id, dataset_case_id: $dataset_case_id, variable_targeting_key: $variable_targeting_key, variable_attributes: $variable_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Run Prompt
#
# POST /ui-api/organizations/{organization}/projects/{project}/prompts/{prompt_slug}/run/
# operationId: run_prompt
# --scenario_messages item shape: {role: "system"|"user"|"assistant"|"tool", parts: list}
# --tools item shape: {name: string, description: any, parameters: record}
export def "ui-api-organizations-projects-prompts-run prompt" [
  prompt_slug: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  template: string
  api_format: string@api-format-completer
  scenario_messages: list # item shape: {role: "system"|"user"|"assistant"|"tool", parts: list}
  --route: any
  --model: any
  --model-settings: any
  --tools: list # item shape: {name: string, description: any, parameters: record}
  --scenario-variables: record
  scenario_id: string # format: uuid
  --baseline-version-id: any
  --includes-unsaved-edits: oneof<nothing, bool>
  --api-key-id: any
  --variable-targeting-key: any
  --variable-attributes: any
]: any -> record<id: string, organization_id: string, project_id: string, prompt_id: string, run_type: string, dataset_id: any, total_cases: any, completed_cases: int, failed_cases: int, baseline_version_id: any, includes_unsaved_edits: bool, scenario_id: any, scenario_name_snapshot: any, model: string, status: string, latency_ms: any, cost_estimate: any, error: any, created_at: string, created_by: string, template_snapshot: string, scenario_messages_snapshot: any, rendered_messages: list<record>, model_settings: any, tools: table<name: string, description: any, parameters: record>, variables: record, output: any, usage: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/($prompt_slug)/run/")
  let body = {template: $template, api_format: $api_format, scenario_messages: $scenario_messages, route: $route, model: $model, model_settings: $model_settings, tools: $tools, scenario_variables: $scenario_variables, scenario_id: $scenario_id, baseline_version_id: $baseline_version_id, includes_unsaved_edits: $includes_unsaved_edits, api_key_id: $api_key_id, variable_targeting_key: $variable_targeting_key, variable_attributes: $variable_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Run Prompt Stream
#
# POST /ui-api/organizations/{organization}/projects/{project}/prompts/{prompt_slug}/run/stream/
# operationId: run_prompt_stream
# --scenario_messages item shape: {role: "system"|"user"|"assistant"|"tool", parts: list}
# --tools item shape: {name: string, description: any, parameters: record}
export def "ui-api-organizations-projects-prompts-run-stream stream" [
  prompt_slug: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  template: string
  api_format: string@api-format-completer
  scenario_messages: list # item shape: {role: "system"|"user"|"assistant"|"tool", parts: list}
  --route: any
  --model: any
  --model-settings: any
  --tools: list # item shape: {name: string, description: any, parameters: record}
  --scenario-variables: record
  scenario_id: string # format: uuid
  --baseline-version-id: any
  --includes-unsaved-edits: oneof<nothing, bool>
  --api-key-id: any
  --variable-targeting-key: any
  --variable-attributes: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/($prompt_slug)/run/stream/")
  let body = {template: $template, api_format: $api_format, scenario_messages: $scenario_messages, route: $route, model: $model, model_settings: $model_settings, tools: $tools, scenario_variables: $scenario_variables, scenario_id: $scenario_id, baseline_version_id: $baseline_version_id, includes_unsaved_edits: $includes_unsaved_edits, api_key_id: $api_key_id, variable_targeting_key: $variable_targeting_key, variable_attributes: $variable_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Run Prompt Batch
#
# POST /ui-api/organizations/{organization}/projects/{project}/prompts/{prompt_slug}/batch-run/
# operationId: run_prompt_batch
# --scenario_messages item shape: {role: "system"|"user"|"assistant"|"tool", parts: list}
# --tools item shape: {name: string, description: any, parameters: record}
export def "ui-api-organizations-projects-prompts-batch-run batch" [
  prompt_slug: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  template: string
  api_format: string@api-format-completer
  scenario_messages: list # item shape: {role: "system"|"user"|"assistant"|"tool", parts: list}
  dataset_id: string # format: uuid
  --route: any
  --model: any
  --model-settings: any
  --tools: list # item shape: {name: string, description: any, parameters: record}
  --scenario-variables: record
  scenario_id: string # format: uuid
  --baseline-version-id: any
  --includes-unsaved-edits: oneof<nothing, bool>
  --api-key-id: any
  --max-cases: any
  --variable-targeting-key: any
  --variable-attributes: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/($prompt_slug)/batch-run/")
  let body = {template: $template, api_format: $api_format, scenario_messages: $scenario_messages, dataset_id: $dataset_id, route: $route, model: $model, model_settings: $model_settings, tools: $tools, scenario_variables: $scenario_variables, scenario_id: $scenario_id, baseline_version_id: $baseline_version_id, includes_unsaved_edits: $includes_unsaved_edits, api_key_id: $api_key_id, max_cases: $max_cases, variable_targeting_key: $variable_targeting_key, variable_attributes: $variable_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Prompt Runs
#
# GET /ui-api/organizations/{organization}/projects/{project}/prompts/{prompt_slug}/runs/
# operationId: list_prompt_runs
export def "ui-api-organizations-projects-prompts-runs runs" [
  prompt_slug: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 30
  --offset: int # default: 0
]: nothing -> table<id: string, organization_id: string, project_id: string, prompt_id: string, run_type: string, dataset_id: any, total_cases: any, completed_cases: int, failed_cases: int, baseline_version_id: any, includes_unsaved_edits: bool, scenario_id: any, scenario_name_snapshot: any, model: string, status: string, latency_ms: any, cost_estimate: any, error: any, created_at: string, created_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/($prompt_slug)/runs/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Prompt Run
#
# GET /ui-api/organizations/{organization}/projects/{project}/prompts/{prompt_slug}/runs/{run_id}/
# operationId: get_prompt_run
export def "ui-api-organizations-projects-prompts-runs run" [
  prompt_slug: string
  run_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, organization_id: string, project_id: string, prompt_id: string, run_type: string, dataset_id: any, total_cases: any, completed_cases: int, failed_cases: int, baseline_version_id: any, includes_unsaved_edits: bool, scenario_id: any, scenario_name_snapshot: any, model: string, status: string, latency_ms: any, cost_estimate: any, error: any, created_at: string, created_by: string, template_snapshot: string, scenario_messages_snapshot: any, rendered_messages: list<record>, model_settings: any, tools: table<name: string, description: any, parameters: record>, variables: record, output: any, usage: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/($prompt_slug)/runs/($run_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Prompt Run Cases
#
# GET /ui-api/organizations/{organization}/projects/{project}/prompts/{prompt_slug}/runs/{run_id}/cases/
# operationId: list_prompt_run_cases
export def "ui-api-organizations-projects-prompts-runs-cases cases" [
  prompt_slug: string
  run_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 100
  --offset: int # default: 0
  --status-filter: string
]: nothing -> table<id: string, organization_id: string, project_id: string, prompt_run_id: string, dataset_case_id: any, case_index: int, variables: record, rendered_messages: any, output: any, usage: any, latency_ms: any, cost_estimate: any, status: string, error: any, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "status_filter" $status_filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/prompts/($prompt_slug)/runs/($run_id)/cases/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run Prompt Playground
#
# POST /ui-api/organizations/{organization}/projects/{project}/playground/run/
# operationId: run_prompt_playground
# --tools item shape: {name: string, description?: any, parameters?: record}
# --model_settings shape: {max_tokens?: int, temperature?: float, top_p?: float, top_k?: int, timeout?: float, parallel_tool_calls?: bool, tool_choice?: any, seed?: int, presence_penalty?: float, frequency_penalty?: float, logit_bias?: record, stop_sequences?: list, extra_headers?: record, thinking?: any, service_tier?: "auto"|"default"|"flex"|"priority", extra_body?: any}
export def "ui-api-organizations-projects-playground-run playground" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  messages: list
  --tools: list # default: [] — item shape: {name: string, description?: any, parameters?: record}
  --model-settings: record # shape: {max_tokens?: int, temperature?: float, top_p?: float, top_k?: int, timeout?: float, parallel_tool_calls?: bool, tool_choice?: any, seed?: int, presence_penalty?: float, frequency_penalty?: float, logit_bias?: record, stop_sequences?: list, extra_headers?: record, thinking?: any, service_tier?: "auto"|"default"|"flex"|"priority", extra_body?: any}
  api_format: string@api-format-completer
  route: string
  model: string
  --api-key-id: any
  --stream: oneof<nothing, bool> # default: false
]: any -> record<output_message: record<parts: list<any>, usage: record<input_tokens: int, cache_write_tokens: int, cache_read_tokens: int, output_tokens: int, input_audio_tokens: int, cache_audio_read_tokens: int, output_audio_tokens: int, details: record>, model_name: any, timestamp: string, kind: string, provider_name: any, provider_url: any, provider_details: any, provider_response_id: any, finish_reason: any, run_id: any, conversation_id: any, metadata: any, state: string>, usage: any, model: string, finish_reason: any, response_id: any, latency_ms: int, cost_estimate: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/playground/run/")
  let body = {messages: $messages, tools: $tools, model_settings: $model_settings, api_format: $api_format, route: $route, model: $model, api_key_id: $api_key_id, stream: $stream} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Run Prompt Playground Stream
#
# POST /ui-api/organizations/{organization}/projects/{project}/playground/run/stream/
# operationId: run_prompt_playground_stream
# --tools item shape: {name: string, description?: any, parameters?: record}
# --model_settings shape: {max_tokens?: int, temperature?: float, top_p?: float, top_k?: int, timeout?: float, parallel_tool_calls?: bool, tool_choice?: any, seed?: int, presence_penalty?: float, frequency_penalty?: float, logit_bias?: record, stop_sequences?: list, extra_headers?: record, thinking?: any, service_tier?: "auto"|"default"|"flex"|"priority", extra_body?: any}
export def "ui-api-organizations-projects-playground-run-stream stream" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  messages: list
  --tools: list # default: [] — item shape: {name: string, description?: any, parameters?: record}
  --model-settings: record # shape: {max_tokens?: int, temperature?: float, top_p?: float, top_k?: int, timeout?: float, parallel_tool_calls?: bool, tool_choice?: any, seed?: int, presence_penalty?: float, frequency_penalty?: float, logit_bias?: record, stop_sequences?: list, extra_headers?: record, thinking?: any, service_tier?: "auto"|"default"|"flex"|"priority", extra_body?: any}
  api_format: string@api-format-completer
  route: string
  model: string
  --api-key-id: any
  --stream: oneof<nothing, bool> # default: false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/playground/run/stream/")
  let body = {messages: $messages, tools: $tools, model_settings: $model_settings, api_format: $api_format, route: $route, model: $model, api_key_id: $api_key_id, stream: $stream} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Load From Span
#
# GET /ui-api/organizations/{organization}/projects/{project}/playground/from-span/
# operationId: load_from_span
export def "ui-api-organizations-projects-playground-from-span span" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --span-id: string
  --trace-id: string
  --since: string
  --until: string
]: nothing -> record<messages: list<any>, tools: table<name: string, description: any, parameters: record>, model_settings: record<max_tokens: int, temperature: float, top_p: float, top_k: int, timeout: float, parallel_tool_calls: bool, tool_choice: any, seed: int, presence_penalty: float, frequency_penalty: float, logit_bias: record, stop_sequences: list<string>, extra_headers: record, thinking: any, service_tier: string, extra_body: any>, route: any, model: any, output_message: any, span_start_timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "span_id" $span_id "scalar") (serialize-qp "trace_id" $trace_id "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/playground/from-span/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Projects List By Org
#
# GET /ui-api/organizations/{organization}/projects/
# operationId: projects_list_by_org
export def "ui-api-organizations-projects org" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, project_name: string, created_at: string, description: any, organization_name: string, visibility: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Projects Create
#
# POST /ui-api/organizations/{organization}/projects/
# operationId: projects_create
export def "ui-api-organizations-projects create" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  project_name: string
  --description: any
  --visibility: string@visibility-completer # default: public
]: any -> record<id: string, project_name: string, created_at: string, description: any, organization_name: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/")
  let body = {project_name: $project_name, description: $description, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Project Info
#
# GET /ui-api/organizations/{organization}/projects/{project}/
# operationId: project_info
export def "ui-api-organizations-projects info" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, project_name: string, created_at: string, description: any, organization_name: string, visibility: string, project_url: string, project_role: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Projects Update
#
# PUT /ui-api/organizations/{organization}/projects/{project}/
# operationId: projects_update
export def "ui-api-organizations-projects update" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-name: any
  --description: any
  --visibility: any
]: any -> record<id: string, project_name: string, created_at: string, description: any, organization_name: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/")
  let body = {project_name: $project_name, description: $description, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Projects Delete
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/
# operationId: projects_delete
export def "ui-api-organizations-projects delete" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Project Dashboard Query
#
# POST /ui-api/organizations/{organization}/projects/{project}/query/
# operationId: project_dashboard_query
export def "ui-api-organizations-projects-query query" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-timestamp: string # format: date-time
  --max-timestamp: string # format: date-time
  --deployment-environment: string
  --limit: int # default: 5000
  --timezone: string
  --body-query: string
  --body-variables: record
  --materialized: oneof<nothing, bool>
  --dashboard-slug: string
  --query-source: string
]: any -> record<columns: table<name: string, type: any, nullable: bool>, data: list<list<any>>, duration: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_timestamp" $min_timestamp "scalar") (serialize-qp "max_timestamp" $max_timestamp "scalar") (serialize-qp "deployment_environment" $deployment_environment "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "timezone" $timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/query/" $qp)
  let body = {query: $body_query, variables: $body_variables, materialized: $materialized, dashboard_slug: $dashboard_slug, query_source: $query_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Project Query Validate
#
# POST /ui-api/organizations/{organization}/projects/{project}/query/validate/
# operationId: project_query_validate
export def "ui-api-organizations-projects-query-validate validate" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-timestamp: string # format: date-time
  --max-timestamp: string # format: date-time
  --deployment-environment: string
  --limit: int # default: 5000
  --timezone: string
  --body-query: string
  --body-variables: record
  --materialized: oneof<nothing, bool>
  --dashboard-slug: string
  --query-source: string
]: any -> record<valid: bool, error: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_timestamp" $min_timestamp "scalar") (serialize-qp "max_timestamp" $max_timestamp "scalar") (serialize-qp "deployment_environment" $deployment_environment "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "timezone" $timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/query/validate/" $qp)
  let body = {query: $body_query, variables: $body_variables, materialized: $materialized, dashboard_slug: $dashboard_slug, query_source: $query_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Standard Dashboards
#
# GET /ui-api/organizations/{organization}/projects/{project}/standard-dashboards/
# operationId: get_standard_dashboards
export def "ui-api-organizations-projects-standard-dashboards dashboards-by-organization-project" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/standard-dashboards/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Standard Dashboards
#
# PUT /ui-api/organizations/{organization}/projects/{project}/standard-dashboards/
# operationId: update_standard_dashboards
export def "ui-api-organizations-projects-standard-dashboards dashboards-by-organization-project-1" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  standard_dashboards: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/standard-dashboards/")
  let body = {standard_dashboards: $standard_dashboards} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Projects Create Read Token
#
# POST /ui-api/organizations/{organization}/projects/{project}/read-tokens/
# operationId: projects_create_read_token
export def "ui-api-organizations-projects-read-tokens token-by-organization-project" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --expires-at: any
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/read-tokens/")
  let body = {description: $description, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Projects Get Read Tokens
#
# GET /ui-api/organizations/{organization}/projects/{project}/read-tokens/
# operationId: projects_get_read_tokens
export def "ui-api-organizations-projects-read-tokens tokens" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # default: 0
  --limit: int # default: 20
  --search: string
  --status: string
  --sort-by: string@sort-by-completer-1 # default: created_at
  --sort-order: string@sort-order-completer # default: desc
]: nothing -> record<data: table<id: string, project_id: string, created_at: string, description: any, expires_at: any, created_by_name: any, project_name: string, token_prefix: string, active: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/read-tokens/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Projects Revoke Read Token
#
# POST /ui-api/organizations/{organization}/projects/{project}/read-tokens/{token_id}/revoke/
# operationId: projects_revoke_read_token
export def "ui-api-organizations-projects-read-tokens-revoke token" [
  token_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/read-tokens/($token_id)/revoke/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Projects Reactivate Read Token
#
# POST /ui-api/organizations/{organization}/projects/{project}/read-tokens/{token_id}/reactivate/
# operationId: projects_reactivate_read_token
export def "ui-api-organizations-projects-read-tokens-reactivate token" [
  token_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/read-tokens/($token_id)/reactivate/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Projects Delete Read Token
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/read-tokens/{token_id}/
# operationId: projects_delete_read_token
export def "ui-api-organizations-projects-read-tokens token-by-token_id-organization-project" [
  token_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/read-tokens/($token_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Saved Search
#
# POST /ui-api/organizations/{organization}/projects/{project}/saved-searches/
# operationId: create_saved_search
export def "ui-api-organizations-projects-saved-searches search-by-project-organization" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  where_clause: string
  --is-private: oneof<nothing, bool>
  filter_alert: any # Optional filter-alert configuration. Within `filter_alert`, `channel_assignments` is the schedule-aware form and takes precedence over `channel_ids` when both are provided.
]: any -> record<id: string, project_id: string, created_at: string, created_by_name: any, updated_at: string, updated_by_name: any, name: string, where_clause: string, is_private: bool, filter_alert: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/saved-searches/")
  let body = {name: $name, where_clause: $where_clause, is_private: $is_private, filter_alert: $filter_alert} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Saved Searches
#
# GET /ui-api/organizations/{organization}/projects/{project}/saved-searches/
# operationId: list_saved_searches
export def "ui-api-organizations-projects-saved-searches searches" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, project_id: string, created_at: string, created_by_name: any, updated_at: string, updated_by_name: any, name: string, where_clause: string, is_private: bool, filter_alert: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/saved-searches/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Saved Search
#
# GET /ui-api/organizations/{organization}/projects/{project}/saved-searches/{saved_search_id}/
# operationId: get_saved_search
export def "ui-api-organizations-projects-saved-searches search-by-saved_search_id-project-organization" [
  saved_search_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, project_id: string, created_at: string, created_by_name: any, updated_at: string, updated_by_name: any, name: string, where_clause: string, is_private: bool, filter_alert: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/saved-searches/($saved_search_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Saved Search
#
# PUT /ui-api/organizations/{organization}/projects/{project}/saved-searches/{saved_search_id}/
# operationId: update_saved_search
export def "ui-api-organizations-projects-saved-searches search-by-saved_search_id-project-organization-1" [
  saved_search_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  where_clause: string
  --is-private: oneof<nothing, bool>
  filter_alert: any # Optional filter-alert configuration. Within `filter_alert`, `channel_assignments` is the schedule-aware form and takes precedence over `channel_ids` when both are provided.
]: any -> record<id: string, project_id: string, created_at: string, created_by_name: any, updated_at: string, updated_by_name: any, name: string, where_clause: string, is_private: bool, filter_alert: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/saved-searches/($saved_search_id)/")
  let body = {name: $name, where_clause: $where_clause, is_private: $is_private, filter_alert: $filter_alert} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Saved Search
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/saved-searches/{saved_search_id}/
# operationId: delete_saved_search
export def "ui-api-organizations-projects-saved-searches search-by-saved_search_id-project-organization-2" [
  saved_search_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/saved-searches/($saved_search_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get User Saved Search Notification
#
# GET /ui-api/organizations/{organization}/projects/{project}/saved-searches/{saved_search_id}/notifications/
# operationId: get_user_saved_search_notification
export def "ui-api-organizations-projects-saved-searches-notifications notification-by-saved_search_id-project-organization" [
  saved_search_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<is_muted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/saved-searches/($saved_search_id)/notifications/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update User Saved Search Notification
#
# PUT /ui-api/organizations/{organization}/projects/{project}/saved-searches/{saved_search_id}/notifications/
# operationId: update_user_saved_search_notification
export def "ui-api-organizations-projects-saved-searches-notifications notification-by-saved_search_id-project-organization-1" [
  saved_search_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-muted: oneof<nothing, bool>
]: any -> record<is_muted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/saved-searches/($saved_search_id)/notifications/")
  let body = {is_muted: $is_muted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set Issue States
#
# POST /ui-api/organizations/{organization}/projects/{project}/saved-searches/set-issue-states/
# operationId: set_issue_states
export def "ui-api-organizations-projects-saved-searches-set-issue-states states" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  filter_alert_issue_ids: list
  state: string@state-completer
]: any -> table<id: string, project_id: string, filter_alert_id: string, created_at: string, updated_at: string, index: int, fingerprint: string, issue_label: string, issue_description: any, last_opened_at: string, state: string, first_trace_id: any, first_span_id: any, first_span_message: any, first_exception_type: any, first_exception_message: any, first_exception_stacktrace: any, latest_trace_id: any, latest_span_id: any, last_notified: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/saved-searches/set-issue-states/")
  let body = {filter_alert_issue_ids: $filter_alert_issue_ids, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Check Saved Search
#
# POST /ui-api/organizations/{organization}/projects/{project}/saved-searches/check/
# operationId: check_saved_search
export def "ui-api-organizations-projects-saved-searches-check search" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-start-timestamp: string # format: date-time
  name: string
  where_clause: string
  --is-private: oneof<nothing, bool>
  filter_alert: any # Optional filter-alert configuration. Within `filter_alert`, `channel_assignments` is the schedule-aware form and takes precedence over `channel_ids` when both are provided.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_start_timestamp" $min_start_timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/saved-searches/check/" $qp)
  let body = {name: $name, where_clause: $where_clause, is_private: $is_private, filter_alert: $filter_alert} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Format Database Statement
#
# POST /ui-api/organizations/{organization}/projects/{project}/sql/format/
# operationId: format_database_statement
export def "ui-api-organizations-projects-sql-format statement" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-system: string
  secret_sql: string
]: any -> record<formatted_query: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "db_system" $db_system "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/sql/format/" $qp)
  let body = {secret_sql: $secret_sql} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Remote Controls
#
# GET /ui-api/organizations/{organization}/projects/{project}/playground/remote-controls/
# operationId: list_remote_controls
export def "ui-api-organizations-projects-playground-remote-controls controls" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string, endpoints: list<record>, connected_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/playground/remote-controls/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Remote Control
#
# GET /ui-api/organizations/{organization}/projects/{project}/playground/remote-controls/{remote_control_id}/
# operationId: get_remote_control
export def "ui-api-organizations-projects-playground-remote-controls control" [
  remote_control_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, project_id: string, name: string, endpoints: table<name: string, type: string, function_signature: any, agent_metadata: any, eval_metadata: any>, connected_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/playground/remote-controls/($remote_control_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch Timeline
#
# GET /ui-api/organizations/{organization}/projects/{project}/timeline/
# operationId: fetch_timeline
export def "ui-api-organizations-projects-timeline timeline" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string
  --spans-since: string # format: date-time
  --spans-until: string # format: date-time
  --n-buckets: int
  --deployment-environment: string
]: nothing -> record<data: table<start: string, end: string, n_records: int, n_errors: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "spans_since" $spans_since "scalar") (serialize-qp "spans_until" $spans_until "scalar") (serialize-qp "n_buckets" $n_buckets "scalar") (serialize-qp "deployment_environment" $deployment_environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/timeline/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Variable Types
#
# GET /ui-api/organizations/{organization}/projects/{project}/variable-types/
# operationId: list_variable_types
export def "ui-api-organizations-projects-variable-types types" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, project_id: string, name: string, description: any, source_hint: any, current_version: int, used_by_count: int, created_at: string, updated_at: string, created_by_name: any, updated_by_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variable-types/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Variable Type
#
# POST /ui-api/organizations/{organization}/projects/{project}/variable-types/
# operationId: create_variable_type
export def "ui-api-organizations-projects-variable-types type-by-organization-project" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  description: any
  --json-schema: any
  --source-hint: any
  --ui-hints: any
]: any -> record<id: string, project_id: string, name: string, description: any, json_schema: record, schema_hash: string, source_hint: any, ui_hints: any, current_version: int, used_by_count: int, created_at: string, updated_at: string, created_by_name: any, updated_by_name: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variable-types/")
  let body = {name: $name, description: $description, json_schema: $json_schema, source_hint: $source_hint, ui_hints: $ui_hints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Variable Type
#
# GET /ui-api/organizations/{organization}/projects/{project}/variable-types/{type_id}/
# operationId: get_variable_type
export def "ui-api-organizations-projects-variable-types type-by-type_id-organization-project" [
  type_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, project_id: string, name: string, description: any, json_schema: record, schema_hash: string, source_hint: any, ui_hints: any, current_version: int, used_by_count: int, created_at: string, updated_at: string, created_by_name: any, updated_by_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variable-types/($type_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Variable Type
#
# PUT /ui-api/organizations/{organization}/projects/{project}/variable-types/{type_id}/
# operationId: update_variable_type
export def "ui-api-organizations-projects-variable-types type-by-type_id-organization-project-1" [
  type_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --description: any
  --json-schema: any
  --source-hint: any
  --ui-hints: any
]: any -> record<id: string, project_id: string, name: string, description: any, json_schema: record, schema_hash: string, source_hint: any, ui_hints: any, current_version: int, used_by_count: int, created_at: string, updated_at: string, created_by_name: any, updated_by_name: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variable-types/($type_id)/")
  let body = {name: $name, description: $description, json_schema: $json_schema, source_hint: $source_hint, ui_hints: $ui_hints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Variable Type
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/variable-types/{type_id}/
# operationId: delete_variable_type
export def "ui-api-organizations-projects-variable-types type-by-type_id-organization-project-2" [
  type_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variable-types/($type_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Variable Type By Name
#
# GET /ui-api/organizations/{organization}/projects/{project}/variable-types/by-name/{name}/
# operationId: get_variable_type_by_name
export def "ui-api-organizations-projects-variable-types-by-name name" [
  name: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, project_id: string, name: string, description: any, json_schema: record, schema_hash: string, source_hint: any, ui_hints: any, current_version: int, used_by_count: int, created_at: string, updated_at: string, created_by_name: any, updated_by_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variable-types/by-name/($name)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Variable Type Versions
#
# GET /ui-api/organizations/{organization}/projects/{project}/variable-types/{type_id}/versions/
# operationId: get_variable_type_versions
export def "ui-api-organizations-projects-variable-types-versions versions" [
  type_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, type_id: string, version: int, json_schema: record, schema_hash: string, source_hint: any, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variable-types/($type_id)/versions/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Variable Definitions
#
# GET /ui-api/organizations/{organization}/projects/{project}/variables/
# operationId: list_variable_definitions
export def "ui-api-organizations-projects-variables definitions" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, project_id: string, type_id: any, type_name: any, kind: string, display_name: any, prompt_slug: any, schema_type: any, name: string, description: any, rollout: record<labels: record, latest_weight: float>, override_count: int, override_names: list<any>, external: bool, label_count: int, version_count: int, created_at: string, updated_at: string, created_by_name: any, updated_by_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variables/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Variable Definition
#
# POST /ui-api/organizations/{organization}/projects/{project}/variables/
# operationId: create_variable_definition
# --rollout shape: {labels: record, latest_weight?: float}
# --overrides item shape: {name?: any, description?: any, conditions: list, rollout: record}
export def "ui-api-organizations-projects-variables definition-by-organization-project" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  description: any
  json_schema: any
  --template-inputs-schema: any
  --type-id: any
  rollout: record # Rollout configuration stored as JSONB. — shape: {labels: record, latest_weight?: float}
  overrides: list # item shape: {name?: any, description?: any, conditions: list, rollout: record}
  --aliases: list
  --example: any
  --external: oneof<nothing, bool>
  --labels: record
]: any -> record<id: string, project_id: string, type_id: any, type_name: any, kind: string, name: string, display_name: any, prompt_slug: any, description: any, json_schema: any, template_inputs_schema: any, labels: record, latest_version: any, rollout: record<labels: record, latest_weight: float>, overrides: table<name: any, description: any, conditions: list, rollout: record>, aliases: any, example: any, external: bool, created_at: string, updated_at: string, created_by_name: any, updated_by_name: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variables/")
  let body = {name: $name, description: $description, json_schema: $json_schema, template_inputs_schema: $template_inputs_schema, type_id: $type_id, rollout: $rollout, overrides: $overrides, aliases: $aliases, example: $example, external: $external, labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Variables Config
#
# GET /ui-api/organizations/{organization}/projects/{project}/variables/config/
# operationId: get_variables_config
export def "ui-api-organizations-projects-variables-config config" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<variables: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variables/config/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Variable Definition
#
# GET /ui-api/organizations/{organization}/projects/{project}/variables/{variable_id}/
# operationId: get_variable_definition
export def "ui-api-organizations-projects-variables definition-by-variable_id-organization-project" [
  variable_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, project_id: string, type_id: any, type_name: any, kind: string, name: string, display_name: any, prompt_slug: any, description: any, json_schema: any, template_inputs_schema: any, labels: record, latest_version: any, rollout: record<labels: record, latest_weight: float>, overrides: table<name: any, description: any, conditions: list, rollout: record>, aliases: any, example: any, external: bool, created_at: string, updated_at: string, created_by_name: any, updated_by_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variables/($variable_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Variable Definition
#
# PUT /ui-api/organizations/{organization}/projects/{project}/variables/{variable_id}/
# operationId: update_variable_definition
# --rollout shape: {labels: record, latest_weight?: float}
# --overrides item shape: {name?: any, description?: any, conditions: list, rollout: record}
export def "ui-api-organizations-projects-variables definition-by-variable_id-organization-project-1" [
  variable_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --routing-description: string
  --name: string
  --description: any
  --json-schema: any
  --template-inputs-schema: any
  --type-id: any
  --rollout: record # Rollout configuration stored as JSONB. — shape: {labels: record, latest_weight?: float}
  --overrides: list # item shape: {name?: any, description?: any, conditions: list, rollout: record}
  --aliases: any
  --example: any
  --external: oneof<nothing, bool>
  --labels: record
]: any -> record<id: string, project_id: string, type_id: any, type_name: any, kind: string, name: string, display_name: any, prompt_slug: any, description: any, json_schema: any, template_inputs_schema: any, labels: record, latest_version: any, rollout: record<labels: record, latest_weight: float>, overrides: table<name: any, description: any, conditions: list, rollout: record>, aliases: any, example: any, external: bool, created_at: string, updated_at: string, created_by_name: any, updated_by_name: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "routing_description" $routing_description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variables/($variable_id)/" $qp)
  let body = {name: $name, description: $description, json_schema: $json_schema, template_inputs_schema: $template_inputs_schema, type_id: $type_id, rollout: $rollout, overrides: $overrides, aliases: $aliases, example: $example, external: $external, labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Variable Definition
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/variables/{variable_id}/
# operationId: delete_variable_definition
export def "ui-api-organizations-projects-variables definition-by-variable_id-organization-project-2" [
  variable_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variables/($variable_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Variable Definition By Name
#
# GET /ui-api/organizations/{organization}/projects/{project}/variables/by-name/{name}/
# operationId: get_variable_definition_by_name
export def "ui-api-organizations-projects-variables-by-name name" [
  name: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, project_id: string, type_id: any, type_name: any, kind: string, name: string, display_name: any, prompt_slug: any, description: any, json_schema: any, template_inputs_schema: any, labels: record, latest_version: any, rollout: record<labels: record, latest_weight: float>, overrides: table<name: any, description: any, conditions: list, rollout: record>, aliases: any, example: any, external: bool, created_at: string, updated_at: string, created_by_name: any, updated_by_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variables/by-name/($name)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Optimizer Settings
#
# GET /ui-api/organizations/{organization}/projects/{project}/variables/{variable_id}/optimizer/settings/
# operationId: get_optimizer_settings
export def "ui-api-organizations-projects-variables-optimizer-settings settings-by-variable_id-organization-project" [
  variable_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<system_prompt: string, default_system_prompt: string, custom_system_prompt: any, is_customized: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variables/($variable_id)/optimizer/settings/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Optimizer Settings
#
# PUT /ui-api/organizations/{organization}/projects/{project}/variables/{variable_id}/optimizer/settings/
# operationId: update_optimizer_settings
export def "ui-api-organizations-projects-variables-optimizer-settings settings-by-variable_id-organization-project-1" [
  variable_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --system-prompt: any
]: any -> record<system_prompt: string, default_system_prompt: string, custom_system_prompt: any, is_customized: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variables/($variable_id)/optimizer/settings/")
  let body = {system_prompt: $system_prompt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Optimizer Evidence Preview
#
# GET /ui-api/organizations/{organization}/projects/{project}/variables/{variable_id}/optimizer/evidence-preview/
# operationId: get_optimizer_evidence_preview
export def "ui-api-organizations-projects-variables-optimizer-evidence-preview preview" [
  variable_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-label: string
  --max-candidate-spans: int # default: 100
  --lookback-minutes: int # default: 7200
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source_label" $source_label "scalar") (serialize-qp "max_candidate_spans" $max_candidate_spans "scalar") (serialize-qp "lookback_minutes" $lookback_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variables/($variable_id)/optimizer/evidence-preview/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stream Optimizer Proposal
#
# POST /ui-api/organizations/{organization}/projects/{project}/variables/{variable_id}/optimizer/proposal/stream/
# operationId: stream_optimizer_proposal
export def "ui-api-organizations-projects-variables-optimizer-proposal-stream proposal" [
  variable_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  source_label: string
  --max-candidate-spans: int
  --lookback-minutes: int
  --evidence-snapshot: any
  --refinement-instructions: any
  --previous-proposed-value: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variables/($variable_id)/optimizer/proposal/stream/")
  let body = {source_label: $source_label, max_candidate_spans: $max_candidate_spans, lookback_minutes: $lookback_minutes, evidence_snapshot: $evidence_snapshot, refinement_instructions: $refinement_instructions, previous_proposed_value: $previous_proposed_value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Versions
#
# GET /ui-api/organizations/{organization}/projects/{project}/variables/{variable_id}/versions/
# operationId: get_versions
export def "ui-api-organizations-projects-variables-versions versions" [
  variable_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string
]: nothing -> table<id: string, variable_definition_id: string, version: int, serialized_value: string, description: any, created_at: string, created_by: any, created_by_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "label" $label "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variables/($variable_id)/versions/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Version
#
# POST /ui-api/organizations/{organization}/projects/{project}/variables/{variable_id}/versions/
# operationId: create_version
export def "ui-api-organizations-projects-variables-versions version-by-variable_id-organization-project" [
  variable_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  serialized_value: string
  --description: any
  --labels: any
]: any -> record<id: string, variable_definition_id: string, version: int, serialized_value: string, description: any, created_at: string, created_by: any, created_by_name: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variables/($variable_id)/versions/")
  let body = {serialized_value: $serialized_value, description: $description, labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Version By Number
#
# GET /ui-api/organizations/{organization}/projects/{project}/variables/{variable_id}/versions/{version}/
# operationId: get_version_by_number
export def "ui-api-organizations-projects-variables-versions number" [
  variable_id: string
  version: int
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, variable_definition_id: string, version: int, serialized_value: string, description: any, created_at: string, created_by: any, created_by_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variables/($variable_id)/versions/($version)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Version
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/variables/{variable_id}/versions/{version}/
# operationId: delete_version
export def "ui-api-organizations-projects-variables-versions version-by-variable_id-version-organization-project" [
  variable_id: string
  version: int
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variables/($variable_id)/versions/($version)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Labels
#
# GET /ui-api/organizations/{organization}/projects/{project}/variables/{variable_id}/labels/
# operationId: get_labels
export def "ui-api-organizations-projects-variables-labels labels" [
  variable_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, variable_definition_id: string, label: string, target_type: string, target_label: any, version_id: any, version_number: any, serialized_value: any, updated_at: string, updated_by: any, updated_by_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variables/($variable_id)/labels/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign Label
#
# PUT /ui-api/organizations/{organization}/projects/{project}/variables/{variable_id}/labels/{label}/
# operationId: assign_label
export def "ui-api-organizations-projects-variables-labels label-by-variable_id-label-organization-project" [
  variable_id: string
  label: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-type: string
  --version: int
  --target-label: string
  --description: any
]: any -> record<id: string, variable_definition_id: string, label: string, target_type: string, target_label: any, version_id: any, version_number: any, serialized_value: any, updated_at: string, updated_by: any, updated_by_name: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variables/($variable_id)/labels/($label)/")
  let body = {target_type: $target_type, version: $version, target_label: $target_label, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Label
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/variables/{variable_id}/labels/{label}/
# operationId: delete_label
export def "ui-api-organizations-projects-variables-labels label-by-variable_id-label-organization-project-1" [
  variable_id: string
  label: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variables/($variable_id)/labels/($label)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Label History
#
# GET /ui-api/organizations/{organization}/projects/{project}/variables/{variable_id}/labels/{label}/history/
# operationId: get_label_history
export def "ui-api-organizations-projects-variables-labels-history history" [
  variable_id: string
  label: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, label: string, target_type: string, target_label: any, version_id: any, version_number: any, previous_target_type: any, previous_target_label: any, previous_version_id: any, previous_version_number: any, description: any, assigned_at: string, assigned_by: any, assigned_by_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variables/($variable_id)/labels/($label)/history/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Routing History
#
# GET /ui-api/organizations/{organization}/projects/{project}/variables/{variable_id}/routing-history/
# operationId: get_routing_history
export def "ui-api-organizations-projects-variables-routing-history history" [
  variable_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, variable_definition_id: string, rollout: record<labels: record, latest_weight: float>, overrides: list<record>, aliases: any, previous_rollout: any, previous_overrides: any, previous_aliases: any, description: any, changed_at: string, changed_by: any, changed_by_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/variables/($variable_id)/routing-history/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get User Project Settings
#
# GET /ui-api/organizations/{organization}/projects/{project}/user-settings/
# operationId: get_user_project_settings
export def "ui-api-organizations-projects-user-settings settings" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/user-settings/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set Default Environment
#
# PUT /ui-api/organizations/{organization}/projects/{project}/user-settings/default-environment/
# operationId: set_default_environment
export def "ui-api-organizations-projects-user-settings-default-environment environment-by-project-organization" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-environment: any
]: any -> record<user_id: string, project_id: string, default_environment: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/user-settings/default-environment/")
  let body = {default_environment: $default_environment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Default Environment
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/user-settings/default-environment/
# operationId: delete_default_environment
export def "ui-api-organizations-projects-user-settings-default-environment environment-by-project-organization-1" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/user-settings/default-environment/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Workflows
#
# GET /ui-api/organizations/{organization}/projects/{project}/workflows/
# operationId: list_workflows
export def "ui-api-organizations-projects-workflows workflows" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alert-id: string
]: nothing -> table<id: string, organization_id: string, project_id: string, display_name: string, slug: string, kind: string, enabled: bool, notification_channels: list<record>, manual_runs_enabled: bool, created_by: any, created_at: string, updated_at: string, last_run_id: any, last_run_status: any, last_run_started_at: any, schedule_cron: any, alert_triggers: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alert_id" $alert_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/workflows/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Workflow
#
# POST /ui-api/organizations/{organization}/projects/{project}/workflows/
# operationId: create_workflow
export def "ui-api-organizations-projects-workflows workflow-by-project-organization" [
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  display_name: string
  slug: string
  instructions: string
  --description: any
  --notification-channel-ids: list
  --repository-resource-ids: list
  --manual-runs-enabled: oneof<nothing, bool>
]: any -> record<id: string, organization_id: string, project_id: string, display_name: string, slug: string, description: any, instructions: string, kind: string, enabled: bool, notification_channel_ids: list<string>, repository_resource_ids: list<string>, manual_runs_enabled: bool, created_by: any, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/workflows/")
  let body = {display_name: $display_name, slug: $slug, instructions: $instructions, description: $description, notification_channel_ids: $notification_channel_ids, repository_resource_ids: $repository_resource_ids, manual_runs_enabled: $manual_runs_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Workflow
#
# GET /ui-api/organizations/{organization}/projects/{project}/workflows/{workflow_slug}/
# operationId: get_workflow
export def "ui-api-organizations-projects-workflows workflow-by-workflow_slug-project-organization" [
  workflow_slug: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, organization_id: string, project_id: string, display_name: string, slug: string, description: any, instructions: string, kind: string, enabled: bool, notification_channel_ids: list<string>, repository_resource_ids: list<string>, manual_runs_enabled: bool, created_by: any, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/workflows/($workflow_slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Workflow
#
# PATCH /ui-api/organizations/{organization}/projects/{project}/workflows/{workflow_slug}/
# operationId: update_workflow
export def "ui-api-organizations-projects-workflows workflow-by-workflow_slug-project-organization-1" [
  workflow_slug: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string
  --description: any
  --instructions: string
  --enabled: oneof<nothing, bool>
  --notification-channel-ids: list
  --repository-resource-ids: list
  --manual-runs-enabled: oneof<nothing, bool>
]: any -> record<id: string, organization_id: string, project_id: string, display_name: string, slug: string, description: any, instructions: string, kind: string, enabled: bool, notification_channel_ids: list<string>, repository_resource_ids: list<string>, manual_runs_enabled: bool, created_by: any, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/workflows/($workflow_slug)/")
  let body = {display_name: $display_name, description: $description, instructions: $instructions, enabled: $enabled, notification_channel_ids: $notification_channel_ids, repository_resource_ids: $repository_resource_ids, manual_runs_enabled: $manual_runs_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Workflow
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/workflows/{workflow_slug}/
# operationId: delete_workflow
export def "ui-api-organizations-projects-workflows workflow-by-workflow_slug-project-organization-2" [
  workflow_slug: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/workflows/($workflow_slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Trigger Run
#
# POST /ui-api/organizations/{organization}/projects/{project}/workflows/{workflow_slug}/runs/
# operationId: trigger_run
export def "ui-api-organizations-projects-workflows-runs run-by-workflow_slug-project-organization" [
  workflow_slug: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, workflow_id: string, triggered_by: string, triggered_by_user_id: any, triggered_by_trigger_id: any, alert_run_id: any, status: string, started_at: any, completed_at: any, scheduled_for: any, run_snapshot: record<instructions: string, context: string>, title: any, summary: any, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/workflows/($workflow_slug)/runs/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Runs
#
# GET /ui-api/organizations/{organization}/projects/{project}/workflows/{workflow_slug}/runs/
# operationId: list_runs
export def "ui-api-organizations-projects-workflows-runs runs" [
  workflow_slug: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 20
  --before: string
]: nothing -> table<id: string, workflow_id: string, triggered_by: string, triggered_by_user_id: any, triggered_by_trigger_id: any, alert_run_id: any, status: string, started_at: any, completed_at: any, scheduled_for: any, run_snapshot: record<instructions: string, context: string>, title: any, summary: any, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/workflows/($workflow_slug)/runs/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Run
#
# GET /ui-api/organizations/{organization}/projects/{project}/workflows/{workflow_slug}/runs/{run_id}/
# operationId: get_run
export def "ui-api-organizations-projects-workflows-runs run-by-workflow_slug-run_id-project-organization" [
  workflow_slug: string
  run_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<run: record<id: string, workflow_id: string, triggered_by: string, triggered_by_user_id: any, triggered_by_trigger_id: any, alert_run_id: any, status: string, started_at: any, completed_at: any, scheduled_for: any, run_snapshot: record<instructions: string, context: string>, title: any, summary: any, created_at: string>, messages: table<id: string, run_id: string, kind: string, message: record, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/workflows/($workflow_slug)/runs/($run_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Post Message
#
# POST /ui-api/organizations/{organization}/projects/{project}/workflows/{workflow_slug}/runs/{run_id}/messages/
# operationId: post_message
export def "ui-api-organizations-projects-workflows-runs-messages message" [
  workflow_slug: string
  run_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  content: string
]: any -> record<id: string, run_id: string, kind: string, message: record, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/workflows/($workflow_slug)/runs/($run_id)/messages/")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Memories
#
# GET /ui-api/organizations/{organization}/projects/{project}/workflows/{workflow_slug}/memories/
# operationId: list_memories
export def "ui-api-organizations-projects-workflows-memories memories" [
  workflow_slug: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, workflow_id: string, source_run_id: any, content: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/workflows/($workflow_slug)/memories/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Memory
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/workflows/{workflow_slug}/memories/{memory_id}/
# operationId: delete_memory
export def "ui-api-organizations-projects-workflows-memories memory" [
  workflow_slug: string
  memory_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/workflows/($workflow_slug)/memories/($memory_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Workflow Triggers
#
# GET /ui-api/organizations/{organization}/projects/{project}/workflows/{workflow_slug}/triggers/
# operationId: list_workflow_triggers
export def "ui-api-organizations-projects-workflows-triggers triggers" [
  workflow_slug: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, workflow_id: string, kind: string, config: record, enabled: bool, created_by: any, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/workflows/($workflow_slug)/triggers/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Workflow Trigger
#
# POST /ui-api/organizations/{organization}/projects/{project}/workflows/{workflow_slug}/triggers/
# operationId: create_workflow_trigger
export def "ui-api-organizations-projects-workflows-triggers trigger-by-workflow_slug-project-organization" [
  workflow_slug: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  config: any
  --enabled: oneof<nothing, bool>
]: any -> record<id: string, workflow_id: string, kind: string, config: record, enabled: bool, created_by: any, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/workflows/($workflow_slug)/triggers/")
  let body = {config: $config, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Workflow Trigger
#
# PATCH /ui-api/organizations/{organization}/projects/{project}/workflows/{workflow_slug}/triggers/{trigger_id}/
# operationId: update_workflow_trigger
export def "ui-api-organizations-projects-workflows-triggers trigger-by-workflow_slug-trigger_id-project-organization" [
  workflow_slug: string
  trigger_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --config: any
]: any -> record<id: string, workflow_id: string, kind: string, config: record, enabled: bool, created_by: any, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/workflows/($workflow_slug)/triggers/($trigger_id)/")
  let body = {enabled: $enabled, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Workflow Trigger
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/workflows/{workflow_slug}/triggers/{trigger_id}/
# operationId: delete_workflow_trigger
export def "ui-api-organizations-projects-workflows-triggers trigger-by-workflow_slug-trigger_id-project-organization-1" [
  workflow_slug: string
  trigger_id: string
  project: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/workflows/($workflow_slug)/triggers/($trigger_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Projects Create Write Token
#
# POST /ui-api/organizations/{organization}/projects/{project}/write-tokens/
# operationId: projects_create_write_token
export def "ui-api-organizations-projects-write-tokens token-by-organization-project" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --expires-at: any
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/write-tokens/")
  let body = {description: $description, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Projects Get Write Tokens
#
# GET /ui-api/organizations/{organization}/projects/{project}/write-tokens/
# operationId: projects_get_write_tokens
export def "ui-api-organizations-projects-write-tokens tokens" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # default: 0
  --limit: int # default: 20
  --search: string
  --status: string
  --sort-by: string@sort-by-completer-1 # default: created_at
  --sort-order: string@sort-order-completer # default: desc
]: nothing -> record<data: table<id: string, project_id: string, created_at: string, description: any, expires_at: any, project_name: string, created_by_name: any, token_prefix: string, active: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/write-tokens/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Projects Write Token Has Data
#
# GET /ui-api/organizations/{organization}/projects/{project}/write-tokens/{token_id}/has-data/
# operationId: projects_write_token_has_data
export def "ui-api-organizations-projects-write-tokens-has-data data" [
  token_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<has_data: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/write-tokens/($token_id)/has-data/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Projects Revoke Write Token
#
# POST /ui-api/organizations/{organization}/projects/{project}/write-tokens/{token_id}/revoke/
# operationId: projects_revoke_write_token
export def "ui-api-organizations-projects-write-tokens-revoke token" [
  token_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/write-tokens/($token_id)/revoke/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Projects Reactivate Write Token
#
# POST /ui-api/organizations/{organization}/projects/{project}/write-tokens/{token_id}/reactivate/
# operationId: projects_reactivate_write_token
export def "ui-api-organizations-projects-write-tokens-reactivate token" [
  token_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/write-tokens/($token_id)/reactivate/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Projects Delete Write Token
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/write-tokens/{token_id}/
# operationId: projects_delete_write_token
export def "ui-api-organizations-projects-write-tokens token-by-token_id-organization-project" [
  token_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/write-tokens/($token_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Latest Project
#
# GET /ui-api/latest-project/
# operationId: get_latest_project
export def "ui-api-latest-project project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/latest-project/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Default Organization
#
# GET /ui-api/default-organization/
# operationId: get_default_organization
export def "ui-api-default-organization organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/default-organization/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Predicted Region
#
# GET /ui-api/prefrences/predicted-region
# operationId: get_predicted_region
export def "ui-api-prefrences-predicted-region region" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cf-ipcountry: string
]: nothing -> record<region: string, country: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/prefrences/predicted-region")
  let extra_headers = {"cf-ipcountry": $cf_ipcountry} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Short Link
#
# POST /ui-api/short-link/
# operationId: create_short_link
export def "ui-api-short-link link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  destination: string
]: any -> record<short_code: string, destination: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/short-link/")
  let body = {destination: $destination} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Short Link
#
# GET /ui-api/short-link/{short_code}/
# operationId: get_short_link
export def "ui-api-short-link link-by-short_code" [
  short_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<short_code: string, destination: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/short-link/($short_code)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# User Info
#
# POST /ui-api/auth/callback
# operationId: user_info
export def "ui-api-auth-callback info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string
  provider: string
  redirect_uri: string
  --flarelytics-cookie: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/auth/callback")
  let body = {code: $code, provider: $provider, redirect_uri: $redirect_uri, flarelytics_cookie: $flarelytics_cookie} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create User
#
# POST /ui-api/auth/users
# operationId: create_user
export def "ui-api-auth-users user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cf-ipcountry: string
  --cf-ipcity: string
  username: string
  --company-name: any
  --company-role: any
  --referral-source: any
  --gclid: any
  --flarelytics-cookie: any
  user_info_jwt: string
]: any -> record<access_token: string, expiration: string, user: record<id: string, name: string, email: string, default_organization: record<id: string, organization_name: string>, personal_organization: record<id: string, organization_name: string>, country: any, city: any, company_name: any, company_role: any, created_at: string, identity_providers: record<google: record, github: record, local: record, custom_providers: record>, session_duration: string>, organizations: table<id: string, organization_name: string, subscription_plan: any, has_admin_panel: bool>, analytics_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/auth/users")
  let body = {username: $username, company_name: $company_name, company_role: $company_role, referral_source: $referral_source, gclid: $gclid, flarelytics_cookie: $flarelytics_cookie, user_info_jwt: $user_info_jwt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"cf-ipcountry": $cf_ipcountry, "cf-ipcity": $cf_ipcity} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Device Auth
#
# POST /ui-api/auth/device-auth
# operationId: device_auth
export def "ui-api-auth-device-auth auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deviceCode: string
  --include-identity-provider-ids: any
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deviceCode" $deviceCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ui-api/auth/device-auth" $qp)
  let body = {include_identity_provider_ids: $include_identity_provider_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send Create Account Email
#
# POST /ui-api/auth/users/email/
# operationId: send_create_account_email
export def "ui-api-auth-users-email email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # format: email
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/auth/users/email/")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Email Signup Session
#
# GET /ui-api/auth/users/email-session-data/{session_token}/
# operationId: get_email_signup_session
export def "ui-api-auth-users-email-session-data session" [
  session_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<email: string, totp_secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/auth/users/email-session-data/($session_token)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create User Email Signup
#
# POST /ui-api/auth/users/email-signup/
# operationId: create_user_email_signup
export def "ui-api-auth-users-email-signup signup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cf-ipcountry: string
  --cf-ipcity: string
  username: string
  --company-name: any
  --company-role: any
  --referral-source: any
  --gclid: any
  --flarelytics-cookie: any
  session_token: string
  password: string # format: password
  totp_code: string
]: any -> record<access_token: string, expiration: string, user: record<id: string, name: string, email: string, default_organization: record<id: string, organization_name: string>, personal_organization: record<id: string, organization_name: string>, country: any, city: any, company_name: any, company_role: any, created_at: string, identity_providers: record<google: record, github: record, local: record, custom_providers: record>, session_duration: string>, organizations: table<id: string, organization_name: string, subscription_plan: any, has_admin_panel: bool>, analytics_enabled: bool, recovery_codes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/auth/users/email-signup/")
  let body = {username: $username, company_name: $company_name, company_role: $company_role, referral_source: $referral_source, gclid: $gclid, flarelytics_cookie: $flarelytics_cookie, session_token: $session_token, password: $password, totp_code: $totp_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"cf-ipcountry": $cf_ipcountry, "cf-ipcity": $cf_ipcity} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Providers
#
# GET /ui-api/auth/providers
# operationId: get_providers
export def "ui-api-auth-providers providers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization: string
]: nothing -> table<id: string, type: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organization" $organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ui-api/auth/providers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Connectable Providers
#
# GET /ui-api/auth/connectable-providers/
# operationId: get_connectable_providers
export def "ui-api-auth-connectable-providers providers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization: string
]: nothing -> record<providers: table<id: string, type: string, name: string, connected: bool>, can_disconnect: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organization" $organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ui-api/auth/connectable-providers/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Login With Email
#
# POST /ui-api/auth/email/login/
# operationId: login_with_email
export def "ui-api-auth-email-login email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
  --password: string
  --flarelytics-cookie: any
  --totp-code: string
  --recovery-code: string
]: any -> record<access_token: string, expiration: string, user: record<id: string, name: string, email: string, default_organization: record<id: string, organization_name: string>, personal_organization: record<id: string, organization_name: string>, country: any, city: any, company_name: any, company_role: any, created_at: string, identity_providers: record<google: record, github: record, local: record, custom_providers: record>, session_duration: string>, organizations: table<id: string, organization_name: string, subscription_plan: any, has_admin_panel: bool>, analytics_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/auth/email/login/")
  let body = {email: $email, password: $password, flarelytics_cookie: $flarelytics_cookie, totp_code: $totp_code, recovery_code: $recovery_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Forgotten Password
#
# POST /ui-api/auth/email/forgotten-password/
# operationId: forgotten_password
export def "ui-api-auth-email-forgotten-password password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # format: email
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/auth/email/forgotten-password/")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reset Password
#
# POST /ui-api/auth/email/reset-password/
# operationId: reset_password
export def "ui-api-auth-email-reset-password password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string
  --new-password: string # format: password
  --totp-code: string
  --recovery-code: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/auth/email/reset-password/")
  let body = {token: $body_token, new_password: $new_password, totp_code: $totp_code, recovery_code: $recovery_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set Provider Link
#
# POST /ui-api/auth/providers/callback/
# operationId: set_provider_link
export def "ui-api-auth-providers-callback link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string
  provider: string
  redirect_uri: string
  --flarelytics-cookie: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/auth/providers/callback/")
  let body = {code: $code, provider: $provider, redirect_uri: $redirect_uri, flarelytics_cookie: $flarelytics_cookie} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add Idp To Token
#
# POST /ui-api/auth/providers/add-idp-to-token/
# operationId: add_idp_to_token
export def "ui-api-auth-providers-add-idp-to-token token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string
  provider: string
  redirect_uri: string
  --flarelytics-cookie: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/auth/providers/add-idp-to-token/")
  let body = {code: $code, provider: $provider, redirect_uri: $redirect_uri, flarelytics_cookie: $flarelytics_cookie} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unlink Provider
#
# DELETE /ui-api/auth/providers/{provider}
# operationId: unlink_provider
export def "ui-api-auth-providers provider" [
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/auth/providers/($provider)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Local Totp Secret
#
# GET /ui-api/auth/providers/local/totp-secret/
# operationId: get_local_totp_secret
export def "ui-api-auth-providers-local-totp-secret secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<totp_secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/auth/providers/local/totp-secret/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set Local Provider Link
#
# POST /ui-api/auth/providers/local/callback/
# operationId: set_local_provider_link
export def "ui-api-auth-providers-local-callback link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string # format: password
  totp_secret: string
  totp_code: string
]: any -> record<recovery_codes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/auth/providers/local/callback/")
  let body = {password: $password, totp_secret: $totp_secret, totp_code: $totp_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Totp Reset Session
#
# GET /ui-api/auth/totp/reset/session/{session_token}/
# operationId: get_totp_reset_session
export def "ui-api-auth-totp-reset-session session" [
  session_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<email: string, totp_secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/auth/totp/reset/session/($session_token)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initiate Totp Reset
#
# POST /ui-api/auth/totp/reset/initiate/
# operationId: initiate_totp_reset
export def "ui-api-auth-totp-reset-initiate reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # format: email
  recovery_code: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/auth/totp/reset/initiate/")
  let body = {email: $email, recovery_code: $recovery_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Complete Totp Reset
#
# POST /ui-api/auth/totp/reset/complete/
# operationId: complete_totp_reset
export def "ui-api-auth-totp-reset-complete reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  session_token: string
  totp_code: string
]: any -> record<recovery_codes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/auth/totp/reset/complete/")
  let body = {session_token: $session_token, totp_code: $totp_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get pending device authorization
#
# GET /ui-api/oauth/device/pending
# operationId: get_pending_device_authorization
export def "ui-api-oauth-device-pending authorization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-code: string
]: nothing -> record<client_id: string, client_name: string, logo_uri: any, client_uri: any, scope: string, scopes: list<string>, allowed_scopes: list<string>, resource: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_code" $user_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ui-api/oauth/device/pending" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Authorize device
#
# POST /ui-api/oauth/device/authorize
# operationId: authorize_device
export def "ui-api-oauth-device-authorize device" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_code: string
  organization_id: string # format: uuid
  project_id: any
  scopes: any
  --limits: any
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/oauth/device/authorize")
  let body = {user_code: $user_code, organization_id: $organization_id, project_id: $project_id, scopes: $scopes, limits: $limits} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deny device authorization
#
# POST /ui-api/oauth/device/deny
# operationId: deny_device
export def "ui-api-oauth-device-deny device" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_code: string
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/oauth/device/deny")
  let body = {user_code: $user_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Public Trace
#
# GET /ui-api/public-traces/{public_trace_id}
# operationId: get_public_trace
export def "ui-api-public-traces trace" [
  public_trace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, title: string, trace_id: string, trace_start: string, trace_end: string, organization_name: string, project_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/public-traces/($public_trace_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Public Trace Fetch Query
#
# POST /ui-api/public-traces/{public_trace_id}/fetch-query
# operationId: public_trace_fetch_query
# --columns item shape: {name: string, expression?: any}
export def "ui-api-public-traces-fetch-query query" [
  public_trace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --columns: list # List of columns to select, optionally as an expression with an alias (e.g. `select attributes->>'foo' as foo` -> [('foo', 'attributes->>'foo')] — item shape: {name: string, expression?: any}
  --body-where: string # SQL WHERE clause to filter the records. The clause should be in the form of a SQL expression, e.g. `service_name = 'my-service'` (default: true)
  --tab-hidden: oneof<nothing, bool>
  --min-start-timestamp: string # format: date-time
  --max-start-timestamp: string # format: date-time
  order: string@order-completer
  --limit: int
  --timezone: string
  --trace-limit: int
  --last-span: list
  --include-ancestors: oneof<nothing, bool>
  --deployment-environment: list
  --table: string
  --exclude-trace-ids: list
]: any -> record<result_spans: table<start_timestamp: string, trace_id: string, span_id: string, parent_span_id: any, span_name: string, level: any, service_name: string, otel_scope_name: any, tags: list, created_at: string, end_timestamp: string, kind: string, message: string, is_exception: bool, exception_type: any, otel_scope_version: any, service_version: any, http_response_status_code: any, gen_ai_operation_name: any, gen_ai_request_model: any, gen_ai_response_model: any, gen_ai_system: any, gen_ai_usage_input_tokens: any, gen_ai_usage_output_tokens: any, gen_ai_response_id: any, operation_cost: any, user_columns: record, matched_filter: bool>, extra_spans: table<start_timestamp: string, trace_id: string, span_id: string, parent_span_id: any, span_name: string, level: any, service_name: string, otel_scope_name: any, tags: list, created_at: string, end_timestamp: string, kind: string, message: string, is_exception: bool, exception_type: any, otel_scope_version: any, service_version: any, http_response_status_code: any, gen_ai_operation_name: any, gen_ai_request_model: any, gen_ai_response_model: any, gen_ai_system: any, gen_ai_usage_input_tokens: any, gen_ai_usage_output_tokens: any, gen_ai_response_id: any, operation_cost: any, user_columns: record, matched_filter: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/public-traces/($public_trace_id)/fetch-query")
  let body = {columns: $columns, where: $body_where, tab_hidden: $tab_hidden, min_start_timestamp: $min_start_timestamp, max_start_timestamp: $max_start_timestamp, order: $order, limit: $limit, timezone: $timezone, trace_limit: $trace_limit, last_span: $last_span, include_ancestors: $include_ancestors, deployment_environment: $deployment_environment, table: $table, exclude_trace_ids: $exclude_trace_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Public Trace Fetch Trace Counts
#
# GET /ui-api/public-traces/{public_trace_id}/fetch-trace-counts
# operationId: public_trace_fetch_trace_counts
export def "ui-api-public-traces-fetch-trace-counts counts" [
  public_trace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<counts: table<trace_id: string, count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/public-traces/($public_trace_id)/fetch-trace-counts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Public Trace Fetch Trace Graph
#
# GET /ui-api/public-traces/{public_trace_id}/fetch-trace-graph
# operationId: public_trace_fetch_trace_graph
export def "ui-api-public-traces-fetch-trace-graph graph" [
  public_trace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<graphs: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/public-traces/($public_trace_id)/fetch-trace-graph")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Public Trace Fetch Ancestors
#
# POST /ui-api/public-traces/{public_trace_id}/fetch-ancestors
# operationId: public_trace_fetch_ancestors
# --columns item shape: {name: string, expression?: any}
export def "ui-api-public-traces-fetch-ancestors ancestors" [
  public_trace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --columns: list # List of columns to select, optionally as an expression with an alias (e.g. `select attributes->>'foo' as foo` -> [('foo', 'attributes->>'foo')] — item shape: {name: string, expression?: any}
  spans: list
]: any -> record<spans: table<start_timestamp: string, trace_id: string, span_id: string, parent_span_id: any, span_name: string, level: any, service_name: string, otel_scope_name: any, tags: list, created_at: string, end_timestamp: string, kind: string, message: string, is_exception: bool, exception_type: any, otel_scope_version: any, service_version: any, http_response_status_code: any, gen_ai_operation_name: any, gen_ai_request_model: any, gen_ai_response_model: any, gen_ai_system: any, gen_ai_usage_input_tokens: any, gen_ai_usage_output_tokens: any, gen_ai_response_id: any, operation_cost: any, user_columns: record, matched_filter: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/public-traces/($public_trace_id)/fetch-ancestors")
  let body = {columns: $columns, spans: $spans} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Public Trace Fetch Data
#
# POST /ui-api/public-traces/{public_trace_id}/fetch-trace
# operationId: public_trace_fetch_data
export def "ui-api-public-traces-fetch-trace data" [
  public_trace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: list
]: any -> record<spans: table<start_timestamp: string, trace_id: string, span_id: string, parent_span_id: any, span_name: string, level: any, service_name: string, otel_scope_name: any, tags: list, created_at: string, end_timestamp: string, kind: string, message: string, is_exception: bool, exception_type: any, otel_scope_version: any, service_version: any, http_response_status_code: any, gen_ai_operation_name: any, gen_ai_request_model: any, gen_ai_response_model: any, gen_ai_system: any, gen_ai_usage_input_tokens: any, gen_ai_usage_output_tokens: any, gen_ai_response_id: any, operation_cost: any, user_columns: record, matched_filter: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/public-traces/($public_trace_id)/fetch-trace")
  let body = {cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Public Trace Fetch Record Details
#
# POST /ui-api/public-traces/{public_trace_id}/fetch-details
# operationId: public_trace_fetch_record_details
# --columns item shape: {name: string, expression?: any}
export def "ui-api-public-traces-fetch-details details" [
  public_trace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --columns: list # List of columns to select, optionally as an expression with an alias (e.g. `select attributes->>'foo' as foo` -> [('foo', 'attributes->>'foo')] — item shape: {name: string, expression?: any}
  spans: list
  --min-start-timestamp: any
  --max-start-timestamp: any
  --timezone: any
]: any -> table<start_timestamp: string, end_timestamp: string, message: string, day: string, duration: any, otel_status_code: any, otel_status_message: any, otel_links: any, otel_events: any, otel_scope_name: any, otel_scope_version: any, http_response_status_code: any, url_path: any, url_query: any, url_full: any, http_route: any, http_method: any, log_body: any, attributes: any, attributes_json_schema: any, otel_scope_attributes: any, service_namespace: any, service_instance_id: any, service_version: any, process_pid: any, otel_resource_attributes: any, telemetry_sdk_name: any, telemetry_sdk_language: any, telemetry_sdk_version: any, deployment_environment: any, exception_type: any, user_columns: record, trace_id: string, span_id: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/public-traces/($public_trace_id)/fetch-details")
  let body = {columns: $columns, spans: $spans, min_start_timestamp: $min_start_timestamp, max_start_timestamp: $max_start_timestamp, timezone: $timezone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Public Trace
#
# POST /ui-api/organizations/{organization}/projects/{project}/public-traces/
# operationId: create_public_trace
export def "ui-api-organizations-projects-public-traces trace-by-organization-project" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string
  trace_id: string
  trace_start: string # format: date-time
  trace_end: string # format: date-time
  --expires-in: string@expires-in-completer
]: any -> record<id: string, title: string, created_at: string, trace_id: string, trace_start: string, trace_end: string, project_id: string, expires_at: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/public-traces/")
  let body = {title: $title, trace_id: $trace_id, trace_start: $trace_start, trace_end: $trace_end, expires_in: $expires_in} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Public Traces
#
# POST /ui-api/organizations/{organization}/projects/{project}/public-traces/list/
# operationId: get_public_traces
export def "ui-api-organizations-projects-public-traces-list traces" [
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trace-id: any
]: any -> table<id: string, title: string, created_at: string, trace_id: string, trace_start: string, trace_end: string, project_id: string, expires_at: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/public-traces/list/")
  let body = {trace_id: $trace_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Public Trace
#
# PUT /ui-api/organizations/{organization}/projects/{project}/public-traces/{public_trace_id}/
# operationId: update_public_trace
export def "ui-api-organizations-projects-public-traces trace-by-public_trace_id-organization-project" [
  public_trace_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string
]: any -> record<id: string, title: string, created_at: string, trace_id: string, trace_start: string, trace_end: string, project_id: string, expires_at: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/public-traces/($public_trace_id)/")
  let body = {title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Public Trace
#
# DELETE /ui-api/organizations/{organization}/projects/{project}/public-traces/{public_trace_id}/
# operationId: delete_public_trace
export def "ui-api-organizations-projects-public-traces trace-by-public_trace_id-organization-project-1" [
  public_trace_id: string
  organization: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/organizations/($organization)/projects/($project)/public-traces/($public_trace_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get User Emails
#
# GET /ui-api/account/emails/
# operationId: get_user_emails
export def "ui-api-account-emails emails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, email: string, verified_at: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/account/emails/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create User Email
#
# POST /ui-api/account/emails/
# operationId: create_user_email
export def "ui-api-account-emails email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # format: email
]: any -> record<id: string, email: string, verified_at: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ui-api/account/emails/")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get User Email
#
# GET /ui-api/account/emails/{email_id}/
# operationId: get_user_email
export def "ui-api-account-emails email-by-email_id" [
  email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, email: string, verified_at: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/account/emails/($email_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete User Email
#
# DELETE /ui-api/account/emails/{email_id}/
# operationId: delete_user_email
export def "ui-api-account-emails email-by-email_id-1" [
  email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/account/emails/($email_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resend Verification Email
#
# POST /ui-api/account/emails/{email_id}/resend-verification/
# operationId: resend_verification_email
export def "ui-api-account-emails-resend-verification email" [
  email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/account/emails/($email_id)/resend-verification/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Verify User Email
#
# PUT /ui-api/account/emails/{email_id}/verify/
# operationId: verify_user_email
export def "ui-api-account-emails-verify email" [
  email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/account/emails/($email_id)/verify/")
  let body = {code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unsubscribe From Alert
#
# GET /ui-api/unsubscribe/alert/{token}
# operationId: unsubscribe_from_alert
export def "ui-api-unsubscribe-alert alert" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/unsubscribe/alert/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unsubscribe From Saved Search
#
# GET /ui-api/unsubscribe/saved-search/{token}
# operationId: unsubscribe_from_saved_search
export def "ui-api-unsubscribe-saved-search search" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ui-api/unsubscribe/saved-search/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
